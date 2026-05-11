---
title: m-stdlib ↔ m-cli — TDD orchestration plan
status: proposed (2026-05-05)
companion: m-stdlib-implementation-plan.md (the existing per-module plan; this doc layers on top)
upstream: ~/projects/vista-meta/docs/vista-orchestration-plan.md
created: 2026-05-05
last_modified: 2026-05-08
revisions: 3
doc_type: [PLAN]
---

# m-stdlib ↔ m-cli — TDD orchestration plan

This is the cross-project coordination plan for m-stdlib and m-cli.
It carves the m-stdlib slice out of the parent
[vista-orchestration-plan](../../../vista-meta/docs/vista-orchestration-plan.md)
and sequences it against the m-cli capability work that has to land in
lockstep — because m-cli is the consumer of m-stdlib's TDD primitives.

m-stdlib **owns** this document; the per-module work plan continues
to live in [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md).
This file adds:

1. The new TDD primitives — `STDFIX`, `STDMOCK`, `STDSEED` — that the
   parent orchestration plan introduced and the existing
   implementation plan does not yet cover.
2. The m-cli capability table required to make those primitives
   actually run as part of `m test`.
3. The joint milestone sequence so each stdlib release ships with its
   matching m-cli consumer.

Everything in [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md)
remains authoritative for the existing Phase 1 / 2 / 3 modules
(`STDASSERT`, `STDUUID`, `STDB64`, `STDHEX`, `STDFMT`, `STDLOG`,
`STDDATE`, `STDCSV`, `STDARGS`, then `STDJSON`, `STDREGEX`, `STDCOLL`,
`STDURL`, then `STDHTTP`, `STDCRYPTO`, `STDCOMPRESS`). This plan does
not duplicate or override that scope.

---

## 1. Intent

Stand up an end-to-end TDD loop for M code:

```
edit .m  →  m fmt  →  m lint  →  m test (with fixtures + mocks)  →
m coverage (line + branch, gated)  →  m test --integration  →  CI
```

Today the language layer is ~80% there. The hard gap is **per-test
isolation, mocking, and seed data** — primitives every modern test
framework takes for granted but M has historically lacked. m-stdlib
is the natural home for those primitives; m-cli is the natural home
for the runner protocol that drives them.

This plan delivers them as a coordinated sequence so neither side
ships unusable artifacts.

---

## 2. Architectural relationship

The relationship is already locked in m-stdlib's CLAUDE.md:

> **m-stdlib has architectural priority over m-cli.** m-cli should
> consume m-stdlib utilities, not duplicate them.

Implications:

- **M-side runtime helpers** (assertions, fixtures, mocks, seed
  loaders, structured logs, JSON, regex, …) belong in m-stdlib.
  m-cli's M code calls into them.
- **Python-side tooling** (CLI, lint engine, runner orchestration,
  LSP, coverage post-processor, output formatters) belongs in m-cli.
  None of that lives in m-stdlib.
- **Coupling points** are documented protocols. STDFIX/STDMOCK/STDSEED
  each define a tiny M-side contract; m-cli's runner implements the
  Python side of that contract.
- **Migration policy.** When stdlib changes a contract, m-cli adapts
  via a companion PR in the same milestone. m-stdlib is never blocked
  on m-cli; m-cli's gate is "no open P0/P1 entries in
  TOOLCHAIN-FINDINGS.md" before public publication.

---

## 3. Current state (2026-05-05)

### m-stdlib

| Tag | Modules | Status |
|---|---|---|
| `v0.0.1` | STDASSERT (9 helpers + silent toggle), STDUUID (v4/v7) | Shipped 2026-04-30 |
| `v0.0.2` | STDB64 + STDHEX | In progress (STDB64 source landed; STDHEX next) |
| `v0.0.3` – `v0.0.7` | STDFMT, STDLOG, STDDATE, STDCSV, STDARGS | Specced; not started |
| `v0.1.0` | Phase 1 release | Pending |

### m-cli

| Tier | Capability | Status |
|---|---|---|
| 1 | `m fmt`, `m lint`, `m test`, single-test selection, `m watch` | Done (2026-04-27) |
| 2 | Coverage (`m coverage` text/lcov/json), pre-commit hooks, style profiles | Done |
| Cross-cutting | `m lsp` Stages 1+2+3+4+4b+B (diagnostics / fmt / code actions / hover / completion / outline / code lens / folding / sig help / highlight / definition / references / workspace index) | Done |
| 2 | DAP debugger | Deferred |

### Coupling points already touched

