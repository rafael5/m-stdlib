STDHTTPTST      ; Test suite for STDHTTP (track H3, target tag v0.4.0).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; the
        ; by-ref analyser can't see writes through the callee boundary.
        ;
        ; Iteration 1 covers pure-M wire-format helpers only:
        ;   parseStatusLine / parseHeader / parseResponse / buildRequest /
        ;   formatHeaders. The libcurl-bound network extrinsics
        ;   ($$get / $$post / $$request) are exercised in iteration 2's
        ;   suite once src/callouts/http.c lands.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---- parseStatusLine ----
        do tStatusLineHttp11Ok(.pass,.fail)
        do tStatusLineHttp10Ok(.pass,.fail)
        do tStatusLineNoReason(.pass,.fail)
        do tStatusLineMultiwordReason(.pass,.fail)
        do tStatusLineMalformedFlagsNotOk(.pass,.fail)
        do tStatusLineEmptyFlagsNotOk(.pass,.fail)
        ;
        ; ---- parseHeader ----
        do tHeaderSimple(.pass,.fail)
        do tHeaderTrimsLeadingSpace(.pass,.fail)
        do tHeaderTrimsLeadingTab(.pass,.fail)
        do tHeaderColonInValueKept(.pass,.fail)
        do tHeaderEmptyValueAllowed(.pass,.fail)
        do tHeaderNoColonYieldsEmpty(.pass,.fail)
        ;
        ; ---- parseResponse ----
        do tResponseFullCrlf(.pass,.fail)
        do tResponseHeaderLookupCaseInsensitive(.pass,.fail)
        do tResponseEmptyBody(.pass,.fail)
        do tResponseDuplicateHeadersJoinComma(.pass,.fail)
        do tResponseToleratesBareLf(.pass,.fail)
        do tResponseStatusOnly(.pass,.fail)
        do tResponseBinaryBodyPreservesBytes(.pass,.fail)
        do tResponseClearsCallerArray(.pass,.fail)
        ;
        ; ---- buildRequest ----
        do tBuildGetMinimal(.pass,.fail)
        do tBuildAddsHostFromUrl(.pass,.fail)
        do tBuildPreservesExplicitHost(.pass,.fail)
        do tBuildAddsContentLengthForBody(.pass,.fail)
        do tBuildOmitsContentLengthWhenAlreadySet(.pass,.fail)
        do tBuildIncludesQueryAndPath(.pass,.fail)
        do tBuildPathOnlySlashWhenEmpty(.pass,.fail)
        do tBuildIncludesPortInHostHeader(.pass,.fail)
        do tBuildPostWithBody(.pass,.fail)
        ;
        ; ---- formatHeaders ----
        do tFormatHeadersBasic(.pass,.fail)
        do tFormatHeadersEmptyArrayProducesEmpty(.pass,.fail)
        do tFormatHeadersDeterministicOrder(.pass,.fail)
        ;
        ; ---- soft-fail until libcurl callout lands ----
        do tNetworkExtrinsicsReturnNotWired(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- parseStatusLine ----------
        ;
tStatusLineHttp11Ok(pass,fail)  ;@TEST "parseStatusLine handles 'HTTP/1.1 200 OK'"
        new s
        do parseStatusLine^STDHTTP("HTTP/1.1 200 OK",.s)
        do eq^STDASSERT(.pass,.fail,$get(s("version")),"HTTP/1.1","version")
        do eq^STDASSERT(.pass,.fail,+$get(s("code")),200,"code")
        do eq^STDASSERT(.pass,.fail,$get(s("reason")),"OK","reason")
        do eq^STDASSERT(.pass,.fail,+$get(s("ok")),1,"ok flag")
        quit
        ;
tStatusLineHttp10Ok(pass,fail)  ;@TEST "parseStatusLine handles HTTP/1.0"
        new s
        do parseStatusLine^STDHTTP("HTTP/1.0 404 Not Found",.s)
        do eq^STDASSERT(.pass,.fail,$get(s("version")),"HTTP/1.0","version")
        do eq^STDASSERT(.pass,.fail,+$get(s("code")),404,"code")
        do eq^STDASSERT(.pass,.fail,$get(s("reason")),"Not Found","reason")
        quit
        ;
tStatusLineNoReason(pass,fail)  ;@TEST "parseStatusLine accepts missing reason phrase (RFC 7230 §3.1.2)"
        new s
        do parseStatusLine^STDHTTP("HTTP/1.1 204",.s)
        do eq^STDASSERT(.pass,.fail,+$get(s("code")),204,"code")
        do eq^STDASSERT(.pass,.fail,$get(s("reason")),"","reason empty")
        do eq^STDASSERT(.pass,.fail,+$get(s("ok")),1,"ok flag")
        quit
        ;
tStatusLineMultiwordReason(pass,fail)   ;@TEST "parseStatusLine keeps multi-word reason phrases"
        new s
        do parseStatusLine^STDHTTP("HTTP/1.1 502 Bad Gateway",.s)
        do eq^STDASSERT(.pass,.fail,$get(s("reason")),"Bad Gateway","multi-word")
        quit
        ;
tStatusLineMalformedFlagsNotOk(pass,fail)       ;@TEST "parseStatusLine sets ok=0 on malformed input"
        new s
        do parseStatusLine^STDHTTP("garbage",.s)
        do eq^STDASSERT(.pass,.fail,+$get(s("ok")),0,"ok=0")
        quit
        ;
tStatusLineEmptyFlagsNotOk(pass,fail)   ;@TEST "parseStatusLine sets ok=0 on empty input"
        new s
        do parseStatusLine^STDHTTP("",.s)
        do eq^STDASSERT(.pass,.fail,+$get(s("ok")),0,"ok=0")
        quit
        ;
        ; ---------- parseHeader ----------
        ;
tHeaderSimple(pass,fail)        ;@TEST "parseHeader splits 'Name: value'"
        new name,value
        do parseHeader^STDHTTP("Content-Type: text/plain",.name,.value)
        do eq^STDASSERT(.pass,.fail,name,"Content-Type","name")
        do eq^STDASSERT(.pass,.fail,value,"text/plain","value")
        quit
        ;
tHeaderTrimsLeadingSpace(pass,fail)     ;@TEST "parseHeader trims leading SP after colon"
        new name,value
        do parseHeader^STDHTTP("X: foo",.name,.value)
        do eq^STDASSERT(.pass,.fail,value,"foo","trimmed")
        quit
        ;
tHeaderTrimsLeadingTab(pass,fail)       ;@TEST "parseHeader trims leading HT after colon"
        new name,value
        do parseHeader^STDHTTP("X:"_$char(9)_"foo",.name,.value)
        do eq^STDASSERT(.pass,.fail,value,"foo","tab trimmed")
        quit
        ;
tHeaderColonInValueKept(pass,fail)      ;@TEST "parseHeader splits on first colon only"
        new name,value
        do parseHeader^STDHTTP("Date: Tue, 06 May 2026 12:34:56 GMT",.name,.value)
        do eq^STDASSERT(.pass,.fail,name,"Date","name")
        do eq^STDASSERT(.pass,.fail,value,"Tue, 06 May 2026 12:34:56 GMT","value w/ colons")
        quit
        ;
tHeaderEmptyValueAllowed(pass,fail)     ;@TEST "parseHeader accepts empty value"
        new name,value
        do parseHeader^STDHTTP("X-Empty:",.name,.value)
        do eq^STDASSERT(.pass,.fail,name,"X-Empty","name")
        do eq^STDASSERT(.pass,.fail,value,"","empty value")
        quit
        ;
tHeaderNoColonYieldsEmpty(pass,fail)    ;@TEST "parseHeader on no-colon line yields empty name + value"
        new name,value
        do parseHeader^STDHTTP("garbage",.name,.value)
        do eq^STDASSERT(.pass,.fail,name,"","name empty on bad input")
        do eq^STDASSERT(.pass,.fail,value,"","value empty on bad input")
        quit
        ;
        ; ---------- parseResponse ----------
        ;
tResponseFullCrlf(pass,fail)    ;@TEST "parseResponse handles a normal CRLF response"
        new resp,raw,crlf
        set crlf=$char(13,10)
        set raw="HTTP/1.1 200 OK"_crlf
        set raw=raw_"Content-Type: text/plain"_crlf
        set raw=raw_"Content-Length: 5"_crlf_crlf
        set raw=raw_"hello"
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,+$get(resp("status")),200,"status")
        do eq^STDASSERT(.pass,.fail,$get(resp("reason")),"OK","reason")
        do eq^STDASSERT(.pass,.fail,$get(resp("version")),"HTTP/1.1","version")
        do eq^STDASSERT(.pass,.fail,$get(resp("body")),"hello","body")
        do eq^STDASSERT(.pass,.fail,$get(resp("header","content-type")),"text/plain","header lookup")
        do eq^STDASSERT(.pass,.fail,$get(resp("header","content-length")),"5","content-length")
        quit
        ;
