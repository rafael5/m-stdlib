STDREGEXTST     ; Test suite for STDREGEX (track L12, target tag v0.2.0).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        ;
        ; v0.2.0 supported subset (mirrors src/STDREGEX.m header):
        ;   Literals, "." (except newline), "^"/"$" anchors, quantifiers
        ;   ("*", "+", "?", "{n}", "{n,}", "{n,m}" — greedy), character
        ;   classes ("[abc]", "[^abc]", "[a-z]"), predefined classes
        ;   (\d \D \w \W \s \S), escapes (\\ \. \^ \$ \( \) \[ \] \{ \}
        ;   \| \* \+ \? \n \t \r), alternation "|", grouping "(...)" /
        ;   "(?:...)".
        ;
        ; Out of scope at v0.2.0 (compile must reject with
        ; U-STDREGEX-UNSUPPORTED): back-refs, lookaround, Unicode
        ; property classes, inline modifiers, possessive quantifiers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---- lifecycle ----
        do tCompileReturnsInteger(.pass,.fail)
        do tCompileIsolatesHandles(.pass,.fail)
        do tFreeRemovesState(.pass,.fail)
        do tValidAcceptsPlainLiteral(.pass,.fail)
        do tValidRejectsUnclosedClass(.pass,.fail)
        do tValidRejectsTrailingBackslash(.pass,.fail)
        ;
        ; ---- literal matching ----
        do tMatchLiteralExact(.pass,.fail)
        do tMatchLiteralRejectsExtraTail(.pass,.fail)
        do tMatchEmptyPatternMatchesEmpty(.pass,.fail)
        do tSearchLiteralFindsSubstring(.pass,.fail)
        do tFindReturnsOneIndexedStart(.pass,.fail)
        do tFindReturnsZeroOnMiss(.pass,.fail)
        ;
        ; ---- "." dot ----
        do tDotMatchesAnySingleChar(.pass,.fail)
        do tDotDoesNotMatchNewline(.pass,.fail)
        ;
        ; ---- anchors ----
        do tCaretAnchorsAtStart(.pass,.fail)
        do tDollarAnchorsAtEnd(.pass,.fail)
        do tCaretAndDollarTogetherIsFullMatch(.pass,.fail)
        ;
        ; ---- quantifiers (greedy) ----
        do tStarMatchesZeroOrMore(.pass,.fail)
        do tPlusMatchesOneOrMore(.pass,.fail)
        do tPlusRequiresOne(.pass,.fail)
        do tQuestionMatchesZeroOrOne(.pass,.fail)
        do tStarIsGreedy(.pass,.fail)
        do tBraceExactCount(.pass,.fail)
        do tBraceMinComma(.pass,.fail)
        do tBraceMinMax(.pass,.fail)
        ;
        ; ---- character classes ----
        do tCharClassMatchesAnyMember(.pass,.fail)
        do tCharClassRangeAtoZ(.pass,.fail)
        do tCharClassNegated(.pass,.fail)
        do tCharClassWithDashAtEnd(.pass,.fail)
        ;
        ; ---- predefined classes ----
        do tBackslashDMatchesDigit(.pass,.fail)
        do tBackslashDDoesNotMatchAlpha(.pass,.fail)
        do tBackslashWMatchesWordChar(.pass,.fail)
        do tBackslashSMatchesWhitespace(.pass,.fail)
        do tBackslashCapDIsNonDigit(.pass,.fail)
        ;
        ; ---- escapes ----
        do tEscapedDotIsLiteral(.pass,.fail)
        do tEscapedBackslashIsLiteral(.pass,.fail)
        ;
        ; ---- alternation ----
        do tAlternationLeftBranch(.pass,.fail)
        do tAlternationRightBranch(.pass,.fail)
        do tAlternationInsideGroup(.pass,.fail)
        ;
        ; ---- grouping & capture ----
        do tCapturingGroupRecordsText(.pass,.fail)
        do tNonCapturingGroupSkipsIndex(.pass,.fail)
        do tNestedCaptureGroups(.pass,.fail)
        do tGroupZeroIsFullMatch(.pass,.fail)
        ;
        ; ---- public-API: findall / replace / split ----
        do tFindallReturnsEveryNonOverlappingMatch(.pass,.fail)
        do tReplaceReplacesEveryMatch(.pass,.fail)
        do tReplaceWithBackref(.pass,.fail)
        do tSplitProducesSegments(.pass,.fail)
        ;
        ; ---- error paths ----
        do tCompileRaisesOnBadPattern(.pass,.fail)
        do tCompileRaisesOnUnsupportedBackref(.pass,.fail)
        do tCompileRaisesOnUnsupportedLookahead(.pass,.fail)
        do tGroupsRaisesOnNoMatch(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- lifecycle ----------
        ;
tCompileReturnsInteger(pass,fail)       ;@TEST "$$compile() returns a positive integer handle"
        new h
        set h=$$compile^STDREGEX("a")
        do true^STDASSERT(.pass,.fail,h>0,"handle is positive")
        do free^STDREGEX(h)
        quit
        ;
tCompileIsolatesHandles(pass,fail)      ;@TEST "$$compile() returns distinct handles each call"
        new h1,h2
        set h1=$$compile^STDREGEX("a")
        set h2=$$compile^STDREGEX("b")
        do ne^STDASSERT(.pass,.fail,h1,h2,"distinct handles")
        do free^STDREGEX(h1)
        do free^STDREGEX(h2)
        quit
        ;
tFreeRemovesState(pass,fail)    ;@TEST "free() removes the compiled-pattern state"
        new h
        set h=$$compile^STDREGEX("a")
        do free^STDREGEX(h)
        do false^STDASSERT(.pass,.fail,$data(^STDLIB($job,"stdregex",h)),"state removed after free")
        quit
        ;
tValidAcceptsPlainLiteral(pass,fail)    ;@TEST "$$valid() returns 1 for a parseable pattern"
        do eq^STDASSERT(.pass,.fail,$$valid^STDREGEX("hello"),1,"plain literal is valid")
        quit
        ;
tValidRejectsUnclosedClass(pass,fail)   ;@TEST "$$valid() returns 0 for an unclosed character class"
        do eq^STDASSERT(.pass,.fail,$$valid^STDREGEX("[abc"),0,"[abc unterminated")
        quit
        ;
tValidRejectsTrailingBackslash(pass,fail)       ;@TEST "$$valid() returns 0 for a trailing backslash"
        do eq^STDASSERT(.pass,.fail,$$valid^STDREGEX("foo\"),0,"trailing backslash invalid")
        quit
        ;
        ; ---------- literal matching ----------
        ;
tMatchLiteralExact(pass,fail)   ;@TEST "$$match() returns 1 when the full string equals the literal pattern"
        new h
        set h=$$compile^STDREGEX("cat")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"cat"),1,"cat == cat")
        do free^STDREGEX(h)
        quit
        ;
tMatchLiteralRejectsExtraTail(pass,fail)        ;@TEST "$$match() requires the entire string (no implicit tail)"
        new h
        set h=$$compile^STDREGEX("cat")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"cats"),0,"cat does not match cats")
        do free^STDREGEX(h)
        quit
        ;
