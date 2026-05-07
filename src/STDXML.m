STDXML  ; m-stdlib — XML parser (well-formed XML 1.0 subset, in-progress).
        ; m-lint: disable-file=M-MOD-036
        ; M-MOD-036 flags M's `@` indirection on a "tainted" local. The
        ; XPath helpers (T27) build subscript references from path strings
        ; that are 100% generated from internal `for i=1:1:childCount` loops
        ; — no user input flows into the indirection target. The pattern is
        ; documented in `docs/modules/stdxml.md` "T27 path-walk indirection".
        ;
        ; Public extrinsics (v0):
        ;   $$parse^STDXML(text,.root)              — parse text into root tree; 1/0
        ;   $$valid^STDXML(text)                    — predicate
        ;   $$rootName^STDXML(.node)                — element tag name
        ;   $$attr^STDXML(.node, name)              — attribute value or ""
        ;   $$text^STDXML(.node)                    — direct text content
        ;   $$childCount^STDXML(.node)              — count of element children
        ;   $$childByName^STDXML(.node, name, .out) — first child with name → .out; 1/0
        ;   $$lastError^STDXML()                    — diagnostic string or ""
        ;
        ; Tree shape (caller-owned; pass by reference):
        ;   node("name")           — element tag
        ;   node("attr", attrName) — attribute value (decoded)
        ;   node("text")           — direct text content (decoded; concatenated text nodes)
        ;   node("childCount")     — number of element children
        ;   node("child", n)       — n-th child element (recursive structure)
        ;
        ; Child traversal MUST go through `childByName` (or analogous helpers
        ; that internally `merge` the child subtree to a non-subscripted local).
        ; Direct passing of `.node("child", n)` is **invalid YDB syntax** —
        ; pass-by-reference of a subscripted local is disallowed at compile
        ; time (TOOLCHAIN-FINDINGS row 2026-05-06, demoted to docs 2026-05-07).
        ; The merge-then-pass idiom is canonical for any STDXML descent.
        ;
        ; Grammar (v0 subset of XML 1.0):
        ;   <document>   ::= <ws>? <element> <ws>?
        ;   <element>    ::= <empty-tag> | <stag> <content> <etag>
        ;   <empty-tag>  ::= "<" <name> <attrs>? <ws>? "/>"
        ;   <stag>       ::= "<" <name> <attrs>? <ws>? ">"
        ;   <etag>       ::= "</" <name> <ws>? ">"
        ;   <attrs>      ::= ( <ws> <attr> )+
        ;   <attr>       ::= <name> <ws>? "=" <ws>? <attval>
        ;   <attval>     ::= '"' <chardata> '"' | "'" <chardata> "'"
        ;   <content>    ::= <chardata>? ( <element> <chardata>? )*
        ;   <name>       ::= [A-Za-z_:] [A-Za-z0-9_:.-]*
        ;   <chardata>   ::= text with the 5 standard entities decoded
        ;
        ; Out of scope (queued — see docs/module-tracker.md):
        ;   - DTDs / DOCTYPE / custom entities                       (T26)
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
parse(text,root)        ; Parse text into root tree; return 1/0.
        ; doc: Sets ^STDLIB($job,"stdxml","err") with a diagnostic on failure.
        ; doc: Example: do  set rc=$$parse^STDXML(text,.tree)
        kill root
        kill ^STDLIB($job,"stdxml","err")
        new ctx,ok,emptyNs
        if text="" do err("empty input") quit 0
        do initCtx(.ctx,text)
        if '$$skipDocLevel(.ctx) quit 0
        if $$peek(.ctx)'="<" do err("expected '<' at root") quit 0
        set ok=$$parseElement(.ctx,.root,.emptyNs)
        if 'ok quit 0
        if '$$skipDocLevel(.ctx) quit 0
        if ctx("pos")'>ctx("len") do err("trailing data after root") quit 0
        quit 1
        ;
valid(text)     ; Return 1 iff text parses as valid XML; else 0.
        ; doc: Example: write $$valid^STDXML("<foo/>")
        new tmp
        quit $$parse(text,.tmp)
        ;
rootName(node)  ; Return the element tag name; "" if missing.
        ; doc: Example: write $$rootName^STDXML(.tree)  ; "foo"
        quit $get(node("name"),"")
        ;
attr(node,name) ; Return attribute value; "" if missing.
        ; doc: Example: write $$attr^STDXML(.tree,"id")
        quit $get(node("attr",name),"")
        ;
ns(node)        ; Return the namespace URI for the element; "" if not in any namespace.
        ; doc: T25 — uses xmlns / xmlns:prefix declarations in scope at the
        ; doc: element's position. Inherited from the nearest enclosing
        ; doc: declaration unless shadowed.
        ; doc: Example: write $$ns^STDXML(.tree)  ; "urn:hl7-org:v3"
        quit $get(node("ns"),"")
        ;
attrNs(node,name)       ; Return the namespace URI for an attribute; "" if unprefixed or absent.
        ; doc: T25b — per XML Namespaces 1.0 §6.2, the default xmlns does
        ; doc: NOT apply to unprefixed attributes; only attributes with an
        ; doc: explicit prefix carry a namespace URI. The built-in `xml:`
        ; doc: prefix resolves to `http://www.w3.org/XML/1998/namespace`.
        ; doc: Example: write $$attrNs^STDXML(.tree,"xsi:type")
        quit $get(node("attrNs",name),"")
        ;
xpath(tree,expr,results)        ; Run an XPath query; populate results(1..N); return N.
        ; doc: Supports element paths (`a/b/c`), absolute (`/foo`),
        ; doc: descendant axis (`//x`), 1-based position predicates
        ; doc: (`x[1]`), wildcards (`*` and `@*`), and attribute axis
        ; doc: (`@attr`). Attribute matches surface as result entries
        ; doc: with `results(i,"text")` set to the attribute value and
        ; doc: `results(i,"name")` set to the attribute name — so
        ; doc: `xpathText` returns the attribute value transparently.
        ; doc: T27b — predicate expressions also accept comparison
        ; doc: operators (`=`, `!=`, `<`, `>`, `<=`, `>=`) and the
        ; doc: functions `position()`, `last()`, `name()`, `text()`,
        ; doc: `count()`, `string-length()`, `normalize-space()`,
        ; doc: `contains()`, `starts-with()`. Examples: `a[@id='2']`,
        ; doc: `*[name()='b']`, `book[count(author)>1]`.
        ; doc: Returns 0 (with results killed) for an unparseable expression.
        ; doc: Example: do  set n=$$xpath^STDXML(.doc,"/r/items/item[2]",.r)
        kill results
        new steps,paths,n,pathCount,i
        if '$$parseXPath(expr,.steps) quit 0
        set paths(1)="",pathCount=1
        for i=1:1:$get(steps("count"),0) do  if pathCount=0 quit
        . new newPaths,newCount
        . set newCount=0
        . do applyStep(.tree,.steps,i,.paths,pathCount,.newPaths,.newCount)
        . kill paths
        . merge paths=newPaths
        . set pathCount=newCount
        if pathCount=0 quit 0
        for i=1:1:pathCount  do mergePathToResult(.tree,.paths,i,.results)
        quit pathCount
        ;
