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
        ; ---- T25b ----
        do tAttrNsUnprefixedReturnsEmpty(.pass,.fail)
        do tAttrNsPrefixedReturnsUri(.pass,.fail)
        do tAttrNsMissingAttrReturnsEmpty(.pass,.fail)
        do tAttrNsDefaultXmlnsDoesNotApply(.pass,.fail)
        do tAttrNsXmlBuiltinPrefix(.pass,.fail)
        do tAttrNsMixedPrefixedUnprefixed(.pass,.fail)
        do tAttrNsUndeclaredPrefixRejected(.pass,.fail)
        ; ---- T27 ----
        do tXpathRelativeChild(.pass,.fail)
        do tXpathAbsoluteRoot(.pass,.fail)
        do tXpathChainedPath(.pass,.fail)
        do tXpathMultipleSiblingMatches(.pass,.fail)
        do tXpathPositionPredicate(.pass,.fail)
        do tXpathDescendantAxis(.pass,.fail)
        do tXpathDescendantWithPredicate(.pass,.fail)
        do tXpathNoMatchReturnsZero(.pass,.fail)
        do tXpathOneFirstMatch(.pass,.fail)
        do tXpathOneMissingReturnsZero(.pass,.fail)
        do tXpathTextReturnsContent(.pass,.fail)
        do tXpathTextMissingReturnsEmpty(.pass,.fail)
        ; ---- T27a ----
        do tXpathWildcardChild(.pass,.fail)
        do tXpathWildcardWithPredicate(.pass,.fail)
        do tXpathDescendantWildcard(.pass,.fail)
        do tXpathChildOfWildcard(.pass,.fail)
        do tXpathAttributeAxis(.pass,.fail)
        do tXpathAttributeOnChild(.pass,.fail)
        do tXpathAttributeMissingReturnsZero(.pass,.fail)
        do tXpathAttributeWildcard(.pass,.fail)
        do tXpathDescendantAttribute(.pass,.fail)
        do tXpathAttributeViaXpathText(.pass,.fail)
        ; ---- T27b ----
        do tXpathPredicateAttrEqualsString(.pass,.fail)
        do tXpathPredicateAttrEqualsDoubleQuoted(.pass,.fail)
        do tXpathPredicateAttrNotEquals(.pass,.fail)
        do tXpathPredicateNameEquals(.pass,.fail)
        do tXpathPredicateTextEquals(.pass,.fail)
        do tXpathPredicateContains(.pass,.fail)
        do tXpathPredicateStartsWith(.pass,.fail)
        do tXpathPredicatePositionEqual(.pass,.fail)
        do tXpathPredicateCountEquals(.pass,.fail)
        do tXpathPredicateCountGreaterThan(.pass,.fail)
        do tXpathPredicateStringLengthGt(.pass,.fail)
        do tXpathPredicateNormalizeSpace(.pass,.fail)
        do tXpathPredicateAttrExistsTruthy(.pass,.fail)
        do tXpathPredicateAttrExistsFiltersOut(.pass,.fail)
        do tXpathPredicateRejectsBadExpr(.pass,.fail)
        ;
        ; ---- T26: DTD / DOCTYPE / custom entities ----
        do tDoctypeNoSubsetSkipped(.pass,.fail)
        do tDoctypeEmptyInternalSubsetSkipped(.pass,.fail)
        do tDoctypeSystemExternalSkipped(.pass,.fail)
        do tDoctypeSystemPlusInternalSubsetSkipped(.pass,.fail)
        do tDoctypePublicExternalSkipped(.pass,.fail)
        do tEntityDeclExpandsInText(.pass,.fail)
        do tEntityDeclExpandsInAttribute(.pass,.fail)
        do tEntityDeclSingleQuotedValue(.pass,.fail)
        do tEntityDeclMultipleDecls(.pass,.fail)
        do tEntityDeclWithCommentsAndPI(.pass,.fail)
        do tEntityDeclIgnoresElementAttlistNotation(.pass,.fail)
        do tDoctypeCommentBetweenDecls(.pass,.fail)
        do tDoctypeUnclosedRejected(.pass,.fail)
        do tEntityDeclUnclosedSubsetRejected(.pass,.fail)
        do tBuiltinEntitiesStillWork(.pass,.fail)
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
        ;
        ; ---- T25b: attribute-namespace resolution ----
