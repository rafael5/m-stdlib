STDFS   ; m-stdlib — File-system primitives (text I/O, path manipulation, bytes).
        ; m-lint: disable-file=M-MOD-024
        ; m-lint: disable-file=M-MOD-022
        ; m-lint: disable-file=M-MOD-036
        ; m-lint: disable-file=M-MOD-020
        ; M-MOD-024 false positives: the linter parses YDB OPEN/USE/CLOSE
        ; deviceparams (readonly, newversion, append, delete, exception,
        ; nowrap, noecho) as local-variable reads. Same finding as STDCSV
        ; and STDCSPRNG; tracked as P2 in TOOLCHAIN-FINDINGS.md.
        ; M-MOD-022: STDFS uses $ZEOF and $ZLEVEL throughout — both are YDB
        ; extensions to the M standard. v0.2.x ships YDB-only by design (see
        ; "Engine portability" in docs/modules/stdfs.md). The IRIS arm will
        ; arrive when STDFS gets its $ZF→stat callout backend.
        ; M-MOD-036 (XECUTE injection) is intentional in the *Bytes() dispatch
        ; helpers: the XECUTE wrapper is the only way to invoke $ZF without
        ; the m fmt abbreviation expander mangling the token (longest-prefix
        ; match against $ZFIND). The XECUTE source is built from a literal
        ; template only — no user data flows in. Same trick as STDCRYPTO /
        ; STDCOMPRESS / STDHTTP.
        ; M-MOD-020 (by-ref formal not written) false positives: dispatch
        ; helpers write to `out` via the XECUTE'd $ZF call.
        ;
        ; Public extrinsics:
        ;   $$readFile^STDFS(path)         — read file as string (LF-separated)
        ;   $$writeFile^STDFS(path,data)   — write data; overwrite if file exists
        ;   $$append^STDFS(path,data)      — append data; create if missing
        ;   readLines^STDFS(path,.lines)   — populate lines(1..N) from file
        ;   $$writeLines^STDFS(path,.lines)— write lines(1..N) as LF-separated
        ;   $$exists^STDFS(path)           — 1 iff path exists
        ;   $$remove^STDFS(path)           — delete path; no-op if absent
        ;   $$size^STDFS(path)             — size in bytes; -1 if missing
        ;   $$basename^STDFS(path)         — last path component
        ;   $$dirname^STDFS(path)          — parent path (or "." / "/")
        ;   $$join^STDFS(left,right)       — POSIX path join (absolute right wins)
        ;
        ; Byte-faithful I/O via $ZF -> libc read(2)/write(2) callouts (T13+T14):
        ;   $$readBytes^STDFS(path)        — file content as bytes (no CR/LF normalisation)
        ;   writeBytes^STDFS(path,data)    — write data verbatim; no trailing LF
        ;   appendBytes^STDFS(path,data)   — append data via O_APPEND atomically
        ;   $$available^STDFS()            — 1 iff stdfs.so is loaded
        ;
        ; Text I/O semantics: file is read line-by-line and rejoined with LF.
        ; Trailing CR (CRLF input) is normalised to LF on read; write emits LF.
        ; Binary I/O (readBytes / writeBytes / appendBytes) preserves bytes
        ; exactly — no LF added on write, no CR/LF stripped on read. Use these
        ; for non-text payloads (gzipped data, binaries, signed blobs).
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
        ; Backend (Bytes API): $ZF -> libc open(2)/read(2)/write(2)/close(2).
        ; Source at src/callouts/stdfs.c; descriptor at tools/std_fs.xc.
        ; When the .so is unavailable the *Bytes() entries set $ECODE to
        ; ,U-STDFS-NOT-WIRED, and return; the text-I/O entries (writeFile /
        ; readFile / writeLines / readLines) and append() keep working via
        ; the YDB SEQ device — append() then takes the read-then-rewrite
        ; fallback automatically.
        ;
        ; Deployment runbook (full detail in docs/modules/stdfs.md):
        ;   1. tools/build-callouts.sh      ; produces so/<plat>/stdfs.so
        ;   2. export STDLIB_LIB=<dir-of-so>
        ;   3. export ydb_xc_std_fs=<abs>/tools/std_fs.xc
        ;
        quit
        ;
        ; ---------- public API: path manipulation ----------
        ;
