# `STDHEX` — RFC-4648 §8 hex encoding

Hex (base-16) encoding and decoding. Lowercase by default;
case-insensitive on decode. Pure-M; no host-call.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `encode` | `$$encode^STDHEX(data)` | Lowercase hex (`0-9 a-f`) — RFC-4648 §8 default form. |
| `encodeu` | `$$encodeu^STDHEX(data)` | Uppercase hex (`0-9 A-F`) — for callers that need the alternate form. |
| `decode` | `$$decode^STDHEX(text)` | The bytes encoded by `encode` or `encodeu`. Accepts uppercase, lowercase, and mixed case. |
| `valid` | `$$valid^STDHEX(text)` | `1` iff `text` has even length and every character is `0-9` / `a-f` / `A-F`. Empty string is valid. |

`encode` and `encodeu` accept any byte string. `decode` and `valid`
accept text in any case.

## Examples

```m
; round-trip ASCII
WRITE $$encode^STDHEX("foobar"),!     ; "666f6f626172"
WRITE $$decode^STDHEX("666f6f626172"),!  ; "foobar"

; lowercase is the default
WRITE $$encode^STDHEX("foo"),!        ; "666f6f"
WRITE $$encodeu^STDHEX("foo"),!       ; "666F6F"

; decode is case-insensitive
WRITE $$decode^STDHEX("DeAdBeEf"),!   ; same 4 bytes as decode("deadbeef")

; predicate
WRITE $$valid^STDHEX("DeAdBeEf"),!    ; 1
WRITE $$valid^STDHEX("abc"),!         ; 0  — odd length
WRITE $$valid^STDHEX("g0"),!          ; 0  — non-hex character
```

## Algorithm

Each input byte splits into two 4-bit nibbles; each nibble maps to
one of `"0123456789abcdef"` (or the uppercase form for `encodeu`).
`decode` reverses the process after normalising the input to
lowercase via `$TRANSLATE`.

## Edge cases

- **Empty input.** All four extrinsics handle `""` cleanly: `encode`,
  `encodeu`, and `decode` return `""`; `valid("")` returns `1`.
- **Mixed case.** `decode` accepts any mix of `a-f` and `A-F` in the
  same input (`DeAdBeEf` decodes the same as `deadbeef` and
  `DEADBEEF`).
- **Tolerant decode.** Odd-length input drops the trailing nibble
  silently. Non-hex characters in input produce undefined byte values
  rather than an error. Use `valid` first if strict validation is
  required.
- **Lowercase by convention.** RFC-4648 §8 specifies a single
  16-character alphabet but is silent on case for the output. We
  follow the modern convention (Linux `xxd`, Python `binascii.hexlify`,
  Rust `hex` crate) of lowercase by default; uppercase is opt-in via
  `encodeu`.
- **Byte semantics.** Input is treated as a string of bytes (one M
  character per byte, values 0..255 via `$ASCII` / `$CHAR`).
  Always-byte semantics (regardless of `$ZCHSET`) arrive with
  `STDCRYPTO` in Phase 3 via `$ZCHAR` / `$ZASCII`.

## Conformance

The module is tested against:

- **Known vectors** — the same `"f"`, `"fo"`, `"foo"`, `"foob"`,
  `"fooba"`, `"foobar"` strings used for `STDB64` (their hex
  encodings are well-known: `66`, `666f`, `666f6f`, `666f6f62`,
  `666f6f6261`, `666f6f626172`).
- **Round-trip property** over random byte strings (lengths 1, 7, 16,
  32, 100, 255) and over `$CHAR(1..127)`.
- **Case round-trip** — `encode` output is exclusively lowercase
  letters, `encodeu` output is exclusively uppercase letters
  (verified across all 256 byte values via M pattern matching with
  pattern codes `L` and `U`).

## Why no `validu`?

`valid` already accepts both cases — there is no benefit to a
strict-uppercase or strict-lowercase predicate. If a future caller
needs to distinguish forms (e.g., to round-trip the exact original
casing), the check is a one-liner: `text=$$encode^STDHEX($$decode^STDHEX(text))`
for lowercase, or the equivalent with `encodeu` for uppercase.

## See also

- [`STDB64`](stdb64.md) for Base64 encoding (more compact, but
  alphabet is more complex).
- `STDCRYPTO` (Phase 3) for byte-safe always-binary handling and for
  consumers like checksum digests that pair hex with crypto.