tAttrNsUnprefixedReturnsEmpty(pass,fail)        ;@TEST "attrNs of an unprefixed attribute is ''"
        new root,rc
        set rc=$$parse^STDXML("<foo id=""abc""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attrNs^STDXML(.root,"id"),"","unprefixed → empty ns")
        quit
        ;
tAttrNsPrefixedReturnsUri(pass,fail)    ;@TEST "attrNs of a prefixed attribute returns the resolved URI"
        new root,rc
        set rc=$$parse^STDXML("<foo xmlns:x=""urn:example"" x:bar=""1""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"x:bar"),"1","attr value")
        do eq^STDASSERT(.pass,.fail,$$attrNs^STDXML(.root,"x:bar"),"urn:example","resolved URI")
        quit
        ;
tAttrNsMissingAttrReturnsEmpty(pass,fail)       ;@TEST "attrNs of an absent attribute is ''"
        new root,rc
        set rc=$$parse^STDXML("<foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attrNs^STDXML(.root,"missing"),"","missing → empty")
        quit
        ;
tAttrNsDefaultXmlnsDoesNotApply(pass,fail)      ;@TEST "default xmlns does NOT give unprefixed attrs a namespace"
        ; Per XML Namespaces 1.0 §6.2: "the namespace name for an unprefixed
        ; attribute name always has no value".
        new root,rc
        set rc=$$parse^STDXML("<foo xmlns=""urn:default"" id=""abc""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$ns^STDXML(.root),"urn:default","element has default ns")
        do eq^STDASSERT(.pass,.fail,$$attrNs^STDXML(.root,"id"),"","attr does NOT inherit default")
        quit
        ;
tAttrNsXmlBuiltinPrefix(pass,fail)      ;@TEST "the built-in 'xml:' prefix resolves without a declaration"
        ; Per XML Namespaces 1.0 §3: the 'xml' prefix is bound to
        ; "http://www.w3.org/XML/1998/namespace" by definition; needn't be declared.
        new root,rc
        set rc=$$parse^STDXML("<foo xml:lang=""en""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses (no parse error for xml:)")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"xml:lang"),"en","value")
        do eq^STDASSERT(.pass,.fail,$$attrNs^STDXML(.root,"xml:lang"),"http://www.w3.org/XML/1998/namespace","built-in xml namespace")
        quit
        ;
tAttrNsMixedPrefixedUnprefixed(pass,fail)       ;@TEST "mixed prefixed and unprefixed attrs each get the right ns"
        new root,rc
        set rc=$$parse^STDXML("<foo xmlns:a=""urn:A"" id=""1"" a:type=""x""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses")
        do eq^STDASSERT(.pass,.fail,$$attrNs^STDXML(.root,"id"),"","unprefixed attr no ns")
        do eq^STDASSERT(.pass,.fail,$$attrNs^STDXML(.root,"a:type"),"urn:A","prefixed attr in urn:A")
        quit
        ;
tAttrNsUndeclaredPrefixRejected(pass,fail)      ;@TEST "an undeclared prefix on an attr is a parse error"
        new root,rc
        set rc=$$parse^STDXML("<foo bogus:attr=""x""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"undeclared attr prefix rejected")
        quit
        ;
        ; ---- T27: XPath subset ----
tXpathRelativeChild(pass,fail)  ;@TEST "xpath('child') finds direct children with that name"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a/><b/><a/></r>",.root)
        set n=$$xpath^STDXML(.root,"a",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two 'a' children")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"name")),"a","first match name")
        do eq^STDASSERT(.pass,.fail,$get(results(2,"name")),"a","second match name")
        quit
        ;
tXpathAbsoluteRoot(pass,fail)   ;@TEST "xpath('/foo') matches the root if its name is foo"
        new root,rc,results,n
        set rc=$$parse^STDXML("<foo><bar/></foo>",.root)
        set n=$$xpath^STDXML(.root,"/foo",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match (root)")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"name")),"foo","root matched")
        ; absolute path that doesn't match the root returns 0
        set n=$$xpath^STDXML(.root,"/bar",.results)
        do eq^STDASSERT(.pass,.fail,n,0,"absolute /bar does NOT match (root is foo)")
        quit
        ;
tXpathChainedPath(pass,fail)    ;@TEST "xpath('a/b') walks two levels"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a><b>hello</b></a></r>",.root)
        set n=$$xpath^STDXML(.root,"a/b",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one b under a")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"text")),"hello","b text=hello")
        quit
        ;
tXpathMultipleSiblingMatches(pass,fail) ;@TEST "xpath('a/b') gathers from all matching parents"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a><b>1</b></a><a><b>2</b><b>3</b></a></r>",.root)
        set n=$$xpath^STDXML(.root,"a/b",.results)
        do eq^STDASSERT(.pass,.fail,n,3,"three b's total across two a's")
        quit
        ;
tXpathPositionPredicate(pass,fail)      ;@TEST "xpath('a[2]') returns the 2nd matching child"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><a id=""2""/><a id=""3""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[2]",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"attr","id")),"2","2nd a has id=2")
        quit
        ;
tXpathDescendantAxis(pass,fail) ;@TEST "xpath('//x') matches x at any depth"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a><x>1</x></a><b><c><x>2</x></c></b></r>",.root)
        set n=$$xpath^STDXML(.root,"//x",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two x's anywhere")
        quit
        ;
tXpathDescendantWithPredicate(pass,fail)        ;@TEST "xpath('//x[1]') returns the first descendant match"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a><x>1</x></a><b><x>2</x></b></r>",.root)
        set n=$$xpath^STDXML(.root,"//x[1]",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match (the first)")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"text")),"1","first x has text=1")
        quit
        ;
tXpathNoMatchReturnsZero(pass,fail)     ;@TEST "xpath('missing') returns 0 with empty results"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a/></r>",.root)
        set n=$$xpath^STDXML(.root,"missing",.results)
        do eq^STDASSERT(.pass,.fail,n,0,"no match")
        do false^STDASSERT(.pass,.fail,$data(results(1)),"results(1) undefined")
        quit
        ;
tXpathOneFirstMatch(pass,fail)  ;@TEST "xpathOne returns 1 and merges first match"
        new root,rc,out
        set rc=$$parse^STDXML("<r><a id=""1""/><a id=""2""/></r>",.root)
        do true^STDASSERT(.pass,.fail,$$xpathOne^STDXML(.root,"a",.out),"found")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.out),"a","first a")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.out,"id"),"1","id=1")
        quit
        ;
tXpathOneMissingReturnsZero(pass,fail)  ;@TEST "xpathOne returns 0 for no match"
        new root,rc,out
        set rc=$$parse^STDXML("<r/>",.root)
        do false^STDASSERT(.pass,.fail,$$xpathOne^STDXML(.root,"missing",.out),"no match")
        quit
        ;
tXpathTextReturnsContent(pass,fail)     ;@TEST "xpathText returns the text of the first match"
        new root,rc
        set rc=$$parse^STDXML("<r><a>hello</a><a>world</a></r>",.root)
        do eq^STDASSERT(.pass,.fail,$$xpathText^STDXML(.root,"a"),"hello","first a's text")
        do eq^STDASSERT(.pass,.fail,$$xpathText^STDXML(.root,"a[2]"),"world","second a's text")
        quit
        ;
tXpathTextMissingReturnsEmpty(pass,fail)        ;@TEST "xpathText of no match returns ''"
        new root,rc
        set rc=$$parse^STDXML("<r/>",.root)
        do eq^STDASSERT(.pass,.fail,$$xpathText^STDXML(.root,"missing"),"","no match → empty")
        quit
        ;
        ; ---- T27a: wildcards + attribute axis ----
tXpathWildcardChild(pass,fail)  ;@TEST "xpath('*') matches any direct child regardless of name"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a/><b/><c/></r>",.root)
        set n=$$xpath^STDXML(.root,"*",.results)
        do eq^STDASSERT(.pass,.fail,n,3,"three children matched")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"name")),"a","first is a")
        do eq^STDASSERT(.pass,.fail,$get(results(2,"name")),"b","second is b")
        do eq^STDASSERT(.pass,.fail,$get(results(3,"name")),"c","third is c")
        quit
        ;
tXpathWildcardWithPredicate(pass,fail)  ;@TEST "xpath('*[2]') returns the second child regardless of name"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a/><b/><c/></r>",.root)
        set n=$$xpath^STDXML(.root,"*[2]",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"name")),"b","second child=b")
        quit
        ;
