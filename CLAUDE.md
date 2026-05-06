---
# Machine-readable project descriptor — schema v1 (2026-05-05).
name: m-stdlib
kind: [m-library, library]
status: active                             # v0.1.0 shipped 2026-05-05; v0.2.0 fully landed on main awaiting tag
languages: [mumps]

runtime:
  needs:
    - "yottadb (primary target)"
  optional:
    - "iris (portability target where reasonable)"
  excludes:
    - "gtm (deliberately out of scope)"

distribution:
  pypi: null
  github: rafael5/m-stdlib

location: ~/projects/m-stdlib

exposes:
  m_routines:
    - "STDASSERT.m (assertions; v0.0.1)"
    - "STDUUID.m (UUID gen; v0.0.1)"
    - "STDB64.m, STDHEX.m, STDFMT.m, STDLOG.m, STDDATE.m, STDCSV.m, STDARGS.m (v0.1.0)"
    - "STDFIX.m (v0.1.1), STDMOCK.m (v0.1.2), STDSEED.m (v0.1.3) — Phase 1b TDD primitives"
    - "STDJSON.m, STDREGEX.m, STDCOLL.m, STDURL.m (v0.2.0; landed on main)"
  planned_routines:
    - "STDHTTP, STDCRYPTO, STDCOMPRESS via $ZF (v0.3.0)"
  formats_produced: []                     # runtime library, no file outputs

consumes:
  formats: []
  services: []

companions:
  - project: m-cli
    relation: "m-stdlib has architectural priority over m-cli — m-cli should consume m-stdlib utilities, not duplicate them"
  - project: m-standard
    relation: "m-stdlib obeys m-standard's reconciled language definitions; rules apply via m-cli lint"
  - project: tree-sitter-m
    relation: "syntax must parse cleanly under tree-sitter-m"
  - project: m-tools
    relation: "shell/runtime infrastructure for testing M libraries"

incompatibilities:
  - "GT.M not supported. AGPL-3.0 YottaDB and IRIS only."
  - "Ships pure-M source; no compiled artifacts. Caller links the routines via $ZRO."

docs:
  primary: README.md
  implementation_plan: docs/m-stdlib-implementation-plan.md
  tdd_orchestration: docs/tdd-orchestration-plan.md   # m-stdlib ↔ m-cli joint milestones; Phase 1b TDD primitives (STDFIX/STDMOCK/STDSEED)
  parallel_tracks: docs/parallel-tracks.md            # dispatch view: 31 zero-interdep tracks ready for parallel pickup
---

# m-stdlib

Pure-M (and selectively `$ZF`-bound) runtime library filling the
highest-impact gaps in M's standard library. Sibling project to m-cli,
m-standard, and tree-sitter-m. YottaDB-first; IRIS-portable where
reasonable.

See [README.md](README.md) for the phase plan.

## Status (2026-05-05)

- v0.0.1 shipped 2026-04-30: STDASSERT (full) + STDUUID.
- **v0.1.0 shipped 2026-05-05** (Phase 1 release tag — commit `3cf84f2`).
  Rolls up tracks L1–L7 + L4b: STDB64, STDHEX, STDFMT, STDLOG, STDDATE,
  STDCSV, STDARGS — all green, all 100% label coverage, 0 lint.
- v0.1.1 (STDFIX), v0.1.2 (STDMOCK), v0.1.3 (STDSEED): Phase 1b TDD
  primitives — labelled commits on `main`, awaiting batch tag.
- **Phase 2 fully landed on `main`, awaiting `v0.2.0` tag**: STDJSON
  (L11), STDREGEX (L12), STDCOLL (L13), STDURL (L14), plus STDLOG L4
  add-on (`FORMAT(kv|json)`) and STDSEED L10 add-on (`loadJson`). All
  implementations green; some `raises`-path test bodies parked pending
  the open STDASSERT.raises P1 fix in TOOLCHAIN-FINDINGS (not a v0.2.0
  blocker).
- m-cli companion tracks C1–C5 + W/X/Y all shipped; M1 closed.
- STDASSERT migrations V1/V2/V3 verified no-op 2026-05-05 — none of
  m-cli, tree-sitter-m, m-standard ship M-side test suites; m-tools
  is the de-facto STDASSERT consumer.

See `docs/parallel-tracks.md` for the live dispatch board.

## Architectural rule

**m-stdlib has priority over m-cli.** When both projects need a utility,
implement it here first; m-cli imports.
