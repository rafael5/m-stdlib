# m-stdlib — resume-here TODO

**Status:** **`v0.4.0` shipped 2026-05-08** (tag `53ecf70`). 32
modules; 32 suites; **2483/2483 assertions green on engine**;
per-module label coverage ≥ 91% (most at 100%); 0 lint errors;
fmt clean across 65 files. **All numbered tracker tickets T1–T30
closed.** Phase 3 (`STDCRYPTO` H1, `STDCOMPRESS` H2, `STDHTTP` H3)
all engine-green; STDXML T26 closed (full XPath / DTD envelope);
STDFS T13/T14 closed (byte-faithful I/O); STDCSPRNG T12 closed
(`getrandom(2)` callout); deployment loop automated via
`scripts/seed-callouts.sh`.

## Live work board

The single source of truth for in-flight + proposed work is
[`module-tracker.md`](module-tracker.md).
This TODO is a thin pointer; do not duplicate state here.

- **Summary table** — 32 shipped modules with Done / Tag / Effort /
  ToDo / Dependency / Headline / m-cli-integration. Per-module deep
  history (scaffolding, migrations, engine deploy, T-ticket closes)
  lives in each module's [`../modules/<m>.md` § History](../modules/)
  section.
- **Proposals** — at [`../plans/future-modules-plan.md`](../plans/future-modules-plan.md)
  (STDYAML, STDNET — both multi-session, deferred until concrete
  consumers drive them).

For dispatch view across all parallel tracks (L1–L27, H1–H3, m-cli
companion C-tracks, conformance-corpus A-tracks):
[`parallel-tracks.md`](parallel-tracks.md).

## Three living docs

- [`../plans/m-stdlib-implementation-plan.md`](../plans/m-stdlib-implementation-plan.md)
  — per-module work plan (authoritative for v0.0.1 → v0.4.0 specs).
- [`../plans/tdd-orchestration-plan.md`](../plans/tdd-orchestration-plan.md)
  — m-stdlib ↔ m-cli joint milestones; M0–M5 fully realised.
  Operational follow-up is
  [`../guides/m-tdd-guide.md`](../guides/m-tdd-guide.md).
- [`parallel-tracks.md`](parallel-tracks.md)
  — dispatch view; current execution status.

## Open work — optional add-ons

All gating tickets (T1–T30) closed. The remaining items in the
tracker are **optional add-ons** that activate only when a concrete
consumer drives them. None is gating any further release:

- **T15** — STDOS `setenv` / quote-aware `splitArgs` / IRIS arm via
  `$ZF → libc setenv/getcwd/gethostname`.
- **T16** — STDSEMVER range syntax extensions (`||` OR, hyphen
  ranges, `*` / `x` / `X` placeholders, prerelease-aware
  comparators, `^0.x.y` zero-major narrowing).
- **T17** — STDSTR Unicode whitespace + locale-aware case folding
  (deferred behind a future STDUNICODE).
- **T18** — STDTOML out-of-scope features (arrays, inline tables,
  dotted keys, array-of-tables, multi-line / literal strings, integer
  underscores + hex/oct/bin, special floats, exponent notation,
  datetime values).
- **T19** — STDCACHE rebase onto STDCOLL OrderedDict + explicit
  `prune()` for batch sweeps.
- **T22** — STDENV variable substitution (`${VAR}`) + `export`
  prefix + multi-line values + process-environment write-back
  (depends on T15 STDOS setenv).
- **STDHTTP iter 3** — IRIS arm via `%Net.HttpRequest`
  `$CLASSMETHOD`. Shares the same M-side req/resp shape as iter 2.
- **A4** — Vendor RFC-4122 UUID test vectors at
  `tests/conformance/uuid/`.
- **A5** — IRIS `iris-portability-check` CI job re-add (fail-soft).

## Architectural rule to remember

**m-stdlib has priority over m-cli; m-cli is a downstream consumer
of m-stdlib artifacts.** When STDASSERT (or any other m-stdlib
convention) lands, m-cli adapts.

## Open toolchain findings

See [`discoveries.md`](discoveries.md). None of the
remaining toolchain items gate any m-stdlib suite at v0.4.0.

## Cross-references

- [`../../README.md`](../../README.md) — public-facing overview;
  mirrors `../guides/users-guide.md` §§ 1–4 + 6–7.
- [`changelog.md`](changelog.md) — release history.
- [`../guides/users-guide.md`](../guides/users-guide.md) — full
  user's guide including § 5 per-module reference.
- [`../modules/index.md`](../modules/index.md) — canonical
  module inventory; one row per shipped module.
