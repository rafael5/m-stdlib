---
module: STDCRYPTO
tag: v0.4.0
phase: Phase 3 + post-P4 wave
stable: stable
since: v0.4.0
synopsis: 'Cryptographic digests via $&stdcrypto → libcrypto'
labels: ['available', 'hmacSha256', 'hmacSha256Bytes', 'hmacSha384', 'hmacSha384Bytes', 'hmacSha512', 'hmacSha512Bytes', 'sha256', 'sha256Bytes', 'sha384', 'sha384Bytes', 'sha512', 'sha512Bytes']
errors: ['U-STDCRYPTO-CALLOUT-MISSING', 'U-STDCRYPTO-DIGEST-FAIL', 'U-STDCRYPTO-HMAC-FAIL']
conformance: []
see_also: []
---

# `STDCRYPTO` — Cryptographic digests + HMAC

SHA-2 digest family and HMAC-SHA-2 message authentication, bound via
`$ZF` to OpenSSL's libcrypto. Phase 3 — first m-stdlib module to
exercise the call-out harness shipped at A6.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `sha256` | `$$sha256^STDCRYPTO(data)` | 64-char lowercase hex SHA-256 digest. |
| `sha384` | `$$sha384^STDCRYPTO(data)` | 96-char lowercase hex SHA-384 digest. |
| `sha512` | `$$sha512^STDCRYPTO(data)` | 128-char lowercase hex SHA-512 digest. |
| `sha256Bytes` | `$$sha256Bytes^STDCRYPTO(data)` | 32 raw bytes. |
| `sha384Bytes` | `$$sha384Bytes^STDCRYPTO(data)` | 48 raw bytes. |
| `sha512Bytes` | `$$sha512Bytes^STDCRYPTO(data)` | 64 raw bytes. |
| `hmacSha256` | `$$hmacSha256^STDCRYPTO(key,msg)` | 64-char lowercase hex HMAC-SHA-256. |
| `hmacSha384` | `$$hmacSha384^STDCRYPTO(key,msg)` | 96-char lowercase hex HMAC-SHA-384. |
| `hmacSha512` | `$$hmacSha512^STDCRYPTO(key,msg)` | 128-char lowercase hex HMAC-SHA-512. |
| `hmacSha256Bytes` | `$$hmacSha256Bytes^STDCRYPTO(key,msg)` | 32 raw bytes. |
| `hmacSha384Bytes` | `$$hmacSha384Bytes^STDCRYPTO(key,msg)` | 48 raw bytes. |
| `hmacSha512Bytes` | `$$hmacSha512Bytes^STDCRYPTO(key,msg)` | 64 raw bytes. |
| `available` | `$$available^STDCRYPTO()` | `1` iff the `std_crypto` callout package is loaded and resolves; else `0`. Never raises. |

`data`, `key`, and `msg` are byte strings (one M character per byte —
values 0..255). Empty inputs are valid for every entry point and
produce the well-known empty-input digests / MACs.

## Examples

```m
; SHA-256 of a string
WRITE $$sha256^STDCRYPTO("abc")
; ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad

; HMAC-SHA-256 with a string key (RFC 4231 §4.3 vector)
WRITE $$hmacSha256^STDCRYPTO("Jefe","what do ya want for nothing?")
; 5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843

; Pre-flight guard
IF '$$available^STDCRYPTO() SET $ECODE=",U-MYAPP-NO-CRYPTO,"

; Raw-bytes form for layering on top
SET digest=$$sha256Bytes^STDCRYPTO(payload)
SET digestB64=$$urlencode^STDB64(digest)
```

## Conformance

| Vector | Source |
|---|---|
| SHA-256, SHA-384, SHA-512 known-input digests | FIPS 180-4 §B (the `"abc"` vector et al.) — replicated in `tests/STDCRYPTOTST.m`. |
| HMAC-SHA-256 / HMAC-SHA-384 / HMAC-SHA-512 | RFC 4231 §4.2 / §4.3 test cases. |

