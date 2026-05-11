---
created: 2026-05-11
last_modified: 2026-05-11
revisions: 0
doc_type: [REFERENCE]
---

# m-stdlib — Documentation Index

> First-pass index generated 2026-05-11. Labels follow the shared vocabulary below; the same vocabulary is used across all m-dev-tools repos.

## Vocabulary

Each doc is labeled `[TYPE · type? · connection · connection?]`.

**Types** — `HISTORY` · `ARCHITECTURE` · `DESIGN` · `ADR` · `SPEC` · `REFERENCE` · `GUIDE` · `TUTORIAL` · `ROADMAP` · `PLAN` · `RESEARCH` · `SURVEY` · `GAP-ANALYSIS` · `STATUS` · `EXPLAINER` · `NOTES` · `WORKED-EXAMPLE` · `SETUP` · `INTEGRATION` · `PROPOSAL` · `BUILD-LOG` · `CHANGELOG` · `POSTMORTEM`

**Repo connections** — `history` · `function` · `design` · `architecture` · `planning` · `implementation`

## `guides/` — User and contributor how-to docs

- **`guides/m-doc-grammar.md`** — `[SPEC · function]` Normative grammar for the structured `; doc:` tags that drive the manifest, per-module markdown, and downstream tooling.
- **`guides/m-tdd-guide.md`** — `[GUIDE · function]` Operational TDD guide covering the m-stdlib primitives, the `m test` runner, and the inner-loop / release-gate commands.
- **`guides/users-guide.md`** — `[GUIDE · function]` Deep user reference for m-stdlib — purpose, non-goals, acceptance gate, and per-module usage notes.

## `modules/` — Per-module reference docs

- **`modules/index.md`** — `[REFERENCE · architecture · function]` Canonical released-module catalogue, organised by phase, with cross-module runtime dependencies and conformance corpora.
- **`modules/stdargs.md`** — `[REFERENCE · function]` Reference for the STDARGS module — argparse with long/short/grouped flags, positionals, sub-commands, and `--` terminator.
- **`modules/stdassert.md`** — `[REFERENCE · function]` Reference for the STDASSERT module — assertion library with nine extrinsics and `^TESTRUN`-compatible output protocol.
- **`modules/stdb64.md`** — `[REFERENCE · function]` Reference for the STDB64 module — RFC-4648 Base64 with standard and URL-safe alphabets.
- **`modules/stdcache.md`** — `[REFERENCE · function]` Reference for the STDCACHE module — LRU + TTL cache over a caller-owned array.
- **`modules/stdcoll.md`** — `[REFERENCE · function]` Reference for the STDCOLL module — Set / Map / Stack / Queue / Deque / Heap / OrderedDict collections.
- **`modules/stdcompress.md`** — `[REFERENCE · function]` Reference for the STDCOMPRESS module — gzip / deflate / zstd compress and decompress via libz + libzstd callouts.
- **`modules/stdcrypto.md`** — `[REFERENCE · function]` Reference for the STDCRYPTO module — SHA-256/384/512 and HMAC-SHA-256/384/512 via libcrypto callouts.
- **`modules/stdcsprng.md`** — `[REFERENCE · function]` Reference for the STDCSPRNG module — crypto random bytes / hex / base64 / token / int / uuid4 over the kernel CSPRNG.
- **`modules/stdcsv.md`** — `[REFERENCE · function]` Reference for the STDCSV module — RFC-4180 CSV parser and writer with optional file I/O.
- **`modules/stddate.md`** — `[REFERENCE · function]` Reference for the STDDATE module — ISO-8601 datetime and duration arithmetic over the proleptic Gregorian calendar.
- **`modules/stdenv.md`** — `[REFERENCE · function]` Reference for the STDENV module — `.env` loader plus typed accessors (`getInt` / `getBool` / `getFloat`).
- **`modules/stdfix.md`** — `[REFERENCE · function]` Reference for the STDFIX module — fixture lifecycle with `with` / `invoke` one-shot transactional scopes.
- **`modules/stdfmt.md`** — `[REFERENCE · function]` Reference for the STDFMT module — printf-style formatter, subset of Python `str.format` syntax.
- **`modules/stdfs.md`** — `[REFERENCE · function]` Reference for the STDFS module — file-system primitives plus byte-faithful I/O via libc callouts.
- **`modules/stdhex.md`** — `[REFERENCE · function]` Reference for the STDHEX module — RFC-4648 §8 hex encoding with lowercase default and case-insensitive decode.
- **`modules/stdhttp.md`** — `[REFERENCE · function]` Reference for the STDHTTP module — HTTP/1.1 client with pure-M wire-format helpers and libcurl-backed verbs.
- **`modules/stdjson.md`** — `[REFERENCE · function]` Reference for the STDJSON module — RFC 8259 JSON parser and serialiser with one M-tree node per JSON value.
- **`modules/stdlog.md`** — `[REFERENCE · function]` Reference for the STDLOG module — structured `key=value` logger with five levels and four sinks.
- **`modules/stdmath.md`** — `[REFERENCE · function]` Reference for the STDMATH module — numeric helpers (clamp / min / max / sum / count / mean) over caller-owned arrays.
- **`modules/stdmock.md`** — `[REFERENCE · function]` Reference for the STDMOCK module — test-time call interception with `register` / `invoke` / `resolve` / `called` / `args`.
- **`modules/stdos.md`** — `[REFERENCE · function]` Reference for the STDOS module — process / env / cmdline helpers (env / pid / cmdline / argv / cwd / user / hostname).
- **`modules/stdprof.md`** — `[REFERENCE · function]` Reference for the STDPROF module — wall-clock profiler with `$ZHOROLOG`-microsecond resolution.
- **`modules/stdregex.md`** — `[REFERENCE · function]` Reference for the STDREGEX module — Thompson-NFA regex engine with literals, classes, groups, alternation, and greedy quantifiers.
- **`modules/stdseed.md`** — `[REFERENCE · function]` Reference for the STDSEED module — declarative TSV / JSON manifest loader for FileMan record fixtures.
- **`modules/stdsemver.md`** — `[REFERENCE · function]` Reference for the STDSEMVER module — SemVer 2.0.0 validate / parse / compare / match with range syntax.
- **`modules/stdsnap.md`** — `[REFERENCE · function]` Reference for the STDSNAP module — snapshot testing with canonical line-per-leaf dump via `$QUERY` walk.
- **`modules/stdstr.md`** — `[REFERENCE · function]` Reference for the STDSTR module — ASCII string helpers (pad / trim / replaceAll / split / startsWith / endsWith).
- **`modules/stdtoml.md`** — `[REFERENCE · function]` Reference for the STDTOML module — TOML 1.0 subset with top-level pairs, `[section]` tables, and scalar values.
- **`modules/stdurl.md`** — `[REFERENCE · function]` Reference for the STDURL module — RFC 3986 URI parse / build / encode / decode / valid / normalize / resolve.
- **`modules/stduuid.md`** — `[REFERENCE · function]` Reference for the STDUUID module — RFC-4122 v4 and RFC-9562 v7 UUID generation.
- **`modules/stdxfrm.md`** — `[REFERENCE · function]` Reference for the STDXFRM module — higher-order array transforms (map / filter / reduce) via XECUTE-evaluated lambdas.
- **`modules/stdxml.md`** — `[REFERENCE · function]` Reference for the STDXML module — XML 1.0 parser plus XPath 1.0 subset with namespaces, predicates, and functions.

