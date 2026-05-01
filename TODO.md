# m-stdlib — resume-here TODO

**Status as of 2026-04-30:** planning complete, no implementation yet.
Directory exists, plan doc is at `docs/m-libraries-remediation.md`.
Read that document **first** in any future session — it carries all
locked decisions (§11), the finalised implementation plan (§12), and
the resolved final questions (§13).

This file is a thin pointer + checklist. The plan is the source of
truth.

---

## Where we left off

- All open questions in §11 of the plan are resolved (locked
  2026-04-30).
- All implementation questions in §13 are answered.
- The next concrete unit of work is **Phase 0** in §12.1 — bootstrap
  the repo skeleton.
- **Implementation was deliberately deferred** at the end of the
  planning session to keep that session focused on planning.

## Architectural rule to remember

**m-stdlib has priority over m-cli; m-cli is a downstream consumer of
m-stdlib artifacts.** When STDASSERT (or any other m-stdlib
convention) lands, m-cli adapts. Do not warp m-stdlib API choices to
fit m-cli's existing internals.

## Next session — Phase 0 checklist

Work top-to-bottom. Each box is the DoD from §12.1.

- [ ] **0.0 Pre-Phase 0 verification (§13.4).** Pull candidate
      YottaDB Docker images locally
      (`yottadb/yottadb-base:latest-master`, `yottadb/yottadb`,
      tagged release lines) and confirm which one starts cleanly
      with `mumps`/`mupip` on `PATH`. Pick the most reliable. Record
      the choice as a comment in `.devcontainer/Dockerfile` and
      `.github/workflows/ci.yml`.
- [ ] **0.1 Skeleton.** Create the project layout from §8.4 of the
      plan: `src/`, `tests/`, `docs/` (already exists), `examples/`,
      `tools/`, `tests/conformance/`, `.devcontainer/`,
      `.github/workflows/`, plus root files: `README.md`, `LICENSE`
      (AGPL-3.0), `Makefile` (per §8.5), `.m-cli.toml` (per §8.3),
      `.pre-commit-config.yaml` (per §8.6 — `repo: local` form per
      §13.6), `CHANGELOG.md`. `git init`. First commit.
- [ ] **0.2 Devcontainer.** Wire `.devcontainer/devcontainer.json`
      and `Dockerfile` per §8.1–§8.2 of the plan. Build locally,
      reopen in container, confirm `m --version` resolves.
- [ ] **0.3 CI.** Land `.github/workflows/ci.yml` per §9.1 with the
      IRIS portability job **omitted** (per §13.3 — reintroduce at
      v0.0.4). Confirm CI is green on a no-op build (fmt-check / lint
      / test all pass on empty `src/`).
- [ ] **0.4 README.** ≤ 1 page. Cover: what the project is, milestone
      tags from §11.6, license, install-from-git instructions, link
      back to the plan in `docs/`.
- [ ] **0.5 STDASSERT bootstrap probe.** Write a one-test
      `STDASSERTTST.m` stub that uses STDASSERT-style assertions and
      run it under `m test`. If it works under the existing
      `t<UpperCase>(pass,fail)` runner, no m-cli change is needed for
      v0.0.1. If it doesn't, file the parallel m-cli ticket per
      §13.2.

**Phase 0 done when:** empty repo + CI green + devcontainer
reproduces locally + STDASSERTTST stub runs (and fails appropriately)
under `m test`.

## Then: Phase 1, commit-by-commit

Per §12.2 of the plan:

- [ ] `v0.0.1` — STDASSERT + STDUUID + tests + per-module docs +
      CHANGELOG entries
- [ ] `v0.0.2` — STDB64 + STDHEX
- [ ] `v0.0.3` — STDFMT
- [ ] `v0.0.4` — STDLOG (text-only output until STDJSON ships); also
      reintroduce IRIS portability job in CI per §13.3
- [ ] `v0.0.5` — STDDATE
- [ ] `v0.0.6` — STDCSV (with RFC-4180 conformance corpus in
      `tests/conformance/csv/`)
- [ ] `v0.0.7` — STDARGS
- [ ] `v0.1.0` — Phase 1 release: CHANGELOG roll-up, GitHub Release,
      source tarball, docs index regenerated

Each PR carries the module + its `*TST.m` + a per-module doc page in
`docs/modules/<name>.md` + a CHANGELOG entry. None of those are
optional.

## Side effects to track in adjacent repos (per §12.3)

When STDASSERT lands in `v0.0.1`, file follow-up issues to migrate
existing `^TESTRUN`-using suites onto STDASSERT:

- [ ] m-cli — file P2 issue
- [ ] tree-sitter-m — file P2 issue
- [ ] m-standard — file P2 issue if applicable (check `tests/`)

These are not blockers for m-stdlib progression.

## Phase 2 / Phase 3

Out of scope for this TODO. Re-read §12.4 of the plan after `v0.1.0`
is tagged.

## Open uncertainties to resolve in-session, not now

- §13.4 — exact YottaDB image (resolve at start of Phase 0).
- §13.5 — when m-cli drops `^TESTRUN` recognition (resolve when m-cli
  is adapting to STDASSERT, not before).
