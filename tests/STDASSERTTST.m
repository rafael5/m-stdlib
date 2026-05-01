STDASSERTTST    ; Test suite for STDASSERT (v0.0.1).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee, so it reports false
        ; positives against the test idiom. Suppressed file-wide here.
        NEW pass,fail
        DO start^STDASSERT(.pass,.fail)
        ;
        DO tEqPassesEqual(.pass,.fail)
        DO tEqRecordsFailOnUnequal(.pass,.fail)
        DO tNePassesUnequal(.pass,.fail)
        DO tNeRecordsFailOnEqual(.pass,.fail)
        DO tTrueAcceptsNonZero(.pass,.fail)
        DO tTrueAcceptsTruthyString(.pass,.fail)
        DO tTrueRecordsFailOnZero(.pass,.fail)
        DO tFalseAcceptsZero(.pass,.fail)
        DO tFalseRecordsFailOnTruthy(.pass,.fail)
        DO tNearWithinEpsilon(.pass,.fail)
        DO tNearAcceptsExactMatch(.pass,.fail)
        DO tNearRecordsFailOutsideEpsilon(.pass,.fail)
        DO tRaisesMatchesEcode(.pass,.fail)
        DO tRaisesRecordsFailWhenCodeRunsClean(.pass,.fail)
        DO tRaisesRecordsFailOnDifferentEcode(.pass,.fail)
        DO tContainsMatchesSubstring(.pass,.fail)
        DO tContainsRecordsFailWhenAbsent(.pass,.fail)
        DO tLenChecksLength(.pass,.fail)
        DO tLenRecordsFailOnMismatch(.pass,.fail)
        DO tStartZeroesCounters(.pass,.fail)
        DO tSilentSuppressesOutput(.pass,.fail)
        ;
        DO report^STDASSERT(pass,fail)
        QUIT
        ;
tEqPassesEqual(pass,fail)       ;@TEST "eq() passes when actual=expected"
        DO eq^STDASSERT(.pass,.fail,1,1,"trivial integer")
        DO eq^STDASSERT(.pass,.fail,"hello","hello","string equality")
        DO eq^STDASSERT(.pass,.fail,"","","empty string")
        QUIT
        ;
