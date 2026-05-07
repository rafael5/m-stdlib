STDENVTST       ; Test suite for STDENV (v0.2.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tParseEmptyReturnsOk(.pass,.fail)
        do tParseSinglePair(.pass,.fail)
        do tParseTwoPairs(.pass,.fail)
        do tParseDoubleQuoted(.pass,.fail)
        do tParseSingleQuoted(.pass,.fail)
        do tParseQuotesPreserveSpaces(.pass,.fail)
        do tParseDoubleQuoteEscapes(.pass,.fail)
        do tParseCommentLine(.pass,.fail)
        do tParseBlankLines(.pass,.fail)
        do tParseLeadingTrailingSpace(.pass,.fail)
        do tParseRejectsBareEquals(.pass,.fail)
        do tParseRejectsInvalidKey(.pass,.fail)
        do tValidPredicate(.pass,.fail)
        do tHasReturnsTrueForKnown(.pass,.fail)
        do tHasReturnsFalseForUnknown(.pass,.fail)
        do tGetReturnsValue(.pass,.fail)
        do tGetReturnsDefaultForMissing(.pass,.fail)
        do tGetIntReturnsNumber(.pass,.fail)
        do tGetIntReturnsDefaultForNonNumeric(.pass,.fail)
        do tGetBoolTrueValues(.pass,.fail)
        do tGetBoolFalseValues(.pass,.fail)
        do tGetBoolReturnsDefaultForUnrecognized(.pass,.fail)
        do tGetFloatReturnsNumber(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- parse / valid basic ----
tParseEmptyReturnsOk(pass,fail) ;@TEST "parse('') returns 1 with empty env"
        new env,rc
        set rc=$$parse^STDENV("",.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"empty doc parses ok")
        quit
        ;
tParseSinglePair(pass,fail)     ;@TEST "parse('FOO=bar') stores FOO=bar"
        new env,rc
        set rc=$$parse^STDENV("FOO=bar",.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"single pair ok")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"FOO",""),"bar","FOO=bar")
        quit
        ;
tParseTwoPairs(pass,fail)       ;@TEST "two pairs on separate lines populate both"
        new env,rc,doc
        set doc="A=1"_$char(10)_"B=2"
        set rc=$$parse^STDENV(doc,.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"two pairs ok")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"A",""),"1","A=1")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"B",""),"2","B=2")
        quit
        ;
        ; ---- quoting ----
tParseDoubleQuoted(pass,fail)   ;@TEST "double-quoted value is unwrapped"
        new env,rc
        set rc=$$parse^STDENV("NAME=""hello""",.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"NAME",""),"hello","unwrapped value")
        quit
        ;
tParseSingleQuoted(pass,fail)   ;@TEST "single-quoted value is unwrapped"
        new env,rc
        set rc=$$parse^STDENV("NAME='hello'",.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"NAME",""),"hello","unwrapped single-quoted")
        quit
        ;
tParseQuotesPreserveSpaces(pass,fail)   ;@TEST "quoted values preserve embedded spaces"
        new env,rc
        set rc=$$parse^STDENV("MSG=""hello world""",.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"MSG",""),"hello world","spaces preserved")
        quit
        ;
