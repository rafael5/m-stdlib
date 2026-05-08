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
| WA2 | not-started | WA | 2 | stdlib | Backfill structured doc tags across all public labels in `src/STD*.m` (incl. `@stable` tier annotation per § 3.6) | WA1 | 3–4d | Every public label in src/ has `@param`s matching the formal-list, `@returns` for extrinsics, `@raises` for any `$ECODE` it sets, ≥1 `@example`, `@since`, `@stable`. Manifest generator (WA4) parses src/ without diagnostics. | § 3.1, § 3.6 | `src/STD*.m` (all 30+ routines) |
| WA3 | not-started | WA | 3 | m-cli | Add lint rule `M-DOC-001` warning on public labels missing required tags (warn-only at first) | WA1 | 0.5–1d | `m lint` raises `M-DOC-001` (severity warn) on a public label whose `; doc:` block is missing `@returns` (extrinsic) or has a `@param` not in the formal-list. No errors emitted yet. | § 3.1 (acceptance gate) | m-cli lint rules dir |
| WA4 | done | WA | 4 | stdlib | Implement `tools/gen-manifest.py` — hand-rolled parser — that walks `src/STD*.m` and emits `dist/stdlib-manifest.json` + `dist/errors.json` per the § 3.2 schema | WA1 | 1–2d | Running `make manifest` produces `dist/stdlib-manifest.json`; all public labels present with signature, source.file/line, plus tag-derived fields (params, returns, raises, examples, since, stable, see_also) populated when WA2 backfill provides tags. | § 3.2, § 11.4 | `tools/gen-manifest.py` (new, ~370 LoC), `dist/stdlib-manifest.json` (new, generated), `dist/errors.json` (new, generated), `Makefile` (`manifest` + `manifest-check` targets) |
| WA5 | done | WA | 5 | stdlib | CI gate: regenerate manifest in CI, fail on diff against committed `dist/stdlib-manifest.json` | WA4 | 0.5d | CI workflow runs `make manifest-check`; passes today, fails if a label changes without manifest re-gen. | § 3.2 (acceptance gate) | `.github/workflows/ci.yml` (step add), `Makefile` (already had `manifest-check`) |
| WA6 | not-started | WA | 6 | stdlib | Add YAML frontmatter (module / tag / phase / stable / since / synopsis / errors / labels / conformance / see_also) to every `docs/modules/stdXXX.md` | — | 0.5d | Every per-module markdown has frontmatter parsing cleanly as YAML. Field values agree with the manifest where overlapping (verified by a small check script, not gated yet). | § 3.3 | `docs/modules/std*.md` |
| WA7 | done | WA | 7 | stdlib | Generate `dist/errors.json` (inverted index of `U-STD*` codes → producing module + labels) as a derivative of the manifest | WA4 | 0.25d | `make manifest` also writes `dist/errors.json` containing every `U-STD*` code with its origin module + labels. | § 3.5 | `tools/gen-manifest.py` (covers WA7 too), `dist/errors.json` (generated) |
| WA8 | not-started | WA | 8 | stdlib | Cut a release tag carrying Wave A; update `docs/modules/index.md` to link the manifest + errors registry | WA2, WA4, WA5, WA6, WA7 | 0.5d | A new tag (≥ `v0.5.0` or per CHANGELOG decision) ships with manifest + errors.json + frontmatter; `docs/modules/index.md` carries a "Machine-readable surface" subsection linking both. | § 8 Wave A gate | `CHANGELOG.md`, `docs/modules/index.md`, git tag |
| WB1 | not-started | WB | 1 | m-cli | `m doc <symbol>` — module overview, single-label, fuzzy lookup; reads `dist/stdlib-manifest.json` from the resolved m-stdlib install at runtime | WA4 | 1–2d | `m doc STDJSON`, `m doc STDJSON.parse`, and `m doc parse` all return correct godoc-style output within ~100ms cold. | § 4.1 | `~/projects/m-cli/src/cmd/doc.m` (new) |
| WB2 | not-started | WB | 2 | m-cli | `m doc --json` and `m doc --short` flags | WB1 | 0.5d | `--json` emits the raw manifest entry; `--short` emits one-line synopsis. Both stable for scripting. | § 4.1 | `~/projects/m-cli/src/cmd/doc.m` |
| WB3 | not-started | WB | 3 | m-cli | `m search <query>` — full-text fuzzy search over manifest synopsis + description + example | WA4 | 0.5–1d | `m search "json parse"` returns ranked `module.label — synopsis` lines; matches against case-insensitive substrings in synopsis, description, examples. | § 4.2 | `~/projects/m-cli/src/cmd/search.m` (new) |
| WB4 | not-started | WB | 4 | m-cli | `m manifest`, `m examples <module>`, `m errors` thin wrappers | WA4, WA7 | 0.5d | All three commands emit useful output piped from the manifest / errors registry. | § 4.3, § 4.4, § 4.5 | `~/projects/m-cli/src/cmd/manifest.m`, `examples.m`, `errors.m` (all new) |
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

**Status.** not-started.

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
- (none yet)

---

#### WA3 — Lint rule `M-DOC-001`

