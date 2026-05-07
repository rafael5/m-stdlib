STDJSON ; m-stdlib — RFC 8259 JSON parser + serialiser.
        ; m-lint: disable-file=M-MOD-024
        ; M-MOD-024 false positives: the linter parses OPEN/CLOSE
        ; deviceparams as local reads (`(readonly)`, `(newversion)`,
        ; `(exception=...)`) and treats `for ... quit:c=""` loops as
        ; reading the iteration variable before assignment.
        ;
        ; Public API:
        ;   $$parse^STDJSON(text,.root)      — populate root, return 1/0
        ;   $$encode^STDJSON(.root)          — serialise to JSON text
        ;   $$valid^STDJSON(text)            — 1 iff text parses
        ;   $$lastError^STDJSON()            — "line:col: msg" or ""
        ;   $$type^STDJSON(.node)            — type label
        ;   $$valueOf^STDJSON(.node)         — scalar string
        ;   parseFile^STDJSON(path,.root)    — read whole file
        ;   writeFile^STDJSON(path,.node)    — write whole file
        ;
        ; Storage convention (one M tree node per JSON value):
        ;   node="o"           object — children at node(key)
        ;   node="a"           array  — children at node(i), i=1..n
        ;   node="s:VALUE"     string — VALUE is the decoded UTF-8 byte string
        ;   node="n:VALUE"     number — VALUE is the canonical numeric string
        ;   node="t" / "f"     true / false
        ;   node="z"           null   ('z' avoids colliding with 'n' for number)
        ;
        ; Parser state lives in a local context array `ctx` passed by ref
        ; through every recursive helper; no global writes during parse.
        ; The last error message is stashed at ^STDLIB($job,"stdjson","err")
        ; for $$lastError.
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDJSON-PARSE,
        ;   ,U-STDJSON-ENCODE,
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
parse(text,root)        ; Parse `text` into `root`. Returns 1/0.
        ; doc: Kills `root` first. On failure, $$lastError() holds the
        ; doc: "line:col: msg" diagnostic and the partial tree is killed.
        ; doc: Internal recursion can fire $ETRAP at arbitrary extrinsic
        ; doc: depth; ZGOTO N:label unwinds the M-stack to parse()'s own
        ; doc: level before the GOTO so parseFail's `quit 0` always
        ; doc: executes in extrinsic context (avoids M17 NOTEXTRINSIC).
        new ctx,$etrap,parseLvl
        set parseLvl=$zlevel
        set $etrap="set $ecode="""" zgoto "_parseLvl_":parseFail^STDJSON"
        kill root
        do initCtx(.ctx,text)
        do parseValue(.ctx,.root)
        do skipWs(.ctx)
        if $$peek(.ctx)'="" do raise(.ctx,"trailing garbage")
        kill ^STDLIB($job,"stdjson","err")
        quit 1
parseFail
        kill root
        quit 0
        ;
valid(text)     ; True iff `text` is conformant RFC-8259 JSON.
        ; doc: Discards the parsed tree; returns just the validity bit.
        ; doc: Empty input is invalid (RFC 8259 §2).
        new tree
        quit $$parse(text,.tree)
        ;
lastError()     ; Return the message from the most recent failed parse.
        ; doc: Empty when the last parse/valid call succeeded.
        quit $get(^STDLIB($job,"stdjson","err"),"")
        ;
type(node)      ; Return the JSON type label of `node` (or "" if undef).
        ; doc: One of: object, array, string, number, true, false, null.
        new c
        if '$data(node)#10 quit ""
        set c=$extract(node,1)
        if c="o" quit "object"
        if c="a" quit "array"
        if c="s" quit "string"
        if c="n" quit "number"
        if c="t" quit "true"
        if c="f" quit "false"
        if c="z" quit "null"
        quit ""
        ;
valueOf(node)   ; Return the scalar value for s/n leaves; "" otherwise.
        ; doc: For s, returns the decoded string content; for n, the
        ; doc: canonical numeric string as parsed from the source.
        new c
        if '$data(node)#10 quit ""
        set c=$extract(node,1)
        if c="s"!(c="n") quit $extract(node,3,$length(node))
        quit ""
        ;
encode(node)    ; Serialise `node` to JSON text.
        ; doc: Object members emit in M collation order (numeric subscripts
        ; doc: first, then string subscripts in byte order). A gappy array
        ; doc: (e.g. node(1) and node(3) without node(2)) sets $ECODE
        ; doc: ,U-STDJSON-ENCODE, rather than inventing a `null`.
        ; doc: ZGOTO-trap catches errors fired anywhere in the recursive
        ; doc: descent and unwinds cleanly to encode()'s own frame so the
        ; doc: post-error `quit ""` runs in extrinsic context (avoids the
        ; doc: M17 NOTEXTRINSIC harness crash documented previously).
        ; doc: Note: there is a separate open issue where the trap fires
        ; doc: on inputs that *should* encode cleanly, returning "" — the
        ; doc: STDLOG-JSON FORMAT('json') tests are deferred pending that
        ; doc: fix. The trap itself is correct; the over-eager $ECODE
        ; doc: setting is in encodeValue/encodeObject internals.
        new $etrap,encodeLvl
        set encodeLvl=$zlevel
        set $etrap="zgoto "_encodeLvl_":encodeFail^STDJSON"
        quit $$encodeValue(.node)
encodeFail
        quit ""
        ;
parseFile(path,root)    ; Stream-read `path`, parse into `root`.
        ; doc: Reads the whole file into memory then defers to parse().
        ; doc: On parse failure, $$lastError holds the diagnostic.
        new buf,line,eof
        set buf=""
        set eof=0
        open path:(readonly):5  else  set $ecode=",U-STDJSON-PARSE," quit
        use path:(exception="goto parseFileEof")
        for  read line  set buf=buf_line_$char(10)
parseFileEof
        set $ecode=""
        close path
        ; Strip the spurious trailing newline we appended on EOF.
        if $extract(buf,$length(buf))=$char(10) set buf=$extract(buf,1,$length(buf)-1)
        if '$$parse(buf,.root) set $ecode=",U-STDJSON-PARSE,"
        quit
        ;
writeFile(path,node)    ; Serialise `node` and write to `path`.
        ; doc: Truncates `path`. Caller's responsibility to validate the
        ; doc: tree shape; encode-time errors propagate via $ECODE.
        new text
        set text=$$encode(.node)
        open path:(newversion):5  else  set $ecode=",U-STDJSON-ENCODE," quit
        use path
        write text
        close path
        quit
        ;
        ; ---------- parser internals ----------
        ;
initCtx(ctx,text)       ; Reset parser state to start of `text`.
        ; doc: Internal — sets src/len/pos/line/col fields used by the
        ; doc: peek/advance/raise helpers.
        set ctx("src")=text
        set ctx("len")=$length(text)
        set ctx("pos")=1
        set ctx("line")=1
        set ctx("col")=1
        quit
        ;
peek(ctx)       ; One byte at the cursor, or "" at EOF.
        ; doc: Internal — does not advance. Returns "" for EOF (which is
        ; doc: distinguishable from the NUL byte $CHAR(0) by length).
        if ctx("pos")>ctx("len") quit ""
        quit $extract(ctx("src"),ctx("pos"))
        ;
peekN(ctx,n)    ; Up to n bytes at the cursor (may be shorter at EOF).
        ; doc: Internal — used to match multi-byte literals like "true".
        quit $extract(ctx("src"),ctx("pos"),ctx("pos")+n-1)
        ;
advance(ctx,n)  ; Move cursor n bytes forward; track line/col.
        ; doc: Internal — newlines bump line and reset col; everything
        ; doc: else bumps col.
        new i,c
        for i=1:1:n do
        . set c=$extract(ctx("src"),ctx("pos"))
        . set ctx("pos")=ctx("pos")+1
        . if c=$char(10) set ctx("line")=ctx("line")+1,ctx("col")=1 quit
        . set ctx("col")=ctx("col")+1
        quit
        ;
skipWs(ctx)     ; Consume RFC-8259 §2 whitespace (sp / ht / lf / cr).
        ; doc: Internal — runs to first non-whitespace or EOF.
        new c
        for  do  quit:c'=" "&(c'=$char(9))&(c'=$char(10))&(c'=$char(13))
        . set c=$$peek(.ctx)
        . if c=" "!(c=$char(9))!(c=$char(10))!(c=$char(13)) do advance(.ctx,1)
        quit
        ;
raise(ctx,msg)  ; Stash msg with line:col prefix; set $ECODE; unwind.
        ; doc: Internal — every parse helper checks $ECODE after a recursive
        ; doc: call and quits early to let the top-level $etrap catch.
        set ^STDLIB($job,"stdjson","err")=ctx("line")_":"_ctx("col")_": "_msg
        set $ecode=",U-STDJSON-PARSE,"
        quit
        ;
parseValue(ctx,node)    ; Dispatch on the first byte; populate `node`.
        ; doc: Internal — top-level parser entry. Must be preceded by
        ; doc: skipWs by the caller (parseObject/parseArray do this).
        new c
        do skipWs(.ctx)
        set c=$$peek(.ctx)
        if c="" do raise(.ctx,"unexpected EOF") quit
        if c="{" do parseObject(.ctx,.node) quit
        if c="[" do parseArray(.ctx,.node) quit
        if c="""" do parseString(.ctx,.node) quit
        if c="t" do parseLiteral(.ctx,.node,"true","t") quit
        if c="f" do parseLiteral(.ctx,.node,"false","f") quit
        if c="n" do parseLiteral(.ctx,.node,"null","z") quit
        if c="-"!(c?1N) do parseNumber(.ctx,.node) quit
        do raise(.ctx,"unexpected character '"_c_"'")
        quit
        ;
