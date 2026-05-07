STDXMLTST       ; Test suite for STDXML (v0.2.x — Phase 4, in-progress).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tParseSelfClosing(.pass,.fail)
        do tParseElementWithText(.pass,.fail)
        do tParseElementWithAttribute(.pass,.fail)
        do tParseElementWithMultipleAttrs(.pass,.fail)
        do tParseNestedSimple(.pass,.fail)
        do tParseNestedDeep(.pass,.fail)
        do tParseTwoSiblings(.pass,.fail)
        do tParseAroundWhitespaceTolerated(.pass,.fail)
        do tEntitiesDecodedInText(.pass,.fail)
        do tEntitiesDecodedInAttr(.pass,.fail)
        do tRootNameReturnsTag(.pass,.fail)
        do tAttrReturnsValue(.pass,.fail)
        do tAttrMissingReturnsEmpty(.pass,.fail)
        do tTextReturnsContent(.pass,.fail)
        do tChildCountReturnsCount(.pass,.fail)
        do tChildByNameFindsFirstMatch(.pass,.fail)
        do tChildByNameMissingReturnsZero(.pass,.fail)
        do tValidPredicate(.pass,.fail)
        do tParseRejectsUnclosedTag(.pass,.fail)
        do tParseRejectsMismatchedClose(.pass,.fail)
        do tParseRejectsMissingGreaterThan(.pass,.fail)
        do tParseRejectsEmpty(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- parse: structural ----
tParseSelfClosing(pass,fail)    ;@TEST "parse('<foo/>') populates root with name=foo"
        new root,rc
        set rc=$$parse^STDXML("<foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses ok")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root name=foo")
        quit
        ;
tParseElementWithText(pass,fail)        ;@TEST "parse('<foo>hello</foo>') captures text"
        new root,rc
        set rc=$$parse^STDXML("<foo>hello</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"hello","text=hello")
        quit
        ;
tParseElementWithAttribute(pass,fail)   ;@TEST "parse('<foo bar=\"baz\"/>') captures the attribute"
        new root,rc
        set rc=$$parse^STDXML("<foo bar=""baz""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"bar"),"baz","attr bar=baz")
        quit
        ;
tParseElementWithMultipleAttrs(pass,fail)       ;@TEST "parse with two attributes captures both"
        new root,rc
        set rc=$$parse^STDXML("<foo a=""1"" b=""2""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"a"),"1","a=1")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"b"),"2","b=2")
        quit
        ;
tParseNestedSimple(pass,fail)   ;@TEST "parse('<root><child/></root>') has 1 child"
        new root,rc
        set rc=$$parse^STDXML("<root><child/></root>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"root","root=root")
        do eq^STDASSERT(.pass,.fail,$$childCount^STDXML(.root),1,"childCount=1")
        quit
        ;
tParseNestedDeep(pass,fail)     ;@TEST "parse('<a><b><c>deep</c></b></a>') has 1 child of 1 child"
        new root,rc,b,c
        set rc=$$parse^STDXML("<a><b><c>deep</c></b></a>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"a","root=a")
        do eq^STDASSERT(.pass,.fail,$$childCount^STDXML(.root),1,"a has 1 child")
        ; descend via childByName which uses merge-then-pass
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"b",.b),"found b under a")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.b),"b","b=b")
        do eq^STDASSERT(.pass,.fail,$$childCount^STDXML(.b),1,"b has 1 child")
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.b,"c",.c),"found c under b")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.c),"deep","c text=deep")
        quit
        ;
