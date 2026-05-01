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
        QUIT
        ;
start(p,f)      ; Initialise pass/fail counters (call by-reference).
        ; doc: Sets p=0,f=0. Call once at the top of every suite entry.
        ; doc: Example: do start^STDASSERT(.pass,.fail)
        SET p=0,f=0
        KILL ^STDLIB($job,"silent")
        QUIT
        ;
silent(on)      ; Toggle PASS/FAIL output suppression (per-process).
        ; doc: Internal helper for STDASSERT's own self-tests of negative
        ; doc: paths (e.g., proving fail() actually increments). Production
        ; doc: callers should not touch this. Auto-reset by start()/report().
        SET ^STDLIB($job,"silent")=+on
        QUIT
        ;
report(p,f)     ; Print summary; halt with error if any failures.
        ; doc: Emits the "Results:" line m-cli's runner parses.
        ; doc: Halts with non-zero status if f>0 — drives CI exit code.
        NEW total
        SET total=p+f
        KILL ^STDLIB($job,"silent")
        WRITE !,"Results: ",total," tests  ",p," passed  ",f," failed",!
        IF f=0 WRITE "All tests passed.",! QUIT
        WRITE f," test(s) FAILED.",!
        HALT
        QUIT
        ;
eq(p,f,actual,expected,desc)    ; Assert actual=expected (string equality).
        ; doc: Args: p,f counters by-ref; actual,expected scalars; desc string.
        ; doc: Example: do eq^STDASSERT(.pass,.fail,result,"hello","greet test")
        IF actual=expected DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"="_expected,"="_actual)
        QUIT
        ;
ne(p,f,actual,expected,desc)    ; Assert actual'=expected (string inequality).
        ; doc: Inverse of eq(). Useful for "must differ" assertions.
        ; doc: Example: do ne^STDASSERT(.pass,.fail,oldId,newId,"id rotated")
        IF actual'=expected DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"!="_expected,"="_actual)
        QUIT
        ;
true(p,f,cond,desc)     ; Assert cond is truthy (non-zero numeric prefix).
        ; doc: M truthiness: leading numeric prefix !=0 is true; else false.
        ; doc: Example: do true^STDASSERT(.pass,.fail,$data(arr),"arr defined")
        IF +cond DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"truthy","="_cond)
        QUIT
        ;
false(p,f,cond,desc)    ; Assert cond is falsy (zero numeric prefix or empty).
        ; doc: Inverse of true(). Empty string and "abc" are both falsy.
        ; doc: Example: do false^STDASSERT(.pass,.fail,$data(missing),"missing undef")
        IF 'cond DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"falsy","="_cond)
        QUIT
        ;
near(p,f,a,b,eps,desc)  ; Assert |a-b|<=eps (float comparison).
        ; doc: Use for fractional comparisons where exact equality is fragile.
        ; doc: Example: do near^STDASSERT(.pass,.fail,sum,3.14,0.01,"approx pi")
        NEW diff
        SET diff=$select(a>b:a-b,1:b-a)
        IF diff'>eps DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"~="_b_" (eps="_eps_")",a)
        QUIT
        ;
raises(p,f,code,errno,desc)     ; Assert XECUTEing 'code' sets $ECODE containing 'errno'.
        ; doc: errno is matched as a substring of $ECODE (M's "[" operator).
        ; doc: For YDB DIVZERO use "Z150373058"; for general "M9" use ",M9,".
        ; doc: Example: do raises^STDASSERT(.pass,.fail,"set x=1/0","Z150373058","divzero")
        ; $ECODE is a special variable and cannot be NEWed; we clear it
        ; explicitly before and after, and use $ETRAP to capture.
        NEW $etrap,captured
        SET captured="",$ecode=""
        SET $etrap="set captured=$ecode set $ecode="""" quit"
        ; m-lint: disable-next-line=M-MOD-036
        XECUTE code  ; XECUTE-of-arg is the documented purpose of raises().
        SET $ecode=""
        IF captured'="",captured[errno DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"$ECODE containing "_errno,$select(captured="":"<no error>",1:captured))
        QUIT
        ;
contains(p,f,haystack,needle,desc)      ; Assert haystack contains needle (M's "[" operator).
        ; doc: Empty needle always matches (M semantics).
        ; doc: Example: do contains^STDASSERT(.pass,.fail,output,"OK","status line")
        IF haystack[needle DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"to contain "_$$quote(needle),$$quote(haystack))
        QUIT
        ;
len(p,f,actual,n,desc)  ; Assert actual=n (length comparison helper).
        ; doc: Caller computes the length; this just compares two integers.
        ; doc: Example: do len^STDASSERT(.pass,.fail,$length(s),5,"5-char string")
        IF actual=n DO recordPass(.p,desc) QUIT
        DO recordFail(.f,desc,"length "_n,"length "_actual)
        QUIT
        ;
        ; --- internal helpers ----------------------------------------
        ;
recordPass(p,desc)      ; Increment p and emit "  PASS  <desc>".
        ; doc: Internal — used by every assertion. Single point of truth
        ; doc: for the runner-visible PASS line.
        SET p=$increment(p)
        IF $get(^STDLIB($job,"silent")) QUIT
        WRITE "  PASS  ",desc,!
        QUIT
        ;
recordFail(f,desc,expected,actual)      ; Increment f and emit FAIL block.
        ; doc: Internal — used by every assertion. Three-line FAIL block
        ; doc: matches the m-cli runner's regex (runner.py:76-78).
        SET f=$increment(f)
        IF $get(^STDLIB($job,"silent")) QUIT
        WRITE "  FAIL  ",desc,!
        WRITE "         expected: ",expected,!
        WRITE "         actual:   ",actual,!
        QUIT
        ;
quote(s)        ; Return s wrapped in double quotes for diagnostic output.
        ; doc: Internal — used by contains() to make whitespace visible.
        QUIT """"_s_""""
