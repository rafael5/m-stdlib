---
module: STDCSPRNG
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'Cryptographic random (kernel CSPRNG via getrandom(2) | /dev/urandom)'
labels: ['available', 'base64', 'bytes', 'hex', 'int', 'token', 'useCallout', 'uuid4']
errors: ['U-STDCSPRNG-BAD-COUNT', 'U-STDCSPRNG-BAD-RANGE', 'U-STDCSPRNG-OPEN-FAIL']
conformance: []
see_also: ['STDB64', 'STDHEX', 'STDUUID']
created: 2026-05-07
last_modified: 2026-05-10
revisions: 6
doc_type: [REFERENCE]
---

# `STDCSPRNG` — Cryptographic random

Kernel-CSPRNG-backed random for security-sensitive identifiers:
session tokens, password reset tokens, JWT signing salts, nonces.
Distinct from [`STDUUID`](stduuid.md), which uses `$RANDOM`
(Mersenne Twister) and is fine for primary keys but **not** for
unpredictability boundaries.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `bytes` | `$$bytes^STDCSPRNG(n)` | n random bytes (string of length n; any byte 0..255). |
| `hex` | `$$hex^STDCSPRNG(n)` | 2n lowercase hex chars representing n random bytes. |
| `base64` | `$$base64^STDCSPRNG(n)` | URL-safe base64 (RFC-4648 §5) of n bytes; no `=` padding. |
| `token` | `$$token^STDCSPRNG(n)` | n-char token from `[A-Za-z0-9_-]` (6 bits / char). |
| `int` | `$$int^STDCSPRNG(min,max)` | Uniform integer in `[min, max]` (inclusive both ends), rejection-sampled. |
| `uuid4` | `$$uuid4^STDCSPRNG()` | RFC-4122 v4 UUID — 122 bits of CSPRNG entropy in canonical hex form. |
| `available` | `$$available^STDCSPRNG()` | `1` iff `/dev/urandom` is openable for reading; else `0`. |
| `useCallout` | `$$useCallout^STDCSPRNG()` | `1` iff the `cs_random` callout (`$ZF → getrandom(2)`) is loaded and resolves; else `0`. |

## Examples

```m
; 16 random bytes (binary)
SET buf=$$bytes^STDCSPRNG(16)

; 32-char hex token (16 bytes of entropy)
SET tok=$$hex^STDCSPRNG(16)

; URL-safe session token (~43 chars; 32 bytes / 256 bits of entropy)
SET sid=$$base64^STDCSPRNG(32)

; 22-char URL-safe token (132 bits of entropy — equivalent UUID strength)
SET tok=$$token^STDCSPRNG(22)

; Fair die roll
SET d=$$int^STDCSPRNG(1,6)

; Crypto-strong UUID v4 (use this, not $$v4^STDUUID, for security IDs)
SET id=$$uuid4^STDCSPRNG()

; Pre-flight guard
IF '$$available^STDCSPRNG() SET $ECODE=",U-MYAPP-NO-CSPRNG,"
```

## Entropy source

Linux kernel ChaCha20 CSPRNG. Two backends share the same pool, so
the choice is purely a perf concern — security guarantees are
identical:

| Backend | When picked | Cost / 16 bytes |
|---|---|---|
| `cs_random` (`$ZF → getrandom(2)`) | `ydb_xc_std_csprng` deployed and the .so resolves | one syscall, batched |
| `/dev/urandom` (`READ *b` loop) | otherwise (always-available soft-fall-back) | 16 device reads |

`bytes()` tries the callout first via `$$useCallout()` and falls
back to the device read on miss. Public API is identical across
both backends — callers never need to pick.

### Why one byte at a time on the device path

The device-read fall-back uses `READ *b` so that record terminators
in the byte stream (LF=`$C(10)`, CR=`$C(13)`) do not truncate the
read. This is correct but unhurried: a 16-byte UUID costs 16
device reads. For the call rates typical of session issuance
(≤ 10⁴ / s), this is well below the YDB engine's I/O ceiling. The
callout backend exists for environments where the per-byte
round-trip becomes a hot path.

### Deploying the callout

```bash
tools/build-callouts.sh                       # produces so/<plat>/cs_random.so
export STDLIB_LIB=<abs-path-to-so/<plat>>     # substituted into std_csprng.xc
export ydb_xc_std_csprng=<abs>/tools/std_csprng.xc
```

`$$useCallout^STDCSPRNG()` returns `1` once those three steps are
complete and the .so loads. With them unset, `bytes()` /
`hex()` / `base64()` / `token()` / `int()` / `uuid4()` all keep
working via `/dev/urandom` — the callout is a perf-only swap.

## Why not `$RANDOM`?

| Property | `$RANDOM` (STDUUID v4) | `STDCSPRNG` |
|---|---|---|
| Predictability of next output given prior outputs | Recoverable from ~624 samples (Mersenne Twister state extraction) | Computationally infeasible (kernel CSPRNG) |
| Suitable for distributed primary keys / log correlation | ✅ | ✅ |
| Suitable for session tokens, password reset tokens, JWT salts, nonces | ❌ | ✅ |
| Cost per byte | Cheap (in-process PRNG) | One device read per byte |

