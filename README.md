# m-stdlib

Pure-M (and selectively `$ZF`-bound) runtime library that fills the
highest-impact gaps in M's standard library — assertions, UUIDs,
base64/hex, formatting, structured logging, datetime, CSV, argparse,
fixtures, mocks, seed loaders, JSON, regex, collections, URLs, file
I/O, process / env / cmdline, SemVer, string helpers, TOML, LRU
cache, profiling, snapshot testing, `.env` loaders, XML, numeric
helpers, higher-order array transforms, SHA + HMAC, gzip / deflate /
zstd, and HTTP/1.1.

Sibling project to [m-cli](https://github.com/m-dev-tools/m-cli) (the
toolchain), [m-standard](https://github.com/m-dev-tools/m-standard) (the
modern-M style guide), and
[tree-sitter-m](https://github.com/m-dev-tools/tree-sitter-m) (the parser).

YottaDB-first; IRIS-portable where reasonable.

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
  [`docs/guides/m-tdd-guide.md`](docs/guides/m-tdd-guide.md) for the integrated workflow.

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
the runner-protocol details live in [`docs/guides/m-tdd-guide.md`](docs/guides/m-tdd-guide.md).

## 4. Module inventory

Backend column: **pure-M** = no host callouts; **`$&pkg.fn`** = YDB
external-call ABI to a libc / OpenSSL / libz / libzstd / libcurl
shared object. m-cli column: **✅ C\<n\>** = m-cli companion
integration shipped (see [`docs/tracking/module-tracker.md`](docs/tracking/module-tracker.md)
for the full companion-track names); **n/a** = no m-cli companion
needed; **🟡** / **🔮** = future / speculative. Status column:
**green-on-engine** = suite passes against the vista-meta YDB engine
via `make test` at the head of `main`.

| # | Module | Backend | m-cli | Headline |
|---|---|---|---|---|
| 1 | [`STDASSERT`](docs/modules/stdassert.md) | pure-M | ✅ C1+C2 | Assertion library — `eq` / `ne` / `true` / `false` / `near` / `raises` / `contains` / `len` + counter `start` / `report`. Wire-protocol-compatible with the m-cli runner. |
| 2 | [`STDUUID`](docs/modules/stduuid.md) | pure-M | n/a | RFC-4122 v4 + RFC-9562 v7 UUIDs. v7 timestamp-prefix sorts in generation order. |
| 3 | [`STDB64`](docs/modules/stdb64.md) | pure-M | n/a | RFC-4648 Base64 — standard alphabet `+ /`, URL-safe variant `- _`, `valid` predicate. |
| 4 | [`STDHEX`](docs/modules/stdhex.md) | pure-M | n/a | RFC-4648 §8 hex — lowercase default, uppercase variant, case-insensitive decode. |
| 5 | [`STDFMT`](docs/modules/stdfmt.md) | pure-M | n/a | Printf-style formatter — subset of Python `str.format` (fill / align / width / precision / type `s d f x X o b`). |
| 6 | [`STDLOG`](docs/modules/stdlog.md) | pure-M | n/a | Structured logger — five levels, four sinks, `kv` or `json` line format. |
| 7 | [`STDDATE`](docs/modules/stddate.md) | pure-M | n/a | ISO-8601 datetime + duration arithmetic (`now`, `fromh`, `toh`, `strftime`, `strptime`, `add`, `diff`). |
| 8 | [`STDCSV`](docs/modules/stdcsv.md) | pure-M | n/a | RFC-4180 CSV parser/writer — every §2 clause, optional file I/O. |
| 9 | [`STDARGS`](docs/modules/stdargs.md) | pure-M | n/a | argparse — long/short/grouped flags, positionals, sub-commands, `--` terminator. |
| 10 | [`STDFIX`](docs/modules/stdfix.md) | pure-M | ✅ C3 | Fixture lifecycle — `with` / `invoke` / `register` / `cleanup`. Powers `m test`'s default per-test isolation. |
| 11 | [`STDMOCK`](docs/modules/stdmock.md) | pure-M | ✅ C4 | Test-time call interception — `register` / `invoke` / `$$resolve` / `$$called` / `$$args`. |
| 12 | [`STDSEED`](docs/modules/stdseed.md) | pure-M | ✅ C5 | TSV / JSON manifest loader for FileMan record fixtures + pluggable filer hook. |
| 13 | [`STDJSON`](docs/modules/stdjson.md) | pure-M | n/a | RFC 8259 JSON parser + serialiser — one M tree node per JSON value. |
| 14 | [`STDREGEX`](docs/modules/stdregex.md) | pure-M | n/a | Thompson-NFA regex engine (literals, classes, groups, alternation, greedy quantifiers, capture, replace, split). |
| 15 | [`STDCOLL`](docs/modules/stdcoll.md) | pure-M | n/a | Collections — Set / Map / Stack / Queue / Deque / Heap / OrderedDict over caller-owned arrays. |
| 16 | [`STDURL`](docs/modules/stdurl.md) | pure-M | 🔮 C9 | RFC 3986 URI parse / build / encode / decode / valid / normalize / resolve. |
| 17 | [`STDCSPRNG`](docs/modules/stdcsprng.md) | pure-M (+ optional `$&` → `getrandom(2)` perf path) | n/a | Cryptographic random — bytes / hex / base64 / token / int / uuid4 backed by `/dev/urandom`. |
| 18 | [`STDFS`](docs/modules/stdfs.md) | pure-M (text I/O) + `$&` → libc `open/read/write/close` (byte-faithful arms) | n/a | File-system primitives — text-mode read/write/append + byte-faithful readBytes/writeBytes/appendBytes + exists/remove/size + basename/dirname/join. |
| 19 | [`STDOS`](docs/modules/stdos.md) | pure-M | n/a | Process / env / cmdline helpers — env / pid / cmdline / argv / cwd / user / hostname / exit. |
| 20 | [`STDSEMVER`](docs/modules/stdsemver.md) | pure-M | 🔮 C10 | SemVer 2.0.0 — valid / parse / compare / matches with caret, tilde, comparator AND-combination. |
| 21 | [`STDSTR`](docs/modules/stdstr.md) | pure-M | n/a | String helpers — pad / trim / replaceAll / split / startsWith / endsWith / case / repeat. |
| 22 | [`STDTOML`](docs/modules/stdtoml.md) | pure-M | 🔮 C11 | TOML 1.0 subset — top-level pairs + `[section]` tables; string / int / float / bool scalars; `#` comments. |
| 23 | [`STDCACHE`](docs/modules/stdcache.md) | pure-M | n/a | LRU + TTL cache over caller-owned array — new / put / get / has / remove / clear. |
| 24 | [`STDPROF`](docs/modules/stdprof.md) | pure-M | ✅ C6 | Wall-clock profiler — start / stop / count / total / mean / min / max / percentile / tags. |
| 25 | [`STDSNAP`](docs/modules/stdsnap.md) | pure-M | ✅ C7 | Snapshot testing — serialize / save / matches / asserts; canonical line-per-leaf dump via `$QUERY`. |
| 26 | [`STDENV`](docs/modules/stdenv.md) | pure-M | ✅ C8 | `.env` loader + typed accessors — parse / parseFile / valid / has / get / getInt / getBool / getFloat. |
| 27 | [`STDXML`](docs/modules/stdxml.md) | pure-M | n/a | XML 1.0 parser — elements, attributes, CDATA, comments / PI / xml-decl, numeric char refs, namespaces, full XPath subset (paths / predicates / descendant axis / wildcards / attribute axis / functions / comparison predicates / DOCTYPE + `<!ENTITY>`). |
| 28 | [`STDMATH`](docs/modules/stdmath.md) | pure-M | n/a | Numeric helpers — clamp / min / max / sum / count / mean over caller-owned arrays. |
| 29 | [`STDXFRM`](docs/modules/stdxfrm.md) | pure-M | n/a | Higher-order array transforms — map / filter / reduce via XECUTE-evaluated lambdas (`value` / `key` / `acc` locals). |
| 30 | [`STDCRYPTO`](docs/modules/stdcrypto.md) | `$&stdcrypto.fn` → libcrypto | 🟡 C12 | SHA-256/384/512 + HMAC-SHA-256/384/512 backed by OpenSSL EVP_Digest + HMAC. Conformance: FIPS 180-4 + RFC 4231 vectors. |
| 31 | [`STDCOMPRESS`](docs/modules/stdcompress.md) | `$&stdcompress.fn` → libz + libzstd | 🟡 C13 | gzip / gunzip / deflate / inflate / zstdCompress / zstdDecompress + magic-byte autodetect; 1 MiB output cap with `,U-…-FAIL,` on overflow. |
| 32 | [`STDHTTP`](docs/modules/stdhttp.md) | `$&stdhttp.fn` → libcurl (callout) + pure-M (wire-format helpers) | 🟡 C14 | HTTP/1.1 client — `$$get` / `$$post` / `$$request` driving libcurl, plus pure-M `parseStatusLine` / `parseHeader` / `parseResponse` / `buildRequest` / `formatHeaders` for offline wire-format work. |

**Aggregate gate, current head (`main`, 2026-05-08):** **32 suites,
2483/2483 assertions green** on the vista-meta YDB engine — every
public extrinsic exercised end-to-end through `m test`. Per-module
label coverage ≥ 91% (most at 100%; STDOS at 91.7%, STDENV at 93.3%
— `exit()` and `parseFile()` respectively unreachable / un-tested
by automated tests), 0 lint errors, fmt clean. See
[`docs/modules/index.md`](docs/modules/index.md) for the per-module
gate breakdown and [`docs/tracking/module-tracker.md`](docs/tracking/module-tracker.md)
for live status, in-flight extensions, and proposed future modules.

## 5. Module reference

The per-module five-minute orientation — one subsection for every
shipped module, with the public surface, typical usage pattern, and
the conformance corpus tied to it — lives in the user's guide:

→ **[`docs/guides/users-guide.md` § 5](docs/guides/users-guide.md#5-module-reference)**

For each module that section gives:

- The headline plus the one-line "why you'd reach for this".
- The minimal code example you'd write as a first call.
- The per-module backend (pure-M vs. `$&pkg.fn` callout) with the
  deployment runbook where relevant.
- A pointer into the authoritative per-module document at
  [`docs/modules/<module>.md`](docs/modules/) for the full label
  list, error codes, edge cases, and extended examples.

The canonical inventory (one row per shipped module, conformance
corpus pointers, cross-module dependency map) is at
[`docs/modules/index.md`](docs/modules/index.md).

## 6. What's next

Live work — proposed modules, in-flight extensions, deferred ToDos —
is tracked in [`docs/tracking/module-tracker.md`](docs/tracking/module-tracker.md). Open
toolchain bugs that block or limit m-stdlib work live in
[`docs/tracking/TOOLCHAIN-FINDINGS.md`](docs/tracking/TOOLCHAIN-FINDINGS.md).
Release history is in [`CHANGELOG.md`](CHANGELOG.md).

## 7. Cross-references

The `docs/` tree is organised into five subfolders by purpose:
**guides/** (long-form orientation), **modules/** (per-module
authoritative API docs + conformance-corpus pointers),
**plans/** (forward-looking specs + roadmaps), **testing/**
(corpus-validation reports), and **tracking/** (live work boards).
Repo-root docs (`CHANGELOG.md`) sit alongside this README.

### `docs/guides/` — long-form orientation

- [`docs/guides/users-guide.md`](docs/guides/users-guide.md) — full user's guide, including the § 5 per-module reference that this README links to.
- [`docs/guides/m-tdd-guide.md`](docs/guides/m-tdd-guide.md) — operational TDD guide for projects building tests on top of m-stdlib's seven m-cli-integrated TDD primitives (STDASSERT / STDFIX / STDMOCK / STDSEED / STDPROF / STDSNAP / STDENV).

### `docs/modules/` — per-module authoritative API docs

- [`docs/modules/index.md`](docs/modules/index.md) — canonical module inventory grouped by phase (v0.1.0 / v0.1.1–v0.1.3 / v0.2.0 / v0.3.0 / v0.4.0); conformance corpus + cross-module dependency map.
- One file per shipped module — `docs/modules/<name>.md` — full label list, error codes, edge cases, extended examples. The **§ 4 Module inventory** table above links each module row directly into its per-module page.

### `docs/plans/` — forward-looking specs + roadmaps

- [`docs/plans/m-stdlib-implementation-plan.md`](docs/plans/m-stdlib-implementation-plan.md) — per-module specs (§8) and §9 acceptance gate.
- [`docs/plans/tdd-orchestration-plan.md`](docs/plans/tdd-orchestration-plan.md) — historical cross-project TDD-orchestration plan (M0 → M5). Now fully realised; [`docs/guides/m-tdd-guide.md`](docs/guides/m-tdd-guide.md) is the operational follow-up.
- [`docs/plans/m-libraries-remediation.md`](docs/plans/m-libraries-remediation.md) — original survey of which gaps exist in M's stdlib and the remediation path that produced m-stdlib.

### `docs/testing/` — corpus validation reports

- [`docs/testing/realcode-validation.md`](docs/testing/realcode-validation.md) — toolchain-side findings against `m-modern-corpus`; STD\* prefix collision-free across 4,215 routines; lint matrix per project.
- [`docs/testing/modern-m-corpus-test-results.md`](docs/testing/modern-m-corpus-test-results.md) — library-fit findings; concrete LOC reductions in real projects (e.g. `_zewdJSON.m` 833 LOC → STDJSON ~50).
- [`docs/testing/vista-corpus-lint-results.md`](docs/testing/vista-corpus-lint-results.md) — lint results against the VistA M corpus, calibrating the `pythonic` profile against legacy code.

### `docs/tracking/` — live work boards

- [`docs/tracking/module-tracker.md`](docs/tracking/module-tracker.md) — single-source-of-truth tracker for shipped, in-flight, and proposed modules; live ToDo board (T1–T30) with per-module history archaeology.
- [`docs/tracking/parallel-tracks.md`](docs/tracking/parallel-tracks.md) — dispatch view; current execution status across L1–L27 / H1–H3 / m-cli companion tracks.
- [`docs/tracking/TODO.md`](docs/tracking/TODO.md) — resume-here pointer; thin index over the tracker boards.
- [`docs/tracking/TOOLCHAIN-FINDINGS.md`](docs/tracking/TOOLCHAIN-FINDINGS.md) — open toolchain bugs with severity, status, and resolution path.

### Repo-root

- [`CHANGELOG.md`](CHANGELOG.md) — release history.

## License

[AGPL-3.0](LICENSE). Family-wide consistency with m-cli, m-standard,
and tree-sitter-m.
