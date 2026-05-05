---
title: m-stdlib — parallel execution tracks
status: live (2026-05-05)
companion: tdd-orchestration-plan.md (joint milestone narrative)
implementation: m-stdlib-implementation-plan.md (per-module specs)
---

# m-stdlib — parallel execution tracks

This document carves the m-stdlib + m-cli plan into **independent
work tracks** — tasks that share zero source-file or API dependency
and can be picked up simultaneously by separate sessions, agents, or
contributors without coordination beyond merge ordering.

The narrative roadmap lives in
[tdd-orchestration-plan.md](tdd-orchestration-plan.md); this doc is
the dispatch view.

---

## 1. Independence model

Two tracks are **independent** if **all** of these hold:

1. They touch disjoint source files: `src/STDxxx.m`, `tests/STDxxxTST.m`,
   `tests/conformance/<corpus>/`, `docs/modules/<module>.md`.
2. Neither consumes the other's public API at runtime.
3. Neither's `*TST.m` suite imports or invokes the other module.

Files that are **shared but mergeable** — `CHANGELOG.md`, the §1
status table in `m-stdlib-implementation-plan.md`, `TODO.md`,
`TOOLCHAIN-FINDINGS.md` — are not coordination points during
development. Track owners produce fragments; concatenation happens at
PR review time. The §9 per-module acceptance gate stays per-module.

Tags merge in dependency order (v0.0.2 → v0.0.3 → …), but
**development can run in parallel**: a track for STDARGS (v0.0.7) can
produce a green branch before STDFMT (v0.0.3) merges, with no rebase
risk because the two routines never see each other.

---

## 2. Dependency map

Real cross-module dependencies — the **only** things that block
parallelism — are these eight edges:

| Consumer | Dependency | Type | Resolution |
|---|---|---|---|
| STDLOG (v0.0.4) | STDDATE (v0.0.5) | Soft — STDLOG ships its own inline ISO-ts helper at v0.0.4; bumps to `$$NOW^STDDATE()` at v0.0.5 | Track L4 ships first with helper; track L5 lands; track L4-bump removes helper |
| m-cli runner SETUP/TEARDOWN wrap | STDFIX (v0.1.1) | Hard | m-cli companion lands after STDFIX |
| m-cli runner CLEAR^STDMOCK | STDMOCK (v0.1.2) | Hard | m-cli companion lands after STDMOCK |
| m-cli `--seed PATH` | STDSEED (v0.1.3) | Hard | m-cli companion lands after STDSEED |
| STDLOG JSON-line output | STDJSON (v0.2.0) | Hard | STDLOG add-on lands in M4 |
| STDSEED `LOADJSON` | STDJSON (v0.2.0) | Hard | STDSEED add-on lands in M4 |
| STDHTTP | STDURL (v0.2.0) + `tools/build-callouts.sh` | Hard | Both ship before Phase 3 |
| STDCRYPTO / STDCOMPRESS | `tools/build-callouts.sh` | Hard | Build harness ships once before all three |

Everything else is independent.

---

## 3. Parallel track table

Each row is a self-contained unit of work: tests-first → impl →
docs/modules/<name>.md → CHANGELOG fragment → §9 gate. **Zero**
runtime or source-file dependency on any other track in the same
group.

### 3.1 m-stdlib Phase 1 — pure-M quick wins

All seven tracks are mutually independent (modulo the soft STDLOG↔STDDATE
edge above). Each is roughly 1–2 weeks for one contributor.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L1** | v0.0.2 | STDB64 | everything | RFC-4648 vectors at `tests/conformance/b64/`. **In progress.** |
| **L2** | v0.0.2 | STDHEX | everything | Bundled with L1 in v0.0.2 by convention; technically independent. |
| **L3** | v0.0.3 | STDFMT | everything | Printf subset of `str.format` |
| **L4** | v0.0.4 | STDLOG (text-only, inline ISO ts) | everything (soft dep on STDDATE; ships with inline helper) | **In progress** — module, tests, and per-module doc landed (45/45 assertions; 18/18 labels at 100%; 0 lint errors). IRIS portability job re-add (track A5) outstanding. |
| **L5** | v0.0.5 | STDDATE | everything | ISO-8601 + arithmetic |
| **L6** | v0.0.6 | STDCSV | everything | RFC-4180 + conformance corpus at `tests/conformance/csv/`. **Tests green (59/59); 100% label coverage; 0 lint errors. Pending merge.** |
| **L7** | v0.0.7 | STDARGS | everything | Uses `$ZCMDLINE` |
| **L4b** | v0.0.5+ | STDLOG bump to `$$NOW^STDDATE()` | merges after L4 + L5 | Trivial follow-on |

