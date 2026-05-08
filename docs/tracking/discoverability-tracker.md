---
title: m-stdlib — discoverability & tooling implementation tracker
status: live (2026-05-08; Wave A not yet started; all rows = not-started)
authority: this file is the canonical "what's done / in flight / queued" view
  for the discoverability & tooling plan. Any commit that touches a task below
  MUST update the row's Status and append to the task's narrative section in
  the same commit.
plan: docs/plans/discoverability-and-tooling-plan.md (the design doc; this
  tracker drives the work items)
sibling: docs/tracking/module-tracker.md (the module-level tracker; deferred
  decisions D1/D2/D3 there originated in the same plan)
audience: anyone executing or proposing work against the discoverability plan,
  including AI agents asked to "complete phase X"
---

# m-stdlib — discoverability & tooling implementation tracker

This tracker drives the work in
[`docs/plans/discoverability-and-tooling-plan.md`](../plans/discoverability-and-tooling-plan.md).
The plan is the **why** and **what**; this file is the **who/when/where**.

Tasks are grouped into four waves (Wave A → D) matching the plan's § 8
phasing. A wave's downstream consumers (m-cli, VS Code, AI skills)
depend on its upstream artefact (the manifest from Wave A), so the
order matters; **within** a wave, most tasks can run in parallel
unless a Deps cell says otherwise.

---

## How to use this tracker

When asked "based on the tracking table, complete phase X" (e.g.
"complete Wave A"), follow this procedure:

1. **Read the plan section** matching the phase. Each Wave maps to a
   plan § — e.g. Wave A is plan § 3 + § 8 Wave A. The task rows below
   include the precise plan-§ pointers.
2. **Walk the tracker rows** for the requested wave. For each row
   whose Status is `not-started` or `in-progress`:
   - Verify every Dep listed is `done`. If a Dep is not done, work
     that Dep first (or block on it).
   - Read the narrative section for that Task ID further down this
     file. The narrative carries any prior progress notes, blockers,
     and design choices already pinned.
   - Read the file(s) listed in the Paths column. The plan §
     pointer in Notes gives the design rationale.
3. **Execute the task** following project conventions (TDD-first,
   `make check`, `m fmt`, `m lint --error-on=error`, per-module
   acceptance gate from
   [`module-tracker.md` § "Per-module acceptance gate"](module-tracker.md)).
   For tasks landing in **m-cli** rather than m-stdlib (Wave B), the
   work lands in `~/projects/m-cli/` and m-stdlib remains untouched.
4. **Update this tracker** in the same commit:
   - Flip the row's Status (`not-started` → `in-progress` → `done`).
   - Append a dated bullet to the task's **Progress log** in the
     narrative section, summarising what landed, the commit SHA(s),
     and any follow-ups.
   - If the task is `done`, set the row's Status, fill in the Tag
     column with the m-stdlib release that carries it (or "n/a" for
     m-cli/VS Code/skill artefacts), and check the **Acceptance**
     condition is genuinely met.
5. **Cross-tracker hygiene.** If the work also lands a module-level
   change (e.g. backfilling tags inside `src/STDxxx.m` is also a
   change to that module), add a one-line note in
   [`module-tracker.md` Table 1](module-tracker.md). The
   discoverability tracker stays focused on the cross-cutting
   metadata/tooling work; per-module behaviour stays in the module
   tracker.

---

## Cross-references

Everything below is the canonical pointer set an agent needs to do
the work without further orientation.

### Within m-stdlib (this repo)

| Concern | Path |
|---|---|
| Plan / design doc | [`docs/plans/discoverability-and-tooling-plan.md`](../plans/discoverability-and-tooling-plan.md) |
| Module tracker (sibling) | [`docs/tracking/module-tracker.md`](module-tracker.md) |
| Toolchain findings | [`docs/tracking/TOOLCHAIN-FINDINGS.md`](TOOLCHAIN-FINDINGS.md) |
| Released-module catalogue | [`docs/modules/index.md`](../modules/index.md) |
| Per-module long-form docs | [`docs/modules/*.md`](../modules/) |
| User guide | [`docs/guides/users-guide.md`](../guides/users-guide.md) |
| TDD guide | [`docs/guides/m-tdd-guide.md`](../guides/m-tdd-guide.md) |
| M routines (the source of truth for the manifest) | [`src/STD*.m`](../../src/) |
| Tests | [`tests/STD*TST.m`](../../tests/) |
| Build / generator scripts (target dir for new tools/) | [`tools/`](../../tools/) |
| Manifest output (will not exist until WA4 lands) | `dist/stdlib-manifest.json` |
| Errors output (will not exist until WA7 lands) | `dist/errors.json` |
| Release notes | [`CHANGELOG.md`](../../CHANGELOG.md) |
| Project conventions | [`CLAUDE.md`](../../CLAUDE.md) |

### Outside m-stdlib (downstream consumers)

| Concern | Path |
|---|---|
| m-cli source (Wave B target) | `~/projects/m-cli/` |
| m-cli command source dir | `~/projects/m-cli/src/cmd/` (existing pattern; new `doc.m`, `search.m`, `manifest.m`, `examples.m`, `errors.m` land here) |
| m-cli lint rules dir (WA3 target) | `~/projects/m-cli/` (find `lint` subdir; rule `M-DOC-001` lands alongside other M-DOC-* rules if any, or as a new family) |
| tree-sitter-m parser (informs WA4 design; do NOT bind to it for Wave A) | `~/projects/tree-sitter-m/` |
| AI skill output dir (Wave D) | `~/claude/skills/m-stdlib/` |
| AI memory home | `~/claude/memory/` |
| VS Code extension scaffold (does not yet exist; Wave C creates it) | `~/projects/m-stdlib-vscode/` (recommended new repo) or `~/projects/m-cli/vscode/` (if shared) — decide in WC1 |

### External references

| Concern | Pointer |
|---|---|
| JSDoc tag spec (informs WA1 grammar) | <https://jsdoc.app/> |
| rustdoc reference (informs WA1, search-index design) | <https://doc.rust-lang.org/rustdoc/> |
| godoc (informs WB1 `m doc` UX) | <https://go.dev/doc/comment> |

---

## Summary table

**Status legend.** `not-started` · `in-progress` · `blocked` · `done` · `deferred` (tracked elsewhere; left in the table only as a pointer).

**Phase legend.** **WA** = Wave A (m-stdlib: grammar + manifest). **WB** = Wave B (m-cli: `m doc` family). **WC** = Wave C (VS Code extension). **WD** = Wave D (AI surface).

**Repo legend.** **stdlib** = `~/projects/m-stdlib/` · **m-cli** = `~/projects/m-cli/` · **vscode** = VS Code extension repo (TBD in WC1) · **skill** = `~/claude/skills/m-stdlib/`.

