STDHTTP ; m-stdlib — HTTP/1.1 client (track H3, target tag v0.4.0).
        ; m-lint: disable-file=M-MOD-020
        ; m-lint: disable-file=M-MOD-024
        ; m-lint: disable-file=M-MOD-036
        ; m-lint: disable-file=M-MOD-008
        ; M-MOD-008: dispatchPerform mirrors the 11-argument C-side
        ; http_perform signature; collapsing into an array would require
        ; flattening on both sides without simplifying anything.
        ; M-MOD-020: get / post pass `.req` to request as a structured
        ; input — request reads req but never writes to it. The
        ; analyser's "pass by value" suggestion is wrong for array-
        ; valued formals (a value-pass would drop subscripts). The
        ; pattern recurs in $$buildRequest($req) too — req is read-
        ; only but must be a by-ref formal to receive the subscripted
        ; tree.
        ; M-MOD-024 false positives: rc / statusCode / respHeaders /
        ; respBody / errMsg are initialised before every XECUTE'd
        ; $&stdhttp.* call but the analyser cannot follow flow through
        ; the XECUTE indirection.
        ; M-MOD-036 (XECUTE injection) is intentional: the XECUTE
        ; wrapper is the only way to embed `$&stdhttp.<fn>(...)`
        ; without tree-sitter-m tripping on the namespaced $&pkg.fn
        ; syntax. Same trick as STDCRYPTO; the XECUTE source is built
        ; from a literal template only.
        ;
        ; Two layers:
        ;   1. Pure-M wire-format helpers (iteration 1):
        ;        do parseStatusLine^STDHTTP(line, .s)
        ;        do parseHeader^STDHTTP(line, .name, .value)
        ;        do parseResponse^STDHTTP(raw, .resp)
        ;        $$buildRequest^STDHTTP(.req)
        ;        $$formatHeaders^STDHTTP(.headers)
        ;   2. Network extrinsics via $&stdhttp.* -> libcurl (iter 2):
        ;        $$get^STDHTTP(url, .resp)
        ;        $$post^STDHTTP(url, body, .resp, contentType)
        ;        $$request^STDHTTP(.req, .resp)
        ;        $$available^STDHTTP()
        ;     The .so is loaded on demand. When it is absent these soft-
        ;     fail with resp("error")="STDHTTP-NOT-WIRED" and return 0
        ;     so callers can degrade gracefully. Deployment runbook:
        ;        1. tools/build-callouts.sh        -> so/<plat>/http.so
        ;        2. export STDLIB_LIB=<dir-of-so>
        ;        3. export ydb_xc_stdhttp=<abs>/tools/std_http.xc
        ;        4. ensure libcurl is on the loader path
        ;        (or run scripts/seed-callouts.sh — does all four)
        ;
        ; Response array shape:
        ;   resp("status")             ; numeric status code
        ;   resp("reason")             ; reason phrase
        ;   resp("version")            ; "HTTP/1.1"
        ;   resp("header", lowerName)  ; header value (name lowercased)
        ;   resp("body")               ; response body bytes
        ;   resp("error")              ; "" on success
        ;
        ; Request array shape:
        ;   req("method")              ; "GET" / "POST" / ...
        ;   req("url")                 ; absolute URL
        ;   req("header", name)        ; case preserved on the wire
        ;   req("body")                ; bytes
        ;   req("timeout")             ; seconds; default 30   (iter 2)
        ;   req("followRedirects")     ; 0/1; default 1        (iter 2)
        ;   req("verifyTls")           ; 0/1; default 1        (iter 2)
        ;
        ; Header lookup on the response side is case-insensitive (keys
        ; are stored lowercased per RFC 7230 §3.2 — server casing is
        ; not semantically significant). On the request side we pass
        ; the caller's casing through to the wire for compatibility
        ; with finicky middleboxes.
        ;
        ; Bodies are M strings of bytes (one M character per byte,
        ; values 0..255 via $ASCII / $CHAR). No transcoding; no
        ; Transfer-Encoding decoding (libcurl handles chunking before
        ; the body reaches M in iteration 2).
        ;
        ; Pure-M throughout in iteration 1 — no $ZF, no $Z* extensions.
        ; Runs unchanged on YDB and IRIS.
        ;
        quit
        ;
        ; ---------- public API: wire-format helpers ----------
        ;
