STDASSERT       ; m-stdlib — assertion library (v0.0.1).
        ;
        ; Output protocol mirrors m-tools/^TESTRUN exactly so m-cli's
        ; `m test` runner accepts STDASSERT-driven suites unchanged:
        ;   "  PASS  <desc>"            (two leading spaces)
        ;   "  FAIL  <desc>"
        ;   "         expected: <e>"    (nine leading spaces)
        ;   "         actual:   <a>"
        ;   "Results: <total> tests  <p> passed  <f> failed"
        ;   "All tests passed."  -or-  "<n> test(s) FAILED."
        ;
        ; Suite shape:
        ;   STDASSERTTST    ;
        ;           new pass,fail
        ;           do start^STDASSERT(.pass,.fail)
        ;           do tMyCase(.pass,.fail)
        ;           do report^STDASSERT(pass,fail)
        ;           quit
        ;
        quit
        ;
start(p,f)      ; Initialise pass/fail counters (call by-reference).
        ; doc: @param p       int     pass counter (by-ref; set to 0)
        ; doc: @param f       int     fail counter (by-ref; set to 0)
        ; doc: @example       do start^STDASSERT(.pass,.fail)
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           do report^STDASSERT, do eq^STDASSERT
        ; doc: Call once at the top of every suite entry.
        set p=0,f=0
        kill ^STDLIB($job,"silent")
        quit
        ;
silent(on)      ; Toggle PASS/FAIL output suppression (per-process).
        ; doc: @internal
        ; doc: Helper for STDASSERT's own self-tests of negative paths
        ; doc: (e.g., proving fail() actually increments). Production
        ; doc: callers should not touch this. Auto-reset by start()/report().
        set ^STDLIB($job,"silent")=+on
        quit
        ;
report(p,f)     ; Print summary; halt with error if any failures.
        ; doc: @param p       int     pass count
        ; doc: @param f       int     fail count
        ; doc: @example       do report^STDASSERT(pass,fail)
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           do start^STDASSERT
        ; doc: Emits the "Results:" line m-cli's runner parses.
        ; doc: Halts with non-zero status if f>0 — drives CI exit code.
        new total
        set total=p+f
        kill ^STDLIB($job,"silent")
        write !,"Results: ",total," tests  ",p," passed  ",f," failed",!
        if f=0 write "All tests passed.",! quit
        write f," test(s) FAILED.",!
        halt
        quit
        ;
eq(p,f,actual,expected,desc)    ; Assert actual=expected (string equality).
        ; doc: @param p          int     pass counter (by-ref)
        ; doc: @param f          int     fail counter (by-ref)
        ; doc: @param actual     string  observed value
        ; doc: @param expected   string  expected value
        ; doc: @param desc       string  human-readable assertion description
        ; doc: @example          do eq^STDASSERT(.pass,.fail,result,"hello","greet test")
        ; doc: @since            v0.0.1
        ; doc: @stable           stable
        ; doc: @see              do ne^STDASSERT, do near^STDASSERT
        if actual=expected do recordPass(.p,desc) quit
        do recordFail(.f,desc,"="_expected,"="_actual)
        quit
        ;
ne(p,f,actual,expected,desc)    ; Assert actual'=expected (string inequality).
        ; doc: @param p          int     pass counter (by-ref)
        ; doc: @param f          int     fail counter (by-ref)
        ; doc: @param actual     string  observed value
        ; doc: @param expected   string  value `actual` must NOT equal
        ; doc: @param desc       string  human-readable description
        ; doc: @example          do ne^STDASSERT(.pass,.fail,oldId,newId,"id rotated")
        ; doc: @since            v0.0.1
        ; doc: @stable           stable
        ; doc: @see              do eq^STDASSERT
        if actual'=expected do recordPass(.p,desc) quit
        do recordFail(.f,desc,"!="_expected,"="_actual)
        quit
        ;
true(p,f,cond,desc)     ; Assert cond is truthy (non-zero numeric prefix).
        ; doc: @param p     int     pass counter (by-ref)
        ; doc: @param f     int     fail counter (by-ref)
        ; doc: @param cond  string  condition (M truthiness)
        ; doc: @param desc  string  description
        ; doc: @example     do true^STDASSERT(.pass,.fail,$data(arr),"arr defined")
        ; doc: @since       v0.0.1
        ; doc: @stable      stable
        ; doc: @see         do false^STDASSERT
        if +cond do recordPass(.p,desc) quit
        do recordFail(.f,desc,"truthy","="_cond)
        quit
        ;
false(p,f,cond,desc)    ; Assert cond is falsy (zero numeric prefix or empty).
        ; doc: @param p     int     pass counter (by-ref)
        ; doc: @param f     int     fail counter (by-ref)
        ; doc: @param cond  string  condition (M falsiness)
        ; doc: @param desc  string  description
        ; doc: @example     do false^STDASSERT(.pass,.fail,$data(missing),"missing undef")
        ; doc: @since       v0.0.1
        ; doc: @stable      stable
        ; doc: @see         do true^STDASSERT
        ; doc: Empty string and "abc" are both falsy.
        if 'cond do recordPass(.p,desc) quit
        do recordFail(.f,desc,"falsy","="_cond)
        quit
        ;
