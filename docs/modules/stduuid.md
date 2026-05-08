---
module: STDUUID
tag: v0.0.1
phase: Phase 1
stable: stable
since: v0.0.1
synopsis: 'UUID v4 + v7 (RFC 4122 / RFC 9562)'
labels: ['v4', 'v7', 'valid', 'variant', 'version']
errors: []
conformance: ['tests/conformance/uuid/']
see_also: ['STDCSPRNG']
---

# `STDUUID` — UUID v4 + v7

RFC-4122 / RFC-9562 compliant UUID generator. Two formats:

- **v4** — 122 random bits. Stateless; collision-resistant for
  reasonable cardinalities. Use for ids that don't need to sort.
- **v7** — 48-bit ms-since-Unix-epoch prefix + 74 random bits.
  Sortable; lexicographic order = generation order. Use for ids
  that act as primary keys, log correlation tokens, or anything
  benefitting from time-ordered insertion.

Output is always **lowercase hex** in the canonical
`xxxxxxxx-xxxx-Vxxx-Yxxx-xxxxxxxxxxxx` form (36 chars including
hyphens), per RFC-9562 §4.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `v4` | `$$v4^STDUUID()` | A new random UUID v4. |
| `v7` | `$$v7^STDUUID()` | A new time-ordered UUID v7. |
| `valid` | `$$valid^STDUUID(u)` | `1` iff `u` is canonical 36-char hex (lower or upper). |
| `version` | `$$version^STDUUID(u)` | Integer version 1..15 from position 15, or `""` if invalid. |
| `variant` | `$$variant^STDUUID(u)` | `"ncs"` / `"rfc4122"` / `"microsoft"` / `"future"` / `""`. |

## Examples

```m
; mint a v4
SET id=$$v4^STDUUID()           ; e.g. "550e8400-e29b-41d4-a716-446655440000"

; mint a v7 (sortable)
SET id=$$v7^STDUUID()           ; e.g. "0193abcd-1234-7000-8000-000000000000"

; validate
WRITE $$valid^STDUUID(id),!     ; 1

; introspect
WRITE $$version^STDUUID(id),!   ; 4 (or 7)
WRITE $$variant^STDUUID(id),!   ; "rfc4122"
```

## Random source

`$RANDOM` (Mersenne Twister). **Not cryptographically strong.**

- ✅ Distributed primary keys, log correlation, request IDs.
- ❌ Session tokens, password reset tokens, signed JWTs, anything
  whose unpredictability is a security boundary. Use `STDCRYPTO`
  (Phase 3) for those.

## Time source (v7)

`$ZHOROLOG` on YottaDB → `(days_since_1840-12-31, seconds_into_day,
microseconds_into_second, tz_offset_seconds)`. The day-zero offset to
1970-01-01 is exactly **47117** days. v7 millisecond timestamp:

```
ms = (days - 47117) * 86_400_000 + seconds * 1000 + (microseconds \ 1000)
```

The first 48 bits (12 hex chars) of the UUID encode this `ms` value.
Two v7s minted in different milliseconds **always** sort correctly:

```m
SET u1=$$v7^STDUUID()
HANG 0.005
SET u2=$$v7^STDUUID()
WRITE u2]u1,!                    ; 1 — use ] (string collation), not <
```

`<` does numeric comparison (which reduces UUIDs to their leading-
digit prefix and returns `0` for any two UUIDs starting with the same
digit). Always use `]` for UUID ordering.

## Edge cases

- **`valid` accepts both cases.** `$$valid^STDUUID("550E8400-E29B-...")`
  returns `1` even though `v4`/`v7` always emit lowercase. Use `valid`
  as the boundary check; downstream code can lowercase via
  `$ZCONVERT(u,"L")` or `$TRANSLATE(u,"ABCDEF","abcdef")`.
- **`version` of versions 8-15.** RFC-9562 reserves versions 8-15 for
  future use. `version` returns the integer 8..15 if the nibble is
  `8`-`f`; the responsibility for "is this RFC-defined?" rests with
  the caller.
- **`variant` for invalid input.** Returns `""`, not throwing, to
  match `version`'s convention.
- **v4 same-millisecond collisions.** With 122 random bits,
  birthday-paradox collision probability passes 50% only at ~2^61
  draws. The test suite ([`tests/STDUUIDTST.m:tV4UniqueAcross200Samples`](../../tests/STDUUIDTST.m))
  asserts no collisions across 200 draws — comfortably below 1-in-2^57
  collision probability.
- **v7 same-millisecond ordering.** When two v7s are minted in the
  same millisecond, the first 48 bits are identical and the remaining
  random bits decide order. There's no monotonic counter (RFC-9562
  Method 1); two v7s in the same ms can sort either way relative to
  each other. If strict per-process monotonicity matters, layer a
  process-local counter on top — out of scope for v0.0.1.

## Error codes

`STDUUID` doesn't set `$ECODE`. Invalid inputs return `""` (for
`version`/`variant`) or `0` (for `valid`).

## Engine portability

Currently YDB-only — `$ZHOROLOG` is a YDB extension. An IRIS arm
using `$ZTIMESTAMP` lands when [`STDDATE`](../plans/m-stdlib-implementation-plan.md#87-stddate--iso-8601-datetime)
ships in v0.0.5; until then, IRIS users get a `M-MOD-022` lint
warning at the `unixMs` helper (suppressed inline with a directive).

## See also

- [`STDASSERT`](stdassert.md) — every test in `STDUUIDTST` is one
  STDASSERT call.
- RFC-4122 — original UUID spec.
- RFC-9562 — UUID v6/v7/v8.
- Implementation plan §8.2 — the API spec.
