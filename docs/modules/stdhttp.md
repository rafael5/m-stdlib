# `STDHTTP` — HTTP/1.1 client (libcurl callout)

HTTP/1.1 + HTTPS client for m-stdlib. Track **H3**, target tag `v0.4.0`
(Phase 3 lead). Two layers:

1. **Pure-M wire-format helpers** — parse/build HTTP/1.1 status lines,
   header blocks, and full responses. Testable without a network or a
   compiled callout.
2. **`$ZF → libcurl` integration** — `src/callouts/http.c` exposes a
   single `http_perform` entry point plus an `http_available` probe;
   `$$get` / `$$post` / `$$request` public extrinsics call into it.

The IRIS arm uses `$CLASSMETHOD` against `%Net.HttpRequest` and shares
the same M-side request/response array shape (Iteration 3, queued).

## Status

**Iteration 1 + 2 landed (2026-05-07).** Pure-M helpers and the
libcurl-backed network extrinsics are wired. `$$available^STDHTTP()`
returns 1 when the callout is loaded, 0 otherwise; when 0, network
calls soft-fail with `resp("error")="STDHTTP-NOT-WIRED"` and return 0
so callers can degrade gracefully without `$ETRAP`.

### Deployment

```
tools/build-callouts.sh                # produces so/<plat>/http.so
export STDLIB_LIB=$PWD/so/<plat>
export ydb_xc_std_http=$PWD/tools/std_http.xc
# libcurl must be on the loader path (libcurl.so.4 on linux,
# libcurl.4.dylib on macOS).
```

## Public API

### Pure-M helpers (iteration 1 — green)

| Entry point | Signature | Behaviour |
|---|---|---|
| `parseStatusLine` | `do parseStatusLine^STDHTTP(line,.s)` | Splits `"HTTP/1.1 200 OK"` → `s("version")`, `s("code")` (numeric), `s("reason")`. Tolerates a missing reason phrase (returns `""`). Sets `s("ok")=0` on a malformed status line. |
| `parseHeader` | `do parseHeader^STDHTTP(line,.name,.value)` | Splits `"Content-Type: text/plain"` on the first `:`. Trims leading SP/HT from value. Header name preserved as-given; lookup tables should lowercase before storing. |
| `parseResponse` | `do parseResponse^STDHTTP(raw,.resp)` | Full response: splits on the first CRLF-CRLF boundary, walks headers, fills `resp("status")`, `resp("reason")`, `resp("version")`, `resp("header",lowerName)`, `resp("body")`. Multi-value headers join with `", "` per RFC 7230 §3.2.2. |
| `buildRequest` | `$$buildRequest^STDHTTP(.req)` | Assembles a wire-format HTTP/1.1 request from `req("method")`, `req("url")`, `req("header",name)`, `req("body")`. Adds `Host:` from STDURL parse if absent. Adds `Content-Length:` if a body is present and the header is absent. |
| `formatHeaders` | `$$formatHeaders^STDHTTP(.headers)` | Joins `headers(name)=value` into a CRLF-terminated header block (each line `Name: value\r\n`, no trailing blank line — caller adds the boundary). |

### Network extrinsics (iteration 2 — green)

| Entry point | Signature | Behaviour |
|---|---|---|
| `get` | `$$get^STDHTTP(url,.resp)` | GET shortcut. Returns the numeric status code; `resp` populated as below. |
| `post` | `$$post^STDHTTP(url,body,.resp,contentType)` | POST shortcut. `contentType` defaults to `application/octet-stream`. |
| `request` | `$$request^STDHTTP(.req,.resp)` | Full request: `req("method")`, `req("url")`, `req("header",name)`, `req("body")`, `req("timeout")` (seconds, default 30), `req("followRedirects")` (0/1, default 1), `req("verifyTls")` (0/1, default 1). |
| `available` | `$$available^STDHTTP()` | `1` iff the libcurl callout is loaded and `curl_easy_init()` works; `0` otherwise. Never raises. |

### Array shapes

**Request (`req`)** — caller-built before `request`:

```
req("method")             ; "GET" / "POST" / "PUT" / ...
req("url")                ; full absolute URL
req("header", name)       ; header value; name as-given (case preserved)
req("body")               ; request body bytes
req("timeout")            ; seconds; default 30
req("followRedirects")    ; 0/1; default 1
req("verifyTls")          ; 0/1; default 1
```

**Response (`resp`)** — populated by `request` / `get` / `post`:

```
resp("status")            ; numeric status code (200, 404, ...) or "" on error
resp("reason")            ; reason phrase ("OK", "Not Found", ...)
resp("version")           ; "HTTP/1.1"
resp("header", lowerName) ; header value (name lowercased for lookup)
resp("body")              ; response body bytes
resp("error")             ; "" on success; libcurl error string otherwise
```

