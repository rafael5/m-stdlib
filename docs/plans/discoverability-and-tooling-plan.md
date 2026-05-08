---
title: m-stdlib — discoverability, metadata, and tooling plan
status: proposal (no work started)
last-updated: 2026-05-08
companion: m-stdlib-implementation-plan.md (the live build plan; this doc is the
  cross-cutting "make it usable" plan that runs in parallel)
audience: m-stdlib maintainers; m-cli maintainers; VS Code / AI tooling builders
---

# m-stdlib — discoverability, metadata, and tooling plan

A standard library is only as useful as its **discoverability**: the
ease with which a developer (human or AI) can answer the questions
"does m-stdlib already do this?", "what's the exact signature?", "show
me an example", "what does it raise?", "what's the storage shape?".
Today m-stdlib answers these questions well **for a human reading the
source**, less well for a human in VS Code without the source open,
and poorly for an AI assistant that has not been hand-fed the file.

This plan catalogues the gap, surveys how Python / Go / Rust solve the
same problem, and recommends a phased set of changes — to m-stdlib
itself, to m-cli, to VS Code tooling, and to the AI surface — that
together turn the library into a **first-class discoverable surface**
on every consumption channel.

---

## 1. Current state — what already exists

m-stdlib is in a strong starting position. The conventions below are
already enforced repo-wide; the plan extends rather than replaces
them.

### 1.1 In each `src/STD*.m` routine