tXpathDescendantWildcard(pass,fail)     ;@TEST "xpath('//*') matches every descendant element"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a><b/></a><c/></r>",.root)
        set n=$$xpath^STDXML(.root,"//*",.results)
        do eq^STDASSERT(.pass,.fail,n,3,"three descendants: a, b, c")
        quit
        ;
tXpathChildOfWildcard(pass,fail)        ;@TEST "xpath('*/x') finds x under any direct child"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a><x>1</x></a><b><x>2</x></b></r>",.root)
        set n=$$xpath^STDXML(.root,"*/x",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two x's via wildcard")
        quit
        ;
tXpathAttributeAxis(pass,fail)  ;@TEST "xpath('@id') returns the id attribute value of the context"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r id=""abc""/>",.root)
        set n=$$xpath^STDXML(.root,"@id",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"text")),"abc","value=abc")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"name")),"id","name=id")
        quit
        ;
tXpathAttributeOnChild(pass,fail)       ;@TEST "xpath('a/@id') returns id attribute of every a child"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><a id=""2""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a/@id",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two id attrs")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"text")),"1","first id=1")
        do eq^STDASSERT(.pass,.fail,$get(results(2,"text")),"2","second id=2")
        quit
        ;
tXpathAttributeMissingReturnsZero(pass,fail)    ;@TEST "xpath('@missing') returns 0"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r/>",.root)
        set n=$$xpath^STDXML(.root,"@missing",.results)
        do eq^STDASSERT(.pass,.fail,n,0,"no match")
        quit
        ;
