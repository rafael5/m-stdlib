---
title: m-stdlib — parallel execution tracks
status: live (2026-05-06)
companion: tdd-orchestration-plan.md (joint milestone narrative)
implementation: m-stdlib-implementation-plan.md (per-module specs)
---

# m-stdlib — parallel execution tracks

This document carves the m-stdlib + m-cli plan into **independent
work tracks** — tasks that share zero source-file or API dependency
and can be picked up simultaneously by separate sessions, agents, or
contributors without coordination beyond merge ordering.

The narrative roadmap lives in
[tdd-orchestration-plan.md](tdd-orchestration-plan.md); this doc is
the dispatch view.

---

## 1. Independence model

Two tracks are **independent** if **all** of these hold:

1. They touch disjoint source files: `src/STDxxx.m`, `tests/STDxxxTST.m`,
   `tests/conformance/<corpus>/`, `docs/modules/<module>.md`.
2. Neither consumes the other's public API at runtime.
3. Neither's `*TST.m` suite imports or invokes the other module.

Files that are **shared but mergeable** — `CHANGELOG.md`, the §1
status table in `m-stdlib-implementation-plan.md`, `TODO.md`,
`TOOLCHAIN-FINDINGS.md` — are not coordination points during
development. Track owners produce fragments; concatenation happens at
PR review time. The §9 per-module acceptance gate stays per-module.

Tags merge in dependency order (v0.0.2 → v0.0.3 → …), but
**development can run in parallel**: a track for STDARGS (v0.0.7) can
produce a green branch before STDFMT (v0.0.3) merges, with no rebase
risk because the two routines never see each other.

---

## 2. Dependency map

Real cross-module dependencies — the **only** things that block
parallelism — are these eight edges:

| Consumer | Dependency | Type | Resolution |
|---|---|---|---|
| STDLOG (v0.0.4) | STDDATE (v0.0.5) | Soft — STDLOG ships its own inline ISO-ts helper at v0.0.4; bumps to `$$NOW^STDDATE()` at v0.0.5 | Track L4 ships first with helper; track L5 lands; track L4-bump removes helper |
| m-cli runner SETUP/TEARDOWN wrap | STDFIX (v0.1.1) | Hard | m-cli companion lands after STDFIX |
| m-cli runner CLEAR^STDMOCK | STDMOCK (v0.1.2) | Hard | m-cli companion lands after STDMOCK |
| m-cli `--seed PATH` | STDSEED (v0.1.3) | Hard | m-cli companion lands after STDSEED |
| STDLOG JSON-line output | STDJSON (v0.2.0) | Hard | STDLOG add-on lands in M4 |
| STDSEED `LOADJSON` | STDJSON (v0.2.0) | Hard | STDSEED add-on lands in M4 |
| STDHTTP | STDURL (v0.2.0) + `tools/build-callouts.sh` | Hard | Both ship before Phase 3 |
| STDCRYPTO / STDCOMPRESS | `tools/build-callouts.sh` | Hard | Build harness ships once before all three |

Everything else is independent.

---

## 3. Parallel track table

Each row is a self-contained unit of work: tests-first → impl →
docs/modules/<name>.md → CHANGELOG fragment → §9 gate. **Zero**
runtime or source-file dependency on any other track in the same
group.

### 3.1 m-stdlib Phase 1 — pure-M quick wins

All seven tracks are mutually independent (modulo the soft STDLOG↔STDDATE
edge above). Each is roughly 1–2 weeks for one contributor.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L1** | v0.0.2 | STDB64 | everything | ✅ **Shipped** in `v0.0.2` (commit `83e11b2`). 55/55 assertions; 100% label coverage; 0 lint. RFC-4648 §10 vectors at `tests/conformance/b64/`. |
| **L2** | v0.0.2 | STDHEX | everything | ✅ **Shipped** in `v0.0.2` (commit `83e11b2`). 49/49 assertions; 100% label coverage; 0 lint. Bundled with L1 by release convention. |
| **L3** | v0.0.3 | STDFMT | everything | ✅ **Shipped** in `v0.0.3` (commit `8e6b689`). Printf subset of `str.format`. 56/56 assertions; 100% label coverage; 0 lint. Error-path tests deferred (TOOLCHAIN-FINDINGS P1). |
| **L4** | v0.0.4 | STDLOG | everything | ✅ **Shipped** in `v0.0.4` (commit `abfa9a2`). 45/45 assertions; 15/15 labels (100%); 0 lint. L4b folded in — STDDATE landed first so STDLOG ships directly with `$$now^STDDATE()`; the inline-helper interim was never cut. |
| **L5** | v0.0.5 | STDDATE | everything | ✅ **Shipped** in `v0.0.5` (commit `1ec3b00`). ISO-8601 + duration arithmetic. 60/60 assertions; 19/20 labels (95.0%); 0 lint. |
| **L6** | v0.0.6 | STDCSV | everything | ✅ **Shipped** in `v0.0.6` (commit `0f7de40`). RFC-4180 parser/writer; corpus at `tests/conformance/csv/`. 59/59 assertions; 100% label coverage; 0 lint. |
| **L7** | v0.0.7 | STDARGS | everything | ✅ **Shipped** in `v0.0.7` (commit `c98d5a1`). argparse-style parser over `$ZCMDLINE`. |
| **L4b** | — | STDLOG bump to `$$now^STDDATE()` | — | ✅ **Folded into L4 / `v0.0.4`** rather than shipping as a follow-on tag. |