xpathOne(tree,expr,out) ; First match into .out; return 1/0.
        ; doc: Convenience wrapper over xpath.
        ; doc: Example: do  if $$xpathOne^STDXML(.doc,"/r/title",.t) ...
        kill out
        new results,n
        set n=$$xpath(.tree,expr,.results)
        if n=0 quit 0
        merge out=results(1)
        quit 1
        ;
xpathText(tree,expr)    ; Return the direct text of the first match; "" if none.
        ; doc: Example: write $$xpathText^STDXML(.doc,"/cfg/host")
        new results,n
        set n=$$xpath(.tree,expr,.results)
        if n=0 quit ""
        quit $get(results(1,"text"),"")
        ;
text(node)      ; Return direct text content; "" if no text.
        ; doc: Example: write $$text^STDXML(.tree)
        quit $get(node("text"),"")
        ;
childCount(node)        ; Return number of element children; 0 if none.
        ; doc: Example: write $$childCount^STDXML(.tree)
        quit $get(node("childCount"),0)
        ;
childByName(node,name,out)      ; Find first child with `name`; merge into `.out`. 1/0.
        ; doc: Pass-by-ref of `.out` allows the caller to receive the child
        ; doc: subtree without violating YDB's `.x(SUBS)` syntax limit. The
        ; doc: merge under the hood is what makes recursive descent into a
        ; doc: parsed XML tree work in YDB.
        ; doc: Example: do  if $$childByName^STDXML(.tree,"book",.b) ...
        kill out
        new n,i,found,foundAt
        set n=$get(node("childCount"),0),found=0,foundAt=0
        if n=0 quit 0
        for i=1:1:n quit:found  do
        . if $get(node("child",i,"name"))=name set found=1,foundAt=i
        if 'found quit 0
        merge out=node("child",foundAt)
        quit 1
        ;
lastError()     ; Return the last parse error diagnostic; "" if none / parse succeeded.
        ; doc: Example: if 'rc write $$lastError^STDXML(),!
        quit $get(^STDLIB($job,"stdxml","err"),"")
        ;
        ; ---------- internal: parser state ----------
        ;
initCtx(ctx,text)       ; Initialise the parse context.
        ; doc: Internal — pos is the 1-based current position.
        kill ctx
        set ctx("text")=text
        set ctx("len")=$length(text)
        set ctx("pos")=1
        quit
        ;
peek(ctx)       ; Return the character at the current position; "" at EOF.
        ; doc: Internal.
        if ctx("pos")>ctx("len") quit ""
        quit $extract(ctx("text"),ctx("pos"))
        ;
peekN(ctx,n)    ; Return the next n characters from the current position.
        ; doc: Internal — for matching multi-char tokens like "</".
        quit $extract(ctx("text"),ctx("pos"),ctx("pos")+n-1)
        ;
advance(ctx,n)  ; Advance the position by n characters.
        ; doc: Internal.
        set ctx("pos")=ctx("pos")+n
        quit
        ;
skipWs(ctx)     ; Skip space/tab/CR/LF whitespace.
        ; doc: Internal.
        new c
        for  set c=$$peek(.ctx) quit:c=""  quit:'($extract(c,1)?1(1" ",1C))  do advance(.ctx,1)
        quit
        ;
        ; ---------- internal: element / attrs ----------
        ;
parseElement(ctx,node,nsIn)     ; Parse one element. nsIn is the inherited namespace map.
        ; doc: Internal — leaves the context positioned after the element.
        ; doc: Threads a per-element namespace map (T25). The parent's `nsIn`
        ; doc: is copied into a local `myNs` before modification, so children
        ; doc: see this element's xmlns declarations but the parent does not.
        new rawName,localName,prefix,ok,end2,myNs,nsUri
        kill node
        if $$peek(.ctx)'="<" do err("expected '<' at element") quit 0
        do advance(.ctx,1)
        set rawName=$$parseName(.ctx)
        if rawName="" do err("expected element name") quit 0
        set node("name")=rawName
        if '$$parseAttrs(.ctx,.node) quit 0
        ; Build local namespace map: copy inherited, then absorb this element's xmlns*.
        merge myNs=nsIn
        do absorbXmlns(.node,.myNs)
        ; Resolve the element's own qualified name.
        do splitQName(rawName,.prefix,.localName)
        if prefix="" do
        . set nsUri=$get(myNs(""))
        else  do
        . if '$data(myNs(prefix)) set nsUri="<<UNDECLARED>>"
        . else  set nsUri=myNs(prefix)
        if nsUri="<<UNDECLARED>>" do err("undeclared namespace prefix '"_prefix_"'") quit 0
        set node("name")=localName
        set node("prefix")=prefix
        set node("ns")=nsUri
        ; T25b: resolve any prefixed attribute names against myNs.
        if '$$resolveAttrNs(.node,.myNs) quit 0
        do skipWs(.ctx)
        set end2=$$peekN(.ctx,2)
        if end2="/>" do advance(.ctx,2) set node("childCount")=0 quit 1
        if $$peek(.ctx)'=">" do err("expected '>' or '/>' after attrs") quit 0
        do advance(.ctx,1)
        ; Element has content: parse text/children until </name>.
        set node("childCount")=0
        if '$$parseContent(.ctx,rawName,.node,.myNs) quit 0
        quit 1
        ;
parseAttrs(ctx,node)    ; Parse zero-or-more attributes onto node.
        ; doc: Internal — leaves the context at the next non-whitespace
        ; doc: character (typically `>` or `/>`).
        new c,attrName,quote,value,done,bad
        set done=0,bad=0
        for  quit:done  do
        . do skipWs(.ctx)
        . set c=$$peek(.ctx)
        . if (c="")!(c=">")!(c="/") set done=1 quit
        . set attrName=$$parseName(.ctx)
        . if attrName="" do err("expected attribute name") set done=1,bad=1 quit
        . do skipWs(.ctx)
        . if $$peek(.ctx)'="=" do err("expected '='") set done=1,bad=1 quit
        . do advance(.ctx,1)
        . do skipWs(.ctx)
        . set quote=$$peek(.ctx)
        . if (quote'="""")&(quote'="'") do err("expected quote for attr value") set done=1,bad=1 quit
        . do advance(.ctx,1)
        . set value=$$parseAttrValue(.ctx,quote)
        . if $$peek(.ctx)'=quote do err("unterminated attr value") set done=1,bad=1 quit
        . do advance(.ctx,1)
        . set node("attr",attrName)=$$decodeEntities(value)
        if bad quit 0
        quit 1
        ;
parseAttrValue(ctx,quote)       ; Read characters until the matching quote (no escapes — entities decoded later).
        ; doc: Internal.
        new out,c
        set out=""
        for  set c=$$peek(.ctx) quit:c=""  quit:c=quote  set out=out_c do advance(.ctx,1)
        quit out
        ;
