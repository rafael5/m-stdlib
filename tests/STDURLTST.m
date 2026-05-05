STDURLTST       ; Test suite for STDURL (track L14, target tag v0.2.0).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---- parse: components ----
        do tParseFullUrl(.pass,.fail)
        do tParseSchemeOnly(.pass,.fail)
        do tParseAuthorityWithUserinfo(.pass,.fail)
        do tParseAuthorityWithPort(.pass,.fail)
        do tParseAuthorityUserinfoAndPort(.pass,.fail)
        do tParsePathOnlyAbsolute(.pass,.fail)
        do tParseQueryOnly(.pass,.fail)
        do tParseFragmentOnly(.pass,.fail)
        do tParseRelativeReference(.pass,.fail)
        do tParseEmptyClearsParts(.pass,.fail)
        do tParseHttpExample(.pass,.fail)
        do tParseHttpsWithEverything(.pass,.fail)
        do tParseEmptyComponentsAreEmpty(.pass,.fail)
        ;
        ; ---- build ----
        do tBuildFullUrl(.pass,.fail)
        do tBuildOmitsEmptyComponents(.pass,.fail)
        do tBuildIncludesPort(.pass,.fail)
        do tBuildIncludesUserinfo(.pass,.fail)
        do tBuildPathOnly(.pass,.fail)
        do tBuildRoundTripsParse(.pass,.fail)
        ;
        ; ---- encode (percent-encoding) ----
        do tEncodeUnreservedPassthrough(.pass,.fail)
        do tEncodeReservedAreEncoded(.pass,.fail)
        do tEncodeSpaceAsPercent20(.pass,.fail)
        do tEncodeNonAsciiBytes(.pass,.fail)
        do tEncodeEmptyIsEmpty(.pass,.fail)
        do tEncodeSafeCharsKept(.pass,.fail)
        do tEncodePercentItself(.pass,.fail)
        ;
        ; ---- decode ----
        do tDecodeBasicPercents(.pass,.fail)
        do tDecodeMixedCaseHex(.pass,.fail)
        do tDecodeNonPercentPassthrough(.pass,.fail)
        do tDecodeEmptyIsEmpty(.pass,.fail)
        do tDecodeRoundTrip(.pass,.fail)
        do tDecodePlusIsLiteralPlus(.pass,.fail)
        ;
        ; ---- valid ----
        do tValidStandardForms(.pass,.fail)
        do tValidRelativeRefs(.pass,.fail)
        do tValidEmptyIsValid(.pass,.fail)
        do tValidRejectsBareSpace(.pass,.fail)
        do tValidRejectsControlChars(.pass,.fail)
        do tValidRejectsBadPercentEncoding(.pass,.fail)
        do tValidRejectsBadScheme(.pass,.fail)
        ;
        ; ---- normalize ----
        do tNormalizeLowerCasesScheme(.pass,.fail)
        do tNormalizeLowerCasesHost(.pass,.fail)
        do tNormalizeUpperCasesPercentHex(.pass,.fail)
        do tNormalizeDecodesUnreserved(.pass,.fail)
        do tNormalizeRemovesDotSegments(.pass,.fail)
        do tNormalizeIdempotent(.pass,.fail)
        ;
        ; ---- resolve (RFC 3986 §5.4) ----
        do tResolveNormalExamples(.pass,.fail)
        do tResolveAbnormalExamples(.pass,.fail)
        do tResolveStrictMode(.pass,.fail)
        ;
        ; ---- lenient decode (Python urllib convention) ----
        do tDecodeLenientOnBadPercent(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- parse ----------
        ;
tParseFullUrl(pass,fail)        ;@TEST "parse() splits scheme/host/path/query/fragment of a full URL"
        new parts
        do parse^STDURL("https://example.com/foo?x=1#top",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("scheme")),"https","scheme")
        do eq^STDASSERT(.pass,.fail,$get(parts("host")),"example.com","host")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"/foo","path")
        do eq^STDASSERT(.pass,.fail,$get(parts("query")),"x=1","query")
        do eq^STDASSERT(.pass,.fail,$get(parts("fragment")),"top","fragment")
        quit
        ;
tParseSchemeOnly(pass,fail)     ;@TEST "parse() of scheme-only URI sets scheme and empty path"
        new parts
        do parse^STDURL("urn:isbn:0451450523",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("scheme")),"urn","scheme")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"isbn:0451450523","path")
        do eq^STDASSERT(.pass,.fail,$get(parts("host")),"","no host")
        quit
        ;