The `tests/STDCRYPTOTST.m` suite exercises both the digest-of-empty
and digest-of-fixed-string paths for each algorithm, plus three HMAC
edge cases: empty key, key-longer-than-block, and the canonical RFC
4231 vectors.

## Architecture

```
M side                              C side                 OpenSSL
──────                              ──────                 ───────
$$sha256^STDCRYPTO(data)            crypto_sha256(         EVP_DigestInit_ex(EVP_sha256())
       │                              int argc,            EVP_DigestUpdate(in)
       │  XECUTE "set rc=             ydb_string_t* in,    EVP_DigestFinal_ex(out)
       │   $&stdcrypto.sha256(        ydb_string_t* out)
       │     inp,.out)"              ────→                 returns 32 bytes
       │                                       ←─ out (32 bytes) ─
       │
       └─→ $$encode^STDHEX(out)  →  hex digest
```

- M-side calls go through `dispatch3` / `dispatch4` helpers that
  build the `set rc=$&stdcrypto.<fn>(...)` command as a string and
  `XECUTE` it. The string-literal indirection serves two purposes:
  (a) sidesteps the open tree-sitter-m grammar gap for the
  `$&pkg.fn` package-prefixed external-call form; (b) sidesteps a
  pre-existing `m fmt` longest-prefix abbreviation bug. The runtime
  semantics are identical to a direct `$&` call — only the source
  spelling differs.
- **YottaDB ABI note — argc-prefixed C signatures.** YDB's
  `$&pkg.fn(args)` external-call ABI prepends an `int argc` to every
  C entry point. So although `tools/std_crypto.xc` describes the
  user-visible signature as
  `crypto_sha256(I:ydb_string_t*, O:ydb_string_t*[64])`, the real C
  function is `int crypto_sha256(int argc, ydb_string_t* in,
  ydb_string_t* out)` and bails with `-5` on a wrong argc. (The
  legacy `$ZF` + `ydb_ci` form was abandoned because YDB r2.02's M
  parser rejects the `.var` byref-output syntax for `$ZF` —
  `$&pkg.fn` is the only form that supports `O:ydb_string_t*[N]`
  output args.)
- The C side uses OpenSSL's EVP interface (`EVP_DigestInit_ex` /
  `EVP_DigestUpdate` / `EVP_DigestFinal_ex`) and `HMAC()` from
  `<openssl/hmac.h>`.
- Output is raw bytes; the M side hex-encodes via
  `$$encode^STDHEX` for the convenience extrinsics.

The `Bytes`-suffixed extrinsics expose the raw digest for callers
that feed the result into another binary pipeline (TLS handshakes,
JWS signature payloads, file-integrity manifests).

## Deployment runbook

STDCRYPTO is the first m-stdlib module that requires a compiled
shared object. Three steps to bring it online:

```bash
# 1. Build the .so for the host platform.
cd ~/projects/m-stdlib
tools/build-callouts.sh                         # produces so/<plat>/std_crypto.so
                                                # requires: gcc/clang, libssl-dev,
                                                # YottaDB headers ($ydb_dist)

# 2. Point YottaDB at the call-out descriptor.
export STDLIB_LIB="$PWD/so/$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
export ydb_xc_stdcrypto="$PWD/tools/std_crypto.xc"
# YDB package names must be alphanumeric, so the env-var name strips
# the underscore: std_crypto.xc → ydb_xc_stdcrypto → $&stdcrypto.<fn>().

# 3. Verify.
ydb -run %XCMD 'write $$available^STDCRYPTO(),!'
# 1
ydb -run %XCMD 'write $$sha256^STDCRYPTO("abc"),!'
# ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
```

