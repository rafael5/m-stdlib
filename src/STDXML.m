STDXML  ; m-stdlib — XML parser (well-formed XML 1.0 subset, in-progress).
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
        ; Out of scope (queued for v0.x.y under T23-T27):
        ;   - <![CDATA[ ... ]]> sections                            (T23)
        ;   - <?processing-instructions ?>                          (T23)
        ;   - <!-- comments -->                                     (T23)
        ;   - <?xml ... ?> / xml decl                               (T23)
        ;   - numeric character references &#nnnn; / &#xHH;          (T24)
        ;   - namespace handling (xmlns="..." / <prefix:tag>)        (T25)
        ;   - DTDs / DOCTYPE / custom entities                       (T26)
        ;   - XPath 1.0 query subset                                 (T27)
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
        new ctx,ok
        if text="" do err("empty input") quit 0
        do initCtx(.ctx,text)
        if '$$skipDocLevel(.ctx) quit 0
        if $$peek(.ctx)'="<" do err("expected '<' at root") quit 0
        set ok=$$parseElement(.ctx,.root)
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
parseElement(ctx,node)  ; Parse one element (start-tag-with-content or empty-tag).
        ; doc: Internal — leaves the context positioned after the element.
        new name,ok,end2,c
        kill node
        if $$peek(.ctx)'="<" do err("expected '<' at element") quit 0
        do advance(.ctx,1)
        set name=$$parseName(.ctx)
        if name="" do err("expected element name") quit 0
        set node("name")=name
        if '$$parseAttrs(.ctx,.node) quit 0
        do skipWs(.ctx)
        set end2=$$peekN(.ctx,2)
        if end2="/>" do advance(.ctx,2) set node("childCount")=0 quit 1
        if $$peek(.ctx)'=">" do err("expected '>' or '/>' after attrs") quit 0
        do advance(.ctx,1)
        ; Element has content: parse text/children until </name>
        set node("childCount")=0
        if '$$parseContent(.ctx,name,.node) quit 0
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
parseContent(ctx,parentName,node)       ; Parse element content until </parentName>.
        ; doc: Internal — populates node("text") and node("child", n, ...).
        ; doc: Dispatches on `<!--` (comment), `<![CDATA[` (literal text),
        ; doc: `<?` (PI, skip), `</` (end of content), and `<name` (child).
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
        . . if '$$parseElement(.ctx,.tmpChild) set bad=1,done=1 quit
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
