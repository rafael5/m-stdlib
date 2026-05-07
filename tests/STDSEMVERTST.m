STDSEMVERTST    ; Test suite for STDSEMVER (v0.2.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tValidPlainTriple(.pass,.fail)
        do tValidWithPrerelease(.pass,.fail)
        do tValidWithBuild(.pass,.fail)
        do tValidWithBoth(.pass,.fail)
        do tValidPrereleaseDottedIds(.pass,.fail)
        do tValidLargeNumbers(.pass,.fail)
        do tInvalidLeadingZeros(.pass,.fail)
        do tInvalidMissingPart(.pass,.fail)
        do tInvalidNonNumericTriple(.pass,.fail)
        do tInvalidEmptyPrereleaseId(.pass,.fail)
        do tInvalidEmpty(.pass,.fail)
        do tParsePopulatesArray(.pass,.fail)
        do tParseHandlesPrereleaseAndBuild(.pass,.fail)
        do tParseRejectsInvalidReturnsZero(.pass,.fail)
        do tMajorMinorPatchAccessors(.pass,.fail)
        do tPrereleaseAccessor(.pass,.fail)
        do tBuildAccessor(.pass,.fail)
        do tCompareEqualReturnsZero(.pass,.fail)
        do tCompareMajorOrders(.pass,.fail)
        do tCompareMinorOrders(.pass,.fail)
        do tComparePatchOrders(.pass,.fail)
        do tCompareIgnoresBuild(.pass,.fail)
        do tComparePrereleaseLowerThanRelease(.pass,.fail)
        do tComparePrereleaseNumericVsAlpha(.pass,.fail)
        do tComparePrereleaseLongerWins(.pass,.fail)
        do tCompareSpecExampleChain(.pass,.fail)
        do tMatchesExact(.pass,.fail)
        do tMatchesComparatorGreater(.pass,.fail)
        do tMatchesComparatorLessOrEqual(.pass,.fail)
        do tMatchesCaret(.pass,.fail)
        do tMatchesTilde(.pass,.fail)
        do tMatchesAndCombination(.pass,.fail)
        do tMatchesRejectsInvalidVersion(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- valid() ----
tValidPlainTriple(pass,fail)    ;@TEST "valid('1.2.3') is 1"
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.2.3"),"plain triple")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("0.0.0"),"zero triple")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("10.20.30"),"multi-digit")
        quit
        ;
tValidWithPrerelease(pass,fail) ;@TEST "valid('1.0.0-alpha') is 1"
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-alpha"),"alpha")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-rc.1"),"rc.1")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-0.3.7"),"numeric ids")
        quit
        ;
tValidWithBuild(pass,fail)      ;@TEST "valid('1.0.0+build') is 1"
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0+build"),"single build id")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0+20130313144700"),"timestamp build")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0+exp.sha.5114f85"),"dotted build")
        quit
        ;
tValidWithBoth(pass,fail)       ;@TEST "valid('1.0.0-alpha+001') is 1"
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-alpha+001"),"alpha+001")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-rc.1+exp.sha.5114f85"),"rc.1+meta")
        quit
        ;
tValidPrereleaseDottedIds(pass,fail)    ;@TEST "valid('1.0.0-x.7.z.92') is 1"
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-x.7.z.92"),"dotted ids")
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-alpha.beta.1"),"alpha.beta.1")
        quit
        ;
tValidLargeNumbers(pass,fail)   ;@TEST "valid('999999.999999.999999') is 1"
        do true^STDASSERT(.pass,.fail,$$valid^STDSEMVER("999999.999999.999999"),"large triple")
        quit
        ;
tInvalidLeadingZeros(pass,fail) ;@TEST "valid('01.2.3') is 0 (no leading zeros)"
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("01.2.3"),"leading-zero major")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.02.3"),"leading-zero minor")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.2.03"),"leading-zero patch")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-01"),"leading-zero numeric prerelease id")
        quit
        ;
tInvalidMissingPart(pass,fail)  ;@TEST "valid() rejects missing parts"
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1"),"major only")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.2"),"major.minor only")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.2."),"trailing dot")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER(".1.2"),"leading dot")
        quit
        ;
tInvalidNonNumericTriple(pass,fail)     ;@TEST "valid() rejects non-numeric triple components"
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("a.b.c"),"alpha triple")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.2.x"),"alpha patch")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.2.3.4"),"four parts")
        quit
        ;
tInvalidEmptyPrereleaseId(pass,fail)    ;@TEST "valid('1.0.0-') and empty dotted IDs are invalid"
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-"),"empty prerelease")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-alpha."),"trailing dot in prerelease")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0-alpha..1"),"empty middle id")
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER("1.0.0+"),"empty build")
        quit
        ;
tInvalidEmpty(pass,fail)        ;@TEST "valid('') is 0"
        do false^STDASSERT(.pass,.fail,$$valid^STDSEMVER(""),"empty string")
        quit
        ;
        ; ---- parse() ----