parseContent(ctx,parentName,node,nsIn)  ; Parse element content until </parentName>.
        ; doc: Internal — populates node("text") and node("child", n, ...).
        ; doc: Dispatches on `<!--` (comment), `<![CDATA[` (literal text),
        ; doc: `<?` (PI, skip), `</` (end of content), and `<name` (child).
        ; doc: nsIn is the inherited namespace map, threaded through to each
        ; doc: child element via parseElement.
        new buf,end2,end4,end9,name,childCount,done,bad,tmpChild,cdataText
        set buf="",childCount=$get(node("childCount"),0),done=0,bad=0,tmpChild=""
        for  quit:done  do
        . if ctx("pos")>ctx("len") do err("unexpected EOF in content") set done=1,bad=1 quit
        . set end2=$$peekN(.ctx,2)
        . if end2="</" set done=1 quit
        . if end2="<!" do  quit
        . . set end4=$$peekN(.ctx,4)
        . . set end9=$$peekN(.ctx,9)
        . . if end4="<!--" if '$$skipComment(.ctx) set bad=1,done=1
        . . if end9="<![CDATA[" do
        . . . if buf'="" set node("text")=$get(node("text"),"")_$$decodeEntities(buf),buf=""
        . . . set cdataText=""
        . . . if '$$parseCdata(.ctx,.cdataText) set bad=1,done=1 quit
        . . . set node("text")=$get(node("text"),"")_cdataText
        . . if (end4'="<!--")&(end9'="<![CDATA[") do err("expected <!-- or <![CDATA[ after <!") set bad=1,done=1
        . if end2="<?" do  quit
        . . if '$$skipPI(.ctx) set bad=1,done=1
        . if $$peek(.ctx)="<" do  quit
        . . if buf'="" set node("text")=$get(node("text"),"")_$$decodeEntities(buf),buf=""
        . . set childCount=childCount+1
        . . if '$$parseElement(.ctx,.tmpChild,.nsIn) set bad=1,done=1 quit
        . . merge node("child",childCount)=tmpChild
        . set buf=buf_$$peek(.ctx)
        . do advance(.ctx,1)
        if bad quit 0
        if buf'="" set node("text")=$get(node("text"),"")_$$decodeEntities(buf)
        set node("childCount")=childCount
        ; Now consume </parentName>
        if $$peekN(.ctx,2)'="</" do err("expected end tag") quit 0
        do advance(.ctx,2)
        set name=$$parseName(.ctx)
        if name'=parentName do err("mismatched end tag: expected </"_parentName_">") quit 0
        do skipWs(.ctx)
        if $$peek(.ctx)'=">" do err("expected '>' at end of close tag") quit 0
        do advance(.ctx,1)
        quit 1
        ;
absorbXmlns(node,nsMap) ; Pull `xmlns` / `xmlns:prefix` attrs out of node into nsMap.
        ; doc: Internal — driven by parseElement. Walks node("attr",...),
        ; doc: collects the namespace declarations into a temporary list,
        ; doc: applies them to nsMap, and kills them from node("attr",...).
        new k,n,i,xkeys,prefix,uri
        set n=0,k="",xkeys=0
        for  set k=$order(node("attr",k)) quit:k=""  do
        . if k="xmlns" set n=n+1,xkeys(n)=k quit
        . if $extract(k,1,6)="xmlns:" set n=n+1,xkeys(n)=k
        for i=1:1:n do
        . set k=xkeys(i)
        . set uri=node("attr",k)
        . if k="xmlns" set nsMap("")=uri
        . else  set prefix=$piece(k,":",2),nsMap(prefix)=uri
        . kill node("attr",k)
        quit
        ;
        ; ---------- internal: XPath (T27) ----------
        ;