✅ **Phase 1 closed.** All seven tracks merged and rolled up under
`v0.1.0` (commit `3cf84f2`, 2026-05-05).

### 3.2 m-stdlib Phase 1b — TDD primitives (M1)

Three tracks, mutually independent. None depend on any Phase 1 module.
Could in principle start before Phase 1 completes.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L8** | v0.1.1 | STDFIX | everything | ✅ **Shipped** in `v0.1.1` (commit `3f8aa51`). TSTART/TROLLBACK isolation via `with` / `invoke`. 28/28 assertions; 5/5 labels (100%); 0 lint. Standalone setup/teardown labels intentionally not exposed (YDB TPQUIT enforces per-frame transaction balance). |
| **L9** | v0.1.2 | STDMOCK | everything | ✅ **Shipped** in `v0.1.2` (commit `c582dc2`). Opt-in `invoke^STDMOCK` interception. 26/26 assertions; 7/7 labels (100%); 0 lint. |
| **L10** | v0.1.3 | STDSEED | works with STDFIX but does not require it | ✅ **Shipped** in `v0.1.3` (commit `bdd4ce9`). TSV manifest → pluggable filer (default `fileViaDie^STDSEED` calls `FILE^DIE`). 25/25 assertions; 10/11 labels (90.9% — `fileViaDie` real-FileMan path pending v0.1.4). `loadJson` is a stub raising `U-STDSEED-NOT-IMPLEMENTED` until L11 (STDJSON) ships in Phase 2. |

✅ **Phase 1b closed.** All three stdlib tracks shipped and rolled up
alongside Phase 1 in the v0.1.x series. Their m-cli companion tracks
(W/X/Y in §3.4) all landed together in m-cli `e5818bd`, closing M1.

### 3.3 m-stdlib Phase 2 — pure-M heavy lifting

