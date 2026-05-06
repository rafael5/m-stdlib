PXXTST  ; STDASSERT-driven test suite for the PXX VistA package.
        ; m-lint: disable-file=M-MOD-020
        ; ===================================================================
        ; Template — replace PXX with your package's namespace prefix.
        ;   1. Rename this file from PXXTST.m to <YOUR-NS>TST.m.
        ;   2. Replace the example tDemographicsLookup* tests with
        ;      assertions against your package's public API.
        ;   3. If you need fixture data, use STDSEED + STDFIX (see below)
        ;      or a stub filer that captures into a scratch global.
        ; ===================================================================
        ;
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---- example tests — replace with your own ----
        do tHappyPath(.pass,.fail)
        do tEmptyInputReturnsEmpty(.pass,.fail)
        do tRaisesOnInvalidInput(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- example tests ----------
        ;
tHappyPath(pass,fail)   ;@TEST "happy-path: $$publicApi^PXX('valid input') returns expected"
        ; Replace with your package's first happy-path test.
        do eq^STDASSERT(.pass,.fail,"replace-me","replace-me","stub assertion — replace")
        quit
        ;
tEmptyInputReturnsEmpty(pass,fail)      ;@TEST "edge: empty input returns empty"
        ; Replace with your package's empty/edge-case test.
        do eq^STDASSERT(.pass,.fail,"","","stub assertion — replace")
        quit
        ;
tRaisesOnInvalidInput(pass,fail)        ;@TEST "error: invalid input raises U-PXX-INVALID"
        ; Replace with your package's negative-path test. Uses
        ; raises^STDASSERT to verify $ECODE is set; the routine under
        ; test should route errors through a `raise()` helper to keep
        ; the trap in extrinsic context (see m-stdlib STDASSERT.raises
        ; ZGOTO fix in commit 9ee9724 for the precedent).
        do raises^STDASSERT(.pass,.fail,
                . "do publicApi^PXX("""")",
                . "U-PXX-INVALID",
                . "empty argument should raise")
        quit
        ;
        ; ---------- fixture-driven test pattern (uncomment + adapt) ----------
        ;
        ; tFiledRecordHasCorrectName(pass,fail)  ;@TEST "FILE^DIE-loaded patient has the manifest name"
        ;       ; Wrap the whole test in a STDFIX transactional scope —
        ;       ; STDSEED writes via FILE^DIE; the trollback at the end
        ;       ; of `with` rolls those writes back per-test isolation.
        ;       do with^STDFIX("pxx-fixture",
        ;               . "do load^STDSEED(""fixtures/patients.tsv"")"_
        ;               . " do eq^STDASSERT(.pass,.fail,"_
        ;               . "    $$NAME^PXX($$lookupDUZ^PXX(""SMITH,JOHN"")),"_
        ;               . "    ""SMITH,JOHN"","_
        ;               . "    ""seeded patient name round-trips"")")
        ;       quit
        ;
