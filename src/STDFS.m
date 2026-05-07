STDFS   ; m-stdlib — File-system primitives (text I/O, path manipulation).
        ; m-lint: disable-file=M-MOD-024
        ; m-lint: disable-file=M-MOD-022
        ; M-MOD-024 false positives: the linter parses YDB OPEN/USE/CLOSE
        ; deviceparams (readonly, newversion, append, delete, exception,
        ; nowrap, noecho) as local-variable reads. Same finding as STDCSV
        ; and STDCSPRNG; tracked as P2 in TOOLCHAIN-FINDINGS.md.
        ; M-MOD-022: STDFS uses $ZEOF and $ZLEVEL throughout — both are YDB
        ; extensions to the M standard. v0.2.x ships YDB-only by design (see
        ; "Engine portability" in docs/modules/stdfs.md). The IRIS arm will
        ; arrive when STDFS gets its $ZF→stat callout backend.
        ;
        ; Public extrinsics:
        ;   $$readFile^STDFS(path)       — read file as string (LF-separated)
        ;   $$writeFile^STDFS(path,data) — write data; overwrite if file exists
        ;   $$append^STDFS(path,data)    — append data; create if missing
        ;   readLines^STDFS(path,.lines) — populate lines(1..N) from file
        ;   $$writeLines^STDFS(path,.lines) — write lines(1..N) as LF-separated
        ;   $$exists^STDFS(path)         — 1 iff path exists
        ;   $$remove^STDFS(path)         — delete path; no-op if absent
        ;   $$size^STDFS(path)           — size in bytes; -1 if missing
        ;   $$basename^STDFS(path)       — last path component
        ;   $$dirname^STDFS(path)        — parent path (or "." / "/")
        ;   $$join^STDFS(left,right)     — POSIX path join (absolute right wins)
        ;
        ; Text I/O semantics: file is read line-by-line and rejoined with LF.
        ; Trailing CR (CRLF input) is normalised to LF on read; write emits LF.
        ; Binary-safe variants (readBytes / writeBytes / atomic-replace / glob)
        ; are reserved for a follow-on patch alongside the $ZF callout backend.
        ;
        ; Path semantics: POSIX-flavoured. Trailing slashes on dirname/basename
        ; follow GNU coreutils conventions: basename strips them, dirname keeps
        ; the parent with its trailing slash collapsed.
        ;
        ; Existence checks delegate to $ZSEARCH, which YDB resolves via stat()
        ; on first call and caches per-process. remove() opens the file with
        ; the DELETE deviceparam — succeeds for files; silently no-ops if the
        ; file is already absent (idempotent contract).
        ;
        quit
        ;
        ; ---------- public API: path manipulation ----------
        ;
basename(path)  ; Return the last component of path.
        ; doc: Trailing slash is stripped before extracting the last segment.
        ; doc: Root path "/" returns "/"; empty path returns "".
        ; doc: Example: write $$basename^STDFS("/etc/hosts")  ; "hosts"
        if path="" quit ""
        if path="/" quit "/"
        new p,n
        set p=path
        ; Strip a single trailing slash so "foo/bar/" → "foo/bar".
        if $extract(p,$length(p))="/" set p=$extract(p,1,$length(p)-1)
        set n=$length(p,"/")
        quit $piece(p,"/",n)
        ;
dirname(path)   ; Return the parent path (everything but the last component).
        ; doc: No-slash inputs return ".". Root "/" returns "/". Trailing
        ; doc: slashes are normalised first ("/foo/bar/" → "/foo").
        ; doc: Example: write $$dirname^STDFS("/etc/hosts")  ; "/etc"
        if path="" quit "."
        if path="/" quit "/"
        new p,n,parent
        set p=path
        if $extract(p,$length(p))="/" set p=$extract(p,1,$length(p)-1)
        if p'["/" quit "."
        set n=$length(p,"/")
        set parent=$piece(p,"/",1,n-1)
        if parent="" quit "/"
        quit parent
        ;
join(left,right)        ; POSIX path join: absolute right replaces left.
        ; doc: Empty operand drops out. Trailing slash on left is collapsed.
        ; doc: Example: write $$join^STDFS("/a","b")     ; "/a/b"
        ; doc:          write $$join^STDFS("/a","/b")    ; "/b"
        ; doc:          write $$join^STDFS("/a/","b")    ; "/a/b"
        if right="" quit left
        if left="" quit right
        if $extract(right,1)="/" quit right
        if $extract(left,$length(left))="/" quit left_right
        quit left_"/"_right
        ;
        ; ---------- public API: existence / metadata ----------
        ;
