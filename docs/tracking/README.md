---
title: m-stdlib — tracking conventions
status: live (2026-05-10)
authority: this file defines the doc model for everything under docs/tracking/.
  Every tracker, the discoveries register, the changelog, and the TODO pointer
  follow the conventions documented here.
audience: anyone landing or proposing work in m-stdlib, or coordinating
  cross-project work that surfaces m-stdlib changes.
companions: docs/plans/ (forward-looking specs that get locked before
  implementation starts).
---

# m-stdlib — tracking conventions

All change-tracking for m-stdlib lives under `docs/tracking/`. This
README defines the model so contributors land in the right file by
default and so future restructures don't reintroduce the
"two trackers each claiming authority" problem.

The model is a clean separation into **four buckets**:

| Bucket | Lives in | Purpose |
|--------|----------|---------|
| **Planning** | [`../plans/`](../plans/) | Forward-looking specs. Get *locked* before implementation starts. |
| **Implementation** | [`<name>-tracker.md`](.) | Live work boards. One tracker per locked plan. Tabular at top, per-task narrative below. |
| **Discoveries** | [`discoveries.md`](discoveries.md) | Issues that weren't anticipated in the plan but had to be addressed during implementation. Single flat table; severity-ranked; cites which task it changed. |
| **Tracking** | [`changelog.md`](changelog.md) + [`TODO.md`](TODO.md) | Release history (one entry per tag, *thin* — pointers into trackers, no re-narration) and "resume here" pointer. |

The rest of this document defines each bucket precisely.

## Bucket 1 — Planning (`../plans/`)

### Lifecycle

A plan moves through three named states tracked in its frontmatter:

| State | Meaning | What you do |
|-------|---------|-------------|
| `proposal` | Drafting. Scope, deliverables, acceptance criteria still moving. | Iterate freely on the plan body. No tracker yet. |
| `locked` (date) | Decisions fixed. Implementation can begin. | Stop editing the plan body. Open `<name>-tracker.md`. From this point on, the plan is **read-only except for `## Plan changes from discoveries`** (a dedicated section appended at lock time). |
| `realized` (tag) | Tracker is closed; release ships. | The tracker proves the plan was executed. Plan stays in `../plans/` if it's still load-bearing reference; moves to `../plans/_archive/` if not. |

### Why "locked" matters

The lock is the contract. Once locked, the plan body answers
"what we believed when we started," not "what's true today." Anything
that *changes* the plan after lock follows this protocol:

1. The change-causing surprise lands in [`discoveries.md`](discoveries.md) as a new row with a populated `Plan impact` column.
2. The plan's `## Plan changes from discoveries` section gains one bullet that links to the discovery row and names the affected task ID.
3. The tracker task acceptance / approach updates to reflect the change; the change is also noted in that task's `Progress log`.

This three-step protocol lets a future reader see (a) what was
originally planned, (b) what we learned during impl, and (c) how the
two reconciled — without rewriting any of the three sources.

### Plan frontmatter (recommended)

```yaml
---
title: <plan name>
status: proposal | locked | realized
locked: 2026-04-30                # date scope was frozen — present iff status ≥ locked
realized: v0.5.0                  # release tag that closed the plan — present iff status = realized
tracker: docs/tracking/<name>-tracker.md
---
```

## Bucket 2 — Implementation tracker (`<name>-tracker.md`)

One tracker per locked plan. Lives in `docs/tracking/`. The shape is
fixed:

```markdown
---
title: <plan name> — implementation tracker
plan: docs/plans/<name>-plan.md
status: in-progress | done
last-touched: 2026-05-10
authority: canonical "what's done / in flight" for the <plan> work program.
  Any commit touching a tracked task MUST update the relevant row(s) here in
  the same commit.
---

# <plan name> — implementation tracker

## Summary table

| Done | ID  | Status      | Title                | Deps  | Acceptance | Commit |
|:----:|-----|-------------|----------------------|-------|------------|--------|
| [x]  | T1  | done        | …                    | —     | …          | abc123 |
| [ ]  | T2  | in-progress | …                    | T1    | …          | —      |
| [ ]  | T3  | blocked     | …                    | T2    | …          | —      |

## Discoveries that changed the plan

Bullet list of pointers to [`discoveries.md`](discoveries.md) rows that caused
scope shifts in this plan, each annotated with the task ID(s) it changed.
Don't repeat the discovery body here — that lives in discoveries.md.

## Per-task narratives

### T1 — <title>

**Status.** done (2026-05-08; commit `abc123`).
**Goal.** One paragraph from the plan section.
**Approach.** Bullets — how the work was attacked.
**Acceptance.** Same string as the table cell, expanded if useful.
**Out of scope.** Anything deliberately not done here.
**Progress log.**
- 2026-05-08 — landed; <commit> ships <surface>; …

### T2 — <title>
…
```

### Status vocabulary

Use this set, not synonyms:
`not-started` · `in-progress` · `blocked` · `done` · `deferred`.

`deferred` rows live at the bottom of the summary table or in a
separate **Deferred / out of scope** subsection so they don't clutter
the active view.

### Process rule

Any commit that touches a module's source, tests, or per-module doc
**MUST update the relevant row(s) in Section 1 (Summary table) in the
same commit**. Add a row to **Section 3 (Per-task narratives)** when
TDD-red is staked. Demote nothing — completed rows stay in the table
forever as the historical record.

### Closing a tracker

When status reaches `done`:

1. Update frontmatter `status: done` + add `realized: <tag>`.
2. Move the file to `_archive/<name>-tracker.md` only if no contributor
   is still consulting it as reference. Otherwise leave in place.
3. Update [`TODO.md`](TODO.md) so the active-tracker pointer doesn't
   include it.

