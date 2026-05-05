STDJSONTST      ; Test suite for STDJSON (v0.2.0, track L11 — RFC 8259).
        ; m-lint: disable-file=M-MOD-020,M-MOD-024
        ; M-MOD-024 disabled file-wide: OPEN/CLOSE deviceparams in the
        ; file-I/O smoke tests are misparsed as local reads — same pattern
        ; STDCSVTST exempts. See TOOLCHAIN-FINDINGS.md.
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        ;
        ; Conformance corpus: representative vectors from JSONTestSuite
        ; vendored at tests/conformance/json/{y,n,i}/. Each vector is
        ; inlined here as a literal so the test runs without reading
        ; the host filesystem (mirrors STDB64TST's RFC-4648 §10 inline
        ; vectors). The vendored files remain the auditable spec.
        ;
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---------- introspection ----------
        do tTypeOnUndefinedReturnsEmpty(.pass,.fail)
        do tValueOfOnContainerReturnsEmpty(.pass,.fail)
        ;
        ; ---------- parse scalars ----------
        do tParseNull(.pass,.fail)
        do tParseTrue(.pass,.fail)
        do tParseFalse(.pass,.fail)
        do tParseEmptyString(.pass,.fail)
        do tParseAsciiString(.pass,.fail)
        do tParseStringTwoCharEscapes(.pass,.fail)
        do tParseStringUnicodeBmpEscape(.pass,.fail)
        do tParseStringSurrogatePair(.pass,.fail)
        do tParseStringEmbeddedColon(.pass,.fail)
        do tParseIntegerZero(.pass,.fail)
        do tParseIntegerPositive(.pass,.fail)
        do tParseIntegerNegative(.pass,.fail)
        do tParseFraction(.pass,.fail)
        do tParseExponentLowercase(.pass,.fail)
        do tParseExponentUppercaseSigned(.pass,.fail)
        do tParseLargeIntegerVerbatim(.pass,.fail)
        ;
        ; ---------- parse containers ----------
        do tParseEmptyObject(.pass,.fail)
        do tParseEmptyArray(.pass,.fail)
        do tParseObjectSinglePair(.pass,.fail)
        do tParseObjectMultiplePairs(.pass,.fail)
        do tParseObjectEmptyKeyAllowed(.pass,.fail)
        do tParseArraySingleElement(.pass,.fail)
        do tParseArrayMultipleElements(.pass,.fail)
        do tParseArrayMixedTypes(.pass,.fail)
        do tParseNestedDeep(.pass,.fail)
        do tParseWhitespaceAroundTokens(.pass,.fail)
        do tParseClearsCallerArray(.pass,.fail)
        ;
        ; ---------- y_* corpus (must parse) ----------
        do tCorpusYAll(.pass,.fail)
        ;
        ; ---------- n_* corpus (must reject) ----------
        do tCorpusNAll(.pass,.fail)
        ;
        ; ---------- i_* corpus (implementation defined) ----------
        do tCorpusIIntOverflowAccepted(.pass,.fail)
        do tCorpusIDuplicateKeyLastWins(.pass,.fail)
        do tCorpusIEmbeddedNullDecoded(.pass,.fail)
        do tCorpusILoneHighSurrogateRejected(.pass,.fail)
        do tCorpusILoneLowSurrogateRejected(.pass,.fail)
        do tCorpusIInvalidUtf8Accepted(.pass,.fail)
        ;
        ; ---------- error reporting ----------
        do tLastErrorClearedOnSuccess(.pass,.fail)
        do tLastErrorReportsLineCol(.pass,.fail)
        do tLastErrorReportsTrailingGarbage(.pass,.fail)
        do tLastErrorReportsUnterminatedString(.pass,.fail)
        do tLastErrorReportsUnexpectedEof(.pass,.fail)
        ;
        ; ---------- valid() ----------
        do tValidAcceptsConformant(.pass,.fail)
        do tValidRejectsMalformed(.pass,.fail)
        do tValidEmpty(.pass,.fail)
        ;
        ; ---------- encode ----------
        do tEncodeNull(.pass,.fail)
        do tEncodeTrue(.pass,.fail)
        do tEncodeFalse(.pass,.fail)
        do tEncodeEmptyString(.pass,.fail)
        do tEncodeAsciiString(.pass,.fail)
        do tEncodeStringEscapes(.pass,.fail)
        do tEncodeStringControlChar(.pass,.fail)
        do tEncodeNumber(.pass,.fail)
        do tEncodeEmptyObject(.pass,.fail)
        do tEncodeEmptyArray(.pass,.fail)
        do tEncodeObject(.pass,.fail)
        do tEncodeArray(.pass,.fail)
        do tEncodeNested(.pass,.fail)
        do tEncodeArrayWithGapRaises(.pass,.fail)
        ;
        ; ---------- round-trip ----------
        do tRoundTripScalars(.pass,.fail)
        do tRoundTripObject(.pass,.fail)
        do tRoundTripArray(.pass,.fail)
        do tRoundTripNested(.pass,.fail)
        ;
        ; ---------- file I/O smoke ----------
        do tParseFileSmoke(.pass,.fail)
        do tWriteFileSmoke(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ============================================================
        ; introspection
        ; ============================================================
        ;
tTypeOnUndefinedReturnsEmpty(pass,fail) ;@TEST "type() on an undefined node returns empty"
        new node
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.node),"","undefined -> """)
        quit
        ;