parseXPath(expr,steps)  ; Parse XPath expression into steps(1..N) with axis/name/pred/attrName.
        ; doc: Internal — supports `name`, `name1/name2`, `/name`, `//name`,
        ; doc: `name[N]`, the wildcard `*` (T27a), and the attribute axis
        ; doc: `@attrName` / `@*` (T27a). An attribute step is terminal —
        ; doc: nothing may follow it. T27b — predicates may be either a
        ; doc: positive integer (legacy `[N]` position filter) or a full
        ; doc: comparison expression like `[@id='2']` / `[name()='foo']` /
        ; doc: `[count(child)>3]`.
        ; doc: Returns 1 on success, 0 on parse failure.
        kill steps
        new pos,len,n,axis,name,pred,c,predStr,fail,done,nameDone,attrName
        new predKind,predExpr,inQuote,probeAst
        set pos=1,n=0,len=$length(expr),fail=0
        if expr="" quit 0
        if $extract(expr,1)="/" do
        . if $extract(expr,2)="/" set axis="descendant",pos=3
        . else  set axis="absolute",pos=2
        else  set axis="child"
        set done=0
        for  quit:done  quit:fail  do
        . if pos>len set done=1 quit
        . ; -- detect attribute axis `@` --
        . set attrName=""
        . if $extract(expr,pos)="@" set attrName="<pending>",pos=pos+1
        . ; -- read element-or-attribute name --
        . set name="",nameDone=0
        . for  quit:nameDone  do
        . . if pos>len set nameDone=1 quit
        . . set c=$extract(expr,pos)
        . . if (c="/")!(c="[") set nameDone=1 quit
        . . set name=name_c,pos=pos+1
        . if name="" set fail=1 quit
        . if attrName="<pending>" set attrName=name,name=""
        . ; -- optional predicate [N] (numeric) or [expr] (T27b) --
        . set pred=0,predKind="none",predExpr=""
        . if pos'>len,$extract(expr,pos)="[" do
        . . set pos=pos+1,predStr="",nameDone=0,inQuote=""
        . . for  quit:nameDone  do
        . . . if pos>len set nameDone=1,fail=1 quit
        . . . set c=$extract(expr,pos)
        . . . if inQuote'="" do  quit
        . . . . if c=inQuote set inQuote=""
        . . . . set predStr=predStr_c,pos=pos+1
        . . . if c="]" set nameDone=1 quit
        . . . if (c="'")!(c="""") set inQuote=c
        . . . set predStr=predStr_c,pos=pos+1
        . . if fail quit
        . . set pos=pos+1
        . . if predStr="" set fail=1 quit
        . . if predStr?1.N set predKind="num",pred=+predStr quit
        . . set predKind="expr",predExpr=predStr
        . . ; validate parsability up front so xpath() reports failure cleanly
        . . if '$$parsePredExpr(predStr,.probeAst) set fail=1
        . if fail quit
        . ; -- record step --
        . set n=n+1
        . set steps(n,"axis")=axis,steps(n,"name")=name,steps(n,"pred")=pred
        . set steps(n,"attrName")=attrName
        . set steps(n,"predKind")=predKind
        . set steps(n,"predExpr")=predExpr
        . ; -- attribute axis is terminal --
        . if attrName'="" do  quit
        . . if pos>len set done=1 quit
        . . set fail=1
        . ; -- determine next step's axis (or end) --
        . if pos>len set done=1 quit
        . if $extract(expr,pos)'="/" set fail=1 quit
        . if $extract(expr,pos+1)="/" set axis="descendant",pos=pos+2
        . else  set axis="child",pos=pos+1
        if fail quit 0
        set steps("count")=n
        quit 1
        ;
applyStep(tree,steps,stepIdx,paths,pathCount,newPaths,newCount)
        ; doc: Apply one XPath step to the current candidate set, producing
        ; doc: a new candidate set in newPaths(1..newCount). T27a: when the
        ; doc: step is an attribute axis (`@x`), candidates are sourced per
        ; doc: the axis (child=basePath, descendant=basePath's descendants)
        ; doc: and each candidate's matching attribute(s) become results.
        ; doc: T27b: predKind="expr" routes through applyExprPredicate for
        ; doc: per-candidate expression evaluation; predKind="num" keeps the
        ; doc: legacy O(1) position filter via applyPredicate.
        new axis,name,pred,attrName,i,basePath,elemPaths,elemCount,predKind,predExpr
        kill newPaths
        set newCount=0
        set axis=steps(stepIdx,"axis")
        set name=steps(stepIdx,"name")
        set pred=steps(stepIdx,"pred")
        set attrName=$get(steps(stepIdx,"attrName"),"")
        set predKind=$get(steps(stepIdx,"predKind"),"none")
        set predExpr=$get(steps(stepIdx,"predExpr"),"")
        if attrName'="" do  quit
        . set elemCount=0
        . for i=1:1:pathCount do
        . . set basePath=paths(i)
        . . if axis="descendant" do collectDescendants(.tree,basePath,"*",.elemPaths,.elemCount) quit
        . . set elemCount=elemCount+1,elemPaths(elemCount)=basePath
        . for i=1:1:elemCount do collectAttribute(.tree,elemPaths(i),attrName,.newPaths,.newCount)
        . if predKind="num",pred>0 do applyPredicate(.newPaths,.newCount,pred)
        . if predKind="expr" do applyExprPredicate(.tree,.newPaths,.newCount,predExpr)
        for i=1:1:pathCount do
        . set basePath=paths(i)
        . if axis="absolute" do  quit
        . . if $$matchName(.tree,basePath,name) set newCount=newCount+1,newPaths(newCount)=basePath
        . if axis="descendant" do collectDescendants(.tree,basePath,name,.newPaths,.newCount) quit
        . do collectChildren(.tree,basePath,name,.newPaths,.newCount)
        if predKind="num",pred>0 do applyPredicate(.newPaths,.newCount,pred)
        if predKind="expr" do applyExprPredicate(.tree,.newPaths,.newCount,predExpr)
        quit
        ;
applyPredicate(newPaths,newCount,pred)  ; Keep only the n-th match (1-based).
        ; doc: Internal — uses merge so any subnodes (attribute results)
        ; doc: are preserved through the in-place reduction.
        new kept
        if pred>newCount kill newPaths set newCount=0 quit
        merge kept=newPaths(pred)
        kill newPaths
        merge newPaths(1)=kept
        set newCount=1
        quit
        ;
matchName(tree,path,want)       ; 1 if the node at `path` matches `want` (`*` is wildcard).
        ; doc: Internal — used by axis=absolute and the wildcard-aware
        ; doc: child / descendant collectors.
        new actual
        set actual=$$nameAtPath(.tree,path)
        if actual="" quit 0
        if want="*" quit 1
        quit actual=want
        ;
nameAtPath(tree,path)   ; Return the name of the node at the given path; "" if none.
        ; doc: Internal — path is comma-separated list of child indices.
        if path="" quit $get(tree("name"),"")
        quit $get(@$$buildRef(path,"""name"""),"")
        ;
buildRef(path,suffix)   ; Build an M name reference like `tree("child",1,"child",3,"name")`.
        ; doc: Internal — `path` is a comma-separated list of child indices
        ; doc: (or "" for the root). `suffix` is the trailing subscript term
        ; doc: (or "" for none). Produces a single subscript list inside the
        ; doc: outer parens — chaining subscripts is not valid M syntax, so
        ; doc: helpers must concatenate everything within one ref.
        new subs,n,i
        set subs=""
        if path'="" do
        . set n=$length(path,",")
        . for i=1:1:n  set subs=subs_$select(i>1:",",1:"")_$char(34)_"child"_$char(34)_","_$piece(path,",",i)
        if subs="",suffix="" quit "tree"
        if subs="" quit "tree("_suffix_")"
        if suffix="" quit "tree("_subs_")"
        quit "tree("_subs_","_suffix_")"
        ;
collectChildren(tree,basePath,name,newPaths,newCount)
        ; doc: Append paths to immediate children of basePath whose name
        ; doc: matches. `name="*"` is a wildcard (any element).
        new childCount,i,childPath,actualName
        set childCount=$get(@$$buildRef(basePath,"""childCount"""),0)
        for i=1:1:childCount do
        . set childPath=$select(basePath="":i,1:basePath_","_i)
        . set actualName=$get(@$$buildRef(childPath,"""name"""))
        . if (name="*")!(actualName=name) do
        . . set newCount=newCount+1,newPaths(newCount)=childPath
        quit
        ;
collectDescendants(tree,basePath,name,newPaths,newCount)
        ; doc: Walk all descendants of basePath; append matches by name.
        ; doc: `name="*"` is a wildcard (any element). Descendant-only —
        ; doc: does NOT include the basePath node itself; matches strict
        ; doc: XPath descendant axis semantics.
        new childCount,i,childPath,actualName
        set childCount=$get(@$$buildRef(basePath,"""childCount"""),0)
        for i=1:1:childCount do
        . set childPath=$select(basePath="":i,1:basePath_","_i)
        . set actualName=$get(@$$buildRef(childPath,"""name"""))
        . if (name="*")!(actualName=name) do
        . . set newCount=newCount+1,newPaths(newCount)=childPath
        . do collectDescendants(.tree,childPath,name,.newPaths,.newCount)
        quit
        ;
collectAttribute(tree,basePath,attrName,newPaths,newCount)
        ; doc: T27a — attribute axis terminal step. `attrName="*"` matches
        ; doc: every attribute on the element at basePath; otherwise only
        ; doc: the named attribute (if present). Each match writes
        ; doc: newPaths(idx) = basePath plus subnodes "attrValue" / "attrName"
        ; doc: which mergePathToResult lifts into results(idx,"text") /
        ; doc: results(idx,"name").
        new tmp,k
        if basePath="" merge tmp=tree
        else  merge tmp=@$$buildRef(basePath,"")
        if attrName="*" do  quit
        . set k=""
        . for  set k=$order(tmp("attr",k)) quit:k=""  do
        . . set newCount=newCount+1
        . . set newPaths(newCount)=basePath
        . . set newPaths(newCount,"attrValue")=tmp("attr",k)
        . . set newPaths(newCount,"attrName")=k
        if '$data(tmp("attr",attrName)) quit
        set newCount=newCount+1
        set newPaths(newCount)=basePath
        set newPaths(newCount,"attrValue")=tmp("attr",attrName)
        set newPaths(newCount,"attrName")=attrName
        quit
        ;
mergePathToResult(tree,paths,idx,results)
        ; doc: Lift one path entry into results(idx). Attribute matches
        ; doc: surface as scalar-like results: results(idx,"text")=value
        ; doc: and results(idx,"name")=attrName. Element matches merge
        ; doc: the subtree at paths(idx) so callers walk them like any
        ; doc: parsed-tree node.
        new path
        set path=paths(idx)
        if $data(paths(idx,"attrValue")) do  quit
        . set results(idx,"text")=paths(idx,"attrValue")
        . set results(idx,"name")=paths(idx,"attrName")
        if path="" merge results(idx)=tree quit
        merge results(idx)=@$$buildRef(path,"")
        quit
        ;
        ; ---------- internal: XPath predicate expressions (T27b) ----------
        ;
applyExprPredicate(tree,newPaths,newCount,exprStr)
        ; doc: T27b — for each candidate path, evaluate the predicate
        ; doc: expression and keep the candidate iff the result coerces to
        ; doc: boolean true (XPath 1.0 truthiness: non-empty string,
        ; doc: non-zero number, true bool). The candidate sub-tree
        ; doc: (attrValue / attrName for attribute matches) is preserved
        ; doc: through `merge` so attribute-axis predicates survive.
        new ast,kept,keptCount,i,oType,oVal,truthy
        if newCount=0 quit
        if '$$parsePredExpr(exprStr,.ast) kill newPaths set newCount=0 quit
        set keptCount=0
        for i=1:1:newCount do
        . do evalPredExpr(.tree,$get(newPaths(i)),i,newCount,.ast,.oType,.oVal)
        . set truthy=$$toBool(oType,oVal)
        . if 'truthy quit
        . set keptCount=keptCount+1
        . merge kept(keptCount)=newPaths(i)
        kill newPaths
        if keptCount>0 merge newPaths=kept
        set newCount=keptCount
        quit
        ;
parsePredExpr(predStr,ast)      ; Parse a predicate body into an AST.
        ; doc: Internal — predStr is the content between `[` and `]`.
        ; doc: AST shape: ast("kind") ∈ {num, str, attr, attrAll, bareName,
        ; doc: wildcard, call, binop}. Numeric/string carry ("val");
        ; doc: attr/bareName/call carry ("name"); call adds ("argCount") and
        ; doc: ("arg",i) sub-trees; binop adds ("op"), ("lhs"), ("rhs")
        ; doc: sub-trees. Returns 1 on success, 0 on parse failure.
        new pos,len
        kill ast
        set pos=1,len=$length(predStr)
        do skipExprWs(predStr,.pos,len)
        if pos>len quit 0
        if '$$parseExpr(predStr,.pos,len,.ast) quit 0
        do skipExprWs(predStr,.pos,len)
        if pos'>len quit 0
        quit 1
        ;
parseExpr(s,pos,len,ast)        ; Parse `primary (compOp primary)?`.
        ; doc: Internal — single-level comparison only (no chained `<`).
        ; doc: Operators: `=`, `!=`, `<`, `>`, `<=`, `>=`.
        new lhs,rhs,op,c1,c2
        set lhs="",rhs=""
        kill ast
        if '$$parsePrimary(s,.pos,len,.lhs) quit 0
        do skipExprWs(s,.pos,len)
        if pos>len merge ast=lhs quit 1
        set c1=$extract(s,pos),c2=$extract(s,pos,pos+1),op=""
        if c2="!=" set op="!=",pos=pos+2
        else  if c2="<=" set op="<=",pos=pos+2
        else  if c2=">=" set op=">=",pos=pos+2
        else  if c1="=" set op="=",pos=pos+1
        else  if c1="<" set op="<",pos=pos+1
        else  if c1=">" set op=">",pos=pos+1
        if op="" merge ast=lhs quit 1
        do skipExprWs(s,.pos,len)
        if '$$parsePrimary(s,.pos,len,.rhs) quit 0
        set ast("kind")="binop",ast("op")=op
        merge ast("lhs")=lhs
        merge ast("rhs")=rhs
        quit 1
        ;
parsePrimary(s,pos,len,ast)     ; Parse one primary expression.
        ; doc: Internal — string lit / number / `@name` or `@*` / parenthesised
        ; doc: expression / `*` (wildcard, only meaningful as count() arg) /
        ; doc: bare name (used in count() arg) / function call `name(args)`.
        new c,bad,parsed
        kill ast
        do skipExprWs(s,.pos,len)
        if pos>len quit 0
        set c=$extract(s,pos),bad=0,parsed=0
        if (c="'")!(c="""") do parseStringLit(s,.pos,len,c,.ast,.bad) set parsed=1
        if 'parsed,c?1N do parseNumLit(s,.pos,len,.ast,.bad) set parsed=1
        if 'parsed,c="@" do parseAttrRef(s,.pos,len,.ast,.bad) set parsed=1
        if 'parsed,c="(" do parseParen(s,.pos,len,.ast,.bad) set parsed=1
        if 'parsed,c="*" set ast("kind")="wildcard",pos=pos+1,parsed=1
        if 'parsed,$$isNameStart(c) do parseFnOrName(s,.pos,len,.ast,.bad) set parsed=1
        if 'parsed quit 0
        if bad quit 0
        quit 1
        ;
parseStringLit(s,pos,len,quote,ast,bad)
        ; doc: Internal — `quote` is the matched delimiter (`'` or `"`).
        new str,ch,done
        set str="",pos=pos+1,bad=0,done=0
        for  quit:done  do
        . if pos>len set bad=1,done=1 quit
        . set ch=$extract(s,pos)
        . if ch=quote set done=1 quit
        . set str=str_ch,pos=pos+1
        if bad quit
        set pos=pos+1
        set ast("kind")="str",ast("val")=str
        quit
        ;
parseNumLit(s,pos,len,ast,bad)
        ; doc: Internal — integer or decimal (no exponent / sign).
        new num,ch,done
        set num="",bad=0,done=0
        for  quit:done  do
        . if pos>len set done=1 quit
        . set ch=$extract(s,pos)
        . if ch?1N set num=num_ch,pos=pos+1 quit
        . if ch=".",num'["." set num=num_ch,pos=pos+1 quit
        . set done=1
        if num="" set bad=1 quit
        if num="." set bad=1 quit
        set ast("kind")="num",ast("val")=+num
        quit
        ;
parseAttrRef(s,pos,len,ast,bad)
        ; doc: Internal — `@name` or `@*`.
        new name
        set bad=0,pos=pos+1
        if pos>len set bad=1 quit
        if $extract(s,pos)="*" set ast("kind")="attrAll",pos=pos+1 quit
        do readNameToken(s,.pos,len,.name)
        if name="" set bad=1 quit
        set ast("kind")="attr",ast("name")=name
        quit
        ;
parseParen(s,pos,len,ast,bad)
        ; doc: Internal — `(` expr `)`. Sub-expr is parsed via parseExpr so
        ; doc: comparison nesting is allowed inside the group.
        new sub
        set sub="",bad=0,pos=pos+1
        do skipExprWs(s,.pos,len)
        if '$$parseExpr(s,.pos,len,.sub) set bad=1 quit
        do skipExprWs(s,.pos,len)
        if pos>len set bad=1 quit
        if $extract(s,pos)'=")" set bad=1 quit
        set pos=pos+1
        merge ast=sub
        quit
        ;
parseFnOrName(s,pos,len,ast,bad)
        ; doc: Internal — name optionally followed by `(args)`. Bare name is
        ; doc: an XPath relative name reference (used as a count() arg).
        new name,argCount,argA,fdone,c
        set bad=0
        do readNameToken(s,.pos,len,.name)
        if name="" set bad=1 quit
        do skipExprWs(s,.pos,len)
        if pos>len set ast("kind")="bareName",ast("name")=name quit
        set c=$extract(s,pos)
        if c'="(" set ast("kind")="bareName",ast("name")=name quit
        set pos=pos+1
        do skipExprWs(s,.pos,len)
        set argCount=0
        if pos'>len,$extract(s,pos)=")" do  quit
        . set pos=pos+1
        . set ast("kind")="call",ast("name")=name,ast("argCount")=0
        set fdone=0
        for  quit:fdone  do
        . if bad set fdone=1 quit
        . do skipExprWs(s,.pos,len)
        . kill argA
        . set argA=""
        . if '$$parseExpr(s,.pos,len,.argA) set bad=1 quit
        . set argCount=argCount+1
        . merge ast("arg",argCount)=argA
        . do skipExprWs(s,.pos,len)
        . if pos>len set bad=1 quit
        . if $extract(s,pos)="," set pos=pos+1 quit
        . if $extract(s,pos)=")" set pos=pos+1,fdone=1 quit
        . set bad=1
        if bad quit
        set ast("kind")="call",ast("name")=name,ast("argCount")=argCount
        quit
        ;
readNameToken(s,pos,len,name)
        ; doc: Internal — read a name [A-Za-z_:][A-Za-z0-9_:.-]*. Hyphen is
        ; doc: included so XPath function names like `string-length` parse.
        new ch,first,rest,done
        set first="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_:"
        set rest=first_"0123456789-."
        set name=""
        if pos>len quit
        set ch=$extract(s,pos)
        if first'[ch quit
        set name=ch,pos=pos+1
        set done=0
        for  quit:done  do
        . if pos>len set done=1 quit
        . set ch=$extract(s,pos)
        . if rest'[ch set done=1 quit
        . set name=name_ch,pos=pos+1
        quit
        ;
isNameStart(ch)
        ; doc: Internal — predicate identifier start char.
        if ch?1A quit 1
        if ch="_" quit 1
        if ch=":" quit 1
        quit 0
        ;
skipExprWs(s,pos,len)
        ; doc: Internal — advance past space / tab / CR / LF.
        new ch,done
        set done=0
        for  quit:done  do
        . if pos>len set done=1 quit
        . set ch=$extract(s,pos)
        . if (ch=" ")!(ch=$char(9))!(ch=$char(10))!(ch=$char(13)) set pos=pos+1 quit
        . set done=1
        quit
        ;
evalPredExpr(tree,ctxPath,posInSet,sizeOfSet,ast,outType,outVal)
        ; doc: Internal — evaluate the AST against the candidate at ctxPath.
        ; doc: Sets outType ∈ {"num","str","bool"} and outVal accordingly.
        new kind,op,lhs,rhs,lT,lV,rT,rV,exists,val,cnt
        set kind=$get(ast("kind"))
        set outType="bool",outVal=0
        if kind="num" set outType="num",outVal=ast("val") quit
        if kind="str" set outType="str",outVal=ast("val") quit
        if kind="attr" do  quit
        . set exists=0,val=""
        . do attrLookupAt(.tree,ctxPath,ast("name"),.exists,.val)
        . if exists set outType="str",outVal=val
        if kind="attrAll" do  quit
        . set outType="num",outVal=$$countAttrsAt(.tree,ctxPath)
        if kind="wildcard" do  quit
        . set outType="num",outVal=$$countAllChildrenAt(.tree,ctxPath)
        if kind="bareName" do  quit
        . set cnt=$$countChildrenByNameAt(.tree,ctxPath,ast("name"))
        . set outType="num",outVal=cnt
        if kind="call" do evalCall(.tree,ctxPath,posInSet,sizeOfSet,.ast,.outType,.outVal) quit
        if kind="binop" do  quit
        . set op=ast("op")
        . merge lhs=ast("lhs")
        . merge rhs=ast("rhs")
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.lhs,.lT,.lV)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.rhs,.rT,.rV)
        . do compareOp(op,lT,lV,rT,rV,.outType,.outVal)
        quit
        ;
