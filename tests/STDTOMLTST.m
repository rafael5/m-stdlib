STDTOMLTST      ; Test suite for STDTOML (v0.2.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tParseEmptyReturnsOk(.pass,.fail)
        do tParseSinglePair(.pass,.fail)
        do tParseTwoPairs(.pass,.fail)
        do tParseStringValue(.pass,.fail)
        do tParseStringWithSpaces(.pass,.fail)
        do tParseStringWithEscapes(.pass,.fail)
        do tParseIntegerPositive(.pass,.fail)
        do tParseIntegerNegative(.pass,.fail)
        do tParseIntegerZero(.pass,.fail)
        do tParseFloatBasic(.pass,.fail)
        do tParseFloatNegative(.pass,.fail)
        do tParseBoolTrue(.pass,.fail)
        do tParseBoolFalse(.pass,.fail)
        do tParseCommentLine(.pass,.fail)
        do tParseCommentTrailing(.pass,.fail)
        do tParseBlankLinesIgnored(.pass,.fail)
        do tParseTableHeader(.pass,.fail)
        do tParseTwoTables(.pass,.fail)
        do tParseTableThenTopLevel(.pass,.fail)
        do tGetReturnsValue(.pass,.fail)
        do tGetSectionDottedSyntax(.pass,.fail)
        do tGetReturnsEmptyForMissing(.pass,.fail)
        do tTypeReportsKind(.pass,.fail)
        do tTypeMissingReturnsEmpty(.pass,.fail)
        do tParseRejectsMalformed(.pass,.fail)
        do tParseRejectsDuplicateKey(.pass,.fail)
        do tParseRejectsUnknownLine(.pass,.fail)
        do tValidPredicate(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- parse / valid basic ----
tParseEmptyReturnsOk(pass,fail) ;@TEST "parse('') returns 1 with empty root"
        new root,rc
        set rc=$$parse^STDTOML("",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"empty doc parses ok")
        quit
        ;
tParseSinglePair(pass,fail)     ;@TEST "parse('key = \"value\"') returns 1 and stores under root"
        new root,rc
        set rc=$$parse^STDTOML("key = ""value""",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"single pair ok")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"key"),"value","key=value")
        quit
        ;
tParseTwoPairs(pass,fail)       ;@TEST "two pairs on separate lines populate both"
        new root,rc,doc
        set doc="a = 1"_$char(10)_"b = 2"
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"two pairs ok")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"a"),1,"a=1")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"b"),2,"b=2")
        quit
        ;
        ; ---- string values ----
tParseStringValue(pass,fail)    ;@TEST "string value preserves bytes between the quotes"
        new root,rc
        set rc=$$parse^STDTOML("name = ""hello""",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"name"),"hello","name=hello")
        quit
        ;
tParseStringWithSpaces(pass,fail)       ;@TEST "string value preserves embedded spaces"
        new root,rc
        set rc=$$parse^STDTOML("greeting = ""hello world""",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"greeting"),"hello world","preserved")
        quit
        ;
tParseStringWithEscapes(pass,fail)      ;@TEST "string value decodes \\n \\t \\\" \\\\"
        new root,rc
        set rc=$$parse^STDTOML("s = ""a\tb\nc\""d\\e""",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"s"),"a"_$char(9)_"b"_$char(10)_"c""d\e","escapes decoded")
        quit
        ;
        ; ---- integers ----
tParseIntegerPositive(pass,fail)        ;@TEST "positive integer parses"
        new root,rc
        set rc=$$parse^STDTOML("port = 8080",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"port"),8080,"port=8080")
        quit
        ;
tParseIntegerNegative(pass,fail)        ;@TEST "negative integer parses"
        new root,rc
        set rc=$$parse^STDTOML("offset = -42",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"offset"),-42,"offset=-42")
        quit
        ;
tParseIntegerZero(pass,fail)    ;@TEST "zero integer parses"
        new root,rc
        set rc=$$parse^STDTOML("count = 0",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"count"),0,"count=0")
        quit
        ;
        ; ---- floats ----
tParseFloatBasic(pass,fail)     ;@TEST "decimal float parses"
        new root,rc
        set rc=$$parse^STDTOML("ratio = 1.5",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"ratio"),1.5,"ratio=1.5")
        quit
        ;
tParseFloatNegative(pass,fail)  ;@TEST "negative float parses"
        new root,rc
        set rc=$$parse^STDTOML("delta = -0.25",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"delta"),-0.25,"delta=-0.25")
        quit
        ;
        ; ---- booleans ----
tParseBoolTrue(pass,fail)       ;@TEST "true parses to 1"
        new root,rc
        set rc=$$parse^STDTOML("enabled = true",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"enabled"),1,"true=1")
        do eq^STDASSERT(.pass,.fail,$$type^STDTOML(.root,"enabled"),"bool","kind=bool")
        quit
        ;
tParseBoolFalse(pass,fail)      ;@TEST "false parses to 0"
        new root,rc
        set rc=$$parse^STDTOML("verbose = false",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"verbose"),0,"false=0")
        do eq^STDASSERT(.pass,.fail,$$type^STDTOML(.root,"verbose"),"bool","kind=bool")
        quit
        ;
        ; ---- comments / blank lines ----
tParseCommentLine(pass,fail)    ;@TEST "lines starting with # are ignored"
        new root,rc,doc
        set doc="# this is a comment"_$char(10)_"x = 1"
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past comment")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"x"),1,"x=1")
        quit
        ;
tParseCommentTrailing(pass,fail)        ;@TEST "trailing # comment after a value is stripped"
        new root,rc
        set rc=$$parse^STDTOML("port = 80  # http",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"port"),80,"port=80")
        quit
        ;
tParseBlankLinesIgnored(pass,fail)      ;@TEST "blank lines and runs of whitespace are tolerated"
        new root,rc,doc
        set doc=""_$char(10)_"a = 1"_$char(10)_$char(10)_"b = 2"_$char(10)_""
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"a"),1,"a=1")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"b"),2,"b=2")
        quit
        ;
        ; ---- tables ----
tParseTableHeader(pass,fail)    ;@TEST "[section] header scopes following pairs"
        new root,rc,doc
        set doc="[server]"_$char(10)_"host = ""localhost"""_$char(10)_"port = 80"
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"server.host"),"localhost","server.host")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"server.port"),80,"server.port")
        quit
        ;