The `tools/std_crypto.xc` descriptor's first line is
`$STDLIB_LIB/std_crypto.so` — YottaDB resolves `$STDLIB_LIB` from
the environment at load time, so the .xc file is portable across
hosts (you set `STDLIB_LIB` per-host).

## Engine-bound testing — `m test`

`scripts/seed-callouts.sh` (invoked automatically by
`scripts/seed-vista.sh` whenever `src/callouts/*.c` is present) handles
the engine-bound wiring end-to-end:

1. Pushes every `src/callouts/*.c` into the vista-meta container and
   compiles it there against the runtime YDB headers, so the resulting
   ABI matches the YDB session that loads it.
2. Stages the .so files under `~/export/seed/m-stdlib/lib/<plat>/` and
   the `tools/std_*.xc` descriptors under `~/export/seed/m-stdlib/xc/`
   inside the container.
3. Idempotently injects a labelled marker block into
   `/etc/profile.d/ydb_env.sh` (via passwordless sudo) that exports
   `STDLIB_LIB` and one `ydb_xc_<pkg>` per descriptor. The package name
   strips non-alphanumerics from the .xc base, so `std_crypto.xc`
   becomes `ydb_xc_stdcrypto`. Re-runs replace the prior block in
   place; deleting the block between the markers is a clean uninstall.

The container image must already include `libcrypto.so.3` (or
`.so.1.1`) at load time. Modern Debian/Ubuntu base images do — the
`ydb-perl-plugin` package has it as a transitive dependency.

This closes **T28 — engine-bound deployment for STDCRYPTO** in
`docs/module-tracker.md`. The same machinery handles the STDCOMPRESS
and STDHTTP iter-2 callouts.

## Error handling

| Code | When it fires |
|---|---|
| `,U-STDCRYPTO-CALLOUT-MISSING,` | The `stdcrypto` callout package isn't loaded — env var unset, .so missing, or symbol unresolvable. `available()` returns `0` in this state. |
| `,U-STDCRYPTO-DIGEST-FAIL,` | OpenSSL's `EVP_Digest*` call returned non-zero (rare; typically only on memory pressure). |
| `,U-STDCRYPTO-HMAC-FAIL,` | OpenSSL's `HMAC()` returned `NULL` (same rarity profile). |
| `,U-STDCRYPTO-BAD-ALGO,` | Internal — `shaLen` got an algorithm name it doesn't recognise. Indicates a bug in this module, not the caller. |

All public extrinsics return the empty string when `$ECODE` is set,
matching STDCSPRNG / STDFMT / STDDATE convention.

## Why $ZF, not pure-M?

SHA-2 requires 32-bit / 64-bit modular arithmetic with bitwise
rotation, AND, OR, XOR. YottaDB's only native bitwise primitives
operate on **bitstrings** (`$ZBITAND` / `$ZBITOR` / `$ZBITXOR`),
which require conversion to and from numeric values per operation.
Pure-M SHA-256 is feasible but ~50× slower than libcrypto and adds
~400 lines of low-level word-twiddling. Phase 3 was always slated
to be the host-callout phase precisely so that primitives in this
class get the right backend.

A future pure-M fallback (for environments where compiled callouts
can't ship — IRIS plugin restrictions, KIDS-distributed VistA
packages) is queued but not on the active roadmap; the architectural
split is: **m-stdlib's pure-M phases (1, 1b, 2, 4) own ergonomics;
Phase 3 owns performance and correctness for primitives that need
it.**

## Out of scope at v1 (queued)

| Feature | Tracker T-N | Notes |
|---|---|---|
| AES-128/256-GCM encrypt / decrypt | T28-AES | Authenticated encryption — most common ask after digests. Same `.so`, two new entry points. |
| Ed25519 sign / verify | T28-Ed25519 | Public-key signatures for JWT EdDSA, file-integrity manifests. |
| X25519 key agreement | T28-X25519 | ECDH for session-key derivation. Pairs with Ed25519 for full DJB-suite. |
| Streaming digest API | T28-stream | `init` / `update` / `final` over a per-handle context — for files larger than M-string-friendly sizes. |
| SHA-1, MD5 | (deprecated) | Available in libcrypto; ship only if a real legacy-compatibility consumer asks. |
| SHA-3 / SHAKE | T28-sha3 | NIST FIPS 202. Lower priority than the SHA-2 family. |

