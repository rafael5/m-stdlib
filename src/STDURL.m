STDURL  ; m-stdlib — RFC 3986 URI parser, builder, encoder, resolver.
        ;
        ; Seven public extrinsics:
        ;   $$parse^STDURL(url,.parts)     — split URL into components; → 1/0
        ;   $$build^STDURL(.parts)         — assemble URL from components
        ;   $$encode^STDURL(s,safe)        — percent-encode (RFC 3986 §2.1)
        ;   $$decode^STDURL(s)             — percent-decode (lenient — leaves
        ;                                    malformed % as literal text)
        ;   $$valid^STDURL(url)            — RFC 3986 well-formedness predicate
        ;   $$normalize^STDURL(url)        — case + percent + dot-segment normalization
        ;   $$resolve^STDURL(base,ref)     — resolve a relative reference (§5.3)
        ;
        ; The .parts array is a flat namespace with these keys:
        ;   parts("scheme")     parts("userinfo")   parts("host")
        ;   parts("port")       parts("path")       parts("query")
        ;   parts("fragment")
        ; parse() initialises every key (empty when absent) so callers can
        ; index without $get.
        ;
        ; Strict-mode resolve: a same-scheme reference like "http:g" against
        ; base "http://a/b/c/d;p?q" resolves to "http:g" (RFC 3986 §5.3
        ; strict; non-strict back-compat is not implemented).
        ;
        ; valid() is the strict gate. decode() is intentionally lenient
        ; (matches Python urllib.parse.unquote) — bad %-sequences pass through
        ; as literal text. Use valid() first if strict input is required.
        ;
        ; Input is treated as a string of bytes (one M character per byte —
        ; values 0..255 via $ASCII / $CHAR). RFC 3986 §2.5 specifies UTF-8
        ; for non-ASCII; producers/consumers should percent-encode UTF-8
        ; bytes before passing to encode().
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
parse(url,parts)        ; Split url into parts(scheme/userinfo/host/port/path/query/fragment).
        ; doc: @param url     string  URL or relative reference
        ; doc: @param parts   array   by-ref local; killed then populated with 7 keys
        ; doc: @example       do parse^STDURL("https://example.com/foo?x=1",.p)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$build^STDURL, $$valid^STDURL, $$normalize^STDURL
        ; doc: All seven keys (scheme/userinfo/host/port/path/query/fragment)
        ; doc: are written; absent components are set to "". Empty input is
        ; doc: valid and yields all-empty parts.
        new rest,scheme,auth,p
        kill parts
        set parts("scheme")="",parts("userinfo")="",parts("host")=""
        set parts("port")="",parts("path")="",parts("query")="",parts("fragment")=""
        if $length(url)=0 quit
        set scheme="",rest=url
        if rest["#" do
        . set parts("fragment")=$piece(rest,"#",2,99999)
        . set rest=$piece(rest,"#",1)
        if rest["?" do
        . set parts("query")=$piece(rest,"?",2,99999)
        . set rest=$piece(rest,"?",1)
        if $$tryScheme(rest,.scheme) do
        . set parts("scheme")=scheme
        . set rest=$extract(rest,$length(scheme)+2,99999)
        if $extract(rest,1,2)="//" do
        . set rest=$extract(rest,3,99999)
        . set p=$$findPathStart(rest)
        . set auth=$extract(rest,1,p-1)
        . set rest=$extract(rest,p,99999)
        . do parseAuth(auth,.parts)
        set parts("path")=rest
        quit
        ;
build(parts)    ; Reassemble parts into a URL string.
        ; doc: @param parts   array   by-ref local with scheme/userinfo/host/port/path/query/fragment
        ; doc: @returns       string  reassembled URL
        ; doc: @example       set p("scheme")="https",p("host")="x.com" w $$build^STDURL(.p)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$parse^STDURL
        ; doc: Emits authority ("//user@host:port") iff any of userinfo, host,
        ; doc: or port is non-empty. The result round-trips parse() for
        ; doc: canonical inputs.
        new s,user,host,port,auth
        set s=""
        if $get(parts("scheme"))'="" set s=parts("scheme")_":"
        set user=$get(parts("userinfo")),host=$get(parts("host")),port=$get(parts("port"))
        if (user'="")!(host'="")!(port'="") do
        . set auth=""
        . if user'="" set auth=user_"@"
        . set auth=auth_host
        . if port'="" set auth=auth_":"_port
        . set s=s_"//"_auth
        set s=s_$get(parts("path"))
        if $get(parts("query"))'="" set s=s_"?"_parts("query")
        if $get(parts("fragment"))'="" set s=s_"#"_parts("fragment")
        quit s
        ;
encode(s,safe)  ; Percent-encode s. Unreserved chars + chars in safe pass through.
        ; doc: @param s       string  input string (one M character per byte)
        ; doc: @param safe    string  additional pass-through characters
        ; doc: @returns       string  percent-encoded text
        ; doc: @example       write $$encode^STDURL("hello world","")  ; "hello%20world"
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$decode^STDURL
        ; doc: Unreserved set is ALPHA / DIGIT / "-" / "." / "_" / "~"
        ; doc: (RFC 3986 §2.3). Space becomes %20 (per RFC; not "+", which
        ; doc: is the application/x-www-form-urlencoded convention).
        new out,i,n,c,unreserved,passthrough
        set out="",n=$length(s)
        if n=0 quit ""
        set unreserved="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        set passthrough=unreserved_$get(safe)
        for i=1:1:n do
        . set c=$extract(s,i)
        . if passthrough[c set out=out_c quit
        . set out=out_$$pct($ascii(c))
        quit out
        ;
decode(s)       ; Percent-decode all valid %HH; leave malformed % as literal.
        ; doc: @param s       string  percent-encoded text
        ; doc: @returns       string  decoded text (lenient — bad %-sequences pass through)
        ; doc: @example       write $$decode^STDURL("hello%20world")  ; "hello world"
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$encode^STDURL, $$valid^STDURL
        ; doc: Use valid() first if strict input is required. "+" is treated
        ; doc: as a literal "+" (form-encoding semantics belong to the caller).
        new out,i,n,c
        set out="",n=$length(s),i=1
        for  quit:i>n  do
        . set c=$extract(s,i)
        . if c="%",i+2<=n,$$isHex($extract(s,i+1,i+2)) do  quit
        . . set out=out_$char($$hex2dec($extract(s,i+1,i+2)))
        . . set i=i+3
        . set out=out_c,i=i+1
        quit out
        ;
valid(url)      ; True iff url is a well-formed RFC 3986 URI (or relative reference).
        ; doc: @param url     string  candidate URL
        ; doc: @returns       bool    1 iff well-formed
        ; doc: @example       write $$valid^STDURL("/foo")  ; 1
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$parse^STDURL
        ; doc: Empty string is valid. Rejects raw spaces, control characters,
        ; doc: and malformed %HH.
        new n,i,c,scheme,bad
        set bad=0
        if url="" quit 1
        if url[":",$translate($piece(url,":"),"/?#")=$piece(url,":") do
        . if '$$tryScheme(url,.scheme) set bad=1
        if bad quit 0
        set n=$length(url),i=1
        for  quit:i>n  quit:bad  do
        . set c=$extract(url,i)
        . if c="%" do  quit
        . . if i+2>n set bad=1 quit
        . . if '$$isHex($extract(url,i+1,i+2)) set bad=1 quit
        . . set i=i+3
        . if '$$isUriChar(c) set bad=1 quit
        . set i=i+1
        quit 'bad
        ;
normalize(url)  ; Apply RFC 3986 §6.2 syntax-based normalization.
        ; doc: @param url     string  URL to normalize
        ; doc: @returns       string  normalized URL
        ; doc: @example       write $$normalize^STDURL("HTTPS://EX.COM/a/./b")  ; "https://ex.com/a/b"
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$resolve^STDURL, $$parse^STDURL
        ; doc: Lowercases scheme + host, uppercases %HH hex digits,
        ; doc: percent-decodes unreserved characters, and removes
        ; doc: dot-segments from the path.
        new parts
        do parse(url,.parts)
        if $get(parts("scheme"))'="" set parts("scheme")=$$lower(parts("scheme"))
        if $get(parts("host"))'="" set parts("host")=$$lower(parts("host"))
        set parts("userinfo")=$$normPct($get(parts("userinfo")))
        set parts("path")=$$normPct($get(parts("path")))
        set parts("query")=$$normPct($get(parts("query")))
        set parts("fragment")=$$normPct($get(parts("fragment")))
        if $get(parts("path"))'="" set parts("path")=$$removeDots(parts("path"))
        quit $$build(.parts)
        ;
resolve(base,ref)       ; Resolve ref against base per RFC 3986 §5.3 (strict mode).
        ; doc: @param base    string  absolute base URL
        ; doc: @param ref     string  relative or absolute reference
        ; doc: @returns       string  absolute URI string
        ; doc: @example       write $$resolve^STDURL("http://a/b/c/d","../g")  ; "http://a/b/g"
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$normalize^STDURL, $$parse^STDURL
        ; doc: Strict mode: a reference that begins with the same scheme
        ; doc: as base is still treated as scheme-bearing.
        new b,r,t,branch
        do parse(base,.b)
        do parse(ref,.r)
        set t("scheme")="",t("userinfo")="",t("host")="",t("port")=""
        set t("path")="",t("query")="",t("fragment")=""
        if $get(r("scheme"))'="" set branch="rs"
        else  if $$hasAuth(.r) set branch="ra"
        else  if $get(r("path"))="" set branch="ep"
        else  if $extract(r("path"),1)="/" set branch="ap"
        else  set branch="rp"
        if branch="rs" do
        . set t("scheme")=r("scheme")
        . set t("userinfo")=r("userinfo"),t("host")=r("host"),t("port")=r("port")
        . set t("path")=$$removeDots(r("path"))
        . set t("query")=r("query")
        if branch="ra" do
        . set t("scheme")=b("scheme")
        . set t("userinfo")=r("userinfo"),t("host")=r("host"),t("port")=r("port")
        . set t("path")=$$removeDots(r("path"))
        . set t("query")=r("query")
        if branch="ep" do
        . set t("scheme")=b("scheme")
        . set t("userinfo")=b("userinfo"),t("host")=b("host"),t("port")=b("port")
        . set t("path")=b("path")
        . set t("query")=$select(r("query")'="":r("query"),1:b("query"))
        if branch="ap" do
        . set t("scheme")=b("scheme")
        . set t("userinfo")=b("userinfo"),t("host")=b("host"),t("port")=b("port")
        . set t("path")=$$removeDots(r("path"))
        . set t("query")=r("query")
        if branch="rp" do
        . set t("scheme")=b("scheme")
        . set t("userinfo")=b("userinfo"),t("host")=b("host"),t("port")=b("port")
        . set t("path")=$$removeDots($$mergePath($$hasAuth(.b),b("path"),r("path")))
        . set t("query")=r("query")
        set t("fragment")=r("fragment")
        quit $$build(.t)
        ;
        ; ---------- internal helpers ----------
        ;
parseAuth(auth,parts)   ; Split authority into userinfo / host / port.
        ; doc: @internal
        ; doc: Handles user:pass@host:port and IPv6 [host]:port.
        new rest,rb
        set rest=auth
        if rest["@" do
        . set parts("userinfo")=$piece(rest,"@",1)
        . set rest=$piece(rest,"@",2,99999)
        if $extract(rest,1)="[" do  quit
        . set rb=$find(rest,"]")
        . if rb=0 set parts("host")=rest quit
        . set parts("host")=$extract(rest,1,rb-1)
        . if $extract(rest,rb)=":" set parts("port")=$extract(rest,rb+1,99999)
        if rest[":" do  quit
        . set parts("host")=$piece(rest,":",1)
        . set parts("port")=$piece(rest,":",2,99999)
        set parts("host")=rest
        quit
        ;
tryScheme(s,scheme)     ; → 1 iff s starts with a valid scheme; sets scheme.
        ; doc: @internal
        ; doc: RFC 3986 §3.1 scheme = ALPHA *(ALPHA/DIGIT/"+"/"-"/".").
        ; doc: A '/' before the first ':' disqualifies (no scheme).
        new colon,slash,p
        set scheme=""
        set colon=$find(s,":")
        if colon=0 quit 0
        set slash=$find(s,"/")
        if slash>0,slash<colon quit 0
        set p=$extract(s,1,colon-2)
        if p="" quit 0
        if '$$isAlpha($extract(p,1)) quit 0
        if $translate(p,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-.")'="" quit 0
        set scheme=p
        quit 1
        ;
findPathStart(s)        ; → 1-based index of first '/' in s, or length(s)+1 if none.
        ; doc: @internal
        ; doc: Used by parse() to bound the authority.
        new p
        set p=$find(s,"/")
        if p=0 quit $length(s)+1
        quit p-1
        ;
hasAuth(parts)  ; → 1 if any of userinfo / host / port is non-empty.
        ; doc: @internal
        ; doc: Pragmatic stand-in for "authority defined".
        if $get(parts("userinfo"))'="" quit 1
        if $get(parts("host"))'="" quit 1
        if $get(parts("port"))'="" quit 1
        quit 0
        ;
mergePath(baseHasAuth,basePath,refPath) ; RFC 3986 §5.2.3 path merge.
        ; doc: @internal
        ; doc: When base has authority and base path is empty, returns
        ; doc: "/" + refPath; otherwise replaces the last segment of
        ; doc: basePath with refPath.
        new p
        if baseHasAuth,basePath="" quit "/"_refPath
        set p=$length(basePath)
        for  quit:p<1  quit:$extract(basePath,p)="/"  set p=p-1
        if p=0 quit refPath
        quit $extract(basePath,1,p)_refPath
        ;
removeDots(path)        ; RFC 3986 §5.2.4 remove-dot-segments.
        ; doc: @internal
        ; doc: Collapses ".", "..", and any "/." or "/.." segments
        ; doc: against the accumulated output. Required by both
        ; doc: normalize() and resolve().
        new out,inp,p
        set out="",inp=path
        for  quit:inp=""  do
        . if $extract(inp,1,3)="../" set inp=$extract(inp,4,99999) quit
        . if $extract(inp,1,2)="./" set inp=$extract(inp,3,99999) quit
        . if $extract(inp,1,3)="/./" set inp="/"_$extract(inp,4,99999) quit
        . if inp="/." set inp="/" quit
        . if $extract(inp,1,4)="/../" do  quit
        . . set inp="/"_$extract(inp,5,99999)
        . . set p=$length(out)
        . . for  quit:p<1  quit:$extract(out,p)="/"  set p=p-1
        . . set out=$select(p<1:"",1:$extract(out,1,p-1))
        . if inp="/.." do  quit
        . . set inp="/"
        . . set p=$length(out)
        . . for  quit:p<1  quit:$extract(out,p)="/"  set p=p-1
        . . set out=$select(p<1:"",1:$extract(out,1,p-1))
        . if (inp=".")!(inp="..") set inp="" quit
        . if $extract(inp,1)="/" do  quit
        . . set p=$find(inp,"/",2)
        . . if p=0 set out=out_inp,inp="" quit
        . . set out=out_$extract(inp,1,p-2)
        . . set inp=$extract(inp,p-1,99999)
        . set p=$find(inp,"/")
        . if p=0 set out=out_inp,inp="" quit
        . set out=out_$extract(inp,1,p-2)
        . set inp=$extract(inp,p-1,99999)
        quit out
        ;
normPct(s)      ; Decode %HH for unreserved chars; uppercase hex of others.
        ; doc: @internal
        ; doc: Used by normalize() per RFC 3986 §6.2.2.
        new out,i,n,c,h,b,unreserved
        set out="",n=$length(s)
        if n=0 quit ""
        set unreserved="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        set i=1
        for  quit:i>n  do
        . set c=$extract(s,i)
        . if c="%",i+2<=n,$$isHex($extract(s,i+1,i+2)) do  quit
        . . set h=$extract(s,i+1,i+2)
        . . set b=$$hex2dec(h)
        . . if unreserved[$char(b) set out=out_$char(b),i=i+3 quit
        . . set out=out_"%"_$$upper(h),i=i+3
        . set out=out_c,i=i+1
        quit out
        ;
pct(b)  ; → "%HH" for byte value b (0..255). Hex is uppercase per §6.2.2.1.
        ; doc: @internal
        ; doc: Render one byte as a percent-triplet.
        new hex
        set hex="0123456789ABCDEF"
        quit "%"_$extract(hex,(b\16)+1)_$extract(hex,(b#16)+1)
        ;
hex2dec(s)      ; "FF" / "ff" / "Ff" → 255. Caller has verified isHex().
        ; doc: @internal
        ; doc: Two-digit hex pair to integer 0..255.
        new c,hi,lo
        set c=$ascii($extract(s,1))
        set hi=$select(c<58:c-48,c<71:c-55,1:c-87)
        set c=$ascii($extract(s,2))
        set lo=$select(c<58:c-48,c<71:c-55,1:c-87)
        quit hi*16+lo
        ;
isHex(s)        ; → 1 if s is non-empty and all hex digits (any case).
        ; doc: @internal
        ; doc: Single $translate validates the whole string.
        if s="" quit 0
        if $translate(s,"0123456789ABCDEFabcdef")="" quit 1
        quit 0
        ;
isAlpha(c)      ; → 1 if c is one ASCII letter.
        ; doc: @internal
        if "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"[c quit 1
        quit 0
        ;
isUriChar(c)    ; → 1 if c is an unreserved or reserved URI character.
        ; doc: @internal
        ; doc: RFC 3986 §2.2/§2.3 character classes.
        if "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;="[c quit 1
        quit 0
        ;
lower(s)        ; ASCII downcase (locale-independent).
        ; doc: @internal
        ; doc: Used by normalize() for scheme and host.
        quit $translate(s,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")
        ;
upper(s)        ; ASCII upcase (locale-independent).
        ; doc: @internal
        ; doc: Used by normPct() for percent-encoded hex digits.
        quit $translate(s,"abcdefghijklmnopqrstuvwxyz","ABCDEFGHIJKLMNOPQRSTUVWXYZ")
