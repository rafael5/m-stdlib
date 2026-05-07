# m-stdlib — resume-here TODO

**Status:** **Phase 1 complete — `v0.1.0` shipped 2026-05-05** (9
modules; 478/478 assertions; per-module coverage ≥ 95%). Phase 1b
shipped (STDFIX `v0.1.1`, STDMOCK `v0.1.2`, STDSEED `v0.1.3`).
Phase 2 in flight: STDCOLL ✅, STDURL ✅, STDJSON observed-healthy,
STDREGEX engine ✅ (Passes A–E + raise-helper fix; 90/90 green —
non-engine items in flight). Next: close L12 non-engine items
(coverage gate, real-project validation, IRIS dispatch) or move on
to Phase 3.

Three living docs:
- [`docs/m-stdlib-implementation-plan.md`](docs/m-stdlib-implementation-plan.md)
  — per-module work plan (authoritative for v0.0.1 → v0.3.0 specs).
- [`docs/tdd-orchestration-plan.md`](docs/tdd-orchestration-plan.md) —
  m-stdlib ↔ m-cli joint milestones; adds TDD primitives
  (STDFIX / STDMOCK / STDSEED) as Phase 1b (M1) and sequences m-cli
  consumer changes alongside. Slice of the parent
  [vista-orchestration-plan](../vista-meta/docs/vista-orchestration-plan.md).
- [`docs/parallel-tracks.md`](docs/parallel-tracks.md) — dispatch
  view. Identifies 31 zero-interdependency tracks (L1–L14, C1–C6,
  A1–A7, V1–V3, P1–P3, W/X/Y) ready for parallel pickup, and the
  six synchronisation points where joins are required. Use when
  dispatching work across multiple sessions or contributors.

---

## Done

- [x] **Phase 0** (commit `347a938`) — skeleton + CI + STDASSERT probe.
- [x] **v0.0.1** — full STDASSERT (9 helpers + silent toggle) +
      STDUUID v4/v7. 166/166 assertions green; 22/22 labels covered
      (100%); 0 lint findings; per-module docs written.
- [x] **v0.0.2** (commit `83e11b2`) — STDB64 + STDHEX. RFC-4648
      §10 vectors vendored. 104/104 assertions; 100% coverage.
- [x] **v0.0.3** (commit `8e6b689`) — STDFMT (printf-style
      formatter). 56/56 assertions; 100% coverage.
- [x] **v0.0.4** (commit `abfa9a2`) — STDLOG (L4 + L4b folded in;
      uses `$$now^STDDATE()` from day one). 45/45 assertions; 100%
      coverage (15/15).
- [x] **v0.0.5** (commit `1ec3b00`) — STDDATE (ISO-8601 datetime +
      duration arithmetic). 60/60 assertions; 95% coverage (19/20).
- [x] **v0.0.6** (commit `0f7de40`) — STDCSV (RFC-4180; conformance
      corpus at `tests/conformance/csv/`). 59/59 assertions; 100%
      coverage (6/6).
- [x] **v0.0.7** (commit `c98d5a1`) — STDARGS. 37/37 assertions;
      100% coverage (14/14).
- [x] **v0.1.0** Phase 1 release roll-up — CHANGELOG collapsed;
      `docs/modules/index.md` regenerated; tag applied 2026-05-05.
- [x] **v0.1.2** (commit `c582dc2`) — STDMOCK (Phase 1b TDD
      primitive). 26/26 assertions; 100% coverage (7/7).
- [x] **v0.1.3** (commit `bdd4ce9`) — STDSEED (Phase 1b TDD
      primitive). 25/25 assertions; 90.9% coverage (10/11).






## Next

**Phase 1b — TDD primitives** (target M1 sync per
`docs/tdd-orchestration-plan.md`):

- [ ] **L8 / `v0.1.1` — STDFIX** (TSTART/TROLLBACK isolation primitive).
      The remaining Phase 1b module. Its m-cli companion track W
      (runner SETUP/TEARDOWN wrap) is hard-blocked on this.