tMatchEmptyPatternMatchesEmpty(pass,fail)       ;@TEST "$$match() — empty pattern matches the empty string"
        new h
        set h=$$compile^STDREGEX("")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,""),1,"'' matches ''")
        do free^STDREGEX(h)
        quit
        ;
tSearchLiteralFindsSubstring(pass,fail) ;@TEST "$$search() returns 1 when the pattern appears anywhere in the string"
        new h
        set h=$$compile^STDREGEX("cat")
        do eq^STDASSERT(.pass,.fail,$$search^STDREGEX(h,"the cat sat"),1,"cat in 'the cat sat'")
        do free^STDREGEX(h)
        quit
        ;
tFindReturnsOneIndexedStart(pass,fail)  ;@TEST "$$find() returns the 1-indexed start of the first match"
        new h
        set h=$$compile^STDREGEX("cat")
        do eq^STDASSERT(.pass,.fail,$$find^STDREGEX(h,"the cat sat"),5,"cat starts at column 5")
        do free^STDREGEX(h)
        quit
        ;
tFindReturnsZeroOnMiss(pass,fail)       ;@TEST "$$find() returns 0 when there is no match"
        new h
        set h=$$compile^STDREGEX("cat")
        do eq^STDASSERT(.pass,.fail,$$find^STDREGEX(h,"the dog sat"),0,"no cat → 0")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- "." dot ----------
        ;