tValueOfOnContainerReturnsEmpty(pass,fail)      ;@TEST "valueOf() on object/array/literal returns empty"
        new node
        set node="o"
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.node),"","object -> """)
        set node="a"
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.node),"","array -> """)
        set node="t"
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.node),"","true -> """)
        set node="z"
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.node),"","null -> """)
        quit
        ;
        ; ============================================================
        ; parse scalars
        ; ============================================================
        ;
tParseNull(pass,fail)   ;@TEST "parse() of 'null' yields a null leaf"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("null",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,root,"z","sigil z")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"null","type=null")
        quit
        ;
tParseTrue(pass,fail)   ;@TEST "parse() of 'true' yields a true leaf"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("true",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,root,"t","sigil t")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"true","type=true")
        quit
        ;
tParseFalse(pass,fail)  ;@TEST "parse() of 'false' yields a false leaf"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("false",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,root,"f","sigil f")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"false","type=false")
        quit
        ;
tParseEmptyString(pass,fail)    ;@TEST "parse() of '\"\"' yields an empty string"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(""""_"""",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,root,"s:","sigil s:")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"string","type=string")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"","value=""")
        quit
        ;
tParseAsciiString(pass,fail)    ;@TEST "parse() of an ASCII string"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(""""_"hello"_"""",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"hello","value=hello")
        quit
        ;
tParseStringTwoCharEscapes(pass,fail)   ;@TEST "parse() decodes \\\\ \\\" \\/ \\b \\f \\n \\r \\t"
        ; y_string_escapes.json:  "a\\b\"c\/d\b\f\n\r\t"
        new root,src,want
        set src=$char(34)_"a\\b"_$char(92)_$char(34)_"c\/d\b\f\n\r\t"_$char(34)
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        set want="a\b"_""""_"c/d"_$char(8)_$char(12)_$char(10)_$char(13)_$char(9)
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),want,"all eight escapes decoded")
        quit
        ;
tParseStringUnicodeBmpEscape(pass,fail) ;@TEST "parse() decodes \\uXXXX in the BMP"
        ; y_string_unicode_escape.json:  "é€"  (é €)
        new root,src,want
        set src=""""_"é€"_""""
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        ; UTF-8: U+00E9 -> C3 A9; U+20AC -> E2 82 AC
        set want=$char(195)_$char(169)_$char(226)_$char(130)_$char(172)
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),want,"BMP escapes -> UTF-8 bytes")
        quit
        ;