tParseAuthorityWithUserinfo(pass,fail)  ;@TEST "parse() extracts userinfo from authority"
        new parts
        do parse^STDURL("ftp://anon@ftp.example.com/pub",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("userinfo")),"anon","userinfo")
        do eq^STDASSERT(.pass,.fail,$get(parts("host")),"ftp.example.com","host")
        quit
        ;
tParseAuthorityWithPort(pass,fail)      ;@TEST "parse() extracts port from authority"
        new parts
        do parse^STDURL("http://example.com:8080/api",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("host")),"example.com","host without port")
        do eq^STDASSERT(.pass,.fail,$get(parts("port")),"8080","port")
        quit
        ;
tParseAuthorityUserinfoAndPort(pass,fail)       ;@TEST "parse() extracts userinfo + host + port together"
        new parts
        do parse^STDURL("https://user:pw@host.example:443/x",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("userinfo")),"user:pw","userinfo")
        do eq^STDASSERT(.pass,.fail,$get(parts("host")),"host.example","host")
        do eq^STDASSERT(.pass,.fail,$get(parts("port")),"443","port")
        quit
        ;
tParsePathOnlyAbsolute(pass,fail)       ;@TEST "parse() handles path-only URIs"
        new parts
        do parse^STDURL("/foo/bar",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("scheme")),"","no scheme")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"/foo/bar","path")
        quit
        ;
tParseQueryOnly(pass,fail)      ;@TEST "parse() extracts a leading ?query as query component"
        new parts
        do parse^STDURL("?a=1&b=2",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("query")),"a=1&b=2","query")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"","no path")
        quit
        ;
tParseFragmentOnly(pass,fail)   ;@TEST "parse() extracts a leading #fragment as fragment component"
        new parts
        do parse^STDURL("#sec-1",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("fragment")),"sec-1","fragment")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"","no path")
        quit
        ;
tParseRelativeReference(pass,fail)      ;@TEST "parse() of relative reference yields no scheme"
        new parts
        do parse^STDURL("../sibling/page.html",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("scheme")),"","no scheme")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"../sibling/page.html","path")
        quit
        ;
tParseEmptyClearsParts(pass,fail)       ;@TEST "parse() of empty string yields all-empty parts"
        new parts
        set parts("scheme")="leftover"
        do parse^STDURL("",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("scheme")),"","stale scheme cleared")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"","empty path")
        quit
        ;
tParseHttpExample(pass,fail)    ;@TEST "parse() of canonical http URL"
        new parts
        do parse^STDURL("http://www.example.org/",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("scheme")),"http","scheme")
        do eq^STDASSERT(.pass,.fail,$get(parts("host")),"www.example.org","host")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"/","root path")
        quit
        ;
tParseHttpsWithEverything(pass,fail)    ;@TEST "parse() handles userinfo + host + port + path + query + fragment"
        new parts
        do parse^STDURL("https://u:p@h.example:8443/a/b?c=d&e=f#g",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("scheme")),"https","scheme")
        do eq^STDASSERT(.pass,.fail,$get(parts("userinfo")),"u:p","userinfo")
        do eq^STDASSERT(.pass,.fail,$get(parts("host")),"h.example","host")
        do eq^STDASSERT(.pass,.fail,$get(parts("port")),"8443","port")
        do eq^STDASSERT(.pass,.fail,$get(parts("path")),"/a/b","path")
        do eq^STDASSERT(.pass,.fail,$get(parts("query")),"c=d&e=f","query")
        do eq^STDASSERT(.pass,.fail,$get(parts("fragment")),"g","fragment")
        quit
        ;
tParseEmptyComponentsAreEmpty(pass,fail)        ;@TEST "parse() leaves omitted components empty"
        new parts
        do parse^STDURL("http://example.com/",.parts)
        do eq^STDASSERT(.pass,.fail,$get(parts("userinfo")),"","no userinfo")
        do eq^STDASSERT(.pass,.fail,$get(parts("port")),"","no port")
        do eq^STDASSERT(.pass,.fail,$get(parts("query")),"","no query")
        do eq^STDASSERT(.pass,.fail,$get(parts("fragment")),"","no fragment")
        quit
        ;
        ; ---------- build ----------
        ;
