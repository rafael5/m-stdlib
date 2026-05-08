STDXFRM ; m-stdlib — Higher-order array transforms (map / filter / reduce via @-indirection lambdas).
        ; m-lint: disable-file=M-MOD-036
        ; M-MOD-036 flags M's `@` indirection on a "tainted" local — but
        ; XECUTE-via-@ of a caller-supplied expression IS the contract of
        ; this module: the lambda is the abstraction. Same shape as STDMOCK's
        ; `do @resolved@(.args)` and STDFIX's `xecute @cleanupCmd`.
        ;
        ; Public entry points:
        ;   do map^STDXFRM(.in, expr, .out)      — out(k) := <expr> for each k
        ;   do filter^STDXFRM(.in, expr, .out)   — copy in(k)→out(k) iff <expr>
        ;   $$reduce^STDXFRM(.in, expr, init)    — fold left; <expr> is new acc
        ;
        ; The lambda string `expr` is evaluated via `@expr` in this module's
        ; stack frame, so it sees these locals:
        ;   value  — the current element's value (in(k))
        ;   key    — the current subscript (k)
        ;   acc    — (reduce only) the accumulator carried forward
        ;
        ; Walk discipline:
        ;   - $ORDER-walk at depth 1 only (the canonical "1-D vector" shape).
        ;   - Subscript shape doesn't matter — int, string, sparse all work.
        ;   - For map/filter, `out` is killed before the walk so stale
        ;     leftovers from a prior call do not leak through.
        ;   - For reduce, the empty-input case returns `init` unchanged.
        ;
        ; Error semantics: if `expr` raises (compile error, $ECODE set,
        ; division by zero, etc.) the error propagates to the caller's
        ; $ETRAP unmodified. STDXFRM does not catch.
        ;
        ; Pure-M throughout — no $Z* extensions. Runs unchanged on YDB and
        ; IRIS. The @-indirection idiom is ANSI standard since the M[UMPS]
        ; X11.1 standard.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
map(in,expr,out)        ; out(k) := <expr> for each k in $ORDER(in,k).
        ; doc: @param in      array   by-ref local; source array (depth 1)
        ; doc: @param expr    string  M expression; locals `value` and `key` available
        ; doc: @param out     array   by-ref local; killed then populated as out(k)
        ; doc: @example       new a,out  set a(1)=1,a(2)=2,a(3)=3  do map^STDXFRM(.a,"value*2",.out)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do filter^STDXFRM, $$reduce^STDXFRM
        ; doc: Lambda locals visible to expr: `value` (in(k)) and `key` (k).
        kill out
        new k,value,key,result,cmd
        set cmd="set result="_expr
        set result="",k=""
        for  set k=$order(in(k)) quit:k=""  do
        . set value=in(k),key=k
        . xecute cmd
        . set out(k)=result
        quit
        ;
filter(in,expr,out)     ; Copy in(k)→out(k) iff <expr> is truthy.
        ; doc: @param in      array   by-ref local; source array
        ; doc: @param expr    string  M predicate expression; `value` and `key` visible
        ; doc: @param out     array   by-ref local; killed then populated with kept entries
        ; doc: @example       do filter^STDXFRM(.a,"value>10",.out)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do map^STDXFRM, $$reduce^STDXFRM
        ; doc: Subscripts are preserved. Values are copied verbatim.
        kill out
        new k,value,key,keep,cmd
        set cmd="set keep="_expr
        set keep="",k=""
        for  set k=$order(in(k)) quit:k=""  do
        . set value=in(k),key=k
        . xecute cmd
        . if keep set out(k)=in(k)
        quit
        ;
reduce(in,expr,init)    ; Fold left: walk in, evaluate expr with `acc`+`value`+`key`.
        ; doc: @param in      array   by-ref local; source array
        ; doc: @param expr    string  M expression; locals `acc`, `value`, `key` available
        ; doc: @param init    string  initial accumulator
        ; doc: @returns       string  final accumulator (init if `in` is empty)
        ; doc: @example       write $$reduce^STDXFRM(.a,"acc+value",0)  ; sum
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do map^STDXFRM, do filter^STDXFRM
        new k,value,key,acc,cmd
        set cmd="set acc="_expr
        set acc=init,k=""
        for  set k=$order(in(k)) quit:k=""  do
        . set value=in(k),key=k
        . xecute cmd
        quit acc