tParseStringSurrogatePair(pass,fail)    ;@TEST "parse() combines a UTF-16 surrogate pair to one codepoint"
        ; y_string_surrogate_pair.json:  "𝄞"  (G clef U+1D11E)
        new root,src,want
        set src=""""_"𝄞"_""""
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        ; UTF-8 of U+1D11E: F0 9D 84 9E
        set want=$char(240)_$char(157)_$char(132)_$char(158)
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),want,"surrogate pair -> 4-byte UTF-8")
        quit
        ;
tParseStringEmbeddedColon(pass,fail)    ;@TEST "parse() string containing ':' round-trips through s: storage"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(""""_"a:b:c"_"""",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"a:b:c","value preserves all colons")
        do eq^STDASSERT(.pass,.fail,root,"s:a:b:c","raw sigil shape")
        quit
        ;
tParseIntegerZero(pass,fail)    ;@TEST "parse() accepts '0' as a number"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("0",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,root,"n:0","stored verbatim")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"number","type=number")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"0","value=0")
        quit
        ;
tParseIntegerPositive(pass,fail)        ;@TEST "parse() accepts a positive integer"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("42",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"42","value=42")
        quit
        ;
tParseIntegerNegative(pass,fail)        ;@TEST "parse() accepts a negative integer"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("-7",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"-7","value=-7")
        quit
        ;
tParseFraction(pass,fail)       ;@TEST "parse() accepts decimal fractions"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("3.14",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"3.14","value=3.14")
        quit
        ;
tParseExponentLowercase(pass,fail)      ;@TEST "parse() accepts 'e' exponent"
        ; y_number_exp.json:  6.022e23
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("6.022e23",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"6.022e23","value verbatim")
        quit
        ;
tParseExponentUppercaseSigned(pass,fail)        ;@TEST "parse() accepts 'E' with signed exponent"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("1.5E-10",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"1.5E-10","value verbatim (case + sign preserved)")
        quit
        ;
tParseLargeIntegerVerbatim(pass,fail)   ;@TEST "parse() of a 16-digit integer preserves all digits"
        ; y_number_large.json:  1234567890123456
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("1234567890123456",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"1234567890123456","16 digits intact")
        quit
        ;
        ; ============================================================
        ; parse containers
        ; ============================================================
        ;
tParseEmptyObject(pass,fail)    ;@TEST "parse() of '{}' yields an empty object node"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("{}",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,root,"o","sigil o")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"object","type=object")
        do eq^STDASSERT(.pass,.fail,$order(root("")),"","no children")
        quit
        ;
tParseEmptyArray(pass,fail)     ;@TEST "parse() of '[]' yields an empty array node"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("[]",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,root,"a","sigil a")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"array","type=array")
        do eq^STDASSERT(.pass,.fail,$order(root("")),"","no children")
        quit
        ;
tParseObjectSinglePair(pass,fail)       ;@TEST "parse() of a single-pair object"
        ; y_object_basic-style:  {"foo":"bar"}
        new root,src
        set src="{"_""""_"foo"_""""_":"_""""_"bar"_""""_"}"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root),"object","root is object")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("foo")),"bar","foo -> bar")
        quit
        ;
tParseObjectMultiplePairs(pass,fail)    ;@TEST "parse() of an object with multiple keys"
        ; y_object_string_keys.json:  {"foo":"bar","baz":"qux"}
        new root,src
        set src="{"_""""_"foo"_""""_":"_""""_"bar"_""""_","_""""_"baz"_""""_":"_""""_"qux"_""""_"}"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("foo")),"bar","foo -> bar")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("baz")),"qux","baz -> qux")
        quit
        ;
tParseObjectEmptyKeyAllowed(pass,fail)  ;@TEST "parse() allows an empty-string key (RFC 8259 §4)"
        new root,src
        set src="{"_""""_""""_":"_""""_"v"_""""_"}"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("")),"v","empty key -> v")
        quit
        ;
tParseArraySingleElement(pass,fail)     ;@TEST "parse() of a one-element array"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("[42]",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root(1)),"42","root[1] = 42")
        quit
        ;