tDotMatchesAnySingleChar(pass,fail)     ;@TEST "'.' matches any single character"
        new h
        set h=$$compile^STDREGEX("c.t")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"cat"),1,"c.t matches cat")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"cot"),1,"c.t matches cot")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"czt"),1,"c.t matches czt")
        do free^STDREGEX(h)
        quit
        ;
tDotDoesNotMatchNewline(pass,fail)      ;@TEST "'.' does not match newline (LF)"
        new h
        set h=$$compile^STDREGEX("a.b")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"_$char(10)_"b"),0,". does not match LF")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- anchors ----------
        ;
tCaretAnchorsAtStart(pass,fail) ;@TEST "'^' anchors the pattern to the start of the string"
        new h
        set h=$$compile^STDREGEX("^cat")
        do eq^STDASSERT(.pass,.fail,$$search^STDREGEX(h,"cat sat"),1,"^cat matches at start")
        do eq^STDASSERT(.pass,.fail,$$search^STDREGEX(h,"the cat sat"),0,"^cat does not match offset")
        do free^STDREGEX(h)
        quit
        ;
tDollarAnchorsAtEnd(pass,fail)  ;@TEST "'$' anchors the pattern to the end of the string"
        new h
        set h=$$compile^STDREGEX("cat$")
        do eq^STDASSERT(.pass,.fail,$$search^STDREGEX(h,"the cat"),1,"cat$ matches at end")
        do eq^STDASSERT(.pass,.fail,$$search^STDREGEX(h,"the cat sat"),0,"cat$ does not match before tail")
        do free^STDREGEX(h)
        quit
        ;
tCaretAndDollarTogetherIsFullMatch(pass,fail)   ;@TEST "'^...$' is equivalent to a full match"
        new h
        set h=$$compile^STDREGEX("^cat$")
        do eq^STDASSERT(.pass,.fail,$$search^STDREGEX(h,"cat"),1,"^cat$ matches cat")
        do eq^STDASSERT(.pass,.fail,$$search^STDREGEX(h,"cats"),0,"^cat$ rejects cats")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- quantifiers (greedy) ----------
        ;
tStarMatchesZeroOrMore(pass,fail)       ;@TEST "'*' matches zero or more of the preceding atom"
        new h
        set h=$$compile^STDREGEX("ab*c")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"ac"),1,"zero b's")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"abc"),1,"one b")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"abbbbc"),1,"many b's")
        do free^STDREGEX(h)
        quit
        ;
tPlusMatchesOneOrMore(pass,fail)        ;@TEST "'+' matches one or more of the preceding atom"
        new h
        set h=$$compile^STDREGEX("ab+c")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"abc"),1,"one b")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"abbc"),1,"two b's")
        do free^STDREGEX(h)
        quit
        ;
tPlusRequiresOne(pass,fail)     ;@TEST "'+' rejects zero of the preceding atom"
        new h
        set h=$$compile^STDREGEX("ab+c")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"ac"),0,"zero b's not allowed")
        do free^STDREGEX(h)
        quit
        ;
