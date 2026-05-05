STDASSERTTST    ; Test suite for STDASSERT (v0.0.1).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee, so it reports false
        ; positives against the test idiom. Suppressed file-wide here.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tEqPassesEqual(.pass,.fail)
        do tEqRecordsFailOnUnequal(.pass,.fail)
        do tNePassesUnequal(.pass,.fail)
        do tNeRecordsFailOnEqual(.pass,.fail)
        do tTrueAcceptsNonZero(.pass,.fail)
        do tTrueAcceptsTruthyString(.pass,.fail)
        do tTrueRecordsFailOnZero(.pass,.fail)
        do tFalseAcceptsZero(.pass,.fail)
        do tFalseRecordsFailOnTruthy(.pass,.fail)
        do tNearWithinEpsilon(.pass,.fail)
        do tNearAcceptsExactMatch(.pass,.fail)
        do tNearRecordsFailOutsideEpsilon(.pass,.fail)
        do tRaisesMatchesEcode(.pass,.fail)
        do tRaisesRecordsFailWhenCodeRunsClean(.pass,.fail)
        do tRaisesRecordsFailOnDifferentEcode(.pass,.fail)
        do tContainsMatchesSubstring(.pass,.fail)
        do tContainsRecordsFailWhenAbsent(.pass,.fail)
        do tLenChecksLength(.pass,.fail)
        do tLenRecordsFailOnMismatch(.pass,.fail)
        do tStartZeroesCounters(.pass,.fail)
        do tSilentSuppressesOutput(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tEqPassesEqual(pass,fail)       ;@TEST "eq() passes when actual=expected"
        do eq^STDASSERT(.pass,.fail,1,1,"trivial integer")
        do eq^STDASSERT(.pass,.fail,"hello","hello","string equality")
        do eq^STDASSERT(.pass,.fail,"","","empty string")
        quit
        ;
tEqRecordsFailOnUnequal(pass,fail)      ;@TEST "eq() records fail when unequal"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do eq^STDASSERT(.p,.f,1,2,"_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"eq() incremented fail")
        do eq^STDASSERT(.pass,.fail,p,0,"eq() did not increment pass")
        quit
        ;
tNePassesUnequal(pass,fail)     ;@TEST "ne() passes when actual!=expected"
        do ne^STDASSERT(.pass,.fail,1,2,"1 ne 2")
        do ne^STDASSERT(.pass,.fail,"a","b","a ne b")
        quit
        ;
tNeRecordsFailOnEqual(pass,fail)        ;@TEST "ne() records fail when equal"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do ne^STDASSERT(.p,.f,5,5,"_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"ne() incremented fail on equal")
        quit
        ;
tTrueAcceptsNonZero(pass,fail)  ;@TEST "true() accepts non-zero numbers"
        do true^STDASSERT(.pass,.fail,1,"1 is truthy")
        do true^STDASSERT(.pass,.fail,42,"42 is truthy")
        do true^STDASSERT(.pass,.fail,-1,"-1 is truthy")
        quit
        ;
tTrueAcceptsTruthyString(pass,fail)     ;@TEST "true() accepts truthy strings"
        ; In M, a string is true if its leading numeric prefix is non-zero.
        do true^STDASSERT(.pass,.fail,"7abc","leading-digit string is truthy")
        quit
        ;
tTrueRecordsFailOnZero(pass,fail)       ;@TEST "true() records fail on zero / empty"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do true^STDASSERT(.p,.f,0,"_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"true() incremented fail on 0")
        quit
        ;
tFalseAcceptsZero(pass,fail)    ;@TEST "false() accepts 0 and empty string"
        do false^STDASSERT(.pass,.fail,0,"0 is falsy")
        do false^STDASSERT(.pass,.fail,"","empty string is falsy")
        do false^STDASSERT(.pass,.fail,"abc","leading-non-digit string is falsy")
        quit
        ;
tFalseRecordsFailOnTruthy(pass,fail)    ;@TEST "false() records fail on truthy"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do false^STDASSERT(.p,.f,1,"_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"false() incremented fail on 1")
        quit
        ;
tNearWithinEpsilon(pass,fail)   ;@TEST "near() accepts |a-b|<=eps"
        do near^STDASSERT(.pass,.fail,1.0,1.005,0.01,"within 0.01")
        do near^STDASSERT(.pass,.fail,3.14,3.15,0.05,"within 0.05")
        quit
        ;
tNearAcceptsExactMatch(pass,fail)       ;@TEST "near() accepts exact match"
        do near^STDASSERT(.pass,.fail,5,5,0.0001,"exact integer match")
        quit
        ;
tNearRecordsFailOutsideEpsilon(pass,fail)       ;@TEST "near() fails when |a-b|>eps"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do near^STDASSERT(.p,.f,1.0,2.0,0.5,"_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"near() incremented fail outside eps")
        quit
        ;
tRaisesMatchesEcode(pass,fail)  ;@TEST "raises() passes when XECUTEd code sets matching $ECODE"
        ; The portable identifier for divide-by-zero is the ANSI M9 code.
        do raises^STDASSERT(.pass,.fail,"new x set x=1/0",",M9,","DIVZERO ecode")
        quit
        ;
tRaisesRecordsFailWhenCodeRunsClean(pass,fail)  ;@TEST "raises() fails when code runs without error"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do raises^STDASSERT(.p,.f,"new x set x=1+1",",M9,","_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"raises() incremented fail on clean run")
        quit
        ;
tRaisesRecordsFailOnDifferentEcode(pass,fail)   ;@TEST "raises() fails when $ECODE doesn't match"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do raises^STDASSERT(.p,.f,"new x set x=1/0",",ZNOSUCHCODE,","_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"raises() incremented fail on mismatched code")
        quit
        ;
tContainsMatchesSubstring(pass,fail)    ;@TEST "contains() passes when needle is in haystack"
        do contains^STDASSERT(.pass,.fail,"hello world","world","substring at end")
        do contains^STDASSERT(.pass,.fail,"hello world","hello","substring at start")
        do contains^STDASSERT(.pass,.fail,"abc","","empty needle always matches")
        quit
        ;
tContainsRecordsFailWhenAbsent(pass,fail)       ;@TEST "contains() fails when needle absent"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do contains^STDASSERT(.p,.f,"hello","xyz","_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"contains() incremented fail on absent needle")
        quit
        ;
tLenChecksLength(pass,fail)     ;@TEST "len() compares length values"
        do len^STDASSERT(.pass,.fail,$length("hello"),5,"hello length 5")
        do len^STDASSERT(.pass,.fail,$length(""),0,"empty length 0")
        quit
        ;
tLenRecordsFailOnMismatch(pass,fail)    ;@TEST "len() fails on mismatched length"
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do len^STDASSERT(.p,.f,$length("hi"),5,"_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,f,1,"len() incremented fail on mismatch")
        quit
        ;
tStartZeroesCounters(pass,fail) ;@TEST "start() zeroes pass/fail counters"
        new p,f set p=99,f=99
        do start^STDASSERT(.p,.f)
        do eq^STDASSERT(.pass,.fail,p,0,"start() zeroed pass")
        do eq^STDASSERT(.pass,.fail,f,0,"start() zeroed fail")
        quit
        ;
tSilentSuppressesOutput(pass,fail)      ;@TEST "silent(1) suppresses output but still increments counters"
        ; Verifies the silent flag toggles output without losing counter writes.
        new p,f set p=0,f=0
        do silent^STDASSERT(1)
        do eq^STDASSERT(.p,.f,1,1,"_")
        do silent^STDASSERT(0)
        do eq^STDASSERT(.pass,.fail,p,1,"silent mode still incremented pass")
        do eq^STDASSERT(.pass,.fail,f,0,"silent mode left fail untouched")
        quit