tParseArrayMultipleElements(pass,fail)  ;@TEST "parse() of a multi-element numeric array"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("[1,2,3]",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root(1)),"1","[1]")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root(2)),"2","[2]")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root(3)),"3","[3]")
        quit
        ;
tParseArrayMixedTypes(pass,fail)        ;@TEST "parse() of a heterogeneous array"
        ; y_array_mixed.json:  [1,"two",true,false,null,{"k":"v"},[1,2]]
        new root,src
        set src="[1,"_""""_"two"_""""_",true,false,null,{"_""""_"k"_""""_":"_""""_"v"_""""_"},[1,2]]"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root(1)),"number","[1]=number")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root(2)),"string","[2]=string")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root(3)),"true","[3]=true")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root(4)),"false","[4]=false")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root(5)),"null","[5]=null")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root(6)),"object","[6]=object")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root(6,"k")),"v","[6].k=v")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.root(7)),"array","[7]=array")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root(7,2)),"2","[7][2]=2")
        quit
        ;
tParseNestedDeep(pass,fail)     ;@TEST "parse() of a 5-deep nested array"
        ; y_nested_deep.json:  [[[[[42]]]]]
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("[[[[[42]]]]]",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root(1,1,1,1,1)),"42","leaf at depth 5")
        quit
        ;
tParseWhitespaceAroundTokens(pass,fail) ;@TEST "parse() ignores RFC-8259 whitespace (sp/ht/lf/cr)"
        ; y_whitespace_around.json:  "   {\n  \"a\"  :  1\t,\n  \"b\" : 2  }"
        new root,src
        set src="   {"_$char(10)_"  "_""""_"a"_""""_"  :  1"_$char(9)_","_$char(10)_"  "_""""_"b"_""""_" : 2  }"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("a")),"1","a=1")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("b")),"2","b=2")
        quit
        ;
tParseClearsCallerArray(pass,fail)      ;@TEST "parse() kills the caller's array before populating"
        new root
        set root("garbage")="should be cleared"
        set root("garbage","deeper")="also gone"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("42",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$data(root("garbage")),0,"prior subtree killed")
        do eq^STDASSERT(.pass,.fail,root,"n:42","root replaced with scalar")
        quit
        ;
        ; ============================================================
        ; y_* corpus — must parse
        ; ============================================================
        ;