**Maximum parallelism for Phase 1: 7 tracks** (L1, L2, L3, L4, L5, L6, L7
all running simultaneously). Today's v0.0.2 sequence is a release
convention — nothing technical prevents L3–L7 from starting now.

### 3.2 m-stdlib Phase 1b — TDD primitives (M1)

Three tracks, mutually independent. None depend on any Phase 1 module.
Could in principle start before Phase 1 completes.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L8** | v0.1.1 | STDFIX | everything | TSTART/TROLLBACK isolation |
| **L9** | v0.1.2 | STDMOCK | everything | Opt-in `INVOKE^STDMOCK` |
| **L10** | v0.1.3 | STDSEED | works with STDFIX but does not require it | TSV manifest → `FILE^DIE`. JSON manifest add-on (LOADJSON) waits for STDJSON in M4. |

**Maximum parallelism for Phase 1b: 3 tracks.** Each pairs with a
m-cli companion track (W/X/Y in §3.4); the M companion is hard-blocked
on the stdlib track but is independent of the other two pairs.

### 3.3 m-stdlib Phase 2 — pure-M heavy lifting

All four tracks mutually independent.

| Track | Tag | Module | Independent of | Notes |
|---|---|---|---|---|
| **L11** | v0.2.0 | STDJSON | everything | RFC 8259; vendored JSONTestSuite |
| **L12** | v0.2.0 | STDREGEX | everything | Thompson-NFA YDB; `$MATCH`/`$LOCATE` IRIS |
| **L13** | v0.2.0 | STDCOLL | everything | Set/Map/Stack/Queue/Deque/Heap/OrderedDict. **Tests green (116/116); 100% label coverage (51/51); 0 lint errors.** Pending merge. |
| **L14** | v0.2.0 | STDURL | everything | RFC 3986; STDHTTP consumer in Phase 3 |

**Maximum parallelism for Phase 2: 4 tracks.**

### 3.4 m-cli companion tracks

Three categories:

**Independent of stdlib (start any time):**

| Track | Capability | Independent of | Notes |
|---|---|---|---|
| **C1** | TOOLCHAIN P1 fix: drop `^TESTRUN` hardcode in single-test runner | everything | Prereq for W/X/Y but not for itself |
| **C2** | `m test --format=junit` | everything | Pure Python; ~1–2 days |
| **C3** | `m test --coverage-min N` / `m coverage --min-percent N` | everything | Pure Python; ~1 day |
| **C4** | `m coverage --branch` | everything | **MVP shipped 2026-05-05** — branch-reach detection (line-level), text/JSON/LCOV output. True/false outcome split deferred (needs ZBREAK-style per-command instrumentation). |
| **C5** | `m test --changed` | everything | **Shipped 2026-05-05** — git-status / git-diff backed; reuses `m watch` affinity. `--changed-base REV` for diffing against a revision. |

**Hard-blocked on a specific stdlib module (start when that module ships):**

| Track | Capability | Blocked on | Notes |
|---|---|---|---|
| **W** | Runner SETUP/TEARDOWN wrap | L8 (STDFIX) ships | Single-line wrapper change |
| **X** | Runner `CLEAR^STDMOCK` between tests | L9 (STDMOCK) ships | Single line |
| **Y** | `m test --seed PATH` | L10 (STDSEED) ships | New CLI flag + load step |

W, X, Y are mutually independent of each other — they can be parallel
once their respective stdlib track is green.

**Hard-blocked on parent plan (vista-orchestration):**

| Track | Capability | Blocked on |
|---|---|---|
| **C6** | `m test --integration` | parent plan Phase 4 (integration harness) |

### 3.5 Auxiliary stdlib tracks (zero-dep on any module)

