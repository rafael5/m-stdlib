---
title: m-stdlib — user's guide
status: live
audience: M developers (VistA, FIS-GT.M heritage projects, IRIS sites) who want a runtime-library substrate so they don't have to re-invent assertions, JSON, regex, datetime, logging, CSV, URL parsing, file I/O, HTTP, crypto digests, and the rest at every site.
companion: modules/index.md (canonical inventory); module-tracker.md (live work board); m-stdlib-implementation-plan.md (per-module specs); m-tdd-guide.md (operational TDD guide for projects building tests on top of m-stdlib's TDD primitives).
---

# m-stdlib — user's guide

## Contents

- [1. What this library is](#1-what-this-library-is)
  - [Non-goals](#non-goals)
- [2. Why a standard library, why now](#2-why-a-standard-library-why-now)
  - [The point of a standard library](#the-point-of-a-standard-library)
  - [The alternative is per-site reinvention](#the-alternative-is-per-site-reinvention)
  - [Now because the toolchain finally supports it](#now-because-the-toolchain-finally-supports-it)
- [3. Per-module acceptance gate](#3-per-module-acceptance-gate)
- [4. Module inventory](#4-module-inventory)
- [5. Module reference](#5-module-reference)
  - [5.1 STDASSERT](#51-stdassert--assertions-detail) — assertions
  - [5.2 STDUUID](#52-stduuid--uuids-detail) — UUIDs
  - [5.3 STDB64](#53-stdb64--base64-detail) — Base64
  - [5.4 STDHEX](#54-stdhex--hex-detail) — hex
  - [5.5 STDFMT](#55-stdfmt--printf-detail) — printf-style
  - [5.6 STDLOG](#56-stdlog--structured-logging-detail) — structured logging
  - [5.7 STDDATE](#57-stddate--datetime-detail) — datetime
  - [5.8 STDCSV](#58-stdcsv--rfc-4180-detail) — RFC 4180 CSV
  - [5.9 STDARGS](#59-stdargs--argparse-detail) — argparse
  - [5.10 STDFIX](#510-stdfix--fixtures-detail) — fixtures
  - [5.11 STDMOCK](#511-stdmock--call-interception-detail) — call interception
  - [5.12 STDSEED](#512-stdseed--fixture-data-detail) — fixture data
  - [5.13 STDJSON](#513-stdjson--json-detail) — JSON
  - [5.14 STDREGEX](#514-stdregex--regex-detail) — regex
  - [5.15 STDCOLL](#515-stdcoll--collections-detail) — collections
  - [5.16 STDURL](#516-stdurl--uri-detail) — URI
  - [5.17 STDCSPRNG](#517-stdcsprng--cryptographic-random-detail) — cryptographic random
  - [5.18 STDFS](#518-stdfs--file-system-detail) — file-system
  - [5.19 STDOS](#519-stdos--process--env--cmdline-detail) — process / env / cmdline
  - [5.20 STDSEMVER](#520-stdsemver--semver-200-detail) — SemVer 2.0.0
  - [5.21 STDSTR](#521-stdstr--string-helpers-detail) — string helpers
  - [5.22 STDTOML](#522-stdtoml--toml-10-subset-detail) — TOML 1.0 subset
  - [5.23 STDCACHE](#523-stdcache--lru--ttl-detail) — LRU + TTL cache
  - [5.24 STDPROF](#524-stdprof--wall-clock-profiler-detail) — wall-clock profiler
  - [5.25 STDSNAP](#525-stdsnap--snapshot-testing-detail) — snapshot testing
  - [5.26 STDENV](#526-stdenv--env-loader-detail) — `.env` loader
  - [5.27 STDXML](#527-stdxml--xml-10-detail) — XML 1.0
  - [5.28 STDMATH](#528-stdmath--numeric-helpers-detail) — numeric helpers
  - [5.29 STDXFRM](#529-stdxfrm--higher-order-array-transforms-detail) — map / filter / reduce
  - [5.30 STDCRYPTO](#530-stdcrypto--sha--hmac-detail) — SHA + HMAC
  - [5.31 STDCOMPRESS](#531-stdcompress--gzip--deflate--zstd-detail) — gzip / deflate / zstd
  - [5.32 STDHTTP](#532-stdhttp--http11-client-detail) — HTTP/1.1 client
- [6. What's next](#6-whats-next)
- [7. Cross-references](#7-cross-references)

## 1. What this library is

`m-stdlib` is a runtime library that fills the highest-impact gaps in
MUMPS / M's standard library: things every other modern runtime ships
out-of-the-box — assertions, UUIDs, base64, JSON, regex, collections,
datetime, logging, CSV, URL parsing, argparse, XML, file I/O,
HTTP, SHA / HMAC, gzip / zstd, and more — but that M historically
shipped only as ad-hoc per-site routines, packages, or, most often,
not at all.

The library is:

- **Pure-M for the entire ergonomics surface; `$ZF`-bound only where
  performance and correctness require it.** Phases 1, 1b, 2, and the
  P4 promotion wave are 100% pure M (no host callouts). Phase 3 — the
  three modules that bind to libcrypto / libz / libzstd / libcurl
  (`STDCRYPTO`, `STDCOMPRESS`, `STDHTTP`) plus the byte-faithful
  arms of `STDFS` and `STDCSPRNG` — uses YottaDB's `$&pkg.fn`
  external-call ABI through a shared deployment harness
  (`scripts/seed-callouts.sh`). Routines are upper-case
  six-or-fewer-character names per the M routine-name convention,
  prefixed `STD*` (the prefix is reserved family-wide).
- **YottaDB-first; IRIS-portable where reasonable.** Every pure-M
  module passes against the `intersystemsdc/iris-community:latest`
  image in fail-soft CI (`.github/workflows/ci.yml` →
  `iris-portability-check`) except where a feature is structurally
  engine-specific (e.g. YDB `view "TRACE"` for coverage).
- **Sibling to `m-cli`** (the toolchain), `m-standard` (the modern-M
  style guide), and `tree-sitter-m` (the parser). Architectural rule:
  **m-stdlib has priority over m-cli**. When both projects need a
  utility it lands here first; m-cli imports.

### Non-goals

- **Not a framework.** No global registries, no init hook, no
  dependency injection. Each module is a flat routine; you `do`-call
  or `$$`-call public labels.
- **Not a compatibility shim.** Does not paper over differences
  between YDB and IRIS — `STDREGEX` runs a Thompson-NFA on every
  engine, but the public API is what's portable, not the
  implementation.
- **Not a security boundary.** Nothing in m-stdlib enforces
  authentication, authorisation, or input sanitisation across trust
  domains. Treat it as a library, not a gateway.
- **Not a TDD framework, though seven of its modules** —
  `STDASSERT`, `STDFIX`, `STDMOCK`, `STDSEED`, `STDPROF`, `STDSNAP`,
  `STDENV` — are the operational primitives behind the m-cli runner's
  TDD support. If you're building a test suite *on top of* m-stdlib
  rather than just consuming utility code, see
  [`m-tdd-guide.md`](m-tdd-guide.md) for the integrated workflow.

## 2. Why a standard library, why now

### The point of a standard library

A standard library exists to enable **rapid, reliable, reproducible,
portable** development with **minimal re-invention**. Every other
modern runtime — Python, Go, Rust, Node, Java — assumes you can call
into a single canonical answer for base64, JSON, regex, datetime,
collections, HTTP, crypto digests, and the rest, and that the answer
behaves the same on every supported platform. `m-stdlib` brings the
same guarantee to MUMPS / M:

- **Rapid** because the canonical answer is one `$$call^STDxxx`
  away — no scaffolding, no shopping for which `^XB*` routine the
  current site happens to use this quarter.
- **Reliable** because every module ships with a vendored conformance
  corpus tied to the relevant RFC or NIST publication (RFC-4648 for
  base64/hex, RFC-4180 for CSV, RFC 8259 for JSON, RFC 3986 for URLs,
  RFC 4122/9562 for UUIDs, FIPS 180-4 for SHA, RFC 4231 for HMAC,
  the JSONTestSuite for JSON edge cases, the W3C XML Test Suite for
  XML, …) and runs all of it on every commit.
- **Reproducible** because the test corpus runs against a containerised
  YottaDB endpoint (`vista-meta`) — the same engine the upstream
  consumers run, with no host-side YDB install to drift.
- **Portable** because IRIS is a first-class CI target: every pure-M
  module is verified against `intersystemsdc/iris-community:latest`
  in fail-soft CI. Phase 3 callouts are YDB-only by design and
  document that explicitly.
- **Minimal re-invention** because contributing a fix at the library
  level fixes it for every consumer instead of the diff propagating
  ad-hoc through forks of `^XB*BASE64` across forty sites.

### The alternative is per-site reinvention

Every M shop with more than a few engineers has a private `^XB*`,
`^DI*`, or `^%Z*` routine that does base64 encoding, JSON parsing,
date arithmetic, or string formatting. Each of those private routines
has its own bug history, its own un-versioned conventions, and its
own opinions about what to do at edge cases. `m-stdlib` publishes a
canonical answer per concern.

### Now because the toolchain finally supports it

The library only works because the toolchain landed first:

- **`m-cli`** ships `m fmt` (style enforcement), `m lint` (XINDEX
  rules + ASTGREP-driven analyses), `m test` (test discovery +
  execution + TAP/JUnit output + coverage minimums + `--changed`
  diff-driven runs + `--seed` / `--update-snapshots` / `--env` /
  `--timings` / `--no-isolation` flags consuming the seven m-cli-
  integrated TDD primitives), and `m coverage` (line + branch +
  LCOV / JSON).
- **`tree-sitter-m`** parses M into a real AST so per-module docs,
  lint rules, and coverage tooling can target language constructs
  rather than line patterns.
- **`vista-meta`** publishes a containerised YottaDB endpoint so
  `make test` runs against a real engine without a host install. CI
  layers an IRIS image on top via `iris-portability-check`.

The toolchain is what makes the canonical-answer guarantee
mechanically enforceable — a per-module §9 acceptance gate
(fmt-check + lint + tests + coverage) blocks any release that drifts.

## 3. Per-module acceptance gate

Every module follows the same gate. The fast inner loop:

```bash
make check        # fmt-check + lint + test — under a minute on the dev box
```

The release-readiness loop (also what GitHub Actions runs):

```bash
make ci           # check + JUnit XML + LCOV coverage at min-percent 85
```

The per-module §9 acceptance gate, applied before any `vN.N.N` tag:

| Gate | Tool | Command | Pass threshold |
|---|---|---|---|
| Format | `m fmt --check` | `make fmt-check` | clean (no diffs) |
| Lint | `m lint --error-on=error` | `make lint` | 0 errors |
| Tests | `m test --format=tap` | `make test` | 100 % assertions pass |
| Coverage | `m coverage --min-percent=85` | `make coverage` | ≥ 85 % per-module label coverage (most modules ship at 100 %) |
| IRIS portability | `iris-portability-check` CI job | (CI only) | fail-soft — surfaces regressions but does not gate merges |

The `make check` invocation talks to vista-meta's YottaDB container
over SSH (`~/data/vista-meta/conn.env`), so there is no host YDB
install to manage. For projects building tests on top of m-stdlib's
TDD primitives, per-test isolation, mocking, fixture seeding, and
the runner-protocol details live in [`m-tdd-guide.md`](m-tdd-guide.md).

## 4. Module inventory

Backend column: **pure-M** = no host callouts; **`$&pkg.fn`** = YDB
external-call ABI to a libc / OpenSSL / libz / libzstd / libcurl
shared object. m-cli column: **✅ C\<n\>** = m-cli companion
integration shipped (see `module-tracker.md` for the full
companion-track names); **n/a** = no m-cli companion needed; **🟡** /
**🔮** = future / speculative. Status column: **green-on-engine** =
suite passes against the vista-meta YDB engine via `make test` at
the head of `main`.

| # | Module | Backend | m-cli | Headline |
|---|---|---|---|---|
| 1 | [`STDASSERT`](../modules/stdassert.md) | pure-M | ✅ C1+C2 | Assertion library — `eq` / `ne` / `true` / `false` / `near` / `raises` / `contains` / `len` + counter `start` / `report`. Wire-protocol-compatible with the m-cli runner. |
| 2 | [`STDUUID`](../modules/stduuid.md) | pure-M | n/a | RFC-4122 v4 + RFC-9562 v7 UUIDs. v7 timestamp-prefix sorts in generation order. |
| 3 | [`STDB64`](../modules/stdb64.md) | pure-M | n/a | RFC-4648 Base64 — standard alphabet `+ /`, URL-safe variant `- _`, `valid` predicate. |
| 4 | [`STDHEX`](../modules/stdhex.md) | pure-M | n/a | RFC-4648 §8 hex — lowercase default, uppercase variant, case-insensitive decode. |
| 5 | [`STDFMT`](../modules/stdfmt.md) | pure-M | n/a | Printf-style formatter — subset of Python `str.format` (fill / align / width / precision / type `s d f x X o b`). |
| 6 | [`STDLOG`](../modules/stdlog.md) | pure-M | n/a | Structured logger — five levels, four sinks, `kv` or `json` line format. |
| 7 | [`STDDATE`](../modules/stddate.md) | pure-M | n/a | ISO-8601 datetime + duration arithmetic (`now`, `fromh`, `toh`, `strftime`, `strptime`, `add`, `diff`). |
| 8 | [`STDCSV`](../modules/stdcsv.md) | pure-M | n/a | RFC-4180 CSV parser/writer — every §2 clause, optional file I/O. |
| 9 | [`STDARGS`](../modules/stdargs.md) | pure-M | n/a | argparse — long/short/grouped flags, positionals, sub-commands, `--` terminator. |
| 10 | [`STDFIX`](../modules/stdfix.md) | pure-M | ✅ C3 | Fixture lifecycle — `with` / `invoke` / `register` / `cleanup`. Powers `m test`'s default per-test isolation. |
| 11 | [`STDMOCK`](../modules/stdmock.md) | pure-M | ✅ C4 | Test-time call interception — `register` / `invoke` / `$$resolve` / `$$called` / `$$args`. |
| 12 | [`STDSEED`](../modules/stdseed.md) | pure-M | ✅ C5 | TSV / JSON manifest loader for FileMan record fixtures + pluggable filer hook. |
| 13 | [`STDJSON`](../modules/stdjson.md) | pure-M | n/a | RFC 8259 JSON parser + serialiser — one M tree node per JSON value. |
| 14 | [`STDREGEX`](../modules/stdregex.md) | pure-M | n/a | Thompson-NFA regex engine (literals, classes, groups, alternation, greedy quantifiers, capture, replace, split). |
| 15 | [`STDCOLL`](../modules/stdcoll.md) | pure-M | n/a | Collections — Set / Map / Stack / Queue / Deque / Heap / OrderedDict over caller-owned arrays. |
| 16 | [`STDURL`](../modules/stdurl.md) | pure-M | 🔮 C9 | RFC 3986 URI parse / build / encode / decode / valid / normalize / resolve. |
| 17 | [`STDCSPRNG`](../modules/stdcsprng.md) | pure-M (+ optional `$&` → `getrandom(2)` perf path) | n/a | Cryptographic random — bytes / hex / base64 / token / int / uuid4 backed by `/dev/urandom`. |
| 18 | [`STDFS`](../modules/stdfs.md) | pure-M (text I/O) + `$&` → libc `open/read/write/close` (byte-faithful arms) | n/a | File-system primitives — text-mode read/write/append + byte-faithful readBytes/writeBytes/appendBytes + exists/remove/size + basename/dirname/join. |
| 19 | [`STDOS`](../modules/stdos.md) | pure-M | n/a | Process / env / cmdline helpers — env / pid / cmdline / argv / cwd / user / hostname / exit. |
| 20 | [`STDSEMVER`](../modules/stdsemver.md) | pure-M | 🔮 C10 | SemVer 2.0.0 — valid / parse / compare / matches with caret, tilde, comparator AND-combination. |
| 21 | [`STDSTR`](../modules/stdstr.md) | pure-M | n/a | String helpers — pad / trim / replaceAll / split / startsWith / endsWith / case / repeat. |
| 22 | [`STDTOML`](../modules/stdtoml.md) | pure-M | 🔮 C11 | TOML 1.0 subset — top-level pairs + `[section]` tables; string / int / float / bool scalars; `#` comments. |
| 23 | [`STDCACHE`](../modules/stdcache.md) | pure-M | n/a | LRU + TTL cache over caller-owned array — new / put / get / has / remove / clear. |
| 24 | [`STDPROF`](../modules/stdprof.md) | pure-M | ✅ C6 | Wall-clock profiler — start / stop / count / total / mean / min / max / percentile / tags. |
| 25 | [`STDSNAP`](../modules/stdsnap.md) | pure-M | ✅ C7 | Snapshot testing — serialize / save / matches / asserts; canonical line-per-leaf dump via `$QUERY`. |
| 26 | [`STDENV`](../modules/stdenv.md) | pure-M | ✅ C8 | `.env` loader + typed accessors — parse / parseFile / valid / has / get / getInt / getBool / getFloat. |
| 27 | [`STDXML`](../modules/stdxml.md) | pure-M | n/a | XML 1.0 parser — elements, attributes, CDATA, comments / PI / xml-decl, numeric char refs, namespaces, full XPath subset (paths / predicates / descendant axis / wildcards / attribute axis / functions / comparison predicates / DOCTYPE + `<!ENTITY>`). |
| 28 | [`STDMATH`](../modules/stdmath.md) | pure-M | n/a | Numeric helpers — clamp / min / max / sum / count / mean over caller-owned arrays. |
| 29 | [`STDXFRM`](../modules/stdxfrm.md) | pure-M | n/a | Higher-order array transforms — map / filter / reduce via XECUTE-evaluated lambdas (`value` / `key` / `acc` locals). |
| 30 | [`STDCRYPTO`](../modules/stdcrypto.md) | `$&stdcrypto.fn` → libcrypto | 🟡 C12 | SHA-256/384/512 + HMAC-SHA-256/384/512 backed by OpenSSL EVP_Digest + HMAC. Conformance: FIPS 180-4 + RFC 4231 vectors. |
| 31 | [`STDCOMPRESS`](../modules/stdcompress.md) | `$&stdcompress.fn` → libz + libzstd | 🟡 C13 | gzip / gunzip / deflate / inflate / zstdCompress / zstdDecompress + magic-byte autodetect; 1 MiB output cap with `,U-…-FAIL,` on overflow. |
| 32 | [`STDHTTP`](../modules/stdhttp.md) | `$&stdhttp.fn` → libcurl (callout) + pure-M (wire-format helpers) | 🟡 C14 | HTTP/1.1 client — `$$get` / `$$post` / `$$request` driving libcurl, plus pure-M `parseStatusLine` / `parseHeader` / `parseResponse` / `buildRequest` / `formatHeaders` for offline wire-format work. |

**Aggregate gate, current head (`main`, 2026-05-08):** **32 suites,
2483/2483 assertions green** on the vista-meta YDB engine — every
public extrinsic exercised end-to-end through `m test`. Per-module
label coverage ≥ 91% (most at 100%; STDOS at 91.7%, STDENV at 93.3%
— `exit()` and `parseFile()` respectively unreachable / un-tested
by automated tests), 0 lint errors, fmt clean. See
[`modules/index.md`](../modules/index.md) for the per-module gate
breakdown and [`module-tracker.md`](../tracking/module-tracker.md) for live
status, in-flight extensions, and proposed future modules.

## 5. Module reference

Each subsection here is a five-minute orientation. Authoritative
detail (full label list, error codes, edge cases, API examples) lives
in the per-module document linked at the top.

### 5.1 `STDASSERT` — assertions ([detail](../modules/stdassert.md))

The cornerstone every other suite uses. Eleven public labels
(`start`, `report`, `eq`, `ne`, `true`, `false`, `near`, `raises`,
`contains`, `len`, `silent`). Each assertion takes counters by
reference (`.pass,.fail`) and emits the line protocol the m-cli
runner consumes without adapter code.

```m
do start^STDASSERT(.pass,.fail)
do eq^STDASSERT(.pass,.fail,$$encode^STDB64("foo"),"Zm9v","RFC-4648 example")
do report^STDASSERT(pass,fail)
```

`raises` captures `$ECODE` from a candidate label running under
`$ETRAP`, supporting both extrinsic chains and procedure-style calls
via a `ZGOTO`-based unwind.

### 5.2 `STDUUID` — UUIDs ([detail](../modules/stduuid.md))

Both v4 (random) and v7 (timestamp-prefix monotonic) per RFC 4122 +
RFC 9562. The v7 implementation matters: it sorts in generation
order under M's natural collation, so `^index($$v7^STDUUID(),...)`
gives you a chronologically-ordered index for free.

API: `$$v4^STDUUID()`, `$$v7^STDUUID()`, `$$valid^STDUUID(s)`,
`$$version^STDUUID(s)`, `$$variant^STDUUID(s)`, plus `parse` /
`format` helpers. Conformance corpus at
`tests/conformance/uuid/rfc4122-vectors.tsv` covers Nil, Max, every
version 1–8, all four variants, mixed/upper case, plus eight
malformed-input rejections.

For security tokens (session IDs, password resets, JWT salts), prefer
`$$uuid4^STDCSPRNG()` — same RFC-4122 v4 surface but kernel-CSPRNG-
backed.

### 5.3 `STDB64` — Base64 ([detail](../modules/stdb64.md))

Standard and URL-safe variants. The URL-safe variant (`- _`, no `=`
padding) is the JWT convention, so STDB64 doubles as the encoding
half of a future JWT helper.

```m
write $$encode^STDB64("foobar"),!         ; Zm9vYmFy
write $$urlencode^STDB64("foo?bar=baz")   ; URL-safe, no padding
```

Five extrinsics: `encode`, `decode`, `urlencode`, `urldecode`,
`valid`. RFC-4648 §10 vectors at `tests/conformance/b64/`.

### 5.4 `STDHEX` — Hex ([detail](../modules/stdhex.md))

RFC-4648 §8. Four extrinsics: `encode` (lowercase), `encodeu`
(uppercase), `decode` (case-insensitive), `valid` (even length +
hex digits).

### 5.5 `STDFMT` — printf ([detail](../modules/stdfmt.md))

Subset of Python `str.format`. Two extrinsics:

- `$$f^STDFMT(template,a1,…,a9)` — up to 9 positional args.
- `$$fn^STDFMT(template,.args)` — named via local array.

Format spec: `{[name][:[fill][align][width][.precision][type]]}`,
where type ∈ `{s d f x X o b}`. `{{` / `}}` escape literal braces.

```m
write $$f^STDFMT("Hello, {0:>10}!","world"),!     ; "Hello,      world!"
write $$f^STDFMT("{0:.3f}",3.14159),!              ; "3.142"
```

### 5.6 `STDLOG` — structured logging ([detail](../modules/stdlog.md))

Five level entry points (`DEBUG` / `INFO` / `WARN` / `ERROR` /
`FATAL`), each accepting an `event` and up to five `key=value` pairs.

```m
do INFO^STDLOG("user.login","userid",duz,"ip",$io,"ua",ua)
; → 2026-05-05T19:10:00.123Z level=INFO event=user.login userid=42 ip=... ua=...
```

Configuration at `^STDLIB($job,"stdlog",...)`: `LEVEL` (per-process
threshold), `SINK` (`stderr` / `stdout` / `global` / `global:^GREF`),
and `FORMAT` (`kv` default, or `json` for one-line JSON-encoded
records via `$$encode^STDJSON`). Output values are emitted raw when
clean, otherwise wrapped in `"…"` with `\\` and `\"` escaping.

### 5.7 `STDDATE` — datetime ([detail](../modules/stddate.md))

Seven extrinsics covering wall-clock and arithmetic:

| Label | Purpose |
|---|---|
| `now` | Current UTC, ms precision, trailing `Z`. |
| `fromh` / `toh` | Convert `$HOROLOG` ↔ ISO 8601 (accepts 2/3/4-piece). |
| `strftime` / `strptime` | `%Y %m %d %H %M %S %j %z %%` directives. |
| `add` | `[-]P[nY][nM][nW][nD][T[nH][nM][nS]]` duration; Feb-29 day-clamp on `+P1Y`. |
| `diff` | `h2 − h1 → PnDTnHnMnS`, sign-prefixed. |

Civil-to-day conversion uses Howard Hinnant's `days_from_civil` over
proleptic Gregorian (verified 1840–2400 incl. all leap-year edge
cases).

### 5.8 `STDCSV` — RFC 4180 ([detail](../modules/stdcsv.md))

Four entry points: `$$parse^STDCSV(text,.rows)`,
`$$write^STDCSV(.rows)`, `parseFile^STDCSV(path,callback)`,
`writeFile^STDCSV(path,.rows)`. Covers every RFC-4180 §2 clause
(CRLF / LF / lone-CR record separators, optional trailing
terminator, optional `"…"` field wrapping, embedded `,` / CRLF /
`""` escape) and strips a leading UTF-8 BOM on input. Conformance
corpus at `tests/conformance/csv/`.

### 5.9 `STDARGS` — argparse ([detail](../modules/stdargs.md))

Long flags, short flags, grouped count flags (`-vvv`), positionals,
sub-commands, `--` end-of-flags terminator. Four actions:
`store_true` / `store` / `count` / `append`.

```m
new p,ns
set p=$$new^STDARGS()
do flag^STDARGS(p,"verbose","v","count")
do flag^STDARGS(p,"output","o","store")
do parse^STDARGS(p,$ZCMDLINE,.ns)
write ns("verbose"),!,ns("output"),!
```

Args source = `$ZCMDLINE` on YDB, explicit string elsewhere. Per-handle
state under `^STDLIB($job,"stdargs",p,...)`.

### 5.10 `STDFIX` — fixtures ([detail](../modules/stdfix.md))

Five public labels enabling per-test isolation:

| Label | Purpose |
|---|---|
| `with(tag,code)` | One-shot transactional scope: opens `tstart`, runs `code`, `trollback`s on exit. |
| `invoke(tag,code)` | Like `with`, but pre-runs setup hooks registered via `register`. |
| `$$active(tag)` | Predicate — is a fixture currently held? |
| `register(tag,setupCode,teardownCode)` | Declarative fixture. |
| `cleanup` | Idempotent rollback of any leaked transactions. |

Why one-shot wrappers and not standalone `setup` / `teardown`? Because
YDB's `TPQUIT` enforces per-routine-frame balance of `tstart` /
`trollback` — a Python-style separately-scoped setup/teardown pair
is structurally impossible. The runner protocol consumes
`with` / `invoke` accordingly, and `m test --no-isolation` opts out.

### 5.11 `STDMOCK` — call interception ([detail](../modules/stdmock.md))

Three procedures (`register` / `unregister` / `clear`), three
extrinsics (`$$resolve` / `$$called` / `$$args`), and one
indirection-driven procedure (`invoke`).

```m
do register^STDMOCK("get^DGFUNC","stub^MYTEST")
; production code calls do invoke^STDMOCK("get^DGFUNC",.args)
; — dispatched to stub^MYTEST instead
do clear^STDMOCK
```

The runner clears the mock registry between tests automatically.
Single-level resolution — no chained replacement. Per-call args
recorded under `^STDLIB($job,"stdmock",...)` so tests can assert what
the production code passed.

### 5.12 `STDSEED` — fixture data ([detail](../modules/stdseed.md))

TSV and JSON manifest loader for FileMan record fixtures.

```
# fixtures/test-patients.tsv
PATIENT	.01=Smith,John	.02=M	.03=2 7 80
PATIENT	.01=Doe,Jane	.02=F	.03=12 1 75
```

```bash
m test --seed fixtures/test-patients.tsv tests/
```

`loadJson` accepts an STDJSON-encoded array of records (same field
shape) for callers who already produce JSON fixtures. Pluggable filer
hook — the default `fileViaDie^STDSEED` invokes `FILE^DIE` and
surfaces `^TMP("DIERR",$J)` as `U-STDSEED-FILER-DIE-ERROR`. Tests
inject a stub filer to run without FileMan.

### 5.13 `STDJSON` — JSON ([detail](../modules/stdjson.md))

RFC 8259 parser + serialiser. Storage convention: one M tree node per
JSON value, with the type discriminator in the leaf:

| Sigil | Type |
|---|---|
| `o` | object — children at `node(key)` |
| `a` | array — children at `node(i)` |
| `s:VALUE` | string |
| `n:VALUE` | number (canonical numeric string) |
| `t` / `f` | true / false |
| `z` | null |

```m
new root,ok
set ok=$$parse^STDJSON("{""user"":""rmr"",""active"":true}",.root)
write $$type^STDJSON(.root("user")),!         ; string
write $$valueOf^STDJSON(.root("user")),!      ; rmr
write $$encode^STDJSON(.root),!                ; round-trips
```

Curated A3 corpus (23 `y_`, 15 `n_`, 8 `i_` files) at
`tests/conformance/json/` — every vector mapped to an RFC 8259 clause
in the corpus README. Recursion through subscripted-by-reference locals
uses the merge-then-pass idiom (YDB's `.x(SUBS)` syntax limit), which
is fully internalised — callers see ordinary-looking
`$$encode^STDJSON(.tree)` calls.

### 5.14 `STDREGEX` — regex ([detail](../modules/stdregex.md))

Thompson-NFA engine. Compiled patterns are positive-integer handles;
pattern state lives at `^STDLIB($job,"stdregex",h,...)`;
`$$free^STDREGEX(h)` releases it.

```m
new h,n,out
set h=$$compile^STDREGEX("(\\w+)@(\\w+\\.\\w+)")
write $$search^STDREGEX(h,"contact rmr@example.com"),!     ; 1
do groups^STDREGEX(h,"contact rmr@example.com",.out)
write out(1),!                                              ; rmr
write out(2),!                                              ; example.com
do free^STDREGEX(h)
```

Supported subset: literals, `.`, `^` / `$`, greedy `*` / `+` / `?` /
`{n}` / `{n,}` / `{n,m}`, `[abc]` / `[^abc]` / `[a-z]`, predefined
classes `\d` `\w` `\s`, alternation `|`, capturing `(…)` and
non-capturing `(?:…)`, `\1..\9` backref expansion in `replace`. Out
of scope: back-refs in pattern, lookaround, named groups, Unicode
property classes, inline modifiers, possessive/lazy quantifiers —
`compile` rejects with `U-STDREGEX-UNSUPPORTED`.

### 5.15 `STDCOLL` — collections ([detail](../modules/stdcoll.md))

Seven by-reference collection types over caller-owned local arrays:

| Type | Headline labels |
|---|---|
| `Set` | `add` / `has` / `remove` / `size` / `clear` / iterate via `$ORDER` |
| `Map` | `put` / `get` / `has` / `remove` / `size` / `clear` |
| `Stack` | `push` / `pop` / `peek` / `size` |
| `Queue` | `enq` / `deq` / `peek` / `size` |
| `Deque` | `pushFront` / `pushBack` / `popFront` / `popBack` / `peekFront` / `peekBack` |
| `Heap` | min-heap with `O(log n)` push / pop, `O(1)` peek; optional payload |
| `OrderedDict` | insertion-ordered; walks via monotonic sequence + reverse map |

Empty-key and empty-pop semantics are silent no-ops / blank returns
rather than `$ECODE`-raising — callers gate on `*Size` to distinguish
empty from a stored `""`.

### 5.16 `STDURL` — URI ([detail](../modules/stdurl.md))

RFC 3986. One procedure (`parse`) writes all seven components of a
URI to the caller's array (`scheme` / `userinfo` / `host` / `port` /
`path` / `query` / `fragment`); six extrinsics handle build, encode,
decode, validity, normalization, and reference resolution.

```m
new u
do parse^STDURL("https://user@example.com:8080/p?q=1#f",.u)
write u("scheme"),!,u("host"),!,u("port"),!  ; https / example.com / 8080
write $$normalize^STDURL("HTTP://Example.COM/a/./b/../c"),!
;   → http://example.com/a/c
write $$resolve^STDURL("/foo","http://a/b/c"),!
;   → http://a/foo (RFC 3986 §5.3 transform-references in strict mode)
```

`decode` is intentionally lenient (Python `urllib.parse.unquote`
semantics — malformed `%` sequences pass through as literal text);
`valid` is the strict gate.

### 5.17 `STDCSPRNG` — cryptographic random ([detail](../modules/stdcsprng.md))

Kernel CSPRNG via `/dev/urandom` (the same source `getrandom(2)` reads
without `GRND_RANDOM`). Use this — not `STDUUID.v4` or `$RANDOM` — for
session tokens, password reset tokens, JWT signing salts, nonces.

```m
write $$bytes^STDCSPRNG(16),!         ; 16 raw bytes (binary-unsafe in print)
write $$hex^STDCSPRNG(16),!           ; 32-char lowercase hex
write $$base64^STDCSPRNG(16),!        ; URL-safe base64 (no padding)
write $$token^STDCSPRNG(24),!         ; URL-safe token, 24 bytes of entropy
write $$int^STDCSPRNG(0,99),!         ; unbiased rejection-sampled int 0–99
write $$uuid4^STDCSPRNG(),!           ; RFC-4122 v4 backed by /dev/urandom
```

`int` rejection-samples on the smallest power of 256 covering the
range, so the distribution is unbiased (no modulo-bias artefact).
`uuid4` round-trips through `$$valid^STDUUID` / `$$version^STDUUID`
identically to `$$v4^STDUUID()` — switch over wherever the UUID is a
security boundary.

### 5.18 `STDFS` — file-system ([detail](../modules/stdfs.md))

Centralises the YDB SEQ-device `OPEN`/`USE`/`READ`/`WRITE`/`CLOSE`
dance so consumers don't re-derive deviceparams or trigger the
M-MOD-024 OPEN/CLOSE-deviceparam lint false-positive. Text-mode I/O
plus existence + metadata + pure-string path manipulation.

```m
do writeFile^STDFS("/tmp/note.txt","hello world")
write $$readFile^STDFS("/tmp/note.txt"),!     ; "hello world"
do append^STDFS("/tmp/note.txt"," — line 2")
do readLines^STDFS("/tmp/note.txt",.lines)
write $$exists^STDFS("/tmp/note.txt"),!       ; 1
write $$size^STDFS("/tmp/note.txt"),!         ; byte count
do remove^STDFS("/tmp/note.txt")
write $$basename^STDFS("/a/b/c.tsv"),!        ; "c.tsv"
write $$dirname^STDFS("/a/b/c.tsv"),!         ; "/a/b"
write $$join^STDFS("/a","b","c"),!            ; "/a/b/c"
```

`exists` uses an `OPEN`-with-`timeout=0` probe inside an
`$ETRAP+ZGOTO $zlevel` so it bypasses `$ZSEARCH`'s per-process cache —
a path created and removed inside one M process round-trips correctly.
`writeFile` always emits a trailing LF (POSIX convention); `readFile`
strips it on the way back.

### 5.19 `STDOS` — process / env / cmdline ([detail](../modules/stdos.md))

Fills the gaps `$ZCMDLINE` / `$ZJOB` / `$ZTRNLNM` leave behind. Useful
glue for STDARGS-driven scripts that want to inspect env, exit with a
non-zero rc, or report `$JOB` / `$cwd` / hostname.

```m
write $$env^STDOS("HOME"),!           ; ~/  ($ZTRNLNM-equivalent)
write $$pid^STDOS(),!                  ; current $JOB
write $$cmdline^STDOS(),!              ; raw $ZCMDLINE
do argv^STDOS(.args)                   ; whitespace-tokenised
write $$cwd^STDOS(),!
write $$hostname^STDOS(),!
do exit^STDOS(2)                       ; ZHALT 2
```

`splitArgs` is whitespace-only — quote-aware tokenisation tracked on
the dispatch board.

### 5.20 `STDSEMVER` — SemVer 2.0.0 ([detail](../modules/stdsemver.md))

Parse / compare / range-match per SemVer 2.0.0. Pure-M (no STDREGEX
runtime dep). Architecturally load-bearing for any future M package
manager — dependency resolution can't exist without this.

```m
write $$valid^STDSEMVER("1.2.3-rc.1+build.5"),!     ; 1
write $$compare^STDSEMVER("1.2.3","1.2.4"),!        ; -1
write $$matches^STDSEMVER("1.2.3","^1.2.0"),!       ; 1 (caret)
write $$matches^STDSEMVER("1.3.0","~1.2"),!         ; 0 (tilde, minor pinned)
write $$matches^STDSEMVER("2.0.0",">=1.0 <2"),!     ; 0 (AND-combined comparators)
do parse^STDSEMVER("1.2.3-rc.1+x",.v)
write v("major"),".",v("minor"),".",v("patch"),! v("prerelease"),!,v("build"),!
```

Range syntax: comparators (`>`, `<`, `>=`, `<=`, `=`), caret (`^`),
tilde (`~`), space-separated AND. Extended range constructs (`||`
OR, hyphen ranges, wildcards, prerelease-aware comparators, npm
`^0.x.y` zero-major narrowing) are tracked in
[`module-tracker.md`](../tracking/module-tracker.md).

### 5.21 `STDSTR` — string helpers ([detail](../modules/stdstr.md))

The pad / trim / split / starts-with / ends-with / case-fold / repeat
basics that show up across every consumer. Pure `$translate` /
`$piece` / `$find` / `$extract` — no `$Z*`, no STDREGEX dep. ASCII-
only.

```m
write $$pad^STDSTR("x",5,"."),!                ; "x...."
write $$padLeft^STDSTR("42",5,"0"),!            ; "00042"
write $$trim^STDSTR("  hi  "),!                 ; "hi"
write $$replaceAll^STDSTR("a,b,c",",",";"),!    ; "a;b;c"
do split^STDSTR("a,b,c",",",.parts)             ; parts(1)="a",parts(2)="b",...
write $$startsWith^STDSTR("hello","he"),!       ; 1
write $$toLowerASCII^STDSTR("ABC"),!            ; "abc"
write $$repeat^STDSTR("-",10),!                  ; "----------"
```

### 5.22 `STDTOML` — TOML 1.0 subset ([detail](../modules/stdtoml.md))

Top-level pairs + `[section]` tables + four scalars (string, signed
decimal int, signed decimal float, bool surfaced as 1/0) + `#`
comments. Tree shape: `root("v",path)` + `root("t",path)` where
`path` is a dotted key.

```m
new toml,cfg
set toml="[server]"_$char(10)_"host=""127.0.0.1"""_$char(10)_"port=8080"
do parse^STDTOML(toml,.cfg)
write cfg("v","server.host"),!     ; "127.0.0.1"
write cfg("v","server.port"),!     ; 8080
write cfg("t","server.port"),!     ; "int"
```

Out of scope: arrays, inline tables, dotted keys,
`[[array-of-tables]]`, multi-line / literal strings, integer
underscores + hex/oct/bin, special floats, exponent notation,
datetime values — see [`module-tracker.md`](../tracking/module-tracker.md) for
the queued extensions.

### 5.23 `STDCACHE` — LRU + TTL ([detail](../modules/stdcache.md))

Caller-owned cache tree (no globals). LRU via two-way `seq ↔ key`
maps; TTL is **lazy on access** (no background sweeper). Memoisation,
RPC-result caching, rate-limit windows.

```m
new cache,v
do new^STDCACHE(.cache,100,300)        ; capacity=100, ttl=300s
do put^STDCACHE(.cache,"user:42",.userTree)
if $$has^STDCACHE(.cache,"user:42") write $$get^STDCACHE(.cache,"user:42"),!
write $$size^STDCACHE(.cache),!,$$capacity^STDCACHE(.cache),!
do remove^STDCACHE(.cache,"user:42")
do clear^STDCACHE(.cache)
```

Multiple caches per process are independent (different `.cache`
locals). Time source is `$HOROLOG` collapsed to seconds.

### 5.24 `STDPROF` — wall-clock profiler ([detail](../modules/stdprof.md))

Caller-owned profiler tree. `$ZHOROLOG`-backed (microsecond
resolution; ANSI `$HOROLOG` is too coarse). Aggregates: count, total,
mean, min, max, percentile.

```m
new prof,i
do start^STDPROF(.prof,"db.query")
do queryDb()                              ; whatever you're profiling
do stop^STDPROF(.prof,"db.query")
write $$count^STDPROF(.prof,"db.query"),!
write $$mean^STDPROF(.prof,"db.query"),!
write $$percentile^STDPROF(.prof,"db.query",95),!
```

`m test --timings` covers the per-suite case at the subprocess level
without needing STDPROF; STDPROF is the right tool for finer-grained
intra-suite timings (per-test, per-section).

### 5.25 `STDSNAP` — snapshot testing ([detail](../modules/stdsnap.md))

Canonical line-per-leaf serialisation via a `$QUERY` walk; save +
match + assert against an on-disk baseline. Force-multiplier for
data-shape tests (parsed JSON trees, FileMan record exports,
RPC responses).

```m
new tree
set tree("a")=1
set tree("b","c")=2
do save^STDSNAP("snapshots/cfg.snap",.tree)
write $$matches^STDSNAP("snapshots/cfg.snap",.tree),!     ; 1
do asserts^STDSNAP(.pass,.fail,"snapshots/cfg.snap",.tree,"config matches")
```

Update mode: when `^STDLIB($job,"stdsnap","update")=1` is set,
`asserts` rewrites the baseline file instead of comparing. Used by
`m test --update-snapshots` to regenerate snapshots after an
intentional output change.

### 5.26 `STDENV` — `.env` loader ([detail](../modules/stdenv.md))

Parses `.env` files with the standard subset: bare values
(whitespace-trimmed), double-quoted with `\n \t \r \" \\` escapes,
single-quoted POSIX-literal (no escape processing), `#` whole-line
comments, leading-letter-or-`_` keys. Typed accessors with default-
on-miss-or-mistype.

```m
new env
do parseFile^STDENV("/cfg/dev.env",.env)
write $$get^STDENV(.env,"DB_HOST","localhost"),!
write $$getInt^STDENV(.env,"PORT",5432),!
write $$getBool^STDENV(.env,"DEBUG",0),!         ; 1 for {true,yes,on,1}
```

`getBool` matches `{true, yes, on, 1}` / `{false, no, off, 0}` case-
insensitive. `m test --env PATH` loads `.env` files automatically
before each suite — see m-cli's runner docs.

### 5.27 `STDXML` — XML 1.0 ([detail](../modules/stdxml.md))

XML 1.0 parser with namespace support and a useful XPath subset.
Public surface covers what a vista-meta HL7v3 / CDA / FHIR consumer
needs out of the box. Tree shape mirrors STDJSON's caller-owned-tree
convention — `node("name")` (local name) / `node("prefix")` /
`node("ns")` / `node("attr",key)` / `node("attrNs",key)` /
`node("text")` / `node("childCount")` / `node("child",N)`.

```m
new doc,sub
do parse^STDXML("<note id=""1""><body>hi</body></note>",.doc)
write $$rootName^STDXML(.doc),!                   ; "note"
write $$attr^STDXML(.doc,"id"),!                   ; "1"
do childByName^STDXML(.doc,"body",.sub)
write $$text^STDXML(.sub),!                        ; "hi"
```

What's covered:

- **Elements / attributes / text** — well-formed XML 1.0.
- **Comments / processing instructions / `<?xml ... ?>` declaration**
  — consumed and discarded (preamble, intra-document, postamble).
- **CDATA sections** — `<![CDATA[ ... ]]>` content stored verbatim
  (no entity decoding).
- **Entity references** — the five standard entities (`&amp;` `&lt;`
  `&gt;` `&quot;` `&apos;`) plus numeric character references
  (`&#NNN;` decimal, `&#xHH;` hex), with full UTF-8 encoding for
  any code point up to U+10FFFF.
- **Namespaces** — element prefix and attribute prefix both resolved
  against the inherited + local `xmlns` map; `xml:` prefix bound
  built-in. Accessors: `$$ns^STDXML(.node)`,
  `$$attrNs^STDXML(.node, attrName)`. Undeclared prefix is a parse
  error.
- **XPath subset** — `$$xpath` / `$$xpathOne` / `$$xpathText` accept
  bare `name`, chained `a/b/c`, absolute `/foo`, descendant `//x`,
  and the position predicate `[N]`. Results are subtree merges so
  callers walk them like any other parsed-tree node.

`childByName` does the internal `merge` to sidestep the YDB `.x(SUBS)`
syntax limit — recursive descent through a parsed XML tree just works
without callers needing merge-then-pass plumbing themselves. The
parser fails closed on unsupported input (`$$lastError^STDXML()`
identifies the offending construct). Out of scope: DTDs / `<!DOCTYPE>` /
custom entity declarations, XPath wildcards / attribute axis (`@attr`),
and XPath functions / comparison predicates (`[@attr='v']`,
`position()`, `count()`, …) — all tracked in
[`module-tracker.md`](../tracking/module-tracker.md).

### 5.28 `STDMATH` — numeric helpers ([detail](../modules/stdmath.md))

Scalar `clamp` plus reductions over caller-owned arrays
(`min` / `max` / `sum` / `count` / `mean`). Pure-M (no `$Z*`,
no STDREGEX dep). Works with any subscript shape — `$ORDER`-walks
depth-1 entries.

```m
write $$clamp^STDMATH(99,0,10),!         ; 10 (rolls down to hi)
write $$clamp^STDMATH(-3,0,10),!         ; 0  (rolls up to lo)

new arr  set arr(1)=3,arr(2)=1,arr(3)=4,arr(4)=1,arr(5)=5
write $$min^STDMATH(.arr),!              ; 1
write $$mean^STDMATH(.arr),!             ; 2.8
```

`mean` returns `""` for an empty array (no division by zero); `sum`
and `count` return `0`. The reductions read scalar leaves only —
nested subtrees are ignored, not recursed.

### 5.29 `STDXFRM` — higher-order array transforms ([detail](../modules/stdxfrm.md))

Three procedures (`map` / `filter`) and one extrinsic (`reduce`) that
modernise the standard `$ORDER`-loop idiom. The transformation is
supplied as an M expression string and evaluated via `XECUTE
"set <target>="_expr` per element — the lambda sees `value` and `key`
(and `acc`, for `reduce`) as plain locals.

```m
new a,out
set a(1)=1,a(2)=2,a(3)=3
do map^STDXFRM(.a,"value*2",.out)
; out(1)=2, out(2)=4, out(3)=6

set a(1)=2,a(2)=4,a(3)=5,a(4)=8
do filter^STDXFRM(.a,"value#2=0",.out)
; out(1)=2, out(2)=4, out(4)=8 (5 dropped)

write $$reduce^STDXFRM(.a,"acc+value",0),!     ; 19
```

Why `XECUTE` and not `@expr` indirection? YDB's `@expr` is
name-indirection (single expratom only) and rejects binary expressions
like `value*2` with `INDEXTRACHARS`. The XECUTE-based dispatch
accepts any valid M expression in scope.

### 5.30 `STDCRYPTO` — SHA + HMAC ([detail](../modules/stdcrypto.md))

OpenSSL-backed digest + MAC primitives. Twelve hex-output and
raw-byte extrinsics covering SHA-256 / SHA-384 / SHA-512 + HMAC-SHA
of each, plus an `$$available^STDCRYPTO()` probe that never raises.
Conformance: FIPS 180-4 §B for SHA, RFC 4231 §4 for HMAC.

```m
write $$sha256^STDCRYPTO("abc"),!
;   ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad

write $$hmacSha256^STDCRYPTO("Jefe","what do ya want for nothing?"),!
;   5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843

if '$$available^STDCRYPTO() set $ec=",U-MYAPP-NO-CRYPTO,"

set digestRaw=$$sha256Bytes^STDCRYPTO(payload)     ; 32 raw bytes
```

Backend: `$&stdcrypto.<fn>` → libcrypto via the YDB external-call
ABI. Deployment is the responsibility of `scripts/seed-callouts.sh`,
which compiles `src/callouts/std_crypto.c` inside the vista-meta
container, stages the resulting `.so` + `tools/std_crypto.xc`, and
idempotently exports `STDLIB_LIB` + `ydb_xc_stdcrypto` into
`/etc/profile.d/ydb_env.sh`. `make seed` invokes it automatically
whenever `src/callouts/*.c` is present.

### 5.31 `STDCOMPRESS` — gzip / deflate / zstd ([detail](../modules/stdcompress.md))

Compression backed by libz (gzip, raw deflate) and libzstd (zstd
frames). Six round-trip extrinsics + an availability probe that
returns the comma-separated list of any *missing* backends:

```m
new buf,roundtrip
if '$$gzip^STDCOMPRESS("hello, world",.buf) write $ec,! quit
write $length(buf),!                            ; ~30 bytes (RFC 1952 framed)

if '$$gunzip^STDCOMPRESS(buf,.roundtrip) write $ec,! quit
write roundtrip,!                               ; "hello, world"

write $$available^STDCOMPRESS(),!               ; "" when both libs load,
                                                ; "libzstd" if zstd is missing
```

Output-by-reference (`.out`) rather than return value because
compressed payloads can run to megabytes and YDB extrinsic returns
hit per-string limits sooner than the 1 MiB cap STDCOMPRESS
documents. The function return is the success boolean; on failure
`$ECODE` carries the specific tag (`,U-STDCOMPRESS-LIBZ-FAIL,` /
`,U-STDCOMPRESS-LIBZSTD-FAIL,` / `,U-STDCOMPRESS-NOT-WIRED,`).

Same `$&stdcompress.<fn>` → libz/libzstd deployment story as STDCRYPTO.

### 5.32 `STDHTTP` — HTTP/1.1 client ([detail](../modules/stdhttp.md))

HTTP/1.1 + HTTPS client. Two layers:

1. **Pure-M wire-format helpers** — `parseStatusLine` / `parseHeader`
   / `parseResponse` / `buildRequest` / `formatHeaders`. Testable
   without a network or a compiled callout; useful for offline
   protocol work and proxy/test-double construction.
2. **libcurl callout** — `$$get` / `$$post` / `$$request` /
   `$$available` drive `src/callouts/http.c::http_perform` via the
   shared `$&pkg.fn` deployment harness.

```m
; Pure-M offline parse — no network needed
new resp
do parseResponse^STDHTTP("HTTP/1.1 200 OK"_$c(13,10)_"Content-Type: text/plain"_$c(13,10,13,10)_"hi",.resp)
write resp("status"),! resp("header","content-type"),!,resp("body"),!
;   200 / text/plain / hi

; Network call — soft-fails to NOT-WIRED if the .so isn't deployed
new resp
do get^STDHTTP("https://example.com/hello.txt",.resp)
if $get(resp("error"))="STDHTTP-NOT-WIRED" set $ec=",U-MYAPP-NO-HTTP,"
write resp("status"),! resp("body"),!
```

`$$available^STDHTTP()` is the cheap pre-flight probe; the network
extrinsics short-circuit on `$$env^STDOS("ydb_xc_stdhttp")=""` so a
missing descriptor doesn't pay the XECUTE compile cost. The IRIS
arm via `%Net.HttpRequest` (iter 3) is queued; the M-side
`req` / `resp` array contract is shared between the two arms.

## 6. What's next

Live work — proposed modules, in-flight extensions, deferred ToDos —
is tracked in [`module-tracker.md`](../tracking/module-tracker.md). Open
toolchain bugs that block or limit m-stdlib work live in
[`discoveries.md`](../tracking/discoveries.md). Release history
is in [`../tracking/changelog.md`](../tracking/changelog.md).

## 7. Cross-references

- [m-tdd-guide.md](m-tdd-guide.md) — operational TDD guide for projects building tests on top of m-stdlib's seven m-cli-integrated TDD primitives (STDASSERT / STDFIX / STDMOCK / STDSEED / STDPROF / STDSNAP / STDENV).
- [modules/index.md](../modules/index.md) — canonical module inventory; one row per shipped module with conformance corpus + cross-module dependency map.
- [module-tracker.md](../tracking/module-tracker.md) — single-source-of-truth tracker for shipped, in-flight, and proposed modules; live ToDo board.
- [m-stdlib-implementation-plan.md](../plans/m-stdlib-implementation-plan.md) — per-module specs (§8) and §9 acceptance gate.
- [tdd-orchestration-plan.md](../plans/tdd-orchestration-plan.md) — historical cross-project TDD-orchestration plan (M0 → M5). Now fully realised; `m-tdd-guide.md` is the operational follow-up.
- [parallel-tracks.md](../tracking/parallel-tracks.md) — dispatch view; current execution status.
- [discoveries.md](../tracking/discoveries.md) — open toolchain bugs with severity, status, and resolution path.
- [../tracking/changelog.md](../tracking/changelog.md) — release history.