tCorpusYAll(pass,fail)  ;@TEST "every y_* corpus vector parses successfully"
        ; This loops the representative subset documented in
        ; tests/conformance/json/README.md. Each call asserts parse=1.
        do expectOk(.pass,.fail,"{}","y_object_empty")
        do expectOk(.pass,.fail,"[]","y_array_empty")
        do expectOk(.pass,.fail,"true","y_true")
        do expectOk(.pass,.fail,"false","y_false")
        do expectOk(.pass,.fail,"null","y_null")
        do expectOk(.pass,.fail,"42","y_number_int")
        do expectOk(.pass,.fail,"-42","y_number_negative")
        do expectOk(.pass,.fail,"0","y_number_zero")
        do expectOk(.pass,.fail,"3.14","y_number_frac")
        do expectOk(.pass,.fail,"6.022e23","y_number_exp")
        do expectOk(.pass,.fail,"1.5E-10","y_number_neg_exp")
        do expectOk(.pass,.fail,"1234567890123456","y_number_large")
        do expectOk(.pass,.fail,""""_"""","y_string_empty")
        do expectOk(.pass,.fail,""""_"hello"_"""","y_string_basic")
        do expectOk(.pass,.fail,$char(34)_"\\"_$char(34),"y_string_escape_subset")
        do expectOk(.pass,.fail,""""_"é"_"""","y_string_unicode_escape")
        do expectOk(.pass,.fail,""""_"𝄞"_"""","y_string_surrogate_pair")
        do expectOk(.pass,.fail,"[[[[[42]]]]]","y_nested_deep")
        do expectOk(.pass,.fail,"[1,"_""""_"two"_""""_",true,false,null,{"_""""_"k"_""""_":"_""""_"v"_""""_"},[1,2]]","y_array_mixed")
        do expectOk(.pass,.fail,"   { "_""""_"a"_""""_" : 1 }   ","y_whitespace_around")
        quit
        ;
        ; ============================================================
        ; n_* corpus — must reject
        ; ============================================================
        ;
tCorpusNAll(pass,fail)  ;@TEST "every n_* corpus vector is rejected"
        do expectFail(.pass,.fail,"zomg","n_garbage")
        do expectFail(.pass,.fail,"01","n_leading_zero")
        do expectFail(.pass,.fail,".5","n_lone_decimal")
        do expectFail(.pass,.fail,""""_"a"_$char(1)_"b"_"""","n_unescaped_ctrl")
        do expectFail(.pass,.fail,"{a:1}","n_unquoted_key")
        do expectFail(.pass,.fail,"[1,2,]","n_trailing_comma_arr")
        do expectFail(.pass,.fail,"{"_""""_"a"_""""_":1,}","n_trailing_comma_obj")
        do expectFail(.pass,.fail,"{ "_""""_"a"_""""_": 1 }extra","n_trailing_garbage")
        do expectFail(.pass,.fail,"[1 2]","n_missing_array_comma")
        do expectFail(.pass,.fail,"{"_""""_"a"_""""_" 1}","n_missing_colon")
        do expectFail(.pass,.fail,"'single'","n_single_quotes")
        do expectFail(.pass,.fail,"++1","n_double_plus")
        do expectFail(.pass,.fail,"[","n_unclosed_arr")
        do expectFail(.pass,.fail,"{","n_unclosed_obj")
        do expectFail(.pass,.fail,""""_"abc","n_unclosed_str")
        quit
        ;
        ; ============================================================
        ; i_* corpus — implementation-defined behaviour
        ; (STDJSON's documented choices, per docs/modules/stdjson.md)
        ; ============================================================
        ;
tCorpusIIntOverflowAccepted(pass,fail)  ;@TEST "i_number_int_overflow_64: 20-digit int accepted, stored verbatim"
        new root
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("12345678901234567890",.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"12345678901234567890","20 digits preserved")
        quit
        ;
tCorpusIDuplicateKeyLastWins(pass,fail) ;@TEST "i_object_duplicate_key: last definition wins"
        ; {"a":1,"a":2}  -> root("a") = 2
        new root,src
        set src="{"_""""_"a"_""""_":1,"_""""_"a"_""""_":2}"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("a")),"2","last write wins")
        quit
        ;
tCorpusIEmbeddedNullDecoded(pass,fail)  ;@TEST "i_string_embedded_null_escape: \\u0000 decodes to $CHAR(0)"
        new root,src
        set src=$char(34)_"\u0000"_$char(34)
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),$char(0),"single NUL byte")
        quit
        ;
tCorpusILoneHighSurrogateRejected(pass,fail)    ;@TEST "i_string_lone_high_surrogate: \\uD834 alone is rejected"
        new root
        do false^STDASSERT(.pass,.fail,$$parse^STDJSON(""""_"\uD834"_"""",.root),"parse rejected")
        do contains^STDASSERT(.pass,.fail,$$lastError^STDJSON(),"lone surrogate","error mentions lone surrogate")
        quit
        ;
tCorpusILoneLowSurrogateRejected(pass,fail)     ;@TEST "i_string_lone_low_surrogate: \\uDD1E alone is rejected"
        new root
        do false^STDASSERT(.pass,.fail,$$parse^STDJSON(""""_"\uDD1E"_"""",.root),"parse rejected")
        do contains^STDASSERT(.pass,.fail,$$lastError^STDJSON(),"lone surrogate","error mentions lone surrogate")
        quit
        ;
tCorpusIInvalidUtf8Accepted(pass,fail)  ;@TEST "i_string_invalid_utf8: parser does not validate UTF-8 well-formedness"
        new root,src
        ; "a<0xff>b" — a literal 0xFF byte inside a string body
        set src=""""_"a"_$char(255)_"b"_""""
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse ok (bytes pass through)")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root),"a"_$char(255)_"b","0xFF preserved")
        quit
        ;
        ; ============================================================
        ; error reporting
        ; ============================================================
        ;
tLastErrorClearedOnSuccess(pass,fail)   ;@TEST "lastError() returns empty after a successful parse"
        new root
        ; First, induce an error
        do false^STDASSERT(.pass,.fail,$$parse^STDJSON("zomg",.root),"first parse fails")
        do contains^STDASSERT(.pass,.fail,$$lastError^STDJSON(),"unexpected","error stashed")
        ; Then a success should clear it
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON("42",.root),"second parse ok")
        do eq^STDASSERT(.pass,.fail,$$lastError^STDJSON(),"","cleared on success")
        quit
        ;
tLastErrorReportsLineCol(pass,fail)     ;@TEST "lastError() includes 1-based line:col prefix"
        new root,err
        ; Two-line input; bad token on line 2 col 1.
        do false^STDASSERT(.pass,.fail,$$parse^STDJSON("[1,"_$char(10)_"zomg]",.root),"parse fails")
        set err=$$lastError^STDJSON()
        do contains^STDASSERT(.pass,.fail,err,"2:1","line:col prefix")
        quit
        ;
tLastErrorReportsTrailingGarbage(pass,fail)     ;@TEST "lastError() reports trailing garbage by name"
        new root
        do false^STDASSERT(.pass,.fail,$$parse^STDJSON("42 oops",.root),"parse fails")
        do contains^STDASSERT(.pass,.fail,$$lastError^STDJSON(),"trailing garbage","reason captured")
        quit
        ;
tLastErrorReportsUnterminatedString(pass,fail)  ;@TEST "lastError() reports an unterminated string by name"
        new root
        do false^STDASSERT(.pass,.fail,$$parse^STDJSON(""""_"abc",.root),"parse fails")
        do contains^STDASSERT(.pass,.fail,$$lastError^STDJSON(),"unterminated string","reason captured")
        quit
        ;
tLastErrorReportsUnexpectedEof(pass,fail)       ;@TEST "lastError() reports unexpected EOF"
        new root
        do false^STDASSERT(.pass,.fail,$$parse^STDJSON("[1,",.root),"parse fails")
        do contains^STDASSERT(.pass,.fail,$$lastError^STDJSON(),"unexpected EOF","reason captured")
        quit
        ;
        ; ============================================================
        ; valid()
        ; ============================================================
        ;
tValidAcceptsConformant(pass,fail)      ;@TEST "valid() returns 1 on every y_* style input"
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("{}"),1,"{} valid")
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("[1,2,3]"),1,"[1,2,3] valid")
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("null"),1,"null valid")
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("6.022e23"),1,"6.022e23 valid")
        quit
        ;
tValidRejectsMalformed(pass,fail)       ;@TEST "valid() returns 0 on every n_* style input"
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("zomg"),0,"garbage rejected")
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("[1,2,]"),0,"trailing comma rejected")
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("{a:1}"),0,"unquoted key rejected")
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON("01"),0,"leading zero rejected")
        quit
        ;
