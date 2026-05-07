STDSTRTST       ; Test suite for STDSTR (v0.2.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tPadLeftPadsToTarget(.pass,.fail)
        do tPadLeftLeavesLongerAlone(.pass,.fail)
        do tPadLeftDefaultCharIsSpace(.pass,.fail)
        do tPadRightPadsToTarget(.pass,.fail)
        do tPadRightLeavesLongerAlone(.pass,.fail)
        do tPadIsAliasForPadLeft(.pass,.fail)
        do tTrimStripsLeadingAndTrailing(.pass,.fail)
        do tTrimPreservesInternalWhitespace(.pass,.fail)
        do tTrimEmptyAllWhitespace(.pass,.fail)
        do tTrimEmptyInputReturnsEmpty(.pass,.fail)
        do tTrimLeftStripsLeadingOnly(.pass,.fail)
        do tTrimRightStripsTrailingOnly(.pass,.fail)
        do tTrimHandlesTabsAndNewlines(.pass,.fail)
        do tReplaceAllReplacesEveryOccurrence(.pass,.fail)
        do tReplaceAllNoMatchReturnsOriginal(.pass,.fail)
        do tReplaceAllOverlappingMatches(.pass,.fail)
        do tReplaceAllEmptyFindReturnsOriginal(.pass,.fail)
        do tReplaceAllReplacementMayContainFind(.pass,.fail)
        do tSplitBasic(.pass,.fail)
        do tSplitEmpty(.pass,.fail)
        do tSplitNoSeparator(.pass,.fail)
        do tSplitTrailingSeparator(.pass,.fail)
        do tSplitMultiCharSeparator(.pass,.fail)
        do tStartsWithTrue(.pass,.fail)
        do tStartsWithFalse(.pass,.fail)
        do tStartsWithEmptyPrefix(.pass,.fail)
        do tEndsWithTrue(.pass,.fail)
        do tEndsWithFalse(.pass,.fail)
        do tEndsWithEmptySuffix(.pass,.fail)
        do tToLowerAsciiBasic(.pass,.fail)
        do tToLowerAsciiPreservesNonAlpha(.pass,.fail)
        do tToUpperAsciiBasic(.pass,.fail)
        do tToUpperAsciiPreservesNonAlpha(.pass,.fail)
        do tRepeatProducesNCopies(.pass,.fail)
        do tRepeatZeroReturnsEmpty(.pass,.fail)
        do tRepeatNegativeReturnsEmpty(.pass,.fail)
        do tRepeatEmptyInputReturnsEmpty(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- pad ----
tPadLeftPadsToTarget(pass,fail) ;@TEST "padLeft('5',3,'0') is '005'"
        do eq^STDASSERT(.pass,.fail,$$padLeft^STDSTR("5",3,"0"),"005","zero-padded triple")
        do eq^STDASSERT(.pass,.fail,$$padLeft^STDSTR("ab",6,"-"),"----ab","dash-padded sextet")
        quit
        ;
tPadLeftLeavesLongerAlone(pass,fail)    ;@TEST "padLeft of an already-long string returns it unchanged"
        do eq^STDASSERT(.pass,.fail,$$padLeft^STDSTR("hello",3,"-"),"hello","longer untouched")
        do eq^STDASSERT(.pass,.fail,$$padLeft^STDSTR("hello",5,"-"),"hello","equal-length untouched")
        quit
        ;
tPadLeftDefaultCharIsSpace(pass,fail)   ;@TEST "padLeft without explicit char defaults to space"
        do eq^STDASSERT(.pass,.fail,$$padLeft^STDSTR("x",4),"   x","default space pad")
        quit
        ;
tPadRightPadsToTarget(pass,fail)        ;@TEST "padRight('ab',6,'-') is 'ab----'"
        do eq^STDASSERT(.pass,.fail,$$padRight^STDSTR("ab",6,"-"),"ab----","dash-padded sextet")
        do eq^STDASSERT(.pass,.fail,$$padRight^STDSTR("x",4),"x   ","default space pad")
        quit
        ;
tPadRightLeavesLongerAlone(pass,fail)   ;@TEST "padRight of an already-long string returns it unchanged"
        do eq^STDASSERT(.pass,.fail,$$padRight^STDSTR("hello",3,"-"),"hello","longer untouched")
        quit
        ;
tPadIsAliasForPadLeft(pass,fail)        ;@TEST "pad() is an alias for padLeft (numeric formatting default)"
        do eq^STDASSERT(.pass,.fail,$$pad^STDSTR("5",3,"0"),"005","pad is left-pad")
        do eq^STDASSERT(.pass,.fail,$$pad^STDSTR("x",4),"   x","pad default char is space")
        quit
        ;
        ; ---- trim ----
tTrimStripsLeadingAndTrailing(pass,fail)        ;@TEST "trim('  hello  ') is 'hello'"
        do eq^STDASSERT(.pass,.fail,$$trim^STDSTR("  hello  "),"hello","spaces stripped")
        quit
        ;
tTrimPreservesInternalWhitespace(pass,fail)     ;@TEST "trim('  a  b  ') is 'a  b'"
        do eq^STDASSERT(.pass,.fail,$$trim^STDSTR("  a  b  "),"a  b","internal preserved")
        quit
        ;
tTrimEmptyAllWhitespace(pass,fail)      ;@TEST "trim('     ') is ''"
        do eq^STDASSERT(.pass,.fail,$$trim^STDSTR("     "),"","all-whitespace becomes empty")
        quit
        ;
tTrimEmptyInputReturnsEmpty(pass,fail)  ;@TEST "trim('') is ''"
        do eq^STDASSERT(.pass,.fail,$$trim^STDSTR(""),"","empty stays empty")
        quit
        ;
tTrimLeftStripsLeadingOnly(pass,fail)   ;@TEST "trimLeft('  x  ') is 'x  '"
        do eq^STDASSERT(.pass,.fail,$$trimLeft^STDSTR("  x  "),"x  ","leading only")
        do eq^STDASSERT(.pass,.fail,$$trimLeft^STDSTR("nope"),"nope","no leading whitespace")
        quit
        ;
tTrimRightStripsTrailingOnly(pass,fail) ;@TEST "trimRight('  x  ') is '  x'"
        do eq^STDASSERT(.pass,.fail,$$trimRight^STDSTR("  x  "),"  x","trailing only")
        do eq^STDASSERT(.pass,.fail,$$trimRight^STDSTR("nope"),"nope","no trailing whitespace")
        quit
        ;
tTrimHandlesTabsAndNewlines(pass,fail)  ;@TEST "trim treats tab, LF, CR as whitespace"
        new s
        set s=$char(9)_"hi"_$char(10,13,32)
        do eq^STDASSERT(.pass,.fail,$$trim^STDSTR(s),"hi","tab+LF+CR+space stripped")
        quit
        ;
        ; ---- replaceAll ----
tReplaceAllReplacesEveryOccurrence(pass,fail)   ;@TEST "replaceAll('a-b-c','-','+') is 'a+b+c'"
        do eq^STDASSERT(.pass,.fail,$$replaceAll^STDSTR("a-b-c","-","+"),"a+b+c","every occurrence")
        do eq^STDASSERT(.pass,.fail,$$replaceAll^STDSTR("foofoofoo","foo","bar"),"barbarbar","multi-char")
        quit
        ;
tReplaceAllNoMatchReturnsOriginal(pass,fail)    ;@TEST "replaceAll with no match returns the input unchanged"
        do eq^STDASSERT(.pass,.fail,$$replaceAll^STDSTR("hello","x","y"),"hello","no-match identity")
        quit
        ;
tReplaceAllOverlappingMatches(pass,fail)        ;@TEST "replaceAll handles non-overlapping greedy left-to-right scan"
        ; "aaaa" with find="aa" should produce "bb" (two non-overlapping matches),
        ; not "ba" (would imply overlap) or "bb"+remainder.
        do eq^STDASSERT(.pass,.fail,$$replaceAll^STDSTR("aaaa","aa","b"),"bb","non-overlapping aa->b")
        do eq^STDASSERT(.pass,.fail,$$replaceAll^STDSTR("aaaaa","aa","b"),"bba","odd length leaves remainder")
        quit
        ;
tReplaceAllEmptyFindReturnsOriginal(pass,fail)  ;@TEST "replaceAll with empty find returns input unchanged"
        ; Empty-needle replace is undefined classically; we choose identity.
        do eq^STDASSERT(.pass,.fail,$$replaceAll^STDSTR("abc","","X"),"abc","empty find is identity")
        quit
        ;
tReplaceAllReplacementMayContainFind(pass,fail) ;@TEST "replacement containing find is not re-replaced"
        ; "a" -> "aa" should yield "aaa" for "aa" input (each 'a' replaced once),
        ; not run away replacing the new 'a's.
        do eq^STDASSERT(.pass,.fail,$$replaceAll^STDSTR("aa","a","aa"),"aaaa","no recursive expansion")
        quit
        ;
        ; ---- split ----
tSplitBasic(pass,fail)  ;@TEST "split('a,b,c', ',', .out) populates 3 elements"
        new out,n
        set n=$$split^STDSTR("a,b,c",",",.out)
        do eq^STDASSERT(.pass,.fail,n,3,"three pieces")
        do eq^STDASSERT(.pass,.fail,$get(out(1)),"a","out(1)=a")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),"b","out(2)=b")
        do eq^STDASSERT(.pass,.fail,$get(out(3)),"c","out(3)=c")
        quit
        ;