- m-cli `m test` discovery uses the parser-aware `t<UpperCase>(pass,fail)`
  contract. STDASSERT respects it — no runner change was needed for
  v0.0.1.
- m-cli's single-test runner hard-codes `^TESTRUN` (TOOLCHAIN P1).
  Migrating to STDASSERT-driven entry is on the m-cli side and is a
  prerequisite for the §6.4 runner protocol additions below.

---

## 4. Coupling points (where this plan creates new contracts)

| Contract | M side (m-stdlib) | Python side (m-cli) | Milestone |
|---|---|---|---|
| Assertion counter | `STDASSERT` (v0.0.1, shipped) | parsed via `TESTRUN` output protocol | M0 (done) |
| Per-test isolation | `SETUP^STDFIX(tag)`, `TEARDOWN^STDFIX(tag)`; wraps body in `TSTART …` / `TROLLBACK` | runner invokes SETUP before each test label and TEARDOWN after, regardless of pass/fail | **M1** |
| Mock registry | `REGISTER^STDMOCK(target,replacement)`, `CLEAR^STDMOCK` | runner calls `CLEAR^STDMOCK` between tests so mocks don't leak | **M1** |
| Seed data | `LOAD^STDSEED(manifest)` reads TSV/JSON of file→record fixtures and `FILE^DIE`s inside the active TSTART | runner exposes `m test --seed PATH` and `m test --integration --seed PATH` | **M1** |
| Coverage gate | (none — pure Python) | `m coverage --min-percent N`, `m test --coverage-min N` (composes coverage + gate in one call) | **M2** |
| JUnit output | (none) | `m test --format=junit` → JUnit XML | **M2** |
| Branch coverage | (none — needs tree-sitter-m branch nodes) | `m coverage --branch` instruments decision points via existing YDB TRACE | **M2** |
| Changed-only run | (none) | `m test --changed` uses `WorkspaceIndex` (m-cli already has it) or vista-meta `routine-calls.tsv` for reverse-dep closure | **M3** |
| Integration mode | `STDSEED` loads fixtures into a live YDB | `m test --integration` runs after install; pairs with vista-cli verify | **M3** |

---

## 5. Joint milestones

Each milestone is a paired (m-stdlib tag, m-cli capability) deliverable.