The `H1` row in `docs/module-tracker.md` Table 1 covers v1's "SHA +
HMAC" footprint; T28 is the umbrella ticket for the post-v1
expansion.

## Reference

- FIPS 180-4 — *Secure Hash Standard*. https://csrc.nist.gov/publications/detail/fips/180/4/final
- RFC 2104 — *HMAC: Keyed-Hashing for Message Authentication*. https://datatracker.ietf.org/doc/html/rfc2104
- RFC 4231 — *Identifiers and Test Vectors for HMAC-SHA-224, HMAC-SHA-256, HMAC-SHA-384, and HMAC-SHA-512*. https://datatracker.ietf.org/doc/html/rfc4231
- RFC 6234 — *US Secure Hash Algorithms (SHA and SHA-based HMAC and HKDF)*. https://datatracker.ietf.org/doc/html/rfc6234
- OpenSSL EVP API — https://www.openssl.org/docs/man3.0/man7/crypto.html
- YottaDB external calls — https://docs.yottadb.com/ProgrammersGuide/extrout.html

## History

SHA-256/384/512 + HMAC-SHA-256/384/512 over OpenSSL libcrypto
(`EVP_DigestInit_ex` / `EVP_DigestUpdate` / `EVP_DigestFinal_ex` for
SHA, `HMAC()` for HMAC). C source at `src/callouts/std_crypto.c`;
descriptor at `tools/std_crypto.xc`.

Initial M-side (commit `9622bbe`) used direct `$ZF(name,...)` syntax
which `m fmt` mangles to `$zfind(...)` (longest-prefix-abbreviation
table bug — see [`discoveries.md`](../tracking/discoveries.md) row
2026-05-07 P2). Workaround landed at `acbaac6`: every $ZF call goes
through an XECUTE'd command-string wrapper (`dispatch3` / `dispatch4`
in src/STDCRYPTO.m) — fmt does not introspect string literals, so the
literal `$ZF` token survives to YDB's parser. Cost: extra helper layer
+ `m-lint: disable-file=M-MOD-036` for the intentional XECUTE. Same
pattern propagated to STDCOMPRESS / STDHTTP.

Engine green-run was T28's gating ticket. Engine reports as GT.M
V7.0-005 which rejects `.var` byref output for `$ZF`, forcing a second
migration: `dispatch3/dispatch4` switched from `$ZF("crypto_<fn>",...)`
to `$&stdcrypto.<fn>(...)` (namespaced call, accepts byref). C side
gained `int argc` prepended to every entry per the `$&pkg.fn` ABI with
arity-check short-circuit. T28 closed 2026-05-07 by
`scripts/seed-callouts.sh` (build-inside-container + idempotent
ydb_env.sh injection); STDCRYPTOTST 23/23 green; coverage 17/17 = 100%.

Six steps closed in the T28 evening session: (1) C-side argc fix;
(2) M-side dispatch rewrite from `$ZF` → `$&stdcrypto.<fn>`;
(3) descriptor LHS rename to alphanumeric (`crypto_sha256` →
`sha256`); (4) `seed-callouts.sh` strips non-alphanumerics from the
descriptor base when computing `ydb_xc_<pkg>` exports;
(5) `dispatch3`/`dispatch4` `$etrap` body returns `quit -1` (avoids
`%YDB-E-QUITARGREQD` in extrinsic frame); (6) `$etrap` propagation
flow stores `rc=-1` and the post-xecute chain still surfaces
`,U-STDCRYPTO-CALLOUT-MISSING,`.
