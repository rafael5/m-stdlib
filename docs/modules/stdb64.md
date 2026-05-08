---
module: STDB64
tag: v0.0.2
phase: Phase 1
stable: stable
since: v0.0.2
synopsis: 'RFC-4648 Base64 (standard + URL-safe)'
labels: ['decode', 'encode', 'urldecode', 'urlencode', 'valid']
errors: []
conformance: ['tests/conformance/b64/']
see_also: ['STDCSPRNG']
---

# `STDB64` — RFC-4648 Base64

Base64 encoding and decoding for the standard alphabet (RFC-4648 §4)
and the URL-safe alphabet (RFC-4648 §5). Pure-M; no host-call.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `encode` | `$$encode^STDB64(data)` | Base64 text using the standard alphabet (`+ /`), with `=` padding. |
| `decode` | `$$decode^STDB64(text)` | The bytes encoded by `encode()`. |
| `urlencode` | `$$urlencode^STDB64(data)` | URL-safe Base64 (`- _`), no padding (RFC-4648 §5; JWT convention). |
| `urldecode` | `$$urldecode^STDB64(text)` | The bytes encoded by `urlencode()`. Padding is optional. |
| `valid` | `$$valid^STDB64(text)` | `1` iff `text` is well-formed standard Base64 (with padding). |

All extrinsics return the empty string on empty input. `encode` and
`urlencode` accept any byte string; `decode`, `urldecode`, and
`valid` accept text from the corresponding alphabet.

## Examples

```m
; round-trip ASCII
WRITE $$encode^STDB64("foobar"),!     ; "Zm9vYmFy"
WRITE $$decode^STDB64("Zm9vYmFy"),!   ; "foobar"

; padding cases
WRITE $$encode^STDB64("f"),!          ; "Zg=="
WRITE $$encode^STDB64("fo"),!         ; "Zm8="
WRITE $$encode^STDB64("foo"),!        ; "Zm9v"

; URL-safe (no padding, '-' and '_' instead of '+' and '/')
WRITE $$urlencode^STDB64("f"),!       ; "Zg"
WRITE $$urldecode^STDB64("Zg"),!      ; "f"
WRITE $$urldecode^STDB64("Zg=="),!    ; "f"  — trailing '=' is tolerated

; predicate
WRITE $$valid^STDB64("Zm9vYmFy"),!    ; 1
WRITE $$valid^STDB64("Zg!="),!        ; 0  — '!' is not in the alphabet
WRITE $$valid^STDB64("Zm9"),!         ; 0  — length not a multiple of 4
```

## Algorithm

Take three input bytes (24 bits) at a time, split into four 6-bit
groups, map each via the 64-character alphabet. When the input length
is not a multiple of three, emit `=` padding for the trailing group
(standard alphabet) or omit padding entirely (URL-safe alphabet).

## Edge cases

- **Empty input.** All five extrinsics handle `""` cleanly: `encode`
  and `urlencode` return `""`; `decode` and `urldecode` return `""`;
  `valid("")` returns `1`.
- **Cross-alphabet rejection.** `valid` rejects URL-safe characters
  (`-` `_`) — they are not in the standard alphabet. To validate
  URL-safe text, use `urldecode` with a length check (or wait for a
  future `validurl` if demand arises).
- **Misplaced padding.** `valid` requires `=` to appear only at the
  end of the string and only as one or two characters. `Z=g=`,
  `====`, and similar are rejected.
- **Tolerant decode.** `decode` and `urldecode` are intentionally
  permissive on input lengths that are not multiples of four; the
  trailing partial group is dropped. Use `valid` first if strict
  validation is required.
- **Byte semantics.** Input is treated as a string of bytes (one M
  character per byte, values 0..255 via `$ASCII` / `$CHAR`). On
  YottaDB UTF-8 mode, multi-byte UTF-8 characters round-trip
  correctly when both producer and consumer treat the string as
  M-characters. Always-byte semantics (regardless of `$ZCHSET`)
  arrive with `STDCRYPTO` in Phase 3 via `$ZCHAR` / `$ZASCII`.

## Conformance

The module is tested against the RFC-4648 §10 vectors, vendored at
[`tests/conformance/b64/rfc4648-section-10.tsv`](../../tests/conformance/b64/rfc4648-section-10.tsv)
and the URL-safe derivation
[`tests/conformance/b64/rfc4648-section-10-urlsafe.tsv`](../../tests/conformance/b64/rfc4648-section-10-urlsafe.tsv).
Round-trip property tests over random byte strings (lengths 1, 7, 16,
32, 100, 255) and over `$CHAR(1..127)` exercise every padding case
and the printable-byte range.

## Why no `validurl`?

The most common URL-safe consumers — JWT, OAuth tokens, file IDs in
URLs — accept both padded and unpadded forms by convention. A strict
URL-safe predicate is easy to write but rarely useful at the boundary;
producers tend to be lenient. If a future caller demands it,
`$$validurl^STDB64(text)` is a 5-line addition.

## See also

- [`STDHEX`](stdhex.md) for hex encoding (case-insensitive decode).
- `STDCRYPTO` (Phase 3) for byte-safe always-binary handling and for
  consumers like `jwt-verify` that combine Base64-URL with crypto.