tParseDoubleQuoteEscapes(pass,fail)     ;@TEST "double-quoted value decodes \\n \\t \\\""
        new env,rc
        set rc=$$parse^STDENV("S=""a\tb\nc\""d""",.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"S",""),"a"_$char(9)_"b"_$char(10)_"c""d","escapes decoded")
        quit
        ;
        ; ---- comments / blank lines ----
tParseCommentLine(pass,fail)    ;@TEST "lines starting with # are ignored"
        new env,rc,doc
        set doc="# this is a comment"_$char(10)_"X=1"
        set rc=$$parse^STDENV(doc,.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past comment")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"X",""),"1","X=1")
        do false^STDASSERT(.pass,.fail,$$has^STDENV(.env,"#"),"# not stored as a key")
        quit
        ;
tParseBlankLines(pass,fail)     ;@TEST "blank lines are tolerated"
        new env,rc,doc
        set doc=""_$char(10)_"A=1"_$char(10)_$char(10)_"B=2"_$char(10)_""
        set rc=$$parse^STDENV(doc,.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"A",""),"1","A=1")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"B",""),"2","B=2")
        quit
        ;
tParseLeadingTrailingSpace(pass,fail)   ;@TEST "leading/trailing whitespace around the = is stripped"
        new env,rc
        set rc=$$parse^STDENV("  KEY  =  value  ",.env)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"KEY",""),"value","whitespace stripped")
        quit
        ;
        ; ---- error paths ----
tParseRejectsBareEquals(pass,fail)      ;@TEST "parse('=value') returns 0"
        new env,rc
        set rc=$$parse^STDENV("=value",.env)
        do eq^STDASSERT(.pass,.fail,rc,0,"empty key rejected")
        quit
        ;
tParseRejectsInvalidKey(pass,fail)      ;@TEST "parse('1KEY=value') returns 0 (key must start with letter or _)"
        new env,rc
        set rc=$$parse^STDENV("1KEY=value",.env)
        do eq^STDASSERT(.pass,.fail,rc,0,"leading-digit key rejected")
        quit
        ;
tValidPredicate(pass,fail)      ;@TEST "valid() agrees with parse() success bit"
        do true^STDASSERT(.pass,.fail,$$valid^STDENV("K=V"),"valid K=V")
        do true^STDASSERT(.pass,.fail,$$valid^STDENV(""),"valid empty")
        do false^STDASSERT(.pass,.fail,$$valid^STDENV("=V"),"invalid empty key")
        quit
        ;
        ; ---- has / get ----
tHasReturnsTrueForKnown(pass,fail)      ;@TEST "has(.env, key) is 1 for a stored key"
        new env,rc
        set rc=$$parse^STDENV("FOO=bar",.env)
        do true^STDASSERT(.pass,.fail,$$has^STDENV(.env,"FOO"),"FOO present")
        quit
        ;
tHasReturnsFalseForUnknown(pass,fail)   ;@TEST "has(.env, key) is 0 for an absent key"
        new env,rc
        set rc=$$parse^STDENV("FOO=bar",.env)
        do false^STDASSERT(.pass,.fail,$$has^STDENV(.env,"BAZ"),"BAZ absent")
        quit
        ;
tGetReturnsValue(pass,fail)     ;@TEST "get(.env, key, default) returns value when present"
        new env,rc
        set rc=$$parse^STDENV("FOO=bar",.env)
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"FOO","fallback"),"bar","value present")
        quit
        ;
tGetReturnsDefaultForMissing(pass,fail) ;@TEST "get(.env, missing, default) returns default"
        new env,rc
        set rc=$$parse^STDENV("FOO=bar",.env)
        do eq^STDASSERT(.pass,.fail,$$get^STDENV(.env,"missing","fallback"),"fallback","default returned")
        quit
        ;
        ; ---- typed accessors ----
tGetIntReturnsNumber(pass,fail) ;@TEST "getInt() coerces a numeric value"
        new env,rc
        set rc=$$parse^STDENV("PORT=8080",.env)
        do eq^STDASSERT(.pass,.fail,$$getInt^STDENV(.env,"PORT",0),8080,"PORT=8080")
        quit
        ;
tGetIntReturnsDefaultForNonNumeric(pass,fail)   ;@TEST "getInt() falls back to default for non-numeric values"
        new env,rc
        set rc=$$parse^STDENV("PORT=high",.env)
        do eq^STDASSERT(.pass,.fail,$$getInt^STDENV(.env,"PORT",-1),-1,"non-numeric falls back")
        do eq^STDASSERT(.pass,.fail,$$getInt^STDENV(.env,"missing",-2),-2,"missing falls back")
        quit
        ;
tGetBoolTrueValues(pass,fail)   ;@TEST "getBool() recognises true/yes/on/1 as true"
        new env,rc,i
        for i=1:1:4 do
        . set rc=$$parse^STDENV("F="_$piece("true,yes,on,1",",",i),.env)
        . do true^STDASSERT(.pass,.fail,$$getBool^STDENV(.env,"F",0),"true value: "_$piece("true,yes,on,1",",",i))
        quit
        ;
tGetBoolFalseValues(pass,fail)  ;@TEST "getBool() recognises false/no/off/0 as false"
        new env,rc,i
        for i=1:1:4 do
        . set rc=$$parse^STDENV("F="_$piece("false,no,off,0",",",i),.env)
        . do false^STDASSERT(.pass,.fail,$$getBool^STDENV(.env,"F",1),"false value: "_$piece("false,no,off,0",",",i))
        quit
        ;
tGetBoolReturnsDefaultForUnrecognized(pass,fail)        ;@TEST "getBool() falls back to default for ambiguous values"
        new env,rc
        set rc=$$parse^STDENV("F=maybe",.env)
        do true^STDASSERT(.pass,.fail,$$getBool^STDENV(.env,"F",1),"unrecognized → default true")
        do false^STDASSERT(.pass,.fail,$$getBool^STDENV(.env,"F",0),"unrecognized → default false")
        do true^STDASSERT(.pass,.fail,$$getBool^STDENV(.env,"missing",1),"missing → default true")
        quit
        ;
tGetFloatReturnsNumber(pass,fail)       ;@TEST "getFloat() coerces a numeric value"
        new env,rc
        set rc=$$parse^STDENV("RATIO=1.5",.env)
        do eq^STDASSERT(.pass,.fail,$$getFloat^STDENV(.env,"RATIO",0),1.5,"RATIO=1.5")
        quit