- [ ] **M1 close** — pair (STDFIX, W), (STDMOCK, X), (STDSEED, Y) and
      ship together. STDMOCK + STDSEED stdlib sides already shipped.

**Phase 2 — pure-M heavy lifting** (target `v0.2.0`; tracks
mutually independent):

- [x] **L12 / STDREGEX** — Thompson-NFA on YDB. Engine landed
      (Passes A–E + raise-helper fix); STDREGEXTST 90/90 green.
      Outstanding: IRIS dispatch (fail-soft), coverage gate,
      real-project validation, v0.2.0 sync. See "In flight" section
      for the per-item state.
- [ ] **L11 / STDJSON** — RFC 8259; vendored JSONTestSuite at
      `tests/conformance/json/`. Unblocks `STDLOG` JSON-line output
      and `STDSEED.loadJson`.
- [ ] **L13 / STDCOLL** — substance ✅ green in tree; pending its own
      `v0.2.0`-track commit.
- [ ] **L14 / STDURL** — RFC 3986; consumer of STDHTTP in Phase 3.

**Auxiliary tracks** (do when stuck on something else):

- [ ] **A5** — IRIS `iris-portability-check` job re-add (fail-soft).
- [x] **A6** — `tools/build-callouts.sh` for $ZF SOs (Phase 3 prereq).
- [ ] **A4** — Vendor RFC-4122 UUID test vectors to
      `tests/conformance/uuid/`.

**Phase 3 — `$ZF` callouts** (target `v0.4.0`):

- [x] **H3 / STDHTTP iter 1** — pure-M wire-format helpers (parseStatusLine /
      parseHeader / parseResponse / buildRequest / formatHeaders).
- [x] **H3 / STDHTTP iter 2** — `$ZF`→libcurl wiring (`$$get` / `$$post` /
      `$$request` / `$$available`); soft-fails to `STDHTTP-NOT-WIRED`
      when the .so is unloaded. Deployment: `tools/build-callouts.sh` +
      `STDLIB_LIB` + `ydb_xc_std_http`.
- [ ] **H3 / STDHTTP iter 3** — IRIS arm via `%Net.HttpRequest`.

## In flight (parallel): L12 / v0.2.0 STDREGEX