**Status.** not-started.

**Goal.** Warn on public labels missing required tags. Lives in m-cli (where lint rules live), not m-stdlib.

**Approach.**
- Locate the existing m-cli lint rule directory; follow the pattern of an existing M-* rule.
- Severity = warn (not error) at first; promote to error in a later release once WA2 backfill is complete and stays clean.
- Required tags by label form: extrinsic (`label() ; ...`) needs `@returns`; procedure (`label(args) ; ...`) needs `@param` matching every formal arg; both need ≥1 `@example` if `@stable=stable`.

**Acceptance.** `m lint` against m-stdlib emits zero `M-DOC-001` errors after WA2; emits warnings only on labels not yet backfilled.

**Out of scope.** Stricter rules (`M-DOC-002`+) — defer to a later pass. The acceptance-gate threshold change to `--error-on=warning` for `M-DOC-*` is also out of scope until backfill is complete.

**Progress log.**
- (none yet)

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

**Status.** not-started.

**Goal.** Every `docs/modules/stdXXX.md` gains YAML frontmatter (per plan § 3.3 schema).

**Approach.**
- Hand-edit each file (only ~20 modules).
- Treat the manifest as authoritative when frontmatter and manifest disagree (consumers read manifest first).
- Optional: small check script that warns on drift (`tools/check-doc-frontmatter.m`); not a CI gate yet.

**Acceptance.** Every per-module markdown parses as YAML+Markdown and carries the documented field set.

**Out of scope.** Generating these markdowns from the manifest — deferred. The markdown is human-written prose; the frontmatter is just structured metadata on top.

**Progress log.**
- (none yet)

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

**Status.** not-started.

**Goal.** Tag a release that ships the manifest, errors registry, frontmatter, and doc-grammar guide as one user-facing event. Update `docs/modules/index.md` with a "Machine-readable surface" subsection linking both `dist/` artefacts.

**Approach.**
- CHANGELOG entry under a new tag (decide `v0.5.0` vs `v0.4.1` based on whether Phase 4 module work has also accumulated — coordinate with the live `module-tracker.md`).
- Add the "Machine-readable surface" subsection to `docs/modules/index.md` linking the manifest, errors.json, and the new grammar guide.
- Ensure `docs/modules/index.md` and the manifest agree on the module list.

**Acceptance.** The new tag exists; CHANGELOG documents Wave A; `docs/modules/index.md` links the new artefacts.

**Out of scope.** Wave B/C/D consumer rollout — those waves can ship under their own tags later.

**Progress log.**
- (none yet)

---

### Wave B — m-cli `m doc` family

#### WB1 — `m doc <symbol>`

**Status.** not-started.

**Goal.** The flagship lookup command, modelled on `go doc`. Plan § 4.1 has the full UX spec.

**Approach.**
- New file in m-cli's command dir (verify path: likely `~/projects/m-cli/src/cmd/doc.m`; mirror existing command file conventions).
- Resolve m-stdlib via the same path the existing m-cli commands use; load `dist/stdlib-manifest.json`.
- Three forms: `m doc STDJSON` (module), `m doc STDJSON.parse` (label), `m doc parse` (fuzzy across modules).
- Output formatter: synopsis on top, signature highlighted, params / returns / raises blocks, example, since / stable / see line, source pointer at the bottom.

**Acceptance.** All three forms return correct output ≤ 100ms cold for the v0.5.0 manifest size.

**Out of scope.** Pager support, colour, network lookups (alt manifest sources). Keep v1 lean.

**Progress log.**
- (none yet)

---

#### WB2 — `--json` and `--short` flags

**Status.** not-started.

**Goal.** Scripting hooks. `--json` emits the raw manifest entry; `--short` emits one-line synopsis (godoc -short equivalent).

**Approach.** Trivial flag-handling on top of WB1.

**Acceptance.** `m doc --json STDJSON.parse | jq .signature` returns the signature string.

**Out of scope.** YAML / TOML output formats. JSON is enough.

**Progress log.**
- (none yet)

---

#### WB3 — `m search <query>`

**Status.** not-started.

**Goal.** Fuzzy search across manifest synopsis + description + examples.

**Approach.**
- Linear scan of the manifest (cheap at this size; revisit if it slows down).
- Substring match, case-insensitive. Rank hits in synopsis above hits in examples.

**Acceptance.** `m search "json parse"` lists relevant labels with their synopses. `m search "URL encode"` finds STDURL.encode.

**Out of scope.** True fuzzy ranking (BM25, trigram). Substring is enough for v1.

**Progress log.**
- (none yet)

---

#### WB4 — `m manifest`, `m examples`, `m errors`

**Status.** not-started.

**Goal.** Thin wrappers that surface the manifest's substructures directly. Plan § 4.3–4.5.

**Approach.** Three short commands — each ≤ 30 LoC. They wrap reading the manifest / errors.json and emitting the relevant subsection.

**Acceptance.** Each command does its one job and pipes cleanly into `jq` or text tools.

**Out of scope.** Filtering flags beyond what's already there in `m doc`.

**Progress log.**
- (none yet)

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
