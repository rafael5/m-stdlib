---
title: m-stdlib — parallel execution tracks
status: live (2026-05-05)
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

All four tracks mutually independent.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L11** | v0.2.0 | STDJSON | everything | ✅ **Landed on `main`** (commit `4144130`); awaits `v0.2.0` tag. RFC 8259 parser + serialiser; consumes the curated A3 corpus at `tests/conformance/json/`. Storage convention: one M tree node per JSON value (`o` / `a` / `s:` / `n:` / `t` / `f` / `z`). |
| **L12** | v0.2.0 | STDREGEX | everything | ✅ **Landed on `main`; gates closed** (target tag `v0.2.0`). API skeleton + TDD-red staked (`fb2fda9`); Pass A lexer/parser → AST (`cfce923`); Pass B Thompson NFA + `raise()` helper fix for the long-latent `$ECODE`/`$ETRAP`/M17 corruption (`3abf7e8`); Pass C Pike-style match/search/find (`491eb38`); Pass D capture groups + greedy semantics via parallel cap-aware simulator (`c51a394`); Pass E findall / replace / split with `\1..\9` backref expansion (`48da86e`); docs/CHANGELOG/status updates (`3ada83d`). **STDREGEXTST 90/90 assertions green; coverage 98.3% (58/59 labels); 0 lint errors.** Module doc at `docs/modules/stdregex.md`. Out-of-scope features rejected with `U-STDREGEX-UNSUPPORTED`. Engine is pure-M and runs on IRIS today; native `$MATCH` / `$LOCATE` translation for the simple-pattern subset deferred to a future IRIS pass (fail-soft via `iris-portability-check` CI job). Only outstanding item: v0.2.0 sync. |
| **L13** | v0.2.0 | STDCOLL | everything | ✅ **Landed on `main`** (commit `232ecb8`); awaits `v0.2.0` tag. Set/Map/Stack/Queue/Deque/Heap/OrderedDict over caller-owned arrays. 116/116 assertions; 51/51 labels (100%); 0 lint. |
| **L14** | v0.2.0 | STDURL | everything | ✅ **Landed on `main`** (commit `232ecb8`); awaits `v0.2.0` tag. RFC 3986 parse / build / encode / decode / valid / normalize / resolve. 150/150 assertions; 21/21 labels (100%); 0 lint. RFC 3986 §5.4 reference-resolution corpus at `tests/conformance/url/`. STDHTTP consumes in Phase 3. |

**Phase 2 status:** all 4 tracks landed on `main` with gates closed
(L11 STDJSON observed-healthy, L12 STDREGEX engine + gates, L13
STDCOLL, L14 STDURL). `v0.2.0` tag waits on the L4 / L10 add-ons
listed in §5 plus the joint sync.

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
| **A7** | `docs/modules/<m>.md` per module | the module itself | ✅ **Done** — every shipped or in-progress module has its doc (stdassert, stduuid, stdb64, stdhex, stdfmt, stdlog, stddate, stdcsv, stdargs, stdmock). Phase 2/3 modules add theirs as they land. |

### 3.6 STDASSERT real-project migration tracks (per impl-plan §10.2)

Three independent migrations: STDASSERT consumed by adjacent
projects' test suites in place of `^TESTRUN`. Each is its own track;
none touch each other.

| Track | Repo | Notes |
|---|---|---|
| **V1** | m-cli — migrate M-side tests onto STDASSERT | Closes one of the TOOLCHAIN P2 entries |
| **V2** | tree-sitter-m — migrate `tests/` if any M-side suites use TESTRUN | Check `tests/` |
| **V3** | m-standard — migrate any `tests/` suites | Probably no-op; verify |

### 3.7 Parent-plan tracks orthogonal to m-stdlib (FYI)

These don't touch m-stdlib but unblock its consumers. Listed for
completeness.

| Track | Work | Owner repo | Status |
|---|---|---|---|
| **P1** | tree-sitter-m v0.1 publish + prebuildify binaries | tree-sitter-m | ⚠️ **Prep done; publish user-gated.** Pre-flight runbook lives in `tree-sitter-m/RELEASE.md`; prebuildify CI workflow shipped at `.github/workflows/prebuilds.yml` (matrix builds Linux/macOS/Windows × x64/arm64 prebuilt N-API binaries on tag push, attaches to GitHub Release). Actual `npm publish` / `cargo publish` / `twine upload` requires registry credentials (npm 2FA, cargo token, PyPI API token) that only the maintainer holds — irreversible once done, so cannot be automated from a session. To complete: maintainer runs §0–§7 of RELEASE.md from a clean `main`. |
| **P2** | vista-meta README.md | vista-meta | ✅ **Shipped 2026-05-05** — `vista-meta/README.md` authored as a thin landing page pointing at `docs/vista-meta-guide.md`. Covers thesis, ships table, requirements, quick-start, runtime layout, doc index, PIKS one-paragraph summary, license, and companion projects. Closes the `docs.primary` gap noted in the project descriptor. |
| **P3** | m-modern-corpus seeding (5–10 non-VA M projects) | m-modern-corpus | ✅ **At floor of target range; closed.** 5 non-VA M projects, 4,215 routines, ~14 MB total: `ewd/` 86, `mgsql/` 36, `m-web-server/` 23, `ydbocto-aux/` 21, `ydbtest/` 4,049. Per the corpus CLAUDE.md this is a one-time snapshot — re-sync deliberately if upstreams ship material changes. Growing toward 10 is a separate, scope-bounded decision (which projects, license review). |