evalCall(tree,ctxPath,posInSet,sizeOfSet,ast,outType,outVal)
        ; doc: Internal — function-call dispatch. Unknown functions return
        ; doc: bool 0 (truthiness preserved as falsy).
        new fname,argCount,a1,a2,a1T,a1V,a2T,a2V,s1,s2,argKind,argName
        set fname=ast("name"),argCount=$get(ast("argCount"),0)
        set outType="bool",outVal=0
        if fname="position" set outType="num",outVal=posInSet quit
        if fname="last" set outType="num",outVal=sizeOfSet quit
        if fname="name" set outType="str",outVal=$$nameAtPath(.tree,ctxPath) quit
        if fname="text" set outType="str",outVal=$$textAtPath(.tree,ctxPath) quit
        if fname="normalize-space" do  quit
        . if argCount=0 set outType="str",outVal=$$normWs($$textAtPath(.tree,ctxPath)) quit
        . merge a1=ast("arg",1)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a1,.a1T,.a1V)
        . set outType="str",outVal=$$normWs($$toStr(a1T,a1V))
        if fname="string-length" do  quit
        . if argCount=0 set outType="num",outVal=$length($$textAtPath(.tree,ctxPath)) quit
        . merge a1=ast("arg",1)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a1,.a1T,.a1V)
        . set outType="num",outVal=$length($$toStr(a1T,a1V))
        if fname="contains" do  quit
        . if argCount<2 quit
        . merge a1=ast("arg",1)
        . merge a2=ast("arg",2)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a1,.a1T,.a1V)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a2,.a2T,.a2V)
        . set s1=$$toStr(a1T,a1V),s2=$$toStr(a2T,a2V)
        . set outType="bool",outVal=$select(s2="":1,1:s1[s2)
        if fname="starts-with" do  quit
        . if argCount<2 quit
        . merge a1=ast("arg",1)
        . merge a2=ast("arg",2)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a1,.a1T,.a1V)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a2,.a2T,.a2V)
        . set s1=$$toStr(a1T,a1V),s2=$$toStr(a2T,a2V)
        . set outType="bool",outVal=$select(s2="":1,1:$extract(s1,1,$length(s2))=s2)
        if fname="count" do  quit
        . if argCount<1 set outType="num",outVal=0 quit
        . set argKind=$get(ast("arg",1,"kind"))
        . set argName=$get(ast("arg",1,"name"))
        . set outType="num",outVal=$$evalCountArg(.tree,ctxPath,argKind,argName)
        if fname="not" do  quit
        . if argCount<1 quit
        . merge a1=ast("arg",1)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a1,.a1T,.a1V)
        . set outType="bool",outVal=$select($$toBool(a1T,a1V):0,1:1)
        if fname="string" do  quit
        . if argCount=0 set outType="str",outVal=$$textAtPath(.tree,ctxPath) quit
        . merge a1=ast("arg",1)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a1,.a1T,.a1V)
        . set outType="str",outVal=$$toStr(a1T,a1V)
        if fname="number" do  quit
        . if argCount=0 set outType="num",outVal=+$$textAtPath(.tree,ctxPath) quit
        . merge a1=ast("arg",1)
        . do evalPredExpr(.tree,ctxPath,posInSet,sizeOfSet,.a1,.a1T,.a1V)
        . set outType="num",outVal=$$toNum(a1T,a1V)
        ; unknown function — fall through with bool 0
        quit
        ;