All four tracks mutually independent. Two follow-on add-ons (L4
STDLOG-JSON and L10 STDSEED-loadJson) ride the same `v0.2.0`
boundary and depend on L11.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L11** | v0.2.0 | STDJSON | everything | ✅ **Landed on `main`** (commit `4144130`); awaits `v0.2.0` tag. RFC 8259 parser + serialiser; consumes the curated A3 corpus at `tests/conformance/json/`. Storage convention: one M tree node per JSON value (`o` / `a` / `s:` / `n:` / `t` / `f` / `z`). |
| **L12** | v0.2.0 | STDREGEX | everything | ✅ **Landed on `main`; gates closed** (target tag `v0.2.0`). API skeleton + TDD-red staked (`fb2fda9`); Pass A lexer/parser → AST (`cfce923`); Pass B Thompson NFA + `raise()` helper fix for the long-latent `$ECODE`/`$ETRAP`/M17 corruption (`3abf7e8`); Pass C Pike-style match/search/find (`491eb38`); Pass D capture groups + greedy semantics via parallel cap-aware simulator (`c51a394`); Pass E findall / replace / split with `\1..\9` backref expansion (`48da86e`); docs/CHANGELOG/status updates (`3ada83d`). **STDREGEXTST 90/90 assertions green; coverage 98.3% (58/59 labels); 0 lint errors.** Module doc at `docs/modules/stdregex.md`. Out-of-scope features rejected with `U-STDREGEX-UNSUPPORTED`. Engine is pure-M and runs on IRIS today; native `$MATCH` / `$LOCATE` translation for the simple-pattern subset deferred to a future IRIS pass (fail-soft via `iris-portability-check` CI job). The L12 raise()-helper pattern was back-ported into STDFMT and STDARGS in commit `8c0b419`. Only outstanding item: v0.2.0 sync. |
| **L13** | v0.2.0 | STDCOLL | everything | ✅ **Landed on `main`** (commit `232ecb8`); awaits `v0.2.0` tag. Set/Map/Stack/Queue/Deque/Heap/OrderedDict over caller-owned arrays. 116/116 assertions; 51/51 labels (100%); 0 lint. |
| **L14** | v0.2.0 | STDURL | everything | ✅ **Landed on `main`** (commit `232ecb8`); awaits `v0.2.0` tag. RFC 3986 parse / build / encode / decode / valid / normalize / resolve. 150/150 assertions; 21/21 labels (100%); 0 lint. RFC 3986 §5.4 reference-resolution corpus at `tests/conformance/url/`. STDHTTP consumes in Phase 3. |
| **L4 add-on** | v0.2.0 | STDLOG `FORMAT(kv\|json)` | depends on L11 | ✅ **Landed on `main`** (commit `8f7c3ba`). New public extrinsic `FORMAT^STDLOG(name)` selects line format: `"kv"` (default) or `"json"` (one RFC-8259 object per log line, built via `$$encode^STDJSON`). Bad format names raise `,U-STDLOG-INVALID-FORMAT,`. Gate: 47/47 kv-path assertions green; the 7 JSON-emission `raises` tests are defined in suite but withheld from the driver pending the STDASSERT.raises P1 / extrinsic-chain crash (TOOLCHAIN-FINDINGS). Implementation ships intact. |
| **L10 add-on** | v0.2.0 | STDSEED `loadJson` | depends on L11 | ✅ **Landed on `main`** (commit `dad6cd1`). Replaces the v0.1.3 `U-STDSEED-NOT-IMPLEMENTED` stub. `loadJson^STDSEED(jsonText,filer)` parses via `$$parse^STDJSON`, expects an array of `{"file":<string>,"fields":{...}}` objects, dispatches each via `filer` (default `fileViaDie`). New error codes: `,U-STDSEED-INVALID-JSON,`, `,U-STDSEED-INVALID-MANIFEST,`. Six new tests defined in suite; the four `raises`-path tests are withheld from the driver under the same STDASSERT.raises P1 blocker as the L4 add-on. Implementation ships intact. |

**Phase 2 status:** all 4 modules + both v0.2.0 add-ons landed on
`main` with gates closed (L11 STDJSON observed-healthy, L12 STDREGEX
engine + gates, L13 STDCOLL, L14 STDURL, L4 STDLOG `FORMAT`, L10
STDSEED `loadJson`). The `v0.2.0` tag is now blocked **only** on the
joint release sync — every member track has shipped to `main`. The
parking-lot test re-enable (raises-path bodies for L4 / L10 / STDFMT /
STDDATE / STDCSV) waits on the open STDASSERT.raises P1 in
TOOLCHAIN-FINDINGS and is **not** a release-tag blocker.

### 3.3b m-stdlib Phase 4 — Table 2 promotions (post-`v0.2.0`)

Phase 4 covers modules promoted out of `docs/module-tracker.md`
Table 2 ahead of (or alongside) the Phase 3 callout work. They
share the `v0.2.0` boundary: they ship in the same release window
but are not gating the tag itself.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L15** | v0.2.x | STDCSPRNG | everything (delegates to STDB64 / STDHEX / STDUUID) | ✅ **Landed on `main` 2026-05-07.** First Table 2 promotion (was Pri 1). Public surface: `bytes` / `hex` / `base64` / `token` / `int` / `uuid4` / `available`. Entropy from `/dev/urandom` (kernel ChaCha20 CSPRNG); single-byte `READ *b` loop avoids record-terminator truncation. `int` rejection-samples on the smallest power of 256 ≥ range (no modulo bias). 405/405 assertions; 7/7 labels (100%); 0 lint errors. Module doc at `docs/modules/stdcsprng.md`. The `$ZF → getrandom(2)` callout backend is reserved as a perf-only swap (T12) once Phase 3 cuts. |
| **L16** | v0.2.x | STDFS | everything | ✅ **Landed on `main` 2026-05-07.** Second Table 2 promotion (was Pri 2). Public surface: text-mode I/O (`readFile` / `writeFile` / `append` / `readLines` / `writeLines`); existence + metadata (`exists` / `remove` / `size`); pure-string path manipulation (`basename` / `dirname` / `join`). `exists()` uses an `$ETRAP+ZGOTO $zlevel` OPEN-probe to bypass the `$ZSEARCH` per-process cache. `writeFile` always emits a trailing LF (POSIX text-file convention; readFile strips it on the way back). `append()` is read-then-rewrite to sidestep a YDB SEQ APPEND-mode position quirk — native append + binary-safe `readBytes`/`writeBytes` queued at T13/T14 alongside the `$ZF → libc` callout backend. 39/39 assertions; 12/12 labels (100%); 0 lint errors. Module doc at `docs/modules/stdfs.md`. |

