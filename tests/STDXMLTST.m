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
        ; ---- T23 / T24 ----
        do tCommentBeforeRoot(.pass,.fail)
        do tCommentAfterRoot(.pass,.fail)
        do tCommentInsideContent(.pass,.fail)
        do tXmlDeclSkipped(.pass,.fail)
        do tProcessingInstructionSkipped(.pass,.fail)
        do tCdataSectionAsText(.pass,.fail)
        do tCdataPreservesEntitiesAsLiterals(.pass,.fail)
        do tCdataAfterText(.pass,.fail)
        do tNumericCharRefDecimalAscii(.pass,.fail)
        do tNumericCharRefHexAscii(.pass,.fail)
        do tNumericCharRefHigh2Byte(.pass,.fail)
        do tNumericCharRefHigh3Byte(.pass,.fail)
        do tCharRefInAttrValue(.pass,.fail)
        do tParseRejectsUnclosedComment(.pass,.fail)
        do tParseRejectsUnclosedCdata(.pass,.fail)
        ; ---- T25 ----
        do tDefaultNamespaceOnRoot(.pass,.fail)
        do tPrefixedNamespaceOnRoot(.pass,.fail)
        do tDefaultNamespaceInheritedToChild(.pass,.fail)
        do tPrefixedNamespaceInheritedToChild(.pass,.fail)
        do tMultiplePrefixesOnOneElement(.pass,.fail)
        do tNamespaceShadowingByChild(.pass,.fail)
        do tRootNameStripsPrefix(.pass,.fail)
        do tXmlnsNotStoredAsAttribute(.pass,.fail)
        do tNoNamespaceReturnsEmptyNs(.pass,.fail)
        do tUndeclaredPrefixRejected(.pass,.fail)
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
        ;
        ; ---- T23: comments / xml-decl / PI / CDATA ----
tCommentBeforeRoot(pass,fail)   ;@TEST "comment before root element is skipped"
        new root,rc
        set rc=$$parse^STDXML("<!-- header --><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past leading comment")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tCommentAfterRoot(pass,fail)    ;@TEST "comment after root element is skipped"
        new root,rc
        set rc=$$parse^STDXML("<foo/><!-- footer -->",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses with trailing comment")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tCommentInsideContent(pass,fail)        ;@TEST "comment inside element content is skipped"
        new root,rc
        set rc=$$parse^STDXML("<foo>before<!-- mid -->after</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses with mid-content comment")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"beforeafter","comment removed from text")
        quit
        ;
tXmlDeclSkipped(pass,fail)      ;@TEST "<?xml ?> declaration before root is skipped"
        new root,rc
        set rc=$$parse^STDXML("<?xml version=""1.0"" encoding=""UTF-8""?><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past xml decl")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tProcessingInstructionSkipped(pass,fail)        ;@TEST "<?target instruction?> is skipped"
        new root,rc
        set rc=$$parse^STDXML("<?xml-stylesheet href=""s.css""?><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past PI")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tCdataSectionAsText(pass,fail)  ;@TEST "<![CDATA[content]]> is captured as literal text"
        new root,rc
        set rc=$$parse^STDXML("<x><![CDATA[hello world]]></x>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses cdata")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"hello world","cdata content")
        quit
        ;
tCdataPreservesEntitiesAsLiterals(pass,fail)    ;@TEST "CDATA preserves & and < without decoding"
        new root,rc
        set rc=$$parse^STDXML("<x><![CDATA[a&b<c]]></x>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses cdata with literals")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"a&b<c","literal & and < preserved")
        quit
        ;
tCdataAfterText(pass,fail)      ;@TEST "text + CDATA + text concatenates"
        new root,rc
        set rc=$$parse^STDXML("<x>before <![CDATA[mid&dle]]> after</x>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses mixed")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"before mid&dle after","mixed text+cdata")
        quit
        ;
        ; ---- T24: numeric character references ----
tNumericCharRefDecimalAscii(pass,fail)  ;@TEST "&#65; decodes to 'A'"
        new root,rc
        set rc=$$parse^STDXML("<x>&#65;&#66;&#67;</x>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"ABC","decimal ASCII decoded")
        quit
        ;
tNumericCharRefHexAscii(pass,fail)      ;@TEST "&#x41; decodes to 'A'"
        new root,rc
        set rc=$$parse^STDXML("<x>&#x41;&#x42;&#x43;</x>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"ABC","hex ASCII decoded")
        quit
        ;
tNumericCharRefHigh2Byte(pass,fail)     ;@TEST "&#xA9; (©, U+00A9) decodes to UTF-8 2 bytes"
        new root,rc,want
        set rc=$$parse^STDXML("<x>&#xA9;</x>",.root)
        ; UTF-8 encoding of U+00A9: 0xC2 0xA9
        set want=$char(194,169)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),want,"U+00A9 → 0xC2 0xA9")
        quit
        ;
