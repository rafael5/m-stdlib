STDSNAP ; m-stdlib — Snapshot testing: serialize an M tree, diff against a baseline.
        ;
        ; Public extrinsics:
        ;   $$serialize^STDSNAP(.data)               — canonical text dump of data tree
        ;   save^STDSNAP(path, .data)                — write serialize(data) to path
        ;   $$matches^STDSNAP(path, .data)           — 1 iff serialize(data) equals file content
        ;   asserts^STDSNAP(.pass, .fail, path, .data, desc) — STDASSERT-style integration
        ;
        ; Workflow:
        ;   First run: caller calls save() to capture the baseline snapshot.
        ;   Subsequent runs: caller calls matches() (or asserts()) to compare
        ;   the current data against the saved baseline. Mismatches surface as
        ;   STDASSERT failures with a one-line summary.
        ;
        ; Canonical format (line-per-leaf):
        ;   (subscripts)=value
        ; where subscripts is a comma-separated M-syntax list (numeric
        ; subscripts unquoted; string subscripts double-quoted with embedded
        ; doubles per M convention) and value is the leaf node's M-quoted
        ; scalar. Numeric values emit unquoted; everything else is wrapped in
        ; "..." with internal " doubled.
        ;
        ; Lines are emitted in $ORDER walk order — natural M-collation, which
        ; gives numeric sort for numeric subscripts and string sort for the
        ; rest. The walk is deterministic; two calls on the same tree produce
        ; byte-identical output.
        ;
        ; Implementation: $QUERY-driven recursive descent. The `data` formal
        ; binds to the caller's array via pass-by-reference; $QUERY(data) walks
        ; descendants via M's natural collation order.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
serialize(data) ; Walk data tree; return the canonical line-per-leaf dump.
        ; doc: @param data    array   by-ref local; the tree to serialize
        ; doc: @returns       string  canonical line-per-leaf dump; "" for an empty tree
        ; doc: @example       write $$serialize^STDSNAP(.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           do save^STDSNAP, $$matches^STDSNAP
        ; doc: Trailing LF is *not* emitted — keeps round-trip clean against
        ; doc: writeFile/readFile, which add and strip a trailing LF.
        new ref,out,line,raw,subs,value
        set out=""
        set ref="data"
        for  set ref=$query(@ref) quit:ref=""  do
        . set value=@ref
        . ; ref is "data(...)" — strip the leading "data" and the leading "("
        . ; to get the subscript chain in canonical M form.
        . set raw=$extract(ref,5,$length(ref))   ; drop "data"
        . if raw="" set subs="" quit             ; root scalar — not normally walked by $QUERY
        . set subs=raw                           ; (subscripts) form
        . set line=subs_"="_$$qval(value)
        . set out=$select(out="":line,1:out_$char(10)_line)
        quit out
        ;
save(path,data) ; Write serialize(data) to path. Overwrites if exists.
        ; doc: @param path    string  filesystem path; truncated if it exists
        ; doc: @param data    array   by-ref local; the tree to serialize
        ; doc: @raises        U-STDFS-OPEN-FAIL  could not open `path` for write (propagated from STDFS)
        ; doc: @example       do save^STDSNAP("snapshots/cfg.snap",.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$matches^STDSNAP, do asserts^STDSNAP
        new text
        set text=$$serialize(.data)
        do writeFile^STDFS(path,text)
        quit
        ;
matches(path,data)      ; Return 1 iff serialize(data) equals the file's content.
        ; doc: @param path    string  filesystem path to the baseline snapshot
        ; doc: @param data    array   by-ref local; current tree
        ; doc: @returns       bool    1 iff current matches baseline; 0 otherwise (incl. missing file)
        ; doc: @example       write $$matches^STDSNAP("snapshots/cfg.snap",.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           do save^STDSNAP, do asserts^STDSNAP
        ; doc: A missing file returns 0 (no match — first run typically calls
        ; doc: save() to seed the snapshot before relying on matches).
        new fileText,curText
        if '$$exists^STDFS(path) quit 0
        set fileText=$$readFile^STDFS(path)
        set curText=$$serialize(.data)
        quit $select(fileText=curText:1,1:0)
        ;
asserts(p,f,path,data,desc)     ; STDASSERT-style snapshot assertion.
        ; doc: @param p       int     pass counter (by-ref; incremented on match)
        ; doc: @param f       int     fail counter (by-ref; incremented on mismatch)
        ; doc: @param path    string  filesystem path to the baseline snapshot
        ; doc: @param data    array   by-ref local; current tree
        ; doc: @param desc    string  human-readable assertion description
        ; doc: @raises        U-STDFS-OPEN-FAIL  in update mode if the write fails (propagated from STDFS)
        ; doc: @example       do asserts^STDSNAP(.pass,.fail,"cfg.snap",.cfg,"config matches baseline")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           do save^STDSNAP, $$matches^STDSNAP
        ; doc: On match: increments p and emits PASS via STDASSERT.
        ; doc: On mismatch: increments f and emits FAIL with a brief diagnostic.
        ; doc: Update mode: when ^STDLIB($job,"stdsnap","update")=1, writes the
        ; doc: current snapshot to `path` and records PASS instead of comparing.
        ; doc: Used by m-cli's `m test --update-snapshots` to regenerate
        ; doc: baselines after an intentional change in test output.
        if $get(^STDLIB($job,"stdsnap","update")) do save(path,.data) do recordPass^STDASSERT(.p,desc_" [snapshot updated]") quit
        if $$matches(path,.data) do recordPass^STDASSERT(.p,desc) quit
        do recordFail^STDASSERT(.f,desc,"snapshot at "_path,"current data differs")
        quit
        ;
        ; ---------- internal: value quoting ----------
        ;
qval(v) ; M-quote a scalar value: numeric → raw; everything else → "..." with " doubled.
        ; doc: @internal
        ; doc: Driven by serialize().
        if $$isNumeric(v) quit v
        quit """"_$$dq(v)_""""
        ;
isNumeric(v)    ; True iff v is a non-empty canonical numeric M literal.
        ; doc: @internal
        ; doc: Uses M's own canonical-form rule: +v rendered as a string
        ; doc: equals v iff v is already in canonical form.
        if v="" quit 0
        quit $select(+v=v:1,1:0)
        ;
dq(s)   ; Double every " in s — M string-literal escape.
        ; doc: @internal
        ; doc: Same routine as STDCSV's dq but inlined for self-containment.
        new q,n
        set q=""""
        set n=$length(s,q)
        if n<2 quit s
        new out,i
        set out=$piece(s,q,1)
        for i=2:1:n  set out=out_q_q_$piece(s,q,i)
        quit out