parseStatusLine(line,s) ; Split an HTTP/1.1 status line into version/code/reason.
        ; doc: @param line    string  HTTP/1.1 status line (e.g. "HTTP/1.1 200 OK")
        ; doc: @param s       array   by-ref local; killed then populated with version/code/reason/ok
        ; doc: @example       do parseStatusLine^STDHTTP("HTTP/1.1 200 OK",.s)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do parseHeader^STDHTTP, do parseResponse^STDHTTP
        ; doc: Tolerates a missing reason phrase (RFC 7230 §3.1.2). s("ok")=1 if
        ; doc: parsed cleanly, 0 if malformed.
        new ver,code,reason
        kill s
        set s("version")="",s("code")="",s("reason")="",s("ok")=0
        if $length(line)=0 quit
        set ver=$piece(line," ",1)
        if $extract(ver,1,5)'="HTTP/" quit
        set code=$piece(line," ",2)
        if code'?3N quit
        set reason=$piece(line," ",3,99999)
        set s("version")=ver
        set s("code")=+code
        set s("reason")=reason
        set s("ok")=1
        quit
        ;
parseHeader(line,name,value)    ; Split "Name: value" into (name, value).
        ; doc: @param line    string  header line
        ; doc: @param name    string  by-ref out; header name (or "" if no colon)
        ; doc: @param value   string  by-ref out; header value (or "" if no colon)
        ; doc: @example       do parseHeader^STDHTTP("Content-Type: text/plain",.n,.v)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do parseStatusLine^STDHTTP, do parseResponse^STDHTTP
        ; doc: Trims leading SP/HT from value. Splits on the first colon only.
        new pos,raw
        set name="",value=""
        set pos=$find(line,":")
        if pos=0 quit
        set name=$extract(line,1,pos-2)
        set raw=$extract(line,pos,99999)
        ; Trim leading SP/HT (RFC 7230 OWS — only SP and HT).
        for  quit:$length(raw)=0  quit:$extract(raw,1)'=" "&($extract(raw,1)'=$char(9))  set raw=$extract(raw,2,99999)
        set value=raw
        quit
        ;
parseResponse(raw,resp) ; Parse a complete HTTP/1.1 response message.
        ; doc: @param raw     byte-string  full HTTP/1.1 response (headers + body)
        ; doc: @param resp    array        by-ref local; killed then populated (status/reason/version/header/body)
        ; doc: @example       do parseResponse^STDHTTP(rawBytes,.resp)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$buildRequest^STDHTTP, $$request^STDHTTP
        ; doc: Splits raw on the first CRLF-CRLF (or LF-LF) boundary. Header
        ; doc: keys are lowercased; multi-value headers join with ", " (RFC 7230 §3.2.2).
        new head,body,sep,boundary,crlf,lf,nLines,i,line,sl,name,value,lc,prev
        kill resp
        set resp("status")="",resp("reason")="",resp("version")=""
        set resp("body")="",resp("error")=""
        set crlf=$char(13,10),lf=$char(10)
        ; Find the header/body separator: prefer CRLF-CRLF; fall back to LF-LF.
        set boundary=$find(raw,crlf_crlf)
        if boundary>0 do
        . set sep=crlf
        . set head=$extract(raw,1,boundary-5)
        . set body=$extract(raw,boundary,99999)
        else  do
        . set boundary=$find(raw,lf_lf)
        . if boundary>0 do
        . . set sep=lf
        . . set head=$extract(raw,1,boundary-3)
        . . set body=$extract(raw,boundary,99999)
        . else  do
        . . ; No separator — treat entire raw as headers.
        . . set sep=crlf,head=raw,body=""
        set resp("body")=body
        set nLines=$length(head,sep)
        if nLines<1 quit
        set line=$piece(head,sep,1)
        do parseStatusLine(line,.sl)
        set resp("version")=$get(sl("version"))
        set resp("status")=$get(sl("code"))
        set resp("reason")=$get(sl("reason"))
        for i=2:1:nLines  do
        . set line=$piece(head,sep,i)
        . if $length(line)=0 quit
        . do parseHeader(line,.name,.value)
        . if name="" quit
        . set lc=$$lower(name)
        . set prev=$get(resp("header",lc))
        . if prev="" set resp("header",lc)=value quit
        . set resp("header",lc)=prev_", "_value
        quit
        ;