tXpathAttributeWildcard(pass,fail)      ;@TEST "xpath('@*') returns every attribute on the context"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r a=""1"" b=""2"" c=""3""/>",.root)
        set n=$$xpath^STDXML(.root,"@*",.results)
        do eq^STDASSERT(.pass,.fail,n,3,"three attrs")
        quit
        ;
tXpathDescendantAttribute(pass,fail)    ;@TEST "xpath('//@id') finds @id at any descendant depth"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><b><c id=""2""/></b></r>",.root)
        set n=$$xpath^STDXML(.root,"//@id",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two id attrs across descendants")
        quit
        ;
tXpathAttributeViaXpathText(pass,fail)  ;@TEST "xpathText('@id') returns the attribute value as a string"
        new root,rc
        set rc=$$parse^STDXML("<r id=""hello""/>",.root)
        do eq^STDASSERT(.pass,.fail,$$xpathText^STDXML(.root,"@id"),"hello","attr value via xpathText")
        quit
        ;
        ; ---- T27b: XPath functions + comparison predicates ----
tXpathPredicateAttrEqualsString(pass,fail)      ;@TEST "xpath('a[@id=''2'']') filters by attribute equality"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><a id=""2""/><a id=""3""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[@id='2']",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"attr","id")),"2","matched a id=2")
        quit
        ;
tXpathPredicateAttrEqualsDoubleQuoted(pass,fail)        ;@TEST "predicate accepts double-quoted string literal"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""x""/><a id=""y""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[@id=""y""]",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"attr","id")),"y","matched a id=y")
        quit
        ;
tXpathPredicateAttrNotEquals(pass,fail) ;@TEST "xpath('a[@id!=''1'']') excludes the matching value"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><a id=""2""/><a id=""3""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[@id!='1']",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two matches: id=2,3")
        quit
        ;
