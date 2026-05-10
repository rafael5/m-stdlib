---
title: m-stdlib — future module proposals
status: proposal
tracker: docs/tracking/module-tracker.md
---

# m-stdlib — future module proposals

This document is the parking lot for module candidates that haven't
crossed TDD-red yet. Each candidate has a sketch, a priority, an
effort estimate, and a rationale for *why this one and not others*.
None has tests staked.

**Promotion process.** Promote a row from this table into
[`docs/tracking/module-tracker.md`](../tracking/module-tracker.md)'s
**Table 1 (Module tracker)** the moment you write `tests/STDxxxTST.m`
and confirm it fails red — at that point assign a track ID (next
available L-number for pure-M or H-number for `$ZF`-bound), bump the
row out of this table, and add it to Table 1 with phase **P4** (or
whatever phase fits).

When promoting, also:

- Add the per-module spec stub to
  [`m-stdlib-implementation-plan.md`](m-stdlib-implementation-plan.md)
  (current sections 8 / 11 / 12 are the spec home for Phase 1 / 2 / 3
  — extend with §13 or later as needed).
- Open the dispatch row in
  [`docs/tracking/parallel-tracks.md`](../tracking/parallel-tracks.md)
  §3.x with the block-on edges (if any) marked in §2's dependency map.
- Update this file's frontmatter `status` if all candidates promote
  out (status becomes `realized`).

## Active proposals

Priority is a single integer 1..N (1 = highest). Priority captures
**when this should be picked up** relative to other proposals,
considering: security gap closure, downstream-module unblock,
adjacent-tooling pressure, breadth of call sites.

Dependency column legend: same as Table 1. **soft** = optional —
module would work without the dep but ships better integration when
the dep is present.

Effort = developer-days, full TDD discipline, all forward estimates
marked **est.**.

| Pri | Candidate | Headline | Dependency | Effort | Rationale |
|---|---|---|---|---|---|
| 1 | `STDYAML` | YAML 1.2 parser | STDDATE; STDSTR (soft) | 12–18d est. | Config ergonomics; preferred to JSON for human-edited configs. **Big spec.** Defer until a concrete consumer asks. |
| 2 | `STDNET` | TCP / UDP socket primitives | `$ZF → libc` POSIX sockets (or YDB native), TBD; A6 | 8–14d est. | Sits below `STDHTTP` and a future `STDDNS`. **Largest lift** of any row; defer until a concrete greenfield service drives it. |

**Aggregate proposal effort:** ~20–32d est. for the remaining 2
candidates if every row eventually lands. Both are multi-session
commitments — the small-and-completable shelf is now empty.

## Promoted out — historical record

Modules that began in this proposal table and have since landed in
[`module-tracker.md`](../tracking/module-tracker.md) Table 1. Kept
here as a reference for how each promotion played out (per-module
deep history lives in each module's
[`docs/modules/<m>.md` § History](../modules/) section).

- **STDCSPRNG** — promoted 2026-05-07 to Table 1 as **L15 P4**.
  Implemented with `/dev/urandom` (kernel ChaCha20 CSPRNG via
  single-byte `READ *b` to avoid record-terminator truncation)
  instead of the originally sketched `$ZF → libc` callout — the API
  surface is stable for a future callout-backend swap (T12, since
  closed) once the Phase 3 build harness is exercised by a real
  consumer.
- **STDFS** — promoted 2026-05-07 to Table 1 as **L16 P4**. Shipped
  as text-mode YDB-only v1: read/write/append/exists/remove/size +
  basename/dirname/join. **T13+T14 closed 2026-05-08** —
  `src/callouts/stdfs.c` adds byte-faithful I/O.
- **STDOS** — promoted 2026-05-07 to Table 1 as **L17 P4**. Shipped
  YDB-only v1: env / pid / cmdline / argc / arg / argv / splitArgs /
  cwd / user / hostname / exit. setenv() and quote-aware splitArgs
  deferred to T15.
- **STDSEMVER** — promoted 2026-05-07 to Table 1 as **L18 P4**. SemVer
  2.0.0; range syntax v1 covers comparators, caret, tilde, AND;
  remaining npm range constructs queued at T16.
- **STDSTR** — promoted 2026-05-07 to Table 1 as **L19 P4**. ASCII-
  only string helpers; Unicode whitespace + locale-aware case folding
  deferred to a future STDUNICODE under T17.
- **STDTOML** — promoted 2026-05-07 to Table 1 as **L20 P4**. TOML
  1.0 subset: top-level pairs + `[section]` tables; 4 scalar types;
  `#` comments. Out-of-scope features (arrays, inline tables, dotted
  keys, etc.) queued at T18.
- **STDCACHE** — promoted 2026-05-07 to Table 1 as **L21 P4**. LRU
  + TTL cache. STDCOLL rebase + `prune` queued at T19.
- **STDPROF** — promoted 2026-05-07 to Table 1 as **L22 P4**. Wall-
  clock profiler. T20 (streaming-percentile) closed
  won't-fix-without-consumer-driver.
- **STDSNAP** — promoted 2026-05-07 to Table 1 as **L23 P4**.
  Snapshot testing. T21 closed via C7's update-mode global flag.
- **STDENV** — promoted 2026-05-07 to Table 1 as **L24 P4**. `.env`
  loader + typed accessors. Variable substitution / multi-line / etc.
  queued at T22.
- **STDXML v0** — promoted 2026-05-07 to Table 1 as **L25 P4**.
  XML 1.0 well-formed parser. T23–T27b + T26 all closed; full XML
  1.0 + Namespaces 1.0 + XPath 1.0 + DTD envelope shipped.
- **STDMATH** — promoted 2026-05-08 to Table 1 as **L26 P4**. Numeric
  helpers (clamp / min / max / sum / count / mean).
- **STDXFRM** — promoted 2026-05-08 to Table 1 as **L27 P4**. Higher-
  order array transforms (map / filter / reduce) via XECUTE-evaluated
  lambdas.

## Cross-references

- [`../tracking/module-tracker.md`](../tracking/module-tracker.md) — current Table 1; promotion target.
- [`../tracking/parallel-tracks.md`](../tracking/parallel-tracks.md) — dispatch view; track IDs assigned at promotion.
- [`m-stdlib-implementation-plan.md`](m-stdlib-implementation-plan.md) — per-module specs; spec stubs added at promotion.
- [`../modules/index.md`](../modules/index.md) — canonical released-module index.