tQuestionMatchesZeroOrOne(pass,fail)    ;@TEST "'?' matches zero or one of the preceding atom"
        new h
        set h=$$compile^STDREGEX("ab?c")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"ac"),1,"zero b's")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"abc"),1,"one b")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"abbc"),0,"two b's reject")
        do free^STDREGEX(h)
        quit
        ;
tStarIsGreedy(pass,fail)        ;@TEST "'*' is greedy — captures the longest possible prefix"
        new h,g
        set h=$$compile^STDREGEX("(a.*b)")
        do groups^STDREGEX(h,"a__b__b",.g)
        do eq^STDASSERT(.pass,.fail,$get(g(1)),"a__b__b","greedy: matched through the second b")
        do free^STDREGEX(h)
        quit
        ;
tBraceExactCount(pass,fail)     ;@TEST "'{n}' requires exactly n of the preceding atom"
        new h
        set h=$$compile^STDREGEX("a{3}")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aaa"),1,"exactly 3")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aa"),0,"too few")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aaaa"),0,"too many (full-match)")
        do free^STDREGEX(h)
        quit
        ;
tBraceMinComma(pass,fail)       ;@TEST "'{n,}' requires at least n of the preceding atom"
        new h
        set h=$$compile^STDREGEX("a{2,}")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"),0,"one a is too few")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aa"),1,"two a's ok")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aaaa"),1,"four a's ok")
        do free^STDREGEX(h)
        quit
        ;
tBraceMinMax(pass,fail) ;@TEST "'{n,m}' requires between n and m of the preceding atom"
        new h
        set h=$$compile^STDREGEX("a{2,3}")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"),0,"one a too few")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aa"),1,"two a's ok")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aaa"),1,"three a's ok")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"aaaa"),0,"four a's too many")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- character classes ----------
        ;
tCharClassMatchesAnyMember(pass,fail)   ;@TEST "'[abc]' matches any one of a, b, c"
        new h
        set h=$$compile^STDREGEX("[abc]")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"),1,"a in [abc]")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"b"),1,"b in [abc]")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"c"),1,"c in [abc]")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"d"),0,"d not in [abc]")
        do free^STDREGEX(h)
        quit
        ;
tCharClassRangeAtoZ(pass,fail)  ;@TEST "'[a-z]' matches any lowercase ASCII letter"
        new h
        set h=$$compile^STDREGEX("[a-z]+")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"hello"),1,"all lowercase")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"Hello"),0,"capital H rejects")
        do free^STDREGEX(h)
        quit
        ;
tCharClassNegated(pass,fail)    ;@TEST "'[^abc]' matches any char NOT in the set"
        new h
        set h=$$compile^STDREGEX("[^abc]")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"d"),1,"d not in [abc] → matches negated")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"),0,"a in [abc] → fails negated")
        do free^STDREGEX(h)
        quit
        ;
tCharClassWithDashAtEnd(pass,fail)      ;@TEST "'[abc-]' includes literal '-' when '-' is last in the class"
        new h
        set h=$$compile^STDREGEX("[abc-]")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"-"),1,"- is literal at end of class")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"),1,"a still in [abc-]")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- predefined classes ----------
        ;
tBackslashDMatchesDigit(pass,fail)      ;@TEST "'\d' matches an ASCII digit"
        new h
        set h=$$compile^STDREGEX("\d")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"5"),1,"5 is a digit")
        do free^STDREGEX(h)
        quit
        ;
tBackslashDDoesNotMatchAlpha(pass,fail) ;@TEST "'\d' rejects alphabetic input"
        new h
        set h=$$compile^STDREGEX("\d")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"),0,"a is not a digit")
        do free^STDREGEX(h)
        quit
        ;
tBackslashWMatchesWordChar(pass,fail)   ;@TEST "'\w' matches a word character (alnum + '_')"
        new h
        set h=$$compile^STDREGEX("\w+")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"foo_42"),1,"foo_42 is all word chars")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"hi!"),0,"trailing ! is not a word char")
        do free^STDREGEX(h)
        quit
        ;