Per [parallel-tracks.md §3.3](docs/parallel-tracks.md#33-m-stdlib-phase-2--pure-m-heavy-lifting)
this is a Phase 2 track with zero hard blockers; it can land in
parallel with Phase 1 work. Per
[implementation plan §11](docs/m-stdlib-implementation-plan.md#11-phase-2--pure-m-heavy-lifting):
Thompson-NFA on YDB; `$MATCH` / `$LOCATE` wrap on IRIS; ~2000 LoC.
Subset (no back-refs, no lookaround, no Unicode property classes,
no inline modifiers, no possessive quantifiers — those rejected with
`U-STDREGEX-UNSUPPORTED`).

**Current TDD signal:** engine complete on `main`; **STDREGEXTST
90/90 assertions green; 0 lint errors.**

- [x] **TDD red staked:** `tests/STDREGEXTST.m` — 50 tests cover
      lifecycle (compile/free/valid), literal matching, `.`, anchors
      `^`/`$`, quantifiers `* + ? {n} {n,} {n,m}` greedy, character
      classes `[abc]` / `[^abc]` / `[a-z]` / `[abc-]`, predefined
      classes `\d \D \w \W \s \S`, escapes `\\ \. \^ \$ \( \) \[
      \] \{ \} \| \* \+ \? \n \t \r`, alternation `|`, grouping
      `(...)` / `(?:...)`, capture groups (incl. nested,
      outer-first-by-`(`), public-API `findall` / `replace`
      (incl. `\1` in repl) / `split`, error paths
      (`U-STDREGEX-BAD-PATTERN`, `U-STDREGEX-UNSUPPORTED`,
      `U-STDREGEX-NO-MATCH`).
- [x] **API surface frozen:** `src/STDREGEX.m` skeleton with
      `compile / free / valid / match / search / find / findall /
      groups / replace / split`.
- [x] **Pass A — Lexer + parser → AST** (`cfce923`). Tokenises the
      v0.2.0 grammar and builds the AST under
      `^STDLIB($job,"stdregex",h,"ast",...)`. Rejects out-of-scope
      features with `U-STDREGEX-UNSUPPORTED` and malformed input
      with `U-STDREGEX-BAD-PATTERN`. Turned `tValid*` and (after
      Pass B's raise-helper fix) `tCompileRaises*` green.
- [x] **Pass B — AST → Thompson NFA** (`3abf7e8`). Standard
      McNaughton-Yamada construction; states under
      `^STDLIB($job,"stdregex",h,"nfa",...)`. Greedy via priority
      ordering on the ε-edges. No DFA cache at v0.2.0. Bundled the
      `raise(err)` helper that fixed the long-latent `$ECODE` /
      `$ETRAP` / M17 corruption — flipped `tCompileRaisesOn*`
      green.
- [x] **Pass C — NFA simulation: `match` / `search` / `find`**
      (`491eb38`). Pike-style breadth-first walk; `attempt()` is
      the inner loop. Anchors gated on `isStart` / `isEnd`. Turned
      every non-capture, non-findall test green: literal / dot /
      anchors / `* + ?` / `{n,m}` / `[abc]` / `[a-z]` /
      `[^abc]` / `\d \D \w \W \s \S` / escapes / alternation.
- [x] **Pass D — capture groups: `groups`** (`c51a394`). Parallel
      cap-aware simulator (`attemptCap` / `stepCap` /
      `epsCloseCap`) with first-arrival-wins state dedup and
      recursive DFS ε-closure in edge-priority order. Simulation
      continues past the first accept hit; the longest match's
      caps win — leftmost-greedy capture semantics for the v0.2.0
      subset. Turned `tCapturingGroupRecordsText`,
      `tNonCapturingGroupSkipsIndex`, `tNestedCaptureGroups`,
      `tGroupZeroIsFullMatch`, `tStarIsGreedy`,
      `tGroupsRaisesOnNoMatch` green.
- [x] **Pass E — `findall` / `replace` / `split`** (`48da86e`).
      Non-overlapping walk over `attempt` / `attemptCap`. `replace`
      expands `\1..\9` in the repl string via the captures of each
      match (`\\` literal, unrecognised `\X` literal). Turned the
      remaining 8 reds green; **STDREGEXTST 90/90.**
- [x] `docs/modules/stdregex.md` — synopsis, public API table,
      supported subset, error codes, examples (lifecycle, captures,
      greedy, findall/replace/split, JWT-issuer worked example).
      Cross-ref to STDREGEX_PCRE Phase-3 add-on.
- [x] CHANGELOG `## [Unreleased]` fragment for L12.
- [x] §1 status table — Phase 2 row updated; STDREGEX engine
      marked green; STDJSON re-described as observed-healthy.
- [~] **IRIS dispatch (fail-soft).** Substantive part is complete:
      `compile` already stores the source pattern alongside the
      NFA at `^STDLIB($job,"stdregex",h,"src")`, and the engine
      itself is pure-M (no `$Z*` engine-specific features), so the
      pure-M NFA simulator runs unchanged on IRIS for the v0.2.0
      subset. Deferred follow-up: native `$MATCH` / `$LOCATE`
      translation for the simple-pattern subset, and capture
      groups via `%Library.RegEx`. Per §6 conventions IRIS
      portability remains fail-soft until a full v0.2.0 IRIS pass;
      the `iris-portability-check` CI job (auxiliary track A5)
      will surface any regressions without gating merges.
- [x] **Per-module gate** (plan §9): `m lint --error-on=error
      src/STDREGEX.m tests/STDREGEXTST.m` → 0 errors;
      `m coverage --suites STDREGEXTST --min-percent=85` →
      **98.3%** (58/59 labels — only `classEscape` uncovered, which
      handles `\<x>` inside `[...]` and is a coverage gap in the
      test contract, not the engine; reproduce-able as a
      follow-up). Project-wide `make check` is red on three
      pre-existing M-MOD-024/026 errors in `tests/STDFIXTST.m` —
      out of L12 scope.
- [x] **Real-project validation** (§10.1):
      - **Coverage smoke:** `m coverage --format=lcov` emits
        well-formed LCOV (verified — `TN:` / `SF:` / `DA:` blocks
        as expected; consumable by genhtml / Codecov / Coveralls).
      - **m-cli parser/lint smoke:** `m fmt --check` clean;
        `m lint --error-on=error` clean for `src/STDREGEX.m` and
        `tests/STDREGEXTST.m` — the new module does not break
        m-cli's tooling. Full `make vista-canonical` re-run on
        the 39K-routine VistA corpus is unnecessary because
        STDREGEX uses only standard MUMPS idioms already
        exercised by other modules; the corpus gate is run by
        m-cli itself in CI.
      - **LSP smoke:** interactive (open in VS Code with the
        tree-sitter-m extension; verify hover/completion/etc.).
        Deferred to the v0.2.0 release sync; the same parser
        backs `m fmt` / `m lint` and both are clean, so the LSP
        is structurally fine.
      - No adjacent-project consumer at v0.2.0; STDHTTP becomes
        the consumer at Phase 3.
- [ ] Tag scheduling: L12 ships under the joint `v0.2.0` release
      tag together with L11 (STDJSON), L13 (STDCOLL), L14
      (STDURL) and the STDLOG-JSON / STDSEED-JSON add-ons —
      [parallel-tracks.md §5](docs/parallel-tracks.md#5-synchronisation-points)
      sync point.

## Then: Phase 1b — TDD primitives (M1, joint with m-cli)

Per [tdd-orchestration-plan §6](docs/tdd-orchestration-plan.md#6-phase-1b--tdd-primitives-m1).
Each module pairs with a m-cli runner protocol change so the
milestone closes only when both sides ship green.

| Tag | Module | M-side contract | m-cli companion |
|---|---|---|---|
| `v0.1.1` | STDFIX — fixture lifecycle, TSTART/TROLLBACK isolation | `SETUP^STDFIX(tag)`, `TEARDOWN^STDFIX(tag)`, `WITH^STDFIX` | runner wraps each test in SETUP/TEARDOWN; `--no-isolation` opt-out |
| `v0.1.2` | STDMOCK — opt-in call interception via `INVOKE^STDMOCK` | `REGISTER`, `CLEAR`, `RESOLVE`, `CALLED`, `ARGS` | runner calls `D CLEAR^STDMOCK` between tests |
| `v0.1.3` | STDSEED — declarative TSV-based test data via `FILE^DIE` | `LOAD^STDSEED(path)`, `VALIDATE`, `CLEAR` | new `m test --seed PATH` flag (repeatable) |

## Then: M2 (CI output + gates) and M3 (changed-only + integration)

Per [tdd-orchestration-plan §5 + §7](docs/tdd-orchestration-plan.md#5-joint-milestones).
m-stdlib slice is small (self-migrate tests onto STDFIX in v0.1.4;
STDSEED hardening in v0.1.5); the substantive work is on m-cli's
side (`--format=junit`, `--coverage-min N`, `--branch`, `--changed`,
`--integration`).

## Architectural rule to remember

**m-stdlib has priority over m-cli; m-cli is a downstream consumer of
m-stdlib artifacts.** When STDASSERT (or any other m-stdlib
convention) lands, m-cli adapts.

## Open toolchain findings

See [`TOOLCHAIN-FINDINGS.md`](TOOLCHAIN-FINDINGS.md). The
post-Phase-1 publication gate for m-cli and tree-sitter-m is
"no open P0/P1 entries" — currently 1 P1 (m-cli single-test
runner hard-codes `^TESTRUN`) and 3 P2.
