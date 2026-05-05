---
# Machine-readable project descriptor — schema v1 (2026-05-05).
name: m-stdlib
kind: [m-library, library]
status: active                             # v0.0.1 shipped 2026-04-30; v0.0.2 in progress
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
  planned_routines:
    - "STDB64, STDHEX (v0.0.2)"
    - "STDFMT, STDLOG, STDDATE, STDCSV, STDARGS (v0.1.0)"
    - "STDJSON, STDREGEX, STDCOLL, STDURL (v0.2.0)"
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

- v0.0.1 shipped 2026-04-30: STDASSERT (full) + STDUUID. 166/166 assertions pass; 22/22 labels covered (100% per `m coverage`); 0 lint findings (`m lint`).
- v0.0.2 in progress: STDB64 + STDHEX.

## Architectural rule

**m-stdlib has priority over m-cli.** When both projects need a utility,
implement it here first; m-cli imports.