tXpathPredicateNameEquals(pass,fail)    ;@TEST "xpath('*[name()=''b'']') filters wildcard by element name"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a/><b/><c/><b/></r>",.root)
        set n=$$xpath^STDXML(.root,"*[name()='b']",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two b's via name()")
        quit
        ;
tXpathPredicateTextEquals(pass,fail)    ;@TEST "xpath('a[text()=''hello'']') filters by text content"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a>hello</a><a>world</a><a>hello</a></r>",.root)
        set n=$$xpath^STDXML(.root,"a[text()='hello']",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two a's with text='hello'")
        quit
        ;
tXpathPredicateContains(pass,fail)      ;@TEST "xpath('a[contains(@class,''foo'')]') filters by substring"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a class=""foo bar""/><a class=""baz""/><a class=""quxfoo""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[contains(@class,'foo')]",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two a's contain 'foo' in @class")
        quit
        ;
tXpathPredicateStartsWith(pass,fail)    ;@TEST "xpath('a[starts-with(@id,''pre'')]') filters by prefix"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""prefixed""/><a id=""other""/><a id=""pre1""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[starts-with(@id,'pre')]",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two a's with id starting with 'pre'")
        quit
        ;
tXpathPredicatePositionEqual(pass,fail) ;@TEST "xpath('a[position()=2]') is equivalent to a[2]"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><a id=""2""/><a id=""3""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[position()=2]",.results)
        do eq^STDASSERT(.pass,.fail,n,1,"one match")
        do eq^STDASSERT(.pass,.fail,$get(results(1,"attr","id")),"2","2nd a has id=2")
        quit
        ;
tXpathPredicateCountEquals(pass,fail)   ;@TEST "xpath('book[count(author)=2]') filters by child count"
        new root,rc,results,n
        set rc=$$parse^STDXML("<lib><book><author/><author/></book><book><author/></book><book><author/><author/></book></lib>",.root)
        set n=$$xpath^STDXML(.root,"book[count(author)=2]",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two books with 2 authors")
        quit
        ;
tXpathPredicateCountGreaterThan(pass,fail)      ;@TEST "xpath('a[count(b)>1]') uses numeric comparison"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a><b/></a><a><b/><b/></a><a><b/><b/><b/></a></r>",.root)
        set n=$$xpath^STDXML(.root,"a[count(b)>1]",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two a's with more than 1 b")
        quit
        ;
tXpathPredicateStringLengthGt(pass,fail)        ;@TEST "xpath('a[string-length(@id)>2]') filters by attribute length"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""x""/><a id=""abc""/><a id=""longer""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[string-length(@id)>2]",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two a's with id longer than 2 chars")
        quit
        ;
tXpathPredicateNormalizeSpace(pass,fail)        ;@TEST "xpath('a[normalize-space()=''hi'']') collapses whitespace before compare"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a>  hi  </a><a>hello</a><a> hi </a></r>",.root)
        set n=$$xpath^STDXML(.root,"a[normalize-space()='hi']",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two a's normalize to 'hi'")
        quit
        ;
tXpathPredicateAttrExistsTruthy(pass,fail)      ;@TEST "xpath('a[@id]') keeps elements with non-empty @id"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><a/><a id=""3""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[@id]",.results)
        do eq^STDASSERT(.pass,.fail,n,2,"two a's have @id")
        quit
        ;
tXpathPredicateAttrExistsFiltersOut(pass,fail)  ;@TEST "xpath('a[@missing]') filters out all when no element has it"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a id=""1""/><a id=""2""/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[@missing]",.results)
        do eq^STDASSERT(.pass,.fail,n,0,"no a has @missing → 0")
        quit
        ;
tXpathPredicateRejectsBadExpr(pass,fail)        ;@TEST "xpath rejects malformed predicate expression"
        new root,rc,results,n
        set rc=$$parse^STDXML("<r><a/></r>",.root)
        set n=$$xpath^STDXML(.root,"a[contains(]",.results)
        do eq^STDASSERT(.pass,.fail,n,0,"unparseable predicate → 0")
        quit
        ;
        ; ---- T26: DTD / DOCTYPE / custom entities ----
        ;
tDoctypeNoSubsetSkipped(pass,fail)      ;@TEST "<!DOCTYPE root> with no subset is skipped"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past DOCTYPE")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tDoctypeEmptyInternalSubsetSkipped(pass,fail)   ;@TEST "<!DOCTYPE root []> with empty internal subset is skipped"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo []><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past empty subset")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tDoctypeSystemExternalSkipped(pass,fail)        ;@TEST "<!DOCTYPE root SYSTEM ""url""> external ref is skipped"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo SYSTEM ""http://x/dtd""><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past SYSTEM ref")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tDoctypeSystemPlusInternalSubsetSkipped(pass,fail)      ;@TEST "<!DOCTYPE root SYSTEM ""url"" [...]> with both is skipped"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo SYSTEM ""x.dtd"" [<!ENTITY g ""H"">]><foo>&g;</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past SYSTEM + subset")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"H","internal entity expands")
        quit
        ;
tDoctypePublicExternalSkipped(pass,fail) ;@TEST "<!DOCTYPE root PUBLIC ""id"" ""url""> is skipped"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo PUBLIC ""-//X//Y"" ""x.dtd""><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses past PUBLIC ref")
        do eq^STDASSERT(.pass,.fail,$$rootName^STDXML(.root),"foo","root=foo")
        quit
        ;
tEntityDeclExpandsInText(pass,fail)     ;@TEST "<!ENTITY name ""value""> expands in element text"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ENTITY g ""Hello"">]><foo>&g; world</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses with custom entity")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"Hello world","entity expanded in text")
        quit
        ;