| Track | Work | Independent of | Notes |
|---|---|---|---|
| **A1** | Vendor RFC-4648 §10 vectors → `tests/conformance/b64/` | everything | Pure data; usable by L1 |
| **A2** | Vendor RFC-4180 corpus → `tests/conformance/csv/` | everything | Used by L6 |
| **A3** | Vendor JSONTestSuite → `tests/conformance/json/` | everything | Used by L11 |
| **A4** | Vendor RFC-4122 UUID vectors → `tests/conformance/uuid/` | everything | Reinforces v0.0.1 STDUUID |
| **A5** | IRIS portability CI job re-add (fail-soft) | everything | Currently bundled with L4; technically independent |
| **A6** | `tools/build-callouts.sh` for $ZF SOs (linux-x86_64, linux-aarch64, macOS) | everything | Phase 3 prereq; can start now |
| **A7** | `docs/modules/<m>.md` per module | the module itself | Each module's doc is independent of every other module's doc |

### 3.6 STDASSERT real-project migration tracks (per impl-plan §10.2)

Three independent migrations: STDASSERT consumed by adjacent
projects' test suites in place of `^TESTRUN`. Each is its own track;
none touch each other.

| Track | Repo | Notes |
|---|---|---|
| **V1** | m-cli — migrate M-side tests onto STDASSERT | Closes one of the TOOLCHAIN P2 entries |
| **V2** | tree-sitter-m — migrate `tests/` if any M-side suites use TESTRUN | Check `tests/` |
| **V3** | m-standard — migrate any `tests/` suites | Probably no-op; verify |

### 3.7 Parent-plan tracks orthogonal to m-stdlib (FYI)

These don't touch m-stdlib but unblock its consumers. Listed for
completeness.

| Track | Work | Owner repo |
|---|---|---|
| **P1** | tree-sitter-m v0.1 publish + prebuildify binaries | tree-sitter-m |
| **P2** | vista-meta README.md | vista-meta |
| **P3** | m-modern-corpus seeding (5–10 non-VA M projects) | m-modern-corpus |

---

## 4. Maximum-parallelism snapshot (today, 2026-05-05)

Given current state (v0.0.1 shipped; v0.0.2 in progress on L1; m-cli
Tier 1+2 done), the following tracks could **all** run simultaneously
with no coordination beyond merge ordering:

```
Phase 1 modules:    L1, L2, L3, L4, L5, L6, L7         (7 tracks)
Phase 1b modules:   L8, L9, L10                        (3 tracks)
Phase 2 modules:    L11, L12, L13, L14                 (4 tracks)
m-cli enhancements: C1, C2, C3, C4, C5                 (5 tracks)
Conformance:        A1, A2, A3, A4                     (4 tracks)
Aux:                A5, A6                             (2 tracks)
STDASSERT migrate:  V1, V2, V3                         (3 tracks)
Parent-plan adj.:   P1, P2, P3                         (3 tracks)
─────────────────────────────────────────────────
Total parallel-eligible:                               31 tracks
```

The release-tag sequence (v0.0.2 → v0.0.3 → … → v0.1.0 → …) is a
**merge ordering**, not a development ordering. With enough hands the
entire Phase-1 set could land in parallel and tag in numeric order
the day each one's gate goes green.

What you **cannot** parallelise:

- W, X, Y on top of L8, L9, L10 (each is hard-blocked on its stdlib
  pair, but the three pairs are independent of each other).
- L4-bump on top of L5 (trivial follow-on).
- STDHTTP on STDURL (Phase 3 → Phase 2 edge).
- STDHTTP / STDCRYPTO / STDCOMPRESS on `tools/build-callouts.sh`
  (one-time infra, then those three are mutually parallel).
- Phase release tags (v0.1.0 / v0.2.0 / v0.3.0) on **all** their
  member tracks — release is the synchronisation point.
- m-cli `--integration` (C6) on parent-plan Phase 4.

---

## 5. Synchronisation points

Where parallelism ends and a join is required:

