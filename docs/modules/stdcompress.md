# `STDCOMPRESS` — gzip / deflate / zstd compression

First Phase 3 (`$ZF`-bound) m-stdlib module. Wraps `libz` for the
RFC 1952 gzip format and the RFC 1951 raw deflate stream, and `libzstd`
for the zstd format. Pure-M wrappers do the byte-level glue; the
compress/decompress kernels execute in C via YDB external calls.

## Status

🚧 **In flight** — H2 track. v1 surface scoped here; tests-first; impl
follows. See `docs/parallel-tracks.md` §3.5 (Phase 3) and
`docs/module-tracker.md` row H2.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `gzip` | `do gzip^STDCOMPRESS(data, .out [, level])` | `1` on success, `0` on failure (see `lastError`). Writes gzip-framed bytes to `.out`. Default level `6`, range `1..9`. |
| `gunzip` | `do gunzip^STDCOMPRESS(data, .out)` | `1` / `0`. Decompresses RFC 1952 gzip stream into `.out`. |
| `deflate` | `do deflate^STDCOMPRESS(data, .out [, level])` | `1` / `0`. Raw RFC 1951 deflate stream (no header, no trailer). Default level `6`. |
| `inflate` | `do inflate^STDCOMPRESS(data, .out)` | `1` / `0`. Decompresses raw RFC 1951 deflate. |
| `zstdCompress` | `do zstdCompress^STDCOMPRESS(data, .out [, level])` | `1` / `0`. Zstandard frame. Default level `3`, range `1..22`. |
| `zstdDecompress` | `do zstdDecompress^STDCOMPRESS(data, .out)` | `1` / `0`. Decompresses a zstd frame. |
| `available` | `$$available^STDCOMPRESS()` | `""` if both libz and libzstd resolve at load time; otherwise a comma-separated list of missing backends (`"libz"`, `"libzstd"`, or `"libz,libzstd"`). |
| `lastError` | `$$lastError^STDCOMPRESS()` | Last error message from libz (`zError(rc)`) or libzstd (`ZSTD_getErrorName`), or `""` if the last call succeeded. |

### Output-by-reference, not return value

Compressed and decompressed payloads can both be megabytes long.
Returning them as extrinsic strings would brush against YDB's per-string
limits and force callers into `$ZSUBSTR`-style chunking. STDCOMPRESS
follows the STDXML / STDJSON convention: caller passes an unset local
variable by reference; the routine populates it. The function-form
return is the success boolean so the call composes cleanly with `if`.

```m
new buf,raw
if '$$gzip^STDCOMPRESS("hello, world",.buf) write $$lastError^STDCOMPRESS(),! quit
if '$$gunzip^STDCOMPRESS(buf,.raw) write $$lastError^STDCOMPRESS(),! quit
write raw,!  ; "hello, world"
```

(`gzip`/`gunzip` etc. are also exposed as `$$` extrinsics returning the
same `1`/`0` for callers that prefer the boolean-in-condition form.)

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

All errors set `lastError()` and return `0`:

| Code | Cause |
|---|---|
| `,U-STDCOMPRESS-BAD-LEVEL,` | Level argument outside the codec's supported range. |
| `,U-STDCOMPRESS-LIBZ-` _zError_ `,` | libz returned a non-Z_OK status. _zError_ is the human string from `zError(rc)`. |
| `,U-STDCOMPRESS-LIBZSTD-` _name_ `,` | libzstd returned an error frame. _name_ is `ZSTD_getErrorName(rc)`. |
| `,U-STDCOMPRESS-OUT-OF-MEMORY,` | The C shim's output buffer allocation failed. |
| `,U-STDCOMPRESS-NOT-AVAILABLE-` _backend_ `,` | The requested codec's backend (`libz` or `libzstd`) failed to load at startup. Use `available()` for an upfront check. |

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

The YDB external-call table is `src/callouts/stdcompress.xc`. At
test / runtime time, `ydb_xc_path` (or the legacy `GTMXC_<name>`
fallback) must point at it. The `m test` runner exports both before
launching the suite when `src/callouts/*.xc` exists.

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
