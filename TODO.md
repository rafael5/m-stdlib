# m-stdlib — resume-here TODO

**Status:** **Phase 1 complete — `v0.1.0` shipped 2026-05-05** (9
modules; 478/478 assertions; per-module coverage ≥ 95%). Phase 1b
in flight (STDMOCK + STDSEED green; STDFIX pending). Phase 2 in
flight (STDCOLL green; STDREGEX scaffolded). Next: STDFIX (`v0.1.1`)
or finish Phase 2 implementation.

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

- [ ] **L12 / STDREGEX** — Thompson-NFA on YDB; `$MATCH` / `$LOCATE`
      wrap on IRIS. Scaffold + 50 tests / 90 assertions in flight; see
      "In flight" section below for current pass-by-pass plan.
- [ ] **L11 / STDJSON** — RFC 8259; vendored JSONTestSuite at
      `tests/conformance/json/`. Unblocks `STDLOG` JSON-line output
      and `STDSEED.loadJson`.
- [ ] **L13 / STDCOLL** — substance ✅ green in tree; pending its own
      `v0.2.0`-track commit.
- [ ] **L14 / STDURL** — RFC 3986; consumer of STDHTTP in Phase 3.

**Auxiliary tracks** (do when stuck on something else):

- [ ] **A5** — IRIS `iris-portability-check` job re-add (fail-soft).
- [ ] **A6** — `tools/build-callouts.sh` for $ZF SOs (Phase 3 prereq).
- [ ] **A4** — Vendor RFC-4122 UUID test vectors to
      `tests/conformance/uuid/`.

## In flight (parallel): L12 / v0.2.0 STDREGEX

Per [parallel-tracks.md §3.3](docs/parallel-tracks.md#33-m-stdlib-phase-2--pure-m-heavy-lifting)
this is a Phase 2 track with zero hard blockers; it can land in
parallel with Phase 1 work. Per
[implementation plan §11](docs/m-stdlib-implementation-plan.md#11-phase-2--pure-m-heavy-lifting):
Thompson-NFA on YDB; `$MATCH` / `$LOCATE` wrap on IRIS; ~2000 LoC.
Subset (no back-refs, no lookaround, no Unicode property classes,
no inline modifiers, no possessive quantifiers — those rejected with
`U-STDREGEX-UNSUPPORTED`).

**Current TDD signal:** stub committed; 50 tests / 90 assertions
discovered; **28/90 pass** against safe-default stub, **62 fail**
as concrete implementation targets.

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
      groups / replace / split` — all bodies are safe-default stubs
      so the harness reports per-test counts during implementation.
- [ ] **Pass A — Lexer + parser → AST.** Tokenise the v0.2.0
      grammar; build a small AST (`literal / dot / anchor / klass /
      class-pred / star / plus / quest / range-quant / concat /
      alt / group(cap?,n)`). Reject unsupported features
      (`(?=` / `(?!` / `(?<=` / `(?<!` / `\1..\9` in pattern /
      `\p{` / `(?[imsx])` / `*+`/`++`/`?+`) with
      `U-STDREGEX-UNSUPPORTED`. Reject malformed input
      (unbalanced parens, unterminated `[`, trailing `\`,
      stray `{n,m}` over an empty atom, `{m,n}` with `m>n`,
      reverse range `[z-a]`) with `U-STDREGEX-BAD-PATTERN`.
      Should turn `tValid*` and `tCompileRaises*` green.
- [ ] **Pass B — AST → Thompson NFA.** Standard McNaughton-Yamada
      construction; states keyed under `^STDLIB($job,"stdregex",h,
      "nfa",state,...)`. Greedy quantifiers via priority on the
      ε-edges. No DFA cache at v0.2.0.
- [ ] **Pass C — NFA simulation: `match` / `search` / `find`.**
      Simulate on the input string M-character by M-character.
      Maintain a dedup'd active-state set per step. Anchors
      handled at simulation entry/exit.
      Should turn `tMatch*`, `tSearch*`, `tFind*`, `tDot*`,
      `tCaret*`, `tDollar*`, `tStar*`, `tPlus*`, `tQuest*`,
      `tBrace*`, `tCharClass*`, `tBackslash*`, `tEscaped*`,
      `tAlternation*` green.
- [ ] **Pass D — capture groups: `groups`.** Extend the
      simulation with submatch tracking (per-state capture-start /
      capture-end snapshots; greedy = first match wins). Honour
      `(?:...)` skipping the capture-group counter. Set
      `U-STDREGEX-NO-MATCH` on no match.
      Should turn `tCapturingGroupRecordsText`,
      `tNonCapturingGroupSkipsIndex`, `tNestedCaptureGroups`,
      `tGroupZeroIsFullMatch`, `tStarIsGreedy`,
      `tGroupsRaisesOnNoMatch` green.
- [ ] **Pass E — `findall` / `replace` / `split`.** Build on
      `find`. Non-overlapping (advance past the match end). For
      `replace`, expand `\1..\9` in the repl string against the
      groups of each match; `\\` is a literal backslash;
      otherwise unrecognised `\X` is a literal `\X`.
      Should turn `tFindallReturnsEveryNonOverlappingMatch`,
      `tReplaceReplacesEveryMatch`, `tReplaceWithBackref`,
      `tSplitProducesSegments` green.
- [ ] **IRIS dispatch (fail-soft).** `compile` keeps the source
      pattern alongside the NFA; `match` / `search` / `find` on
      IRIS dispatch to `$MATCH` / `$LOCATE` translations of the
      v0.2.0 subset. Goal: parity on the simple-pattern subset;
      capture groups on IRIS may use the `%Library.RegEx`
      class. Per §6 conventions IRIS portability remains
      fail-soft until a full v0.2.0 IRIS pass.
- [ ] Per-module gate (plan §9): `make check` green; `make coverage
      --min-percent=85` green for `STDREGEX` only.
- [ ] `docs/modules/stdregex.md` — synopsis, public API table,
      supported subset, error codes, examples (incl. JWT-issuer
      parsing as a STDHTTP setup). Cross-ref to STDREGEX_PCRE
      Phase-3 add-on.
- [ ] CHANGELOG `## [Unreleased]` fragment for L12.
- [ ] §1 status table — bump Phase 2 to "in progress".
- [ ] Real-project validation (§10.1) on m-cli `make
      vista-canonical` smoke + LSP smoke + coverage smoke. No
      adjacent-project consumer at v0.2.0; STDHTTP becomes the
      consumer at Phase 3.
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
