---
module: STDCOMPRESS
tag: v0.4.0
phase: Phase 3 + post-P4 wave
stable: stable
since: v0.4.0
synopsis: ""
labels: ['available', 'deflate', 'gunzip', 'gzip', 'inflate', 'zstdCompress', 'zstdDecompress']
errors: ['U-STDCOMPRESS-BAD-LEVEL', 'U-STDCOMPRESS-CALLOUT-MISSING', 'U-STDCOMPRESS-LIBZ-FAIL', 'U-STDCOMPRESS-LIBZSTD-FAIL']
conformance: []
see_also: []
---

# `STDCOMPRESS` — gzip / deflate / zstd compression

First Phase 3 (`$ZF`-bound) m-stdlib module. Wraps `libz` for the
RFC 1952 gzip format and the RFC 1951 raw deflate stream, and `libzstd`
for the zstd format. Pure-M wrappers do the byte-level glue; the
compress/decompress kernels execute in C via YDB external calls.

## Status

✅ **Shipped** — H2 track. Engine-verified 2026-05-08 via `make test`:
STDCOMPRESSTST 59/59 against the vista-meta YDB engine (T11 Phase 3
entry closed; T28 deployment closed; T30 `$ECODE` channel redesign
closed). See `docs/parallel-tracks.md` §3.5 (Phase 3) and
`docs/module-tracker.md` row H2.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `gzip` | `$$gzip^STDCOMPRESS(data, .out [, level])` | `1` on success, `0` on failure (see `$ECODE`). Writes gzip-framed bytes to `.out`. Default level `6`, range `1..9`. |
| `gunzip` | `$$gunzip^STDCOMPRESS(data, .out)` | `1` / `0`. Decompresses RFC 1952 gzip stream into `.out`. |
| `deflate` | `$$deflate^STDCOMPRESS(data, .out [, level])` | `1` / `0`. Raw RFC 1951 deflate stream (no header, no trailer). Default level `6`. |
| `inflate` | `$$inflate^STDCOMPRESS(data, .out)` | `1` / `0`. Decompresses raw RFC 1951 deflate. |
| `zstdCompress` | `$$zstdCompress^STDCOMPRESS(data, .out [, level])` | `1` / `0`. Zstandard frame. Default level `3`, range `1..22`. |
| `zstdDecompress` | `$$zstdDecompress^STDCOMPRESS(data, .out)` | `1` / `0`. Decompresses a zstd frame. |
| `available` | `$$available^STDCOMPRESS()` | `""` if both libz and libzstd resolve at load time; otherwise a comma-separated list of missing backends (`"libz"`, `"libzstd"`, or `"libz,libzstd"`). Never raises. |

### Output-by-reference, not return value

Compressed and decompressed payloads can both be megabytes long.
Returning them as extrinsic strings would brush against YDB's per-string
limits and force callers into `$ZSUBSTR`-style chunking. STDCOMPRESS
follows the STDXML / STDJSON convention: caller passes an unset local
variable by reference; the routine populates it. The function-form
return is the success boolean so the call composes cleanly with `if`.

```m
new buf,raw,$etrap
set $etrap="write $zstatus,!  set $ecode=""""  quit"
if '$$gzip^STDCOMPRESS("hello, world",.buf) write $ecode,! quit
if '$$gunzip^STDCOMPRESS(buf,.raw) write $ecode,! quit
write raw,!  ; "hello, world"
```

### Binary-safe semantics

Compressed output contains arbitrary bytes 0x00–0xFF including embedded
NULs. STDCOMPRESS treats inputs and outputs as byte strings: each M
character is one byte, indexed via `$ZASCII` / `$ZCHAR` (not `$ASCII` /
`$CHAR`, which are codepoint-aware in YDB UTF-8 mode). The C ABI uses
`ydb_string_t*` (length + ptr), which is binary-clean by construction —
embedded NULs are preserved on the M↔C boundary.

UTF-8 text input round-trips correctly because UTF-8 is a byte
encoding; the compressor neither knows nor cares about codepoints.
Set `$ZCHSET` to `M` for guaranteed byte semantics across both
producers and consumers.

## Format choice

| Codec | When to use |
|---|---|
| `gzip` / `gunzip` | HTTP `Content-Encoding: gzip`, on-disk `.gz` files, anything that mentions `magic 1F 8B`. RFC 1952. |
| `deflate` / `inflate` | Raw RFC 1951 deflate. The "real" HTTP `Content-Encoding: deflate` per the spec letter. Smallest output of the libz pair (no header / trailer). |
| `zstdCompress` / `zstdDecompress` | Modern compression. Faster than gzip at the same ratio; better ratios at higher levels. RFC 8478. |

There is no `zlib` / `unzlib` pair (RFC 1950 — raw deflate plus 2-byte
header + Adler32 trailer) in v1. Add when a real consumer needs it;
the underlying libz call only differs by `windowBits`.

## Compression levels

| Backend | Range | Default | Notes |
|---|---|---|---|
| libz (gzip / deflate) | `1..9` | `6` | `1` is fastest / largest, `9` is slowest / smallest. `0` (no compression) is rejected with `,U-STDCOMPRESS-BAD-LEVEL,` to avoid surprise pass-through. |
| libzstd | `1..22` | `3` | `1..3` = fast tier; `19..22` = ultra tier (much slower, marginal gains). Negative levels (zstd `--fast`) deferred. |

## Errors

All errors set `$ECODE` and the call returns `0`. Wrap in `$ETRAP` to
recover, or check `$ECODE` after the call.