tBuildFullUrl(pass,fail)        ;@TEST "$$build() reassembles a full URL"
        new parts,url
        set parts("scheme")="https",parts("host")="example.com",parts("path")="/foo"
        set parts("query")="x=1",parts("fragment")="top"
        set url=$$build^STDURL(.parts)
        do eq^STDASSERT(.pass,.fail,url,"https://example.com/foo?x=1#top","full")
        quit
        ;
tBuildOmitsEmptyComponents(pass,fail)   ;@TEST "$$build() omits absent scheme / authority / query / fragment"
        new parts
        set parts("path")="/foo"
        do eq^STDASSERT(.pass,.fail,$$build^STDURL(.parts),"/foo","path-only")
        kill parts
        set parts("scheme")="urn",parts("path")="isbn:0451450523"
        do eq^STDASSERT(.pass,.fail,$$build^STDURL(.parts),"urn:isbn:0451450523","scheme + path")
        quit
        ;
tBuildIncludesPort(pass,fail)   ;@TEST "$$build() emits :port when port is present"
        new parts
        set parts("scheme")="http",parts("host")="example.com",parts("port")="8080",parts("path")="/"
        do eq^STDASSERT(.pass,.fail,$$build^STDURL(.parts),"http://example.com:8080/","port")
        quit
        ;
tBuildIncludesUserinfo(pass,fail)       ;@TEST "$$build() emits userinfo@ when userinfo is present"
        new parts
        set parts("scheme")="ftp",parts("userinfo")="anon",parts("host")="ftp.example.com",parts("path")="/pub"
        do eq^STDASSERT(.pass,.fail,$$build^STDURL(.parts),"ftp://anon@ftp.example.com/pub","userinfo")
        quit
        ;
tBuildPathOnly(pass,fail)       ;@TEST "$$build() of just a path returns the path"
        new parts
        set parts("path")="../sibling"
        do eq^STDASSERT(.pass,.fail,$$build^STDURL(.parts),"../sibling","relative path")
        quit
        ;
tBuildRoundTripsParse(pass,fail)        ;@TEST "build(parse(url)) == url for canonical URLs"
        new url,parts,r
        for url="https://example.com/","http://u:p@h:80/a?b=c#d","urn:isbn:0451450523","/abs/path","?just=query","#frag" do
        . do parse^STDURL(url,.parts)
        . set r=$$build^STDURL(.parts)
        . do eq^STDASSERT(.pass,.fail,r,url,"round-trip "_url)
        . kill parts
        quit
        ;
        ; ---------- encode ----------
        ;
tEncodeUnreservedPassthrough(pass,fail) ;@TEST "encode() leaves unreserved chars (ALPHA DIGIT - . _ ~) untouched"
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("abcXYZ012-._~",""),"abcXYZ012-._~","unreserved")
        quit
        ;
tEncodeReservedAreEncoded(pass,fail)    ;@TEST "encode() percent-encodes reserved gen-delims and sub-delims"
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("/",""),"%2F","slash encoded")
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("?",""),"%3F","question encoded")
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("#",""),"%23","hash encoded")
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("&",""),"%26","ampersand encoded")
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("=",""),"%3D","equals encoded")
        quit
        ;
tEncodeSpaceAsPercent20(pass,fail)      ;@TEST "encode() emits %20 for space (RFC 3986, not application/x-www-form-urlencoded)"
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("hello world",""),"hello%20world","space")
        quit
        ;
tEncodeNonAsciiBytes(pass,fail) ;@TEST "encode() percent-encodes high-bit bytes"
        new s
        set s=$char(195)_$char(169)        ; UTF-8 for 'é'
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL(s,""),"%C3%A9","é as UTF-8")
        quit
        ;
tEncodeEmptyIsEmpty(pass,fail)  ;@TEST "encode() of empty string is empty"
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("",""),"","empty")
        quit
        ;
tEncodeSafeCharsKept(pass,fail) ;@TEST "encode() preserves chars listed in the safe argument"
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("/foo/bar","/"),"/foo/bar","slash kept when safe")
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("a=b&c","="),"a=b%26c","equals kept, ampersand encoded")
        quit
        ;
tEncodePercentItself(pass,fail) ;@TEST "encode() percent-encodes a literal percent sign"
        do eq^STDASSERT(.pass,.fail,$$encode^STDURL("100%",""),"100%25","percent")
        quit
        ;
        ; ---------- decode ----------
        ;
tDecodeBasicPercents(pass,fail) ;@TEST "decode() decodes %HH triplets"
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("hello%20world"),"hello world","%20 -> space")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("a%2Fb"),"a/b","%2F -> /")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("100%25"),"100%","%25 -> %")
        quit
        ;