tResponseHeaderLookupCaseInsensitive(pass,fail) ;@TEST "parseResponse stores header keys lowercased"
        new resp,raw,crlf
        set crlf=$char(13,10)
        set raw="HTTP/1.1 200 OK"_crlf_"X-Custom-Header: yes"_crlf_crlf
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,$get(resp("header","x-custom-header")),"yes","lc lookup")
        do eq^STDASSERT(.pass,.fail,$data(resp("header","X-Custom-Header")),0,"original casing absent")
        quit
        ;
tResponseEmptyBody(pass,fail)   ;@TEST "parseResponse handles an empty body"
        new resp,raw,crlf
        set crlf=$char(13,10)
        set raw="HTTP/1.1 204 No Content"_crlf_"Server: x"_crlf_crlf
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,+$get(resp("status")),204,"204")
        do eq^STDASSERT(.pass,.fail,$get(resp("body")),"","empty body")
        do eq^STDASSERT(.pass,.fail,$get(resp("header","server")),"x","server header")
        quit
        ;
tResponseDuplicateHeadersJoinComma(pass,fail)   ;@TEST "parseResponse joins duplicate headers with ', ' (RFC 7230 §3.2.2)"
        new resp,raw,crlf
        set crlf=$char(13,10)
        set raw="HTTP/1.1 200 OK"_crlf
        set raw=raw_"Vary: Accept"_crlf_"Vary: User-Agent"_crlf_crlf
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,$get(resp("header","vary")),"Accept, User-Agent","joined")
        quit
        ;