### 3.4 m-cli companion tracks

Three categories:

**Independent of stdlib (start any time):**

| Track | Capability | Independent of | Notes |
|---|---|---|---|
| **C1** | TOOLCHAIN P1 fix: drop `^TESTRUN` hardcode in single-test runner | everything | ✅ **Shipped 2026-05-05** (m-cli `23241a2`) — `m_cli.test.discovery.detect_protocol(src)` scans for `do start^XYZ(.pass,.fail)` and records the assertion-library routine on each `TestCase.protocol` (defaults to `TESTRUN` for backwards compatibility); `run_case` invokes `do start^{protocol}` / `do report^{protocol}` so STDASSERT-driven suites work via single-test selection without source edits. Closes the m-stdlib P1 TOOLCHAIN-FINDINGS row. |
| **C2** | `m test --format=junit` | everything | ✅ **Shipped 2026-05-05** (m-cli `23241a2`) — `_write_junit()` in `m_cli.test.output` emits Jenkins-style XML over the parsed `RunResult` list. `--format` choices are `text` / `tap` / `json` / `junit` in `m_cli.cli`. |
| **C3** | `m test --coverage-min N` / `m coverage --min-percent N` | everything | ✅ **Shipped 2026-05-05** (m-cli `23241a2`) — `m coverage --min-percent N` exits 1 when measured coverage is below the threshold; threshold echoed in text mode and surfaced as `min_percent` in JSON output. |
| **C4** | `m coverage --branch` | everything | ✅ **MVP shipped 2026-05-05** (m-cli `23241a2`) — branch-reach detection (line-level), text/JSON/LCOV output. True/false outcome split deferred (needs ZBREAK-style per-command instrumentation). |
| **C5** | `m test --changed` | everything | ✅ **Shipped 2026-05-05** (m-cli `23241a2`) — git-status / git-diff backed; reuses `m watch` affinity. `--changed-base REV` for diffing against a revision. |

**Hard-blocked on a specific stdlib module (start when that module ships):**

| Track | Capability | Blocked on | Notes |
|---|---|---|---|
| **W** | Runner SETUP/TEARDOWN wrap | L8 (STDFIX) ships | ✅ **Shipped** in m-cli (commit `e5818bd`) — STDFIX-style per-test transactional isolation in the runner loop. |
| **X** | Runner `CLEAR^STDMOCK` between tests | L9 (STDMOCK) ships | ✅ **Shipped** in m-cli (commit `e5818bd`) — `do clear^STDMOCK` between tests. |
| **Y** | `m test --seed PATH` | L10 (STDSEED) ships | ✅ **Shipped** in m-cli (commit `e5818bd`) — `--seed PATH` flag (repeatable) loads STDSEED TSV manifests before each test. |

W, X, Y all landed together in m-cli `e5818bd`, closing M1 across all
three (stdlib, m-cli) pairs.

**Hard-blocked on parent plan (vista-orchestration):**

| Track | Capability | Blocked on |
|---|---|---|
| **C6** | `m test --integration` | parent plan Phase 4 (integration harness) |

### 3.5 Auxiliary stdlib tracks (zero-dep on any module)