tEntityDeclExpandsInAttribute(pass,fail) ;@TEST "<!ENTITY name ""value""> expands in attribute value"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ENTITY id ""abc123"">]><foo bar=""&id;""/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses with attr entity")
        do eq^STDASSERT(.pass,.fail,$$attr^STDXML(.root,"bar"),"abc123","entity expanded in attribute")
        quit
        ;
tEntityDeclSingleQuotedValue(pass,fail) ;@TEST "<!ENTITY name 'value'> with single quotes works"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ENTITY g 'Hi'>]><foo>&g;</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses single-quoted entity")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"Hi","single-quoted value expanded")
        quit
        ;
tEntityDeclMultipleDecls(pass,fail)     ;@TEST "multiple <!ENTITY> declarations all expand"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ENTITY a ""A""><!ENTITY b ""B"">]><foo>&a;-&b;</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses multi-entity DOCTYPE")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"A-B","both entities expanded")
        quit
        ;
tEntityDeclWithCommentsAndPI(pass,fail) ;@TEST "comments and PIs inside DOCTYPE subset are skipped"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!-- pre --><!ENTITY g ""V""><?pi data?>]><foo>&g;</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses subset with comment + PI")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"V","entity still found")
        quit
        ;
tEntityDeclIgnoresElementAttlistNotation(pass,fail) ;@TEST "<!ELEMENT> / <!ATTLIST> / <!NOTATION> are skipped"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ELEMENT foo (#PCDATA)><!ATTLIST foo id CDATA #IMPLIED><!NOTATION n SYSTEM ""x""><!ENTITY g ""kept"">]><foo>&g;</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses subset with element/attlist/notation")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"kept","entity decl still picked up")
        quit
        ;
tDoctypeCommentBetweenDecls(pass,fail)  ;@TEST "<!-- comment --> between markup decls in subset"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ENTITY a ""A""><!-- between --><!ENTITY b ""B"">]><foo>&a;&b;</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses subset with mid-comment")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"AB","both entities survive")
        quit
        ;
tDoctypeUnclosedRejected(pass,fail)     ;@TEST "<!DOCTYPE foo without > is rejected"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo<foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"unclosed DOCTYPE → fail")
        quit
        ;
tEntityDeclUnclosedSubsetRejected(pass,fail)    ;@TEST "<!DOCTYPE foo [<!ENTITY... without ]> is rejected"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ENTITY g ""x""><foo/>",.root)
        do eq^STDASSERT(.pass,.fail,rc,0,"unclosed internal subset → fail")
        quit
        ;
tBuiltinEntitiesStillWork(pass,fail)    ;@TEST "after DOCTYPE, &amp; / &lt; / numeric refs still expand"
        new root,rc
        set rc=$$parse^STDXML("<!DOCTYPE foo [<!ENTITY g ""x"">]><foo>&amp;&lt;&#65;&g;</foo>",.root)
        do eq^STDASSERT(.pass,.fail,rc,1,"parses combined builtin + custom")
        do eq^STDASSERT(.pass,.fail,$$text^STDXML(.root),"&<Ax","builtins + custom both decode")
        quit
