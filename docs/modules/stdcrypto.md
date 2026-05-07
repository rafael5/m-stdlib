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
M side                      C side                  OpenSSL
──────                      ──────                  ───────
$$sha256^STDCRYPTO(data)    crypto_sha256()         EVP_DigestInit_ex(EVP_sha256())
       │                           │                EVP_DigestUpdate(in)
       │   $&std_crypto.           │                EVP_DigestFinal_ex(out)
       └─→  crypto_sha256(data,    │
            .out)            ─────→│                returns 32 bytes
                                   │
       ←──────────────────  out (32 bytes) ←─────────
       │
       └─→ $$encode^STDHEX(out)  →  hex digest
```

- M-side `$&std_crypto.crypto_sha256` invokes the C function via the
  YDB external-call mechanism.
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
export ydb_xc_std_crypto="$PWD/tools/std_crypto.xc"

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

For the test suite (`make test`) to run green, the **vista-meta YDB
container** needs the same wiring inside it:

1. The container image must include `libcrypto.so.3` (or `.so.1.1`) at
   load time. Modern Debian/Ubuntu base images already do; the
   `ydb-perl-plugin` package has it as a transitive dependency.
2. `scripts/seed-vista.sh` must scp `so/<plat>/std_crypto.so` and
   `tools/std_crypto.xc` into the container alongside the routines.
3. The container's YDB session must `export ydb_xc_std_crypto=...` and
   `STDLIB_LIB=...` before `m test` invokes the suite.

Steps 2 and 3 are the open work tracked at **T28 — engine-bound
deployment for STDCRYPTO** in `docs/module-tracker.md`. Until it
lands, `STDCRYPTOTST.m` runs RED on the engine — every test fails
under `,U-STDCRYPTO-CALLOUT-MISSING,`. Local hosts with
`STDLIB_LIB` + `ydb_xc_std_crypto` exported can run the suite green
today, given libssl-dev and YottaDB headers.

## Error handling

| Code | When it fires |
|---|---|
| `,U-STDCRYPTO-CALLOUT-MISSING,` | The `std_crypto` callout package isn't loaded — env var unset, .so missing, or symbol unresolvable. `available()` returns `0` in this state. |
| `,U-STDCRYPTO-DIGEST-FAIL,` | OpenSSL's `EVP_Digest*` call returned non-zero (rare; typically only on memory pressure). |
| `,U-STDCRYPTO-HMAC-FAIL,` | OpenSSL's `HMAC()` returned `NULL` (same rarity profile). |
| `,U-STDCRYPTO-BAD-SYMBOL,` | Internal-only — the symbol-dispatch helper got a name it doesn't recognise. Indicates a bug in this module, not the caller. |

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
