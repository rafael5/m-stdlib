---
title: M Test Driven Development Guide
audience: M developers building or maintaining test suites on top of m-stdlib's TDD primitives.
companion: users-guide.md (general m-stdlib usage). modules/index.md (per-module reference).
---

# M Test Driven Development Guide

The integrated TDD loop on M:

```
edit .m  →  m fmt  →  m lint  →  m test (with fixtures + mocks)  →
m coverage (line + branch, gated)  →  m test --integration  →  CI
```

This guide documents what to type and how the pieces fit. It covers
the runtime substrate (m-stdlib), the runner (m-cli), the
container endpoint (vista-meta), and the inner-loop / release-gate
commands that drive them.

## Contents

- [1. The TDD substrate at a glance](#1-the-tdd-substrate-at-a-glance)
- [2. The seven m-cli-integrated primitives](#2-the-seven-m-cli-integrated-primitives)
- [3. The runner protocol](#3-the-runner-protocol)
  - [3.1 `m test` flags](#31-m-test-flags)
  - [3.2 What the runner does for each test](#32-what-the-runner-does-for-each-test)
  - [3.3 `m coverage` flags](#33-m-coverage-flags)
- [4. The TDD inner loop](#4-the-tdd-inner-loop)
- [5. The release-readiness gate](#5-the-release-readiness-gate)
- [6. Worked example — TDD-ing a new module](#6-worked-example--tdd-ing-a-new-module)
- [7. Operational recipes](#7-operational-recipes)
  - [7.1 Per-test transactional isolation](#71-per-test-transactional-isolation)
  - [7.2 Mocking call sites](#72-mocking-call-sites)
  - [7.3 Loading fixture data](#73-loading-fixture-data)
  - [7.4 Snapshot testing](#74-snapshot-testing)
  - [7.5 Configuring tests via `.env`](#75-configuring-tests-via-env)
  - [7.6 Profiling slow tests](#76-profiling-slow-tests)
  - [7.7 Running only changed suites](#77-running-only-changed-suites)
  - [7.8 Single-test selection](#78-single-test-selection)
- [8. CI integration](#8-ci-integration)
- [9. Troubleshooting](#9-troubleshooting)
- [10. Cross-references](#10-cross-references)

## 1. The TDD substrate at a glance

Three projects collaborate to provide M's TDD substrate. None of
them is responsible for the whole stack:

| Project | Responsibility | Operational entry point |
|---|---|---|
| **`m-stdlib`** | M-side runtime primitives — assertions, fixtures, mocks, seed data, profiling, snapshots, `.env` config — and the test-discovery contract (`*TST.m` suites, `t<UpperCase>(pass,fail)` labels). | `do start^STDASSERT(.pass,.fail)` / `do eq^STDASSERT(...)` / etc. — see §2. |
| **`m-cli`** | Python-side runner — `m test` (discovery, execution, output formats, isolation wrap, `--seed` / `--env` / `--update-snapshots` / `--timings` / `--changed` integration), `m coverage` (label coverage, LCOV / JSON, `--min-percent` gate), `m fmt`, `m lint`. | `m test tests/` / `m coverage --min-percent=85` — see §3. |
| **`vista-meta`** | Containerised YottaDB endpoint that `m test` and `m coverage` talk to over SSH (`~/data/vista-meta/conn.env`). No host YDB install required. Same engine the upstream consumers run. | `cd ~/projects/vista-meta && make run` (one-time per host); subsequent `m test` invocations reuse it. |

The architectural rule is that M-side runtime helpers belong in
`m-stdlib`, Python-side tooling belongs in `m-cli`, and coupling
points are documented protocols. The seven m-cli-integrated
primitives below are the realised contract.

## 2. The seven m-cli-integrated primitives

Seven m-stdlib modules are wired into the m-cli runner and form the
operational TDD substrate. Other m-stdlib modules are general-
purpose runtime utilities — heavily used inside test suites (every
suite asserts via `STDASSERT`; many encode/decode through `STDB64` /
`STDJSON` / `STDREGEX`) but not part of the TDD wiring per se.

| # | Module | Runner contract | Companion flag |
|---|---|---|---|
| 1 | [`STDASSERT`](../modules/stdassert.md) | `do start^STDASSERT(.pass,.fail)` at suite entry; `do <verb>^STDASSERT(.pass,.fail,...)` per assertion; `do report^STDASSERT(pass,fail)` at exit. The runner parses the `PASS` / `FAIL` lines to compute per-suite totals. | (always on; built-in) |
| 2 | [`STDFIX`](../modules/stdfix.md) | Runner wraps each test label in `do invoke^STDFIX("<label>",code)` so a `tstart` / `trollback $tlevel-1` brackets every test. Database mutations (`^DPT`, `^DIC`, `^XTMP`, anything global) auto-roll-back at end-of-test. | `--no-isolation` opts out |
| 3 | [`STDMOCK`](../modules/stdmock.md) | Runner calls `do clear^STDMOCK` between each pair of test labels so registrations don't leak across tests. Mock state (call count, recorded args) is `$JOB`-scoped. | (always on; built-in) |
| 4 | [`STDSEED`](../modules/stdseed.md) | Before each suite, runner calls `do load^STDSEED("PATH")` for each `--seed PATH`. Pluggable filer hook (`fileViaDie^STDSEED` is the default; tests inject a stub for unit-mode). Cleanup is automatic via STDFIX rollback. | `--seed PATH` (repeatable; order preserved) |
| 5 | [`STDPROF`](../modules/stdprof.md) | `m test --timings` captures the subprocess wall-clock per suite via Python `time.perf_counter()` — STDPROF is the in-process API for finer-grained intra-suite timings (`start^STDPROF` / `stop^STDPROF` / `$$percentile^STDPROF`). | `--timings` (subprocess level); `start^STDPROF` / `stop^STDPROF` (intra-suite) |
| 6 | [`STDSNAP`](../modules/stdsnap.md) | `m test --update-snapshots` sets `^STDLIB($JOB,"stdsnap","update")=1` so `do asserts^STDSNAP(...)` rewrites the baseline instead of comparing. Useful after an intentional output change. | `--update-snapshots` |
| 7 | [`STDENV`](../modules/stdenv.md) | Before each suite, runner calls `do parseFile^STDENV("PATH",.env)` and merges into `^STDLIB($JOB,"env",KEY)`. Test code reads via `$get(^STDLIB($JOB,"env","KEY"))`. Later `--env` files override earlier keys. | `--env PATH` (repeatable) |

These seven, together with `m test`, are the framework. Every other
m-stdlib module is general-purpose and unrelated to the TDD wiring.

## 3. The runner protocol

### 3.1 `m test` flags

The full surface, taken from `m test --help` at HEAD:

| Flag | Purpose |
|---|---|
| `--list` | List discovered suites and tests without running them. |
| `--filter SUBSTR` | Only run suites whose name contains this substring. |
| `--format text\|tap\|json\|junit` | Output format. Default `text`. JUnit XML for CI consumption. |
| `-q` / `--quiet` | Suppress summary output. |
| `--changed` | Only run suites whose source has changed (working tree + index + untracked). |
| `--changed-base REV` | With `--changed`: diff against revision REV instead of the working tree. |
| `--no-isolation` | Skip the per-test `STDFIX` transactional wrapper (legacy `^TESTRUN` suites). |
| `--seed PATH` | Load a `STDSEED` TSV manifest before each test. Repeatable; order preserved. |
| `--env PATH` | Load a `.env` file via `STDENV` before each suite. Repeatable; later files override earlier keys. |
| `--update-snapshots` | Set the `STDSNAP` update sentinel so `asserts^STDSNAP` rewrites baselines instead of comparing. |
| `--timings` | Show per-suite wall-clock duration in the summary line. |
| `--timeout SECONDS` | Per-suite timeout (per-test in single-test mode). Subprocess killed on overrun; reported as TIMEOUT. |

A single test is selected with `FILE::tLabel` syntax:

```bash
m test tests/STDCRYPTOTST.m::tSha256Abc      # one test
m test tests/STDCRYPTOTST.m                  # whole suite
m test tests/                                # all suites
```

### 3.2 What the runner does for each test

Per-test wrapper (with `--no-isolation` *off*, the default):

```
do invoke^STDFIX("<label>","do t<label>^<SUITE>(.pass,.fail)")
do clear^STDMOCK
```

`invoke^STDFIX` opens a `tstart` before the inner `xecute`, runs the
test body, and `trollback`s on the way out — pass *or* fail, including
`$ECODE`-raised exits (the `$etrap` body completes the unwind). With
`--no-isolation`, the runner just calls
`do t<label>^<SUITE>(.pass,.fail)` directly.

Between tests, `clear^STDMOCK` resets the mock registry so no stale
registration leaks. STDMOCK state is `$JOB`-scoped and outside the
TSTART scope, so it survives the rollback (this is intentional —
mocks are the test framework's state, not the test subject's state).

### 3.3 `m coverage` flags

| Flag | Purpose |
|---|---|
| `--routines PATH` | Explicit production-routines path (repeatable). |
| `--tests PATH` | Explicit test-suites path (repeatable). |
| `--suites SUITES` | Comma-separated suite names to restrict the run. |
| `--format text\|json\|lcov` | LCOV is consumable by `genhtml` / Codecov / Coveralls. |
| `--lines` | Show line-level detail in text output. |
| `--uncovered` | Print only uncovered labels (text format). |
| `--branch` | Collect branch coverage on `IF` / `ELSE` / `FOR` / postconditional decisions. |
| `--min-percent N` | Fail with exit 1 if total coverage is below this percent. |

Coverage is label-level (with optional branch reporting); line-level
via source instrumentation is a future deliverable, but in practice
label-level catches most regressions because m-stdlib labels are
small (one purpose per label).

## 4. The TDD inner loop

The loop for any module — m-stdlib's own modules and any project
building on top:

1. **Write the test file with realistic fixtures** —
   `tests/STDxxxTST.m`. Each test label is named `t<UpperCase>` and
   takes `(pass,fail)` by reference. Use `STDASSERT` verbs for the
   assertions; the m-cli runner discovers labels by parsing the
   tree-sitter-m AST.
2. **Run** — confirm a deliberate red:
   ```bash
   m test tests/STDxxxTST.m
   ```
   Either an `ImportError`-equivalent (`%YDB-E-ZLINKFILE` because the
   public label doesn't exist yet) or an assertion failure because
   stubs return safe defaults.
3. **Implement** — `src/STDxxx.m`.
4. **Run** — confirm green:
   ```bash
   m test tests/STDxxxTST.m
   ```
5. **`make check`** (fmt-check + lint + test) before committing;
   **`make coverage`** before tagging.

The fast inner loop is `make check`:

```bash
make check        # fmt-check + lint + test — under a minute
```

## 5. The release-readiness gate

The per-module §9 acceptance gate (applied before any `vN.N.N` tag):

| Gate | Tool | Command | Pass threshold |
|---|---|---|---|
| Format | `m fmt --check` | `make fmt-check` | clean (no diffs) |
| Lint | `m lint --error-on=error` | `make lint` | 0 errors |
| Tests | `m test --format=tap` | `make test` | 100 % assertions pass |
| Coverage | `m coverage --min-percent=85` | `make coverage` | ≥ 85 % per-module label coverage (most modules ship at 100 %) |
| IRIS portability | `iris-portability-check` CI job | (CI only) | fail-soft — surfaces regressions but does not gate merges |

`make ci` chains the lot:

```bash
make ci           # check + JUnit XML + LCOV coverage at min-percent 85
```

## 6. Worked example — TDD-ing a new module

```bash
# 0. Scaffold via m-cli (writes src/<NAME>.m, tests/<NAME>TST.m, .m-cli.toml,
#    Makefile, README, CI from a TDD-shaped template)
m new STDFOO

cd STDFOO
```

Edit `tests/STDFOOTST.m` to stake the public contract:

```m
STDFOOTST       ; Test suite for STDFOO.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        do tBarReturnsLength(.pass,.fail)
        do tBarRejectsEmpty(.pass,.fail)
        do report^STDASSERT(pass,fail)
        quit
        ;
tBarReturnsLength(pass,fail) ;@TEST "$$bar^STDFOO returns input length"
        do eq^STDASSERT(.pass,.fail,$$bar^STDFOO("hello"),5,"length of hello")
        quit
        ;
tBarRejectsEmpty(pass,fail) ;@TEST "$$bar^STDFOO raises on empty input"
        do raises^STDASSERT(.pass,.fail,"$$bar^STDFOO("""")",",U-STDFOO-EMPTY,","empty rejected")
        quit
```

Run — confirm a deliberate red (`tBarReturnsLength` fails because
the label doesn't exist):

```bash
m test tests/
```

Implement `src/STDFOO.m`:

```m
STDFOO  ; Length helper.
        quit
bar(s)
        if s="" set $ecode=",U-STDFOO-EMPTY," quit ""
        quit $length(s)
```

Run — confirm green:

```bash
m test tests/
# m test: 1 suite(s), 1 passed, 2/2 assertions passed
```

Run the gate:

```bash
make check        # fmt + lint + test
make coverage     # ≥ 85% label coverage
```

## 7. Operational recipes

### 7.1 Per-test transactional isolation

Default. Every test label runs inside `tstart` / `trollback`. To
write a test that mutates a global and proves the mutation worked,
you don't need cleanup code:

```m
tStoreWritesGlobal(pass,fail) ;@TEST "store^MYAPP writes to ^USER"
        do store^MYAPP(42,"alice")
        do eq^STDASSERT(.pass,.fail,$get(^USER(42)),"alice","stored")
        quit                                          ; rollback automatic
```

The runner wraps this in `invoke^STDFIX(...)`; any `^USER(42)` set
during the test is rolled back when the wrapper exits. The next test
starts with a clean slate.

To disable for legacy suites:

```bash
m test --no-isolation tests/LegacyTST.m
```

### 7.2 Mocking call sites

STDMOCK is **opt-in at the call site** — production code must call
`do invoke^STDMOCK("TARGET",.args)` (or `$$resolve^STDMOCK("TARGET")`)
instead of a bare `do TARGET`. Once it does, tests can swap the
implementation:

```m
; production
sendEmail(to,body)
        do invoke^STDMOCK("smtp^DELIVERY",to,body)
        quit
```

```m
; test
tSendEmailUsesSmtp(pass,fail) ;@TEST "sendEmail dispatches to smtp^DELIVERY"
        do register^STDMOCK("smtp^DELIVERY","stub^MYTEST")
        do sendEmail^MYAPP("a@b","hello")
        do eq^STDASSERT(.pass,.fail,$$called^STDMOCK("smtp^DELIVERY"),1,"called once")
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("smtp^DELIVERY",1,1),"a@b","first arg")
        ; do clear^STDMOCK is called by the runner between tests
        quit
        ;
stub^MYTEST(to,body)    ; the stub registered above
        ; record / no-op / assert as needed
        quit
```

### 7.3 Loading fixture data

```bash
m test --seed fixtures/test-patients.tsv tests/
```

```
# fixtures/test-patients.tsv
PATIENT	.01=Smith,John	.02=M	.03=2 7 80
PATIENT	.01=Doe,Jane	.02=F	.03=12 1 75
```

Seeds load *inside* the per-test STDFIX scope, so they roll back
automatically after each test. Tests can rely on
`$$exists^DIC(2,"Smith,John")` finding the seeded record without
worrying about cleanup.

For JSON-formatted fixtures (e.g. exports from a sister system that
already produces JSON):

```bash
m test --seed fixtures/test-patients.json tests/
```

`STDSEED.loadJson` accepts an STDJSON-encoded array of records with
the same field shape.

### 7.4 Snapshot testing

For data-shape regressions (parsed JSON trees, FileMan record
exports, RPC responses), a snapshot is the right tool:

```m
tParsedConfigShape(pass,fail) ;@TEST "config tree matches snapshot"
        new tree
        do parseFile^STDTOML("/cfg/dev.toml",.tree)
        do asserts^STDSNAP(.pass,.fail,"snapshots/dev-config.snap",.tree,"dev config")
        quit
```

Initial run: there's no baseline, so `asserts` saves one and passes.
Subsequent runs compare against the saved file. After an
intentional change, regenerate:

```bash
m test --update-snapshots tests/MYAPPTST.m
```

`asserts` rewrites the baseline instead of comparing; the next
normal run pins to the new shape.

### 7.5 Configuring tests via `.env`

```bash
m test --env .env.test --env .env.local tests/
```

Both files load before each suite; later files override earlier
keys. Inside test code:

```m
tDbHostFromEnv(pass,fail) ;@TEST "DB_HOST falls back to localhost"
        new host
        set host=$get(^STDLIB($JOB,"env","DB_HOST"))
        if host="" set host="localhost"
        do eq^STDASSERT(.pass,.fail,host,"localhost","fallback works")
        quit
```

`STDENV.parseFile` handles double-quoted (`"\n \t \r \" \\"` escapes)
and single-quoted (POSIX-literal) values, plus `#` whole-line
comments and leading-letter-or-`_` keys.

### 7.6 Profiling slow tests

Subprocess level — `m test --timings` reports per-suite wall-clock:

```bash
m test --timings tests/
# ok  STDXMLTST  (209/209 passed)  0.84s
# ok  STDREGEXTST  (102/102 passed)  0.62s
# ...
```

Intra-suite — STDPROF inside the test body:

```m
tPerfPath(pass,fail) ;@TEST "parse stays under 50ms p95"
        new prof,i
        for i=1:1:1000 do
        . do start^STDPROF(.prof,"parse")
        . do parse^STDXML(testInput,.tree)
        . do stop^STDPROF(.prof,"parse")
        do true^STDASSERT(.pass,.fail,$$percentile^STDPROF(.prof,"parse",95)<50000,"p95 < 50ms")
        quit
```

(Microsecond resolution via `$ZHOROLOG`.)

### 7.7 Running only changed suites

```bash
m test --changed                          # diff against working tree + index + untracked
m test --changed --changed-base main      # diff against main
```

The runner reverse-walks m-cli's `WorkspaceIndex` (which maps each
routine to inbound call sites) so a change to `src/MYAPP.m` runs
not just `tests/MYAPPTST.m` but every suite that exercises a label
in `MYAPP`.

### 7.8 Single-test selection

```bash
m test tests/STDCRYPTOTST.m::tSha256Abc       # one test
m test --filter "Sha256" tests/                # all suites whose name contains Sha256
```

`FILE::tLabel` is the precise selector — useful when iterating on a
specific failing assertion. `--filter` is the substring match across
the suite-name search.

## 8. CI integration

GitHub Actions, GitLab, TeamCity, Jenkins all consume JUnit XML.
`make ci` produces it:

```bash
make ci
# → test-results.tap, test-results.junit (via m test --format=junit)
# → coverage.lcov (via m coverage --format=lcov)
# → coverage.json (via m coverage --format=json)
```

Inside the job, gate on coverage:

```bash
m coverage --min-percent=85       # exit 1 below threshold
```

The `iris-portability-check` job in m-stdlib's CI
(`.github/workflows/ci.yml`) runs the same suite against
`intersystemsdc/iris-community:latest` in fail-soft mode — surfaces
regressions but does not gate merges, since IRIS-specific quirks
shouldn't block YDB-first development.

## 9. Troubleshooting

**`m test` says "no conn file: ~/data/vista-meta/conn.env".** The
vista-meta container isn't running. Bring it up:

```bash
cd ~/projects/vista-meta && make run
```

The connection contract is published once on `make run`; subsequent
`m test` invocations reuse it.

**Tests pass on the host but fail in CI.** The CI job either
(a) doesn't have `vista-meta` available — check the workflow file
declares the YDB image — or (b) is missing a `--seed` / `--env`
argument that local invocations rely on. Make the inner loop
`make check` reproduce the failure locally first; CI is downstream of
local correctness.

**`%YDB-E-QUITARGREQD` from a test that uses `$ETRAP`.** `$etrap`
firing inside an extrinsic must `quit` *with an argument*. Either
move the etrap into a procedure-level frame, or end the body with
`quit -1` (or another sentinel). See
[`TOOLCHAIN-FINDINGS.md`](../tracking/TOOLCHAIN-FINDINGS.md) for any
open issues in this area.

**Tests leak state between runs.** Either you have `--no-isolation`
on by mistake, or the test mutates something STDFIX can't roll back
(local files via `STDFS`, env vars via `STDOS.setenv`, mock state
that the runner handles separately). For files: clean up explicitly
in the test. For mocks: trust the runner's
`do clear^STDMOCK`-between-tests guarantee.

**`m test --update-snapshots` doesn't update.** STDSNAP only
rewrites if a baseline exists *and* the new content differs — a
no-op update is silent. Delete the baseline file and re-run if you
want a guaranteed regeneration.

**Coverage reports 0% but tests pass.** YDB `view "TRACE"` requires
the `ydb_dist`-sourced session that `m test` already uses. If
coverage breaks while tests pass, the issue is almost always
`--routines` / `--tests` autodetect mis-locating the source —
pass them explicitly:

```bash
m coverage --routines src/ --tests tests/ --min-percent=85
```

## 10. Cross-references

- [`users-guide.md`](users-guide.md) — general m-stdlib user's guide; full module inventory, per-module reference, library philosophy.
- [`modules/index.md`](../modules/index.md) — canonical module inventory; per-module reference + cross-module dependency map.
- [`m-stdlib-implementation-plan.md`](../plans/m-stdlib-implementation-plan.md) — per-module specs (§8) and the §9 acceptance gate.
- [`module-tracker.md`](../tracking/module-tracker.md) — single-source-of-truth tracker for shipped, in-flight, and proposed modules; live ToDo board.
- [`TOOLCHAIN-FINDINGS.md`](../tracking/TOOLCHAIN-FINDINGS.md) — open toolchain bugs with severity, status, and resolution path.
- [`../../m-cli/CLAUDE.md`](../../../m-cli/CLAUDE.md) — m-cli's project context; runner / lint / lsp conventions.
