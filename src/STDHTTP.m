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
        ; respBody / errMsg are initialised before every XECUTE'd $ZF
        ; call but the analyser cannot follow flow through the XECUTE
        ; indirection.
        ; M-MOD-036 (XECUTE injection) is intentional: the XECUTE
        ; wrapper is the only way to invoke $ZF without the m fmt
        ; abbreviation expander mangling the token (longest-prefix
        ; match against $ZFIND). Same trick as STDCRYPTO / STDCOMPRESS;
        ; the XECUTE source is built from a literal template only.
        ;
        ; Two layers:
        ;   1. Pure-M wire-format helpers (iteration 1):
        ;        do parseStatusLine^STDHTTP(line, .s)
        ;        do parseHeader^STDHTTP(line, .name, .value)
        ;        do parseResponse^STDHTTP(raw, .resp)
        ;        $$buildRequest^STDHTTP(.req)
        ;        $$formatHeaders^STDHTTP(.headers)
        ;   2. Network extrinsics via $ZF -> libcurl (iteration 2):
        ;        $$get^STDHTTP(url, .resp)
        ;        $$post^STDHTTP(url, body, .resp, contentType)
        ;        $$request^STDHTTP(.req, .resp)
        ;        $$available^STDHTTP()
        ;     The .so is loaded on demand. When it is absent these soft-
        ;     fail with resp("error")="STDHTTP-NOT-WIRED" and return 0
        ;     so callers can degrade gracefully. Deployment runbook:
        ;        1. tools/build-callouts.sh        -> so/<plat>/http.so
        ;        2. export STDLIB_LIB=<dir-of-so>
        ;        3. export ydb_xc_std_http=<abs>/tools/std_http.xc
        ;        4. ensure libcurl is on the loader path
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
        ; doc: Sets s("version"), s("code") (numeric), s("reason"),
        ; doc: s("ok") (1=parsed cleanly, 0=malformed). Tolerates a
        ; doc: missing reason phrase (RFC 7230 §3.1.2).
        ; doc: Example:
        ; doc:   do parseStatusLine^STDHTTP("HTTP/1.1 200 OK",.s)
        ; doc:   ; s("version")="HTTP/1.1", s("code")=200, s("reason")="OK"
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
        ; doc: Trims leading SP/HT from value. Header name preserved
        ; doc: as-given. Splits on the first colon only — colons in
        ; doc: the value (Date, ETag with port:host pairs, etc.) are
        ; doc: kept. Returns name="" / value="" if no colon present.
        ; doc: Example:
        ; doc:   do parseHeader^STDHTTP("Content-Type: text/plain",.n,.v)
        ; doc:   ; n="Content-Type", v="text/plain"
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
        ; doc: Splits raw on the first CRLF-CRLF boundary (or LF-LF if
        ; doc: the server uses bare LF), walks the status line and
        ; doc: header block, fills resp("status"), resp("reason"),
        ; doc: resp("version"), resp("header",lcName), resp("body").
        ; doc: Multi-value headers join with ", " (RFC 7230 §3.2.2).
        ; doc: Header keys are lowercased for case-insensitive lookup.
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
        ; doc: Returns the wire-format request string (request line +
        ; doc: headers + CRLF + body). Synthesises Host: from the URL
        ; doc: when not provided. Adds Content-Length: when a body is
        ; doc: present and the header is absent.
        ; doc: Example:
        ; doc:   set req("method")="GET",req("url")="http://x.com/a"
        ; doc:   write $$buildRequest^STDHTTP(.req)
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
        ; doc: Each line emitted as "Name: value\r\n". Walks $order so
        ; doc: output is subscript-sorted (deterministic). Caller is
        ; doc: responsible for the final blank-line boundary.
        new sub,out,crlf
        set crlf=$char(13,10),out="",sub=""
        for  set sub=$order(headers(sub)) quit:sub=""  do
        . set out=out_sub_": "_headers(sub)_crlf
        quit out
        ;
        ; ---------- public API: network extrinsics ----------
        ;
get(url,resp)   ; HTTP GET shortcut. Returns numeric status code, or 0 on error.
        ; doc: Drives $$request with method=GET. Soft-fails with
        ; doc:   resp("error")="STDHTTP-NOT-WIRED" and returns 0 if the
        ; doc:   libcurl callout is unavailable.
        new req
        set req("method")="GET",req("url")=url
        quit $$request(.req,.resp)
        ;
post(url,body,resp,contentType) ; HTTP POST shortcut. Defaults Content-Type to application/octet-stream.
        ; doc: Drives $$request with method=POST. Soft-fails the same
        ; doc:   way as $$get when the callout is unavailable.
        new req
        set req("method")="POST",req("url")=url
        set req("body")=$get(body)
        set req("header","Content-Type")=$get(contentType,"application/octet-stream")
        quit $$request(.req,.resp)
        ;
