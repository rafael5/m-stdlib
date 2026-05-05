# m-stdlib — resume-here TODO

**Status:** Phase 0 + v0.0.1 shipped 2026-04-30. Next: v0.0.2.

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






## Next: v0.0.2 — STDB64 + STDHEX

Update Todos

Write tests/STDB64TST.m with RFC-4648 §10 vectors + URL-safe + round-trip + valid()

Confirm TDD red against missing STDB64

Implement src/STDB64.m (encode/decode/urlencode/urldecode/valid)

Confirm STDB64TST green

Write tests/STDHEXTST.m (round-trip, case-insensitive decode, valid)

Implement src/STDHEX.m (encode/encodeu/decode/valid)

Run full per-module gate (fmt + lint + test + coverage)

Write docs/modules/stdb64.md + stdhex.md

Update CHANGELOG, plan, memory, TODO

Commit, tag v0.0.2, push




Per [implementation plan §8.3–§8.4](docs/m-stdlib-implementation-plan.md#83-stdb64--rfc-4648-base64).

- [ ] Write `tests/STDB64TST.m` first. Vendor the RFC-4648 §10
      vectors into `tests/conformance/b64/` and assert byte-equivalent
      round-trip on every vector. Confirm TDD red.
- [ ] Implement `src/STDB64.m`: `ENCODE`, `DECODE`, `URLENCODE`
      (`-_`, no padding), `URLDECODE`, `VALID`. Lookup-table-based
      hot loop on `$EXTRACT`.
- [ ] Confirm TDD green.
- [ ] Write `tests/STDHEXTST.m`. Round-trip on random byte strings
      0..1024 bytes; case-insensitive decode; reject odd-length and
      non-hex inputs.
- [ ] Implement `src/STDHEX.m`: `ENCODE` (lowercase default),
      `ENCODEU` (uppercase), `DECODE`, `VALID`.
- [ ] Per-module gate (plan §9): `make check` + `make coverage` both
      green; coverage ≥85% per module.
- [ ] Write `docs/modules/stdb64.md` + `docs/modules/stdhex.md`.
- [ ] Update CHANGELOG, plan §1 status table, memory.
- [ ] Commit, tag `v0.0.2`, push.

## Then: v0.0.3..v0.0.7

| Tag | Module | Plan ref |
|---|---|---|
| `v0.0.3` | STDFMT (printf-style formatter) | §8.5 |
| `v0.0.4` | STDLOG (text-only) + IRIS CI re-add | §8.6 |
| `v0.0.5` | STDDATE (ISO-8601, replaces STDLOG inline ts) | §8.7 |
| `v0.0.6` | STDCSV (RFC-4180 + conformance corpus) | §8.8 |
| `v0.0.7` | STDARGS | §8.9 |
| `v0.1.0` | Phase 1 release | §8.10 |

Each PR: source + `*TST.m` + `docs/modules/*.md` + CHANGELOG entry.
None of those are optional.

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