| Track | Work | Independent of | Notes |
|---|---|---|---|
| **A1** | Vendor RFC-4648 §10 vectors → `tests/conformance/b64/` | everything | ✅ **Done** — TSVs (standard + URL-safe) + README; landed alongside L1. |
| **A2** | Vendor RFC-4180 corpus → `tests/conformance/csv/` | everything | ✅ **Done** — 10 CSV fixtures (every §2 clause + extensions) + README; landed alongside L6. |
| **A3** | Vendor JSONTestSuite → `tests/conformance/json/` | everything | ✅ **Done** — curated subset (23 `y_`, 15 `n_`, 8 `i_` files) + README mapping each file to an RFC-8259 clause. Full ~318-file JSONTestSuite intentionally not vendored. |
| **A4** | Vendor RFC-4122 UUID vectors → `tests/conformance/uuid/` | everything | ✅ **Done** — `rfc4122-vectors.tsv` (27 rows: every version 1–8, all four variants, mixed/upper case, malformed-input rejections) + README. Reinforces v0.0.1 STDUUID. |
| **A5** | IRIS portability CI job re-add (fail-soft) | everything | ✅ **Done** — `iris-portability-check` job in `.github/workflows/ci.yml`, `continue-on-error: true`, runs on PRs only against `intersystemsdc/iris-community:latest`. |
| **A6** | `tools/build-callouts.sh` for $ZF SOs (linux-x86_64, linux-aarch64, macOS) | everything | ✅ **Done** — bash script, platform auto-detect (linux-x86_64 / linux-aarch64 / darwin-x86_64 / darwin-arm64), `--check` / `--clean` / `--target=` flags; smoke-test fixture at `src/callouts/probe.c`; output gitignored. |
| **A7** | `docs/modules/<m>.md` per module | the module itself | ✅ **Done** — every shipped or in-progress module has its doc (stdassert, stduuid, stdb64, stdhex, stdfmt, stdlog, stddate, stdcsv, stdargs, stdmock, stdfix, stdseed, stdjson, stdregex, stdcoll, stdurl). Phase 3 modules add theirs as they land. Top-level `docs/users-guide.md` (commit `d6654c3`) provides a TDD-first walkthrough across the v0.1.x / v0.2.0 surface. |

### 3.6 STDASSERT real-project migration tracks (per impl-plan §10.2)

Migrations of `^TESTRUN`-using test suites onto STDASSERT. The
plan originally named V1 / V2 / V3 against m-cli, tree-sitter-m,
and m-standard, but those three projects ship no M-side test
suites at all. The actual real-project STDASSERT consumer turned
out to be **m-tools** (whose homegrown `^TESTRUN.m` runner
predated STDASSERT by ~5 weeks), tracked retroactively as **V4**.

| Track | Repo | Status |
|---|---|---|
| **V1** | m-cli — migrate M-side tests onto STDASSERT | ✅ **Verified no-op 2026-05-05.** m-cli has zero `*TST.m` routines outside `tests/fixtures/` (which are SAC/parser fixtures, not test suites). m-cli's tests are pure pytest in Python; the M side is invoked at runtime by the `m test` runner, not via static suites. The C1 fix (m-cli `23241a2`) made the runner protocol-aware so STDASSERT-driven suites in *consumer* projects (m-stdlib, m-tools) work end-to-end — that is the actual TOOLCHAIN P1 closure. |
| **V2** | tree-sitter-m — migrate `tests/` if any M-side suites use TESTRUN | ✅ **Verified no-op 2026-05-05.** tree-sitter-m's `test/` directory holds the tree-sitter grammar corpus (`corpus/*.txt` parser test cases + `coverage/keywords.m` token-coverage fixture) — no M-side test routines, no `TESTRUN` references anywhere in the tree. |
| **V3** | m-standard — migrate any `tests/` suites | ✅ **Verified no-op 2026-05-05.** m-standard's `tests/` directory is exclusively pytest (Python). The M code in `sources/` is the SAC / YDB / IRIS reference corpus being catalogued, not test suites for m-standard itself. The lone `TESTRUN` hit in `docs/m-libraries-remediation.md` is a reference to the legacy library — no source to migrate. |
| **V4** | m-tools — migrate suites from homegrown `^TESTRUN.m` to `^STDASSERT` | ✅ **Shipped 2026-05-06** (m-tools commit `3eec0bf`). Mechanical rename across all 11 suites: `CSVTST`, `GLOBALTST`, `GTREETST`, `HELLOTST`, `IDXTST`, `JSONTST`, `SAFETST`, `STRFNSTST`, `TASKSTST`, `TXNTST`, `VALIDATETST` — `do start^TESTRUN(.pass,.fail)` / `do eq^TESTRUN(.pass,.fail,...)` / `do report^TESTRUN(pass,fail)` → STDASSERT equivalents. API parity exact, suite bodies untouched. `routines/tests/TESTRUN.m` deleted. Backstory: m-tools shipped its own no-deps `^TESTRUN.m` scaffold runner from its initial commit `41ed967` (2026-03-24) — ~5 weeks before STDASSERT existed. The migration was performed in a prior session but sat uncommitted in m-tools' working tree until 2026-05-06. **This is the impl-plan §10.1 item-4 "adjacent-project consumption" gate for STDASSERT.** |

### 3.7 Parent-plan tracks orthogonal to m-stdlib (FYI)