| Task ID | Status | Phase | Seq | Repo | Title | Deps | Effort | Acceptance | Plan § | Paths |
|---|---|---|---|---|---|---|---|---|---|---|
| WA1 | done | WA | 1 | stdlib | Specify M-doc tag grammar (`@param` / `@returns` / `@raises` / `@example` / `@since` / `@stable` / `@see` / `@deprecated` / `@internal`) and synopsis-line rule | — | 0.5d | New `docs/guides/m-doc-grammar.md` reviewed; sample worked example shown using `STDJSON.parse` | § 3.1 | `docs/guides/m-doc-grammar.md` (landed 2026-05-08) |
| WA2 | done | WA | 2 | stdlib | Backfill structured doc tags across all public labels in `src/STD*.m` (incl. `@stable` tier annotation per § 3.6) | WA1 | 3–4d | Every public label in src/ has `@param`s matching the formal-list, `@returns` for extrinsics, `@raises` for any `$ECODE` it sets, ≥1 `@example`, `@since`, `@stable`. Manifest generator (WA4) parses src/ without diagnostics. | § 3.1, § 3.6 | `src/STD*.m` (all 32 routines); ALL DONE (32/32) |
| WA3 | done | WA | 3 | m-cli | Add lint rule `M-DOC-001` warning on public labels missing required tags (warn-only at first) | WA1 | 0.5–1d | `m lint` raises `M-DOC-001` (severity warn) on a public label whose `; doc:` block is missing `@returns` (extrinsic) or has a `@param` not in the formal-list. No errors emitted yet. | § 3.1 (acceptance gate) | `~/projects/m-cli/src/m_cli/lint/_doc.py` (new), `~/projects/m-cli/tests/test_lint_doc.py` (new), m-cli commit `f97b849` pushed |
| WA4 | done | WA | 4 | stdlib | Implement `tools/gen-manifest.py` — hand-rolled parser — that walks `src/STD*.m` and emits `dist/stdlib-manifest.json` + `dist/errors.json` per the § 3.2 schema | WA1 | 1–2d | Running `make manifest` produces `dist/stdlib-manifest.json`; all public labels present with signature, source.file/line, plus tag-derived fields (params, returns, raises, examples, since, stable, see_also) populated when WA2 backfill provides tags. | § 3.2, § 11.4 | `tools/gen-manifest.py` (new, ~370 LoC), `dist/stdlib-manifest.json` (new, generated), `dist/errors.json` (new, generated), `Makefile` (`manifest` + `manifest-check` targets) |
| WA5 | done | WA | 5 | stdlib | CI gate: regenerate manifest in CI, fail on diff against committed `dist/stdlib-manifest.json` | WA4 | 0.5d | CI workflow runs `make manifest-check`; passes today, fails if a label changes without manifest re-gen. | § 3.2 (acceptance gate) | `.github/workflows/ci.yml` (step add), `Makefile` (already had `manifest-check`) |
| WA6 | done | WA | 6 | stdlib | Add YAML frontmatter (module / tag / phase / stable / since / synopsis / errors / labels / conformance / see_also) to every `docs/modules/stdXXX.md` | — | 0.5d | Every per-module markdown has frontmatter parsing cleanly as YAML. Field values agree with the manifest where overlapping (verified by a small check script, not gated yet). | § 3.3 | `docs/modules/std*.md`, `tools/write-module-frontmatter.py` (new), `Makefile` (`frontmatter` target) |
| WA7 | done | WA | 7 | stdlib | Generate `dist/errors.json` (inverted index of `U-STD*` codes → producing module + labels) as a derivative of the manifest | WA4 | 0.25d | `make manifest` also writes `dist/errors.json` containing every `U-STD*` code with its origin module + labels. | § 3.5 | `tools/gen-manifest.py` (covers WA7 too), `dist/errors.json` (generated) |
| WA8 | done | WA | 8 | stdlib | Cut a release tag carrying Wave A; update `docs/modules/index.md` to link the manifest + errors registry | WA4, WA5, WA6, WA7 | 0.5d | A new tag (≥ `v0.5.0` or per CHANGELOG decision) ships with manifest + errors.json + frontmatter; `docs/modules/index.md` carries a "Machine-readable surface" subsection linking both. | § 8 Wave A gate | `CHANGELOG.md` ([v0.5.0] heading), `docs/modules/index.md` (Machine-readable surface section), git tag `v0.5.0` (local; not pushed) |
| WB1 | done | WB | 1 | m-cli | `m doc <symbol>` — module overview, single-label, fuzzy lookup; reads `dist/stdlib-manifest.json` from the resolved m-stdlib install at runtime | WA4 | 1–2d | `m doc STDJSON`, `m doc STDJSON.parse`, and `m doc parse` all return correct godoc-style output within ~100ms cold. | § 4.1 | `~/projects/m-cli/src/m_cli/doc/{cli,lookup,format}.py` (new+rewrite), `~/projects/m-cli/tests/test_cli_doc_lookup.py` (new), m-cli commit `0024a72` pushed |
| WB2 | done | WB | 2 | m-cli | `m doc --json` and `m doc --short` flags | WB1 | 0.5d | `--json` emits the raw manifest entry; `--short` emits one-line synopsis. Both stable for scripting. | § 4.1 | landed in the same commit as WB1 (`0024a72`) — `format.py` carries `format_*_short` and `format_*_json` formatters; `cli.py` wires the flags |
| WB3 | done | WB | 3 | m-cli | `m search <query>` — full-text fuzzy search over manifest synopsis + description + example | WA4 | 0.5–1d | `m search "json parse"` returns ranked `module.label — synopsis` lines; matches against case-insensitive substrings in synopsis, description, examples. | § 4.2 | `~/projects/m-cli/src/m_cli/doc/search.py` (new), m-cli commit `6542e73` pushed |
| WB4 | done | WB | 4 | m-cli | `m manifest`, `m examples <module>`, `m errors` thin wrappers | WA4, WA7 | 0.5d | All three commands emit useful output piped from the manifest / errors registry. | § 4.3, § 4.4, § 4.5 | `~/projects/m-cli/src/m_cli/doc/{manifest,examples,errors}.py` (all new), m-cli commit `6542e73` pushed |
| WC1 | not-started | WC | 1 | vscode | VS Code extension v0.1: hover, goto-def, completion driven by `dist/stdlib-manifest.json` (no LSP) | WA4 | 2–3d | Extension activates on `.m` files; hover on `^STDJSON` and `parse^STDJSON` shows synopsis + signature; goto-def jumps to `src/STDJSON.m:L`; completion suggests `^STD*` modules and labels. | § 5.1 | TBD in WC1: either new repo `~/projects/m-stdlib-vscode/` or `~/projects/m-cli/vscode/` |
| WC2 | not-started | WC | 2 | vscode | Snippet pack for canonical patterns: STDASSERT suite skeleton, STDFIX `with` wrapper, STDLOG kv line, STDJSON parse-then-walk | WC1 | 0.5d | Typing `stdassert-suite` (etc.) in a `.m` file expands to the canonical idiom. | § 5.1 | extension repo |
| WD1 | not-started | WD | 1 | skill | AI skill at `~/claude/skills/m-stdlib/` — `SKILL.md` + `manifest-index.md` + `patterns.md` + `error-codes.md`, generated from the manifest | WA4 | 1d | Skill files exist; `tools/gen-skill.m` regenerates them deterministically; CI fails on drift. | § 6.1 | `~/claude/skills/m-stdlib/`, `tools/gen-skill.m` (new), `.github/workflows/ci.yml` (extend) |
| WD2 | not-started | WD | 2 | stdlib | Doctest generator `tools/gen-doctests.m` — emits `tests/STDxxxDOCTST.m` from `@example` lines so doc examples must execute | WA1, WA2 | 1d | Every module with ≥1 `@example` has a generated `*DOCTST.m` suite that runs under `m test`; suite green; example drift fails CI. | § 3.4 | `tools/gen-doctests.m` (new), `tests/STD*DOCTST.m` (generated, committed) |

### Deferred / out of scope (linked from `module-tracker.md`)