tParseTwoTables(pass,fail)      ;@TEST "two [section] headers scope independently"
        new root,rc,doc
        set doc="[a]"_$char(10)_"x = 1"_$char(10)_"[b]"_$char(10)_"x = 2"
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"a.x"),1,"a.x=1")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"b.x"),2,"b.x=2")
        quit
        ;
tParseTableThenTopLevel(pass,fail)      ;@TEST "top-level pairs before any header land at root"
        new root,rc,doc
        set doc="title = ""m-stdlib"""_$char(10)_"[meta]"_$char(10)_"version = ""0.2.0"""
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"title"),"m-stdlib","top-level title")
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"meta.version"),"0.2.0","meta.version")
        quit
        ;
        ; ---- get / type introspection ----
tGetReturnsValue(pass,fail)     ;@TEST "get(.tree, key) returns the stored value"
        new root,rc
        set rc=$$parse^STDTOML("k = 42",.root)
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"k"),42,"k=42")
        quit
        ;
tGetSectionDottedSyntax(pass,fail)      ;@TEST "get(.tree, 'section.key') accesses a sectioned value"
        new root,rc,doc
        set doc="[s]"_$char(10)_"k = ""v"""
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"s.k"),"v","s.k=v")
        quit
        ;
tGetReturnsEmptyForMissing(pass,fail)   ;@TEST "get of an absent key returns ''"
        new root,rc
        set rc=$$parse^STDTOML("k = 1",.root)
        do eq^STDASSERT(.pass,.fail,$$get^STDTOML(.root,"missing"),"","absent returns ''")
        quit
        ;
tTypeReportsKind(pass,fail)     ;@TEST "type(.tree, key) returns string/integer/float/bool"
        new root,rc,doc
        set doc="s = ""x"""_$char(10)_"i = 1"_$char(10)_"f = 1.5"_$char(10)_"b = true"
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,$$type^STDTOML(.root,"s"),"string","string kind")
        do eq^STDASSERT(.pass,.fail,$$type^STDTOML(.root,"i"),"integer","integer kind")
        do eq^STDASSERT(.pass,.fail,$$type^STDTOML(.root,"f"),"float","float kind")
        do eq^STDASSERT(.pass,.fail,$$type^STDTOML(.root,"b"),"bool","bool kind")
        quit
        ;
tTypeMissingReturnsEmpty(pass,fail)     ;@TEST "type of an absent key returns ''"
        new root,rc
        set rc=$$parse^STDTOML("k = 1",.root)
        do eq^STDASSERT(.pass,.fail,$$type^STDTOML(.root,"missing"),"","absent returns ''")
        quit
        ;
        ; ---- error paths ----
tParseRejectsMalformed(pass,fail)       ;@TEST "parse('= 1') returns 0 and root stays empty"
        new root,rc
        set rc=$$parse^STDTOML("= 1",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"missing key rejected")
        quit
        ;
tParseRejectsDuplicateKey(pass,fail)    ;@TEST "duplicate key in same scope returns 0"
        new root,rc,doc
        set doc="k = 1"_$char(10)_"k = 2"
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"duplicate rejected")
        quit
        ;
tParseRejectsUnknownLine(pass,fail)     ;@TEST "an unparseable non-blank line returns 0"
        new root,rc,doc
        set doc="x = 1"_$char(10)_"this is not toml"
        set rc=$$parse^STDTOML(doc,.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"junk rejected")
        quit
        ;
tValidPredicate(pass,fail)      ;@TEST "valid() agrees with parse()'s success bit"
        do true^STDASSERT(.pass,.fail,$$valid^STDTOML("k = 1"),"valid k=1")
        do true^STDASSERT(.pass,.fail,$$valid^STDTOML(""),"valid empty")
        do false^STDASSERT(.pass,.fail,$$valid^STDTOML("= 1"),"invalid bare =")
        do false^STDASSERT(.pass,.fail,$$valid^STDTOML("not toml at all"),"invalid junk")
        quit