These don't touch m-stdlib but unblock its consumers. Listed for
completeness.

| Track | Work | Owner repo | Status |
|---|---|---|---|
| **P1** | tree-sitter-m v0.1 publish + prebuildify binaries | tree-sitter-m | ⚠️ **Prep done; publish user-gated.** Pre-flight runbook lives in `tree-sitter-m/RELEASE.md`; prebuildify CI workflow shipped at `.github/workflows/prebuilds.yml` (matrix builds Linux/macOS/Windows × x64/arm64 prebuilt N-API binaries on tag push, attaches to GitHub Release). Actual `npm publish` / `cargo publish` / `twine upload` requires registry credentials (npm 2FA, cargo token, PyPI API token) that only the maintainer holds — irreversible once done, so cannot be automated from a session. To complete: maintainer runs §0–§7 of RELEASE.md from a clean `main`. |
| **P2** | vista-meta README.md | vista-meta | ✅ **Shipped 2026-05-05** — `vista-meta/README.md` authored as a thin landing page pointing at `docs/vista-meta-guide.md`. Covers thesis, ships table, requirements, quick-start, runtime layout, doc index, PIKS one-paragraph summary, license, and companion projects. Closes the `docs.primary` gap noted in the project descriptor. |
| **P3** | m-modern-corpus seeding (5–10 non-VA M projects) | m-modern-corpus | ✅ **At floor of target range; closed.** 5 non-VA M projects, 4,215 routines, ~14 MB total: `ewd/` 86, `mgsql/` 36, `m-web-server/` 23, `ydbocto-aux/` 21, `ydbtest/` 4,049. Per the corpus CLAUDE.md this is a one-time snapshot — re-sync deliberately if upstreams ship material changes. Growing toward 10 is a separate, scope-bounded decision (which projects, license review). |

---

## 4. Execution snapshot (today, 2026-05-05 EOD)

State of the dispatch board. Tags `v0.0.1` and `v0.1.0` are the only
two cut in git so far — every intermediate `v0.0.x` / `v0.1.x` and
the entire `v0.2.0`-eligible body of work exists as labelled commits
on `main` awaiting their tags at the next release boundary.

```
Phase 1   (L1–L7, L4b)                       ✅ ALL SHIPPED — rolled up under v0.1.0
Phase 1b  (L8, L9, L10)                      ✅ ALL SHIPPED — v0.1.1 / v0.1.2 / v0.1.3
Phase 2   L11 STDJSON                        ✅ landed on main (awaits v0.2.0 tag)
          L12 STDREGEX                       ✅ engine + gates closed; raise-helper back-ported to STDFMT/STDARGS
          L13 STDCOLL                        ✅ landed on main (awaits v0.2.0 tag)
          L14 STDURL                         ✅ landed on main (awaits v0.2.0 tag)
          L4  STDLOG FORMAT(kv|json) add-on  ✅ landed on main (8f7c3ba) — JSON-emission tests parked under STDASSERT.raises P1
          L10 STDSEED loadJson add-on        ✅ landed on main (dad6cd1) — replaces v0.1.3 stub; raises tests parked under same P1
Phase 4   L15 STDCSPRNG                      ✅ landed on main 2026-05-07 — first Table 2 promotion (was Pri 1); /dev/urandom backend
          L16 STDFS                          ✅ landed on main 2026-05-07 — second Table 2 promotion (was Pri 2); text-mode YDB-only v1
m-cli     C1 dynamic ^TESTRUN protocol       ✅ shipped
          C2 --format=junit                  ✅ shipped
          C3 --coverage-min / --min-percent  ✅ shipped
          C4 --branch coverage MVP           ✅ shipped 2026-05-05
          C5 --changed                       ✅ shipped 2026-05-05
          W / X / Y                          ✅ shipped (m-cli e5818bd) — closes M1
          C6 --integration                   — blocked on parent-plan Phase 4
Aux       A1, A2, A3, A4, A5, A6, A7         ✅ ALL DONE
STDASSERT V1, V2, V3                         ✅ ALL VERIFIED NO-OP 2026-05-05 (see §3.6) — no M-side suites in m-cli / tree-sitter-m / m-standard
          V4 m-tools migration               ✅ shipped 2026-05-06 (m-tools `3eec0bf`) — 11 suites migrated TESTRUN→STDASSERT; TESTRUN.m deleted
Parent    P1 tree-sitter-m v0.1 publish      ⚠️ prebuildify CI shipped; publish user-gated (registry creds)
          P2 vista-meta README.md            ✅ shipped 2026-05-05
          P3 m-modern-corpus seeding         ✅ at floor of 5–10 (5 projects, 4,215 routines)
Docs      users-guide.md                     ✅ shipped 2026-05-05 (commit d6654c3) — TDD-first stdlib walkthrough
```