tValidEmpty(pass,fail)  ;@TEST "valid() rejects empty input"
        do eq^STDASSERT(.pass,.fail,$$valid^STDJSON(""),0,"empty rejected")
        quit
        ;
        ; ============================================================
        ; encode
        ; ============================================================
        ;
tEncodeNull(pass,fail)  ;@TEST "encode() emits 'null' for the z sigil"
        new node
        set node="z"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),"null","emit null")
        quit
        ;
tEncodeTrue(pass,fail)  ;@TEST "encode() emits 'true' for the t sigil"
        new node
        set node="t"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),"true","emit true")
        quit
        ;
tEncodeFalse(pass,fail) ;@TEST "encode() emits 'false' for the f sigil"
        new node
        set node="f"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),"false","emit false")
        quit
        ;
tEncodeEmptyString(pass,fail)   ;@TEST "encode() emits ""\"\"\""""
        new node
        set node="s:"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),""""_"""","emit "_""""_""""_"""")
        quit
        ;
tEncodeAsciiString(pass,fail)   ;@TEST "encode() emits a quoted ASCII string"
        new node
        set node="s:hello"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),""""_"hello"_"""","quoted hello")
        quit
        ;
tEncodeStringEscapes(pass,fail) ;@TEST "encode() re-escapes \\ \" / control"
        new node,want
        set node="s:a"_$char(10)_"b"_""""_"c\d"
        ; expect:  "a\nb\"c\\d"
        set want=$char(34)_"a\nb"_$char(92)_$char(34)_"c\\d"_$char(34)
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),want,"reescape applied")
        quit
        ;