tResponseToleratesBareLf(pass,fail)     ;@TEST "parseResponse tolerates bare-LF line endings"
        new resp,raw,lf
        set lf=$char(10)
        set raw="HTTP/1.1 200 OK"_lf_"Content-Type: text/plain"_lf_lf_"hi"
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,+$get(resp("status")),200,"status")
        do eq^STDASSERT(.pass,.fail,$get(resp("body")),"hi","body")
        do eq^STDASSERT(.pass,.fail,$get(resp("header","content-type")),"text/plain","header")
        quit
        ;
tResponseStatusOnly(pass,fail)  ;@TEST "parseResponse handles status line + blank line + no headers"
        new resp,raw,crlf
        set crlf=$char(13,10)
        set raw="HTTP/1.1 200 OK"_crlf_crlf
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,+$get(resp("status")),200,"status")
        do eq^STDASSERT(.pass,.fail,$get(resp("body")),"","empty body")
        quit
        ;
tResponseBinaryBodyPreservesBytes(pass,fail)    ;@TEST "parseResponse preserves arbitrary body bytes"
        new resp,raw,crlf,body
        set crlf=$char(13,10)
        set body=$char(0,1,2,3,255,254,253)
        set raw="HTTP/1.1 200 OK"_crlf_crlf_body
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,$get(resp("body")),body,"binary preserved")
        quit
        ;
tResponseClearsCallerArray(pass,fail)   ;@TEST "parseResponse kills caller's resp array first"
        new resp,raw,crlf
        set crlf=$char(13,10)
        set resp("header","stale")="leftover"
        set resp("body")="leftover"
        set raw="HTTP/1.1 200 OK"_crlf_crlf
        do parseResponse^STDHTTP(raw,.resp)
        do eq^STDASSERT(.pass,.fail,$data(resp("header","stale")),0,"stale header gone")
        do eq^STDASSERT(.pass,.fail,$get(resp("body")),"","stale body gone")
        quit
        ;
        ; ---------- buildRequest ----------
        ;
tBuildGetMinimal(pass,fail)     ;@TEST "buildRequest emits GET request line + Host header + blank line"
        new req,wire,crlf
        set crlf=$char(13,10)
        set req("method")="GET"
        set req("url")="http://example.com/"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"GET / HTTP/1.1"_crlf,"request line")
        do contains^STDASSERT(.pass,.fail,wire,"Host: example.com"_crlf,"host header")
        ; Blank-line terminator
        do contains^STDASSERT(.pass,.fail,wire,crlf_crlf,"blank line")
        quit
        ;
tBuildAddsHostFromUrl(pass,fail)        ;@TEST "buildRequest synthesises Host: from URL when not given"
        new req,wire
        set req("method")="GET"
        set req("url")="https://api.example.org/v1/x"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"Host: api.example.org","host from url")
        quit
        ;
tBuildPreservesExplicitHost(pass,fail)  ;@TEST "buildRequest does not override an explicit Host header"
        new req,wire
        set req("method")="GET"
        set req("url")="http://10.0.0.1/"
        set req("header","Host")="virtual.example.com"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"Host: virtual.example.com","explicit host kept")
        ; And we should not also emit the URL-derived host
        do false^STDASSERT(.pass,.fail,wire["Host: 10.0.0.1","no duplicate Host")
        quit
        ;
tBuildAddsContentLengthForBody(pass,fail)       ;@TEST "buildRequest adds Content-Length when a body is present"
        new req,wire
        set req("method")="POST"
        set req("url")="http://example.com/x"
        set req("body")="hello"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"Content-Length: 5","content-length")
        do contains^STDASSERT(.pass,.fail,wire,"hello","body in wire")
        quit
        ;