## `plans/` — Implementation and roadmap plans

- **`plans/discoverability-and-tooling-plan.md`** — `[PLAN · planning]` Phased plan to turn m-stdlib into a first-class discoverable surface across the source, CLI, VS Code, and AI consumption channels.
- **`plans/future-modules-plan.md`** — `[PROPOSAL · planning]` Parking lot for module candidates that haven't crossed TDD-red yet, with priority and promotion process.
- **`plans/m-libraries-remediation.md`** — `[ROADMAP · planning · design]` Background remediation strategy and prioritised roadmap derived from the M libraries survey — decisions locked.
- **`plans/m-stdlib-implementation-plan.md`** — `[PLAN · planning · implementation]` Live per-module work plan with phase status, non-negotiables, and per-module specs for v0.0.1 through v0.4.0.
- **`plans/tdd-orchestration-plan.md`** — `[PLAN · planning · architecture]` Cross-project coordination plan sequencing m-stdlib TDD primitives against the matching m-cli capability work.

## `testing/` — Validation results across real-world corpora

- **`testing/modern-m-corpus-test-results.md`** — `[RESEARCH · GAP-ANALYSIS · function]` Findings from running m-stdlib against five active non-VistA OSS M projects, focused on library-fit substitution opportunities.
- **`testing/realcode-validation.md`** — `[RESEARCH · function]` Toolchain-side validation of m-stdlib against the m-modern-corpus snapshot — collision sweep and lint-pass matrix.
- **`testing/vista-corpus-lint-results.md`** — `[RESEARCH · function]` Lint-pass results from running m-cli's rule profiles against the 39,375-routine VistA corpus.

## `tracking/` — Live trackers for in-flight work

- **`tracking/README.md`** — `[REFERENCE · architecture · planning]` Existing index for the tracking/ subdir — defines the four-bucket doc model (planning / implementation / discoveries / tracking).
- **`tracking/changelog.md`** — `[CHANGELOG · history]` Keep-a-Changelog release history; one entry per tag with thin pointers into trackers and per-module History sections.
- **`tracking/discoverability-tracker.md`** — `[STATUS · implementation · planning]` Wave A–D implementation tracker for the discoverability and tooling plan, with tabular summary and per-task narrative.
- **`tracking/discoveries.md`** — `[NOTES · history · implementation]` Discoveries register — every issue not anticipated in a locked plan but addressed during implementation, internal and external.
- **`tracking/module-tracker.md`** — `[STATUS · implementation]` Master per-module tracker — Summary table, closed-tickets archaeology (T1–T30), and Must-know section.
- **`tracking/parallel-tracks.md`** — `[STATUS · architecture · implementation]` Dispatch view across L1–L27 / H1–H3 / m-cli companion C-tracks with the cross-module dependency map.
- **`tracking/TODO.md`** — `[STATUS · implementation]` Resume-here pointer — thin index over the trackers with current release status and live work board.