tEncodeStringControlChar(pass,fail)     ;@TEST "encode() emits \\u00XX for control bytes lacking a named escape"
        new node,want
        ; $CHAR(1) -> "\u0001"
        set node="s:"_$char(1)
        set want=$char(34)_"\u0001"_$char(34)
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),want,"\\u0001")
        quit
        ;
tEncodeNumber(pass,fail)        ;@TEST "encode() emits the verbatim number string"
        new node
        set node="n:6.022e23"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),"6.022e23","verbatim")
        quit
        ;
tEncodeEmptyObject(pass,fail)   ;@TEST "encode() of empty object is '{}'"
        new node
        set node="o"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),"{}","empty object")
        quit
        ;
tEncodeEmptyArray(pass,fail)    ;@TEST "encode() of empty array is '[]'"
        new node
        set node="a"
        do eq^STDASSERT(.pass,.fail,$$encode^STDJSON(.node),"[]","empty array")
        quit
        ;
tEncodeObject(pass,fail)        ;@TEST "encode() of a 2-pair object emits both members"
        new node,out
        set node="o"
        set node("a")="n:1"
        set node("b")="s:hi"
        set out=$$encode^STDJSON(.node)
        ; M collation: "a" before "b" lexically; numeric subscripts come first
        ; (none here). Expect {"a":1,"b":"hi"}.
        do eq^STDASSERT(.pass,.fail,out,"{"_""""_"a"_""""_":1,"_""""_"b"_""""_":"_""""_"hi"_""""_"}","2-pair object emitted")
        quit
        ;
tEncodeArray(pass,fail) ;@TEST "encode() of a mixed array emits in 1..n order"
        new node,out
        set node="a"
        set node(1)="n:1"
        set node(2)="s:two"
        set node(3)="t"
        set out=$$encode^STDJSON(.node)
        do eq^STDASSERT(.pass,.fail,out,"[1,"_""""_"two"_""""_",true]","mixed array emitted")
        quit
        ;
tEncodeNested(pass,fail)        ;@TEST "encode() walks nested structures"
        new node,out
        set node="o"
        set node("xs")="a"
        set node("xs",1)="n:1"
        set node("xs",2)="n:2"
        set out=$$encode^STDJSON(.node)
        do eq^STDASSERT(.pass,.fail,out,"{"_""""_"xs"_""""_":[1,2]}","object containing array")
        quit
        ;
