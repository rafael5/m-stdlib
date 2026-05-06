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
        ; doc: Sets p=0,f=0. Call once at the top of every suite entry.
        ; doc: Example: do start^STDASSERT(.pass,.fail)
        set p=0,f=0
        kill ^STDLIB($job,"silent")
        quit
        ;
silent(on)      ; Toggle PASS/FAIL output suppression (per-process).
        ; doc: Internal helper for STDASSERT's own self-tests of negative
        ; doc: paths (e.g., proving fail() actually increments). Production
        ; doc: callers should not touch this. Auto-reset by start()/report().
        set ^STDLIB($job,"silent")=+on
        quit
        ;
report(p,f)     ; Print summary; halt with error if any failures.
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
        ; doc: Args: p,f counters by-ref; actual,expected scalars; desc string.
        ; doc: Example: do eq^STDASSERT(.pass,.fail,result,"hello","greet test")
        if actual=expected do recordPass(.p,desc) quit
        do recordFail(.f,desc,"="_expected,"="_actual)
        quit
        ;
ne(p,f,actual,expected,desc)    ; Assert actual'=expected (string inequality).
        ; doc: Inverse of eq(). Useful for "must differ" assertions.
        ; doc: Example: do ne^STDASSERT(.pass,.fail,oldId,newId,"id rotated")
        if actual'=expected do recordPass(.p,desc) quit
        do recordFail(.f,desc,"!="_expected,"="_actual)
        quit
        ;
true(p,f,cond,desc)     ; Assert cond is truthy (non-zero numeric prefix).
        ; doc: M truthiness: leading numeric prefix !=0 is true; else false.
        ; doc: Example: do true^STDASSERT(.pass,.fail,$data(arr),"arr defined")
        if +cond do recordPass(.p,desc) quit
        do recordFail(.f,desc,"truthy","="_cond)
        quit
        ;
false(p,f,cond,desc)    ; Assert cond is falsy (zero numeric prefix or empty).
        ; doc: Inverse of true(). Empty string and "abc" are both falsy.
        ; doc: Example: do false^STDASSERT(.pass,.fail,$data(missing),"missing undef")
        if 'cond do recordPass(.p,desc) quit
        do recordFail(.f,desc,"falsy","="_cond)
        quit
        ;
near(p,f,a,b,eps,desc)  ; Assert |a-b|<=eps (float comparison).
        ; doc: Use for fractional comparisons where exact equality is fragile.
        ; doc: Example: do near^STDASSERT(.pass,.fail,sum,3.14,0.01,"approx pi")
        new diff
        set diff=$select(a>b:a-b,1:b-a)
        if diff'>eps do recordPass(.p,desc) quit
        do recordFail(.f,desc,"~="_b_" (eps="_eps_")",a)
        quit
        ;
raises(p,f,code,errno,desc)     ; Assert XECUTEing 'code' sets $ECODE containing 'errno'.
        ; doc: errno is matched as a substring of $ECODE (M's "[" operator).
        ; doc: For YDB DIVZERO use "Z150373058"; for general "M9" use ",M9,".
        ; doc: Example: do raises^STDASSERT(.pass,.fail,"set x=1/0","Z150373058","divzero")
        ; $ECODE is a special variable and cannot be NEWed; we clear it
        ; explicitly before and after, and use $ETRAP+ZGOTO to unwind cleanly
        ; out of arbitrary extrinsic depth (the trap's arg-less QUIT is
        ; illegal in extrinsic context — fires M17 NOTEXTRINSIC). ZGOTO N
        ; unwinds the stack to $ZLEVEL=N before the GOTO, so capture our
        ; level at $ETRAP-set time and use that as the unwind target.
        new $etrap,captured,raisesLvl
        set captured="",$ecode=""
        set raisesLvl=$zlevel
        set $etrap="set captured=$ecode set $ecode="""" zgoto "_raisesLvl_":raisesUnwound^STDASSERT"
        ; m-lint: disable-next-line=M-MOD-036
        xecute code  ; XECUTE-of-arg is the documented purpose of raises().
raisesUnwound   ; Trap-resume target — also reached on no-error fall-through.
        ; doc: Internal — never an external entry point. The linter sees it
        ; doc: as a label without formals; the `captured`, `errno`, `desc`
        ; doc: locals it reads come from raises()'s frame, restored intact
        ; doc: after ZGOTO unwinds to that level.
        set $ecode=""
        ; m-lint: disable-next-line=M-MOD-024
        if captured'="",captured[errno do recordPass(.p,desc) quit
        ; m-lint: disable-next-line=M-MOD-024
        do recordFail(.f,desc,"$ECODE containing "_errno,$select(captured="":"<no error>",1:captured))
        quit
        ;
contains(p,f,haystack,needle,desc)      ; Assert haystack contains needle (M's "[" operator).
        ; doc: Empty needle always matches (M semantics).
        ; doc: Example: do contains^STDASSERT(.pass,.fail,output,"OK","status line")
        if haystack[needle do recordPass(.p,desc) quit
        do recordFail(.f,desc,"to contain "_$$quote(needle),$$quote(haystack))
        quit
        ;
len(p,f,actual,n,desc)  ; Assert actual=n (length comparison helper).
        ; doc: Caller computes the length; this just compares two integers.
        ; doc: Example: do len^STDASSERT(.pass,.fail,$length(s),5,"5-char string")
        if actual=n do recordPass(.p,desc) quit
        do recordFail(.f,desc,"length "_n,"length "_actual)
        quit
        ;
        ; --- internal helpers ----------------------------------------
        ;
recordPass(p,desc)      ; Increment p and emit "  PASS  <desc>".
        ; doc: Internal — used by every assertion. Single point of truth
        ; doc: for the runner-visible PASS line.
        set p=$increment(p)
        if $get(^STDLIB($job,"silent")) quit
        write "  PASS  ",desc,!
        quit
        ;
recordFail(f,desc,expected,actual)      ; Increment f and emit FAIL block.
        ; doc: Internal — used by every assertion. Three-line FAIL block
        ; doc: matches the m-cli runner's regex (runner.py:76-78).
        set f=$increment(f)
        if $get(^STDLIB($job,"silent")) quit
        write "  FAIL  ",desc,!
        write "         expected: ",expected,!
        write "         actual:   ",actual,!
        quit
        ;
quote(s)        ; Return s wrapped in double quotes for diagnostic output.
        ; doc: Internal — used by contains() to make whitespace visible.
        quit """"_s_""""