basename(path)  ; Return the last component of path.
        ; doc: @param path    path    POSIX path
        ; doc: @returns       string  last path component; "/" for root; "" for empty input
        ; doc: @example       write $$basename^STDFS("/etc/hosts")  ; "hosts"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$dirname^STDFS, $$join^STDFS
        ; doc: Trailing slash is stripped before extracting the last segment.
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
        ; doc: @param path    path    POSIX path
        ; doc: @returns       path    parent path; "." for no-slash input; "/" for root
        ; doc: @example       write $$dirname^STDFS("/etc/hosts")  ; "/etc"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$basename^STDFS, $$join^STDFS
        ; doc: Trailing slashes are normalised first ("/foo/bar/" → "/foo").
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
        ; doc: @param left    path    left operand
        ; doc: @param right   path    right operand (absolute right wins)
        ; doc: @returns       path    joined path
        ; doc: @example       write $$join^STDFS("/a","b")     ; "/a/b"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$dirname^STDFS, $$basename^STDFS
        ; doc: Empty operand drops out. Trailing slash on left is collapsed.
        if right="" quit left
        if left="" quit right
        if $extract(right,1)="/" quit right
        if $extract(left,$length(left))="/" quit left_right
        quit left_"/"_right
        ;
        ; ---------- public API: existence / metadata ----------
        ;