parseLiteral(ctx,node,word,sigil)       ; Match word; set node=sigil.
        ; doc: Internal — used for the three keyword literals true/false/null.
        new got
        set got=$$peekN(.ctx,$length(word))
        if got'=word do raise(.ctx,"unexpected character '"_$$peek(.ctx)_"'") quit
        do advance(.ctx,$length(word))
        set node=sigil
        quit
        ;
parseObject(ctx,node)   ; Parse {...} into `node`.
        ; doc: Internal — handles empty object, comma-separated members,
        ; doc: empty-string keys (RFC 8259 allows them). Recurses into a
        ; doc: non-subscripted local (`tmp`) and merges back into
        ; doc: node(key) afterwards; passing subscripted formals by
        ; doc: reference (`do parseValue(.ctx,.node(key))`) crashes the
        ; doc: YDB harness in this environment (TOOLCHAIN-FINDINGS).
        new c,key,done,tmp
        set node="o"
        do advance(.ctx,1)
        do skipWs(.ctx)
        if $$peek(.ctx)="}" do advance(.ctx,1) quit
        set done=0
        for  quit:done!($ecode'="")  do
        . if $$peek(.ctx)'="""" do raise(.ctx,"expected string key") quit
        . set key=$$parseStringValue(.ctx)
        . if $ecode'="" quit
        . do skipWs(.ctx)
        . if $$peek(.ctx)'=":" do raise(.ctx,"expected ':' after key") quit
        . do advance(.ctx,1)
        . kill tmp
        . do parseValue(.ctx,.tmp)
        . merge node(key)=tmp
        . if $ecode'="" quit
        . do skipWs(.ctx)
        . set c=$$peek(.ctx)
        . if c="}" set done=1 do advance(.ctx,1) quit
        . if c'="," do raise(.ctx,"expected ',' or '}'") quit
        . do advance(.ctx,1)
        . do skipWs(.ctx)
        quit
        ;