## Bucket 3 — Discoveries register ([`discoveries.md`](discoveries.md))

A single flat table covering every issue that wasn't anticipated in
a locked plan but had to be addressed during implementation. Both
**internal** discoveries (m-stdlib design pivots — the ZGOTO unwind
fix, STDFIX one-shot wrappers, STDJSON merge-then-pass) and
**external** discoveries (toolchain bugs in m-cli / tree-sitter-m /
YDB) live in the same register, distinguished by the `Subject` column.

### Schema

| Column | Meaning |
|--------|---------|
| Date | Surface date (YYYY-MM-DD). |
| Severity | `P0` · `P1` · `P2` · `P3` · `docs`. P0/P1 are gating; `docs` is "documented design constraint, not a defect." |
| Subject | Where the discovery sits. `m-stdlib` (internal), `m-cli`, `tree-sitter-m`, `m-standard`, `YottaDB`, `vista-meta`, or a slash-pair if both. |
| Area | Concrete locus — module, file, label, flag, lint rule ID. Whatever helps a reader find the relevant code. |
| Finding | What surprised us. Reproduce-able shape preferred over abstract description. |
| Plan impact | What the implementation did (or will do) about it. Link to the affected tracker row(s) by ID. **Required column.** |
| Status | `open` · `resolved` (with date) · `documented` (for `docs`-severity rows that don't need a fix). |

### What goes here

A row should land in `discoveries.md` if **all three** are true:

- It wasn't called out in the locked plan.
- It changed the implementation in a non-trivial way (acceptance, scope, design, workaround).
- Future contributors would benefit from knowing about it.

Don't put routine work-log items here — those go in the tracker's
per-task `Progress log`. The discovery register is for the things
the plan *got wrong* (or didn't see coming).

### What does NOT go here

- Trivial bugs found and fixed inside a single task (record in the task progress log).
- Tasks that were anticipated but harder than expected (record in the task progress log).
- Cross-project feature requests with no current m-stdlib impact (those are upstream issues).

## Bucket 4 — Tracking surfaces

### `changelog.md` — thin release history

One entry per tagged release. **Each entry is a paragraph + bullet
list of pointers**, not a re-narration of the trackers. Format:

```markdown
## [v0.5.0] — 2026-05-08

**Headline.** Discoverability & tooling Wave A.

- WA1, WA4–WA8 closed → [`discoverability-tracker.md` § Wave A](discoverability-tracker.md#wave-a--m-stdlib-grammar--manifest)
- Discoveries that shaped this release:
  [`discoveries.md` 2026-05-06 `.x(SUBS)`](discoveries.md#2026-05-06),
  [`discoveries.md` 2026-05-07 `$ZF` mangling](discoveries.md#2026-05-07)
- Tag: `v0.5.0`. Compare: `v0.4.0..v0.5.0`.
```

If the changelog entry needs more than ~10 bullet pointers, the
narrative belongs in the tracker, not here.

### `TODO.md` — resume-here pointer

Names the active tracker(s), the next 1–3 actionable items, and links
into the canonical board. **Doesn't store state itself.** If a TODO
entry lives here for more than a session or two, it belongs in a
tracker.

## File-by-file index

| File | Role | When to write here |
|------|------|--------------------|
| [`README.md`](README.md) | This file. The doc model. | Updates only when the doc model itself changes. |
| [`module-tracker.md`](module-tracker.md) | Master per-module tracker — Summary table (Done checkbox + module rows) + closed-tickets archaeology (T1–T30) + Must-know section. Per-module deep history lives in [`../modules/<m>.md` § History](../modules/); proposals live in [`../plans/future-modules-plan.md`](../plans/future-modules-plan.md). | Every commit that lands or moves a module-level task. |
| [`discoverability-tracker.md`](discoverability-tracker.md) | Wave A–D implementation tracker for the discoverability & tooling plan. Tabular summary + per-task narrative; matches the Bucket 2 template. | Every commit that lands a Wave task. |
| [`parallel-tracks.md`](parallel-tracks.md) | Dispatch view across L1–L27 / H1–H3 / m-cli companion C-tracks. Derived index, not a primary tracker. | When a track changes status; when a new track lands. |
| [`discoveries.md`](discoveries.md) | Discoveries register (Bucket 3). | When a discovery surfaces and the criteria above are met. |
| [`changelog.md`](changelog.md) | Release history (Bucket 4). | At every tag cut. |
| [`TODO.md`](TODO.md) | Resume-here pointer (Bucket 4). | At session boundaries; never as state storage. |

## Anti-patterns to avoid

- **Two trackers each claiming authority for overlapping scopes.** One tracker per locked plan. Cross-cutting work goes in the most-relevant tracker; cross-references handle the overlap.
- **Re-narrating tracker content in the changelog.** The changelog cites; the tracker tells. Don't duplicate.
- **Editing a locked plan body.** Plans are read-only after lock except for the explicit `## Plan changes from discoveries` section.
- **Hiding discoveries inside tracker progress logs.** A genuine discovery (something the plan didn't anticipate) earns a row in `discoveries.md`. Future readers shouldn't have to grep tracker progress-log narratives to retrieve them.
- **Letting `TODO.md` accumulate state.** TODO is a pointer, not a database. If something's been there more than a session, it goes into a tracker.

## Cross-references

- [`../plans/`](../plans/) — the planning bucket.
- [`../guides/users-guide.md`](../guides/users-guide.md) — user-facing reference; mirrors `../README.md` § narrative.
- [`../modules/index.md`](../modules/index.md) — canonical module inventory.
- [`../../README.md`](../../README.md) — public-facing overview.
- [`../../CLAUDE.md`](../../CLAUDE.md) — Claude project context; cites this file for the tracking convention.