tSplitEmpty(pass,fail)  ;@TEST "split('', sep, .out) yields 0"
        new out,n
        set n=$$split^STDSTR("",",",.out)
        do eq^STDASSERT(.pass,.fail,n,0,"empty input yields 0 pieces")
        do false^STDASSERT(.pass,.fail,$data(out(1)),"out untouched")
        quit
        ;
tSplitNoSeparator(pass,fail)    ;@TEST "split with no separator in input yields 1 piece"
        new out,n
        set n=$$split^STDSTR("solo",",",.out)
        do eq^STDASSERT(.pass,.fail,n,1,"one piece")
        do eq^STDASSERT(.pass,.fail,$get(out(1)),"solo","out(1)=solo")
        quit
        ;
tSplitTrailingSeparator(pass,fail)      ;@TEST "split('a,b,', ',', .out) yields 3 with empty third"
        new out,n
        set n=$$split^STDSTR("a,b,",",",.out)
        do eq^STDASSERT(.pass,.fail,n,3,"three pieces incl empty trailing")
        do eq^STDASSERT(.pass,.fail,$get(out(3)),"","out(3)=''")
        quit
        ;
tSplitMultiCharSeparator(pass,fail)     ;@TEST "split('a::b::c', '::', .out) handles multi-char sep"
        new out,n
        set n=$$split^STDSTR("a::b::c","::",.out)
        do eq^STDASSERT(.pass,.fail,n,3,"three pieces on '::'")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),"b","out(2)=b")
        quit
        ;
        ; ---- startsWith / endsWith ----