Header lookup is case-insensitive: keys are lowercased on insertion so
`resp("header","content-type")` works regardless of what the server
sent. The original casing is not preserved (server casing is not
semantically significant per RFC 7230 §3.2).

## Examples

```m
; iteration 1 — parse a captured response
new resp,raw
set raw="HTTP/1.1 200 OK"_$char(13,10)
set raw=raw_"Content-Type: text/plain"_$char(13,10)
set raw=raw_"Content-Length: 5"_$char(13,10,13,10)
set raw=raw_"hello"
do parseResponse^STDHTTP(raw,.resp)
write resp("status"),!                       ; 200
write resp("header","content-type"),!        ; "text/plain"
write resp("body"),!                         ; "hello"

; iteration 1 — build a request line + header block
new req
set req("method")="GET"
set req("url")="https://example.com/api/v1/things?x=1"
set req("header","Accept")="application/json"
write $$buildRequest^STDHTTP(.req)
; GET /api/v1/things?x=1 HTTP/1.1
; Host: example.com
; Accept: application/json
; (blank line)
```

```m
; iteration 2 — convenience GET
new resp
if '$$available^STDHTTP() do  quit  ; degrade gracefully if SO missing
. write "http callout unavailable; skipping fetch",!
if '$$get^STDHTTP("https://example.com/health",.resp) do
. write "fetch failed: ",resp("error"),!
. quit
write resp("status")," ",resp("reason"),!
write resp("body"),!
```

## Dependencies

- **STDURL** (`v0.2.0`) — `parse^STDURL` extracts host/path/port for
  request-line and Host-header construction.
- **`tools/build-callouts.sh`** — compiles `src/callouts/http.c`
  into `so/<platform>/http.so`.
- **libcurl** — runtime dep on iteration 2; the M side soft-fails
  with `resp("error")="STDHTTP-NOT-WIRED"` when the SO is missing
  rather than aborting. `$$available^STDHTTP()` is the cheap probe.

## Edge cases

- **CRLF tolerance.** `parseResponse` accepts both bare LF and CRLF
  for line endings; emit-side `buildRequest` and `formatHeaders`
  always use CRLF (RFC 7230 §3 requires CRLF for compliant servers).
- **Status without reason.** `"HTTP/1.1 204"` (no reason phrase) is
  accepted; `s("reason")` becomes `""`. RFC 7230 §3.1.2 allows this.
- **Multiple headers with same name.** Joined with `", "` per RFC
  7230 §3.2.2 — `Set-Cookie` is the documented exception, but for v1
  STDHTTP applies the comma-join rule uniformly. `Set-Cookie` parsing
  belongs in a future `STDCOOKIE` module.
- **Body byte semantics.** Bodies are M strings of bytes (0..255 via
  `$ASCII` / `$CHAR`); STDHTTP performs no transcoding. Callers
  decode as appropriate.
- **No transfer-decoding by `parseResponse`.** It returns the body as
  the server sent it. `Transfer-Encoding: chunked` is handled inside
  libcurl in iteration 2 — by the time the body reaches `$$request`
  via the callout it has already been de-chunked.
- **Redirect headers.** When `req("followRedirects")=1` (default),
  libcurl emits the headers from every response in the redirect chain
  to the M side. `$$request` keeps only the **final** response's
  status line + header block (split on `\r\n\r\n`, take the last
  non-empty piece) — intermediate 3xx responses are not surfaced.
- **Output budgets.** Response headers and body are each captured into
  a 1 MiB pre-allocated buffer; oversize responses are silently
  truncated by the C-side capture callback. Callers needing exact-size
  enforcement should validate `Content-Length` themselves.
- **`$$buildRequest` does not encode the URL.** It uses the URL as
  given. Callers needing percent-encoding apply `STDURL.encode` first.

## Errors

Pure-M helpers do not set `$ECODE`. Malformed input degrades to a
flag in the output array (`s("ok")=0`, etc.) so callers can branch
without `$ETRAP`. The libcurl callout (iteration 2) translates curl
error codes into `resp("error")` strings; `$ECODE` stays clean.

## See also

- [`STDURL`](stdurl.md) — RFC 3986 URL parser; consumed by
  `buildRequest` for `Host:` synthesis.
- [`STDB64`](stdb64.md) — Base64 (used for `Authorization: Basic`
  headers).
- `STDCRYPTO` (H1, queued) — paired with STDHTTP via the
  `examples/jwt-verify.m` end-to-end Phase 3 demo.