**There is no remaining open development work for the `v0.2.0`
release.** The four Phase 2 modules and both v0.2.0 add-ons (L4 +
L10) have all landed on `main`. The release tag itself is the only
synchronisation point left — the joint sync (CHANGELOG roll-up,
GitHub Release, version bump in module banners) is queued behind
maintainer dispatch.

The two open development items that are **not** v0.2.0 blockers:

1. **STDASSERT.raises P1** (TOOLCHAIN-FINDINGS, surfaced 2026-05-05):
   `$ETRAP` arg-less `quit` is illegal in extrinsic-function chains
   and triggers `M17 NOTEXTRINSIC` cascading into `Z150374554`.
   Footprint: STDFMT (6 tests), STDDATE, STDCSV, STDLOG L4 add-on
   (7 tests), STDSEED L10 add-on (4 tests). The implementations
   themselves all ship; only the `raises`-path *tests* are parked
   in the suite, withheld from the driver. Fix candidates: `ZGOTO
   N:label` unwind, or a parallel `raisesx^STDASSERT` that is
   extrinsic-aware.
2. **m-cli single-test mode regression P1** (TOOLCHAIN-FINDINGS,
   surfaced 2026-05-05): post-C1 `m test FILE.m::tLabel` exits with
   rc=253 and empty stdio against any STDASSERT-driven suite (same
   shape as the documented `$GET($ECODE)` silent-crash signature).
   Whole-suite mode of the same suites is healthy. Needs in-process
   stderr capture in m-cli's child-process wrapper.

Phase 3 cannot start until the v0.2.0 release sync closes and the
build-callouts harness (A6 — already shipped) is exercised by its
first consumer.

What you **cannot** parallelise:

- W, X, Y on top of L8, L9, L10 (each is hard-blocked on its stdlib
  pair, but the three pairs are independent of each other).
- L4-bump on top of L5 (trivial follow-on).
- STDHTTP on STDURL (Phase 3 → Phase 2 edge).
- STDHTTP / STDCRYPTO / STDCOMPRESS on `tools/build-callouts.sh`
  (one-time infra, then those three are mutually parallel).
- Phase release tags (v0.1.0 / v0.2.0 / v0.3.0) on **all** their
  member tracks — release is the synchronisation point.
- m-cli `--integration` (C6) on parent-plan Phase 4.

---

## 5. Synchronisation points

Where parallelism ends and a join is required:

| Sync | What joins | Why |
|---|---|---|
| **v0.1.0 release** ✅ | L1–L7 (and L4-bump after L5) | Phase 1 release tag; CHANGELOG roll-up; GitHub Release |
| **M1 close** ✅ | L8 + W; L9 + X; L10 + Y | Each (stdlib, m-cli) pair must ship together for the runner protocol to work. All three pairs landed (W/X/Y in m-cli `e5818bd`). |
| **v0.2.0 release** | L11–L14 + STDLOG-JSON add-on (L4) + STDSEED-JSON add-on (L10) | Phase 2 release tag — **all member tracks landed on `main` 2026-05-05; awaiting tag dispatch only.** |
| **Phase 3 entry** | A6 (build harness) before STDHTTP / STDCRYPTO / STDCOMPRESS | Build infra must work before any Phase 3 track starts |
| **v0.3.0 release** | All Phase 3 tracks + jwt-verify example | Phase 3 release |
| **v1.0.0** | 3 months of API stability after v0.3.0 | Time-based, not work-based |

---

## 6. Pick-list — what to dispatch right now

Phase 1, 1b, and **all four Phase 2 modules plus both v0.2.0 add-ons**
are on `main`. There is no remaining stdlib *development* work
queueing for `v0.2.0`. The dispatch board reduces to:

**Highest leverage** (cuts the v0.2.0 release tag):

- **v0.2.0 release sync** — CHANGELOG `[Unreleased]` → `[v0.2.0]`
  collapse, version bump in module banners, GitHub Release notes,
  `git tag v0.2.0`. Every member track has landed on `main`; this
  is a maintainer dispatch step. See §5 sync table.

**Toolchain debt that *does not* gate v0.2.0 but blocks the parked
test bodies:**