tEncodeArrayWithGapRaises(pass,fail)    ;@TEST "encode() raises on a gappy array (1,3 with no 2)"
        new node,etrap,errok
        set node="a"
        set node(1)="n:1"
        set node(3)="n:3"
        set errok=0
        new $etrap
        set $etrap="set errok=($ecode["",U-STDJSON-ENCODE,"") set $ecode="""" goto pop"
        do encodeAndDiscard(.node)
pop     do true^STDASSERT(.pass,.fail,errok,"encode of gappy array sets U-STDJSON-ENCODE")
        quit
        ;
encodeAndDiscard(node)
        new x
        set x=$$encode^STDJSON(.node)
        quit
        ;
        ; ============================================================
        ; round-trip
        ; ============================================================
        ;
tRoundTripScalars(pass,fail)    ;@TEST "parse(encode(x)) preserves every scalar type"
        new src,root,back,reback
        for src="null","true","false","42","-7","3.14","6.022e23",""""_"hello"_"""" do
        . do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse "_src)
        . set back=$$encode^STDJSON(.root)
        . do true^STDASSERT(.pass,.fail,$$parse^STDJSON(back,.reback),"reparse "_back)
        . do eq^STDASSERT(.pass,.fail,reback,root,"tree-equal after round-trip "_src)
        quit
        ;
tRoundTripObject(pass,fail)     ;@TEST "object round-trips by re-parsing the encoded form"
        new src,root,back,reback
        set src="{"_""""_"a"_""""_":1,"_""""_"b"_""""_":"_""""_"x"_""""_"}"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse")
        set back=$$encode^STDJSON(.root)
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(back,.reback),"reparse")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.reback("a")),"1","a")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.reback("b")),"x","b")
        quit
        ;
tRoundTripArray(pass,fail)      ;@TEST "array round-trips"
        new src,root,back,reback
        set src="[1,2,3]"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse")
        set back=$$encode^STDJSON(.root)
        do eq^STDASSERT(.pass,.fail,back,"[1,2,3]","encoded form matches")
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(back,.reback),"reparse")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.reback(2)),"2","[2]")
        quit
        ;
tRoundTripNested(pass,fail)     ;@TEST "nested object/array round-trips"
        new src,root,back,reback
        set src="{"_""""_"xs"_""""_":[1,"_""""_"two"_""""_",true,null]}"
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(src,.root),"parse")
        set back=$$encode^STDJSON(.root)
        do true^STDASSERT(.pass,.fail,$$parse^STDJSON(back,.reback),"reparse")
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.reback("xs",4)),"null","[xs][4] still null")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.reback("xs",2)),"two","[xs][2] still 'two'")
        quit
        ;
        ; ============================================================
        ; file I/O smoke
        ; ============================================================
        ;
tParseFileSmoke(pass,fail)      ;@TEST "parseFile() reads a JSON file from disk"
        new path,root
        set path="/tmp/stdjson-parsefile-"_$job_".json"
        open path:(newversion):5  else  do false^STDASSERT(.pass,.fail,1,"open for write failed") quit
        use path
        write "{"_""""_"name"_""""_":"_""""_"Alice"_""""_","_""""_"age"_""""_":30}"
        close path
        do parseFile^STDJSON(path,.root)
        do eq^STDASSERT(.pass,.fail,$ecode,"","parseFile no error")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("name")),"Alice","name=Alice")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.root("age")),"30","age=30")
        open path:(newversion):0  use path  close path:delete
        quit
        ;
tWriteFileSmoke(pass,fail)      ;@TEST "writeFile() emits JSON that parseFile() reads back identically"
        new path,src,back
        set path="/tmp/stdjson-writefile-"_$job_".json"
        set src="o"
        set src("greeting")="s:hello"
        set src("count")="n:3"
        do writeFile^STDJSON(path,.src)
        do parseFile^STDJSON(path,.back)
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.back("greeting")),"hello","greeting round-trips")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.back("count")),"3","count round-trips")
        open path:(newversion):0  use path  close path:delete
        quit
        ;
        ; ============================================================
        ; corpus helpers
        ; ============================================================
        ;
expectOk(p,f,text,desc) ; Helper: assert parse() returns 1 for `text`.
        new root,ok
        set ok=$$parse^STDJSON(text,.root)
        do true^STDASSERT(.p,.f,ok,desc_" -- parse ok")
        quit
        ;
expectFail(p,f,text,desc)       ; Helper: assert parse() returns 0 for `text`.
        new root,ok
        set ok=$$parse^STDJSON(text,.root)
        do false^STDASSERT(.p,.f,ok,desc_" -- parse rejected")
        quit
        ;