evalCountArg(tree,ctxPath,argKind,argName)
        ; doc: Internal — count() takes a node-set producer. v0 supports a
        ; doc: single-step relative path: bareName / `*` / `@name` / `@*`.
        if argKind="bareName" quit $$countChildrenByNameAt(.tree,ctxPath,argName)
        if argKind="wildcard" quit $$countAllChildrenAt(.tree,ctxPath)
        if argKind="attr" quit $select($$attrExistsAt(.tree,ctxPath,argName):1,1:0)
        if argKind="attrAll" quit $$countAttrsAt(.tree,ctxPath)
        quit 0
        ;
attrLookupAt(tree,path,attrName,exists,val)
        ; doc: Internal — set exists/val for an attribute lookup at path.
        new tmp
        set exists=0,val=""
        if path="" merge tmp=tree
        else  merge tmp=@$$buildRef(path,"")
        if '$data(tmp("attr",attrName)) quit
        set exists=1,val=tmp("attr",attrName)
        quit
        ;
attrExistsAt(tree,path,attrName)
        new tmp
        if path="" merge tmp=tree
        else  merge tmp=@$$buildRef(path,"")
        if $data(tmp("attr",attrName)) quit 1
        quit 0
        ;
textAtPath(tree,path)
        ; doc: Internal — direct text content at path; "" if absent.
        if path="" quit $get(tree("text"),"")
        quit $get(@$$buildRef(path,"""text"""),"")
        ;