| Code | Cause |
|---|---|
| `,U-STDCOMPRESS-BAD-LEVEL,` | Level argument outside the codec's supported range. |
| `,U-STDCOMPRESS-CALLOUT-MISSING,` | The `stdcompress` callout shared object isn't loaded (env not set, .so not built, or library missing). Use `available()` for an upfront check. |
| `,U-STDCOMPRESS-LIBZ-FAIL,` | libz returned a non-Z_OK status — usually corrupt / truncated input on inflate, or a `Z_BUF_ERROR` if compressed output exceeded the 1 MiB cap. |
| `,U-STDCOMPRESS-LIBZSTD-FAIL,` | libzstd returned an error frame — same shape as libz on the corrupt-input path. |

### Error channel — implementation note

The internal `dispatchC` / `dispatchD` helpers return a status string
(`""` / `"MISSING"` / `"FAIL"`) rather than setting `$ECODE` directly.
Each public extrinsic maps the status onto the right `$ECODE` tag
**after** dispatch returns. The reason: while a local `$ETRAP` is
armed inside dispatch (to catch the missing-callout case), an
explicit `set $ecode=,U-…,` would re-fire the local trap before the
caller can observe the value. By splitting the responsibilities —
dispatch only catches dispatch-level errors, public extrinsics own
the user-visible `$ECODE` contract — both the missing-callout path
(rare) and the codec-failure path (common) propagate cleanly to
the caller's trap.

The error-path tests in `STDCOMPRESSTST.m` use the standard
`raises^STDASSERT(.pass,.fail,code,errno,desc)` idiom, not the
manual `set $etrap="set $ecode="""" quit"` + `contains^STDASSERT`
pattern — the manual pattern's argless `quit` from inside the etrap
unwinds past the contains assertion before it executes, so the
`$ECODE` value is never inspected. `raises^STDASSERT` uses `ZGOTO`
to unwind cleanly after capturing `$ECODE`.

## Build

The C shims live in `src/callouts/stdcompress.c`. Build with the
project-wide harness:

```bash
tools/build-callouts.sh
```

This produces `so/<platform>/stdcompress.so` (or `.dylib` on macOS) and
links against `-lz` and `-lzstd`. The build host must have `zlib.h`
and `zstd.h` available (Debian/Ubuntu: `apt install zlib1g-dev
libzstd-dev`; macOS: `brew install zlib zstd`).

The YDB call-out descriptor is `tools/std_compress.xc`. M-side calls
use the `$&stdcompress.<fn>(...)` namespaced syntax (XECUTE-wrapped
to keep tree-sitter-m happy with the `$&pkg.fn` token), so YDB
expects `ydb_xc_stdcompress=<path>` (alphanumeric package name —
no underscore between `std` and `compress`).

For local development on a host with `libz.so.1` + `libzstd.so.1`
loadable:

```bash
tools/build-callouts.sh                                     # produce .so
export STDLIB_LIB=$PWD/so/$(uname -s | tr 'A-Z' 'a-z')-$(uname -m)
export ydb_xc_stdcompress=$PWD/tools/std_compress.xc
```

For the engine-bound test loop, `make seed` runs `scripts/seed-callouts.sh`,
which scps `src/callouts/*.c` + `tools/std_*.xc` into the vista-meta
container, compiles each `.c` against the runtime YDB headers (so the
ABI matches r2.02), stages `.so` + `.xc` artefacts under
`~/export/seed/m-stdlib/{lib/<plat>,xc}/`, and idempotently injects a
marker block into `/etc/profile.d/ydb_env.sh` exporting
`STDLIB_LIB` + `ydb_xc_stdcompress` (and the per-package env vars
for the other Phase 3 modules) so every `m test` SSH session
inherits them. Running multiple modules in one session is a no-op —
each gets its own `ydb_xc_<pkg>` slot.

### Output buffer cap — 1 MiB

`tools/std_compress.xc` declares `O:ydb_string_t*[1048576]` — 1 MiB —
on every output parameter. YDB r2.02 caps M-string length at 1 MiB
by default, so larger declarations (the originally-shipped `[16777216]`
form) trip a parse error at descriptor load time. The `preallocBuf()`
M-side helper pre-allocates the same 1 MiB so the C side can write
through `ydb_string_t.length` in place. Payloads that compress / decompress
to more than 1 MiB will need the streaming API (queued — see
"Out of scope" below).

## Out of scope (queued)

- Streaming API (`open` / `write` / `close` handle triplet) for
  compressing payloads that don't fit in memory. v1 is one-shot only.
- RFC 1950 zlib format (windowBits = +15). Trivial follow-on once a
  real consumer asks.
- Negative zstd levels (`--fast` tier). Reasonable lift; defer until a
  real consumer drives it.
- zstd dictionaries (`ZSTD_CDict` / `ZSTD_DDict`).
- Multi-threaded zstd (`ZSTD_c_nbWorkers`).
- Brotli (RFC 7932). Add as a separate codec pair if HTTP CDN support
  drives it; libbrotlidec / libbrotlienc are similar in shape to libzstd.

## Conformance corpus

`tests/conformance/compress/` holds a small fixed-bytes corpus of
known-good outputs to guard against silent format drift across libz /
libzstd version bumps. Each fixture is the **byte-exact** compressed
encoding of a labelled string at level 6 (libz) / 3 (zstd) plus the
matching decompressed plaintext. Round-trip tests don't need it
(self-consistent), but cross-version regression tests do.