tDecodeMixedCaseHex(pass,fail)  ;@TEST "decode() accepts upper, lower, mixed-case hex"
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("%2f"),"/","lowercase")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("%2F"),"/","uppercase")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("%2f%2F"),"//","mixed")
        quit
        ;
tDecodeNonPercentPassthrough(pass,fail) ;@TEST "decode() leaves non-percent chars untouched"
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("hello"),"hello","plain")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("a-b_c.d~e"),"a-b_c.d~e","unreserved")
        quit
        ;
tDecodeEmptyIsEmpty(pass,fail)  ;@TEST "decode() of empty string is empty"
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL(""),"","empty")
        quit
        ;
tDecodeRoundTrip(pass,fail)     ;@TEST "decode(encode(s)) == s for arbitrary printable strings"
        new s
        for s="hello world","a/b?c#d","100% pure","with=equals&amp","plain" do
        . do eq^STDASSERT(.pass,.fail,$$decode^STDURL($$encode^STDURL(s,"")),s,"round-trip "_s)
        quit
        ;
tDecodePlusIsLiteralPlus(pass,fail)     ;@TEST "decode() does NOT translate '+' to space (RFC 3986; that's form-encoding)"
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("a+b"),"a+b","plus is literal")
        quit
        ;
        ; ---------- valid ----------
        ;
tValidStandardForms(pass,fail)  ;@TEST "valid() accepts canonical RFC 3986 URLs"
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("https://example.com/"),"https URL")
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("http://a/b/c/d;p?q"),"with semicolon and query")
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("urn:isbn:0451450523"),"urn")
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("ftp://user@host:21/p"),"ftp")
        quit
        ;
tValidRelativeRefs(pass,fail)   ;@TEST "valid() accepts relative references"
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("../foo"),"parent relative")
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("/abs/path"),"absolute path")
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("?query=only"),"query only")
        do true^STDASSERT(.pass,.fail,$$valid^STDURL("#frag"),"fragment only")
        quit
        ;
tValidEmptyIsValid(pass,fail)   ;@TEST "valid() accepts empty string (degenerate relative ref)"
        do true^STDASSERT(.pass,.fail,$$valid^STDURL(""),"empty")
        quit
        ;
tValidRejectsBareSpace(pass,fail)       ;@TEST "valid() rejects unencoded space"
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("http://x/with space"),"raw space")
        quit
        ;
tValidRejectsControlChars(pass,fail)    ;@TEST "valid() rejects raw control characters"
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("http://x/"_$char(10)),"newline")
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("http://x/"_$char(9)),"tab")
        quit
        ;
tValidRejectsBadPercentEncoding(pass,fail)      ;@TEST "valid() rejects malformed %-encoding"
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("/foo%2"),"truncated")
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("/foo%2G"),"non-hex")
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("/foo%"),"bare percent")
        quit
        ;
tValidRejectsBadScheme(pass,fail)       ;@TEST "valid() rejects scheme not starting with ALPHA"
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("1http://x/"),"digit start")
        do false^STDASSERT(.pass,.fail,$$valid^STDURL("-x://y/"),"dash start")
        quit
        ;
        ; ---------- normalize ----------
        ;
tNormalizeLowerCasesScheme(pass,fail)   ;@TEST "normalize() lower-cases the scheme"
        do eq^STDASSERT(.pass,.fail,$$normalize^STDURL("HTTPS://example.com/"),"https://example.com/","scheme")
        quit
        ;
tNormalizeLowerCasesHost(pass,fail)     ;@TEST "normalize() lower-cases the host"
        do eq^STDASSERT(.pass,.fail,$$normalize^STDURL("https://EXAMPLE.COM/Path"),"https://example.com/Path","host but not path")
        quit
        ;
tNormalizeUpperCasesPercentHex(pass,fail)       ;@TEST "normalize() upper-cases hex digits inside %HH"
        do eq^STDASSERT(.pass,.fail,$$normalize^STDURL("/a%2fb%c3%a9"),"/a%2Fb%C3%A9","percent hex")
        quit
        ;
tNormalizeDecodesUnreserved(pass,fail)  ;@TEST "normalize() decodes percent-encoded unreserved chars"
        do eq^STDASSERT(.pass,.fail,$$normalize^STDURL("/a%2Db%5Fc"),"/a-b_c","- and _ unreserved")
        quit
        ;