| # | m-stdlib | m-cli | Theme |
|---|---|---|---|
| **M0** | v0.0.1 (STDASSERT, STDUUID) — done | Tier 1 + Tier 2 base — done | Foundation |
| **M0.5** | v0.0.2 → v0.1.0 (STDB64, STDHEX, STDFMT, STDLOG, STDDATE, STDCSV, STDARGS) — existing plan | TOOLCHAIN P1 fix: drop hard-coded `^TESTRUN`; STDASSERT-aware single-test entry | Phase 1 ship |
| **M1** | v0.1.1 (STDFIX), v0.1.2 (STDMOCK), v0.1.3 (STDSEED) | Runner protocol: SETUP/TEARDOWN, CLEAR^STDMOCK between tests, `--seed PATH` | **TDD primitives** |
| **M2** | v0.1.4 (real-project validation: migrate m-stdlib's own tests onto STDFIX) | `--format=junit`, `--coverage-min N`, `--branch` (branch coverage) | **CI output + gates** |
| **M3** | v0.1.5 (STDSEED hardening: large fixtures, multi-file manifests) | `m test --changed`, `m test --integration` | **Changed-only + integration** |
| **M4** | v0.2.0 (Phase 2: STDJSON, STDREGEX, STDCOLL, STDURL — existing plan) | LSP signature help refreshed with stdlib hover docs | Phase 2 ship |
| **M5** | v0.3.0 (Phase 3: STDHTTP, STDCRYPTO, STDCOMPRESS — existing plan) | DAP debugger (Tier 2 #10, currently deferred) — re-evaluate | Phase 3 + debugger |

M0.5 is the existing m-stdlib Phase 1 with one m-cli companion fix.
**M1–M3 are net new** and are the substance of this plan.

---

## 6. Phase 1b — TDD primitives (M1)

Three new pure-M modules slotting between the existing v0.1.0 (Phase
1 release) and v0.2.0 (Phase 2 start). Each is small (≤ 400 LoC of M)
and each pairs with a tightly-scoped m-cli runner change.

### 6.1 STDFIX — fixture lifecycle and per-test isolation

**Tag:** `v0.1.1`. **Routine:** `STDFIX.m`. **Est. LoC:** 250 + 80
tests.

**Public API (sketch):**

```m
SETUP^STDFIX(tag)        ; opens TSTART, registers tag in ^STDLIB($J,"FIX")
TEARDOWN^STDFIX(tag)     ; TROLLBACK to the matching savepoint
WITH^STDFIX(tag,code)    ; XECUTE code inside an auto-managed scope
$$ACTIVE^STDFIX()        ; → 1 if a fixture scope is currently open
REGISTER^STDFIX(tag,setupCode,teardownCode)  ; declarative fixture
INVOKE^STDFIX(tag)       ; runs the registered setup/teardown pair
CLEANUP^STDFIX           ; idempotent rollback of any leaked scope
```

**Isolation strategy:** `TSTART *:T="BATCH"` (YDB nested transactions
with restartable type) per test, `TROLLBACK` on teardown. This rolls
back every global mutation inside the test body — `^DPT`, `^DIC`,
`^XTMP`, anything — without touching what the test framework itself
writes (counters live in local vars, which transactions don't cover).

**IRIS portability:** IRIS supports `TSTART/TROLLBACK` with the same
semantics for the subset we use (no LOCK escalation tricks). Marked
fail-soft until v0.0.4-style gating is reintroduced.

**Tests:**
- Open scope, write to ^TEST(1), teardown → ^TEST is empty.
- Nested SETUP within an active scope → savepoint, partial rollback.
- TEARDOWN without matching SETUP → documented `$ECODE` error.
- WITH^STDFIX rolls back even if XECUTE'd code raises.
- CLEANUP after a leaked scope succeeds and leaves the database
  consistent.

**Companion m-cli change:** runner calls `D SETUP^STDFIX(label)`
before invoking each test label and `D TEARDOWN^STDFIX(label)` after,
regardless of whether the test passed or failed. New flag
`m test --no-isolation` opts out for legacy `^TESTRUN`-style suites
that don't want it.

### 6.2 STDMOCK — call interception

**Tag:** `v0.1.2`. **Routine:** `STDMOCK.m`. **Est. LoC:** 200 + 60
tests.

**Public API:**

```m
REGISTER^STDMOCK(target,replacement)  ; "TAG^ROU" → "TAG^STUB"
UNREGISTER^STDMOCK(target)
CLEAR^STDMOCK                          ; remove all registered mocks
$$RESOLVE^STDMOCK(target)              ; → replacement, or target if none
INVOKE^STDMOCK(target,.args)           ; D @$$RESOLVE^STDMOCK(target) with args
$$CALLED^STDMOCK(target)               ; → call count for this target since CLEAR
$$ARGS^STDMOCK(target,n)               ; → recorded args from call n
```

**Mechanism:** registry lives in `^STDLIB($J,"MOCK",target) =
replacement`. Callers must use `D @$$RESOLVE^STDMOCK("TAG^ROU")(.a,.b)`
in production code at injection points — i.e. STDMOCK is **opt-in at
the call site**, not transparent rewriting.

**Why opt-in:** transparent interception would require parser-aware
rewriting at lint time and a special-cased lookup at every `D` /
`D ^FOO` site. Opt-in via `INVOKE^STDMOCK` keeps the core MUMPS
semantics intact and matches how Python `unittest.mock.patch` is
explicit at the boundary.

**Tests:**
- Register A → B; INVOKE A actually calls B.
- CALLED counts; ARGS records args.
- CLEAR removes all; UNREGISTER removes one.
- Mocks survive a TSTART/TROLLBACK pair (registry is a $J-scoped
  global, transactions don't cover it).

**Companion m-cli change:** runner calls `D CLEAR^STDMOCK` between
tests so registrations don't leak across labels. Single line in the
runner.

### 6.3 STDSEED — declarative test data

**Tag:** `v0.1.3`. **Routine:** `STDSEED.m`. **Est. LoC:** 350 + 100
tests.

**Public API:**

```m
LOAD^STDSEED(manifestPath)         ; read TSV/JSON, FILE^DIE rows
LOADJSON^STDSEED(jsonText)         ; parse + load (uses STDJSON; Phase 2)
$$LOADED^STDSEED(manifestPath)     ; → 1 if currently loaded
CLEAR^STDSEED(manifestPath)        ; KILL the loaded records (best-effort)
$$VALIDATE^STDSEED(manifestPath)   ; → 0 if all rows file-valid; ^ECODE on error
```

**Manifest format** (TSV is v0.1.3; JSON in M4 once STDJSON ships):

```tsv
# file 9.4 — package
file	field=value	field=value	...
9.4	.01=MY PACKAGE	1=MYPKG	8=MY PACKAGE
# file 200 — user
200	.01=USER,TEST ONE	2=THING
```

**Filing strategy:** every row goes through `FILE^DIE` (FileMan API
of record). Errors are captured in `^TMP("DIERR",$J)` and propagated
to `$ECODE`. Loads happen inside the **caller's** TSTART scope so
STDFIX rollback cleans them up automatically — STDSEED does not open
its own transaction.

**Tests:**
- Load a 3-row TSV → `^DIC(9.4,...)` shows the rows.
- Validate-only mode reports DIE errors without writing.
- CLEAR removes the loaded rows.
- Load nested in STDFIX → TEARDOWN rolls back the seeded data.

**Companion m-cli change:** new flag `m test --seed PATH` (and
`--seed PATH` repeatable) that calls `D LOAD^STDSEED("PATH")` before
the suite runs and lets STDFIX handle cleanup. For integration mode
(M3), `--seed` is the primary fixture-loading mechanism.

### 6.4 m-cli runner protocol changes (M1 companion PR)

One m-cli PR pairs with M1. Touches:

- `src/m_cli/test/runner.py`:
  - Per-test wrapper builds: `D SETUP^STDFIX(LBL) X "D tLBL^SUITE(.p,.f)"
    D CLEAR^STDMOCK D TEARDOWN^STDFIX(LBL)`. Wrapping is opt-out via
    `--no-isolation`.
  - New `--seed PATH` flag (repeatable) prepended as
    `D LOAD^STDSEED("PATH")` before the suite entry.
  - Resilient teardown: if a test label crashes mid-execution, the
    runner still emits the TEARDOWN call so isolation holds.
- `src/m_cli/test/cli.py`:
  - `--no-isolation`, `--seed PATH` flags surfaced.
- TOOLCHAIN-FINDINGS P1 fix lands first (drop `^TESTRUN` hard-coding).

Estimated effort: 4–6 days m-cli work + the three stdlib modules in
parallel. M1 ships when both sides are green.

---

## 7. m-cli enhancements (M2 + M3)

Not stdlib-coupled — pure m-cli Python work — but sequenced here so
the joint milestones make sense.

### 7.1 `m test --format=junit` (M2)

JUnit XML output for CI consumption (GitHub Actions, GitLab,
TeamCity). Composes existing `text` / `tap` / `json` formatters in
`src/m_cli/test/output.py`. Each test label becomes a `<testcase>`;
suite-level totals roll up to `<testsuite>`. Failure text is the
TESTRUN `expected/actual` block. Effort: 1–2 days.

### 7.2 `m test --coverage-min N` and `m coverage --min-percent N` (M2)

Composes `m coverage` with `m test`. Returns non-zero exit if
line-coverage falls below the threshold. m-stdlib already enforces
≥85 % per module via `make coverage` — this generalises that to any
project. Effort: 1 day.

### 7.3 Branch coverage (`m coverage --branch`) (M2)

Today's `m coverage` is line-only via YDB `view "TRACE"`. Branch
coverage requires:

1. tree-sitter-m identifies decision points (`IF`, `ELSE`, `$SELECT`,
   `FOR`, `JOB :`).
2. `m coverage` instruments those points (one line per branch
   outcome).
3. Output formatter splits into line-cov + branch-cov columns.

The tree-sitter-m grammar already has the needed nodes; the
instrumenter and formatter are the work. Effort: 1–2 weeks. Line-cov
output is unchanged (back-compat).

### 7.4 `m test --changed` (M3)

Run only tests touching modified files. Two implementation paths:

1. **m-cli's own `WorkspaceIndex`** — already maps `routine → labels`
   and inbound call sites. Reverse from changed routines through the
   index to find affected suites. Self-contained; works on any M
   project.
2. **vista-meta `routine-calls.tsv`** — pre-built call graph for
   VistA. Faster startup; only useful in vista-meta-rooted projects.

Default to (1) since m-cli already owns the index. (2) is a
performance optimisation if (1) is too slow on big workspaces. Effort:
3–4 days.

### 7.5 `m test --integration` (M3)

Runs after `vista-cli install` (parent plan, Phase 3) against a live
container. Differences from unit mode:

- No per-test TSTART/TROLLBACK by default — integration tests assert
  on durable state.
- `--seed` is mandatory (reproducible fixtures).
- RPC smoke harness (Python side, in `py-kids-install`) drives RPCs
  over VistALink; M-side integration tests run against the same
  database.
- Output goes to JUnit by default (CI consumption).

Effort: 1–2 weeks; tightly coupled to the parent plan's Phase 4
(integration test framework).

---

## 8. Sequencing

```
M0 ─── v0.0.1 (STDASSERT, STDUUID) ───────────────────────────────── done

M0.5 ── v0.0.2..v0.1.0 (Phase 1 modules; existing plan) ── 8 weeks
        └─ m-cli companion: TOOLCHAIN P1 fix (drop ^TESTRUN hardcode)

M1 ─── v0.1.1 (STDFIX) ───┐
       v0.1.2 (STDMOCK)   ├── 4 weeks (parallel)
       v0.1.3 (STDSEED) ──┘
        └─ m-cli companion PR: runner protocol (SETUP/TEARDOWN, CLEAR^MOCK, --seed)

M2 ─── v0.1.4 (m-stdlib self-migrates onto STDFIX) ─── 2 weeks
        └─ m-cli: --format=junit, --coverage-min N, --branch

M3 ─── v0.1.5 (STDSEED hardening) ──── 3 weeks
        └─ m-cli: --changed, --integration

M4 ─── v0.2.0 (Phase 2: STDJSON, STDREGEX, STDCOLL, STDURL) ─── 12 weeks
        └─ m-cli: LSP signature help refresh

M5 ─── v0.3.0 (Phase 3: STDHTTP, STDCRYPTO, STDCOMPRESS) ─── later
        └─ m-cli: DAP debugger re-evaluation
```

Total to M3 (working integrated TDD loop): **~17 weeks** from
v0.1.0 ship.

---

## 9. Cross-project gates

Adapted from m-stdlib-implementation-plan §9 (per-module gate); these
extend it for joint milestones.

A milestone closes only when:

- [ ] All stdlib tags in the milestone meet the per-module gate
      (`m fmt --check`, `m lint`, `m test`, `m coverage ≥ 85 %`,
      `m lsp` hover, docs, CHANGELOG).
- [ ] Companion m-cli PR is merged with `make check` green.
- [ ] m-stdlib's own test suite re-runs green under the new
      m-cli runner protocol (regression check).
- [ ] At least one downstream project (m-cli's M-side tests, or a
      vista-meta sample) consumes the new module end-to-end.
- [ ] `TOOLCHAIN-FINDINGS.md` has no new P0/P1 entries opened by the
      milestone work, OR they have linked m-cli / tree-sitter-m
      issues with timelines.

m-stdlib stays the regression suite for the toolchain (per existing
§9 / §10 of the implementation plan).

---

## 10. Open questions

- **STDFIX nesting depth.** YDB's `TSTART *` allows reasonable
  nesting; do we cap explicitly (e.g. 16) or trust the engine? Decide
  at v0.1.1 entry.
- **STDMOCK call recording overhead.** Recording every arg to
  `^STDLIB($J,"MOCK","ARGS",target,n)` is fine for tests but might
  be costly if a test loops a million times against a mock. Add an
  `--no-record` runner flag if profiling shows it. Defer until proof.
- **STDSEED manifest format.** TSV in v0.1.3 (no STDJSON yet); JSON
  added in M4 once STDJSON ships. YAML deliberately not on the table
  — adds a Phase 3 dep ($ZF libyaml) for marginal gain.
- **`m test --integration` durable assertions.** If integration tests
  don't roll back, how do they reset state between runs? Probably
  via mupip backup/restore at the volume level (parent plan Phase 4)
  rather than per-test — STDFIX is unit-mode only.
- **Whether STDLOG (v0.0.4) should consume STDFIX directly.** Probably
  not — STDLOG runs in production, STDFIX is test-mode. Keep them
  decoupled.
- **Whether `m test --no-isolation` should be the default for legacy
  suites that predate STDFIX.** Probably yes — existing
  `^TESTRUN`-style suites should keep working unchanged. Decide at M1
  entry; document the migration path.

---

## 11. Cross-references

- [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md) — per-module work plan; authoritative for v0.0.1 → v0.3.0 module specs.
- [m-libraries-remediation.md](m-libraries-remediation.md) — background and rationale for m-stdlib's existence.
- [TOOLCHAIN-FINDINGS.md](../tracking/TOOLCHAIN-FINDINGS.md) — open m-cli / tree-sitter-m issues blocking publication.
- [../../m-cli/CLAUDE.md](../../CLAUDE.md) — m-cli's project context; runner / lint / lsp conventions.
- [../../m-cli/TODO.md](../../../m-cli/TODO.md) — m-cli's resume-here list; M1/M2/M3 entries land here as work begins.
- [../../vista-meta/docs/vista-orchestration-plan.md](../../../vista-meta/docs/vista-orchestration-plan.md) — the parent end-to-end plan; this doc is its m-stdlib slice.
- [../../vista-meta/TODO.md](../../../vista-meta/TODO.md) T-004 — master tracker for the parent plan.