parseArray(ctx,node)    ; Parse [...] into `node`.
        ; doc: Internal — handles empty array, comma-separated elements;
        ; doc: trailing comma is rejected (RFC 8259 §5). Recurses into a
        ; doc: non-subscripted local for the same reason as parseObject.
        new c,i,done,tmp
        set node="a"
        do advance(.ctx,1)
        do skipWs(.ctx)
        if $$peek(.ctx)="]" do advance(.ctx,1) quit
        set done=0,i=0
        for  quit:done!($ecode'="")  do
        . set i=i+1
        . kill tmp
        . do parseValue(.ctx,.tmp)
        . merge node(i)=tmp
        . if $ecode'="" quit
        . do skipWs(.ctx)
        . set c=$$peek(.ctx)
        . if c="]" set done=1 do advance(.ctx,1) quit
        . if c'="," do raise(.ctx,"expected ',' or ']'") quit
        . do advance(.ctx,1)
        . do skipWs(.ctx)
        quit
        ;
parseString(ctx,node)   ; Parse "..." into `node` as s:VALUE.
        ; doc: Internal — uses parseStringValue() to decode; wraps in
        ; doc: the s: sigil.
        new s
        set s=$$parseStringValue(.ctx)
        if $ecode'="" quit
        set node="s:"_s
        quit
        ;
