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
        ; doc: An empty tree (no defined subscripts) returns "".
        ; doc: Trailing LF is *not* emitted — keeps round-trip clean against
        ; doc: writeFile/readFile, which add and strip a trailing LF.
        ; doc: Example: write $$serialize^STDSNAP(.cfg)
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
        ; doc: Sets $ECODE=,U-STDFS-OPEN-FAIL, on write failure (propagated
        ; doc: from STDFS).
        ; doc: Example: do save^STDSNAP("snapshots/cfg.snap",.cfg)
        new text
        set text=$$serialize(.data)
        do writeFile^STDFS(path,text)
        quit
        ;
matches(path,data)      ; Return 1 iff serialize(data) equals the file's content.
        ; doc: A missing file returns 0 (no match — first run typically calls
        ; doc: save() to seed the snapshot before relying on matches).
        ; doc: Example: write $$matches^STDSNAP("snapshots/cfg.snap",.cfg)
        new fileText,curText
        if '$$exists^STDFS(path) quit 0
        set fileText=$$readFile^STDFS(path)
        set curText=$$serialize(.data)
        quit $select(fileText=curText:1,1:0)
        ;
asserts(p,f,path,data,desc)     ; STDASSERT-style snapshot assertion.
        ; doc: On match: increments p and emits PASS via STDASSERT.
        ; doc: On mismatch: increments f and emits FAIL with a brief diagnostic
        ; doc: noting the snapshot path (full diff is the file vs current text;
        ; doc: caller can shell out to `diff` for the byte-level inspection).
        ; doc: Example: do asserts^STDSNAP(.pass,.fail,"cfg.snap",.cfg,"config matches baseline")
        ; doc:
        ; doc: Update mode: when ^STDLIB($job,"stdsnap","update")=1, asserts()
        ; doc: writes the current snapshot to `path` (overwriting any existing
        ; doc: file) and records PASS instead of comparing. Used by m-cli's
        ; doc: `m test --update-snapshots` to regenerate baselines after an
        ; doc: intentional change in test output. Update mode never fails —
        ; doc: a write error still fires the underlying STDFS error trap.
        if $get(^STDLIB($job,"stdsnap","update")) do save(path,.data) do recordPass^STDASSERT(.p,desc_" [snapshot updated]") quit
        if $$matches(path,.data) do recordPass^STDASSERT(.p,desc) quit
        do recordFail^STDASSERT(.f,desc,"snapshot at "_path,"current data differs")
        quit
        ;
        ; ---------- internal: value quoting ----------
        ;
qval(v) ; M-quote a scalar value: numeric → raw; everything else → "..." with " doubled.
        ; doc: Internal — driven by serialize().
        if $$isNumeric(v) quit v
        quit """"_$$dq(v)_""""
        ;
isNumeric(v)    ; True iff v is a non-empty canonical numeric M literal.
        ; doc: Internal — uses M's own canonical-form rule: +v rendered as a
        ; doc: string equals v iff v is already in canonical form.
        if v="" quit 0
        quit $select(+v=v:1,1:0)
        ;
dq(s)   ; Double every " in s — M string-literal escape.
        ; doc: Internal — same routine as STDCSV's dq but inlined for self-containment.
        new q,n
        set q=""""
        set n=$length(s,q)
        if n<2 quit s
        new out,i
        set out=$piece(s,q,1)
        for i=2:1:n  set out=out_q_q_$piece(s,q,i)
        quit out