tBuildOmitsContentLengthWhenAlreadySet(pass,fail)       ;@TEST "buildRequest does not duplicate Content-Length when caller set one"
        new req,wire
        set req("method")="POST"
        set req("url")="http://example.com/x"
        set req("body")="hello"
        set req("header","Content-Length")="5"
        set wire=$$buildRequest^STDHTTP(.req)
        ; Exactly one Content-Length line (no duplicates).
        do eq^STDASSERT(.pass,.fail,$length(wire,"Content-Length:"),2,"one C-L line")
        quit
        ;
tBuildIncludesQueryAndPath(pass,fail)   ;@TEST "buildRequest preserves path + query in request line"
        new req,wire
        set req("method")="GET"
        set req("url")="http://example.com/api/v1/things?x=1&y=2"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"GET /api/v1/things?x=1&y=2 HTTP/1.1","path+query")
        quit
        ;
tBuildPathOnlySlashWhenEmpty(pass,fail) ;@TEST "buildRequest emits / when URL has no path"
        new req,wire
        set req("method")="GET"
        set req("url")="http://example.com"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"GET / HTTP/1.1","slash path")
        quit
        ;
tBuildIncludesPortInHostHeader(pass,fail)       ;@TEST "buildRequest emits host:port in Host header when port is present"
        new req,wire
        set req("method")="GET"
        set req("url")="http://example.com:8080/x"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"Host: example.com:8080","host with port")
        quit
        ;
tBuildPostWithBody(pass,fail)   ;@TEST "buildRequest emits POST with body and Content-Type"
        new req,wire,crlf
        set crlf=$char(13,10)
        set req("method")="POST"
        set req("url")="http://example.com/api"
        set req("header","Content-Type")="application/json"
        set req("body")="{""a"":1}"
        set wire=$$buildRequest^STDHTTP(.req)
        do contains^STDASSERT(.pass,.fail,wire,"POST /api HTTP/1.1","method+path")
        do contains^STDASSERT(.pass,.fail,wire,"Content-Type: application/json","content-type")
        do contains^STDASSERT(.pass,.fail,wire,crlf_crlf_"{""a"":1}","body after blank line")
        quit
        ;
        ; ---------- formatHeaders ----------
        ;
tFormatHeadersBasic(pass,fail)  ;@TEST "formatHeaders emits 'Name: value\r\n' lines"
        new h,out,crlf
        set crlf=$char(13,10)
        set h("Accept")="application/json"
        set h("X-Trace")="abc"
        set out=$$formatHeaders^STDHTTP(.h)
        do contains^STDASSERT(.pass,.fail,out,"Accept: application/json"_crlf,"accept")
        do contains^STDASSERT(.pass,.fail,out,"X-Trace: abc"_crlf,"x-trace")
        quit
        ;
tFormatHeadersEmptyArrayProducesEmpty(pass,fail)        ;@TEST "formatHeaders returns '' for empty array"
        new h,out
        set out=$$formatHeaders^STDHTTP(.h)
        do eq^STDASSERT(.pass,.fail,out,"","empty header block")
        quit
        ;
tFormatHeadersDeterministicOrder(pass,fail)     ;@TEST "formatHeaders walks $order so output is subscript-sorted"
        new h,out,crlf,first,second
        set crlf=$char(13,10)
        set h("Z")="z"
        set h("A")="a"
        set out=$$formatHeaders^STDHTTP(.h)
        ; "A: a\r\n" must appear before "Z: z\r\n"
        set first=$find(out,"A: a")
        set second=$find(out,"Z: z")
        do true^STDASSERT(.pass,.fail,(first>0)&(second>0)&(first<second),"A before Z")
        quit
        ;
        ; ---------- soft-fail until iteration 2 ----------
        ;
tNetworkExtrinsicsReturnNotWired(pass,fail)     ;@TEST "$$get / $$post / $$request stub responses set resp(error)='STDHTTP-NOT-WIRED' until libcurl callout lands"
        new resp,req,rc
        set rc=$$get^STDHTTP("http://example.com/",.resp)
        do eq^STDASSERT(.pass,.fail,$get(resp("error")),"STDHTTP-NOT-WIRED","get not-wired")
        do eq^STDASSERT(.pass,.fail,rc,0,"get returns 0")
        kill resp
        set rc=$$post^STDHTTP("http://example.com/","body",.resp,"text/plain")
        do eq^STDASSERT(.pass,.fail,$get(resp("error")),"STDHTTP-NOT-WIRED","post not-wired")
        kill resp
        set req("method")="GET",req("url")="http://example.com/"
        set rc=$$request^STDHTTP(.req,.resp)
        do eq^STDASSERT(.pass,.fail,$get(resp("error")),"STDHTTP-NOT-WIRED","request not-wired")
        quit
        ;