countChildrenByNameAt(tree,path,want)
        new cc,i,actual,cp,n
        set cc=$get(@$$buildRef(path,"""childCount"""),0),n=0
        for i=1:1:cc do
        . set cp=$select(path="":i,1:path_","_i)
        . set actual=$get(@$$buildRef(cp,"""name"""))
        . if actual=want set n=n+1
        quit n
        ;
countAllChildrenAt(tree,path)
        quit $get(@$$buildRef(path,"""childCount"""),0)
        ;
countAttrsAt(tree,path)
        new tmp,k,n
        if path="" merge tmp=tree
        else  merge tmp=@$$buildRef(path,"")
        set n=0,k=""
        for  set k=$order(tmp("attr",k)) quit:k=""  set n=n+1
        quit n
        ;
toBool(type,val)
        ; doc: Internal — XPath 1.0 boolean coercion.
        if type="bool" quit $select(val:1,1:0)
        if type="num" quit $select(val=0:0,1:1)
        if type="str" quit $select(val="":0,1:1)
        quit 0
        ;
toStr(type,val)
        if type="str" quit val
        if type="num" quit val_""
        if type="bool" quit $select(val:"true",1:"false")
        quit ""
        ;
toNum(type,val)
        if type="num" quit +val
        if type="str" quit +val
        if type="bool" quit $select(val:1,1:0)
        quit 0
        ;
