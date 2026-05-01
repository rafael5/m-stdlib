STDASSERT       ; m-stdlib — assertion library (Phase 0 bootstrap probe).
        ;
        ; Status: PROBE STUB. Replaced by the full STDASSERT in v0.0.1
        ; (per docs/m-stdlib-implementation-plan.md §8.1). Exposes the
        ; minimum API needed to confirm m-cli's `m test` runner accepts
        ; STDASSERT-driven suites under the existing
        ; t<UpperCase>(pass,fail) discovery convention.
        ;
        ; The output protocol mirrors m-tools/^TESTRUN exactly:
        ;   "  PASS  <desc>"            (two leading spaces)
        ;   "  FAIL  <desc>"
        ;   "         expected: <e>"    (nine leading spaces)
        ;   "         actual:   <a>"
        ;   "Results: <total> tests  <p> passed  <f> failed"
        ;   "All tests passed."  -or-  "<n> test(s) FAILED."
        ;
        QUIT
        ;
start(pass,fail)        ; Initialise pass/fail counters (call by-reference).
        SET pass=0,fail=0
        QUIT
        ;
eq(pass,fail,actual,expected,desc)      ; Assert actual=expected.
        IF actual=expected DO pass(.pass,desc) QUIT
        DO fail(.fail,desc,"="_expected,"="_actual)
        QUIT
        ;
ok(pass,fail,cond,desc) ; Assert cond is truthy.
        IF cond DO pass(.pass,desc) QUIT
        DO fail(.fail,desc,"true","false")
        QUIT
        ;
pass(pass,desc) ; Record a passing assertion.
        SET pass=pass+1
        WRITE "  PASS  ",desc,!
        QUIT
        ;
fail(fail,desc,expected,actual) ; Record a failing assertion.
        SET fail=fail+1
        WRITE "  FAIL  ",desc,!
        WRITE "         expected: ",expected,!
        WRITE "         actual:   ",actual,!
        QUIT
        ;
report(pass,fail)       ; Print summary; halt with error if any failures.
        NEW total
        SET total=pass+fail
        WRITE !,"Results: ",total," tests  ",pass," passed  ",fail," failed",!
        IF fail=0 WRITE "All tests passed.",! QUIT
        WRITE fail," test(s) FAILED.",!
        HALT
        QUIT