tStartsWithTrue(pass,fail)      ;@TEST "startsWith('hello world', 'hello') is 1"
        do true^STDASSERT(.pass,.fail,$$startsWith^STDSTR("hello world","hello"),"matches prefix")
        do true^STDASSERT(.pass,.fail,$$startsWith^STDSTR("foo","foo"),"equal strings match")
        quit
        ;
tStartsWithFalse(pass,fail)     ;@TEST "startsWith('hello', 'world') is 0"
        do false^STDASSERT(.pass,.fail,$$startsWith^STDSTR("hello","world"),"no match")
        do false^STDASSERT(.pass,.fail,$$startsWith^STDSTR("foo","foobar"),"prefix longer than s")
        quit
        ;
tStartsWithEmptyPrefix(pass,fail)       ;@TEST "startsWith(s, '') is always 1"
        do true^STDASSERT(.pass,.fail,$$startsWith^STDSTR("hello",""),"empty prefix matches")
        do true^STDASSERT(.pass,.fail,$$startsWith^STDSTR("",""),"empty/empty matches")
        quit
        ;
tEndsWithTrue(pass,fail)        ;@TEST "endsWith('hello world', 'world') is 1"
        do true^STDASSERT(.pass,.fail,$$endsWith^STDSTR("hello world","world"),"matches suffix")
        do true^STDASSERT(.pass,.fail,$$endsWith^STDSTR("foo","foo"),"equal strings match")
        quit
        ;