- A header block immediately under the routine line:
  - One-line purpose (`; m-stdlib — RFC 8259 JSON parser + serialiser.`)
  - **Public API** section listing every public extrinsic / procedure
    with signature and one-line summary
  - Storage / wire-format conventions where relevant (e.g. STDJSON's
    sigil table, STDDATE's horolog forms)
  - **Errors** — every `$ECODE` value the module raises, in the
    `,U-STDxxx-NAME,` namespace
- Per-label contracts via `; doc:` comments immediately under the
  label line — purpose, args, returns, edge cases, often an
  `; doc: Example:` line
- Lint disables documented inline (`; m-lint: disable-file=M-MOD-024`
  with rationale)

### 1.2 In `docs/modules/`

- `index.md` — phase-keyed catalogue of every shipped module with
  tag, purpose, and link to the per-module doc
- One `stdXXX.md` per module: Public API table, storage model,
  examples, conformance corpus reference, error-code list

### 1.3 In `docs/guides/`

- `users-guide.md` — top-level orientation
- `m-tdd-guide.md` — the TDD workflow that ties STDASSERT / STDFIX /
  STDMOCK / STDSEED / STDPROF / STDSNAP / STDENV together

### 1.4 What is *not* yet there

| Gap | Impact on humans | Impact on AI |
|---|---|---|
| No frontmatter on `docs/modules/*.md` | Mild — humans navigate via index | Significant — no machine-readable per-doc metadata |
| No structured doc-comment grammar (the `; doc:` convention is informal) | Mild — readable but not greppable for "what raises X" | High — AI cannot reliably extract signatures / params / returns / examples without reading whole files |
| No machine-readable manifest of all public symbols | Mild — humans use grep | High — AI must re-scan src/ each session; VS Code has no symbol index |
| No `m doc` command in m-cli | Mild — humans open `docs/modules/` | High — AI agents can't ask the toolchain "what's the signature?" |
| No VS Code extension | Significant — no hover docs, no goto-def into m-stdlib, no completion of `^STD*` symbols | n/a |
| No central error-code registry | Mild — humans grep `,U-STD` across src/ | High — AI cannot enumerate the error surface |
| No machine-checkable doctests | Mild — examples in `; doc:` are not executed | High — AI-generated examples can drift undetected |

The thesis of the rest of this plan: **invest in (a) a formal doc-comment
grammar that is the single source of truth, (b) a generated machine-
readable manifest, and (c) thin consumers (m-cli, VS Code, AI skills)
that all read from that manifest.** Don't duplicate text across `.m`
headers, `docs/modules/*.md`, and a future manifest — pick one source
and generate the rest.

---

## 2. How other standard libraries solve this

The four mainstream modern stdlibs converge on roughly the same
pattern. m-stdlib should adopt the parts that map cleanly onto M.

### 2.1 Python

- **Docstrings (PEP 257)** are first-class language values
  (`function.__doc__`); `help(obj)` is a runtime built-in.
- **Type hints (PEP 484)** are machine-readable signatures at the
  language level.
- **Sphinx + reStructuredText** generate HTML docs from docstrings;
  intersphinx cross-links libraries; ReadTheDocs hosts and rebuilds
  on every commit.
- **Doctests** (`>>> ` blocks in docstrings) execute as part of
  `pytest --doctest-modules` — examples that don't run, fail.
- **stub files (`.pyi`)** decouple type info from implementation for
  performance-critical or C-implemented modules.

**Lesson for m-stdlib:** doc text lives next to the code, but a
generator turns it into a separate publishable artefact. Examples are
*executable*. Type info is *machine-extractable*.

### 2.2 Go

- **godoc convention** is dead-simple: a comment immediately above a
  declaration is the doc; the first sentence is the synopsis. No
  tags, no markup syntax beyond a few rules.
- **`go doc <symbol>`** is a command-line tool every Go developer has
  in muscle memory. `go doc encoding/json.Unmarshal` returns the
  signature + first paragraph of the doc.
- **Examples** are `func Example*` test functions — they appear
  inline in the rendered docs and are run by `go test`.
- **`pkg.go.dev`** is the canonical hosted index; it auto-builds for
  every public module.
- **`doc.go`** — a per-package file that holds the package-level
  overview, separate from any specific symbol.

**Lesson for m-stdlib:** the **CLI lookup tool** (`go doc`) is the
single biggest force-multiplier. `m doc STDJSON.parse` should exist
and be fast (sub-100ms). Examples should be runnable.

### 2.3 Rust

- **rustdoc** uses `///` for outer docs and `//!` for inner docs;
  body is **CommonMark Markdown**. This is the most expressive
  doc-comment syntax of the four.
- **Doctests** in fenced code blocks are compiled and run by
  `cargo test`. Compile-failure of a doc example fails the suite.
- **`#[doc]` attribute** allows programmatic doc generation (macros,
  conditional docs).
- **`docs.rs`** auto-builds rustdoc for every published crate.
- **`cargo doc --open`** is the developer's daily-driver.
- **Search index** — every rustdoc site ships a static
  `search-index.js` keyed on (crate, module, item) that powers
  in-page fuzzy search **and** is consumed by tooling.

**Lesson for m-stdlib:** the **search index** is the killer feature.
A static JSON of (module, label, signature, summary, tags) is
trivial to ship, infinitely useful to humans (fuzzy search on a docs
site) and AI (one-shot grep of the entire library surface).

### 2.4 Node / TypeScript

- **JSDoc tags** (`@param`, `@returns`, `@throws`, `@example`,
  `@deprecated`, `@since`) provide a structured grammar inside the
  free-form doc-comment.
- **`.d.ts`** declaration files give the compiler / editor a
  signatures-only view that is fast to load.
- **Language Server Protocol (LSP)** drives hover, goto, completion
  in every editor; the same server feeds VS Code, Vim, and Emacs.

**Lesson for m-stdlib:** **structured tags** are the bridge between
free-form prose and machine extraction. `.d.ts` is the model for a
**signatures-only manifest** that AI and editors consume without
parsing the implementation.

### 2.5 Synthesis

| Capability | Python | Go | Rust | Node/TS | m-stdlib today | m-stdlib target |
|---|---|---|---|---|---|---|
| Doc lives next to code | ✅ docstring | ✅ comment-above | ✅ `///` | ✅ JSDoc | ✅ `; doc:` | keep |
| Structured doc tags | informal | informal | markdown | ✅ JSDoc tags | informal | **add** |
| CLI lookup | `help()` (REPL) | ✅ `go doc` | ✅ `cargo doc` | — | — | **add** (`m doc`) |
| Generated HTML / md docs | ✅ Sphinx | ✅ pkg.go.dev | ✅ docs.rs | ✅ TypeDoc | partial (hand-written) | **generate from source** |
| Machine-readable manifest | type-stubs | godoc -json | search-index.js | `.d.ts` | — | **add** (`stdlib-manifest.json`) |
| Doctests executed | ✅ doctest | ✅ Example funcs | ✅ rustdoc | partial | — | **add** |
| Editor LSP integration | ✅ pylsp | ✅ gopls | ✅ rust-analyzer | ✅ tsserver | — | **add** (M LSP, scoped to stdlib first) |
| Static error-surface index | exceptions in docs | error vars | `Result<T,E>` | `@throws` | per-routine header only | **central registry** |

---

## 3. Recommendations — the m-stdlib surface

This section recommends changes inside `m-stdlib` itself. Sections
4–6 cover m-cli, VS Code, and AI consumers. The intended dependency
order is **3 → 4 → 5 → 6** (manifest first; everything else reads
from it).

### 3.1 Formalise an M-doc grammar (extends, does not replace, `; doc:`)

**Proposal.** Specify a tiny structured-tag grammar that lives inside
the existing `; doc:` comment line. Tags are optional; existing
prose-only `; doc:` lines remain valid. The formatter and linter
learn the grammar.

```m
parse(text,root)        ; Parse `text` into `root`. Returns 1/0.
        ; doc: @param text   string  RFC-8259 JSON document
        ; doc: @param root   array   caller-owned destination (killed before populate)
        ; doc: @returns      bool    1 on success, 0 on failure
        ; doc: @raises       U-STDJSON-PARSE  malformed input
        ; doc: @example      do parse^STDJSON("[1,2,3]",.t) write $$type^STDJSON(.t) ; "array"
        ; doc: @since        v0.2.0
        ; doc: @stable       stable
        ; doc: @see          $$valid^STDJSON, $$lastError^STDJSON
        ; doc: Kills `root` first. On failure, $$lastError() holds the
        ; doc: "line:col: msg" diagnostic and the partial tree is killed.
```

**Rules.**
- A `@tag` must be the first non-whitespace token after `; doc:`.
- Tags allowed: `@param`, `@returns`, `@raises`, `@example`,
  `@since`, `@stable` (one of `experimental`, `stable`, `deprecated`),
  `@see`, `@deprecated`, `@internal`.
- Untagged `; doc:` lines are **prose continuation** — appended to
  the prior tag, or to a free-form description block if before the
  first tag.
- The first tag-free `; doc:` line is the **synopsis** (consumed by
  `m doc` short-form output, godoc-style).

**Why this shape.** Free-form prose stays readable; the tag set is
small enough to memorise; it maps 1:1 onto JSDoc / rustdoc concepts
the AI assistants already know; and it can be parsed with ~30 lines
of M code or a tree-sitter-m query.

**Acceptance gate.** A new lint rule `M-DOC-001` that warns (not
errors) on any public label whose `; doc:` block is missing
`@returns` (for extrinsics) or has a `@param` not matching the
formal-list. Promote to error in a later release.

### 3.2 Single source of truth → generated manifest

**Proposal.** Generate `dist/stdlib-manifest.json` from src/ on every
build. The manifest is the **canonical machine-readable surface**;
`docs/modules/*.md` becomes a generated artefact consuming the same
manifest.

**Schema (sketch):**

```json
{
  "stdlib_version": "0.4.0",
  "generated_at": "2026-05-08T00:00:00Z",
  "modules": {
    "STDJSON": {
      "tag": "v0.2.0",
      "phase": "Phase 2",
      "synopsis": "RFC 8259 JSON parser + serialiser.",
      "stable": "stable",
      "errors": ["U-STDJSON-PARSE", "U-STDJSON-ENCODE"],
      "storage": "see docs/modules/stdjson.md#storage-model",
      "labels": {
        "parse": {
          "form": "extrinsic",
          "signature": "$$parse^STDJSON(text, .root)",
          "params": [
            {"name": "text", "type": "string", "doc": "RFC-8259 JSON document"},
            {"name": "root", "type": "array",  "doc": "caller-owned destination"}
          ],
          "returns": {"type": "bool", "doc": "1 on success, 0 on failure"},
          "raises": ["U-STDJSON-PARSE"],
          "examples": [
            "do parse^STDJSON(\"[1,2,3]\",.t) write $$type^STDJSON(.t) ; \"array\""
          ],
          "since": "v0.2.0",
          "stable": "stable",
          "see_also": ["valid^STDJSON", "lastError^STDJSON"],
          "synopsis": "Parse `text` into `root`. Returns 1/0.",
          "source": {"file": "src/STDJSON.m", "line": 39}
        }
      }
    }
  },
  "errors": {
    "U-STDJSON-PARSE": {"module": "STDJSON", "labels": ["parse", "valid", "parseFile"]}
  }
}
```

**Why a single big manifest, not per-routine sidecars.**

- One file → one HTTP fetch / one `Read` for an AI agent.
- A search index over (module, label, synopsis, example) is one pass
  over the same JSON.
- Cross-refs (`@see`, error → producing-labels reverse index) are
  cheap to compute once.
- Per-routine sidecars duplicate the file-walk cost; humans don't
  open them; editors prefer one warm cache.

A **per-module slim view** (`dist/manifest/STDJSON.json`) can be
emitted alongside as an optional optimisation — same data, scoped —
for tools that want one module at a time. Recommendation: **defer
this** until a consumer asks for it.

**Generator.** A new `tools/gen-manifest.m` (or `.sh` wrapping a
tree-sitter-m query) reads src/ and writes `dist/stdlib-manifest.json`.
CI verifies the generator's output is byte-identical to the committed
file (so manifest drift fails the build the same way `m fmt` drift
does today).

### 3.3 Doc frontmatter on `docs/modules/*.md`

**Proposal.** Every `docs/modules/stdXXX.md` gains YAML frontmatter
with the same machine-readable fields the manifest carries. This
makes the markdown layer also greppable without parsing it.

```yaml
---
module: STDJSON
tag: v0.2.0
phase: Phase 2
stable: stable
since: v0.2.0
synopsis: RFC 8259 JSON parser + serialiser.
errors: [U-STDJSON-PARSE, U-STDJSON-ENCODE]
labels: [parse, encode, valid, lastError, type, valueOf, parseFile, writeFile]
conformance: tests/conformance/json/
see_also: [STDREGEX, STDURL, STDLOG]
---
```

If the manifest exists and is authoritative, frontmatter is
redundant for tools — but it's still cheap to write, cheap to
validate, and it future-proofs the docs against tools that don't
want to load the full manifest. **Keep frontmatter; treat the
manifest as the canonical answer when they disagree.**

### 3.4 Executable doctests

**Proposal.** Every `@example` line in a public label's doc block is
extracted by a new `tools/gen-doctests.m` and emitted as a generated
test routine `tests/STDJSONDOCTST.m` (etc.) that runs under the
existing `m test` runner. Examples that don't run, fail.

This delivers Rust's "examples-can't-rot" guarantee with zero new
tooling on the runner side — it's just more `*TST.m` routines.

**Convention.** An `@example` line is either:

- A bare invocation that produces visible output (`write $$x^MOD(...)`
  → captured and compared against the next `@example` line if it
  starts with `; expected:`), **or**
- A self-asserting expression: `do eq^STDASSERT(.p,.f, $$x^MOD(...),
  expected, "doc example")` — already self-checking.

The second form is preferred because it composes with existing
STDASSERT plumbing.

### 3.5 Central error-code registry

**Proposal.** A generated `dist/errors.json` (subset of the
manifest's `errors` map) becomes the canonical answer to "what does
m-stdlib raise, and from where?". Today this is per-module. Pulling
it into one file lets AI / docs / `m doc errors` enumerate the
entire error surface in one read.

The `,U-STDxxx-NAME,` naming convention is already disciplined; the
registry is just the inverted index.

### 3.6 Stability tier per public label

**Proposal.** Every public label is annotated with one of:

- `experimental` — may change without a major bump
- `stable` — guarded by SemVer
- `deprecated` — slated for removal; `@deprecated since v0.X` and
  `@see` the replacement

The tier surfaces in the manifest, in `m doc`, and as a docstring
badge in `docs/modules/*.md`. Deprecation is the harder discipline —
without a tier, m-stdlib has no graceful API-evolution story.

---

## 4. Recommendations — m-cli (the toolchain layer)

m-cli is the natural home for *consuming* the manifest. None of these
require new infra beyond the manifest from §3.2.

### 4.1 `m doc <symbol>`

The single most-impactful tool. Mirrors `go doc`.

```bash
$ m doc STDJSON.parse
$$parse^STDJSON(text, .root) → bool

Parse `text` into `root`. Returns 1/0.

  text  string   RFC-8259 JSON document
  root  array    caller-owned destination (killed before populate)

raises:  U-STDJSON-PARSE
since:   v0.2.0   stable
see:     valid^STDJSON, lastError^STDJSON

example:
  do parse^STDJSON("[1,2,3]",.t)
  write $$type^STDJSON(.t)  ; "array"

source: src/STDJSON.m:39
```

Forms:
- `m doc STDJSON` — module overview + label list
- `m doc STDJSON.parse` — single label
- `m doc parse` — fuzzy lookup across all modules
- `m doc --short STDJSON.parse` — synopsis-only (one line)
- `m doc --json STDJSON.parse` — raw manifest entry (AI / scripting)

### 4.2 `m search <query>`

Full-text search over the manifest's `synopsis` + `description` +
`example` fields. Returns ranked `module.label — synopsis` lines.
Same code path as the docs-site search index in §5.2.

### 4.3 `m manifest`

Emits the resolved `stdlib-manifest.json` (or a filtered subset) on
stdout. Trivial wrapper for piping into `jq` or feeding an AI agent.

### 4.4 `m examples STDJSON`

Prints every `@example` from the module. Convenient for "show me
how to use this" without opening the per-module markdown.

### 4.5 `m errors`

Lists every `U-STD*` error code, the module that raises it, and the
labels that can raise it. One-shot answer to "where could this
$ECODE come from?".

### 4.6 m-cli ↔ m-stdlib coupling

m-cli must not vendor the manifest. It looks up m-stdlib by the
already-existing import path and reads `dist/stdlib-manifest.json`
from the installed copy. Multiple m-stdlib versions on a system →
m-cli respects the project's resolved version (same model as `m fmt`
/ `m lint` finding the project's `.m-cli.toml`).

---

## 5. Recommendations — VS Code (the editor surface)

This is where the human-developer experience compounds. Two
deliverables, in order:

### 5.1 m-stdlib VS Code extension (lightweight; ships first)

Built on the manifest alone — no language server required.

**Capabilities:**
- **Hover**: hovering on `^STDJSON`, `parse^STDJSON`, or
  `$$parse^STDJSON(...)` shows the synopsis + signature + first
  example, sourced from the manifest.
- **Go to definition** (manifest-driven): jumps to
  `src/STDJSON.m:39` for `parse^STDJSON` (the manifest already
  carries the line number).
- **Completion**: typing `^STD` triggers a completion list of every
  module; typing `parse^STD` filters; selecting inserts the call
  with parameter snippets.
- **Diagnostic surface for `,U-STD*,`**: when an `$ETRAP` handler
  references `,U-STDJSON-PARSE,` or similar, hover shows where it's
  raised.
- **Snippets** for the canonical patterns: STDASSERT suite skeleton,
  STDFIX `with` wrapper, STDLOG kv line, STDJSON parse-then-walk.

**Scope guardrail.** This is **not** a language server for M. It is
specifically the **m-stdlib companion**. M-language LSP is a much
larger project (parsing, type inference over `$T` etc., scope
analysis); deferring it lets the stdlib win immediately.

**Implementation sketch.** TypeScript extension. On activation, load
`dist/stdlib-manifest.json` from the workspace's resolved m-stdlib.
Register hover, completion, and definition providers scoped to `.m`
files. Roughly 500 LoC for a v0.1.

### 5.2 Docs site with searchable static index (optional but cheap)

Generate `dist/site/` from the manifest + `docs/modules/*.md`. Host
on GitHub Pages. Ship a `search-index.json` (rustdoc-style) that
powers an in-page fuzzy search. Same JSON the VS Code extension
loads — single source of truth.

The bar for "would this be worth it?": the moment a second human
developer outside the maintainer ring needs to onboard, the docs
site recoups its cost.

### 5.3 Future: full M LSP

Out of scope for this plan. Track separately. The stdlib extension
should be designed so that when a real LSP arrives, the stdlib
surface federates into it (the manifest is still the authority for
stdlib symbols).

---

## 6. Recommendations — AI-assisted development

The AI surface benefits from §3 (manifest) and §4 (m-cli) almost for
free. The remaining items are about **reducing context cost** for
agents working with m-stdlib.

### 6.1 An AI-context skill at `~/claude/skills/m-stdlib/`

A knowledge-skill (per the global skill convention) loaded on
demand. Contents:

- `SKILL.md` — frontmatter declaring trigger conditions ("user is
  writing M and references `^STD*` symbols, OR working in a project
  whose `.m-cli.toml` resolves m-stdlib"); short prose orientation.
- `manifest-index.md` — a hand-curated **quick-reference** version
  of the manifest: ~one line per module + one line per public label
  with signature. Optimised for the model's context window — full
  manifest is JSON, this is dense English.
- `patterns.md` — the canonical idioms: how to write a STDASSERT
  suite, how to seed a STDFIX `with` block, how to emit STDLOG
  JSON-line output, how to walk a STDJSON tree. Each pattern in 5–15
  lines of M.
- `error-codes.md` — every `U-STD*` code, what raised it, what to
  do about it. Generated from `dist/errors.json`.

The skill is **regenerated** from the manifest by a script in
`tools/gen-skill.m`; it lives in `~/claude/skills/m-stdlib/` (per
the global filesystem convention) but is built from this repo. CI
fails if the generator output drifts from what's checked in.

### 6.2 `m doc --json` as the AI primary interface

Once §4.1 lands, an AI agent's preferred move for "what does
$$parse^STDJSON do?" becomes `m doc --json STDJSON.parse` rather
than `Read src/STDJSON.m`. The Read costs ~600 lines of context;
the manifest entry costs ~30. This single change changes the
economics of AI-assisted M development.

### 6.3 Examples as AI training data

Every `@example` is a working snippet. The skill at §6.1 should
include the **executed** examples (i.e. `@example` plus the
recorded output where applicable) as the model's pattern library.
This makes the AI generate idiomatic m-stdlib code by default.

### 6.4 What *not* to do for AI

- Do **not** hand-write a "for AI" doc layer separate from the
  human-facing one. Two sources of truth diverge. The human-facing
  manifest is already optimal for AI when it carries the right tags.
- Do **not** preload the AI with the full manifest at session start —
  it's wasteful. Load it on demand via `m doc` or the skill.
- Do **not** rely on the AI scraping `docs/modules/*.md` markdown —
  the manifest is structured; markdown is for humans.

---

## 7. Per-routine vs master index — the design call

The user's question, surfaced explicitly: **per-routine machine-
readable file, or a single master index?**

**Recommendation: master index, primary; per-routine slim view,
optional and deferred.**

| Criterion | Master only | Per-routine only | Both |
|---|---|---|---|
| AI fetch cost | one read | one read per call | one read |
| Editor warm cache | one file | many files | one file |
| Scoped tooling (e.g. "give me one module") | jq filter | direct read | direct read |
| Maintenance cost (drift between files) | low | low | medium |
| Initial implementation cost | low | medium | medium |
| Gives up nothing? | gives up scoped reads | gives up holistic queries | yes |

The master index covers every consumer this plan envisions. Per-
routine slim views are a perf optimisation that buys little until a
specific consumer asks for it. **Defer until asked.**

The exception: **the routine's own header comment** is already a
per-routine doc, and it's the **source** the manifest is generated
from. So in a sense, every routine already ships its own "doc file"
— it's the comment block. That's enough.

---

## 8. Phasing

The work clusters into four waves. Each wave is independently
shippable; later waves depend on earlier ones.

### Wave A — grammar + manifest (m-stdlib repo)

1. Specify the M-doc grammar (§3.1) — write
   `docs/guides/m-doc-grammar.md`.
2. Backfill `@param` / `@returns` / `@raises` / `@example` /
   `@since` / `@stable` tags across **public labels** in src/. Free-
   form prose stays as continuation.
3. Add lint rule `M-DOC-001` (warn-only at first).
4. Implement `tools/gen-manifest.m` → `dist/stdlib-manifest.json`.
5. Add CI gate: regenerate the manifest, fail on diff.
6. Add frontmatter to `docs/modules/*.md` (§3.3).
7. Generate `dist/errors.json` (§3.5).
8. Tag a release; update `docs/modules/index.md` to link the
   manifest.

**Gate.** Wave A is "done" when an external tool can answer "what's
the signature of `$$parse^STDJSON`?" by reading exactly one file.

### Wave B — m-cli `m doc` family

1. `m doc <symbol>` (§4.1).
2. `m doc --json` and `m doc --short`.
3. `m search <query>` (§4.2).
4. `m manifest`, `m examples`, `m errors`.

**Gate.** A maintainer can answer any "what does X do?" question
without opening a file.

### Wave C — VS Code extension

1. Hover + goto-def + completion (§5.1) over the manifest.
2. Snippets for STDASSERT / STDFIX / STDLOG / STDJSON canonical
   patterns.
3. Optional: docs site with search index (§5.2).

**Gate.** A new developer can write m-stdlib-consuming M code in VS
Code without opening `src/STD*.m`.

### Wave D — AI surface

1. Skill at `~/claude/skills/m-stdlib/` (§6.1), generator in
   `tools/gen-skill.m`.
2. Doctests via `tools/gen-doctests.m` (§3.4) — keeps `@example`
   honest, which is what makes the skill trustworthy.

**Gate.** An AI session that mentions m-stdlib loads ~3KB of skill
context and produces idiomatic m-stdlib code on the first attempt.

---

## 9. What does *not* need to change

Worth naming explicitly so the plan doesn't accidentally become a
rewrite:

- **The `; doc:` convention** stays. Tags extend it; prose is still
  legal.
- **The `STD*` prefix and 6-char routine name limit** stay.
- **The `,U-STDxxx-NAME,` error namespace** stays — this is what
  makes §3.5 trivial.
- **The phase-keyed `docs/modules/index.md`** stays — humans
  browsing the catalogue benefit from the historical phase view that
  a flat manifest doesn't carry.
- **Per-module `docs/modules/stdXXX.md`** stays as the
  long-form / human-facing surface (storage diagrams, conformance
  notes, examples with prose). The manifest is not a replacement for
  rich prose — it's the structured backbone underneath.
- **TDD-first, `m test`, STDASSERT** — none of this plan touches the
  testing surface. Doctests in §3.4 emit *more* `*TST.m` routines;
  they don't change how testing works.

---

## 10. Risk and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Tag grammar bikeshedding stalls Wave A | medium | Borrow JSDoc verbatim; the small subset above is non-negotiable; everything else is deferred. |
| Generator drift from hand-written docs | high (without CI gate) | CI re-runs `gen-manifest`, fails on diff (same model as `m fmt`). |
| VS Code extension grows scope into "M LSP" | high | Hard scope: stdlib-only. M LSP tracked as a separate project. |
| Manifest-as-canonical breaks human writers who want to edit markdown | low | Markdown stays primary for prose; manifest is generated from comments, not from markdown. Writers edit `.m` headers + prose md, never the manifest by hand. |
| Backfilling tags across 30+ modules is large | medium | One module per session; no version gate; lint stays warn-only until coverage is high. |
| AI skill drifts from manifest | high (without CI gate) | Skill is generated; CI re-runs `gen-skill`, fails on diff. |

---

## 11. Decisions and deferred questions

Resolved 2026-05-08. Items marked **revisit** are tracked in
`docs/tracking/module-tracker.md` § "Deferred decisions — revisit
triggers" with their trigger conditions.

### 11.1 HTML hosted docs — **deferred**

Decision: do not build `dist/site/` in the §8 phasing. The manifest
enables HTML generation cheaply at any later date, so deferring
costs nothing.

**Revisit when:** a non-maintainer adopts m-stdlib, or a second
human contributor lands a module. Tracker note logged.

### 11.2 `@stable` tier CI gate — annotate now, gate later

The full question: should CI fail when a label marked `@stable` is
removed or has its signature changed outside a major-version bump?

**Two pieces, separable:**

| Piece | Cost | Value | Recommendation |
|---|---|---|---|
| `@stable` **annotation** in the manifest | trivial (one tag in the doc-comment grammar) | useful signal in `m doc`, in `docs/modules/*.md` badges, and as input to a future gate | **keep — ships with Wave A** |
| **CI gate** that diffs manifest-at-HEAD against manifest-at-last-tag and fails on `stable` regressions | moderate (a script + a tag-anchor convention; plus the discipline of deprecation cycles for every change) | enforces SemVer at the API surface, not just the version string | **defer** |

**Impact when on:**
- *Positive.* Makes "stable means stable" a property the build
  system enforces rather than a convention that drifts. Catches
  accidental signature changes the moment they land. Forces the
  deprecate-then-remove discipline (`@deprecated since v0.X` →
  removed in v(X+1).0) instead of silent breakage. Protects every
  downstream consumer from regressions discovered only via their
  own test failures.
- *Negative.* Slows iteration when it's still cheap to iterate. At
  v0.4.0, with m-cli as effectively the only consumer and both
  projects in the same hands, every breaking change is already
  reviewed by the same person who'd add the `@deprecated` —
  there's no third party to protect. The gate would mostly add
  ceremony to changes the maintainer is already making
  intentionally. Also requires every public label to carry an
  accurate `@stable` value, so backfill cost compounds with the
  Wave A doc-tag backfill.

**Importance — depends on stage:**

| Stage | Importance | Why |
|---|---|---|
| Pre-1.0, single maintainer, m-cli is the only consumer | **low** | Coordination by hand is cheap; gate is mostly ceremony. |
| Approaching 1.0 | **high** | 1.0 is the promise "we won't break it"; the gate is what makes that promise auditable. Without the gate, 1.0 is a marketing label. |
| Post-1.0 with non-maintainer consumers | **critical** | The gate is the only thing standing between an accidental signature change and a downstream incident. |

**Decision.** Ship the **annotation** in Wave A (every public label
gets `@stable` = `experimental` / `stable` / `deprecated`). **Defer
the CI gate** until 1.0 is planned or a non-maintainer consumer
adopts m-stdlib, whichever comes first. The annotation is
self-justifying as documentation; turning on the gate later is a
one-script delta with no schema migration.

### 11.3 Manifest distribution to consumers — **runtime read**

Decision: m-cli (and any other consumer) reads
`dist/stdlib-manifest.json` from the resolved m-stdlib install at
runtime. No vendored copy in m-cli; no build-time import.

**Why this is the simplest option with the least baggage:**
- One source of truth. Vendoring means two; the moment they drift,
  `m doc` lies.
- No version-pinning ceremony in m-cli. The manifest version
  matches whatever m-stdlib version the project resolves — the
  same resolution `.m-cli.toml` already does for `m fmt` / `m lint`
  / `m test`.
- No new "import" mechanism. The file lives at a known path under
  the installed routine directory; m-cli reads it like any other
  asset.
- Latency is fine. The manifest is a single JSON; loading + jq-style
  filter is microseconds. Caching is unnecessary.

**Revisit only if:** `m doc` cold-start latency becomes user-visible
(unlikely at any plausible manifest size — even a 10× growth in
modules is well under 1 MB). No tracker note needed; the trigger is
self-evident.

### 11.4 Manifest generator — hand parser, then re-evaluate

Decision: implement `tools/gen-manifest.m` as a hand-rolled M parser
(~150 LoC) for Wave A. Do **not** wait on tree-sitter-m.

**Why hand parser first:**
- Ships now. tree-sitter-m's API is moving; binding to it today
  means rewriting twice.
- Scope is tiny. The generator only needs to recognise the
  routine-line, label-line, the `; doc:` block grammar, and the
  formal-list parens. Everything else is comments and
  pass-through.
- Failure mode is benign. A parser bug produces a wrong manifest
  entry, caught by the CI gate that compares regenerated output
  against the committed file.

**Revisit when:** tree-sitter-m hits a stable v1, OR the hand
parser starts needing language features beyond labels and doc
comments (e.g. cross-module type inference, dead-code detection).
Tracker note logged.

---

## 12. Cross-references

- [`README.md`](../../README.md) — top-level project overview, phase
  plan, module inventory.
- [`CHANGELOG.md`](../../CHANGELOG.md) — release history; the
  manifest's `since:` fields must match.
- [`docs/modules/index.md`](../modules/index.md) — phase-keyed
  catalogue; will gain a "manifest" link in Wave A.
- [`docs/plans/m-stdlib-implementation-plan.md`](m-stdlib-implementation-plan.md)
  — the live build plan (modules and phases). This plan runs in
  parallel.
- [`docs/guides/m-tdd-guide.md`](../guides/m-tdd-guide.md) — TDD
  workflow; doctests in §3.4 land additional `*TST.m` routines into
  the same workflow.
- [`docs/tracking/module-tracker.md`](../tracking/module-tracker.md)
  — the work board; manifest stability tier (§3.6) feeds promotion
  decisions on this board.