When in doubt, use `STDCSPRNG`. The performance cost is small enough
that defaulting to "secure" rarely matters in practice — and the
class of bugs avoided (predictable session tokens, guessable
password reset links, replayable nonces) is severe.

## `int(min, max)` distribution

Rejection sampling on the smallest power of 256 covering the range,
so the distribution is **unbiased** (no modulo-bias artefact). For
a range of size `R`:

1. Compute `nbytes` such that `256^nbytes ≥ R`.
2. Read `nbytes` random bytes; assemble as integer `r` in
   `[0, 256^nbytes - 1]`.
3. If `r ≥ accept = 256^nbytes - (256^nbytes mod R)`, redraw
   (probability `< R / 256^nbytes`, typically `< 1/256`).
4. Return `min + (r mod R)`.

Worst-case redraw rate: just under 50% (when `R` is just over a
power of 256). Expected reads per call: ~2 × `nbytes`.

Range is bounded by M scalar precision — YDB's exact-decimal
arithmetic carries 18 digits, comfortably accommodating any
practical range. For exact uniformity at spans larger than 2⁵³,
prefer composing `bytes()` directly.

## Edge cases

- **`bytes(0)` returns `""`.** Same for `hex(0)`, `base64(0)`,
  `token(0)`. No device read is performed. This matches the
  contract used across the v0.1.x string-builder modules.
- **Negative count → `$ECODE`.** `bytes(-1)`, `hex(-1)`,
  `base64(-1)`, `token(-1)` all set
  `$ECODE=",U-STDCSPRNG-BAD-COUNT,"` rather than silently returning
  `""`. Caller's bug, not data noise.
- **`int(n, n)` returns `n`.** Singleton ranges short-circuit
  without consuming entropy.
- **`int(max, min)` with `max < min`.** Sets
  `$ECODE=",U-STDCSPRNG-BAD-RANGE,"`. Asymmetric to `int(n, n)`
  by design — `min == max` is a valid degenerate range, `min > max`
  is a programmer error.
- **`uuid4` interop with `STDUUID`.** `$$valid^STDUUID(u)`,
  `$$version^STDUUID(u)`, and `$$variant^STDUUID(u)` all accept
  STDCSPRNG `uuid4()` output unchanged — same canonical form, same
  RFC-4122 variant nibble pattern, same lowercase hex.

## Error codes

| `$ECODE` | Raised by | Meaning |
|---|---|---|
| `,U-STDCSPRNG-BAD-COUNT,` | `bytes`, `hex`, `base64`, `token` | Negative `n` argument. |
| `,U-STDCSPRNG-BAD-RANGE,` | `int` | `max < min`. |
| `,U-STDCSPRNG-OPEN-FAIL,` | `bytes` (and indirectly `hex`/`base64`/`token`/`uuid4`/`int`) | `/dev/urandom` could not be opened — environment lacks the device, or process lacks read permission. Pre-flight with `$$available^STDCSPRNG()` to avoid mid-run. |

## Engine portability

YDB on Linux is the supported configuration. The `/dev/urandom`
contract (and CSPRNG semantics) is provided by every modern
Linux distribution; macOS provides it as well, with the same
ChaCha20-derived semantics. Windows YDB is not supported.

For IRIS, the public API is preserved by a drop-in replacement
that delegates to `%SYSTEM.Encryption` at the same labels — slated
for the IRIS-portability pass.

## See also

- [`STDUUID`](stduuid.md) — `$RANDOM`-backed UUID v4/v7. Use that
  for non-security IDs; this for security IDs.
- [`STDB64`](stdb64.md) — `urlencode` is the engine behind
  `STDCSPRNG.base64()`.
- [`STDHEX`](stdhex.md) — `encode` is the engine behind
  `STDCSPRNG.hex()` and `STDCSPRNG.uuid4()`.
- [`STDASSERT`](stdassert.md) — every test in `STDCSPRNGTST` is one
  STDASSERT call.
- RFC-4122 — UUID spec.
- RFC-4648 §5 — URL-safe base64.
- `getrandom(2)` Linux man page — kernel CSPRNG semantics.

## History

Original ship used a pure-M `/dev/urandom` `READ *b` loop (single-byte
reads to avoid record-terminator truncation; rejection-sampled over the
smallest power-of-256 ≥ range to dodge modulo bias). T12 (closed
2026-05-07) added the `$ZF → getrandom(2)` callout backend
(`src/callouts/cs_random.c`) for batch perf — `cs_random.so` loops over
`getrandom(2)` until `n` bytes filled with `EINTR` retry; M side gains
`$$useCallout^STDCSPRNG()` probe and an internal `dispatchRandom(n)`
XECUTE-wrapped `$ZF` call (the XECUTE wrap dodges the `$ZF` →
`$zfind` mangling that `m fmt`'s longest-prefix table introduces).
`$$bytes` tries the callout first, falls back to `/dev/urandom` on
miss — public API unchanged.

STDCSPRNGTST 406/406 green when the callout descriptor isn't deployed
(soft-fall-back path). Engine-deployed perf path verified separately
under T28's `seed-callouts.sh` harness; same kernel ChaCha20 pool
either way.