exists(path)    ; Return 1 iff path exists; else 0.
        ; doc: @param path    path    filesystem path
        ; doc: @returns       bool    1 iff openable; 0 otherwise
        ; doc: @example       write $$exists^STDFS("/etc/hosts")  ; 1
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$size^STDFS, $$readFile^STDFS
        ; doc: Probes via OPEN with timeout=0 inside an $ETRAP — succeeds iff
        ; doc: the path is openable. Avoids $ZSEARCH's per-process cache, so
        ; doc: a path created and removed inside one M process round-trips
        ; doc: correctly.
        new $etrap,result,lvl
        if path="" quit 0
        set result=0,lvl=$zlevel
        set $etrap="set $ecode="""" zgoto "_lvl_":existsRet^STDFS"
        open path:(readonly):0
        close path
        set result=1
existsRet       ; Trap-resume target; reached on success fall-through too.
        ; doc: @internal
        ; doc: Never an external entry point.
        quit result
        ;
size(path)      ; Return size of path in bytes; -1 if missing or unreadable.
        ; doc: @param path    path    filesystem path
        ; doc: @returns       int     byte count; -1 if missing or unreadable
        ; doc: @example       write $$size^STDFS(path)  ; 4096
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$exists^STDFS, $$readBytes^STDFS
        ; doc: Implemented via OPEN/READ-loop tally — does not depend on a stat
        ; doc: callout. Acceptable for routine-sized files; for multi-MB paths
        ; doc: prefer the future $ZF→stat backend.
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
        ; doc: @param path    path    filesystem path
        ; doc: @returns       string  file content; lines LF-separated, trailing LF dropped
        ; doc: @raises        U-STDFS-OPEN-FAIL  path is missing or unreadable
        ; doc: @example       set body=$$readFile^STDFS("/etc/hosts")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$writeFile^STDFS, $$readBytes^STDFS, do readLines^STDFS
        ; doc: Trailing CR on each line is dropped (CRLF normalisation).
        ; doc: A trailing LF is normalised away (round-trips with writeFile).
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
        ; doc: @param path    path    filesystem path; truncated if exists
        ; doc: @param data    string  text content (lines may be LF-separated)
        ; doc: @raises        U-STDFS-OPEN-FAIL  could not open `path` for write
        ; doc: @example       do writeFile^STDFS("/tmp/out.txt","hi")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$readFile^STDFS, do writeBytes^STDFS, do writeLines^STDFS
        ; doc: Empty data creates a zero-byte file.
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
        ; doc: @param path    path    filesystem path; created if absent
        ; doc: @param data    string  text content
        ; doc: @raises        U-STDFS-OPEN-FAIL  could not open for read or write
        ; doc: @example       do append^STDFS("/tmp/log","tick"_$char(10))
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$writeFile^STDFS, do appendBytes^STDFS
        ; doc: Implementation: text-mode read-then-rewrite. For byte-faithful
        ; doc: append at EOF use $$appendBytes^STDFS instead.
        if '$$exists(path) do writeFile(path,data) quit
        new old
        set old=$$readFile(path)
        do writeFile(path,old_data)
        quit
        ;
remove(path)    ; Delete path; idempotent (no-op if already absent).
        ; doc: @param path    path    filesystem path
        ; doc: @raises        U-STDFS-REMOVE-FAIL  open-with-DELETE failed (not the missing-file case)
        ; doc: @example       do remove^STDFS("/tmp/out.txt")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$exists^STDFS
        if '$$exists(path) quit
        open path:(readonly):2  else  set $ecode=",U-STDFS-REMOVE-FAIL," quit
        close path:(delete)
        quit
        ;
readLines(path,lines)   ; Read path into lines(1..N) (1-indexed; CRLF normalised).
        ; doc: @param path    path    filesystem path
        ; doc: @param lines   array   by-ref local; killed then populated as lines(1..N)
        ; doc: @raises        U-STDFS-OPEN-FAIL  path is missing or unreadable
        ; doc: @example       do readLines^STDFS(path,.lines)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$readFile^STDFS, $$writeLines^STDFS
        ; doc: Each line is one M string under lines(i). Empty file → empty array.
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
        ; doc: @param path    path    filesystem path; truncated if exists
        ; doc: @param lines   array   by-ref local subscripted as lines(1..N)
        ; doc: @raises        U-STDFS-OPEN-FAIL  could not open `path` for write
        ; doc: @example       do writeLines^STDFS(path,.lines)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           do readLines^STDFS, $$writeFile^STDFS
        ; doc: lines must be 1-indexed and dense (no gaps in $ORDER).
        new i,prev
        set prev=$io
        open path:(newversion:stream:nowrap):5  else  set $ecode=",U-STDFS-OPEN-FAIL," quit
        use path
        set i=""
        for  set i=$order(lines(i)) quit:i=""  write lines(i),!
        use prev
        close path
        quit
        ;
        ; ---------- public API: byte-faithful I/O via $ZF callouts (T13+T14) ----------
        ;
writeBytes(path,data)   ; Write data to path verbatim — no trailing LF, no transcoding.
        ; doc: @param path    path    filesystem path; truncated if exists
        ; doc: @param data    byte-string  one M character per byte (0..255)
        ; doc: @raises        U-STDFS-NOT-WIRED  stdfs.so is unavailable
        ; doc: @raises        U-STDFS-OPEN-FAIL  open(2) failed
        ; doc: @example       do writeBytes^STDFS("/tmp/blob.bin",bytes)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$readBytes^STDFS, do appendBytes^STDFS, $$writeFile^STDFS
        do dispatch2("stdfs_writeBytes",path,data)
        quit
        ;
appendBytes(path,data)  ; Append data to path via O_APPEND — atomic at EOF, byte-faithful.
        ; doc: @param path    path    filesystem path; created if absent
        ; doc: @param data    byte-string  one M character per byte
        ; doc: @raises        U-STDFS-NOT-WIRED  stdfs.so is unavailable
        ; doc: @raises        U-STDFS-OPEN-FAIL  open(2) failed
        ; doc: @example       do appendBytes^STDFS("/tmp/blob.bin",chunk)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do writeBytes^STDFS, do append^STDFS
        do dispatch2("stdfs_appendBytes",path,data)
        quit
        ;
readBytes(path) ; Return file content as a byte string — no CR/LF normalisation.
        ; doc: @param path    path    filesystem path
        ; doc: @returns       byte-string  file contents byte-for-byte
        ; doc: @raises        U-STDFS-NOT-WIRED       stdfs.so is unavailable
        ; doc: @raises        U-STDFS-OPEN-FAIL       open(2) failed
        ; doc: @raises        U-STDFS-READ-TRUNCATED  file exceeds the 16 MiB buffer cap
        ; doc: @example       set blob=$$readBytes^STDFS("/tmp/blob.bin")
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$readFile^STDFS, do writeBytes^STDFS
        ; doc: For text I/O with newline-joining and CRLF normalisation,
        ; doc: prefer $$readFile^STDFS instead.
        new out
        if '$$available() set $ecode=",U-STDFS-NOT-WIRED," quit ""
        set out=$$dispatchRead("stdfs_readBytes",path)
        quit out
        ;
available()     ; 1 iff the stdfs callout is loaded and open(2) is reachable.
        ; doc: @returns       bool    1 iff stdfs.so is loaded; 0 otherwise
        ; doc: @example       if '$$available^STDFS() do warn^MYAPP("byte-faithful I/O unavailable")
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do writeBytes^STDFS, $$readBytes^STDFS
        ; doc: Never raises — clears $ECODE on the way out.
        new $etrap,rc,cmd
        if $$env^STDOS("ydb_xc_std_fs")="" quit 0
        set $etrap="set $ecode="""" set rc=0 quit"
        set rc=0
        set cmd="set rc=$ZF(""stdfs_available"")"
        xecute cmd
        set $ecode=""
        quit +rc
        ;
        ; ---------- internal helpers ----------
        ;