tParsePopulatesArray(pass,fail) ;@TEST "parse('1.2.3', .v) populates v(1..3) and returns 1"
        new v,rc
        set rc=$$parse^STDSEMVER("1.2.3",.v)
        do eq^STDASSERT(.pass,.fail,rc,1,"parse returns 1")
        do eq^STDASSERT(.pass,.fail,$get(v(1)),1,"v(1)=major=1")
        do eq^STDASSERT(.pass,.fail,$get(v(2)),2,"v(2)=minor=2")
        do eq^STDASSERT(.pass,.fail,$get(v(3)),3,"v(3)=patch=3")
        do eq^STDASSERT(.pass,.fail,$get(v(4)),"","v(4)=prerelease=''")
        do eq^STDASSERT(.pass,.fail,$get(v(5)),"","v(5)=build=''")
        quit
        ;
tParseHandlesPrereleaseAndBuild(pass,fail)      ;@TEST "parse('1.2.3-rc.1+exp', .v) extracts pre and build"
        new v,rc
        set rc=$$parse^STDSEMVER("1.2.3-rc.1+exp",.v)
        do eq^STDASSERT(.pass,.fail,rc,1,"parse returns 1")
        do eq^STDASSERT(.pass,.fail,$get(v(1)),1,"major")
        do eq^STDASSERT(.pass,.fail,$get(v(2)),2,"minor")
        do eq^STDASSERT(.pass,.fail,$get(v(3)),3,"patch")
        do eq^STDASSERT(.pass,.fail,$get(v(4)),"rc.1","prerelease")
        do eq^STDASSERT(.pass,.fail,$get(v(5)),"exp","build")
        quit
        ;
tParseRejectsInvalidReturnsZero(pass,fail)      ;@TEST "parse('not-a-version', .v) returns 0 and v is empty"
        new v,rc
        set rc=$$parse^STDSEMVER("not-a-version",.v)
        do eq^STDASSERT(.pass,.fail,rc,0,"parse returns 0 for invalid")
        do false^STDASSERT(.pass,.fail,$data(v(1)),"v(1) undefined for invalid")
        quit
        ;
        ; ---- accessors ----
tMajorMinorPatchAccessors(pass,fail)    ;@TEST "major/minor/patch return the integer parts"
        do eq^STDASSERT(.pass,.fail,$$major^STDSEMVER("1.2.3"),1,"major(1.2.3)=1")
        do eq^STDASSERT(.pass,.fail,$$minor^STDSEMVER("1.2.3"),2,"minor(1.2.3)=2")
        do eq^STDASSERT(.pass,.fail,$$patch^STDSEMVER("1.2.3"),3,"patch(1.2.3)=3")
        do eq^STDASSERT(.pass,.fail,$$major^STDSEMVER("invalid"),"","major(invalid)=''")
        quit
        ;
tPrereleaseAccessor(pass,fail)  ;@TEST "prerelease returns the prerelease tail or ''"
        do eq^STDASSERT(.pass,.fail,$$prerelease^STDSEMVER("1.2.3"),"","no prerelease")
        do eq^STDASSERT(.pass,.fail,$$prerelease^STDSEMVER("1.2.3-rc.1"),"rc.1","rc.1")
        do eq^STDASSERT(.pass,.fail,$$prerelease^STDSEMVER("1.2.3-rc.1+meta"),"rc.1","build stripped")
        quit
        ;
tBuildAccessor(pass,fail)       ;@TEST "build returns the build tail or ''"
        do eq^STDASSERT(.pass,.fail,$$build^STDSEMVER("1.2.3"),"","no build")
        do eq^STDASSERT(.pass,.fail,$$build^STDSEMVER("1.2.3+exp"),"exp","build only")
        do eq^STDASSERT(.pass,.fail,$$build^STDSEMVER("1.2.3-rc.1+exp"),"exp","build with prerelease")
        quit
        ;
        ; ---- compare() ----
tCompareEqualReturnsZero(pass,fail)     ;@TEST "compare(a, a) returns 0"
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.2.3","1.2.3"),0,"identical triples")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-rc.1","1.0.0-rc.1"),0,"identical with prerelease")
        quit
        ;
tCompareMajorOrders(pass,fail)  ;@TEST "compare orders by major first"
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.2.3","2.0.0"),-1,"1.x < 2.x")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("2.0.0","1.99.99"),1,"2.x > 1.x")
        quit
        ;
tCompareMinorOrders(pass,fail)  ;@TEST "compare uses minor when major equal"
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.2.3","1.3.0"),-1,"1.2 < 1.3")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.3.0","1.2.99"),1,"1.3 > 1.2")
        quit
        ;
tComparePatchOrders(pass,fail)  ;@TEST "compare uses patch when major.minor equal"
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.2.3","1.2.4"),-1,"patch 3 < 4")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.2.4","1.2.3"),1,"patch 4 > 3")
        quit
        ;
