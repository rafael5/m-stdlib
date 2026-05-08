---
module: STDURL
tag: v0.2.0
phase: Phase 2
stable: stable
since: v0.2.0
synopsis: 'RFC 3986 URI parser, builder, encoder, resolver'
labels: ['build', 'decode', 'encode', 'normalize', 'parse', 'resolve', 'valid']
errors: []
conformance: ['tests/conformance/url/']
see_also: ['STDHTTP']
---

# `STDURL` — RFC 3986 URI parser, builder, encoder, resolver

URL splitting / re-assembly, percent-encoding, validation, syntactic
normalisation, and relative-reference resolution per
[RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986). Pure-M; no
host-call. The downstream consumer is `STDHTTP` in Phase 3.

## Public API

| Extrinsic / Procedure | Signature | Behaviour |
|---|---|---|
| `parse` | `do parse^STDURL(url,.parts)` | Splits `url` into `parts(scheme/userinfo/host/port/path/query/fragment)`. Kills `parts` first; writes every key (empty when absent). |
| `build` | `$$build^STDURL(.parts)` | Re-assembles a URL from `parts`. Emits authority (`//user@host:port`) iff any of userinfo / host / port is non-empty. |
| `encode` | `$$encode^STDURL(s,safe)` | Percent-encodes `s`. The unreserved set (RFC 3986 §2.3) plus any chars listed in `safe` pass through; everything else becomes `%HH`. Space → `%20`. |
| `decode` | `$$decode^STDURL(s)` | Percent-decodes every valid `%HH`. Lenient — malformed `%` sequences (e.g. `%2`, `%2G`, bare `%`) pass through as literal text (Python `urllib.parse.unquote` semantics). |
| `valid` | `$$valid^STDURL(url)` | `1` iff `url` is a well-formed RFC 3986 URI (or relative reference). Strict: rejects raw spaces, control characters, and malformed `%HH`. Use this if strict input is required. |
| `normalize` | `$$normalize^STDURL(url)` | Applies RFC 3986 §6.2 syntax-based normalisation: lowercases scheme + host, uppercases hex digits in `%HH`, percent-decodes unreserved characters, removes `.` and `..` dot-segments. |
| `resolve` | `$$resolve^STDURL(base,ref)` | Resolves `ref` against `base` per RFC 3986 §5.3 (strict mode). Returns the absolute URI string. |

`parse` is a procedure (no return value); `build` / `encode` / `decode`
/ `valid` / `normalize` / `resolve` are extrinsics.

## Examples

```m
; round-trip a full URL
new parts
do parse^STDURL("https://u:p@h.example:8443/a/b?c=d#e",.parts)
write parts("scheme"),!     ; "https"
write parts("userinfo"),!   ; "u:p"
write parts("host"),!       ; "h.example"
write parts("port"),!       ; "8443"
write parts("path"),!       ; "/a/b"
write parts("query"),!      ; "c=d"
write parts("fragment"),!   ; "e"
write $$build^STDURL(.parts),!     ; "https://u:p@h.example:8443/a/b?c=d#e"

; percent-encoding
write $$encode^STDURL("hello world",""),!         ; "hello%20world"
write $$encode^STDURL("/a/b","/"),!               ; "/a/b"  — slash kept
write $$decode^STDURL("hello%20world"),!          ; "hello world"
write $$decode^STDURL("%2G"),!                    ; "%2G"   — lenient

; validation
write $$valid^STDURL("/path"),!                   ; 1
write $$valid^STDURL("http://x/with space"),!     ; 0

; normalisation
write $$normalize^STDURL("HTTPS://EX.COM/a/./b"),!   ; "https://ex.com/a/b"

; relative-reference resolution (RFC 3986 §5.4.1)
write $$resolve^STDURL("http://a/b/c/d;p?q","../g"),!   ; "http://a/b/g"
write $$resolve^STDURL("http://a/b/c/d;p?q","//g"),!    ; "http://g"
write $$resolve^STDURL("http://a/b/c/d;p?q","?y"),!     ; "http://a/b/c/d;p?y"
```

## Components and the parts array

`parse` always writes seven keys; absent components are `""`. The
contract lets callers index without `$get`:

```
parts("scheme")     parts("userinfo")   parts("host")
parts("port")       parts("path")       parts("query")
parts("fragment")
```

`build` emits the authority sentinel `//` only when at least one of
userinfo / host / port is non-empty. The empty-authority form
`file:///path` is therefore not preserved across parse → build (it
becomes `file:/path`); arrange explicit string handling at the
boundary if the empty-authority distinction matters.

## Edge cases

- **Empty input.** `parse("",.parts)` clears `parts` and writes all
  seven keys as `""`. `valid("")` returns `1` (empty is a degenerate
  same-document reference per RFC 3986 §4.2). `decode("")` and
  `encode("")` return `""`.
- **Lenient decode vs. strict valid.** `decode("%2G")` returns the
  literal three characters `%2G`; `valid("%2G")` returns `0`. This
  split matches `urllib.parse.unquote` (lenient) + a separate
  predicate, and avoids forcing `decode` callers into error handling
  for ill-formed input.
- **`+` is literal.** `decode("a+b")` returns `"a+b"`. The `+`-as-space
  rule is `application/x-www-form-urlencoded`, not RFC 3986 percent-
  encoding; that translation belongs in a future `STDFORM` module
  (or in caller code that knows it is parsing form bodies).
- **IPv6 hosts.** `[::1]:8080` parses into `host="[::1]"` (brackets
  preserved) and `port="8080"`. `build` re-emits the brackets.
- **Strict resolve.** `resolve("http://a/b/c/","http:g")` returns
  `"http:g"` (RFC 3986 §5.3 strict — same scheme is *not* inherited).
  The non-strict back-compat behaviour from RFC 2396 (drop the leading
  scheme when it matches the base) is intentionally not implemented.
- **`//` without scheme.** `parse("//host/path",.parts)` correctly
  populates host and path even when no scheme is present (a network-
  path reference, RFC 3986 §4.2).
- **Byte semantics.** Input is treated as a string of bytes (one M
  character per byte, values 0..255 via `$ASCII` / `$CHAR`). For
  non-ASCII characters, callers should percent-encode UTF-8 bytes
  before passing to `encode` (RFC 3986 §2.5).

## Conformance

The module is tested against the RFC 3986 §5.4 reference-resolution
table, vendored at
[`tests/conformance/url/rfc3986-section-5.4.1-normal.tsv`](../../tests/conformance/url/rfc3986-section-5.4.1-normal.tsv)
and
[`tests/conformance/url/rfc3986-section-5.4.2-abnormal.tsv`](../../tests/conformance/url/rfc3986-section-5.4.2-abnormal.tsv)
(23 normal + 19 abnormal cases). Round-trip property tests cover
parse → build for canonical URLs and encode → decode for printable
strings.

## Errors

`STDURL` does not set `$ECODE`. Validation lives in `valid()`;
parsing and decoding are deliberately permissive so the module
composes cleanly with caller-side validation pipelines.

## See also

- [`STDB64`](stdb64.md) — Base64 (used by JWT producers alongside URL
  encoding).
- `STDHTTP` (Phase 3) — HTTP/1.1 + HTTPS client; consumes
  `parse` / `build` to assemble request lines and `Host` headers.