near(p,f,a,b,eps,desc)  ; Assert |a-b|<=eps (float comparison).
        ; doc: @param p     int     pass counter (by-ref)
        ; doc: @param f     int     fail counter (by-ref)
        ; doc: @param a     num     first value
        ; doc: @param b     num     second value
        ; doc: @param eps   num     tolerance (max allowed |a-b|)
        ; doc: @param desc  string  description
        ; doc: @example     do near^STDASSERT(.pass,.fail,sum,3.14,0.01,"approx pi")
        ; doc: @since       v0.0.1
        ; doc: @stable      stable
        ; doc: @see         do eq^STDASSERT
        ; doc: Use for fractional comparisons where exact equality is fragile.
        new diff
        set diff=$select(a>b:a-b,1:b-a)
        if diff'>eps do recordPass(.p,desc) quit
        do recordFail(.f,desc,"~="_b_" (eps="_eps_")",a)
        quit
        ;
raises(p,f,code,errno,desc)     ; Assert XECUTEing 'code' sets $ECODE containing 'errno'.
        ; doc: @param p      int     pass counter (by-ref)
        ; doc: @param f      int     fail counter (by-ref)
        ; doc: @param code   string  M code XECUTEd inside the assertion frame
        ; doc: @param errno  string  substring expected to appear in $ECODE
        ; doc: @param desc   string  description
        ; doc: @example      do raises^STDASSERT(.pass,.fail,"set x=1/0","Z150373058","divzero")
        ; doc: @since        v0.0.1
        ; doc: @stable       stable
        ; doc: @see          do contains^STDASSERT
        ; doc: errno is matched as a substring (M's "[" operator). For YDB
        ; doc: DIVZERO use "Z150373058"; for general "M9" use ",M9,".
        ; $ECODE is a special variable and cannot be NEWed; we clear it
        ; explicitly before and after, and use $ETRAP+ZGOTO to unwind cleanly
        ; out of arbitrary extrinsic depth (the trap's arg-less QUIT is
        ; illegal in extrinsic context — fires M17 NOTEXTRINSIC). ZGOTO N
        ; unwinds the stack to $ZLEVEL=N before the GOTO, so capture our
        ; level at $ETRAP-set time and use that as the unwind target.
        ;
        ; The `use $principal` in the trap is load-bearing: when an error
        ; fires deep in the XECUTEd code while a non-principal SEQ device
        ; is current (e.g. an OPENed file mid-read inside walk^STDSEED),
        ; the ZGOTO unwind otherwise hangs. Restoring $principal first
        ; releases the device-context lock and lets the unwind complete
        ; cleanly. Diagnosed against STDSEEDTST tLoadFilerErrorPropagates-
        ; Ecode 2026-05-07.
        new $etrap,captured,raisesLvl
        set captured="",$ecode=""
        set raisesLvl=$zlevel
        set $etrap="use $principal set captured=$ecode set $ecode="""" zgoto "_raisesLvl_":raisesUnwound^STDASSERT"
        ; m-lint: disable-next-line=M-MOD-036
        xecute code  ; XECUTE-of-arg is the documented purpose of raises().
raisesUnwound   ; Trap-resume target — also reached on no-error fall-through.
        ; doc: @internal
        ; doc: Never an external entry point. The locals it reads come
        ; doc: from raises()'s frame, restored intact after ZGOTO unwinds.
        set $ecode=""
        ; m-lint: disable-next-line=M-MOD-024
        if captured'="",captured[errno do recordPass(.p,desc) quit
        ; m-lint: disable-next-line=M-MOD-024
        do recordFail(.f,desc,"$ECODE containing "_errno,$select(captured="":"<no error>",1:captured))
        quit
        ;
contains(p,f,haystack,needle,desc)      ; Assert haystack contains needle (M's "[" operator).
        ; doc: @param p          int     pass counter (by-ref)
        ; doc: @param f          int     fail counter (by-ref)
        ; doc: @param haystack   string  string to search
        ; doc: @param needle     string  substring to find (empty always matches)
        ; doc: @param desc       string  description
        ; doc: @example          do contains^STDASSERT(.pass,.fail,output,"OK","status line")
        ; doc: @since            v0.0.1
        ; doc: @stable           stable
        ; doc: @see              do raises^STDASSERT
        if haystack[needle do recordPass(.p,desc) quit
        do recordFail(.f,desc,"to contain "_$$quote(needle),$$quote(haystack))
        quit
        ;
len(p,f,actual,n,desc)  ; Assert actual=n (length comparison helper).
        ; doc: @param p       int     pass counter (by-ref)
        ; doc: @param f       int     fail counter (by-ref)
        ; doc: @param actual  int     observed length
        ; doc: @param n       int     expected length
        ; doc: @param desc    string  description
        ; doc: @example       do len^STDASSERT(.pass,.fail,$length(s),5,"5-char string")
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           do eq^STDASSERT
        if actual=n do recordPass(.p,desc) quit
        do recordFail(.f,desc,"length "_n,"length "_actual)
        quit
        ;
        ; --- internal helpers ----------------------------------------
        ;
recordPass(p,desc)      ; Increment p and emit "  PASS  <desc>".
        ; doc: @internal
        ; doc: Used by every assertion. Single point of truth for the
        ; doc: runner-visible PASS line.
        set p=$increment(p)
        if $get(^STDLIB($job,"silent")) quit
        write "  PASS  ",desc,!
        quit
        ;
recordFail(f,desc,expected,actual)      ; Increment f and emit FAIL block.
        ; doc: @internal
        ; doc: Used by every assertion. Three-line FAIL block matches
        ; doc: the m-cli runner's regex (runner.py:76-78).
        set f=$increment(f)
        if $get(^STDLIB($job,"silent")) quit
        write "  FAIL  ",desc,!
        write "         expected: ",expected,!
        write "         actual:   ",actual,!
        quit
        ;
quote(s)        ; Return s wrapped in double quotes for diagnostic output.
        ; doc: @internal
        ; doc: Used by contains() to make whitespace visible.
        quit """"_s_""""
