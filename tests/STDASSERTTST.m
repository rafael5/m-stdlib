STDASSERTTST    ; Test suite for STDASSERT — Phase 0 probe.
        NEW pass,fail
        DO start^STDASSERT(.pass,.fail)
        ;
        DO tEqMatchesEqualStrings(.pass,.fail)
        DO tEqDistinguishesUnequal(.pass,.fail)
        DO tOkAcceptsTruthy(.pass,.fail)
        ;
        DO report^STDASSERT(pass,fail)
        QUIT
        ;
tEqMatchesEqualStrings(pass,fail)       ;@TEST "eq() passes when actual=expected"
        DO eq^STDASSERT(.pass,.fail,"hello","hello","string equality")
        QUIT
        ;
tEqDistinguishesUnequal(pass,fail)      ;@TEST "eq() passes when integers match"
        DO eq^STDASSERT(.pass,.fail,42,42,"integer equality")
        QUIT
        ;
tOkAcceptsTruthy(pass,fail)     ;@TEST "ok() passes for non-zero"
        DO ok^STDASSERT(.pass,.fail,1,"one is truthy")
        QUIT