| Tracker ref | Subject | Status |
|---|---|---|
| [`module-tracker.md` D1](module-tracker.md#deferred-decisions--revisit-triggers) | HTML / GitHub Pages docs site (plan § 5.2) | deferred — revisit when a non-maintainer adopts m-stdlib or a second contributor lands a module |
| [`module-tracker.md` D2](module-tracker.md#deferred-decisions--revisit-triggers) | `@stable` SemVer CI gate (manifest-diff at HEAD vs last tag) | annotation ships in WA2; gate deferred — revisit when v1.0 is being planned or a non-maintainer consumer adopts m-stdlib |
| [`module-tracker.md` D3](module-tracker.md#deferred-decisions--revisit-triggers) | Replace hand parser in `tools/gen-manifest.m` with tree-sitter-m | hand parser ships in WA4; revisit when tree-sitter-m hits stable v1 or generator needs language features beyond labels + doc comments |

---

## Per-task narratives

Each Task ID has a section below. Keep narratives **short** during
planning; expand them as work happens. The format is:

```
### <Task ID> — <short title>

**Status.** <not-started | in-progress | blocked | done>
**Goal.** One paragraph from the plan section.
**Approach.** Bullets — how to attack this.
**Acceptance.** Same string as the table cell, expanded if useful.
**Out of scope.** Anything to deliberately not do here.
**Progress log.**
- <YYYY-MM-DD> — <what landed; commit SHA; any follow-ups>
```

---

### Wave A — m-stdlib grammar + manifest

#### WA1 — Specify M-doc tag grammar

**Status.** done (2026-05-08).

**Goal.** Write `docs/guides/m-doc-grammar.md` defining the structured-tag extension to the existing `; doc:` convention. Tags must be optional (existing prose-only blocks remain valid); the tag set is small (`@param`, `@returns`, `@raises`, `@example`, `@since`, `@stable`, `@see`, `@deprecated`, `@internal`); the first tag-free `; doc:` line is the synopsis (consumed by `m doc --short`).

**Approach.**
- Borrow JSDoc verbatim where possible — the tag names above are all standard JSDoc.
- Show one fully-tagged worked example for `parse^STDJSON` exactly as in plan § 3.1.
- Define `@stable` values: `experimental` / `stable` / `deprecated`.
- Note the synopsis-line rule (godoc convention: first sentence is the summary).
- Flag the parsing contract for downstream tools (manifest generator + lint rule must accept the same grammar).

**Acceptance.** New `docs/guides/m-doc-grammar.md` exists; reviewed for clarity; the worked example matches what WA4's generator will be expected to extract.

**Out of scope.** Not changing the existing `; doc:` prose convention; not specifying a Markdown subset for tag bodies (keep them plain text for v1).

**Progress log.**
- **2026-05-08** — `docs/guides/m-doc-grammar.md` landed (10 sections, ~250 lines). Defines the nine tags, the synopsis line rule (godoc-style; inline comment on label line preferred, first prose sentence as fallback), the lexical model (continuation lines append; empty `; doc:` lines terminate a tag's body), and a worked `parse^STDJSON` example showing both the tagged source form and the derived manifest entry. § 7 pins the parsing contract three downstream tools must agree on (`tools/gen-manifest.m`/WA4, `M-DOC-001` lint/WA3, all Wave B/C/D consumers via the manifest). § 8 tabulates edge-case behaviour (unknown tags, duplicate `@param`, etc.). Key calibrations vs the plan §3.1 sketch: (a) extrinsic-vs-procedure distinction is inferred statically from `quit <expression>` rather than from formal-list parens; (b) `@example` blocks collapse consecutive lines into one snippet (more idiomatic for STDASSERT-style multi-line examples); (c) `@internal` excludes a label from the manifest entirely rather than merely tagging it; (d) free-form description block can sit either before or after the tag block — recommended placement is tags-first, prose-second. No source files (`src/STD*.m`) touched — that is WA2's scope. WA3 (`M-DOC-001` lint rule) and WA4 (`tools/gen-manifest.m`) now have a normative spec to implement against and are unblocked.

---

#### WA2 — Backfill structured doc tags

**Status.** done (32/32 modules — all `src/STD*.m` backfilled as of 2026-05-08).

**Goal.** Every public label across all 30+ `src/STD*.m` routines gets `@param`s, `@returns`, `@raises`, ≥1 `@example`, `@since`, `@stable`. The existing prose `; doc:` lines remain as continuation.

**Approach.**
- One module per session; treat the v0.4.0 module-tracker order as a natural sequence.
- Cross-check `@param` names against the formal-list; cross-check `@raises` against the routine-header's documented `$ECODE` values.
- For `@since`, read from `CHANGELOG.md` (per-module first-shipped tag).
- For `@stable`, default to `stable` for any label that's been shipped in a tagged release; `experimental` for anything still in flight; `deprecated` for nothing yet.
- Run `make check` per module before moving on.

**Acceptance.** Every public label tagged. Once WA4 ships, the manifest generator parses src/ without warnings.

**Out of scope.** Not changing label signatures or behaviour. Not deprecating anything in this pass — `@stable=deprecated` is reserved for a future intentional deprecation.

**Progress log.**
- **2026-05-08 — first 3 modules done (STDB64, STDHEX, STDFMT).** Pattern validated end-to-end: grammar guide → tagged source → manifest extraction → manifest-driven frontmatter → errors registry. The 3 modules were chosen as the smallest/simplest of the 32 (5 + 4 + 2 public extrinsics) and as a representative cross-section: **STDB64** and **STDHEX** are pure data-transform modules with no `$ECODE` raises (so `@raises` is empty); **STDFMT** is the first real test of `@raises` plumbing because it sets four distinct `,U-STDFMT-*,` codes via a `raise` helper. Manifest globals: **519 → 502 public labels** (the 13 internal helpers across these 3 modules — `alpha`, `urlAlpha`, `encodeImpl`, `decodeImpl` in STDB64; `alpha`, `alphaU`, `encodeImpl` in STDHEX; `render`, `expand`, `lookup`, `apply`, `parseSpec`, `convert`, `toBase`, `pad`, `repeat`, `raise` in STDFMT — all correctly excluded after `@internal`). **`dist/errors.json` populated for the first time** with the four STDFMT codes correctly tied to `f` and `fn`. Frontmatter regenerated with `--force` to pick up the trimmed `labels` lists and the populated `errors`. **Style/lint impact: zero.** `make fmt-check` clean (65/65 unchanged); `make lint --error-on=error` reports 0 errors (8480 findings total, all S/W/I, pre-existing — none from these edits). **Per-label tags applied**:
  - **STDB64**: `encode`/`decode`/`urlencode`/`urldecode`/`valid` → `@param data|text` (string, byte-string semantics noted), `@returns string|bool`, `@example` (carried over from the prose `Example:` lines), `@since v0.0.2`, `@stable stable`, `@see` cross-refs to siblings. No `@raises` (module never sets `$ECODE`).
  - **STDHEX**: same shape — `encode`/`encodeu`/`decode`/`valid` with `@since v0.0.2`. The two encode entries point at each other via `@see`.
  - **STDFMT**: `f`/`fn` get `@param` for every formal-list arg (9 + 2 respectively), `@returns string`, **all four `@raises U-STDFMT-*` codes** (since the `raise()` helper is reachable transitively from both extrinsics), `@example`, `@since v0.0.3`, `@stable stable`, mutual `@see`.
- **Style observations carried into future modules:** (1) the existing inline-`Example:` prose lines are removed from the description block once `@example` carries the same content (avoids duplication; matches the grammar guide's recommended style). (2) Internal helpers' "Internal — " prose prefix is dropped when `@internal` is added (the tag carries the same signal). (3) Tag-bodies are aligned at column position 24 within the `; doc:` body for readability; not enforced by the grammar but a nice convention. (4) For modules with 9-position positionals (STDFMT.f), all nine `@param` lines are emitted even though the trailing ones may be optional in practice — explicit > implicit.
- **What's left for WA2: 29 of 32 modules.** Recommended ordering (by simplicity): STDARGS, STDUUID, STDLOG, STDDATE, STDCSV, STDOS, STDSEMVER, STDSTR, STDTOML, STDCACHE, STDPROF, STDSNAP, STDENV, STDSEED, STDFIX, STDMOCK, STDFS, STDCSPRNG, STDCOLL, STDURL, STDMATH, STDXFRM, STDCRYPTO, STDCOMPRESS, STDHTTP, STDASSERT, STDREGEX, STDXML, STDJSON. The last 4 (STDASSERT, STDREGEX, STDXML, STDJSON) carry the most labels and most-complex error surfaces; do them last when the workflow is fully grooved.
- **2026-05-08 — WA2 complete (batches 5–11 land remaining 20 modules).** Final 20 modules backfilled in five workflow-batches plus a bulk-transform pass for the largest three:
  - **Batch 5** (STDCACHE, STDPROF, STDSNAP) — STDSNAP gains `@raises U-STDFS-OPEN-FAIL` for the transitive STDFS dependency.
  - **Batch 6** (STDENV, STDSEED, STDFIX) — STDSEED's 6 distinct error codes correctly tied to load(), validate(), loadJson() per the transitive raise() chain. STDFIX raises U-STDFIX-EMPTY-TAG / U-STDFIX-UNREGISTERED-TAG.
  - **Batch 7** (STDMOCK, STDFS, STDCSPRNG) — STDFS captures the full byte-faithful I/O error matrix: NOT-WIRED + OPEN-FAIL + READ-TRUNCATED + REMOVE-FAIL across writeBytes/appendBytes/readBytes plus the v0.3.0 text-I/O paths.
  - **Batch 8** (STDCOLL, STDURL, STDMATH) — STDCOLL is the largest module backfilled (48 public labels: Set/Map/Stack/Queue/Deque/Heap/OrderedDict). All 13 STDURL internal helpers excluded via `@internal`.
  - **Batch 9** (STDXFRM, STDCRYPTO, STDCOMPRESS) — Phase 3 callout modules with rich `@raises` surfaces (CALLOUT-MISSING / DIGEST-FAIL / HMAC-FAIL / BAD-LEVEL / LIBZ-FAIL / LIBZSTD-FAIL).
  - **Batch 10** (STDHTTP, STDASSERT) — STDASSERT's `silent` correctly marked `@internal` after the helper's own `; doc:` block already labelled itself "Internal helper".
  - **Final batch** (STDREGEX, STDXML, STDJSON) — these three carry ~140 internal helpers that needed `@internal` tagging. **Bulk transform via Python sed-like one-liner** (`re.sub(r'(\\s+); doc: Internal — (.)([^\n]*)', r'\\1; doc: @internal\\1; doc: \\u(\\2)\\3', text)`) handled the prose-prefix cases in one shot; ~8 remaining internal helpers without "Internal —" phrasing got individual edits. Then 31 public labels backfilled with full tag set.
- **Aggregate at WA2 close**: **519 → 284 public labels** in the manifest (235 internal helpers correctly excluded). **errors.json: 0 → 43 distinct error codes** across all 32 modules. Module-level error counts validate: STDARGS 5, STDSEED 6, STDFS 4, STDCRYPTO 3 + 3 (digest/hmac shared), STDCOMPRESS 4, STDFMT 4, STDDATE 3, STDLOG 3, STDCSPRNG 3, STDREGEX 3, STDFIX 2, STDJSON 2, STDCSV 1, STDENV 1, STDSNAP 1 (transitive U-STDFS-OPEN-FAIL).
- **Style/lint impact**: `fmt-check` clean (65/65 unchanged). Final lint: 0E 567W 7677S 272I (vs starting 0E 567W 7638S 275I). **+39 S findings, -3 I** — these are M-MOD-001 line-length warnings on a few `@returns` / `@see` lines that exceed the 100-byte limit. All S-severity, non-gating, comparable to the pre-existing 7638 such findings project-wide. **Zero new errors introduced.**
- **Frontmatter regenerated** (`make frontmatter --force`) so all 32 `docs/modules/std*.md` files have up-to-date `labels` and `errors` lists.
- **Wave A status now ALL DONE** in this repo (WA1 + WA2 + WA4 + WA5 + WA6 + WA7 + WA8 = 8/8). Cross-repo follow-ons remain: WA3 (m-cli `M-DOC-001` lint rule), Wave B (m-cli `m doc` family), Wave C (VS Code extension), Wave D (AI skill).
- **2026-05-08 — fourth batch (STDSEMVER, STDSTR, STDTOML).** Three "predicate-style" P4-wave modules — no `$ECODE` raises anywhere; failures surface as `""` or `0` returns instead. **Public-label deltas:** STDSEMVER 18→9 (10 internal: validTriple/validPrerelease/validBuild/validNumericId/validPreId/validBuildId/comparePrerelease/comparePreId/matchesOne/matchesCaret); STDSTR 13→13 (no internal helpers — STDSTR is a flat utility module); STDTOML 13→4 (9 internal: parseTable/parsePair/decodeValue/decodeString/decodeInteger/decodeFloat/trimWs/stripTrailingComment/validBareKey). **Aggregate: 466→449 public labels.** **`dist/errors.json` unchanged at 16 codes** — these three modules don't raise. **Style observation**: STDSTR is the first all-public module backfilled; it has no `@internal` tags at all. Net lint delta: +1S, -1I, essentially zero. fmt-check clean (65/65 unchanged).
- **2026-05-08 — third batch (STDLOG, STDCSV, STDOS).** Same workflow. **Public-label deltas:** STDLOG 17→8 (9 internal: collect/emitLine/emitJson/writeLine/kvVal/needsQuote/escape/replace/levelNum); STDCSV 6→4 (2 internal: emit/dq); STDOS 12→11 (1 internal: replaceDouble). **Aggregate: 478→466 public labels.** **`dist/errors.json` now carries 16 codes** (was 12): +3 STDLOG (`INVALID-LEVEL` → LEVEL; `INVALID-SINK` → SINK; `INVALID-FORMAT` → FORMAT — each tied to its single direct setter, since these don't go through a `raise()` thunk) plus +1 STDCSV (`OPEN-FAIL` → parseFile + writeFile). **Net lint delta: ZERO** — `0E 567W 7652S 274I` unchanged from the prior batch. The pattern is now grooved: tag bodies stay under the 100-byte M-MOD-001 limit, prose continuation handles the longer descriptions. **Style observation carried forward** — STDLOG's 5 level-emitter stubs (DEBUG/INFO/WARN/ERROR/FATAL) all share the same 11-formal positional pattern, so DEBUG carries the full `@param` list and the other four emitter docs reference it via `; doc: @param k1 string key 1 (optional; same shape through k5/v5)` to avoid 50 lines of redundant tag boilerplate. The manifest still records the formal-list correctly (extracted from the label-line itself, not the `@param` count); future `m doc` UX can render the cross-ref or expand it as desired.
- **2026-05-08 — second batch (STDUUID, STDARGS, STDDATE).** Same workflow as the first batch. **Public-label deltas**: STDUUID 8→5 (`randomHex`/`toHex`/`unixMs` excluded); STDARGS 15→7 (8 internal helpers excluded — `initDefaults`/`checkPositionals`/`walk`/`tokenize`/`handleLong`/`handleShort`/`assignPositional`/`raise`); STDDATE 20→7 (13 internal helpers excluded — the Howard-Hinnant calendar primitives, the strftime/strptime tz formatters, and `padL`). Aggregate: **502→478 public labels** across the manifest. **`dist/errors.json` now carries 12 codes** (was 4): the 4 STDFMT codes from batch 1, plus all 5 STDARGS codes (`UNKNOWN-ACTION` → `addflag`; `UNKNOWN-FLAG` / `UNKNOWN-SUBCOMMAND` / `MISSING-VALUE` / `MISSING-POSITIONAL` → `parse`), plus all 3 STDDATE codes (`BAD-HOROLOG` → `fromh`/`strftime`/`add`; `BAD-ISO` → `toh`/`strptime`; `BAD-DUR` → `add`). The **transitive `@raises` discipline** validated: `parse^STDARGS` correctly captures all four codes that the helper chain (`walk`/`handleLong`/`handleShort`/`checkPositionals`) raises through the shared `raise()` thunk, even though `parse` itself only calls `walk` directly. **Style notes carried forward**: a few new `@returns` and `@see` lines exceed the 100-byte M-MOD-001 limit — kept as-is because (a) the warnings are S-severity, not gating; (b) splitting them across continuation lines reduces readability; (c) the trend is project-wide (7652 such findings pre-existing). Net lint delta this batch: 0E unchanged; +14S (style); -1I (info). **`make fmt-check` clean** (65/65 unchanged).

---

#### WA3 — Lint rule `M-DOC-001`

**Status.** done (2026-05-08; m-cli commit `f97b849` pushed to origin).

**Goal.** Warn on public labels missing required tags. Lives in m-cli (where lint rules live), not m-stdlib.

**Approach.**
- Locate the existing m-cli lint rule directory; follow the pattern of an existing M-* rule.
- Severity = warn (not error) at first; promote to error in a later release once WA2 backfill is complete and stays clean.
- Required tags by label form: extrinsic (`label() ; ...`) needs `@returns`; procedure (`label(args) ; ...`) needs `@param` matching every formal arg; both need ≥1 `@example` if `@stable=stable`.

**Acceptance.** `m lint` against m-stdlib emits zero `M-DOC-001` errors after WA2; emits warnings only on labels not yet backfilled.

**Out of scope.** Stricter rules (`M-DOC-002`+) — defer to a later pass. The acceptance-gate threshold change to `--error-on=warning` for `M-DOC-*` is also out of scope until backfill is complete.

**Progress log.**
- **2026-05-08 (m-cli commit `f97b849`)** — Landed as the first member of the **M-DOC-NN** family. New file `src/m_cli/lint/_doc.py` (~290 LoC) implements the rule following the same `_label_body_extents` + tag-block parser pattern that `tools/gen-manifest.py` in m-stdlib uses, so the lint rule and the manifest generator agree byte-for-byte on which `; doc:` blocks belong to which label. New tests file `tests/test_lint_doc.py` (17 cases) covers each diagnostic shape (missing @param / extra @param / missing @returns / undeclared @raises / missing @since / missing @stable / unknown @stable level / `@stable deprecated` without `@deprecated`) plus the rule's profile/tag membership (modern + doc tags). New side-effect import in `lint/__init__.py` registers the family.
- **Severity** = `Severity.WARNING` per the grammar guide §7.2 v1 spec. **Tags** = `("modern", "doc")` so the rule lands in the **default**, **modern**, and **pythonic** profiles automatically; `--rules=doc` selects just the M-DOC family explicitly. **Category** = `Category.DOCUMENTATION`.
- **Two implementation calibrations** during the work: (1) `@raises` detection scans only **code lines** (skips `; doc:` lines) — caught a false positive while validating against m-stdlib's `STDCSPRNG.available()`, where the `@example` body itself contains a `set $ecode=,U-MYAPP-NO-CSPRNG,` to demonstrate caller code; that's documentation, not a code-side raise. Pinned by a regression test. (2) **Transitive @raises** (codes raised by helpers the label calls but doesn't catch) is intentionally NOT inferred — would need a workspace call graph the m-cli lint engine doesn't yet have (cross-routine pass is the same gap M-XINDX-007/008 face). v1 surfaces direct raises only. The grammar guide §5.3 acknowledges this as an under-reporting trade-off; the manifest's `raised_in_body` informational field captures the same direct-raise set for consumers wanting it.
- **Validation against m-stdlib post-WA2**: `m lint --rules=M-DOC-001 src/` reports **zero findings** (every public label in src/ carries the required tag set). Project-wide `make lint` jumps from 567W → 600W (+33), all M-DOC-001 findings against `tests/STD*TST.m` files — test routines are NOT in WA2's scope, but M-DOC-001 correctly flags them as candidates for a follow-on backfill pass. **0E unchanged** (M-DOC-001 is WARNING, doesn't gate `--error-on=error`).
- **STDLOG side-fix** (m-stdlib commit pending alongside this row's update): the four level-emitter labels INFO/WARN/ERROR/FATAL each have 11 formals (`event,k1,v1,...,k5,v5`) but I'd taken a shortcut during WA2 and only annotated `@param k1` (with note "same shape through k5/v5"). M-DOC-001 correctly flagged the 36 missing `@param` tags. Backfilled to add the 9 missing per-label `@param` tags each — DEBUG already had the full set; INFO/WARN/ERROR/FATAL now match. After the fix: 0 M-DOC-001 findings against src/. Manifest regenerated.
- **Acceptance met.** Closing WA3.

---

#### WA4 — Manifest generator

**Status.** done (2026-05-08).

**Goal.** `tools/gen-manifest.m` walks `src/STD*.m` and writes `dist/stdlib-manifest.json` per the schema in plan § 3.2.

**Approach.**
- Hand-rolled M parser (~150 LoC). Decision recorded in plan § 11.4 / tracker D3 — do NOT bind to tree-sitter-m for v1.
- Recognised tokens: routine line (column 1, all-caps name); label line (column 1, lowercase or camel name, optional formal-list in parens); comment line (`;`); `; doc:` block (special).
- Emit JSON via `$$encode^STDJSON` — eat our own dog food.
- Provide a Makefile target `make manifest` that runs the generator.
- Source location: each label entry carries `source: {file, line}` so VS Code goto-def works without a separate index.

**Acceptance.** `make manifest` produces `dist/stdlib-manifest.json` containing every public label with the full schema. Manual spot-check against `STDJSON`, `STDDATE`, `STDREGEX` confirms accuracy.

**Out of scope.** Markdown rendering; HTML generation; per-module slim manifests (deferred per plan § 3.2 "until a consumer asks").

**Progress log.**
- **2026-05-08** — Generator landed as `tools/gen-manifest.py` (~370 LoC of Python), pivoting away from the planned `.m` implementation. **Reason for the pivot** (open redirect point if user prefers M): (a) there is no clean home for a non-stdlib M routine — `src/STDMAN.m` would pollute the consumer-facing stdlib promise, and `tools/*.m` has no precedent or routine-path wiring in m-cli's `m test` discovery; (b) Python's `json` stdlib emits canonical output cheaply where bash + jq would have been awkward (jq is not installed on host); (c) Python is already a project dependency through m-cli; (d) the plan § 3.2 explicitly allows alternative implementations ("or `.sh` wrapping..."). The eat-own-dog-food argument for using STDJSON loses out to shipping speed for v1; can be revisited if a real consumer needs it. Also pivoted artefact path: `tools/gen-manifest.m` → `tools/gen-manifest.py` (tracker row updated). **What landed:**
  - `tools/gen-manifest.py` — module-file walker (`parse_module_file`), label-line parser (`parse_label_line`), doc-block tag extractor (`parse_doc_block`), label entry builder (`build_label_entry`), manifest assembler (`build_manifest`), and an inline `--self-test` mode that parses a synthetic `STDFOO` fixture and asserts structural correctness (passes; runs in <100ms). Reads `CHANGELOG.md` to populate `stdlib_version` (currently `v0.4.0`). Emits `dist/stdlib-manifest.json` and `dist/errors.json` (the inverted error-code index — empty until WA2 adds `@raises` tags; this also covers WA7's deliverable).
  - **Schema as implemented:** `{stdlib_version, generated_at, modules: {NAME: {synopsis, description, errors, labels: {NAME: {form, signature, synopsis, params, returns, raises, raised_in_body, examples, since, stable, see_also, deprecated, description, source: {file, line}}}, source: {file, line}}}, errors: {CODE: {module, labels}}}`. The `raised_in_body` field is informational (lists `,U-STDxxx-,` codes detected via `set $ecode=` static scan) — it powers the WA3 lint rule's cross-check between actual raise sites and declared `@raises`. **Calibration vs the plan:** added `raised_in_body` (not in plan § 3.2 schema) for the WA3 hand-off; added module-level `description` (the routine-header prose under the synopsis) since it's free signal. Module-level `tag` / `phase` / `stable` / `storage` from plan § 3.2 are not yet populated — those come from `docs/modules/*.md` frontmatter once WA6 lands; the generator can merge them in then.
  - **Doc-comment grammar parser:** implements docs/guides/m-doc-grammar.md § 3 strictly. The key call: indent-based continuation — a non-tag line whose body starts with whitespace extends the prior tag; a non-indented non-tag line flushes the current tag and joins the description block. This made the `parse^STDJSON` worked example in §6 of the grammar guide work as written, without requiring an empty `; doc:` separator between the tag block and the post-tag prose.
  - **Makefile:** new `manifest` (regenerate) and `manifest-check` (regenerate + `git diff --exit-code`) targets. The `manifest-check` target is the local equivalent of WA5; the actual CI workflow change is still WA5's scope.
- **Real-world output.** `make manifest` against current src/ (no WA2 backfill) reports **32 modules, 519 public labels** in `dist/stdlib-manifest.json` (415 KB, 10,326 lines). Spot-checks confirm: (1) STDJSON.parse correctly classified extrinsic with `signature: "$$parse^STDJSON(text, root)"` and `source: {file: "src/STDJSON.m", line: 39}`; synopsis + description extracted faithfully. (2) Internal labels with no `; doc:` block (`parseFail`, `encodeFail`, `parseFileEof`) are correctly excluded. (3) Labels that have architecture-explainer `; doc:` blocks but aren't part of the public surface (e.g. `parseArray`, `encodeValue`, STDASSERT's `recordFail`) currently leak into the manifest — these need `@internal` tags during WA2 backfill, by design (the grammar's design call: better to ship leak-on-the-side-of-overinclusion than hide labels with documented contracts). (4) `dist/errors.json` is `{}` because no `@raises` tags exist yet — this is correct; backfill repopulates.
- **Two known sub-issues, deferred:** (a) The `signature` field reflects the formal-list verbatim (`text, root`), losing the by-reference convention (`text, .root` at call sites) — needs either a `@param`-level by-ref marker (grammar refinement) or static analysis (e.g. `kill <name>` / `merge <name>=` inside the body implies by-ref). Not v1 critical. (b) Module-level `phase` / `tag` / `stable` / `storage` fields from plan § 3.2 schema are absent at module level — they originate in `docs/modules/*.md` frontmatter (WA6) and will merge in once that lands.
- **Unblocks.** WA5 (CI gate — wire `make manifest-check` into `.github/workflows/ci.yml`); WA7 already covered (errors.json ships in the same generator); all of Wave B (`m doc` family reads `dist/stdlib-manifest.json`); WC1 (VS Code extension reads the same manifest); WD1 (AI skill regenerates from manifest).

---

#### WA5 — Manifest CI gate

**Status.** done (2026-05-08).

**Goal.** CI fails when `dist/stdlib-manifest.json` drifts from what `tools/gen-manifest.m` would produce.

**Approach.**
- Add a CI step: `make manifest && git diff --exit-code dist/stdlib-manifest.json`.
- Mirrors the existing `m fmt --check` pattern.
- The committed manifest **is** the authoritative artefact; any commit that touches a `; doc:` block must include the regenerated manifest in the same commit.

**Acceptance.** CI green when manifest matches; CI red when a tag is added/removed in src/ without re-running `make manifest`.

**Out of scope.** Auto-regenerating in CI and committing back — keep the regeneration as a developer responsibility (matches the `m fmt` model).

**Progress log.**
- **2026-05-08** — CI gate landed in `.github/workflows/ci.yml` as a new "Manifest drift check" step on the m-stdlib job, placed after the m-cli/tree-sitter-m install but before `Initialise YDB workspace`. The step runs `make manifest-check` (the local target landed with WA4) which regenerates the manifest and runs `git diff --exit-code dist/stdlib-manifest.json dist/errors.json`. Engine-free — only needs `python3` + `git`, both already installed by the prior steps. Not added to the iris-portability-check job because the manifest is engine-agnostic (one drift gate is sufficient). Not added to the local `make check` target — TDD loops touch `; doc:` blocks frequently and would trip the gate during normal iteration; CI is the authoritative gate, `make manifest-check` is the on-demand local equivalent.
- **Pre-flight fixes to `tools/gen-manifest.py` to make the gate viable.** The first manifest landed in WA4 had a `generated_at: <wall-clock>` field that changed every run, which would have caused the gate to fail spuriously on every commit. Removed the field outright — the information it carried (when was the manifest produced) is already covered by `stdlib_version` (sourced from CHANGELOG) and `git log dist/stdlib-manifest.json` (commit history). Also dropped `import datetime` and the `_dt.UTC` reference (Python 3.11+ only) for cross-version portability. Verified determinism with two consecutive `make manifest` runs — byte-identical output.
- **Unblocks.** Wave A close: WA6 (frontmatter on docs/modules/*.md, no deps) + WA8 (release tag) are the remaining stdlib-side rows. WA7 (errors.json) was already covered by WA4's generator. WA2 (backfill) and WA3 (lint rule in m-cli) remain.

---

#### WA6 — Doc frontmatter

**Status.** done (2026-05-08).

**Goal.** Every `docs/modules/stdXXX.md` gains YAML frontmatter (per plan § 3.3 schema).

**Approach.**
- Hand-edit each file (only ~20 modules).
- Treat the manifest as authoritative when frontmatter and manifest disagree (consumers read manifest first).
- Optional: small check script that warns on drift (`tools/check-doc-frontmatter.m`); not a CI gate yet.

**Acceptance.** Every per-module markdown parses as YAML+Markdown and carries the documented field set.

**Out of scope.** Generating these markdowns from the manifest — deferred. The markdown is human-written prose; the frontmatter is just structured metadata on top.

**Progress log.**
- **2026-05-08** — Pivoted from "hand-edit each file" to a small idempotent backfill tool, `tools/write-module-frontmatter.py` (~180 LoC). Reads `dist/stdlib-manifest.json` (synopsis, labels, errors per module) plus `docs/modules/index.md` (phase + tag tables, conformance corpora table, cross-module dependency bullets) and prepends a YAML frontmatter block to each `docs/modules/std*.md`. Idempotent on re-run — files that already start with `---\n` are skipped; `--force` regenerates. New Makefile target `make frontmatter` invokes it.
- **What landed:** all 32 module docs now carry frontmatter — module / tag / phase / stable / since / synopsis / labels / errors / conformance / see_also. Spot-check on `docs/modules/stdjson.md` shows the right shape (phase: Phase 2, tag: v0.2.0, conformance: ['tests/conformance/json/'], see_also: ['STDLOG', 'STDSEED'] — derived from index.md cross-deps).
- **Calibration vs the plan §3.3 schema.** The plan listed `storage` as a field; dropped it from the auto-derived set because it pointers at an in-doc anchor and changes per-module (better expressed in the prose itself). All other plan fields are populated. Stable defaults to "stable" for every module currently in a tagged release; experimental/deprecated will need hand-edits when those states arise.
- **Known limitations the user can iterate on:**
  - **`labels` includes internal helpers** (e.g. STDJSON's `parseArray`, `encodeValue`) because the manifest currently lists every label with a `; doc:` block. Once WA2 backfills `@internal` tags and the manifest regenerates, `make frontmatter --force` cleans up the labels list.
  - **`errors` is `[]` everywhere** because no `@raises` tags exist yet — also resolves with WA2.
  - **`synopsis` is the verbatim first line of the routine header** with `m-stdlib —` and trailing period stripped. Some have parenthetical track/tag noise (e.g. STDHTTP: "HTTP/1.1 client (track H3, target tag v0.4.0)"). Cleaning these is a separate src/ pass — not WA6's scope.
  - **`see_also`** is derived from index.md's cross-deps section — modules without a runtime dep relationship get `[]`. Hand-edits welcome; the tool's `--force` would clobber them today, so a future iteration should diff hand-curated fields and merge rather than overwrite.
- **Unblocks WA8** (release tag) — the only remaining stdlib-side row. WA2 (backfill) and WA3 (m-cli lint) are cross-repo.

---

#### WA7 — Errors registry

**Status.** done (2026-05-08; structurally rolled into WA4).

**Goal.** `dist/errors.json` is the inverted index: `U-STD*` code → producing module + labels.

**Approach.**
- Extend `tools/gen-manifest.m` to emit a second file. Same source data, different shape.
- Cheap derivative — adds a few lines to the generator.

**Acceptance.** `make manifest` writes both `dist/stdlib-manifest.json` and `dist/errors.json`; the errors index covers every `,U-STDxxx-NAME,` referenced in any `@raises` tag.

**Out of scope.** Per-error long-form descriptions — those live in the routine headers and per-module docs.

**Progress log.**
- **2026-05-08** — Done as part of WA4. `tools/gen-manifest.py` walks every label's `@raises` tags and aggregates an inverted `{code: {module, labels: [...]}}` index, written to `dist/errors.json` alongside the manifest. The CI manifest-check gate (WA5) covers this file too. `dist/errors.json` is currently `{}` because no `@raises` tags exist in src/ — once WA2 backfill adds them, the file populates without further generator work.

---

#### WA8 — Wave A release

**Status.** done (2026-05-08; tagged `v0.5.0` locally, not pushed).

**Goal.** Tag a release that ships the manifest, errors registry, frontmatter, and doc-grammar guide as one user-facing event. Update `docs/modules/index.md` with a "Machine-readable surface" subsection linking both `dist/` artefacts.

**Approach.**
- CHANGELOG entry under a new tag (decide `v0.5.0` vs `v0.4.1` based on whether Phase 4 module work has also accumulated — coordinate with the live `module-tracker.md`).
- Add the "Machine-readable surface" subsection to `docs/modules/index.md` linking the manifest, errors.json, and the new grammar guide.
- Ensure `docs/modules/index.md` and the manifest agree on the module list.

**Acceptance.** The new tag exists; CHANGELOG documents Wave A; `docs/modules/index.md` links the new artefacts.

**Out of scope.** Wave B/C/D consumer rollout — those waves can ship under their own tags later.

**Progress log.**
- **2026-05-08 (prep)** — All non-tag-cut prep work landed:
  - `CHANGELOG.md` gains an `[Unreleased]` section that captures Wave A — M-doc tag grammar v1, manifest generator + dist/, CI manifest-drift gate, frontmatter on all 32 module docs, the index.md machine-readable surface section. Frames the release as doc + tooling only (no `src/STD*.m` runtime behaviour change). Calls out WA2 + WA3 as the high-leverage Wave-A follow-ons.
  - `docs/modules/index.md` gains a "Machine-readable surface" subsection (right under the lead-in paragraph, before "Phase 1") — table of artefacts (`dist/stdlib-manifest.json`, `dist/errors.json`, `docs/guides/m-doc-grammar.md`, per-module frontmatter) plus regeneration commands (`make manifest`, `make frontmatter`, `make manifest-check`).
  - Pre-flight fix to `tools/gen-manifest.py`: `read_stdlib_version()` now skips an `[Unreleased]` heading and returns the most-recent versioned entry, so the manifest's `stdlib_version` stays anchored to the last shipped tag (`v0.4.0` today) until WA8's tag is cut. Without this fix, adding `[Unreleased]` to CHANGELOG would have flipped `stdlib_version` to empty string and the WA5 gate would have fired spuriously.
- **Pending — user decision points:**
  - **Version number.** `v0.5.0` (SemVer minor-bump for new tooling surface) vs `v0.4.1` (treat the docs/tooling delta as a patch). Recommendation: `v0.5.0` — the manifest is a new public API consumers will depend on, even if no `src/` runtime changes.
  - **Timing.** Tag now (Wave A is shippable as-is — manifest + frontmatter + grammar + CI gate all green), or wait for WA2 backfill to land first so the manifest's tag-derived fields populate before the version cut. Recommendation: tag now (decoupled releases — Wave A tag ships the surface, a follow-on tag ships the populated manifest from WA2).
  - **Coordination with module-level work.** If a Phase 4 module is mid-flight (Table 2 candidates: STDYAML / STDMATH / STDXFRM / STDNET), bundle vs. solo-cut. The current `module-tracker.md` says all numbered T-tickets T1-T30 are closed and Table 2 has only proposed (not started) modules — solo-cut is clean today.
- **Action when user gives the go-ahead:**
  1. Edit `[Unreleased]` heading in CHANGELOG.md → `[v0.5.0] — 2026-MM-DD` (or chosen version + date).
  2. `make manifest` to regenerate `stdlib_version` to the new tag.
  3. Commit the CHANGELOG header + manifest update as the release-sync commit (precedent: `53ecf70` for v0.4.0).
  4. `git tag -a v0.5.0 -m "<release annotation>"`. Decide whether to push (`git push origin v0.5.0`) per project policy.
  5. Flip this row to `done`.
- **2026-05-08 (release sync)** — User accepted both recommendations. Cut **v0.5.0**: CHANGELOG `[Unreleased]` heading flipped to `[v0.5.0] — 2026-05-08`; `make manifest` re-ran and `stdlib_version` flipped to `v0.5.0` in both `dist/stdlib-manifest.json` and `dist/errors.json`. Tag `v0.5.0` cut locally with annotated message enumerating Wave A scope. **Tag not pushed** — branch is local-only per session policy. Frontmatter not regenerated because `since:` per-module is anchored to each module's first-shipped tag (e.g. STDJSON's stays `v0.2.0`), not the rolling stdlib release. **Wave A m-stdlib-side: ALL DONE (WA1+WA4+WA5+WA6+WA7+WA8). Cross-repo: WA2 (src/ tag backfill), WA3 (m-cli M-DOC-001 lint), WB1 (m-cli `m doc`).**

---

### Wave B — m-cli `m doc` family

#### WB1 — `m doc <symbol>`

**Status.** done (2026-05-08; m-cli commit `0024a72` pushed to origin).

**Goal.** The flagship lookup command, modelled on `go doc`. Plan § 4.1 has the full UX spec.

**Approach.**
- New file in m-cli's command dir (verify path: likely `~/projects/m-cli/src/cmd/doc.m`; mirror existing command file conventions).
- Resolve m-stdlib via the same path the existing m-cli commands use; load `dist/stdlib-manifest.json`.
- Three forms: `m doc STDJSON` (module), `m doc STDJSON.parse` (label), `m doc parse` (fuzzy across modules).
- Output formatter: synopsis on top, signature highlighted, params / returns / raises blocks, example, since / stable / see line, source pointer at the bottom.

**Acceptance.** All three forms return correct output ≤ 100ms cold for the v0.5.0 manifest size.

**Out of scope.** Pager support, colour, network lookups (alt manifest sources). Keep v1 lean.

**Progress log.**
- **2026-05-08 (m-cli commit `0024a72`)** — Repurposed the existing `m doc` CLI from path-based extract-to-Markdown to godoc-style symbol lookup over `dist/stdlib-manifest.json`. Three-file module (`src/m_cli/doc/`): **`lookup.py`** owns manifest discovery (4-level fallback: --manifest flag → $M_CLI_MANIFEST env → walk-up from cwd → `~/projects/m-stdlib/dist/stdlib-manifest.json`) and symbol resolution (classifies into module / module.label / fuzzy bare-name); **`format.py`** owns three output forms (long with signature/params/returns/raises/example/source; short = one-line synopsis; json = raw manifest entry); **`cli.py`** is the rewritten argparse handler that ties them together. **Legacy `extract.py` / `render.py` kept on disk** as a programmatic surface — only the CLI was repurposed. **The 4 old `doc_command` tests in `test_doc.py` were dropped** since they exercised the path-based CLI behaviour that no longer exists; the 12 library-direct tests for extract/render still pass. **WB2 is structurally absorbed into WB1** because `--short` and `--json` are wired in this commit too (the plan separated them as a follow-on task; landing them together cost one extra flag definition and three test classes — total cost was negligible vs. shipping them separate). **WB3 fuzzy search** is also partially live here: `m doc <bare-name>` does cross-module exact-name lookup with multi-hit listing — the broader `m search "phrase"` substring scan is still WB3.
- **30 new tests in `tests/test_cli_doc_lookup.py`** covering: lookup classification (module / dotted / bare / unknown), manifest discovery order (explicit/env/walk-up/missing), all three output forms (module long/short/json + label long/short/json + multi-hit list), and CLI error paths (missing manifest → exit 2, malformed JSON → exit 2, no match → exit 1, found → exit 0). All pass.
- **End-to-end against m-stdlib v0.5.0**: `m doc STDJSON.parse` renders the full godoc-style block with signature `$$parse^STDJSON(text, root) → bool`, params/returns/raises tables, since/stable/see line, the `@example` body, and `source: src/STDJSON.m:39`. `m doc parse` finds 8 cross-module hits (STDARGS/STDCSV/STDENV/STDJSON/STDSEMVER/STDTOML/STDURL/STDXML each have a `parse` label). `m doc` (no args) lists all 32 modules with synopses. Cold latency ~30ms (well under the 100ms target).
- **Pre-existing manifest generator bug surfaced and fixed in m-stdlib (committed alongside this row's update)**: `tools/gen-manifest.py`'s `ROUTINE_LINE_RE` regex capped routine-name length at 8 chars (the M89 standard limit), but YDB and IRIS allow up to 31. STDASSERT (9), STDCRYPTO (9), STDCSPRNG (9), STDSEMVER (9), STDCOMPRESS (11) were all returning empty `synopsis` in the manifest. Relaxed to `[A-Z][A-Z0-9]{0,30}`. Manifest regenerated; all 32 modules now have non-empty synopses; frontmatter on the affected `docs/modules/*.md` regenerated to match.
- **Unblocks**: WB2 (`--json` + `--short` already shipped), WB3 (`m search` — keyword-search variant of WB1), WB4 (`m manifest` / `m examples` / `m errors` thin wrappers — all read the same manifest), WC1 (VS Code extension can consume the same manifest via the same path-resolution logic via a TypeScript port of `find_manifest`), WD1 (AI skill regenerator already has its input format pinned).

---

#### WB2 — `--json` and `--short` flags

**Status.** done (2026-05-08; landed in the same m-cli commit `0024a72` as WB1).

**Goal.** Scripting hooks. `--json` emits the raw manifest entry; `--short` emits one-line synopsis (godoc -short equivalent).

**Approach.** Trivial flag-handling on top of WB1.

**Acceptance.** `m doc --json STDJSON.parse | jq .signature` returns the signature string.

**Out of scope.** YAML / TOML output formats. JSON is enough.

**Progress log.**
- **2026-05-08** — Shipped together with WB1 in m-cli `0024a72`. Verified end-to-end: `m doc --json STDFMT.f | python3 -c 'import sys,json; print(json.load(sys.stdin)["signature"])'` → `$$f^STDFMT(template, a1, a2, a3, a4, a5, a6, a7, a8, a9)`. `m doc --short STDASSERT.eq` → `STDASSERT.eq — Assert actual=expected (string equality).`. Both forms covered by tests in `tests/test_cli_doc_lookup.py` (TestDocCommandShort, TestDocCommandJson).

---

#### WB3 — `m search <query>`

**Status.** done (2026-05-08; m-cli commit `6542e73` pushed to origin).

**Goal.** Fuzzy search across manifest synopsis + description + examples.

**Approach.**
- Linear scan of the manifest (cheap at this size; revisit if it slows down).
- Substring match, case-insensitive. Rank hits in synopsis above hits in examples.

**Acceptance.** `m search "json parse"` lists relevant labels with their synopses. `m search "URL encode"` finds STDURL.encode.

**Out of scope.** True fuzzy ranking (BM25, trigram). Substring is enough for v1.

**Progress log.**
- **2026-05-08 (m-cli `6542e73`)** — Landed at `~/projects/m-cli/src/m_cli/doc/search.py` (~115 LoC). **AND-style match across query tokens** (every space-separated token must appear somewhere in the label's haystack — synopsis ∪ description ∪ examples). **Three-tier ranking**: tier 0 = primary token in synopsis (highest priority), tier 1 = primary token in description, tier 2 = primary token only in examples. Within tier, results sort by (module, label) for determinism. **`--limit N`** truncates output (default 50); a footer message reports `showing N of M matches` when truncation kicks in. Manifest discovery is shared with `m doc` via the existing `find_manifest()` from `lookup.py` — same fallback chain (--manifest flag → $M_CLI_MANIFEST → walk-up from cwd → `~/projects/m-stdlib/dist/...`). Exit codes: 0 = matches found, 1 = no matches, 2 = manifest unreachable. **End-to-end against m-stdlib v0.5.0**: `m search "URL encode"` correctly returns STDB64.urldecode + STDB64.urlencode + STDURL.encode (the first two via @example bodies that contain "URL"; STDURL.encode via synopsis). `m search "json parse"` returns 6 hits ranked by tier (STDJSON.valid + STDLOG.FORMAT in tier 0 because both labels' synopses have "json" or "JSON"; STDJSON.parse + STDJSON.parseFile + STDJSON.lastError + STDJSON.valueOf in tier 1/2). 7 unit tests in `tests/test_cli_manifest_subcommands.py::TestSearch` covering case-insensitivity, AND-match, ranking, --limit truncation, no-match, missing-query.

---

#### WB4 — `m manifest`, `m examples`, `m errors`

**Status.** done (2026-05-08; m-cli commit `6542e73` pushed to origin — landed in same commit as WB3).

**Goal.** Thin wrappers that surface the manifest's substructures directly. Plan § 4.3–4.5.

**Approach.** Three short commands — each ≤ 30 LoC. They wrap reading the manifest / errors.json and emitting the relevant subsection.

**Acceptance.** Each command does its one job and pipes cleanly into `jq` or text tools.

**Out of scope.** Filtering flags beyond what's already there in `m doc`.

**Progress log.**
- **2026-05-08 (m-cli `6542e73`)** — Three sibling files under `~/projects/m-cli/src/m_cli/doc/`, each its own top-level CLI command, all sharing the manifest discovery from `lookup.py`:
  - **`m manifest [path]`** (`manifest.py` ~80 LoC) — emits the resolved manifest as JSON. With no path → whole manifest. With `STDJSON` / `STDJSON.parse` / `modules` / `errors` / `stdlib_version` → just that subtree. Pipes cleanly into `jq`. Verified: `m manifest stdlib_version` → `"v0.5.0"`; `m manifest STDJSON.encode | jq .signature` → `$$encode^STDJSON(node)`.
  - **`m examples [MODULE]`** (`examples.py` ~70 LoC) — walks every label's `@example` bodies and emits `module.label: <body>` lines for grep-friendliness. With a `MODULE` arg, scopes the walk to that module. Multi-line example bodies emit one prefixed line per source line. Verified: `m examples STDFMT` → `STDFMT.f: write $$f^STDFMT(...)`, `STDFMT.fn: set a("n")=...`.
  - **`m errors`** (`errors.py` ~95 LoC) — inverted index over `@raises` tags. Reads `dist/errors.json` (m-stdlib's WA7 sidecar) when present and falls back to deriving from the main manifest's per-label `raises` arrays — both produce identical output. `--json` emits the same shape as the sidecar for scripting. Verified: `m errors` lists all 43 codes from m-stdlib v0.5.0, each with producing module + every label that raises it (e.g. `U-STDCOMPRESS-CALLOUT-MISSING  STDCOMPRESS: gzip, gunzip, deflate, inflate, zstdCompress, zstdDecompress`).
- **17 unit tests** in `tests/test_cli_manifest_subcommands.py` covering: m manifest (full output, MODULE / MODULE.label / top-level subpaths, unknown paths); m examples (all-modules walk, module filter, no-examples module, unknown module); m errors (derivation from manifest, sidecar preference, --json flag, empty manifest). Plus 2 shared tests covering missing-manifest → 2 and malformed-manifest → 2 across all four WB3+WB4 commands.
- **Wave B status: ALL DONE — WB1+WB2+WB3+WB4 = 4/4 rows.** The full manifest-reader CLI surface from plan §4 is shipped: `m doc <symbol>` (long/short/json), `m search <query>`, `m manifest [path]`, `m examples [module]`, `m errors`. Cold latency ~30ms per command; manifest is a single ~415KB JSON read on each invocation.

---

### Wave C — VS Code extension

#### WC1 — Extension v0.1

**Status.** not-started.

**Goal.** Manifest-driven hover, goto-definition, and completion in VS Code for `.m` files. Plan § 5.1 has the capability list.

**Approach.**
- **First decision:** new repo `~/projects/m-stdlib-vscode/` vs subdir `~/projects/m-cli/vscode/`. Recommend new repo — keeps m-cli's release cycle clean and the VS Code extension publishable independently.
- TypeScript extension. On activation, locate the workspace's resolved m-stdlib (look for `.m-cli.toml` upwards; resolve install path the same way `m doc` does; load `dist/stdlib-manifest.json`).
- Register hover provider on `^STD*` and `parse^STDJSON`-style tokens.
- Register definition provider using `source.{file,line}` from the manifest.
- Register completion provider scoped to `.m` files.
- Hard scope: this is **not** a full M LSP. Stdlib symbols only.

**Acceptance.** Hover on `parse^STDJSON` shows synopsis + signature. Cmd/Ctrl-click jumps to `src/STDJSON.m:39`. Typing `^STD` shows a completion list of every module.

**Out of scope.** Full M LSP, project-aware symbols outside m-stdlib, lint integration, format-on-save (m-cli already has those via CLI).

**Progress log.**
- (none yet)

---

#### WC2 — Snippet pack

**Status.** not-started.

**Goal.** Canonical idiom snippets. Plan § 5.1.

**Approach.**
- VS Code snippet JSON for: STDASSERT suite skeleton, STDFIX `with` wrapper, STDLOG kv line, STDJSON parse-then-walk.
- Trigger names: `stdassert-suite`, `stdfix-with`, `stdlog-kv`, `stdjson-parse`.

**Acceptance.** Each snippet expands into a working, lint-clean M block.

**Out of scope.** Snippets for every module; cover only the high-frequency idioms.

**Progress log.**
- (none yet)

---

### Wave D — AI surface

#### WD1 — AI skill

**Status.** not-started.

**Goal.** A knowledge-skill at `~/claude/skills/m-stdlib/` regenerated from the manifest. Plan § 6.1.

**Approach.**
- New `tools/gen-skill.m` reads `dist/stdlib-manifest.json` + `dist/errors.json` and writes:
  - `~/claude/skills/m-stdlib/SKILL.md` (frontmatter with trigger conditions, prose orientation)
  - `~/claude/skills/m-stdlib/manifest-index.md` (one line per module + per public label, dense English)
  - `~/claude/skills/m-stdlib/patterns.md` (5–15 line idioms for STDASSERT / STDFIX / STDLOG / STDJSON)
  - `~/claude/skills/m-stdlib/error-codes.md` (every `U-STD*` code, origin, mitigation)
- CI gate: regenerate the skill, fail on diff (same model as the manifest gate).

**Acceptance.** Skill files exist and load via the standard skill mechanism. A `/skill m-stdlib` invocation gives the model the surface needed to write idiomatic m-stdlib code.

**Out of scope.** Hand-tuning skill prose beyond the generator output. If a passage needs prose embellishment, add it to a "static-prose" partial in the generator so re-runs don't lose it.

**Progress log.**
- (none yet)

---

#### WD2 — Doctest generator

**Status.** not-started.

**Goal.** Make `@example` lines executable. Plan § 3.4.

**Approach.**
- New `tools/gen-doctests.m` reads the manifest, extracts `@example` lines, and emits `tests/STDxxxDOCTST.m` per module.
- Generated suite uses STDASSERT plumbing to self-check examples. Two `@example` shapes:
  - Bare invocation followed by `; expected: <value>` → captured-output assertion.
  - Self-asserting `do eq^STDASSERT(...)` → emit verbatim.
- CI gate: regenerate doctests, fail on diff (same model as manifest gate).

**Acceptance.** Every module with ≥1 `@example` has a `*DOCTST.m` suite that runs under `m test`. Suite green. Doc example drift fails CI.

**Out of scope.** Doctest support for non-public labels (internal helpers) — public surface only.

**Progress log.**
- (none yet)

---

## Sequencing summary

A compact dependency view, useful when planning a session:

```
Wave A:
  WA1 ──┬──► WA2 ──┐
        ├──► WA3   │
        └──► WA4 ──┼──► WA5
                   ├──► WA7 ──┐
              WA6 ─┴──────────┴──► WA8

Wave B (depends on WA4):
  WA4 ──► WB1 ──► WB2
       └─► WB3
       └─► WB4 (also needs WA7 for `m errors`)

Wave C (depends on WA4):
  WA4 ──► WC1 ──► WC2

Wave D:
  WA4 ──► WD1
  WA1 + WA2 ──► WD2
```

The shortest path to a useful new capability is **WA1 → WA4 → WB1**:
once those three are done, every subsequent piece (other Wave A
items, the rest of Wave B, all of Wave C, Wave D) becomes easier.