parseStringValue(ctx)   ; Parse "..." and return the decoded content.
        ; doc: Internal — handles \\\\ \\" \\/ \\b \\f \\n \\r \\t and \\uXXXX
        ; doc: escapes, including UTF-16 surrogate pairs. Bare control
        ; doc: bytes 0x00..0x1F are rejected.
        new out,c,bv,esc,cp,cp2
        set out=""
        if $$peek(.ctx)'="""" do raise(.ctx,"expected '""'") quit ""
        do advance(.ctx,1)
        for  do  quit:$ecode'=""!(c="""")
        . set c=$$peek(.ctx)
        . if c="" do raise(.ctx,"unterminated string") quit
        . if c="""" do advance(.ctx,1) quit
        . set bv=$ascii(c)
        . if bv<32 do raise(.ctx,"unescaped control character") quit
        . if c="\" do
        . . do advance(.ctx,1)
        . . set esc=$$peek(.ctx)
        . . if esc="" do raise(.ctx,"unterminated string") quit
        . . if esc="""" set out=out_"""" do advance(.ctx,1) quit
        . . if esc="\" set out=out_"\" do advance(.ctx,1) quit
        . . if esc="/" set out=out_"/" do advance(.ctx,1) quit
        . . if esc="b" set out=out_$char(8) do advance(.ctx,1) quit
        . . if esc="f" set out=out_$char(12) do advance(.ctx,1) quit
        . . if esc="n" set out=out_$char(10) do advance(.ctx,1) quit
        . . if esc="r" set out=out_$char(13) do advance(.ctx,1) quit
        . . if esc="t" set out=out_$char(9) do advance(.ctx,1) quit
        . . if esc="u" do
        . . . new sawSurrogate
        . . . do advance(.ctx,1)
        . . . set cp=$$parseHex4(.ctx)
        . . . if cp<0 do raise(.ctx,"bad \u escape") quit
        . . . set sawSurrogate=0
        . . . if cp>=55296,cp<=56319 do
        . . . . ; high surrogate — must be followed by \uDCxx..\uDFxx
        . . . . if $$peekN(.ctx,2)'="\u" do raise(.ctx,"lone surrogate") quit
        . . . . do advance(.ctx,2)
        . . . . set cp2=$$parseHex4(.ctx)
        . . . . if cp2<56320!(cp2>57343) do raise(.ctx,"lone surrogate") quit
        . . . . set cp=65536+(cp-55296)*1024+(cp2-56320)
        . . . . set sawSurrogate=1
        . . . if $ecode'="" quit
        . . . if 'sawSurrogate,cp>=56320,cp<=57343 do raise(.ctx,"lone surrogate") quit
        . . . set out=out_$$emitUtf8(cp)
        . . . quit
        . . if $ecode'="" quit
        . . do raise(.ctx,"bad escape '\"_esc_"'")
        . else  set out=out_c do advance(.ctx,1)
        if $ecode'="" quit ""
        quit out
        ;
parseHex4(ctx) ; Parse exactly 4 hex digits; return codepoint or -1.
        ; doc: Internal — does not raise; caller decides what to do with -1.
        new s,n,i,c,v
        set s=$$peekN(.ctx,4)
        if $length(s)<4 quit -1
        set n=0
        for i=1:1:4 do  quit:v<0
        . set c=$extract(s,i)
        . set v=$$hexVal(c)
        . if v<0 quit
        . set n=n*16+v
        if v<0 quit -1
        do advance(.ctx,4)
        quit n
        ;
hexVal(c)       ; Map a hex char to 0..15; -1 if not hex.
        ; doc: Internal — accepts 0-9, A-F, a-f.
        new bv
        set bv=$ascii(c)
        if bv>=48,bv<=57 quit bv-48
        if bv>=65,bv<=70 quit bv-55
        if bv>=97,bv<=102 quit bv-87
        quit -1
        ;
emitUtf8(cp)    ; Codepoint -> 1-4 byte UTF-8 byte sequence.
        ; doc: Internal — assumes cp is a valid scalar (caller filters
        ; doc: out the surrogate range D800-DFFF).
        if cp<128 quit $char(cp)
        if cp<2048 quit $char(192+cp\64)_$char(128+cp#64)
        if cp<65536 quit $char(224+cp\4096)_$char(128+(cp\64)#64)_$char(128+cp#64)
        quit $char(240+cp\262144)_$char(128+(cp\4096)#64)_$char(128+(cp\64)#64)_$char(128+cp#64)
        ;
parseNumber(ctx,node)   ; Parse a number per RFC 8259 §6.
        ; doc: Internal — captures the source span verbatim; rejects
        ; doc: leading zeros, lone decimals, and missing exponent digits.
        new start,c,saw,len
        set start=ctx("pos")
        if $$peek(.ctx)="-" do advance(.ctx,1)
        set c=$$peek(.ctx)
        if c'?1N do raise(.ctx,"bad number") quit
        if c="0" do advance(.ctx,1)
        else  do
        . for  do  quit:$$peek(.ctx)'?1N
        . . do advance(.ctx,1)
        if $$peek(.ctx)="." do
        . do advance(.ctx,1)
        . if $$peek(.ctx)'?1N do raise(.ctx,"bad number") quit
        . for  do  quit:$$peek(.ctx)'?1N
        . . do advance(.ctx,1)
        if $ecode'="" quit
        set c=$$peek(.ctx)
        if c="e"!(c="E") do
        . do advance(.ctx,1)
        . set c=$$peek(.ctx)
        . if c="+"!(c="-") do advance(.ctx,1)
        . if $$peek(.ctx)'?1N do raise(.ctx,"bad number") quit
        . for  do  quit:$$peek(.ctx)'?1N
        . . do advance(.ctx,1)
        if $ecode'="" quit
        set len=ctx("pos")-start
        set node="n:"_$extract(ctx("src"),start,start+len-1)
        quit
        ;
        ; ---------- encoder internals ----------
        ;
encodeValue(node)       ; Recursive walker — return JSON text for `node`.
        ; doc: Internal — dispatches on the type sigil; raises
        ; doc: ,U-STDJSON-ENCODE, on unknown sigil.
        new c
        if '$data(node)#10,$data(node)=0 set $ecode=",U-STDJSON-ENCODE," quit ""
        set c=$extract(node,1)
        if c="o" quit $$encodeObject(.node)
        if c="a" quit $$encodeArray(.node)
        if c="s" quit $$encodeString($extract(node,3,$length(node)))
        if c="n" quit $extract(node,3,$length(node))
        if c="t" quit "true"
        if c="f" quit "false"
        if c="z" quit "null"
        set $ecode=",U-STDJSON-ENCODE,"
        quit ""
        ;
encodeObject(node)      ; Emit {k:v,...} for an object node.
        ; doc: Internal — walks node() children in M collation order.
        ; doc: Uses `merge tmp=node(k)` to copy the child subtree into a
        ; doc: non-subscripted local before recursing; passing subscripted
        ; doc: formals by reference (`$$encodeValue(.node(k))`) crashes
        ; doc: the YDB harness in this environment (TOOLCHAIN-FINDINGS).
        new out,k,first,tmp
        set out="{"
        set first=1
        set k=$order(node(""))
        for  quit:k=""  do
        . if 'first set out=out_","
        . set first=0
        . kill tmp
        . merge tmp=node(k)
        . set out=out_$$encodeString(k)_":"_$$encodeValue(.tmp)
        . set k=$order(node(k))
        set out=out_"}"
        quit out
        ;
encodeArray(node)       ; Emit [v,v,...] for an array node.
        ; doc: Internal — expects 1..n contiguous indices; sets
        ; doc: ,U-STDJSON-ENCODE, on a gap. Uses merge-into-local before
        ; doc: recursing for the same reason as encodeObject.
        new out,i,n,first,tmp
        set out="["
        set n=0
        set i=$order(node(""))
        for  quit:i=""  set n=n+1,i=$order(node(i))
        set first=1
        for i=1:1:n do  quit:$ecode'=""
        . if '$data(node(i)) set $ecode=",U-STDJSON-ENCODE," quit
        . if 'first set out=out_","
        . set first=0
        . kill tmp
        . merge tmp=node(i)
        . set out=out_$$encodeValue(.tmp)
        if $ecode'="" quit ""
        set out=out_"]"
        quit out
        ;
encodeString(s) ; Wrap `s` in quotes; re-escape per RFC 8259 §7.
        ; doc: Internal — bytes 0x00-0x1F lacking a named escape become
        ; doc: \\u00XX; bytes 0x20+ pass through (caller is assumed to be
        ; doc: handing in a UTF-8 byte sequence).
        new out,n,i,c,bv
        set out=""""
        set n=$length(s)
        for i=1:1:n do
        . set c=$extract(s,i)
        . set bv=$ascii(c)
        . if c="""" set out=out_"\""" quit
        . if c="\" set out=out_"\\" quit
        . if bv=8 set out=out_"\b" quit
        . if bv=9 set out=out_"\t" quit
        . if bv=10 set out=out_"\n" quit
        . if bv=12 set out=out_"\f" quit
        . if bv=13 set out=out_"\r" quit
        . if bv<32 set out=out_"\u00"_$$hex2(bv) quit
        . set out=out_c
        set out=out_""""
        quit out
        ;
hex2(bv)        ; Two-digit lowercase hex for a byte value 0..255.
        ; doc: Internal — used for \\u00XX control-byte escaping.
        new alpha,hi,lo
        set alpha="0123456789abcdef"
        set hi=bv\16
        set lo=bv#16
        quit $extract(alpha,hi+1)_$extract(alpha,lo+1)
        ;