tCompareIgnoresBuild(pass,fail) ;@TEST "compare ignores +build metadata"
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.2.3+a","1.2.3+b"),0,"differing build ignored")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.2.3+abc","1.2.3"),0,"build vs no-build")
        quit
        ;
tComparePrereleaseLowerThanRelease(pass,fail)   ;@TEST "1.0.0-alpha < 1.0.0 (prerelease lower than release)"
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha","1.0.0"),-1,"prerelease < release")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0","1.0.0-rc.1"),1,"release > prerelease")
        quit
        ;
tComparePrereleaseNumericVsAlpha(pass,fail)     ;@TEST "numeric prerelease IDs always lower than alpha IDs"
        ; SemVer §11.4.3 — numeric identifiers always have lower precedence
        ; than alphanumeric identifiers.
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-1","1.0.0-alpha"),-1,"numeric < alpha")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha","1.0.0-1"),1,"alpha > numeric")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha.1","1.0.0-alpha.beta"),-1,"alpha.1 < alpha.beta")
        quit
        ;
tComparePrereleaseLongerWins(pass,fail) ;@TEST "longer prerelease wins ties on shared prefix"
        ; SemVer §11.4.4 — a larger set of identifiers has higher precedence
        ; if the leading parts are equal.
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha","1.0.0-alpha.1"),-1,"alpha < alpha.1")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha.1","1.0.0-alpha"),1,"alpha.1 > alpha")
        quit
        ;
tCompareSpecExampleChain(pass,fail)     ;@TEST "SemVer §11 ordering example chain holds end-to-end"
        ; 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta <
        ; 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha","1.0.0-alpha.1"),-1,"alpha < alpha.1")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha.1","1.0.0-alpha.beta"),-1,"alpha.1 < alpha.beta")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-alpha.beta","1.0.0-beta"),-1,"alpha.beta < beta")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-beta","1.0.0-beta.2"),-1,"beta < beta.2")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-beta.2","1.0.0-beta.11"),-1,"beta.2 < beta.11 (numeric)")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-beta.11","1.0.0-rc.1"),-1,"beta.11 < rc.1")
        do eq^STDASSERT(.pass,.fail,$$compare^STDSEMVER("1.0.0-rc.1","1.0.0"),-1,"rc.1 < 1.0.0")
        quit
        ;
        ; ---- matches() ----
tMatchesExact(pass,fail)        ;@TEST "matches('1.2.3', '1.2.3') is 1; mismatched is 0"
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.3","1.2.3"),"exact match")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.3","1.2.4"),"exact mismatch")
        quit
        ;
tMatchesComparatorGreater(pass,fail)    ;@TEST "matches(version, '>1.0.0') honours strict greater"
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.0.1",">1.0.0"),"1.0.1 > 1.0.0")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.0.0",">1.0.0"),"1.0.0 NOT > 1.0.0")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("0.9.9",">1.0.0"),"0.9.9 NOT > 1.0.0")
        quit
        ;
tMatchesComparatorLessOrEqual(pass,fail)        ;@TEST "matches(version, '<=2.0.0') honours <="
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.5.0","<=2.0.0"),"1.5.0 <= 2.0.0")
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("2.0.0","<=2.0.0"),"2.0.0 <= 2.0.0")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("2.0.1","<=2.0.0"),"2.0.1 NOT <= 2.0.0")
        quit
        ;
tMatchesCaret(pass,fail)        ;@TEST "matches(version, '^1.2.3') means >=1.2.3 <2.0.0"
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.3","^1.2.3"),"1.2.3 in ^1.2.3")
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.99.0","^1.2.3"),"1.99.0 in ^1.2.3")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.2","^1.2.3"),"1.2.2 NOT in ^1.2.3")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("2.0.0","^1.2.3"),"2.0.0 NOT in ^1.2.3")
        quit
        ;
tMatchesTilde(pass,fail)        ;@TEST "matches(version, '~1.2.3') means >=1.2.3 <1.3.0"
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.3","~1.2.3"),"1.2.3 in ~1.2.3")
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.99","~1.2.3"),"1.2.99 in ~1.2.3")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.2","~1.2.3"),"1.2.2 NOT in ~1.2.3")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.3.0","~1.2.3"),"1.3.0 NOT in ~1.2.3")
        quit
        ;
tMatchesAndCombination(pass,fail)       ;@TEST "matches(version, '>=1.2.3 <2.0.0') ANDs the comparators"
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.5.0",">=1.2.3 <2.0.0"),"1.5.0 in range")
        do true^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.3",">=1.2.3 <2.0.0"),"1.2.3 lower bound")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("1.2.2",">=1.2.3 <2.0.0"),"1.2.2 below range")
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("2.0.0",">=1.2.3 <2.0.0"),"2.0.0 above range")
        quit
        ;
tMatchesRejectsInvalidVersion(pass,fail)        ;@TEST "matches() returns 0 for an invalid version"
        do false^STDASSERT(.pass,.fail,$$matches^STDSEMVER("not-a-version","^1.0.0"),"invalid version returns 0")
        quit
