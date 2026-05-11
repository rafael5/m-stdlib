---
title: m-stdlib — master module development tracker
status: live (2026-05-10; all numbered tickets T1–T30 closed; 32 modules / 2483 assertions green on engine; Wave A discoverability + tooling plan closed at v0.5.0)
audience: anyone landing or proposing a module in m-stdlib.
authority: this file is the canonical "what's done / in flight" view for module-level work. All
  module-level commits MUST update the relevant row(s) here in the same commit.
companions: docs/tracking/README.md (the four-bucket doc model this tracker follows),
  docs/plans/future-modules-plan.md (proposal pipeline; promote rows from there into Table 1
  here), docs/tracking/parallel-tracks.md (dispatch view), docs/plans/m-stdlib-implementation-plan.md
  (per-module specs and §9 acceptance gate), docs/modules/index.md (canonical released-module index).
created: 2026-05-07
last_modified: 2026-05-10
revisions: 37
doc_type: [STATUS]
---

# m-stdlib — master module development tracker

This document is the canonical tracker for every shipped or in-flight
m-stdlib module. It is intentionally heavy tables / thin prose so a
glance answers: *what shipped*, *what's half-done*, *what's queued*.

**Where things live now** (per
[`README.md`](README.md) § four-bucket model):

- **This file** — current-state tracker (Summary table + per-module
  status). Module-level commits update rows here.
- **[`../modules/<m>.md` § History](../modules/)** — per-module
  archaeology (scaffolding history, migrations, engine deploy,
  T-ticket closes). Co-located with each module's API reference.
- **[`../plans/future-modules-plan.md`](../plans/future-modules-plan.md)**
  — proposal pipeline for candidates that haven't crossed TDD-red yet
  (was the old "Table 2"). Promote a row from there into the Summary
  table below the moment TDD-red is staked.
- **[`discoveries.md`](discoveries.md)** — issues that surfaced during
  implementation but weren't anticipated in the locked plan
  (cross-referenced from per-task progress logs).

**Process rule.** Any commit that touches a module's source, tests,
or per-module doc MUST update the relevant row(s) in the **Summary
table** below in the same commit. Demote nothing — completed modules
stay in the table forever as the historical record.

---

## Summary table — modules

Phase tags: **P1** = Phase 1 pure-M quick wins (`v0.0.x → v0.1.0`,
shipped 2026-05-05). **P1b** = Phase 1b TDD primitives
(`v0.1.1 → v0.1.3`, shipped 2026-05-05). **P2** = Phase 2 pure-M heavy
lifting (`v0.2.0`). **P3** = Phase 3 `$ZF`-bound callouts
(`v0.4.0`). **P4** = post-`v0.2.0` pure-M promotions out of the
proposals plan.

m-cli integration status legend: **✅** = companion shipped;
**n/a** = no m-cli companion needed for this module; **🟡** = pending
(blocked work); **🔮** = future / Phase 3 dependency.

