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
  discoveries: docs/tracking/discoveries.md                 # discoveries register: in-project pivots + external toolchain findings (renamed from TOOLCHAIN-FINDINGS.md 2026-05-10)
  tracking_readme: docs/tracking/README.md                  # the four-bucket doc model that everything under docs/tracking/ follows
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
| [`README.md`](docs/tracking/README.md) | Defines the four-bucket doc model (planning · implementation · discoveries · tracking) that everything under docs/tracking/ follows. Read this first. |
| [`changelog.md`](docs/tracking/changelog.md) | Release history (Keep-a-Changelog format). One entry per tag. |
| [`module-tracker.md`](docs/tracking/module-tracker.md) | Master per-module tracker — Summary table (Done checkbox + module rows) + closed-tickets archaeology (T1–T30) + Must-know section. Per-module deep history lives in [`docs/modules/<m>.md` § History](docs/modules/); proposals (was Table 2) live in [`docs/plans/future-modules-plan.md`](docs/plans/future-modules-plan.md). |
| [`discoverability-tracker.md`](docs/tracking/discoverability-tracker.md) | Wave A–D implementation tracker for the discoverability & tooling plan; tabular summary + per-task narrative with progress logs. |
| [`parallel-tracks.md`](docs/tracking/parallel-tracks.md) | Dispatch view across L1–L27 / H1–H3 / m-cli companion C-tracks. |
| [`discoveries.md`](docs/tracking/discoveries.md) | Discoveries register — every issue that wasn't anticipated in a locked plan but had to be addressed during implementation. Both internal m-stdlib pivots and external findings against m-cli / tree-sitter-m / YDB / vista-meta. (Renamed from TOOLCHAIN-FINDINGS.md 2026-05-10; scope broadened.) |
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

## Setup

m-stdlib ships pure-M source; there is no compiled artifact to install.
The toolchain dependencies are `m-cli` (Python) and the YottaDB runtime.

```bash
# Clone m-cli alongside m-stdlib and install it into a venv.
git clone https://github.com/m-dev-tools/tree-sitter-m ~/projects/tree-sitter-m
git clone https://github.com/m-dev-tools/m-cli         ~/projects/m-cli
cd ~/projects/m-cli
python3 -m venv .venv
.venv/bin/pip install -e ".[lsp]" ../tree-sitter-m

# Engine: start m-test-engine for `make test` / `make coverage`.
make -C ~/projects/m-test-engine up   # provides DockerEngine for m-cli
```

The `M` Makefile variable defaults to `$HOME/projects/m-cli/.venv/bin/m`;
override it if your checkout lives elsewhere.

## Test

```bash
make test          # engine-bound; needs YDB transport (LocalEngine, DockerEngine, or SSHEngine)
make safe-test     # same suites with auto-recovery from vista-meta failure modes
make coverage      # gated at 85% per module
make check         # fmt-check + lint + test (fast dev loop)
make ci            # check + TAP + JSON coverage (CI-shaped invocation)
```

Engine-free checks (`fmt-check`, `lint`, `manifest-check`,
`skill-check`, `doctest-check`) work on a fresh clone without YDB
configured.

## Build / generate

The repo commits its own generated artefacts under `dist/` — every
change to `src/STD*.m` or to a `; doc:` block must be followed by a
regenerate-and-commit, gated by CI.

```bash
make manifest        # → dist/stdlib-manifest.json + dist/errors.json
make skill           # → dist/skill/{SKILL.md,manifest-index.md,patterns.md,error-codes.md}
make doctest         # → tests/STD<MOD>DOCTST.m for every module with Pattern-A @examples
make frontmatter     # re-syncs YAML frontmatter on docs/modules/std*.md
```

The Phase 0 `repo.meta.json` (`dist/repo.meta.json`) is hand-edited —
not regenerated — and is covered by `make check-manifest` (see below).

## Verify

These commands match `dist/repo.meta.json`'s `verification_commands`
and are what an agent should run to confirm a change in this repo:

```bash
make manifest          # regenerate dist/
make test              # run the suite
make check-manifest    # drift gate: dist/ matches src/ AND repo.meta.json is committed
```

## Guardrails

- **Do not hand-edit `dist/stdlib-manifest.json`, `dist/errors.json`,
  `dist/skill/`, or `tests/STD*DOCTST.m`.** They are regenerated from
  `src/STD*.m` doc-comments by `make manifest`, `make skill`, and
  `make doctest`. CI's drift gates will reject any direct edit.
- **`dist/repo.meta.json` is the one file under `dist/` that is
  hand-edited.** Bump `verified_on` to today's date whenever you
  touch it; `make check-manifest` asserts that `dist/` (including
  `repo.meta.json`) is committed and clean.
- **Do not introduce GT.M support.** AGPL-3.0 YottaDB and IRIS only —
  GT.M is deliberately out of scope.
- **Do not duplicate utilities into m-cli.** m-stdlib has architectural
  priority; m-cli consumes from here.
- **Trackers update in the same commit.** Any commit that touches a
  module's source, tests, or per-module doc must update the relevant
  row in `docs/tracking/module-tracker.md` (see "Tracking conventions"
  above).

## Layout conventions

`docs/` holds **only** human-readable prose. Technical artifacts live
elsewhere — m-stdlib's top-level layout:

| Path | Contents |
|---|---|
| `docs/` | Tracking (changelog, module tracker, discoveries, parallel tracks), per-module API reference (`modules/`), plans, guides, testing writeups |
| `dist/` | Phase 0 `repo.meta.json` + `stdlib-manifest.json` / `errors.json` / `skill/` (drift gates) |
| `examples/` | Demo M source (e.g. `stdargs-demo.m`) |
| `templates/` | Project scaffolds (e.g. `m-vista-test-suite/`) |
| `scripts/` | Shell helpers |
| `src/` | M (`.m`) source |
| `tests/` | Test suites — hand-written `STD*TST.m` + generated `STD*DOCTST.m` |
| `tools/` | Python generator scripts (gen-manifest, gen-skill, gen-doctests, write-module-frontmatter) |

Enforced by `make check-docs-prose` (CI gate). Org-level rule:
[`.github/CONTRIBUTING.md` § Layout conventions](https://github.com/m-dev-tools/.github/blob/main/CONTRIBUTING.md#layout-conventions).