tNumericCharRefHigh3Byte(pass,fail)     ;@TEST "&#x4E2D; (中, U+4E2D) decodes to UTF-8 3 bytes"
        new root,rc,want
        set rc=$$parse^STDXML("<x>&#x4E2D;</x>",.root)
        ; UTF-8 encoding of U+4E2D: 0xE4 0xB8 0xAD
        set want=$char(228,184,173)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),want,"U+4E2D → 0xE4 0xB8 0xAD")
        quit
        ;
tCharRefInAttrValue(pass,fail)  ;@TEST "numeric char refs decode in attribute values"
        new root,rc
        set rc=$$parse^STDXML("<x v=""&#65;&#x42;C""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"v"),"ABC","attr char refs decoded")
        quit
        ;
        ; ---- T23 error paths ----
tParseRejectsUnclosedComment(pass,fail) ;@TEST "parse with unclosed comment returns 0"
        new root,rc
        set rc=$$parse^STDXML("<!-- never closed <foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"unclosed comment rejected")
        quit
        ;
tParseRejectsUnclosedCdata(pass,fail)   ;@TEST "parse with unclosed CDATA returns 0"
        new root,rc
        set rc=$$parse^STDXML("<x><![CDATA[never closed</x>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"unclosed cdata rejected")
        quit
        ;
        ; ---- T25: namespaces (element-level v1) ----
tDefaultNamespaceOnRoot(pass,fail)      ;@TEST "default xmlns puts the root in that namespace"
        new root,rc
        set rc=$$parse^STDXML("<foo xmlns=""urn:default""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","local name preserved")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.root),"urn:default","ns=urn:default")
        quit
        ;
tPrefixedNamespaceOnRoot(pass,fail)     ;@TEST "prefixed xmlns:x binds the element's prefix to that URI"
        new root,rc
        set rc=$$parse^STDXML("<x:foo xmlns:x=""urn:example""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","prefix stripped from name")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.root),"urn:example","ns=urn:example")
        quit
        ;
tDefaultNamespaceInheritedToChild(pass,fail)    ;@TEST "default xmlns inherits to children"
        new root,rc,child
        set rc=$$parse^STDXML("<root xmlns=""urn:d""><child/></root>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.root),"urn:d","root ns")
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"child",.child),"found child")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.child),"urn:d","child inherits ns")
        quit
        ;
tPrefixedNamespaceInheritedToChild(pass,fail)   ;@TEST "prefix declarations are visible to children"
        new root,rc,child
        set rc=$$parse^STDXML("<x:r xmlns:x=""urn:X""><x:c/></x:r>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.root),"urn:X","root ns")
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"c",.child),"found c")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.child),"urn:X","child uses inherited prefix")
        quit
        ;
tMultiplePrefixesOnOneElement(pass,fail)        ;@TEST "two xmlns:* declarations bind two prefixes"
        new root,rc,a,b
        set rc=$$parse^STDXML("<r xmlns:a=""urn:A"" xmlns:b=""urn:B""><a:x/><b:y/></r>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"x",.a),"found x")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.a),"urn:A","x in urn:A")
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"y",.b),"found y")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.b),"urn:B","y in urn:B")
        quit
        ;
tNamespaceShadowingByChild(pass,fail)   ;@TEST "child xmlns shadows the parent's binding"
        new root,rc,child
        set rc=$$parse^STDXML("<r xmlns=""urn:outer""><c xmlns=""urn:inner""/></r>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.root),"urn:outer","root in outer")
        do true^STDASSERT(.pass,.fail,$$childByName^STDXML(.root,"c",.child),"found c")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.child),"urn:inner","c shadowed to inner")
        quit
        ;
tRootNameStripsPrefix(pass,fail)        ;@TEST "rootName returns local part when a prefix was used"
        new root,rc
        set rc=$$parse^STDXML("<x:foo xmlns:x=""urn:e""/>",.root)
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","local name only")
        quit
        ;
tXmlnsNotStoredAsAttribute(pass,fail)   ;@TEST "xmlns / xmlns:* declarations don't appear via attr()"
        new root,rc
        set rc=$$parse^STDXML("<foo xmlns=""urn:d"" xmlns:x=""urn:e"" id=""abc""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"xmlns"),"","xmlns not in attrs")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"xmlns:x"),"","xmlns:x not in attrs")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"id"),"abc","regular attr present")
        quit
        ;
tNoNamespaceReturnsEmptyNs(pass,fail)   ;@TEST "ns() of an element without xmlns returns ''"
        new root,rc
        set rc=$$parse^STDXML("<plain/>",.root)
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.root),"","ns='' for non-namespaced element")
        quit
        ;
tUndeclaredPrefixRejected(pass,fail)    ;@TEST "an undeclared prefix is a parse error"
        new root,rc
        set rc=$$parse^STDXML("<x:foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"undeclared prefix rejected")
        quit
