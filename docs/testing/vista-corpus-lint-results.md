---
title: m-stdlib — VistA corpus lint results
status: live (2026-05-06)
corpus: ~/projects/vista-meta/vista/vista-m-host/Packages (39,375 routines, 176 packages)
companion: modern-m-corpus-test-results.md (non-VA companion)
informs: m-cli profile tuning (xindex / vista / sac / default), tree-sitter-m grammar gaps
created: 2026-05-06
last_modified: 2026-05-10
revisions: 4
doc_type: [RESEARCH]
---

# VistA corpus — lint pass results

m-cli's lint engine ships several rule profiles relevant to VistA M
code: `xindex` (XINDEX port, 34 engine-neutral rules), `vista`
(VA-Kernel-specific, 8 rules), `sac` (VA SAC portable subset, 23
rules), and `default` (m-cli's curated daily-lint set, 29 rules).
This document records what running each profile against the
**39,375-routine** VistA corpus surfaces — both for measuring rule
signal-vs-noise on the canonical legacy M codebase, and for
informing the next round of profile tuning.

## 1. Profile-by-profile summary

```
$ m lint --rules=<PROFILE> --target-engine=yottadb \
    ~/projects/vista-meta/vista/vista-m-host/Packages/
```

| Profile | Rules | Files linted | Parse errs | E | W | S | I | Total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `xindex` | 34 | 38,954 | 376 | 16,931 | 23,828 | 198,895 | 203 | **239,857** |
| `vista` | 8 | 38,954 | 376 | 0 | 245 | 0 | 14,456 | **14,701** |
| `sac` | 23 | 38,954 | 376 | 14 | 11,146 | 2,774 | 203 | **14,137** |
| `default` | 29 | 38,954 | 376 | **498,458** | 58,017 | 25,500 | 120,740 | **702,715** |

**376 parse errors out of 38,954 = 0.97 %.** Tree-sitter-m handles
VistA syntax extremely well. Compare with modern non-VA corpora —
ydbtest hit **17.6 %** parse-error rate. VistA is the original
codebase tree-sitter-m grew up against; modern non-VA M code uses
idioms the grammar didn't need to cover at first.

### Big-picture takeaways

- **`default` is unusable as-is on VistA.** 702 K findings, with one
  rule (`M-MOD-024` read-of-undefined-local) producing **487 K of
  the 498 K errors** — virtually all false positives on Kernel-init
  locals (see §3.1).
- **`xindex` is dominated by one rule too** — `M-XINDX-049`
  (unreferenced label) at 161 K firings, **67 %** of the profile's
  total. VistA's `$TEXT`-introspection / indirection / external-xref
  patterns defeat static reachability.
- **`vista` and `sac` are the production-clean profiles.** Both
  ~14 K findings, both dominated by *real* signal — banner-format
  compliance, locks/reads without timeouts, LABEL+OFFSET fragility.

## 2. Top firing rules — what they actually flag

### 2.1 `xindex` profile

| Rule | Firings | Severity | What it flags | Real or false? |
|---|---:|---|---|---|
| **M-XINDX-049** | 160,768 | S | "Label 'X' is declared but never referenced" | ❌ Mostly false on VistA. `$TEXT(LABEL+0)`, `@var` indirection, and external xref tables (`^DIC`, `^DD`) reference labels invisibly to static analysis. |
| **M-XINDX-013** | 35,215 | S | "Blank(s) at end of line" | ✅ Pure trivia, but real (manual editing artefacts). |
| **M-XINDX-007** | 16,385 | E | "Call to undefined routine ^%DT" | ❌ False on VistA. `^%DT`, `^%DTC`, `^%ZTLOAD`, `^DIR`, `^DIE` etc. are universally available FileMan/Kernel utilities — just outside the linted corpus's namespace. |
| **M-XINDX-009** | 11,461 | W | "Unreachable code: line follows unconditional terminator" | ✅ Real dead code. |
| **M-XINDX-060** | 5,621 | W | "LOCK missing :timeout (will block indefinitely)" | ✅ Real deadlock risk. |
| **M-XINDX-033** | 2,652 | W | "READ command does not have a :timeout" | ✅ Real hang risk. |
| **M-XINDX-030** | 1,602 | W | "LABEL+OFFSET syntax — offset-dependent calls are fragile" | ✅ Real fragility. |

**Profile health**: ~60 % of `xindex` firings are M-XINDX-049 (label-
unreferenced) noise. Suppressing or info-only-ing that rule on
VistA, plus an allowlist of trusted Kernel/FileMan routines for
M-XINDX-007, would drop the profile to ~63 K findings — almost all
real signal.

### 2.2 `vista` profile (VA-Kernel-specific)

| Rule | Firings | Severity | What it flags |
|---|---:|---|---|
| **M-XINDX-056** | 10,867 | I | "Patch number missing from second line (expected `**patch_list**`)" |
| **M-XINDX-044** | 3,556 | I | "2nd line of routine violates the SAC (must start with `;;version;package;...;date;build`)" |
| M-XINDX-034 | 109 | I | (sample below) |
| M-XINDX-029 | 98 | I | |
| M-XINDX-062 | 33 | I | |
| M-XINDX-032 | 23 | I | |
| M-XINDX-036 | 15 | I | |

All `vista` rules emit at **I** (info) or **W** (warning) severity
— none are errors. The two top firers are SAC banner-format
compliance, which is real signal for VA shops but not gating.

### 2.3 `sac` profile (VA SAC portable subset)

Top firers (production-real-signal):

| Rule | Firings | What it flags |
|---|---:|---|
| **M-XINDX-060** | 5,621 | LOCK without `:timeout` |
| **M-XINDX-033** | 2,652 | READ without `:timeout` |
| **M-XINDX-030** | 1,602 | LABEL+OFFSET fragility |
| M-XINDX-057 | 1,389 | (other SAC) |
| M-XINDX-047 | 1,330 | (other SAC) |
| M-XINDX-061 | 419 | |
| M-XINDX-017 | 333 | |
| M-XINDX-045 | 286 | |

**The healthiest profile against VistA** in terms of signal-to-noise.
The top 3 findings are concrete production-grade lint targets — a
VistA Kernel patch reviewer would *want* every one of these flagged.

### 2.4 `default` profile (m-cli daily-lint)

The big one — 702 K findings. Distribution:

| Rule | Firings | Severity | What it flags | Real or false? |
|---|---:|---|---|---|
| **M-MOD-024** | 487,102 | E | "Local 'X' may be read before being definitely defined" | ❌ Mostly false on VistA. Kernel auto-defines `U`, `IO`, `IOM`, `IOSL`, `DT`, `DTIME`, `DUZ`, `DUZ(0)`, `%UCI`, etc. at routine entry. Reaching-defs analysis can't see Kernel-supplied init. |
| **M-MOD-034** | 64,173 | I | "`SET A=A+1` — prefer `SET A=$INCREMENT(A)`" | ✅ Real modernization. VistA pre-dates `$INCREMENT`. |
| **M-MOD-029** | 56,103 | I | "Label 'X' comment density 0% below threshold 10%" | ⚠️ Style, real per spec but deeply non-VistA-style. |
| M-MOD-020 | 17,154 | E | (by-reference args) | Mixed (same M-MOD-020 false-positive on test idioms also seen in m-stdlib's own suite). |
| M-MOD-006 | 15,498 | | (label/structure) | |
| M-MOD-001 | 14,072 | | "Line is over 80 bytes" | ✅ Real, but 100 % of VistA legacy code violates it. |

**Profile health**: 70 % of `default` findings are M-MOD-024
false positives, and another ~17 % are style hits VistA can't be
expected to satisfy (M-MOD-029 comment-density, M-MOD-001
line-length). Without a VistA-aware Kernel-locals allowlist,
`default` is roughly 1,000× too noisy on this corpus to be useful.

## 3. False-positive shapes the corpus uncovered

### 3.1 Kernel-supplied locals — M-MOD-024 (487 K hits)

VistA's Kernel runtime auto-initialises a known set of locals at
session entry: `U` (set to `$char(94)`, the universal `^` field
separator), `IO`, `IOM`, `IOSL`, `DT` (today's FileMan date),
`DTIME`, `DUZ` (logged-in user IEN), `DUZ(0)` (security level),
`%UCI` (UCI/namespace), and more. These are universally present
across VistA and treated as "always defined" by every VistA
developer. Static reaching-defs analysis can't see Kernel's init
because Kernel is in another routine.

**Sample:**
```
A1BFCHK1.m:14:13: [E] M-MOD-024: Local '%UCI' may be read before being definitely defined
A1BFCHK1.m:23:78: [E] M-MOD-024: Local 'U' may be read before being definitely defined
```

**Fix shape**: m-cli's M-MOD-024 needs an opt-in VistA-aware
allowlist of Kernel-auto-locals. Could ship as a
`[lint.vista.kernel_locals]` config in `.m-cli.toml`, or as a
hardcoded list activated when `--rules=...,vista,...` is in the
profile.

### 3.2 Trusted-routines list — M-XINDX-007 (16 K errors)

`^%DT` (FileMan date validator) is the classic case. Every VistA
routine that takes a date input calls `D ^%DT` to validate format.
The XINDEX port flags it as undefined because the corpus snapshot
doesn't include FileMan's own `%DT.m` (which lives in `^%DT` namespace
not under `Packages/`).

**Sample:**
```
A1BFEX1.m:16:41: [E] M-XINDX-007: Call to undefined routine ^%DT
A1BFEX1.m:17:81: [E] M-XINDX-007: Call to undefined routine ^%DT
```

**Fix shape**: trusted-external-routines allowlist for the M-XINDX-007
rule, defaulted to the FileMan/Kernel/MailMan canonical set
(`^%DT`, `^%DTC`, `^%ZIS`, `^%ZISC`, `^%ZTLOAD`, `^XLFDT`, `^XLFSTR`,
`^DIR`, `^DIE`, `^DIC`, `^XMD`, etc.). Same `.m-cli.toml` /
profile-flag mechanism as the Kernel-locals list.

### 3.3 `$TEXT` introspection / dispatch tables — M-XINDX-049 (161 K)

VistA's runtime label resolution is far more dynamic than static
analysis can model:

- `$TEXT(LABEL+0^ROUTINE)` reads source text of a label by name;
  many "unreferenced" labels are referenced via `$TEXT` for
  introspection or error reporting.
- `^DIC` / `^DD` xref tables store routine+label as data, dispatched
  at runtime via `D @routine`.
- `XOBV*` action records, `OPTION` file (`^DIC(19)`) entries, and
  protocol files (`^ORD(101)`) all dispatch to labels by string.

A pure static-reachability rule misses every one of these and
emits a false positive.

**Fix shape**: M-XINDX-049 should either (a) skip routines that
contain a `$TEXT(*+0` reference (heuristic — those routines do
introspection), or (b) drop to **info** severity on VistA, or (c)
opt out via an `--rules=^M-XINDX-049` exclusion in the
default-VistA profile combo.

## 4. Real-signal rules — keep prominent

These rules produce findings that a VistA Kernel reviewer would
*want* flagged:

| Rule | Firings | Why it's real signal |
|---|---:|---|
| **M-XINDX-009** | 11,461 | Dead code after `QUIT` / `HALT` / `GOTO` — historical artefacts that should be cleaned up. |
| **M-XINDX-060** | 5,621 | LOCK without `:timeout` — production deadlock risk. Every one of these should at least carry an explicit "intentionally indefinite" comment if the unbounded wait is wanted. |
| **M-XINDX-033** | 2,652 | READ without `:timeout` — same shape, hangs the session indefinitely on idle terminals. |
| **M-XINDX-030** | 1,602 | LABEL+OFFSET — fragile against label additions/removals; VA SAC discourages it. |
| **M-XINDX-056** | 10,867 | Patch banner missing — VistA SAC mandate. Real compliance signal. |
| **M-XINDX-044** | 3,556 | 2nd line banner format — same theme. |
| **M-MOD-034** | 64,173 | `SET A=A+1` → `$INCREMENT` — modernization candidate; some are perf-relevant (atomic counter under YDB). |

Together: ~99 K real-signal findings spread across `xindex` + `vista`
+ `sac` profiles. That's the production-relevant baseline.

## 5. Per-package noise distribution

Top 10 noisiest packages by `xindex` finding count:

```
17,339  Integrated Billing       (2,451 routines)
16,589  Registration
10,911  DRG Grouper
10,806  IFCAP
10,703  Mental Health
 9,330  Dietetics
 9,080  Scheduling
 8,429  Lexicon Utility
 6,959  Lab Service
 6,836  Kernel
```

Noise correlates with size — Integrated Billing is the largest
package by routine count. **Findings-per-routine** is the more
interesting metric; computing that requires per-package routine
counts, which the current pass didn't capture cleanly. A follow-up
pass could compute findings/routine to identify packages with
density-anomalies (a small package with unusually high finding
density would be a quality outlier worth inspecting).

Quietest packages (each < 5 findings total):

```
Mobile Mental Health Program  (1)
VistA Web                     (1)
Medical Health E-Screening    (2)
Veterans Data Integration ... (2)
Credentials Tracking          (3)
```

These are small modern packages, often single-routine
M-side surfaces around web/HTTP/RPC interfaces.

## 6. Parse errors — tree-sitter-m grammar gaps

**376 parse errors out of 38,954 routines = 0.97 %.**

This is a **far better** rate than the modern non-VA corpus —
ydbtest hit 17.6 %. The grammar covers VistA legacy syntax very
well; non-VA modern M idioms are where the gaps live (computed
`for` ranges, `*$` indirection, mid-line `quit:cond` chains, etc.).

**Action**: each of the 376 parse-error files in VistA is worth a
focused triage pass — at this scale, it's likely 5-10 distinct
grammar gaps surfacing repeatedly. Would feed back into
tree-sitter-m as concrete grammar issues.

## 7. Action items

| For | What | Why |
|---|---|---|
| m-cli | Ship a VistA-Kernel-locals allowlist for M-MOD-024 (`U`/`IO`/`DT`/`DUZ`/`%UCI`/etc.). | Drops `default` profile from 702 K to ~215 K findings on VistA — closer to actionable. |
| m-cli | Ship a trusted-external-routines allowlist for M-XINDX-007 (FileMan + Kernel + MailMan canonical APIs). | Closes 16 K false-positive errors on `^%DT` and friends. |
| m-cli | Loosen M-XINDX-049 (label-unreferenced) on routines containing `$TEXT(*+0` — those use runtime introspection that beats static analysis. | Closes ~80–100 K of the 160 K firings; the remaining 60–80 K are likely real. |
| m-cli | Add a `--rules=xindex,vista,sac` documented combination as the canonical "VistA full lint" profile. | Closes the gap that `default` is unusable on VistA and individual VA profiles must be combined. |
| tree-sitter-m | Triage the 376 parse-error files; group by grammar-gap shape and open issues. | Tiny scope (1 % of corpus); high-leverage since VistA is the canonical reference corpus for the grammar. |
| m-stdlib | Reference this document in `users-guide.md` §6.5 (Portability open questions) under "VistA real-corpus validation". | Concrete evidence that the lint chain works against the canonical legacy corpus, and what work remains before it's CI-gateable. |

## 8. Validation results — 2026-05-06

After landing the recommended fixes (m-cli commit `4b082d0`,
tree-sitter-m commit `80d933f`, m-stdlib commit `37046c3`), the
canonical VistA corpus was re-linted and the false-positive
closures measured directly:

| Rule | Baseline | After fix | Closed | % closure |
|---|---:|---:|---:|---:|
| **M-MOD-024** (Kernel-locals) | 487,102 | 383,914 | 103,188 | **21 %** |
| **M-XINDX-007** (trusted-routines) | 16,385 | 1,642 | 14,743 | **90 %** |
| **M-XINDX-049** ($TEXT heuristic) | 160,768 | 52,556 | 108,212 | **67 %** |
| Combined three-rule total | 664,255 | 438,112 | 226,143 | **34 %** |

**`vista-full` profile, full canonical corpus, all allowlists active**:

- Before recommended config: ~268,000 findings (xindex + vista + sac
  union with no allowlists) including ~17,000 errors.
- **After**: **131,603 findings** (2,188 E / 24,073 W / 90,683 S /
  14,659 I).
- Net delta: **51 % overall reduction**, **87 % reduction in actionable
  errors** (16,931 → 2,188).

The `default` profile's M-MOD-024 false-positive class (the largest
pain point at 487K firings) drops by 21 % from the Kernel-locals
allowlist alone. Remaining 384K M-MOD-024 firings include reads of
Y / X / DTOUT / DUOUT (post-call locals from `^DIR` / `^DIC`
interactions — deliberately NOT in the universal-entry allowlist
because they're only defined post-call, and a flat allowlist would
mask "use-before-call" bugs) plus genuine app-level uninitialized
reads. A more aggressive call-aware rule that infers Y/etc. as
post-`D ^DIR` defined would close most of the remainder; that's a
separate piece of cross-routine analysis.

Per-file evidence kept under `~/data/m-stdlib/test-runs.log` per
the safe-test wrapper convention.

## 9. Cross-references

- [`modern-m-corpus-test-results.md`](modern-m-corpus-test-results.md) — non-VA companion (5 modern OSS projects, 4,209 routines).
- [`realcode-validation.md`](realcode-validation.md) — earlier validation pass over modern corpus only.
- [`users-guide.md`](../guides/users-guide.md) §6.5 — portability open questions.
- m-cli `m lint --list-profiles` — canonical profile descriptions.
- m-cli `examples/vista-lint-presets/` — drop-in `.m-cli.toml` for VistA.
- tree-sitter-m `docs/vista-parse-error-categories.md` — parser-side triage of the 376 outliers.
- m-stdlib `templates/m-vista-test-suite/` — STDASSERT-shaped test scaffold for VistA package modernization.