tNormalizeRemovesDotSegments(pass,fail) ;@TEST "normalize() removes . and .. dot-segments from the path"
        do eq^STDASSERT(.pass,.fail,$$normalize^STDURL("http://x/a/./b/../c"),"http://x/a/c","dot segments")
        quit
        ;
tNormalizeIdempotent(pass,fail) ;@TEST "normalize() is idempotent"
        new u,n1,n2
        for u="HTTPS://EXAMPLE.COM/A/./B/../c","/a%2fb","https://h/" do
        . set n1=$$normalize^STDURL(u)
        . set n2=$$normalize^STDURL(n1)
        . do eq^STDASSERT(.pass,.fail,n2,n1,"idempotent for "_u)
        quit
        ;
        ; ---------- resolve (RFC 3986 §5.4) ----------
        ;
tResolveNormalExamples(pass,fail)       ;@TEST "resolve() matches RFC 3986 §5.4.1 normal examples"
        new b
        set b="http://a/b/c/d;p?q"
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g:h"),"g:h","g:h")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g"),"http://a/b/c/g","g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"./g"),"http://a/b/c/g","./g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g/"),"http://a/b/c/g/","g/")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"/g"),"http://a/g","/g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"//g"),"http://g","//g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"?y"),"http://a/b/c/d;p?y","?y")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g?y"),"http://a/b/c/g?y","g?y")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"#s"),"http://a/b/c/d;p?q#s","#s")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g#s"),"http://a/b/c/g#s","g#s")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g?y#s"),"http://a/b/c/g?y#s","g?y#s")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,";x"),"http://a/b/c/;x",";x")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g;x"),"http://a/b/c/g;x","g;x")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g;x?y#s"),"http://a/b/c/g;x?y#s","g;x?y#s")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,""),"http://a/b/c/d;p?q","empty")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"."),"http://a/b/c/",".")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"./"),"http://a/b/c/","./")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,".."),"http://a/b/","..")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"../"),"http://a/b/","../")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"../g"),"http://a/b/g","../g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"../.."),"http://a/","../..")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"../../"),"http://a/","../../")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"../../g"),"http://a/g","../../g")
        quit
        ;
tResolveAbnormalExamples(pass,fail)     ;@TEST "resolve() matches RFC 3986 §5.4.2 abnormal examples"
        new b
        set b="http://a/b/c/d;p?q"
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"../../../g"),"http://a/g","over-popped 1")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"../../../../g"),"http://a/g","over-popped 2")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"/./g"),"http://a/g","/./g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"/../g"),"http://a/g","/../g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g."),"http://a/b/c/g.","g.")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,".g"),"http://a/b/c/.g",".g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g.."),"http://a/b/c/g..","g..")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"..g"),"http://a/b/c/..g","..g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"./../g"),"http://a/b/g","./../g")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"./g/."),"http://a/b/c/g/","./g/.")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g/./h"),"http://a/b/c/g/h","g/./h")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g/../h"),"http://a/b/c/h","g/../h")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g;x=1/./y"),"http://a/b/c/g;x=1/y","g;x=1/./y")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g;x=1/../y"),"http://a/b/c/y","g;x=1/../y")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g?y/./x"),"http://a/b/c/g?y/./x","g?y/./x")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g?y/../x"),"http://a/b/c/g?y/../x","g?y/../x")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g#s/./x"),"http://a/b/c/g#s/./x","g#s/./x")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL(b,"g#s/../x"),"http://a/b/c/g#s/../x","g#s/../x")
        quit
        ;
tResolveStrictMode(pass,fail)   ;@TEST "resolve() is strict (RFC 3986 §5.4.2): http:g resolves to itself"
        do eq^STDASSERT(.pass,.fail,$$resolve^STDURL("http://a/b/c/d;p?q","http:g"),"http:g","strict scheme")
        quit
        ;
        ; ---------- lenient decode ----------
        ;
tDecodeLenientOnBadPercent(pass,fail)   ;@TEST "decode() leaves malformed %-sequences as literal text (Python urllib semantics)"
        ; Strictness lives in valid(), not decode() — see tValidRejectsBadPercentEncoding.
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("%2"),"%2","truncated %2 unchanged")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("%2G"),"%2G","non-hex %2G unchanged")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("%"),"%","bare % unchanged")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("a%2/b"),"a%2/b","embedded bad % unchanged")
        do eq^STDASSERT(.pass,.fail,$$decode^STDURL("%20%"),$char(32)_"%","good then bad — % left literal at EOS")
        quit
