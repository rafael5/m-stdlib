---
title: m-stdlib — real-code validation against m-modern-corpus
status: live (2026-05-05)
corpus: ~/projects/m-modern-corpus (5 projects, 4,215 routines, ~14 MB)
companion: users-guide.md (§6.5 "Portability open questions")
created: 2026-05-05
last_modified: 2026-05-08
revisions: 3
doc_type: [RESEARCH]
---

# Real-code validation — m-stdlib against m-modern-corpus

m-modern-corpus is a snapshot of five active non-VistA OSS M projects:
EWD (86 routines), m-web-server (23), mgsql (36), ydbocto-aux (21),
and the YottaDB regression-test corpus (4,049). It is the validation
fixture m-cli uses to gate that lint rules don't false-positive on
modern idioms outside the VA legacy style. This document records
what running m-stdlib's toolchain over that corpus surfaced from
m-stdlib's perspective.

## 1. Naming-collision sweep

**Goal:** confirm m-stdlib's reserved `STD*` routine prefix does not
collide with anything in the corpus.

**Result:** clean. `find ~/projects/m-modern-corpus -name 'STD*.m'`
returns zero matches across 4,215 routines. The reserved prefix is
safe to claim family-wide on the open-source side.

## 2. Lint-pass matrix

`m lint --rules=pythonic` over the four small projects (ydbtest's
4,049 routines deliberately skipped here — its rule profile is
already in m-cli's `make lint-modern` baseline):

| Project | Routines | Parsed | Parse errors | E | W | S | I |
|---|---:|---:|---:|---:|---:|---:|---:|
| `ewd/` | 86 | 77 | 9 | 859 | 1,696 | 12,772 | 908 |
| `m-web-server/src/` | 23 | 16 | 7 | 158 | 23 | 1,330 | 99 |
| `mgsql/yottadb/` | 36 | 24 | 12 | 855 | 421 | 2,746 | 790 |
| `ydbocto-aux/src/` | 21 | 17 | 4 | 11 | 85 | 183 | 28 |
| **total** | 166 | 134 | 32 | 1,883 | 2,225 | 17,031 | 1,825 |

**Severity legend**: E=error, W=warning, S=suggestion, I=info.

### What the numbers say

- **32 parse errors across 166 routines** is a tree-sitter-m gap, not
  a lint-rule problem. Modern non-VistA M uses idioms (GT.M-era
  syntax variants, `^%` percent-prefixed system routine calls,
  GT.M-specific deviceparam shapes) that the grammar doesn't yet
  cover. Each parse-error file should be triaged as a tree-sitter-m
  issue.
- **1,883 errors total** is too noisy to gate CI on for a
  modern-style project. The bulk comes from two rules:
  - **`M-MOD-024` (read-of-undefined-local)** — false-positives on
    `%name` percent-prefixed locals (which by historical convention
    survive across labels and aren't formally `NEW`-defined per
    branch); also fires on patterns where the flow-analysis can't
    track conditional definition. The same rule already required
    file-wide silencing in m-stdlib's `STDLOG.m` / `STDCSV.m` for
    YDB `OPEN` deviceparam misparses (TOOLCHAIN-FINDINGS P2).
  - **`M-MOD-036` (taint flows into indirection)** — flagged 4× in
    `ydbocto-aux` alone. The pattern `@gvn` where `gvn` was built
    from a parameter is the YDBOcto / `m-cli`-style dispatch idiom
    in M. Caller-side trust gates whether each instance is a real
    risk; the rule is correctly noisy but needs whitelist support
    or per-callsite suppression to be a useful CI gate on M codebases
    that lean heavily on indirection.
- **`ydbocto-aux` is the cleanest** — 11 errors over 17 parsed
  routines. It's also the youngest codebase in the corpus and uses
  a style closest to what the `--rules=pythonic` profile assumes.

### Sample of real findings worth inspecting upstream

| File | Line | Rule | Finding |
|---|---:|---|---|
| `ydbocto-aux/.../ _ydboctoInit.m` | 57 | `M-MOD-027` | `set $etrap` without preceding `new $etrap` — handler escapes the label. Often intentional at a top-level entry; worth a comment if so. |
| `ydbocto-aux/.../ _ydboctoDiscard.m` | 97, 115 | `M-MOD-036` | `tableGVNAME` / `gvn` built from a parameter and used in `@…` indirection. Caller is trusted SQL machinery, so not a real exploit; pattern still worth annotating. |
| `mgsql/yottadb/_mgsqlz.m` | 63 | `M-MOD-036` | Same shape — `cb` callback name flows into `@cb`. Documented dispatch idiom; pattern-level finding. |

## 3. Migration-target candidates

Where corpus code reimplements something m-stdlib already covers:

| Corpus routine | Lines | m-stdlib equivalent | Notes |
|---|---:|---|---|
| `ewd/_zewdJSON.m` | 833 | `STDJSON` (parse + encode) | Hand-rolled JSON parser/serialiser dating to 2013; AGPL-3.0. STDJSON's storage convention (one M tree node per JSON value) maps cleanly. Replacing the parser would drop EWD by ~500 lines net. |
| `m-web-server/src/_webjsonDecodeTest.m` | 329 | `STDJSON.parse` | A test routine; could become a 30-line `STDJSON`-driven equivalent that lives inside m-stdlib's conformance corpus. |
| `ewd/_zewdHTMLParser.m` | (TBD) | none yet | Outside m-stdlib's scope — but suggests a future `STDHTML` candidate per users-guide §6.3. |
| `ewd/_zewdJS.m` (regex use) | (TBD) | `STDREGEX` | Compiled-handle pattern would replace ad-hoc `$pattern` matching once IRIS-portability dispatch lands. |

These are **opportunities**, not in-flight migrations. m-modern-corpus
is a snapshot; mutating it would defeat its purpose. The candidates
matter as **evidence** that m-stdlib's API surface is sized to a real
need, not a hypothetical one.

## 4. What's missing from this validation

- **No runtime end-to-end exercise.** This pass ran m-stdlib's
  *toolchain* (m-cli lint + tree-sitter-m parse) against the corpus
  source. It did **not** exercise m-stdlib's *runtime modules*
  (STDJSON, STDREGEX, etc.) by invoking them from corpus routines.
  Doing that would require uploading a corpus subset to the
  vista-meta YDB container and writing thin test wrappers — useful,
  but a separate body of work.
- **`ydbtest` skipped here.** 4,049 routines are best run through
  m-cli's pre-existing `make lint-modern` loop rather than re-linted
  ad hoc. Their findings already feed the m-cli rule-tuning baseline.
- **No IRIS-side replay.** The fail-soft `iris-portability-check` CI
  job covers m-stdlib's own suites against IRIS; running
  m-modern-corpus through IRIS would surface a different parse-error
  set (since IRIS accepts class-syntax idioms YDB does not).
- **No `STD*` runtime collision under a real load.** Naming
  prefix-collision was checked statically; whether globals
  `^STDLIB($job,...)` collide with anything corpus code uses needs a
  run-time exercise.

## 5. Action items

| For | What | Why |
|---|---|---|
| tree-sitter-m | Triage the 32 parse errors above (one issue per file or one rolled-up issue per syntactic gap). | Each parse error blocks lint findings on that file — directly limits the value of the corpus-validation loop. |
| m-cli | Per-callsite suppression syntax for `M-MOD-036` (taint indirection). | The rule is correct but unusable as-is on codebases that use `@var` dispatch heavily. |
| m-cli | Per-rule allowlist for `%`-prefixed locals in `M-MOD-024` (read-of-undefined). | Historical convention; flagging these as undefined is wrong-by-default for non-VistA modern M. |
| m-stdlib | Consider a follow-on **runtime** validation: upload `ewd/_zewdJSON.m` to the test container alongside m-stdlib, write a tFoo test that round-trips a known JSON value through `parseJSON^_zewdJSON` and `$$parse^STDJSON`, assert agreement on N inputs. | Concrete behavioural-equivalence evidence for the migration-target claim in §3. |

## 6. Summary

m-stdlib's reserved prefix is collision-free across a 4,215-routine
modern-M corpus. m-stdlib's toolchain runs cleanly over the corpus —
no crashes, no infrastructure failures. The findings the toolchain
surfaces are a mix of real lint-worthy patterns and known
false-positive shapes already tracked in
[`TOOLCHAIN-FINDINGS.md`](../tracking/TOOLCHAIN-FINDINGS.md). At least two
corpus routines (`_zewdJSON.m`, `_webjsonDecodeTest.m`) reimplement
functionality m-stdlib now ships and could plausibly migrate.

The primary next-step for tightening this loop is tree-sitter-m
parse coverage — until those 32 parse errors close, the lint findings
on those files are unobservable.
