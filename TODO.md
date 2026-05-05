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
