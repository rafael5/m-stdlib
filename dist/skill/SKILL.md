---
name: m-stdlib
type: knowledge
description: >
  m-stdlib is a pure-M (and selectively $ZF-bound) runtime library
  filling the highest-impact gaps in M's standard library —
  assertions, UUIDs, base64/hex, JSON, regex, datetime, logging,
  CSV, URL, file I/O, HTTP, crypto digests, and more. Load when
  writing M code that calls any STD* module, or when planning
  utility code in MUMPS/YottaDB. Triggers: "m-stdlib", "STDJSON", "STDASSERT", "STDCRYPTO", "STDLOG", "$$parse^STD", "do start^STDASSERT", "^STD".
---

# m-stdlib — pattern library and quick reference (v0.5.0)

Generated from m-stdlib's `dist/stdlib-manifest.json` — every public
module + label, the canonical-idiom library, and the full U-STD* error
surface, all rendered for AI / agent context loading.

**Catalogue:** 32 modules, 284 public labels,
43 error codes.

## When to use this skill

Load when the task references any `STD*` module / `^STD` symbol or
when designing utility code in MUMPS / YottaDB — the patterns here
often replace bespoke per-site reinventions.

## Companion files

| File | Use when |
|---|---|
| [`patterns.md`](patterns.md) | Looking for a copy-paste idiom for a frequent task (STDASSERT suite skeleton, STDFIX `with`, STDLOG kv, STDJSON parse, etc.). |
| [`manifest-index.md`](manifest-index.md) | You know the module name and want the full label list with synopses; or grepping for a function by name. |
| [`error-codes.md`](error-codes.md) | An $ETRAP fired with a `,U-STDxxx-,` code and you need to know which module / label set it. |

## Module catalogue

- **`STDARGS`** — argparse (v0.0.7).
- **`STDASSERT`** — assertion library (v0.0.1).
- **`STDB64`** — RFC-4648 Base64 (standard + URL-safe).
- **`STDCACHE`** — LRU + TTL cache over a caller-owned local array.
- **`STDCOLL`** — collections (Set, Map, Stack, Queue, Deque, Heap, OrderedDict).
- **`STDCOMPRESS`** — gzip / deflate / zstd via $&stdcompress callouts.
- **`STDCRYPTO`** — Cryptographic digests via $&stdcrypto → libcrypto.
- **`STDCSPRNG`** — Cryptographic random (kernel CSPRNG via getrandom(2) | /dev/urandom).
- **`STDCSV`** — RFC-4180 CSV parser/writer (pure-M).
- **`STDDATE`** — ISO-8601 datetime + arithmetic (v0.0.5).
- **`STDENV`** — .env file loader with typed accessors.
- **`STDFIX`** — fixture lifecycle and per-test isolation.
- **`STDFMT`** — printf-style formatter (subset of Python str.format).
- **`STDFS`** — File-system primitives (text I/O, path manipulation, bytes).
- **`STDHEX`** — RFC-4648 §8 hex encoding (lowercase by default).
- **`STDHTTP`** — HTTP/1.1 client (track H3, target tag v0.4.0).
- **`STDJSON`** — RFC 8259 JSON parser + serialiser.
- **`STDLOG`** — structured key=value logger (v0.0.4).
- **`STDMATH`** — Numeric helpers (clamp / min / max / sum / count / mean over arrays).
- **`STDMOCK`** — opt-in test-time call interception (mock registry).
- **`STDOS`** — Process / env / cmdline helpers (YDB-only v1).
- **`STDPROF`** — Wall-clock profiler with per-tag aggregates + percentiles.
- **`STDREGEX`** — regular expressions (track L12, v0.2.0).
- **`STDSEED`** — declarative test data loader (v0.1.3).
- **`STDSEMVER`** — SemVer 2.0.0 parse / compare / range matching.
- **`STDSNAP`** — Snapshot testing: serialize an M tree, diff against a baseline.
- **`STDSTR`** — String helpers (pad / trim / split / replaceAll / case / repeat).
- **`STDTOML`** — TOML 1.0 parser (deliberately narrow v1 subset).
- **`STDURL`** — RFC 3986 URI parser, builder, encoder, resolver.
- **`STDUUID`** — UUID v4 + v7 (RFC 4122 / RFC 9562).
- **`STDXFRM`** — Higher-order array transforms (map / filter / reduce via @-indirection lambdas).
- **`STDXML`** — XML parser (well-formed XML 1.0 subset, in-progress).

## Architectural rules

- **m-stdlib has priority over m-cli.** When both projects need a
  utility, implement it in m-stdlib first; m-cli imports.
- **YottaDB-first; IRIS-portable where reasonable.** Pure-M modules
  pass against IRIS in fail-soft CI; engine-bound modules
  (STDCRYPTO, STDCOMPRESS, STDHTTP, STDFS byte-mode, STDCSPRNG
  callout) are YottaDB-only at v0.5.0.
- **Each module is a flat routine; you `do`-call or `$$`-call public
  labels.** No global registries, no init hooks, no DI.

## Quick start

For any specific symbol, prefer `m doc <module>.<label>` from a
terminal — the manifest is the source of truth and the per-symbol
output is byte-for-byte richer than this skill.

For a copy-paste idiom matching a high-frequency task, see
`patterns.md`.