Dependency column legend: **none** = pure-M, no internal or external
deps. **module name** = runtime call into that stdlib module.
**`$ZF → libname`** = host-call to a shared library (Phase 3 callout
boundary). **runtime-only** = needed at use-site, not at compile-time
(e.g. `FILE^DIE` for STDSEED's default filer). Soft / folded edges
are noted in parens.

**Done column.** Checkbox view of release status: `[x]` = the module's
shipped surface is its terminal state; `[ ]` = `T<n>` is actively
planned and the row hasn't reached its terminal state.

**ToDo column.** `none (completed)` = the shipped surface is the
final deliverable for this module. `none (options)` = module is
shipped; the T-ticket noted in the per-module
[`../modules/<m>.md` § History](../modules/) section is an **optional
add-on** that activates only when a concrete consumer drives it (it
is *not* gating any further work). A bare `T<n>` = work is actively
planned and the module's row is not yet at its terminal state.

**Effort unit.** Days of one experienced M developer working the
full TDD discipline: tests-first, implementation, §9 acceptance gate
(fmt + lint + test + coverage ≥ 85%), per-module doc, changelog
fragment. 1d ≈ 6–8 productive hours.

**Tag column.** Most recent released tag that includes the module's
current state.

| Done | Phase | Track | # | Module | Tag | Effort | ToDo | Dependency | Headline | m-cli integration |
|:----:|---|---|---|---|---|---|---|---|---|---|
| [x] | P1 | L0 | 1 | [`STDASSERT`](../modules/stdassert.md) | `v0.1.0` | 5d | none (completed) | none | Assertion library | ✅ C1 + C2 |
| [x] | P1 | L0 | 2 | [`STDUUID`](../modules/stduuid.md) | `v0.1.0` | 3d | none (completed) | none | RFC-4122 v4 + RFC-9562 v7 UUIDs | n/a |
| [x] | P1 | L1 | 3 | [`STDB64`](../modules/stdb64.md) | `v0.1.0` | 3d | none (completed) | none | RFC-4648 Base64 (std + URL-safe) | n/a |
| [x] | P1 | L2 | 4 | [`STDHEX`](../modules/stdhex.md) | `v0.1.0` | 1d | none (completed) | none | RFC-4648 §8 hex | n/a |
| [x] | P1 | L3 | 5 | [`STDFMT`](../modules/stdfmt.md) | `v0.1.0` | 5d | none (completed) | none | Printf-style (`str.format` subset) | n/a |
| [x] | P1 | L4 | 6 | [`STDLOG`](../modules/stdlog.md) | `v0.2.0` | 3d | none (completed) | STDDATE; STDJSON | Structured kv/json logger | n/a |
| [x] | P1 | L5 | 7 | [`STDDATE`](../modules/stddate.md) | `v0.1.0` | 5d | none (completed) | none | ISO-8601 datetime + duration arithmetic | n/a |
| [x] | P1 | L6 | 8 | [`STDCSV`](../modules/stdcsv.md) | `v0.1.0` | 4d | none (completed) | none | RFC-4180 CSV parse/write + file I/O | n/a |
| [x] | P1 | L7 | 9 | [`STDARGS`](../modules/stdargs.md) | `v0.1.0` | 4d | none (completed) | none | argparse (long/short/group/positional/`--`) | n/a |
| [x] | P1b | L8 | 10 | [`STDFIX`](../modules/stdfix.md) | `v0.2.0` | 3d | none (completed) | none | Per-test transactional isolation | ✅ C3 |
| [x] | P1b | L9 | 11 | [`STDMOCK`](../modules/stdmock.md) | `v0.2.0` | 3d | none (completed) | none | Test-time call interception | ✅ C4 |
| [x] | P1b | L10 | 12 | [`STDSEED`](../modules/stdseed.md) | `v0.2.0` | 3d | none (completed) | STDJSON; runtime-only `FILE^DIE` | TSV/JSON fixture loader + pluggable filer | ✅ C5 |
| [x] | P2 | L11 | 13 | [`STDJSON`](../modules/stdjson.md) | `v0.2.0` | 7d | none (completed) | none | RFC 8259 JSON parser + serialiser | n/a |
| [x] | P2 | L12 | 14 | [`STDREGEX`](../modules/stdregex.md) | `v0.2.0` | 10d | none (options) | none | Thompson-NFA regex (no back-refs / lookaround) | n/a |
| [x] | P2 | L13 | 15 | [`STDCOLL`](../modules/stdcoll.md) | `v0.2.0` | 5d | none (completed) | none | Set/Map/Stack/Queue/Deque/Heap/OrderedDict | n/a |
| [x] | P2 | L14 | 16 | [`STDURL`](../modules/stdurl.md) | `v0.2.0` | 5d | none (completed) | none | RFC 3986 URI parse/build/normalise/resolve | 🔮 C9 |
| [x] | P4 | L15 | 17 | [`STDCSPRNG`](../modules/stdcsprng.md) | `v0.3.0` | 1d | none (completed) | STDB64; STDHEX; STDUUID; `$ZF → getrandom(2)` (with `/dev/urandom` fallback) | Crypto random — bytes / hex / base64 / token / int / uuid4 | n/a |
| [x] | P4 | L16 | 18 | [`STDFS`](../modules/stdfs.md) | `v0.4.0` | 2d | none (completed) | `$ZF → libc open/read/write/close` | File-system primitives + byte-faithful I/O | n/a |
| [x] | P4 | L17 | 19 | [`STDOS`](../modules/stdos.md) | `v0.3.0` | 1d | none (options) | none | Process / env / cmdline helpers | n/a |
| [x] | P4 | L18 | 20 | [`STDSEMVER`](../modules/stdsemver.md) | `v0.3.0` | 1d | none (options) | none | SemVer 2.0.0 — valid / parse / compare / matches | 🔮 C10 |
| [x] | P4 | L19 | 21 | [`STDSTR`](../modules/stdstr.md) | `v0.3.0` | 1d | none (options) | none | String helpers (pad/trim/replaceAll/split/case-fold/repeat) | n/a |
| [x] | P4 | L20 | 22 | [`STDTOML`](../modules/stdtoml.md) | `v0.3.0` | 1d | none (options) | none | TOML 1.0 subset — top-level pairs + `[section]` tables | 🔮 C11 |
| [x] | P4 | L21 | 23 | [`STDCACHE`](../modules/stdcache.md) | `v0.3.0` | 1d | none (options) | none | LRU + TTL cache over caller-owned array | n/a |
| [x] | P4 | L22 | 24 | [`STDPROF`](../modules/stdprof.md) | `v0.3.0` | 1d | none (completed) | none | Wall-clock profiler — start/stop/count/total/mean/min/max/percentile | ✅ C6 |
| [x] | P4 | L23 | 25 | [`STDSNAP`](../modules/stdsnap.md) | `v0.3.0` | 1d | none (completed) | STDFS; STDASSERT | Snapshot testing — serialize/save/matches/asserts | ✅ C7 |
| [x] | P4 | L24 | 26 | [`STDENV`](../modules/stdenv.md) | `v0.3.0` | 1d | none (options) | STDFS | `.env` loader + typed accessors | ✅ C8 |
| [x] | P4 | L25 | 27 | [`STDXML`](../modules/stdxml.md) | `v0.4.0` | 14d | none (completed) | none | XML 1.0 + Namespaces 1.0 + XPath 1.0 + DTD envelope | n/a |
| [x] | P4 | L26 | 28 | [`STDMATH`](../modules/stdmath.md) | `v0.4.0` | 1d | none (completed) | none | Numeric helpers — clamp / min / max / sum / count / mean | n/a |
| [x] | P4 | L27 | 29 | [`STDXFRM`](../modules/stdxfrm.md) | `v0.4.0` | 1d | none (completed) | none | Higher-order array transforms — map / filter / reduce | n/a |
| [x] | P3 | H1 | 30 | [`STDCRYPTO`](../modules/stdcrypto.md) | `v0.4.0` | 2d | none (completed) | `$&stdcrypto.fn → libcrypto`; A6 | SHA-256/384/512 + HMAC-SHA-256/384/512 | 🟡 C12 |
| [x] | P3 | H2 | 31 | [`STDCOMPRESS`](../modules/stdcompress.md) | `v0.4.0` | 6d | none (completed) | `$&stdcompress.fn → libz + libzstd`; A6 | gzip / gunzip / deflate / inflate / zstdCompress / zstdDecompress | 🟡 C13 |
| [x] | P3 | H3 | 32 | [`STDHTTP`](../modules/stdhttp.md) | `v0.4.0` | 4d | none (options) | STDURL; `$&stdhttp.fn → libcurl`; A6 | HTTP/1.1 client + pure-M wire-format helpers | 🟡 C14 |

**Aggregate.** ~108d shipped across all 32 landed modules (sum of
the Effort column above). **Full engine suite green on `main`
2026-05-08: 32 suites, 2483/2483 assertions.** All three Phase 3
modules engine-green: STDCRYPTO H1 (23/23), STDCOMPRESS H2 (59/59),
STDHTTP H3 (68/68). **All numbered tickets T1–T30 closed.** Optional
add-ons (rows tagged `none (options)`: T15 / T16 / T17 / T18 / T19 /
T22 / STDHTTP iter 3) sit behind concrete-consumer drivers and are
not gating any release. Per-module deep history (scaffolding, migrations,
engine deploy, T-ticket close narratives) lives in each module's
[`../modules/<m>.md` § History](../modules/) section.

## m-cli integration short codes

(Full track names spelled out in
[`parallel-tracks.md` §3.4](parallel-tracks.md))

**Shipped:**

- **C1** = dynamic `^TESTRUN` / `^STDASSERT` protocol detection (m-cli `23241a2`).
- **C2** = m-tools test-suite migration TESTRUN→STDASSERT (m-tools `3eec0bf`).
- **C3** = runner SETUP/TEARDOWN wrap consuming STDFIX (m-cli `e5818bd`).
- **C4** = `do clear^STDMOCK` between tests (m-cli `e5818bd`).
- **C5** = `m test --seed PATH` flag consuming STDSEED (m-cli `e5818bd`).
- **C6** = `m test --timings` consuming STDPROF for subprocess-level wall-clock per suite via Python `time.perf_counter()`; STDPROF is the in-process API for finer-grained intra-suite timing (m-cli `8ef34a6`).
- **C7** = `m test --update-snapshots` consuming STDSNAP — sets `^STDLIB($JOB,"stdsnap","update")=1` so `asserts^STDSNAP` rewrites baselines (m-cli `8ef34a6`, m-stdlib `631b4e7`).
- **C8** = `m test --env PATH` consuming STDENV — repeatable; loads each `.env` via `parseFile^STDENV` (m-cli `8ef34a6`).

**Future / speculative** (no concrete consumer yet, listed for traceability):

- **C9** = STDHTTP (P3) consumer of STDURL — m-cli today uses Python `urllib.parse` on the host side; STDURL only enters m-cli through the future STDHTTP path.
- **C10** = `m install <pkg>@<range>` as consumer of STDSEMVER — m-cli is not a package manager today; speculative.
- **C11** = m-cli runtime config from `.m-cli.toml` via STDTOML — m-cli today reads config via Python 3.11+ stdlib `tomllib`; STDTOML would only land if config consumption moves to the M side.
- **C12** = STDCRYPTO P3 hookup — m-cli has no hashing / HMAC / signing path today; queued behind T28 close.
- **C13** = STDCOMPRESS P3 hookup — m-cli has no compression path today.
- **C14** = STDHTTP P3 hookup — m-cli today shells across SSH or uses Python `urllib`/`requests`.

### m-cli integrations not done — rationale

Eight P4 modules carry no *active* m-cli companion track. Six
(L15, L16, L17, L19, L21, L25) have **none planned**; L18 STDSEMVER
→ C10 and L20 STDTOML → C11 are tagged speculative. Each was
evaluated as an inner-loop binding and the answer was no for one of
three reasons: the function is **not part of the dev inner loop**,
the function is **already covered by the Python CLI side** (Python's
stdlib does the job natively and m-cli's host code is Python), or the
function is **for M consumers of m-stdlib** rather than for m-cli's
own toolchain flows. Per-module:

- **L15 STDCSPRNG** — *Not inner-loop.* m-cli doesn't generate security tokens or signing salts. Consumers are downstream M apps; m-cli has no need.
- **L16 STDFS** — *Replicated in Python CLI interface.* m-cli's host code uses `pathlib.Path`, `os`, `tempfile`, `shutil` natively — richer than STDFS. STDFS is for M-side consumers.
- **L17 STDOS** — *Replicated in Python CLI interface.* `os.environ`, `sys.argv`, `subprocess`, and `shlex.split` cover the same surface in Python. STDOS is for M code that needs to escape `$ZTRNLNM` portability quirks.
- **L18 STDSEMVER** — *Not inner-loop, not used today.* m-cli has no `m install <pkg>@<range>` command. Python's `packaging.version` is the host-side equivalent if a package manager is ever built.
- **L19 STDSTR** — *Replicated in Python CLI interface.* `str.ljust`, `str.strip`, `str.replace`, `str.split`, `str.lower`, etc. cover every helper natively.
- **L20 STDTOML** — *Replicated in Python CLI interface.* m-cli already reads config via Python `tomllib`. STDTOML is for M-side config consumers.
- **L21 STDCACHE** — *Lower value for end-user CLI.* m-cli is short-lived per-invocation (every `m test` is a fresh Python interpreter). No persistent state for a cache to warm.
- **L25 STDXML** — *Not inner-loop.* m-cli has no XML in any of its flows. STDXML's documented consumer is vista-meta's HL7v3 / CDA / FHIR pipeline.

## Aggregate gate, current head (2026-05-10)

**32 suites, 2483/2483 assertions green on the vista-meta YDB
engine** (full m-stdlib surface — every public extrinsic exercised
end-to-end through `m test`). Per-module label coverage ≥ 91% (most
at 100%; STDOS at 91.7%, STDENV at 93.3% — `exit()` and `parseFile()`
respectively unreachable / un-tested by automated tests), 0 lint
errors, fmt clean.

`v0.5.0` shipped (commit `a75137d`); the
[`discoverability-tracker.md`](discoverability-tracker.md) Wave A
work program closed at this tag.

---

## Open work

All numbered tickets T1–T30 are closed. There is no in-flight
module-level work as of 2026-05-10. Optional add-ons exist for seven
modules (rows tagged `none (options)` in the Summary table) but
none is gating any further release; each is on a "reopen when a
concrete consumer drives it" basis.

The proposal pipeline for new modules lives in
[`../plans/future-modules-plan.md`](../plans/future-modules-plan.md).
Active proposals: STDYAML (12-18d est.), STDNET (8-14d est.) — both
deferred until a concrete consumer drives them.

When a new ticket opens, follow the per-task narrative template in
[`README.md`](README.md) § Bucket 2:

```markdown
### T<n> — <title>

**Status.** in-progress | blocked | done.
**Goal.** One paragraph.
**Approach.** Bullets.
**Acceptance.** What "done" means.
**Out of scope.** What's deliberately not done.
**Progress log.**
- 2026-MM-DD — what landed; commit SHA; any follow-ups.
```

---

## Closed tickets — archaeology

T1–T30 narratives preserved here as the historical record. Module-
specific ticket content is also surfaced in each module's
[`../modules/<m>.md` § History](../modules/) section. Cross-cutting
tickets (T1, T2, T3, T6, T7, T11) live only here.

### T1 — STDASSERT.raises P1 (resolved 2026-05-06; downstream closed 2026-05-07)
**Status:** ✅ **closed.** Library-level fix shipped via ZGOTO unwind;
all downstream re-enables (T2, T3) completed in the same series of
commits leading into the v0.2.0 release sync.
**What it was:** `$ETRAP` arg-less `quit` was illegal in
extrinsic-function chains and triggered `%YDB-E-NOTEXTRINSIC` (M17),
cascading into `Z150374554` and clobbering the captured `$ECODE`.
Surfaced building STDFMT and re-surfaced under every module that
drove errors through extrinsic chains: STDFMT (6 tests), STDDATE,
STDCSV, STDLOG L4 add-on (7 tests), STDSEED L10 add-on (4 tests).
**What fixed it:** `raises^STDASSERT` now captures
`raisesLvl=$zlevel` at trap-set time and the trap unwinds via
`zgoto raisesLvl:raisesUnwound^STDASSERT` instead of arg-less `quit`.
Verified by `tFormatInvalidRaises` in STDLOGTST. Reference:
[`discoveries.md`](discoveries.md) row 2026-05-05 P1.

### T2 — Re-enable parked `raises`-path tests in STDFMT / STDDATE / STDCSV
**Status:** ✅ **closed 2026-05-07.**
**Outcome:**
- **STDFMT 56 → 62 assertions** — six new raises tests added covering all four `U-STDFMT-*` codes (UNCLOSED-BRACE, UNESCAPED-RBRACE, UNKNOWN-TYPE, MISSING-ARG ×3).
- **STDDATE 60 → 66 assertions** — three previously-defined-but-undispatched raises labels (`tFromhRejectsEmpty`, `tTohInvalidRaisesEcode`, `tStrptimeInvalidRaisesEcode`) wired into the dispatcher.
- **STDCSV** — file-open-fail path documented as a separate refactor: STDCSV's `open … else  set $ecode=…` pattern only catches OPEN *timeouts*, not immediate file-not-found errors (which fire `$ETRAP` directly with the underlying YDB code). A raises-test would observe the YDB code, not `U-STDCSV-OPEN-FAIL`. Suite header notes this; explicit OPEN-fail trapping deferred.

### T3 — STDLOG-JSON / STDSEED-loadJson `raises`-path tests parked under STDJSON-encode P1
**Status:** ✅ **fully closed 2026-05-07.**
**Outcome:**
- **STDLOG 48 → 62 assertions** — all six JSON-emission tests run. Two passed after T6's STDJSON refactor; the four that probe the parsed tree via `$$valueOf^STDJSON(.tree("k"))` were unblocked by the merge-then-pass refactor in commit `fb48f39` (per the `.x(SUBS)` syntax-limit diagnosis below — see T6 / [`discoveries.md`](discoveries.md) row 2026-05-06).
- **STDSEED 25 → 35 assertions** — all six loadJson tests run. Unblocked by the `raises^STDASSERT` `use $principal` trap fix (commit `e637425`) which resolves the SEQ-device + ZGOTO-unwind hang inside `walk^STDSEED`'s file-read loop.

### T4 — STDFIX lint findings cleanup
**Status:** ✅ **closed 2026-05-07** (already resolved earlier).
`m lint --error-on=error` is clean project-wide (0 errors); the
TODO description was stale. STDFIXTST has the appropriate
`m-lint: disable-file=M-MOD-020` and `disable-next-line=M-MOD-026`
directives. Remaining findings are severity-S (suggestions:
M-MOD-001 line length, M-MOD-009 commands per line) — they don't
gate the §9 acceptance check.

### T5 — STDFIX explicit re-raise contract not asserted in tests
**Status:** ✅ **closed at the documentation level 2026-05-07**;
upstream YottaDB fix still pending.
The rollback + scope-cleanup observables are verified by the
existing STDFIXTST suite; the re-raise contract remains
documented-but-untested in `docs/modules/stdfix.md`'s
"Caveats" / Errors section, with the deferral cause clarified
(YottaDB P2 — `$ETRAP`-driven `trollback` of its own scope does
not propagate `$ECODE` to the outer trap — [`discoveries.md`](discoveries.md)
row 2026-05-05 P2). Closing this row from the tracker; the
upstream-bug item itself stays open in [`discoveries.md`](discoveries.md)
until fixed.

### T6 — STDJSON `$$encode` extrinsic-chain P1
**Status:** ✅ **fully closed 2026-05-07.**
**Diagnosis (corrected):** initial hypothesis ("YDB-harness
subscripted-by-ref crash") was wrong. Direct `mumps -run` repro
shows it's a **documented YDB syntax limit**: `.x(SUBS)` is invalid
syntax in YottaDB r2.02 — `%YDB-E-COMMAORRPAREXP` at compile time.
Standard ANSI M permits only `.x` (whole local) by reference; YDB
does not extend that. Canonical workaround: **merge-then-pass**.
[`discoveries.md`](discoveries.md) row 2026-05-06 was demoted from
P1 to `docs` and marked resolved.
**Fixes applied:**
- `src/STDJSON.m` (commit `c3a0880`): `encodeArray` / `encodeObject` recurse via `merge tmp=node(k)` + `$$encodeValue(.tmp)` (read-only); `parseObject` / `parseArray` via `do parseValue(.ctx,.tmp)` + `merge node(k)=tmp` (write-back).
- `tests/STDLOGTST.m` (commit `fb48f39`): 4 deferred JSON-emission tests refactored to merge-then-pass via `sub` local; also `do parse^STDJSON(...)` → `set ok=$$parse^STDJSON(...)` (parse is extrinsic-form, calling as procedure fires M17).
- `tests/STDJSONTST.m` (commits `0343b13` + `e159147`): 23 + 4 caller-side `.x(SUBS)` sites refactored to merge-then-pass; `parseStringValue` `\u<hex>` escape fall-through fixed (one-line `quit` postcondition); `tEncodeArrayWithGapRaises` rewritten to drop fragile cross-frame `goto pop` from $ETRAP.

**Verified:** STDJSONTST 209/209 green (was crashing at #55).
Aggregate gate: 16 suites, **1222/1222 assertions**.

### T7 — v0.2.0 release sync
**Status:** ✅ **shipped 2026-05-07.**
**Outcome:** changelog `## [Unreleased]` collapsed into a new
`## [v0.2.0] — 2026-05-07` section that covers STDJSON, STDREGEX,
STDCOLL, STDURL, STDLOG-JSON add-on, STDSEED-loadJson add-on, plus
the rolled-in Phase 1b minor tags (STDFIX `v0.1.1`, STDMOCK
`v0.1.2`, STDSEED `v0.1.3`). `docs/modules/index.md` regenerated to
absorb all v0.2.0 modules and add Phase 2 conformance corpora
(`tests/conformance/{json,url,uuid}/`). Cross-module dependency
section refreshed for the L4-→STDJSON and L10-→STDJSON edges. Git
tag `v0.2.0` cut and pushed.

### T8 — STDSEED `fileViaDie` real-FileMan integration
**Status:** ✅ **closed at the documentation level 2026-05-07**;
explicit FileMan integration test deferred to a future minor.
The label compiles and is observably correct against any FileMan
host (manual smoke runs against vista-meta succeed); the gap is
test-coverage (10/11 = 90.9% labels), not implementation. The
real-FileMan integration path is documented in
`docs/modules/stdseed.md` as a v0.1.4-or-later scoped follow-on,
gated by STDFIX `with`/`invoke` for rollback safety. The 10/11
gate already exceeds the §9 threshold (≥85%), so this is a
coverage-quality wish, not a release blocker.

### T9 — STDREGEX `classEscape` coverage gap
**Status:** ✅ **closed 2026-05-07.** Five new tests added
(`tClassDigitEscape`, `tClassWordEscape`, `tClassSpaceEscape`,
`tClassLiteralEscape`, `tClassRangeViaEscape`) exercise `\<x>`
inside character classes for all three predefined symbol families
(`\d`, `\w`, `\s`), literal escapes (`\.`, `\-`), and a
range-via-escape (`[\t-\n]`). STDREGEX 90 → 102 assertions;
per-module label coverage 98.3% → **100% (59/59)**.

### T10 — STDREGEX IRIS native `$MATCH` / `$LOCATE` dispatch
**Status:** ✅ **closed at the documentation level 2026-05-07.**
The pure-M Thompson-NFA engine runs unchanged on IRIS for the
entire v0.2.0 subset — IRIS portability is **not** a blocker.
What was deferred is a perf-only follow-up: native `$MATCH` /
`$LOCATE` dispatch for the simple-pattern subset (with
`%Library.RegEx` for captures). Documented as a perf-follow-up in
`docs/modules/stdregex.md`'s "IRIS portability" section; the
`iris-portability-check` CI job continues to surface any
regressions in fail-soft mode without gating merges.

### T11 — Phase 3 entry (STDCRYPTO, STDCOMPRESS, STDHTTP)
**Modules affected:** STDCRYPTO, STDCOMPRESS, STDHTTP.
**Status:** ✅ **closed 2026-05-07.** All three Phase 3 modules now
green on the vista-meta YDB engine via `make test`: STDCRYPTOTST 23/23,
STDCOMPRESSTST 59/59, STDHTTPTST 68/68. Aggregate gate this session:
**32 suites, 2483/2483 assertions** across the full m-stdlib surface.
**Sequencing recap:**
1. ✅ v0.2.0 release sync (T7) — closed when v0.3.0 shipped 2026-05-07.
2. IRIS `$ZF` portability spike — deferred behind the YDB-side green run; validate against `intersystemsdc/iris-community:latest` next.
3. ✅ STDCRYPTO chosen as the lead (closed T28).
4. ✅ STDCOMPRESS green-run (closed T30 via dispatch-status-return refactor + 6 tests migrated to `raises^STDASSERT` idiom).
5. ✅ STDHTTP iter 2 green-run (closed T29).

**Per-module specs:** [`../plans/m-stdlib-implementation-plan.md`](../plans/m-stdlib-implementation-plan.md) §12.

### T12 — STDCSPRNG `$ZF → getrandom(2)` callout backend (resolved 2026-05-07)
**Module:** STDCSPRNG.
**Status:** ✅ **closed 2026-05-07.** Both backends now coexist:
the new `cs_random` callout (`$ZF → getrandom(2)`) is tried first, the
existing `/dev/urandom` `READ *b` loop is the soft-fall-back. Same
kernel ChaCha20 pool either way — API stable, callers unchanged.
**What landed:**
- `src/callouts/cs_random.c` — single `cs_random(n, out)` entry; loops over `getrandom(2)` until `n` bytes are filled (handling the 256-byte syscall cap and `EINTR` retry); writes through caller's `ydb_string_t*` buffer (1 MiB capacity declared in the .xc).
- `tools/std_csprng.xc` — call-in descriptor; consumes `STDLIB_LIB` the same way `std_crypto.xc` and `std_http.xc` do.
- `src/STDCSPRNG.m` — new `$$useCallout^STDCSPRNG()` probe (env-var fast-path → 1-byte probe via the callout) and internal `dispatchRandom(n)` helper (XECUTE-wrapped `$ZF` to dodge m fmt's longest-prefix mangle of `$ZF → $zfind`; same trick as STDCRYPTO / STDHTTP / STDCOMPRESS). `$$bytes` tries `dispatchRandom` first; on empty return (env unset, .so missing, getrandom(2) failure) falls back to the device-read path (now factored out as `bytesFromDevice`).
- `tests/STDCSPRNGTST.m` — added `tUseCalloutReturnsBoolean`; suite green at 406/406 with the callout undeployed (soft-fall-back path).
**Reference:** `docs/modules/stdcsprng.md` "Entropy source" section.

### T13 — STDFS native append + native I/O backend ✅ **CLOSED 2026-05-08**
**Module:** STDFS.
**Status:** closed. New `do appendBytes^STDFS(path, data)` extrinsic
calls `$ZF → stdfs_appendBytes` which issues
`open(O_WRONLY|O_CREAT|O_APPEND)` + a single looped `write(2)` —
atomic at EOF, no lseek race, no SEQ-device byte-0 quirk, no implicit
trailing LF. The text-mode `append^STDFS` keeps its read-then-rewrite
implementation by design: rerouting it through native `O_APPEND` would
leave an interior LF in the file whenever the previous content already
ended with one, breaking the documented `readFile(append(x, y)) ==
readFile(x) + y` contract. Callers that want byte-faithful append at
EOF use `appendBytes` directly; callers that want text-mode "concat
+ trailing LF" semantics keep using `append`.

### T14 — STDFS binary-safe `readBytes` / `writeBytes` ✅ **CLOSED 2026-05-08**
**Module:** STDFS.
**Status:** closed. `$$readBytes^STDFS(path)` and
`do writeBytes^STDFS(path,data)` go through `$ZF → stdfs_readBytes` /
`stdfs_writeBytes` which issue raw `open(2)` / `read(2)` / `write(2)`
at the libc layer — no trailing LF added on write, no CR/LF
normalisation on read, exact byte counts preserved. 16 MiB per-call
output cap is declared in the `.xc` descriptor; oversize reads surface
`,U-STDFS-READ-TRUNCATED,` rather than silently truncating. The
text-I/O entries (`readFile` / `writeFile` / `readLines` /
`writeLines`) keep their POSIX text-file semantics.

### T15 — STDOS `setenv` / quote-aware `splitArgs` / IRIS arm
**Module:** STDOS.
**Status:** queued; STDOS ships in v0.2.x with read-only env access,
whitespace-only `splitArgs`, YDB-only intrinsics (`$ZTRNLNM`, `$JOB`,
`$ZCMDLINE`, `ZHALT`). Three deferred features:
1. `setenv(name, val)` — needs `$ZF → libc setenv(3)`.
2. Quote-aware `splitArgs` — preserve embedded spaces inside `'...'` and `"..."`.
3. IRIS arm — `$CLASSMETHOD %SYSTEM.Util.GetEnviron()` / `%SYS.System` for env / pid / cwd / hostname.

### T16 — STDSEMVER range syntax extensions
**Module:** STDSEMVER.
**Status:** queued; STDSEMVER ships in v0.2.x with a deliberately
narrow range subset (exact / `>` `<` `>=` `<=` `=` / `^` / `~` / AND).
The remaining npm-flavour range constructs (`||` OR, hyphen ranges,
wildcard placeholders, prerelease-aware comparators, zero-major
narrowing) are documented as deferred. Schedule when a concrete
consumer (m-cli `m install`, or another package-manager-style use
case) drives the requirement.

### T17 — STDSTR Unicode whitespace + locale-aware case folding
**Module:** STDSTR.
**Status:** queued behind a future STDUNICODE module. STDSTR v1's
`trim` family handles only ASCII space / tab / LF / CR;
`toLowerASCII` / `toUpperASCII` only fold the 26 unaccented Latin
letters. Unicode whitespace classes and locale-aware case folding are
deliberately out of scope. Activates when STDUNICODE arrives.

### T18 — STDTOML out-of-scope features
**Module:** STDTOML.
**Status:** queued. STDTOML v1 covers the practical 80% subset
(top-level pairs + `[section]` tables + four scalar types + comments).
Remaining TOML 1.0 surface deferred: arrays, inline tables, dotted
keys, `[[array-of-tables]]`, multi-line / literal strings, integer
literal extensions, special floats, exponent notation, datetime
values. Schedule when a concrete consumer drives the requirement.

### T19 — STDCACHE STDCOLL rebase + `prune` operation
**Module:** STDCACHE.
**Status:** queued. STDCACHE v1 inlines its bookkeeping. Two follow-ups
make sense once a concrete consumer exposes them: rebase onto STDCOLL's
OrderedDict; explicit `prune^STDCACHE(.cache)` for batch expired-entry
sweeps. v1 is correct and bounded; neither is urgent.

### T20 — STDPROF streaming-percentile via STDCOLL Heap (CKMS sketch)
**Module:** STDPROF.
**Status:** ✅ **closed 2026-05-07** as won't-fix-without-consumer-driver.
The only consumer today is m-cli `m test --timings` (C6), which calls
`percentile()` once per tag at end-of-run — the exact one-shot report
the v1 walk is sized for. Reopen if a real caller hits the linear-walk
limitation.

### T21 — STDSNAP root-scalar + auto-update + diff helper (closed 2026-05-07)
**Module:** STDSNAP.
**Status:** ✅ **closed.** STDSNAP v1 + C7's update mode is the final
deliverable; item 2 (auto-update) was delivered via C7's
`^STDLIB($JOB,"stdsnap","update")=1` global mechanism (m-stdlib
`631b4e7`, m-cli `8ef34a6`); items 1 (root-scalar) and 3 (diff helper)
closed as won't-fix-without-consumer-driver.

### T22 — STDENV out-of-scope features
**Module:** STDENV.
**Status:** queued. STDENV v1 covers the practical 80% of `.env`
files. Remaining dotenv conventions deferred: variable substitution
(`${VAR}` / `$VAR`), `export` prefix, multi-line values,
process-environment write-back via STDOS `setenv` (T15).

### T23-T27 — STDXML deferred features
**Module:** STDXML.
**Status:** ✅ **all resolved**: T23/T24/T25/T25b/T27v0/T27a/T27b on
2026-05-07; **T26 closed 2026-05-08**. STDXML now covers the full
12-16d XML 1.0 + Namespaces 1.0 + XPath 1.0 + DTD envelope (internal
subset + `<!ENTITY>` custom entities). STDXMLTST 209/209 green on
engine. Per-ticket detail (CDATA / PI / comments / xml-decl;
numeric refs; element + attribute namespaces; XPath wildcards /
attribute axis / functions / comparison predicates; DTD) lives in
[`../modules/stdxml.md` § History](../modules/stdxml.md).

### T28 — Engine-bound deployment for STDCRYPTO
**Status:** ✅ **closed 2026-05-07.** STDCRYPTOTST runs 23/23 against
the vista-meta YDB engine via `make test`. Per-module label coverage
17/17 = 100%; lint clean. Per-step deployment narrative
(C-side argc fix; M-side dispatch rewrite from `$ZF` →
`$&stdcrypto.<fn>`; descriptor LHS rename; `seed-callouts.sh`
package-name strip; `$etrap` body returns value; `$etrap` propagation
flow) lives in
[`../modules/stdcrypto.md` § History](../modules/stdcrypto.md).
The same per-module-deployment pattern was applied to STDCOMPRESS
(T28 follow-on) and STDHTTP iter 2 (T29).

### T29 — STDHTTP iteration 2 (libcurl callout)
**Module affected:** STDHTTP (H3 P3).
**Status:** ✅ **closed 2026-05-07.** STDHTTPTST runs 68/68 against
the vista-meta YDB engine via `make test` with the http.so deployed.
Per-module label coverage 94.1%; lint clean. Implementation detail
(libcurl glue in `src/callouts/http.c`, `tools/std_http.xc`
descriptor, M-side wiring through XECUTE-wrapped
`$&stdhttp.http_perform`, soft-fail on missing descriptor) lives in
[`../modules/stdhttp.md` § History](../modules/stdhttp.md).
**IRIS arm (iteration 3):** deferred. The `%Net.HttpRequest`
`$CLASSMETHOD` arm shares the same M-side req/resp shape and lands
when the IRIS portability spike unblocks behind T28.

### T30 — STDCOMPRESS / STDCRYPTO `$ECODE` channel redesign
**Modules affected:** STDCOMPRESS (H2 P3), STDCRYPTO (H1 P3).
**Status:** ✅ **closed 2026-05-07** — STDCOMPRESSTST now 59/59 green.

**Resolution shape (different from the originally-sketched global
side-channel).** No `^STDLIB($JOB,…)` global needed; the simpler
fix was to make `dispatchC` / `dispatchD` return a status string
("" / "MISSING" / "FAIL") and have each public extrinsic
(`gzip` / `gunzip` / `deflate` / `inflate` / `zstdCompress` /
`zstdDecompress`) map that status to the appropriate `$ECODE` tag
*after* the dispatch's local `$etrap` is out of scope. Since the
public extrinsic has no local `$etrap`, the caller's trap fires
cleanly when `$ecode` goes non-empty.

**Test-side companion change.** Six tests in `tests/STDCOMPRESSTST.m`
migrated from the manual `set $etrap="set $ecode="""" quit"` +
`contains^STDASSERT` pattern to `raises^STDASSERT` — the standard
m-stdlib idiom (already used by STDFMT / STDDATE / STDCSV / STDLOG).

**STDCRYPTO impact:** none required — STDCRYPTOTST has no failure-
path `$ECODE`-contains assertions, so the latent bug in
`dispatch3` / `dispatch4` is not exercised. If a future test does
exercise the failure paths, STDCRYPTO can adopt the same
status-return refactor (~0.5d).

**Side fix in this session:** `src/STDXFRM.m` regression — name
indirection migrated to XECUTE. Detail in
[`../modules/stdxfrm.md` § History](../modules/stdxfrm.md).

---

## Must-know — sequencing, dependencies, conventions

**Read these before starting work on any module or combination of
modules.** None of the rules below are enforced by tooling — they are
enforced by review.

### Architectural priority

- **m-stdlib has priority over m-cli.** When both projects need a utility, it lands in m-stdlib first; m-cli imports. This rule lives in `~/projects/m-stdlib/CLAUDE.md` and the project README.
- **GT.M is permanently out of scope.** Anyone forking m-stdlib for GT.M would need to remove the `view "TRACE"` coverage hooks and the `tstart` rollback levels. Locked decision.

### Dependency map (the only edges that block parallelism)

Per [`parallel-tracks.md` §2](parallel-tracks.md):

| Consumer | Dependency | Type | Notes |
|---|---|---|---|
| STDLOG (`v0.0.4`) | STDDATE (`v0.0.5`) | Soft (folded) | L4b folded into L4 release because L5 landed first; the inline-ts interim was never cut. |
| m-cli runner SETUP/TEARDOWN wrap | STDFIX (`v0.1.1`) | Hard | shipped — m-cli `e5818bd` |
| m-cli runner CLEAR^STDMOCK | STDMOCK (`v0.1.2`) | Hard | shipped — m-cli `e5818bd` |
| m-cli `--seed PATH` | STDSEED (`v0.1.3`) | Hard | shipped — m-cli `e5818bd` |
| STDLOG JSON-line output | STDJSON (`v0.2.0`) | Hard | landed on `main` — see T3, T6 |
| STDSEED `loadJson` | STDJSON (`v0.2.0`) | Hard | landed on `main` — see T3, T6 |
| STDHTTP | STDURL (`v0.2.0`) + `tools/build-callouts.sh` | Hard | both shipped; STDHTTP iter 1 (pure-M helpers) landed; iter 2 (libcurl callout) closed at T29 |
| STDCRYPTO / STDCOMPRESS | `tools/build-callouts.sh` | Hard | A6 shipped; closed at T11 |

Everything else is independent — tracks for different modules can run
in parallel without coordination beyond merge ordering.

### Synchronisation points

Tags merge in dependency order, but **development can run in
parallel**: a track for STDARGS (`v0.0.7`) can produce a green
branch before STDFMT (`v0.0.3`) merges. The joins are at release-tag
time, not development time:

| Sync | Status | What joins |
|---|---|---|
| `v0.1.0` release | ✅ shipped 2026-05-05 | L1–L7, L4b |
| `M1` close | ✅ shipped 2026-05-05 | L8+W, L9+X, L10+Y |
| `v0.2.0` release | ✅ shipped 2026-05-07 | L11–L14 + STDLOG-JSON + STDSEED-loadJson |
| `v0.3.0` release | ✅ shipped 2026-05-07 | P4 wave (L15–L24) |
| `v0.4.0` release | ✅ shipped 2026-05-08 | L25 (STDXML), L26 (STDMATH), L27 (STDXFRM), H1–H3 (Phase 3) |
| `v0.5.0` release | ✅ shipped 2026-05-08 | Wave A discoverability + tooling (manifest + frontmatter + CI gate) |
| `v1.0.0` | 🟡 queued (time-based) | 3 months of API stability after `v0.5.0` |

### Deferred decisions — revisit triggers

Decisions intentionally deferred. Each row records the deferred
choice, the trigger condition that should re-open it, and the
plan-doc location of the original analysis. Source:
[`../plans/discoverability-and-tooling-plan.md`](../plans/discoverability-and-tooling-plan.md)
§ 11.

| ID | Deferred decision | Default in effect | Revisit when | Source |
|---|---|---|---|---|
| D1 | Build an HTML / GitHub Pages docs site (`dist/site/`) generated from the manifest + `docs/modules/*.md` | Markdown-only; humans read on GitHub | A non-maintainer adopts m-stdlib, **or** a second human contributor lands a module | discoverability-and-tooling-plan.md § 5.2, § 11.1 |
| D2 | Turn on the `@stable` SemVer CI gate (manifest diff at HEAD vs last tag fails on `stable` regressions outside a major bump) | Annotation ships with Wave A; gate stays off | v1.0 is being planned, **or** a non-maintainer consumer adopts m-stdlib, whichever comes first | discoverability-and-tooling-plan.md § 3.6, § 11.2 |
| D3 | Replace the hand-rolled `tools/gen-manifest.m` parser with a tree-sitter-m–driven generator | Hand parser (~150 LoC) ships in Wave A | tree-sitter-m hits a stable v1, **or** the manifest generator needs language features beyond labels + doc comments | discoverability-and-tooling-plan.md § 3.2, § 11.4 |

These rows are deliberately not Tn tickets — Tn is for active or
queued work; these are conditional re-openings. Promote a row to a
Tn ticket the moment its trigger fires.

### Per-module acceptance gate (§9 of the implementation plan)

Every module must pass these before its `vN.N.N` tag:

| Gate | Tool | Pass threshold |
|---|---|---|
| Format | `m fmt --check` | clean (no diffs) |
| Lint | `m lint --error-on=error` | 0 errors |
| Tests | `m test --format=tap` | 100% assertions pass |
| Coverage | `m coverage --min-percent=85` | ≥ 85% per-module label coverage (most modules ship at 100%) |
| IRIS portability | `iris-portability-check` CI job | fail-soft — surfaces regressions but does not gate merges |

### TDD discipline (non-negotiable)

Per `~/.claude/CLAUDE.md` and [`../guides/users-guide.md`](../guides/users-guide.md) §2:

1. Write `tests/STDxxxTST.m` with realistic fixtures.
2. Run — confirm a deliberate red.
3. Implement `src/STDxxx.m`.
4. Run — confirm green.
5. `make check` (fmt-check + lint + test) before commit; `make coverage` before tag.

`m fmt` and `m lint --error-on=error` run automatically as a
PostToolUse hook on every Edit/Write of a `.m` file; lint errors come
back as a system reminder mid-turn.

### Conventions for parallel work (so multiple tracks don't stomp each other)

Per [`parallel-tracks.md` §7](parallel-tracks.md):

- **changelog.md fragments per track.** Each track adds one bullet under `## [Unreleased]`; release sync collapses to the next tag.
- **§1 status table in implementation-plan.md.** Each track edits its own row only; conflicts are line-level.
- **TODO.md.** Avoid editing during track work; update at milestone close.
- **discoveries.md.** Append-only during track work; renumber at milestone close.
- **`docs/modules/index.md`.** Each track adds its own row; regeneration at release time absorbs the table.
- **`module-tracker.md` (this file).** Updated **in the same commit** as any module-level change. Both tables are line-level mergeable; conflicts at the row level only.
- **m-cli companion PRs.** Ride alongside their stdlib track but live in `~/projects/m-cli/`. Track owner opens both branches, merges stdlib first, then m-cli.

### Status / state docs (read in this order for a cold start)

1. `~/projects/m-stdlib/CLAUDE.md` — project status banner; the "what shipped, what's next" one-screen view.
2. [`../guides/users-guide.md`](../guides/users-guide.md) — TDD-first walkthrough; module narrative in §4 and §5.
3. [`README.md`](README.md) — the four-bucket doc model; what goes where.
4. **This file** — canonical module tracker.
5. [`parallel-tracks.md`](parallel-tracks.md) — dispatch view; what to pick up.
6. [`../plans/m-stdlib-implementation-plan.md`](../plans/m-stdlib-implementation-plan.md) — per-module specs + §9 acceptance gate.
7. [`discoveries.md`](discoveries.md) — open + resolved discoveries (in-project pivots + external toolchain findings).
8. [`changelog.md`](changelog.md) — release history.
9. [`TODO.md`](TODO.md) — resume-here pointer; small.

## Cross-references

- [`README.md`](README.md) — the four-bucket doc model that this tracker follows.
- [`../guides/users-guide.md`](../guides/users-guide.md) — narrative § companion.
- [`parallel-tracks.md`](parallel-tracks.md) — dispatch view (track IDs, track-level state).
- [`../plans/m-stdlib-implementation-plan.md`](../plans/m-stdlib-implementation-plan.md) — per-module specs (§8 P1, §11 P2, §12 P3) and §9 acceptance gate.
- [`../plans/future-modules-plan.md`](../plans/future-modules-plan.md) — proposal pipeline (was Table 2 here).
- [`../plans/tdd-orchestration-plan.md`](../plans/tdd-orchestration-plan.md) — joint m-stdlib ↔ m-cli milestone narrative (M0–M5).
- [`../modules/index.md`](../modules/index.md) — released-module canonical index (regenerated each release).
- [`discoveries.md`](discoveries.md) — discoveries register: in-project pivots + external toolchain findings.
- [`changelog.md`](changelog.md) — release history.
- [`TODO.md`](TODO.md) — resume-here pointer.
- [`../../CLAUDE.md`](../../CLAUDE.md) — project context + architectural rule.
- [`../../m-cli/TODO.md`](../../../m-cli/TODO.md) — m-cli's own track list.