buildRequest(req)       ; Assemble an HTTP/1.1 request message from req array.
        ; doc: @param req     array       by-ref local with method/url/header/body subscripts
        ; doc: @returns       byte-string  full wire-format request (line + headers + CRLF + body)
        ; doc: @example       set req("method")="GET",req("url")="http://x.com/a"  write $$buildRequest^STDHTTP(.req)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           do parseResponse^STDHTTP, $$formatHeaders^STDHTTP
        ; doc: Synthesises Host: from the URL when not provided. Adds
        ; doc: Content-Length: when a body is present and the header is absent.
        new method,url,parts,target,hostHeader,body,wire,sub,flags
        new crlf
        set crlf=$char(13,10)
        set method=$get(req("method"),"GET")
        set url=$get(req("url"),"")
        do parse^STDURL(url,.parts)
        set target=$$requestTarget(.parts)
        set hostHeader=$$urlHost(.parts)
        do scanHeaders(.req,.flags)
        set body=$get(req("body"))
        set wire=method_" "_target_" HTTP/1.1"_crlf
        ; Synthesised Host first (deterministic placement) when absent.
        if 'flags("host"),hostHeader'="" set wire=wire_"Host: "_hostHeader_crlf
        ; Caller's headers (sorted by $order — deterministic).
        set sub=""
        for  set sub=$order(req("header",sub)) quit:sub=""  set wire=wire_sub_": "_req("header",sub)_crlf
        ; Auto Content-Length when body present and caller didn't set one.
        if (body'=""),'flags("cl") set wire=wire_"Content-Length: "_$length(body)_crlf
        ; Header/body separator + body.
        set wire=wire_crlf_body
        quit wire
        ;
requestTarget(parts)    ; Build the request-target (path[+?query]) from a parsed URL.
        new target
        set target=$get(parts("path"))
        if target="" set target="/"
        if $get(parts("query"))'="" set target=target_"?"_parts("query")
        quit target
        ;
urlHost(parts)  ; Build the Host header value (host[:port]) from a parsed URL.
        new host
        set host=$get(parts("host"))
        if $get(parts("port"))'="" set host=host_":"_parts("port")
        quit host
        ;
scanHeaders(req,flags)  ; Walk req("header",*) and set flags("host") / flags("cl") presence bits.
        new sub,lc
        set flags("host")=0,flags("cl")=0,sub=""
        for  set sub=$order(req("header",sub)) quit:sub=""  do
        . set lc=$$lower(sub)
        . if lc="host" set flags("host")=1
        . if lc="content-length" set flags("cl")=1
        quit
        ;
formatHeaders(headers)  ; Join headers(name)=value into a CRLF-terminated header block.
        ; doc: @param headers array   by-ref local subscripted as headers(name)=value
        ; doc: @returns       string  CRLF-terminated header block
        ; doc: @example       set h("X")="1" write $$formatHeaders^STDHTTP(.h)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$buildRequest^STDHTTP
        ; doc: Walks $order so output is subscript-sorted (deterministic).
        ; doc: Caller is responsible for the final blank-line boundary.
        new sub,out,crlf
        set crlf=$char(13,10),out="",sub=""
        for  set sub=$order(headers(sub)) quit:sub=""  do
        . set out=out_sub_": "_headers(sub)_crlf
        quit out
        ;
        ; ---------- public API: network extrinsics ----------
        ;
get(url,resp)   ; HTTP GET shortcut. Returns numeric status code, or 0 on error.
        ; doc: @param url     string  absolute URL
        ; doc: @param resp    array   by-ref local; populated on return
        ; doc: @returns       int     HTTP status code; 0 on transport / TLS / not-wired error
        ; doc: @example       set sc=$$get^STDHTTP("https://example.com",.r)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$post^STDHTTP, $$request^STDHTTP
        ; doc: Soft-fails with resp("error")="STDHTTP-NOT-WIRED" if the
        ; doc: libcurl callout is unavailable.
        new req
        set req("method")="GET",req("url")=url
        quit $$request(.req,.resp)
        ;
post(url,body,resp,contentType) ; HTTP POST shortcut. Defaults Content-Type to application/octet-stream.
        ; doc: @param url           string       absolute URL
        ; doc: @param body          byte-string  request body
        ; doc: @param resp          array        by-ref local; populated on return
        ; doc: @param contentType   string       Content-Type header (default "application/octet-stream")
        ; doc: @returns             int          HTTP status code; 0 on transport / TLS / not-wired error
        ; doc: @example             set sc=$$post^STDHTTP("https://example.com/api","payload",.r,"application/json")
        ; doc: @since               v0.4.0
        ; doc: @stable              stable
        ; doc: @see                 $$get^STDHTTP, $$request^STDHTTP
        new req
        set req("method")="POST",req("url")=url
        set req("body")=$get(body)
        set req("header","Content-Type")=$get(contentType,"application/octet-stream")
        quit $$request(.req,.resp)
        ;
request(req,resp)       ; Generic HTTP request. Returns numeric status code, or 0 on error.
        ; doc: @param req     array   by-ref local with method/url/header/body/timeout/followRedirects/verifyTls
        ; doc: @param resp    array   by-ref local; populated as documented in the routine header
        ; doc: @returns       int     HTTP status code; 0 on transport / TLS / DNS failure or callout missing
        ; doc: @example       set req("method")="DELETE",req("url")="https://x.com/y"  set sc=$$request^STDHTTP(.req,.r)
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$get^STDHTTP, $$post^STDHTTP, $$available^STDHTTP
        ; doc: 4xx/5xx return their status code (the caller decides what to do
        ; doc: with non-2xx); 0 means the request did not complete.
        new method,url,headerBlock,body,timeoutMs,follow,verify
        new statusCode,respHeaders,respBody,errMsg,rc
        kill resp
        set resp("status")="",resp("reason")="",resp("version")=""
        set resp("body")="",resp("error")=""
        set method=$get(req("method"),"GET")
        set url=$get(req("url"),"")
        set headerBlock=$$requestHeaderBlock(.req)
        set body=$get(req("body"),"")
        set timeoutMs=+$get(req("timeout"),30)*1000
        if timeoutMs<=0 set timeoutMs=30000
        set follow=$select(+$get(req("followRedirects"),1):1,1:0)
        set verify=$select(+$get(req("verifyTls"),1):1,1:0)
        set statusCode=0
        set respHeaders=$$preallocBuf(1048576)
        set respBody=$$preallocBuf(1048576)
        set errMsg=$$preallocBuf(256)
        set rc=$$dispatchPerform(method,url,headerBlock,body,timeoutMs,follow,verify,.statusCode,.respHeaders,.respBody,.errMsg)
        if rc=-99 set resp("error")="STDHTTP-NOT-WIRED" quit 0
        do parseHeaderStream(respHeaders,.resp)
        set resp("body")=respBody
        if rc'=0 do
        . set resp("error")=$select($length(errMsg):errMsg,1:"STDHTTP-CALLOUT-FAIL")
        . set resp("status")=0
        . set resp("reason")=""
        if rc=0 set resp("status")=+statusCode
        quit +$get(resp("status"))
        ;
available()     ; 1 iff the libcurl callout is loaded and curl_easy_init() works.
        ; doc: @returns       bool    1 iff stdhttp.so is loaded and libcurl resolves
        ; doc: @example       if '$$available^STDHTTP() do warn^MYAPP("HTTP unavailable")
        ; doc: @since         v0.4.0
        ; doc: @stable        stable
        ; doc: @see           $$request^STDHTTP
        ; doc: Never raises — clears $ECODE on the way out.
        new $etrap,rc,cmd
        if $$env^STDOS("ydb_xc_stdhttp")="" quit 0
        set $etrap="set $ecode="""" set rc=0 quit 0"
        set rc=0
        set cmd="set rc=$&stdhttp.http_available()"
        xecute cmd
        set $ecode=""
        quit +rc
        ;
        ; ---------- internal helpers ----------
        ;
lower(s)        ; ASCII-lowercase a header name.
        ; doc: @internal
        ; doc: Header tokens are ASCII per RFC 7230 §3.2.6.
        quit $translate(s,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")
        ;
requestHeaderBlock(req) ; Build CRLF-terminated header block from req("header",*).
        ; doc: @internal
        ; doc: libcurl's CURLOPT_HTTPHEADER consumes one "Name: value"
        ; doc: line per slist entry; the C side parses this block.
        new sub,out,crlf
        set crlf=$char(13,10),out="",sub=""
        for  set sub=$order(req("header",sub)) quit:sub=""  do
        . set out=out_sub_": "_req("header",sub)_crlf
        quit out
        ;
parseHeaderStream(stream,resp)  ; Parse libcurl's captured header stream into resp.
        ; doc: @internal
        ; doc: When CURLOPT_FOLLOWLOCATION is on, libcurl emits headers
        ; doc: for every redirect. We keep the final response's headers.
        new finalHeaders,n,crlfcrlf,raw
        set crlfcrlf=$char(13,10,13,10)
        if $length(stream)=0 quit
        set n=$length(stream,crlfcrlf)
        ; A well-formed capture ends with CRLFCRLF, so $piece(.,N) = "".
        ; The last non-empty piece (N-1) is the final response's header
        ; block. For a single response this is the only block.
        set finalHeaders=$piece(stream,crlfcrlf,$select(n>1:n-1,1:1))
        set raw=finalHeaders_crlfcrlf
        do parseResponse(raw,.resp)
        quit
        ;
preallocBuf(n)  ; Allocate an n-byte M string for $ZF output capture.
        ; doc: @internal
        ; doc: YDB callouts need the M-side string at full capacity
        ; doc: before the C side writes into it.
        quit $justify("",n)
        ;
dispatchPerform(method,url,headerBlock,body,timeoutMs,follow,verify,statusCode,respHeaders,respBody,errMsg)      ; Invoke $&stdhttp.http_perform(...).
        ; doc: @internal
        ; doc: XECUTE-wraps the namespaced $&pkg.fn call. Returns the
        ; doc: C-side rc on success, -99 if the callout is unavailable.
        new $etrap,rc,cmd
        if $$env^STDOS("ydb_xc_stdhttp")="" quit -99
        set $etrap="set $ecode="""" set rc=-99 quit -99"
        set rc=0
        set cmd="set rc=$&stdhttp.http_perform(method,url,headerBlock,body,timeoutMs,follow,verify,.statusCode,.respHeaders,.respBody,.errMsg)"
        xecute cmd
        set $ecode=""
        quit rc
        ;