tParseTwoSiblings(pass,fail)    ;@TEST "parse with two sibling children gives childCount=2"
        new root,rc
        set rc=$$parse^STDXML("<r><a/><b/></r>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$childCount^STDXML(.root),2,"two children")
        quit
        ;
tParseAroundWhitespaceTolerated(pass,fail)      ;@TEST "whitespace between tags is tolerated"
        new root,rc
        set rc=$$parse^STDXML("  <foo>  hi  </foo>  ",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses with surrounding whitespace")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
        ; ---- entity decoding ----
tEntitiesDecodedInText(pass,fail)       ;@TEST "the 5 standard entities decode in text content"
        new root,rc
        set rc=$$parse^STDXML("<x>&amp;&lt;&gt;&quot;&apos;</x>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"&<>""'","entity decode")
        quit
        ;
tEntitiesDecodedInAttr(pass,fail)       ;@TEST "the 5 standard entities decode in attribute values"
        new root,rc
        set rc=$$parse^STDXML("<x v=""&amp;&lt;&gt;&quot;&apos;""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"v"),"&<>""'","attr entity decode")
        quit
        ;
        ; ---- accessors ----
tRootNameReturnsTag(pass,fail)  ;@TEST "rootName returns the element tag"
        new root,rc
        set rc=$$parse^STDXML("<bookstore/>",.root)
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"bookstore","tag=bookstore")
        quit
        ;
tAttrReturnsValue(pass,fail)    ;@TEST "attr() returns the value for a present attribute"
        new root,rc
        set rc=$$parse^STDXML("<x id=""abc""/>",.root)
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"id"),"abc","id=abc")
        quit
        ;
tAttrMissingReturnsEmpty(pass,fail)     ;@TEST "attr() returns '' for an absent attribute"
        new root,rc
        set rc=$$parse^STDXML("<x/>",.root)
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"missing"),"","absent → ''")
        quit
        ;
tTextReturnsContent(pass,fail)  ;@TEST "text() returns the direct text content"
        new root,rc
        set rc=$$parse^STDXML("<x>hello world</x>",.root)
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"hello world","text=hello world")
        quit
        ;
tChildCountReturnsCount(pass,fail)      ;@TEST "childCount() returns the number of element children"
        new root,rc
        set rc=$$parse^STDXML("<r><a/><b/><c/></r>",.root)
        do eq^STDASSERT(.pass,.fail,$$childCount^STDXML(.root),3,"three children")
        do eq^STDASSERT(.pass,.fail,$$childCount^STDXML(.root),3,"idempotent read")
        quit
        ;
tChildByNameFindsFirstMatch(pass,fail)  ;@TEST "childByName populates the child subtree and returns 1"
        new root,rc,child
        set rc=$$parse^STDXML("<r><a id=""1""/><b id=""2""/></r>",.root)
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"b",.child),"found b")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.child),"b","child name=b")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.child,"id"),"2","child attr id=2")
        quit
        ;
tChildByNameMissingReturnsZero(pass,fail)       ;@TEST "childByName returns 0 if no child matches"
        new root,rc,child
        set rc=$$parse^STDXML("<r><a/></r>",.root)
        do false^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"missing",.child),"no match")
        quit
        ;
        ; ---- valid / error paths ----
tValidPredicate(pass,fail)      ;@TEST "valid() agrees with parse()'s success bit"
        do true^STDASSERT(.pass,.fail,$$valid^STDXML("<foo/>"),"valid <foo/>")
        do true^STDASSERT(.pass,.fail,$$valid^STDXML("<foo>x</foo>"),"valid <foo>x</foo>")
        do false^STDASSERT(.pass,.fail,$$valid^STDXML("<foo>"),"unclosed invalid")
        do false^STDASSERT(.pass,.fail,$$valid^STDXML(""),"empty invalid")
        quit
        ;
tParseRejectsUnclosedTag(pass,fail)     ;@TEST "parse('<foo>') returns 0"
        new root,rc
        set rc=$$parse^STDXML("<foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"unclosed rejected")
        quit
        ;
tParseRejectsMismatchedClose(pass,fail) ;@TEST "parse('<foo></bar>') returns 0"
        new root,rc
        set rc=$$parse^STDXML("<foo></bar>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"mismatched close rejected")
        quit
        ;
tParseRejectsMissingGreaterThan(pass,fail)      ;@TEST "parse('<foo') returns 0"
        new root,rc
        set rc=$$parse^STDXML("<foo",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"missing > rejected")
        quit
        ;
tParseRejectsEmpty(pass,fail)   ;@TEST "parse('') returns 0"
        new root,rc
        set rc=$$parse^STDXML("",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"empty rejected")
        quit