request(req,resp)       ; Generic HTTP request. Returns numeric status code, or 0 on error.
        ; doc: Reads req("method"), req("url"), req("header",name),
        ; doc:   req("body"), req("timeout") (seconds, default 30),
        ; doc:   req("followRedirects") (0/1, default 1),
        ; doc:   req("verifyTls") (0/1, default 1).
        ; doc: Populates resp("status") (numeric), resp("reason"),
        ; doc:   resp("version"), resp("header",lcName) (case-insensitive
        ; doc:   keys), resp("body"), resp("error") ("" on success;
        ; doc:   libcurl error string or "STDHTTP-NOT-WIRED" otherwise).
        ; doc: Returns the numeric status code on a completed HTTP
        ; doc:   exchange (including 4xx / 5xx — the caller decides what
        ; doc:   to do with non-2xx); returns 0 on transport / TLS / DNS
        ; doc:   failures or when the callout is unavailable.
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
        ; doc: Returns 0 if the .so is missing, the descriptor is not
        ; doc:   exported, or libcurl is unavailable on the loader path.
        ; doc: Never raises — clears $ECODE on the way out.
        ; doc: Cheap fast path: if $ZTRNLNM("ydb_xc_std_http") is empty
        ; doc:   the descriptor isn't deployed — return 0 without paying
        ; doc:   the XECUTE / $ZF round-trip.
        new $etrap,rc,cmd
        if $$env^STDOS("ydb_xc_std_http")="" quit 0
        set $etrap="set $ecode="""" set rc=0 quit"
        set rc=0
        set cmd="set rc=$ZF(""http_available"")"
        xecute cmd
        set $ecode=""
        quit +rc
        ;
        ; ---------- internal helpers ----------
        ;
lower(s)        ; ASCII-lowercase a header name.
        ; doc: Header tokens are ASCII per RFC 7230 §3.2.6, so we only
        ; doc:   need to translate A-Z. Avoids a STDSTR dependency for
        ; doc:   this one tiny use.
        quit $translate(s,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")
        ;
requestHeaderBlock(req) ; Build CRLF-terminated header block from req("header",*).
        ; doc: Internal — libcurl's CURLOPT_HTTPHEADER consumes one
        ; doc:   "Name: value" line per slist entry; the C side parses
        ; doc:   this block line-by-line. Host: and Content-Length: are
        ; doc:   left to libcurl (synthesised from CURLOPT_URL and
        ; doc:   CURLOPT_POSTFIELDSIZE respectively); explicit caller
        ; doc:   values override libcurl's defaults via slist precedence.
        new sub,out,crlf
        set crlf=$char(13,10),out="",sub=""
        for  set sub=$order(req("header",sub)) quit:sub=""  do
        . set out=out_sub_": "_req("header",sub)_crlf
        quit out
        ;
parseHeaderStream(stream,resp)  ; Parse libcurl's captured header stream into resp.
        ; doc: Internal — when CURLOPT_FOLLOWLOCATION is on, libcurl
        ; doc:   emits headers for every redirect response. We keep the
        ; doc:   final response's headers (last block before the trailing
        ; doc:   CRLFCRLF) and feed it to parseResponse with an empty
        ; doc:   body — the caller installs the real body afterwards.
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
        ; doc: Internal — YDB callouts need the M-side string at full
        ; doc:   capacity before the C side writes into it. $justify
        ; doc:   allocates n spaces in one O(n) pass; the C side
        ; doc:   overwrites and updates ydb_string_t.length on return.
        quit $justify("",n)
        ;
dispatchPerform(method,url,headerBlock,body,timeoutMs,follow,verify,statusCode,respHeaders,respBody,errMsg)      ; Invoke $ZF("http_perform", ...).
        ; doc: Internal — XECUTE-wraps $ZF so m fmt cannot mangle the
        ; doc:   token (longest-prefix bug against $ZFIND). Returns the
        ; doc:   C-side rc on success, -99 if the callout is unavailable.
        ; doc: Fast path: if $ZTRNLNM("ydb_xc_std_http") is empty the
        ; doc:   descriptor isn't deployed — return -99 immediately so
        ; doc:   request() can flip to "STDHTTP-NOT-WIRED" without
        ; doc:   triggering XECUTE compilation (which itself can fail
        ; doc:   on engines with a non-writable ydb_routines).
        new $etrap,rc,cmd
        if $$env^STDOS("ydb_xc_std_http")="" quit -99
        set $etrap="set $ecode="""" set rc=-99 quit"
        set rc=0
        set cmd="set rc=$ZF(""http_perform"",method,url,headerBlock,body,timeoutMs,follow,verify,.statusCode,.respHeaders,.respBody,.errMsg)"
        xecute cmd
        set $ecode=""
        quit rc
        ;
