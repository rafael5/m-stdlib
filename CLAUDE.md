---
# Machine-readable project descriptor.
name: m-stdlib
kind: [m-library, library]
status: active
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
  github: m-dev-tools/m-stdlib

location: ~/projects/m-stdlib

exposes:
  m_routines: "see docs/modules/index.md"
  formats_produced: []

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
  - project: m-test-engine
    relation: "default Docker engine for `make test` and CI"

incompatibilities:
  - "GT.M not supported. AGPL-3.0 YottaDB and IRIS only."
  - "Ships pure-M source; no compiled artifacts. Caller links the routines via $ZRO."

docs:
  primary: README.md
  # Every doc that records change is in docs/tracking/.
  tracking_root: docs/tracking/
  changelog: docs/tracking/changelog.md
  module_tracker: docs/tracking/module-tracker.md           # canonical "what's done / in flight / proposed" view
  discoverability_tracker: docs/tracking/discoverability-tracker.md
  parallel_tracks: docs/tracking/parallel-tracks.md         # dispatch view across all parallel tracks
  todo: docs/tracking/TODO.md                               # resume-here pointer
  toolchain_findings: docs/tracking/TOOLCHAIN-FINDINGS.md   # open toolchain bugs against m-cli / tree-sitter-m / YDB
  implementation_plan: docs/plans/m-stdlib-implementation-plan.md
  tdd_orchestration: docs/plans/tdd-orchestration-plan.md   # m-stdlib ↔ m-cli joint milestones
---

# m-stdlib — Claude Project Context

Pure-M (and selectively `$ZF`-bound) runtime library filling the
highest-impact gaps in M's standard library. Sibling project to m-cli,
m-standard, and tree-sitter-m. YottaDB-first; IRIS-portable where
reasonable.

See [README.md](README.md) for the public-facing overview and
[`docs/guides/users-guide.md`](docs/guides/users-guide.md) for the
deep user reference.

## Tracking conventions

**All changes to m-stdlib — releases, in-flight work, deferred items,
external-toolchain findings, and discovered issues — are recorded in
[`docs/tracking/`](docs/tracking/).** The repo root carries no
change-tracking documents; CLAUDE.md / README.md are pointers only.

The canonical files inside `docs/tracking/`:

| File | Purpose |
|------|---------|
| [`changelog.md`](docs/tracking/changelog.md) | Release history (Keep-a-Changelog format). One entry per tag. |
| [`module-tracker.md`](docs/tracking/module-tracker.md) | Master per-module tracker — Table 1 (shipped + in-flight) + ToDo expansion + Table 2 (proposals) + per-module archaeology. |
| [`discoverability-tracker.md`](docs/tracking/discoverability-tracker.md) | Wave A–D implementation tracker for the discoverability & tooling plan; tabular summary + per-task narrative with progress logs. |
| [`parallel-tracks.md`](docs/tracking/parallel-tracks.md) | Dispatch view across L1–L27 / H1–H3 / m-cli companion C-tracks. |
| [`TOOLCHAIN-FINDINGS.md`](docs/tracking/TOOLCHAIN-FINDINGS.md) | Toolchain weaknesses surfaced during m-stdlib work (against m-cli / tree-sitter-m / YDB). |
| [`TODO.md`](docs/tracking/TODO.md) | "Resume here" pointer; thin index over the trackers. |

**Process rule.** Any commit that touches a module's source, tests,
or per-module doc MUST update the relevant row(s) in the appropriate
tracker in the same commit (the rule defined in
[`module-tracker.md`](docs/tracking/module-tracker.md)). Commits that
ship a tagged release MUST add a corresponding entry to
[`changelog.md`](docs/tracking/changelog.md).

Plans (forward-looking specs that get locked before implementation
starts) live in [`docs/plans/`](docs/plans/), separate from tracking.

## Architectural rule

**m-stdlib has priority over m-cli.** When both projects need a utility,
implement it here first; m-cli imports.