- **STDASSERT.raises P1** (TOOLCHAIN-FINDINGS) — fix `$ETRAP` arg-less
  `quit` cascade in extrinsic-function chains. Once shipped, re-enable
  the parked `raises`-path tests in STDFMT (6), STDDATE, STDCSV,
  STDLOG L4 add-on (7), STDSEED L10 add-on (4). Implementations all
  ship; only the test bodies are withheld.
- **m-cli single-test mode P1** (TOOLCHAIN-FINDINGS) — post-C1
  regression: `m test FILE.m::tLabel` exits rc=253 with empty stdio
  on any STDASSERT-driven suite. Whole-suite mode unaffected. Needs
  in-process stderr capture in m-cli's child-process wrapper.

**M1 closed** (W, X, Y all shipped in m-cli `e5818bd`):

- ✅ **m-cli W** — `with`/`invoke` wrap in the runner loop (consumes
  `STDFIX`).
- ✅ **m-cli X** — `do clear^STDMOCK` between tests (consumes `STDMOCK`).
- ✅ **m-cli Y** — `m test --seed PATH` flag (consumes `STDSEED`).

**m-cli enhancements** (independent of any stdlib work) — all shipped:

- ✅ **C1** — `^TESTRUN` hardcode dropped from m-cli single-test runner;
  protocol resolves dynamically per suite (TOOLCHAIN P1 fix).
- ✅ **C2** — `m test --format=junit`.
- ✅ **C3** — `m coverage --min-percent N`.
- ✅ **C4** — `m coverage --branch` MVP.
- ✅ **C5** — `m test --changed`.

**STDASSERT migrations** (real-project consumers per §3.6):

- ✅ **V1** — m-cli has no M-side test suites to migrate (verified no-op).
- ✅ **V2** — tree-sitter-m has no M-side test suites to migrate (verified no-op).
- ✅ **V3** — m-standard has no M-side test suites to migrate (verified no-op).
- ✅ **V4** — m-tools migration shipped 2026-05-06 (m-tools commit
  `3eec0bf`): 11 suites renamed TESTRUN→STDASSERT, `routines/tests/
  TESTRUN.m` deleted. Closes the impl-plan §10.1 item-4
  "adjacent-project consumption" gate for STDASSERT.

**Parent-plan adjacent** (orthogonal, don't gate stdlib):

- ⚠️ **P1** — tree-sitter-m v0.1 publish (prebuildify CI shipped;
  publish itself user-gated on registry credentials).
- ✅ **P2** — vista-meta `README.md` (shipped 2026-05-05).
- ✅ **P3** — m-modern-corpus seeding at floor (5 projects).

**Phase 3 is queued** (do not start until v0.2.0 cuts):

STDHTTP, STDCRYPTO, STDCOMPRESS, plus the jwt-verify example. The
build-callouts harness (A6) shipped already, so Phase 3 has no
remaining infra prereq beyond the v0.2.0 release sync.

---

## 7. Conventions for parallel work

So multiple tracks can land without stomping each other:

- **CHANGELOG.md fragments per track.** Each track adds a single
  bullet under an `## Unreleased` heading; the maintainer collapses
  them into the next tag's section at release time.
- **Plan §1 status table.** Each track edits exactly its own row;
  conflicts are line-level and trivial to resolve.
- **TODO.md.** Avoid editing during track work. Update only at
  milestone close.
- **TOOLCHAIN-FINDINGS.md.** Append-only during track work; renumber
  at milestone close.
- **`docs/modules/index.md`** (when it exists). Each track adds its
  own row; index regeneration at v0.1.0 / v0.2.0 / v0.3.0 release
  time absorbs the table.
- **m-cli companion PRs** ride alongside their stdlib track but live
  in `~/projects/m-cli/`. Track owner opens both branches, merges
  stdlib first, then m-cli.

---

## 8. Cross-references

- [tdd-orchestration-plan.md](tdd-orchestration-plan.md) — joint milestone narrative; this doc is the dispatch view.
- [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md) — per-module specs and §9 acceptance gate; this doc references them by track.
- [TOOLCHAIN-FINDINGS.md](../TOOLCHAIN-FINDINGS.md) — open m-cli / tree-sitter-m issues; track C1 closes the P1.
- [../../m-cli/TODO.md](../../m-cli/TODO.md) — m-cli's own track list (C1–C5 land here as work begins).
- [../../vista-meta/docs/vista-orchestration-plan.md](../../vista-meta/docs/vista-orchestration-plan.md) — parent plan; tracks P1–P3 belong to its scope.