tEndsWithFalse(pass,fail)       ;@TEST "endsWith('hello', 'world') is 0"
        do false^STDASSERT(.pass,.fail,$$endsWith^STDSTR("hello","world"),"no match")
        do false^STDASSERT(.pass,.fail,$$endsWith^STDSTR("foo","foobar"),"suffix longer than s")
        quit
        ;
tEndsWithEmptySuffix(pass,fail) ;@TEST "endsWith(s, '') is always 1"
        do true^STDASSERT(.pass,.fail,$$endsWith^STDSTR("hello",""),"empty suffix matches")
        do true^STDASSERT(.pass,.fail,$$endsWith^STDSTR("",""),"empty/empty matches")
        quit
        ;
        ; ---- toLowerASCII / toUpperASCII ----
tToLowerAsciiBasic(pass,fail)   ;@TEST "toLowerASCII converts A-Z to a-z"
        do eq^STDASSERT(.pass,.fail,$$toLowerASCII^STDSTR("HELLO"),"hello","all upper")
        do eq^STDASSERT(.pass,.fail,$$toLowerASCII^STDSTR("MiXeD"),"mixed","mixed case")
        quit
        ;
tToLowerAsciiPreservesNonAlpha(pass,fail)       ;@TEST "toLowerASCII preserves digits and punctuation"
        do eq^STDASSERT(.pass,.fail,$$toLowerASCII^STDSTR("ABC-123"),"abc-123","digits + dash kept")
        do eq^STDASSERT(.pass,.fail,$$toLowerASCII^STDSTR(""),"","empty stays empty")
        quit
        ;
tToUpperAsciiBasic(pass,fail)   ;@TEST "toUpperASCII converts a-z to A-Z"
        do eq^STDASSERT(.pass,.fail,$$toUpperASCII^STDSTR("hello"),"HELLO","all lower")
        do eq^STDASSERT(.pass,.fail,$$toUpperASCII^STDSTR("MiXeD"),"MIXED","mixed case")
        quit
        ;
tToUpperAsciiPreservesNonAlpha(pass,fail)       ;@TEST "toUpperASCII preserves digits and punctuation"
        do eq^STDASSERT(.pass,.fail,$$toUpperASCII^STDSTR("abc-123"),"ABC-123","digits + dash kept")
        quit
        ;
        ; ---- repeat ----
tRepeatProducesNCopies(pass,fail)       ;@TEST "repeat('ab',3) is 'ababab'"
        do eq^STDASSERT(.pass,.fail,$$repeat^STDSTR("ab",3),"ababab","three copies")
        do eq^STDASSERT(.pass,.fail,$$repeat^STDSTR("-",10),"----------","ten dashes")
        do eq^STDASSERT(.pass,.fail,$$repeat^STDSTR("x",1),"x","one copy")
        quit
        ;
tRepeatZeroReturnsEmpty(pass,fail)      ;@TEST "repeat(s, 0) is ''"
        do eq^STDASSERT(.pass,.fail,$$repeat^STDSTR("ab",0),"","zero copies")
        quit
        ;
tRepeatNegativeReturnsEmpty(pass,fail)  ;@TEST "repeat(s, -1) is ''"
        do eq^STDASSERT(.pass,.fail,$$repeat^STDSTR("ab",-1),"","negative count returns empty")
        quit
        ;
tRepeatEmptyInputReturnsEmpty(pass,fail)        ;@TEST "repeat('', n) is ''"
        do eq^STDASSERT(.pass,.fail,$$repeat^STDSTR("",5),"","empty source returns empty")
        quit