tBackslashSMatchesWhitespace(pass,fail) ;@TEST "'\s' matches whitespace (space, tab, newline)"
        new h
        set h=$$compile^STDREGEX("\s")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h," "),1,"space is whitespace")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,$char(9)),1,"tab is whitespace")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,$char(10)),1,"LF is whitespace")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"x"),0,"x is not whitespace")
        do free^STDREGEX(h)
        quit
        ;
tBackslashCapDIsNonDigit(pass,fail)     ;@TEST "'\D' matches a non-digit"
        new h
        set h=$$compile^STDREGEX("\D")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a"),1,"a is non-digit")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"5"),0,"5 is a digit → fails")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- escapes ----------
        ;
tEscapedDotIsLiteral(pass,fail) ;@TEST "'\\.' matches a literal period"
        new h
        set h=$$compile^STDREGEX("a\.b")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a.b"),1,"a.b matches a\.b")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"axb"),0,"axb rejects (escaped .)")
        do free^STDREGEX(h)
        quit
        ;
tEscapedBackslashIsLiteral(pass,fail)   ;@TEST "'\\\\' matches a literal backslash"
        new h
        set h=$$compile^STDREGEX("a\\b")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"a\b"),1,"a\\b matches a\\\\b")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- alternation ----------
        ;
tAlternationLeftBranch(pass,fail)       ;@TEST "'a|b' matches the left branch"
        new h
        set h=$$compile^STDREGEX("cat|dog")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"cat"),1,"left branch")
        do free^STDREGEX(h)
        quit
        ;
tAlternationRightBranch(pass,fail)      ;@TEST "'a|b' matches the right branch"
        new h
        set h=$$compile^STDREGEX("cat|dog")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"dog"),1,"right branch")
        do free^STDREGEX(h)
        quit
        ;
tAlternationInsideGroup(pass,fail)      ;@TEST "'(cat|dog)s' uses the group as the alternation scope"
        new h
        set h=$$compile^STDREGEX("(cat|dog)s")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"cats"),1,"cats matches")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"dogs"),1,"dogs matches")
        do eq^STDASSERT(.pass,.fail,$$match^STDREGEX(h,"cat"),0,"cat (no s) rejects")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- grouping & capture ----------
        ;
tCapturingGroupRecordsText(pass,fail)   ;@TEST "groups() records each capture group by 1-indexed slot"
        new h,g
        set h=$$compile^STDREGEX("(\d+)-(\w+)")
        do groups^STDREGEX(h,"42-foo",.g)
        do eq^STDASSERT(.pass,.fail,$get(g(1)),"42","group 1 = 42")
        do eq^STDASSERT(.pass,.fail,$get(g(2)),"foo","group 2 = foo")
        do free^STDREGEX(h)
        quit
        ;
tNonCapturingGroupSkipsIndex(pass,fail) ;@TEST "(?:...) does not consume a capture-group slot"
        new h,g
        set h=$$compile^STDREGEX("(?:foo)(\d+)")
        do groups^STDREGEX(h,"foo42",.g)
        do eq^STDASSERT(.pass,.fail,$get(g(1)),"42","g(1) is the digits, not 'foo'")
        do false^STDASSERT(.pass,.fail,$data(g(2)),"no g(2)")
        do free^STDREGEX(h)
        quit
        ;
tNestedCaptureGroups(pass,fail) ;@TEST "nested capture groups number outer-first by '(' position"
        new h,g
        set h=$$compile^STDREGEX("((a)(b))")
        do groups^STDREGEX(h,"ab",.g)
        do eq^STDASSERT(.pass,.fail,$get(g(1)),"ab","g(1) = outer = ab")
        do eq^STDASSERT(.pass,.fail,$get(g(2)),"a","g(2) = first inner = a")
        do eq^STDASSERT(.pass,.fail,$get(g(3)),"b","g(3) = second inner = b")
        do free^STDREGEX(h)
        quit
        ;
