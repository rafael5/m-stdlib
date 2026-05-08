---
# Machine-readable project descriptor — schema v1 (2026-05-05).
name: m-stdlib
kind: [m-library, library]
status: active                             # see CHANGELOG.md for release history
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
  # Canonical per-module inventory: docs/modules/index.md.
  # Per-version landing details: CHANGELOG.md.
  m_routines: "see docs/modules/index.md"
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
  changelog: CHANGELOG.md
  implementation_plan: docs/plans/m-stdlib-implementation-plan.md
  tdd_orchestration: docs/plans/tdd-orchestration-plan.md   # m-stdlib ↔ m-cli joint milestones
  module_tracker: docs/tracking/module-tracker.md           # single-source-of-truth tracker for shipped/in-flight/proposed modules
  parallel_tracks: docs/tracking/parallel-tracks.md         # dispatch view across all parallel tracks
  todo: docs/tracking/TODO.md                               # resume-here pointer
  toolchain_findings: docs/tracking/TOOLCHAIN-FINDINGS.md   # open toolchain bugs against m-cli / tree-sitter-m / YDB
---

# m-stdlib

Pure-M (and selectively `$ZF`-bound) runtime library filling the
highest-impact gaps in M's standard library. Sibling project to m-cli,
m-standard, and tree-sitter-m. YottaDB-first; IRIS-portable where
reasonable.

See [README.md](README.md) for the phase plan and
[CHANGELOG.md](CHANGELOG.md) for release history (current state, what
landed in each tag, and the per-module / per-track narrative). The
live work board is
[docs/tracking/module-tracker.md](docs/tracking/module-tracker.md);
[docs/tracking/parallel-tracks.md](docs/tracking/parallel-tracks.md)
is the dispatch view. Open toolchain bugs are tracked in
[docs/tracking/TOOLCHAIN-FINDINGS.md](docs/tracking/TOOLCHAIN-FINDINGS.md).

## Architectural rule

**m-stdlib has priority over m-cli.** When both projects need a utility,
implement it here first; m-cli imports.