tEqRecordsFailOnUnequal(pass,fail)      ;@TEST "eq() records fail when unequal"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO eq^STDASSERT(.p,.f,1,2,"_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"eq() incremented fail")
        DO eq^STDASSERT(.pass,.fail,p,0,"eq() did not increment pass")
        QUIT
        ;
tNePassesUnequal(pass,fail)     ;@TEST "ne() passes when actual!=expected"
        DO ne^STDASSERT(.pass,.fail,1,2,"1 ne 2")
        DO ne^STDASSERT(.pass,.fail,"a","b","a ne b")
        QUIT
        ;
tNeRecordsFailOnEqual(pass,fail)        ;@TEST "ne() records fail when equal"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO ne^STDASSERT(.p,.f,5,5,"_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"ne() incremented fail on equal")
        QUIT
        ;
tTrueAcceptsNonZero(pass,fail)  ;@TEST "true() accepts non-zero numbers"
        DO true^STDASSERT(.pass,.fail,1,"1 is truthy")
        DO true^STDASSERT(.pass,.fail,42,"42 is truthy")
        DO true^STDASSERT(.pass,.fail,-1,"-1 is truthy")
        QUIT
        ;
tTrueAcceptsTruthyString(pass,fail)     ;@TEST "true() accepts truthy strings"
        ; In M, a string is true if its leading numeric prefix is non-zero.
        DO true^STDASSERT(.pass,.fail,"7abc","leading-digit string is truthy")
        QUIT
        ;
tTrueRecordsFailOnZero(pass,fail)       ;@TEST "true() records fail on zero / empty"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO true^STDASSERT(.p,.f,0,"_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"true() incremented fail on 0")
        QUIT
        ;
tFalseAcceptsZero(pass,fail)    ;@TEST "false() accepts 0 and empty string"
        DO false^STDASSERT(.pass,.fail,0,"0 is falsy")
        DO false^STDASSERT(.pass,.fail,"","empty string is falsy")
        DO false^STDASSERT(.pass,.fail,"abc","leading-non-digit string is falsy")
        QUIT
        ;
tFalseRecordsFailOnTruthy(pass,fail)    ;@TEST "false() records fail on truthy"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO false^STDASSERT(.p,.f,1,"_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"false() incremented fail on 1")
        QUIT
        ;
tNearWithinEpsilon(pass,fail)   ;@TEST "near() accepts |a-b|<=eps"
        DO near^STDASSERT(.pass,.fail,1.0,1.005,0.01,"within 0.01")
        DO near^STDASSERT(.pass,.fail,3.14,3.15,0.05,"within 0.05")
        QUIT
        ;
tNearAcceptsExactMatch(pass,fail)       ;@TEST "near() accepts exact match"
        DO near^STDASSERT(.pass,.fail,5,5,0.0001,"exact integer match")
        QUIT
        ;
tNearRecordsFailOutsideEpsilon(pass,fail)       ;@TEST "near() fails when |a-b|>eps"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO near^STDASSERT(.p,.f,1.0,2.0,0.5,"_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"near() incremented fail outside eps")
        QUIT
        ;
tRaisesMatchesEcode(pass,fail)  ;@TEST "raises() passes when XECUTEd code sets matching $ECODE"
        ; The portable identifier for divide-by-zero is the ANSI M9 code.
        DO raises^STDASSERT(.pass,.fail,"new x set x=1/0",",M9,","DIVZERO ecode")
        QUIT
        ;
tRaisesRecordsFailWhenCodeRunsClean(pass,fail)  ;@TEST "raises() fails when code runs without error"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO raises^STDASSERT(.p,.f,"new x set x=1+1",",M9,","_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"raises() incremented fail on clean run")
        QUIT
        ;
tRaisesRecordsFailOnDifferentEcode(pass,fail)   ;@TEST "raises() fails when $ECODE doesn't match"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO raises^STDASSERT(.p,.f,"new x set x=1/0",",ZNOSUCHCODE,","_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"raises() incremented fail on mismatched code")
        QUIT
        ;
tContainsMatchesSubstring(pass,fail)    ;@TEST "contains() passes when needle is in haystack"
        DO contains^STDASSERT(.pass,.fail,"hello world","world","substring at end")
        DO contains^STDASSERT(.pass,.fail,"hello world","hello","substring at start")
        DO contains^STDASSERT(.pass,.fail,"abc","","empty needle always matches")
        QUIT
        ;
tContainsRecordsFailWhenAbsent(pass,fail)       ;@TEST "contains() fails when needle absent"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO contains^STDASSERT(.p,.f,"hello","xyz","_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"contains() incremented fail on absent needle")
        QUIT
        ;
tLenChecksLength(pass,fail)     ;@TEST "len() compares length values"
        DO len^STDASSERT(.pass,.fail,$length("hello"),5,"hello length 5")
        DO len^STDASSERT(.pass,.fail,$length(""),0,"empty length 0")
        QUIT
        ;
tLenRecordsFailOnMismatch(pass,fail)    ;@TEST "len() fails on mismatched length"
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO len^STDASSERT(.p,.f,$length("hi"),5,"_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,f,1,"len() incremented fail on mismatch")
        QUIT
        ;
tStartZeroesCounters(pass,fail) ;@TEST "start() zeroes pass/fail counters"
        NEW p,f SET p=99,f=99
        DO start^STDASSERT(.p,.f)
        DO eq^STDASSERT(.pass,.fail,p,0,"start() zeroed pass")
        DO eq^STDASSERT(.pass,.fail,f,0,"start() zeroed fail")
        QUIT
        ;
tSilentSuppressesOutput(pass,fail)      ;@TEST "silent(1) suppresses output but still increments counters"
        ; Verifies the silent flag toggles output without losing counter writes.
        NEW p,f SET p=0,f=0
        DO silent^STDASSERT(1)
        DO eq^STDASSERT(.p,.f,1,1,"_")
        DO silent^STDASSERT(0)
        DO eq^STDASSERT(.pass,.fail,p,1,"silent mode still incremented pass")
        DO eq^STDASSERT(.pass,.fail,f,0,"silent mode left fail untouched")
        QUIT