exists(path)    ; Return 1 iff path exists; else 0.
        ; doc: Probes via OPEN with timeout=0 inside an $ETRAP — succeeds iff
        ; doc: the path is openable. Avoids $ZSEARCH's per-process cache, so
        ; doc: a path created and removed inside one M process round-trips
        ; doc: correctly. The trap catches YDB's hard-error on missing files
        ; doc: (Z150379354) and unwinds via ZGOTO so the extrinsic returns
        ; doc: cleanly — same pattern as raises^STDASSERT (TOOLCHAIN P1 fix).
        ; doc: Example: write $$exists^STDFS("/etc/hosts")  ; 1
        new $etrap,result,lvl
        if path="" quit 0
        set result=0,lvl=$zlevel
        set $etrap="set $ecode="""" zgoto "_lvl_":existsRet^STDFS"
        open path:(readonly):0
        close path
        set result=1
existsRet       ; Trap-resume target; reached on success fall-through too.
        ; doc: Internal — never an external entry point.
        quit result
        ;
size(path)      ; Return size of path in bytes; -1 if missing or unreadable.
        ; doc: Implemented via OPEN/READ-loop tally — does not depend on a stat
        ; doc: callout. Acceptable for routine-sized files; for multi-MB paths
        ; doc: prefer the future $ZF→stat backend.
        ; doc: Example: write $$size^STDFS(path)  ; 4096
        if '$$exists(path) quit -1
        new total,line,prev
        set total=0,prev=$io
        open path:(readonly):2  else  quit -1
        use path:(noecho)
        for  do  quit:$zeof
        . read line
        . if $zeof,line="" quit
        . ; +1 for the terminator that produced this read; only when not at EOF.
        . set total=total+$length(line)+$select($zeof:0,1:1)
        use prev
        close path
        quit total
        ;
        ; ---------- public API: I/O ----------
        ;
readFile(path)  ; Return file content as a string (lines joined by $C(10)).
        ; doc: Trailing CR on each line is dropped (CRLF normalisation).
        ; doc: A trailing LF is normalised away (round-trips with writeFile).
        ; doc: Sets $ECODE=,U-STDFS-OPEN-FAIL, if path is missing or unreadable.
        ; doc: Example: set body=$$readFile^STDFS("/etc/hosts")
        if '$$exists(path) set $ecode=",U-STDFS-OPEN-FAIL," quit ""
        new buf,line,prev
        set buf="",prev=$io
        open path:(readonly):2  else  set $ecode=",U-STDFS-OPEN-FAIL," quit ""
        use path:(noecho)
        for  do  quit:$zeof
        . read line
        . if $zeof,line="" quit
        . if $extract(line,$length(line))=$char(13) set line=$extract(line,1,$length(line)-1)
        . set buf=$select(buf="":line,1:buf_$char(10)_line)
        use prev
        close path
        quit buf
        ;
writeFile(path,data)    ; Write data to path (overwrite if exists).
        ; doc: Empty data creates a zero-byte file. Sets $ECODE=,U-STDFS-OPEN-FAIL,
        ; doc: on open failure (typically a missing parent directory).
        ; doc: Example: do writeFile^STDFS("/tmp/out.txt","hi")
        new prev
        set prev=$io
        open path:(newversion:stream:nowrap):5  else  set $ecode=",U-STDFS-OPEN-FAIL," quit
        use path
        if data'="" write data
        use prev
        close path
        quit
        ;
append(path,data)       ; Append data to path; create the file if missing.
        ; doc: Sets $ECODE=,U-STDFS-OPEN-FAIL, on open failure.
        ; doc: Example: do append^STDFS("/tmp/log","tick"_$char(10))
        if '$$exists(path) do writeFile(path,data) quit
        ; Read-then-rewrite: avoids the YDB SEQ-device APPEND-mode quirk
        ; where the first WRITE in stream-append mode lands at position 0
        ; instead of EOF. Round-trips cleanly through readFile/writeFile.
        new old
        set old=$$readFile(path)
        do writeFile(path,old_data)
        quit
        ;
remove(path)    ; Delete path; idempotent (no-op if already absent).
        ; doc: Sets $ECODE=,U-STDFS-REMOVE-FAIL, if the open-with-DELETE fails
        ; doc: for any reason other than "file already absent".
        ; doc: Example: do remove^STDFS("/tmp/out.txt")
        if '$$exists(path) quit
        open path:(readonly):2  else  set $ecode=",U-STDFS-REMOVE-FAIL," quit
        close path:(delete)
        quit
        ;
readLines(path,lines)   ; Read path into lines(1..N) (1-indexed; CRLF normalised).
        ; doc: Each line is one M string under lines(i). Empty file → empty array.
        ; doc: Sets $ECODE=,U-STDFS-OPEN-FAIL, if path is missing or unreadable.
        ; doc: Example: do readLines^STDFS(path,.lines)
        kill lines
        if '$$exists(path) set $ecode=",U-STDFS-OPEN-FAIL," quit
        new line,n,prev
        set n=0,prev=$io
        open path:(readonly):2  else  set $ecode=",U-STDFS-OPEN-FAIL," quit
        use path:(noecho)
        for  do  quit:$zeof
        . read line
        . if $zeof,line="" quit
        . if $extract(line,$length(line))=$char(13) set line=$extract(line,1,$length(line)-1)
        . set n=n+1,lines(n)=line
        use prev
        close path
        quit
        ;
writeLines(path,lines)  ; Write lines(1..N) to path, separated and terminated by LF.
        ; doc: lines must be 1-indexed and dense (no gaps in $ORDER).
        ; doc: Sets $ECODE=,U-STDFS-OPEN-FAIL, on open failure.
        ; doc: Example: do writeLines^STDFS(path,.lines)
        new i,prev
        set prev=$io
        open path:(newversion:stream:nowrap):5  else  set $ecode=",U-STDFS-OPEN-FAIL," quit
        use path
        set i=""
        for  set i=$order(lines(i)) quit:i=""  write lines(i),!
        use prev
        close path
        quit