| Sync | What joins | Why |
|---|---|---|
| **v0.1.0 release** | L1–L7 (and L4-bump after L5) | Phase 1 release tag; CHANGELOG roll-up; GitHub Release |
| **M1 close** | L8 + W; L9 + X; L10 + Y | Each (stdlib, m-cli) pair must ship together for the runner protocol to work |
| **v0.2.0 release** | L11–L14 + STDLOG-JSON add-on + STDSEED-JSON add-on | Phase 2 release tag |
| **Phase 3 entry** | A6 (build harness) before STDHTTP / STDCRYPTO / STDCOMPRESS | Build infra must work before any Phase 3 track starts |
| **v0.3.0 release** | All Phase 3 tracks + jwt-verify example | Phase 3 release |
| **v1.0.0** | 3 months of API stability after v0.3.0 | Time-based, not work-based |

---

## 6. Pick-list — what to dispatch right now

Given v0.0.1 shipped and v0.0.2 (L1) in flight, these are the
zero-blocked tracks ready to start today:

**Highest leverage** (unblock multiple downstream consumers):

- **L8 (STDFIX)** — unblocks W, m-cli runner protocol, every future
  test that wants isolation.
- **A6 (build-callouts.sh)** — unblocks all of Phase 3.
- **C1 (m-cli TOOLCHAIN P1 fix)** — closes one P1 finding; clears the
  publication gate for m-cli + tree-sitter-m.

**High velocity** (small, independent, finishable in a session):

- **L2 (STDHEX)** — already specced; bundle-mate to L1.
- **L3 (STDFMT)**, **L5 (STDDATE)**, **L6 (STDCSV)**, **L7 (STDARGS)** — each
  ~1–2 weeks for one contributor; all mutually parallel.
- **C2 (--format=junit)**, **C3 (--coverage-min N)** — each a day or
  two of m-cli Python work.
- **A1–A4 (conformance corpora)** — pure data vendoring, unblocks
  TDD-first work on the matching module.

**Medium velocity** (larger but still independent):

- **L9 (STDMOCK)**, **L10 (STDSEED)** — mutually parallel with L8.
- **L11 (STDJSON)**, **L12 (STDREGEX)**, **L13 (STDCOLL)**,
  **L14 (STDURL)** — Phase 2 modules; per existing plan they wait for
  v0.1.0 by convention, but technically have zero blockers today.
- **C4 (--branch coverage)** — tree-sitter-m nodes are present.
- **C5 (--changed)** — `WorkspaceIndex` is in place.

**Low priority but free** (do them when stuck on something else):

- **A5 (IRIS CI re-add)**, **V1/V2/V3 (STDASSERT migrations)**,
  **P1/P2/P3 (parent-plan adjacent)**.

---

## 7. Conventions for parallel work

So multiple tracks can land without stomping each other:

- **CHANGELOG.md fragments per track.** Each track adds a single
  bullet under an `## Unreleased` heading; the maintainer collapses
  them into the next tag's section at release time.
- **Plan §1 status table.** Each track edits exactly its own row;
  conflicts are line-level and trivial to resolve.
- **TODO.md.** Avoid editing during track work. Update only at
  milestone close.
- **TOOLCHAIN-FINDINGS.md.** Append-only during track work; renumber
  at milestone close.
- **`docs/modules/index.md`** (when it exists). Each track adds its
  own row; index regeneration at v0.1.0 / v0.2.0 / v0.3.0 release
  time absorbs the table.
- **m-cli companion PRs** ride alongside their stdlib track but live
  in `~/projects/m-cli/`. Track owner opens both branches, merges
  stdlib first, then m-cli.

---

## 8. Cross-references

- [tdd-orchestration-plan.md](tdd-orchestration-plan.md) — joint milestone narrative; this doc is the dispatch view.
- [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md) — per-module specs and §9 acceptance gate; this doc references them by track.
- [TOOLCHAIN-FINDINGS.md](../TOOLCHAIN-FINDINGS.md) — open m-cli / tree-sitter-m issues; track C1 closes the P1.
- [../../m-cli/TODO.md](../../m-cli/TODO.md) — m-cli's own track list (C1–C5 land here as work begins).
- [../../vista-meta/docs/vista-orchestration-plan.md](../../vista-meta/docs/vista-orchestration-plan.md) — parent plan; tracks P1–P3 belong to its scope.