compareOp(op,lT,lV,rT,rV,outType,outVal)
        ; doc: Internal — `=`/`!=` use string equality unless both operands
        ; doc: are numeric; `<`/`>`/`<=`/`>=` always coerce both to number.
        new lN,rN,lS,rS
        set outType="bool"
        if (op="<")!(op=">")!(op="<=")!(op=">=") do  quit
        . set lN=$$toNum(lT,lV),rN=$$toNum(rT,rV)
        . if op="<" set outVal=$select(lN<rN:1,1:0) quit
        . if op=">" set outVal=$select(lN>rN:1,1:0) quit
        . if op="<=" set outVal=$select(lN'>rN:1,1:0) quit
        . if op=">=" set outVal=$select(lN'<rN:1,1:0)
        if (lT="num")&(rT="num") do  quit
        . set lN=+lV,rN=+rV
        . if op="=" set outVal=$select(lN=rN:1,1:0) quit
        . set outVal=$select(lN'=rN:1,1:0)
        set lS=$$toStr(lT,lV),rS=$$toStr(rT,rV)
        if op="=" set outVal=$select(lS=rS:1,1:0) quit
        set outVal=$select(lS'=rS:1,1:0)
        quit
        ;
normWs(s)
        ; doc: Internal — XPath normalize-space: trim leading/trailing
        ; doc: whitespace and collapse internal runs to a single space.
        new out,i,n,ch,inWs
        set out="",n=$length(s),inWs=1
        for i=1:1:n do
        . set ch=$extract(s,i)
        . if (ch=" ")!(ch=$char(9))!(ch=$char(10))!(ch=$char(13)) set inWs=1 quit
        . if inWs,out'="" set out=out_" "
        . set out=out_ch,inWs=0
        quit out
        ;
resolveAttrNs(node,nsMap)       ; Resolve namespace URIs for any prefixed attrs on node.
        ; doc: T25b — internal. Walks node("attr",...); for each attr name
        ; doc: containing ":", splits into prefix:local, resolves the prefix
        ; doc: against nsMap (with the built-in `xml:` prefix as a fallback),
        ; doc: and stores the resolved URI at node("attrNs", attrName).
        ; doc: Unprefixed attrs get no entry in node("attrNs",...) — per spec,
        ; doc: they have no namespace regardless of any default xmlns.
        ; doc: Returns 0 (and sets err) if any prefix is undeclared.
        new k,prefix,local,xmlNs,bad
        set xmlNs="http://www.w3.org/XML/1998/namespace",bad=0,k=""
        for  set k=$order(node("attr",k)) quit:k=""  quit:bad  do
        . if k'[":" quit
        . do splitQName(k,.prefix,.local)
        . if prefix="" quit
        . if prefix="xml" set node("attrNs",k)=xmlNs quit
        . if '$data(nsMap(prefix)) do err("undeclared namespace prefix on attribute: '"_prefix_"'") set bad=1 quit
        . set node("attrNs",k)=nsMap(prefix)
        if bad quit 0
        quit 1
        ;
splitQName(qname,prefix,localName)      ; Split "x:foo" into prefix="x" / local="foo".
        ; doc: Internal — handles the no-colon case ("foo" → prefix="" / local="foo").
        ; doc: A trailing colon ("x:") is malformed but treated leniently —
        ; doc: prefix="x", local="" — caller will likely reject downstream.
        new colonAt
        set colonAt=$find(qname,":")
        if colonAt=0 set prefix="",localName=qname quit
        set prefix=$extract(qname,1,colonAt-2)
        set localName=$extract(qname,colonAt,$length(qname))
        quit
        ;
parseName(ctx)  ; Read an XML name [A-Za-z_:] [A-Za-z0-9_:.-]*; return "" on failure.
        ; doc: Internal — XML 1.0 §2.3 Name production (subset).
        new c,out,first,rest
        set first="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_:"
        set rest=first_"0123456789.-"
        set c=$$peek(.ctx)
        if first'[c quit ""
        set out=c
        do advance(.ctx,1)
        for  set c=$$peek(.ctx) quit:c=""  quit:rest'[c  set out=out_c do advance(.ctx,1)
        quit out
        ;
        ; ---------- internal: doc-level skipping (T23) ----------
        ;
skipDocLevel(ctx)       ; Skip whitespace, comments, and PIs at the document level.
        ; doc: Internal — used before and after the root element. Returns 0
        ; doc: only if a comment / PI is malformed (unclosed); whitespace and
        ; doc: a missing comment / PI are normal.
        new end2,end4,done,bad
        set done=0,bad=0
        for  quit:done  do
        . do skipWs(.ctx)
        . set end2=$$peekN(.ctx,2)
        . set end4=$$peekN(.ctx,4)
        . if end4="<!--" do  quit
        . . if '$$skipComment(.ctx) set done=1,bad=1
        . if end2="<?" do  quit
        . . if '$$skipPI(.ctx) set done=1,bad=1
        . set done=1
        if bad quit 0
        quit 1
        ;
skipComment(ctx)        ; Consume `<!-- ... -->`. Return 1/0 on closure.
        ; doc: Internal — XML 1.0 §2.5. Comments may not contain `--` per the
        ; doc: spec, but v0 doesn't enforce that (just searches for `-->`).
        new pos,closeAt
        if $$peekN(.ctx,4)'="<!--" do err("expected <!--") quit 0
        do advance(.ctx,4)
        set pos=ctx("pos")
        set closeAt=$find(ctx("text"),"-->",pos)
        if closeAt=0 do err("unclosed comment") quit 0
        ; $find returns position after the match — set pos to that.
        set ctx("pos")=closeAt
        quit 1
        ;
skipPI(ctx)     ; Consume `<? ... ?>`. Return 1/0 on closure.
        ; doc: Internal — XML 1.0 §2.6. Also handles the `<?xml ... ?>`
        ; doc: declaration in the same path (not specially distinguished in v0).
        new closeAt
        if $$peekN(.ctx,2)'="<?" do err("expected <?") quit 0
        do advance(.ctx,2)
        set closeAt=$find(ctx("text"),"?>",ctx("pos"))
        if closeAt=0 do err("unclosed processing instruction") quit 0
        set ctx("pos")=closeAt
        quit 1
        ;
parseCdata(ctx,text)    ; Consume `<![CDATA[ ... ]]>`. Append literal content to text.
        ; doc: Internal — XML 1.0 §2.7. CDATA content is not entity-decoded;
        ; doc: `&` and `<` are preserved verbatim. Caller appends `text` to
        ; doc: the element's accumulator.
        new closeAt,startAt
        if $$peekN(.ctx,9)'="<![CDATA[" do err("expected <![CDATA[") quit 0
        do advance(.ctx,9)
        set startAt=ctx("pos")
        set closeAt=$find(ctx("text"),"]]>",startAt)
        if closeAt=0 do err("unclosed CDATA section") quit 0
        ; $find returns position after the match end; the content runs from
        ; startAt to closeAt-4 (3 chars of `]]>` + 1 for $find's offset).
        set text=$extract(ctx("text"),startAt,closeAt-4)
        set ctx("pos")=closeAt
        quit 1
        ;
        ; ---------- internal: entity decoding ----------
        ;
decodeEntities(s)       ; Decode the 5 standard entities + numeric character refs in s.
        ; doc: Internal — &amp; &lt; &gt; &quot; &apos; → & < > " '.
        ; doc: T24: also &#NNN; (decimal) and &#xHH; (hex), UTF-8-encoded.
        new out,n,i,c,end,name,cp,first
        set n=$length(s),out="",i=1
        for  quit:i>n  do
        . set c=$extract(s,i)
        . if c'="&" set out=out_c,i=i+1 quit
        . set end=$find(s,";",i)
        . if end=0 set out=out_c,i=i+1 quit
        . set name=$extract(s,i+1,end-2)
        . if name="amp" set out=out_"&",i=end quit
        . if name="lt" set out=out_"<",i=end quit
        . if name="gt" set out=out_">",i=end quit
        . if name="quot" set out=out_"""",i=end quit
        . if name="apos" set out=out_"'",i=end quit
        . set first=$extract(name,1)
        . if first="#" do  quit
        . . set cp=$$decodeNumericRef(name)
        . . if cp<0 set out=out_c,i=i+1 quit
        . . set out=out_$$encodeUtf8(cp),i=end
        . set out=out_c,i=i+1
        quit out
        ;
decodeNumericRef(name)  ; Parse `#NNN` (decimal) or `#xHH` (hex). Return code point or -1.
        ; doc: Internal — driven by decodeEntities. `name` excludes the
        ; doc: leading `&` and trailing `;`.
        new digits,n,i,c,cp,base,allowed
        if $extract(name,1)'="#" quit -1
        if $extract(name,2)="x" do
        . set base=16,digits=$extract(name,3,$length(name))
        . set allowed="0123456789abcdefABCDEF"
        else  do
        . set base=10,digits=$extract(name,2,$length(name))
        . set allowed="0123456789"
        if digits="" quit -1
        set n=$length(digits),cp=0
        for i=1:1:n do  if cp<0 quit
        . set c=$extract(digits,i)
        . if allowed'[c set cp=-1 quit
        . if base=10 set cp=cp*10+(c-0)
        . else  set cp=cp*16+$$hexDigit(c)
        if cp<0 quit -1
        if cp>1114111 quit -1   ; > U+10FFFF — invalid
        quit cp
        ;
hexDigit(c)     ; Return numeric value of a hex digit; -1 if invalid.
        ; doc: Internal — driven by decodeNumericRef.
        if (c?1N) quit c
        if "abcdef"[c quit $find("abcdef",c)+8
        if "ABCDEF"[c quit $find("ABCDEF",c)+8
        quit -1
        ;
encodeUtf8(cp)  ; Encode a code point as a 1-4-byte UTF-8 string.
        ; doc: Internal — used after numeric character reference decode.
        ; doc: U+0000-007F = 1 byte; U+0080-07FF = 2 bytes;
        ; doc: U+0800-FFFF = 3 bytes; U+10000-10FFFF = 4 bytes.
        if cp<128 quit $char(cp)
        if cp<2048 quit $char(192+(cp\64))_$char(128+(cp#64))
        if cp<65536 quit $char(224+(cp\4096))_$char(128+((cp\64)#64))_$char(128+(cp#64))
        quit $char(240+(cp\262144))_$char(128+((cp\4096)#64))_$char(128+((cp\64)#64))_$char(128+(cp#64))
        ;
        ; ---------- internal: error reporting ----------
        ;
err(msg)        ; Stash a diagnostic in ^STDLIB.
        ; doc: Internal.
        set ^STDLIB($job,"stdxml","err")=msg
        quit