---

## 4. Execution snapshot (today, 2026-05-05)

State of the dispatch board after the morning's commits. Tags
`v0.0.1` and `v0.1.0` are the only two cut in git so far — every
intermediate `v0.0.x` / `v0.1.x` exists as a labelled commit on
`main` awaiting its tag at the next release boundary.

```
Phase 1   (L1–L7, L4b)                     ✅ ALL SHIPPED — rolled up under v0.1.0
Phase 1b  (L8, L9, L10)                    ✅ ALL SHIPPED — v0.1.1 / v0.1.2 / v0.1.3
Phase 2   L11 STDJSON                      ✅ landed on main (awaits v0.2.0 tag)
          L12 STDREGEX                     ✅ engine landed on main (awaits v0.2.0 tag; non-engine items in flight)
          L13 STDCOLL                      ✅ landed on main (awaits v0.2.0 tag)
          L14 STDURL                       ✅ landed on main (awaits v0.2.0 tag)
m-cli     C1 dynamic ^TESTRUN protocol     ✅ shipped
          C2 --format=junit                ✅ shipped
          C3 --coverage-min / --min-percent ✅ shipped
          C4 --branch coverage MVP         ✅ shipped 2026-05-05
          C5 --changed                     ✅ shipped 2026-05-05
          W / X / Y                        ✅ shipped (m-cli e5818bd) — closes M1
          C6 --integration                 — blocked on parent-plan Phase 4
Aux       A1, A2, A3, A4, A5, A6, A7       ✅ ALL DONE
STDASSERT V1, V2, V3                       — see §3.6
Parent    P1 tree-sitter-m v0.1 publish    ⚠️ prebuildify CI shipped; publish user-gated (registry creds)
          P2 vista-meta README.md          ✅ shipped 2026-05-05
          P3 m-modern-corpus seeding       ✅ at floor of 5–10 (5 projects, 4,215 routines)
```

Active stdlib work right now reduces to **L12 STDREGEX non-engine
items** (coverage gate, real-project validation, IRIS dispatch)
plus the v0.2.0 add-ons listed in §5 (STDLOG JSON-line output,
STDSEED `LOADJSON`). Everything else of `v0.2.0`-eligible work is
already on `main`. Phase 3 cannot start until the v0.2.0 release
sync closes and the build-callouts harness (A6 — already shipped)
is exercised by its first consumer.

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
| **v0.2.0 release** | L11–L14 + STDLOG-JSON add-on + STDSEED-JSON add-on | Phase 2 release tag |
| **Phase 3 entry** | A6 (build harness) before STDHTTP / STDCRYPTO / STDCOMPRESS | Build infra must work before any Phase 3 track starts |
| **v0.3.0 release** | All Phase 3 tracks + jwt-verify example | Phase 3 release |
| **v1.0.0** | 3 months of API stability after v0.3.0 | Time-based, not work-based |

---

## 6. Pick-list — what to dispatch right now

Phase 1, 1b, and three of four Phase 2 modules are on `main`. The
zero-blocked, ready-to-dispatch tracks today are:

**Highest leverage** (closes the v0.2.0 release tag):

- **L12 STDREGEX** — engine landed in commits `3abf7e8` (Pass B +
  raise-helper fix), `491eb38` (Pass C match/search/find),
  `c51a394` (Pass D captures + greedy), `48da86e` (Pass E
  findall/replace/split); STDREGEXTST 90/90 green. Per-module gate
  closed: `m coverage --min-percent=85` → **98.3%** label coverage;
  `m lint --error-on=error` → 0 errors for STDREGEX. Real-project
  validation closed: `m fmt --check` clean, lcov well-formed; LSP
  smoke deferred to the v0.2.0 release sync (interactive, but the
  same tree-sitter-m parser backs `m fmt`/`m lint` and both pass).
  Module doc shipped at `docs/modules/stdregex.md`. Remaining: IRIS
  `$MATCH`/`$LOCATE` translation (fail-soft, deferred to a future
  IRIS pass — engine is pure-M and runs on IRIS today; the
  translation is the optimisation, not a correctness requirement).
- **STDLOG JSON-line add-on** — small follow-on once L11 STDJSON is
  consumable; emits one JSON object per log line via `STDJSON.encode`.
- **STDSEED `LOADJSON` add-on** — replaces the
  `U-STDSEED-NOT-IMPLEMENTED` stub now that L11 has shipped.

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

**STDASSERT migrations** (real-project consumers per §3.6):

- **V1** — m-cli M-side tests onto STDASSERT (closes a TOOLCHAIN P2).
- **V2** — tree-sitter-m M-side tests (verify any exist).
- **V3** — m-standard test suites (likely no-op; verify).

**Parent-plan adjacent** (orthogonal, don't gate stdlib):

- **P1** — tree-sitter-m v0.1 publish + prebuildify binaries.
- **P2** — vista-meta `README.md`.
- **P3** — m-modern-corpus seeding.

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