tGroupZeroIsFullMatch(pass,fail)        ;@TEST "groups() — g(0) is the full match text"
        new h,g
        set h=$$compile^STDREGEX("\d+")
        do groups^STDREGEX(h,"the 42 cats",.g)
        do eq^STDASSERT(.pass,.fail,$get(g(0)),"42","g(0) is the matched substring")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- public-API: findall / replace / split ----------
        ;
tFindallReturnsEveryNonOverlappingMatch(pass,fail)      ;@TEST "findall() populates out(n) with each non-overlapping match"
        new h,out
        set h=$$compile^STDREGEX("\d+")
        do findall^STDREGEX(h,"a 1 b 22 c 333",.out)
        do eq^STDASSERT(.pass,.fail,$get(out(1)),"1","first match = 1")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),"22","second match = 22")
        do eq^STDASSERT(.pass,.fail,$get(out(3)),"333","third match = 333")
        do free^STDREGEX(h)
        quit
        ;
tReplaceReplacesEveryMatch(pass,fail)   ;@TEST "$$replace() replaces every match with the literal replacement"
        new h
        set h=$$compile^STDREGEX("\d+")
        do eq^STDASSERT(.pass,.fail,$$replace^STDREGEX(h,"a 1 b 22 c","#"),"a # b # c","every digit run replaced")
        do free^STDREGEX(h)
        quit
        ;
tReplaceWithBackref(pass,fail)  ;@TEST "$$replace() honours \\1 in the replacement string"
        new h
        set h=$$compile^STDREGEX("(\d+)")
        do eq^STDASSERT(.pass,.fail,$$replace^STDREGEX(h,"x42y","[\1]"),"x[42]y","\\1 expands to capture 1")
        do free^STDREGEX(h)
        quit
        ;
tSplitProducesSegments(pass,fail)       ;@TEST "split() populates out(n) with the segments between matches"
        new h,out
        set h=$$compile^STDREGEX(",")
        do split^STDREGEX(h,"a,b,c",.out)
        do eq^STDASSERT(.pass,.fail,$get(out(1)),"a","seg 1 = a")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),"b","seg 2 = b")
        do eq^STDASSERT(.pass,.fail,$get(out(3)),"c","seg 3 = c")
        do free^STDREGEX(h)
        quit
        ;
        ; ---------- error paths ----------
        ;
tCompileRaisesOnBadPattern(pass,fail)   ;@TEST "compile() with an unbalanced group raises U-STDREGEX-BAD-PATTERN"
        do raises^STDASSERT(.pass,.fail,"new h set h=$$compile^STDREGEX(""(abc"")","U-STDREGEX-BAD-PATTERN","unbalanced ( rejected")
        quit
        ;
tCompileRaisesOnUnsupportedBackref(pass,fail)   ;@TEST "compile() rejects back-references with U-STDREGEX-UNSUPPORTED"
        do raises^STDASSERT(.pass,.fail,"new h set h=$$compile^STDREGEX(""(a)\1"")","U-STDREGEX-UNSUPPORTED","backref \1 rejected at v0.2.0")
        quit
        ;
tCompileRaisesOnUnsupportedLookahead(pass,fail) ;@TEST "compile() rejects '(?=...)' lookahead with U-STDREGEX-UNSUPPORTED"
        do raises^STDASSERT(.pass,.fail,"new h set h=$$compile^STDREGEX(""(?=a)b"")","U-STDREGEX-UNSUPPORTED","lookahead rejected at v0.2.0")
        quit
        ;
tGroupsRaisesOnNoMatch(pass,fail)       ;@TEST "groups() raises U-STDREGEX-NO-MATCH when no match exists"
        new h
        set h=$$compile^STDREGEX("\d+")
        do raises^STDASSERT(.pass,.fail,"new g do groups^STDREGEX("_h_",""no digits here"",.g)","U-STDREGEX-NO-MATCH","groups() with no match")
        do free^STDREGEX(h)
        quit
        ;