dispatch2(sym,path,data)        ; Two-input $ZF dispatch (writeBytes / appendBytes).
        ; doc: @internal
        ; doc: XECUTE-wraps $ZF(sym, path, data) so the m fmt token-mangler
        ; doc: doesn't touch $ZF. Sets $ECODE on failure:
        ; doc: ,U-STDFS-NOT-WIRED, if the .so is unloaded;
        ; doc: ,U-STDFS-OPEN-FAIL, otherwise.
        new $etrap,rc,cmd
        if $$env^STDOS("ydb_xc_std_fs")="" set $ecode=",U-STDFS-NOT-WIRED," quit
        set $etrap="set $ecode="""" set rc=-1 quit"
        set rc=0
        set cmd="set rc=$ZF("""_sym_""",path,data)"
        xecute cmd
        if rc=-1 set $ecode=",U-STDFS-NOT-WIRED," quit
        if 'rc set $ecode=",U-STDFS-OPEN-FAIL," quit
        quit
        ;
dispatchRead(sym,path)  ; One-input / one-output $ZF dispatch (readBytes).
        ; doc: @internal
        ; doc: Preallocates a 16 MiB buffer (matching the .xc-declared cap),
        ; doc: invokes $ZF(sym, path, .out), returns the filled bytes.
        new $etrap,rc,cmd,out
        if $$env^STDOS("ydb_xc_std_fs")="" set $ecode=",U-STDFS-NOT-WIRED," quit ""
        set $etrap="set $ecode="""" set rc=-1 quit"
        set rc=0
        set out=$$preallocBuf()
        set cmd="set rc=$ZF("""_sym_""",path,.out)"
        xecute cmd
        if rc=-1 set $ecode=",U-STDFS-NOT-WIRED," quit ""
        if 'rc do  quit ""
        . new err
        . set err=$$lasterror()
        . if err["U-STDFS-READ-TRUNCATED" set $ecode=",U-STDFS-READ-TRUNCATED," quit
        . set $ecode=",U-STDFS-OPEN-FAIL,"
        quit out
        ;
preallocBuf()   ; 16 MiB pre-allocated output buffer for the C side to fill.
        ; doc: @internal
        ; doc: YDB callouts need the M-side string at full capacity before
        ; doc: the C side writes into it.
        quit $justify("",16777216)
        ;
lasterror()     ; Return the C-side last-error message ("" if none).
        ; doc: @internal
        ; doc: readBytes uses this to distinguish OPEN-fail from
        ; doc: READ-TRUNCATED. Soft-fails to "" if the callout is missing.
        new $etrap,rc,cmd,out
        if $$env^STDOS("ydb_xc_std_fs")="" quit ""
        set $etrap="set $ecode="""" set rc=0 quit"
        set rc=0
        set out=$justify("",1024)
        set cmd="set rc=$ZF(""stdfs_lasterror"",.out)"
        xecute cmd
        set $ecode=""
        quit out
        ;
