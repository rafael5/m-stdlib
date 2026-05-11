---
created: 2026-04-30
last_modified: 2026-05-10
revisions: 38
doc_type: [CHANGELOG]
---

# Changelog

All notable changes to m-stdlib are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the project
adheres to [Semantic Versioning](https://semver.org/). Pre-1.0 minor
versions may include breaking changes.

**Reading model.** Each entry below is a thin index — a one-paragraph
headline plus bullet pointers into the canonical sources (tracker
tickets, per-module History sections, discoveries register). The
deep implementation narrative lives in those sources, not duplicated
here. See [`README.md`](README.md) § Bucket 4 for the rationale.

## [v0.5.0] — 2026-05-08

**Discoverability & tooling — Wave A.** First wave of the
[discoverability and tooling plan](../plans/discoverability-and-tooling-plan.md):
structured-tag grammar, machine-readable manifest, CI manifest-drift
gate. Doc + tooling only — no `src/STD*.m` runtime behaviour change.

- **Closed Wave A tasks:** WA1 (M-doc tag grammar), WA4 (manifest generator), WA5 (CI manifest-drift gate), WA6 (frontmatter on all 32 module docs), WA7 (`dist/errors.json`), WA8 (this release tag) — see [`discoverability-tracker.md` § Wave A](discoverability-tracker.md#wave-a--m-stdlib-grammar--manifest).
- **New machine-readable surface:** [`dist/stdlib-manifest.json`](../../dist/stdlib-manifest.json) (every public module + label with signature, source line, tag-derived fields), `dist/errors.json` (inverted `U-STD*` → producing-module index), YAML frontmatter on every `docs/modules/std*.md`.
- **Cross-cutting follow-ons (deferred):** WA2 (src/ tag backfill), WA3 (`M-DOC-001` lint rule in m-cli) — both unblock Wave B (m-cli `m doc` family) once landed.
- Tag: `v0.5.0`. Compare: `v0.4.0..v0.5.0`.

## [v0.4.0] — 2026-05-08

**Phase 3 close + STDXML full envelope + STDFS byte-faithful I/O +
deployment automation.** All three Phase 3 callout modules engine-
green; STDXML reaches ~100% of its 12-16d envelope; STDFS gains
libc-backed byte-faithful arms. Aggregate gate at this tag:
**32 suites, 2483/2483 assertions green on engine, 0E lint, fmt
clean.**

- **Phase 3 modules engine-green** — [STDCRYPTO](../modules/stdcrypto.md) H1 (23/23, T28 closed), [STDCOMPRESS](../modules/stdcompress.md) H2 (59/59, T28 + T30 closed), [STDHTTP](../modules/stdhttp.md) H3 (68/68, T29 closed). Per-module deployment narratives in each module's § History.
- **STDXML reaches feature-complete v1** — [T26 (DTDs / DOCTYPE / `<!ENTITY>`)](module-tracker.md#t23-t27--stdxml-deferred-features) + T27a (XPath wildcards + attribute axis) + T27b (XPath functions + comparison predicates). [`stdxml.md` § History](../modules/stdxml.md) walks all eight T-ticket landings.
- **STDFS byte-faithful I/O** — T13 + T14 closed; new `writeBytes` / `appendBytes` / `readBytes` / `available` extrinsics over libc. [`stdfs.md` § History](../modules/stdfs.md).
- **STDCSPRNG getrandom(2) callout** — T12 closed; pure-M `/dev/urandom` fallback unchanged. [`stdcsprng.md` § History](../modules/stdcsprng.md).
- **Two more P4 promotions** — STDMATH (L26) and STDXFRM (L27) — see [`stdxfrm.md` § History](../modules/stdxfrm.md) for the `@expr` → XECUTE migration that landed this release.
- **Deployment harness** — `scripts/seed-callouts.sh` (T28 + T29 close): build inside container, stage `.so` + `.xc`, idempotently inject `STDLIB_LIB` + `ydb_xc_<pkg>` into `/etc/profile.d/ydb_env.sh`. Used by all four callout modules.
- **Discoveries that shaped this release:** [`discoveries.md` 2026-05-07](discoveries.md) `$ZF` mangling (`m fmt` rewrites `$ZF` → `$zfind`); `$&pkg.fn` ABI prepends `int argc` on every C entry; YDB r2.02 caps M-strings at 1 MiB.
- Tag: `v0.4.0`. Compare: `v0.3.0..v0.4.0`.

## [v0.3.0] — 2026-05-07

**Phase-2 close + P4 module wave + bug-fix sweep.** Eleven new pure-M
modules promoted out of the proposal pipeline (see
[`future-modules-plan.md` § Promoted out](../plans/future-modules-plan.md));
three m-cli companion tracks bind the new modules into `m test`. New
lint rule `M-MOD-037` catches the YDB `.x(SUBS)` syntax limit at lint
time. Aggregate stable-suite gate: **16 suites, 1230+ assertions, 0E
lint, fmt clean.**

- **P4 promotions (L15–L25)** — STDCSPRNG, STDFS, STDOS, STDSEMVER, STDSTR, STDTOML, STDCACHE, STDPROF, STDSNAP, STDENV, STDXML v0+T23+T24+T25+T25b. Per-module narratives in each module's § History (e.g. [`stdfs.md`](../modules/stdfs.md), [`stdcsprng.md`](../modules/stdcsprng.md), [`stdxml.md`](../modules/stdxml.md)).
- **m-cli companion tracks** — C6 (`m test --timings` consuming STDPROF), C7 (`--update-snapshots` consuming STDSNAP), C8 (`--env PATH` consuming STDENV). Short-code reference in [`module-tracker.md` § m-cli integration short codes](module-tracker.md#m-cli-integration-short-codes).
- **STDXML closes T23 + T24 + T25 + T25b** during this cycle; T26/T27 close in v0.4.0. See [`stdxml.md` § History](../modules/stdxml.md).
- **New lint rule** — `M-MOD-037` (in m-cli) flags `.x(SUBS)` calls at lint time, anchored to [`discoveries.md` 2026-05-06](discoveries.md) `.x(SUBS)` syntax.
- Tag: `v0.3.0`. Compare: `v0.2.0..v0.3.0`.

## [v0.2.0] — 2026-05-07

**Phase 2 release.** Four pure-M heavy-lift modules complete the
Phase-2 set: STDJSON, STDREGEX, STDCOLL, STDURL. Two add-ons land on
the same tag boundary: STDLOG `FORMAT(kv|json)` and STDSEED
`loadJson`. Phase 1b TDD primitives (STDFIX, STDMOCK, STDSEED) rolled
into this release as their `v0.1.x` minor tags were never cut.
Aggregate gate: 800+ assertions across 16 suites, 0 lint errors,
per-module label coverage ≥ 95%.

- **Phase 2 core** — STDJSON (L11), STDREGEX (L12), STDCOLL (L13), STDURL (L14). Per-module reference in [`docs/modules/`](../modules/).
- **Add-ons** — STDLOG `FORMAT(kv|json)` (L4 add-on) and STDSEED `loadJson` (L10 add-on); both unblocked by STDJSON in this release.
- **Phase 1b folded in** — STDFIX (L8), STDMOCK (L9), STDSEED (L10).
- **Auxiliary tracks A3/A4/A5/A6** — JSON conformance corpus, RFC-4122/9562 UUID vectors, IRIS portability CI job, `tools/build-callouts.sh` Phase 3 prereq.
- **Discoveries that shaped this release:**
  - [`discoveries.md` 2026-05-05 P1](discoveries.md) STDASSERT.raises ZGOTO unwind — fixed `$ETRAP` arg-less `quit` cascade in extrinsic chains; unblocks T2 (STDFMT/STDDATE/STDCSV raises tests) and partial T3 (STDLOG-JSON).
  - [`discoveries.md` 2026-05-06 docs](discoveries.md) `.x(SUBS)` syntax limit — STDJSON encode/parse refactored to merge-then-pass; T6 closed.
  - [`discoveries.md` 2026-05-05 P2](discoveries.md) `$ETRAP`+TROLLBACK propagation — STDFIX restructured to one-shot `with`/`invoke`.
  - See [`stdregex.md` § History](../modules/stdregex.md) for the `raise()`-helper pattern (commit `3abf7e8`) back-ported to STDFMT/STDARGS in `8c0b419`.
- **Closed tickets:** T1, T2, T3, T6, T7, T9, T10. Cross-references in [`module-tracker.md` § Closed tickets](module-tracker.md#closed-tickets--archaeology).
- Tag: `v0.2.0`. Compare: `v0.1.0..v0.2.0`.

## [v0.1.0] — 2026-05-05

**Phase 1 release.** Seven new pure-M modules ship across tags
`v0.0.2`–`v0.0.7`, completing the Phase-1 set planned in §8 of the
implementation plan. With `v0.0.1` (`STDASSERT` + `STDUUID`),
m-stdlib at `v0.1.0` provides nine modules: assertions, UUIDs,
base64 + hex, printf-style formatting, structured logging, ISO-8601
datetime, RFC-4180 CSV, argparse.

- **Phase 1 modules (L1–L7, L4b folded)** — [STDB64](../modules/stdb64.md) (L1), [STDHEX](../modules/stdhex.md) (L2), [STDFMT](../modules/stdfmt.md) (L3), [STDLOG](../modules/stdlog.md) (L4 + L4b folded — STDDATE landed first so the inline-ts interim was never cut; see [`stdlog.md` § History](../modules/stdlog.md)), [STDDATE](../modules/stddate.md) (L5), [STDCSV](../modules/stdcsv.md) (L6), [STDARGS](../modules/stdargs.md) (L7).
- **Conformance corpora** — `tests/conformance/b64/` (RFC-4648 §10), `tests/conformance/csv/` (RFC-4180 §2 + excel-quirks + UTF-8 BOM); `{json,uuid}/` reserved for Phase 2.
- **Per-module gate (§9):** 527/527 assertions across 9 suites, 0E lint, ≥95% label coverage per module (most at 100%), fmt clean. STDLOG inline-timestamp helper removed in favour of `$$now^STDDATE()`.
- **Deferred:** error-path `raises` tests for STDFMT and STDDATE — blocked on the STDASSERT.raises P1 documented in [`discoveries.md` 2026-05-05](discoveries.md). Closed in v0.2.0.
- Tag: `v0.1.0`. Compare: `v0.0.1..v0.1.0`.

### Per-tag history

| Tag | Date | Commit | Modules added |
|---|---|---|---|
| `v0.0.2` | 2026-05-05 | `83e11b2` | STDB64 (RFC-4648 std + URL-safe), STDHEX (RFC-4648 §8) |
| `v0.0.3` | 2026-05-05 | `8e6b689` | STDFMT (printf-style; subset of Python `str.format`) |
| `v0.0.4` | 2026-05-05 | `abfa9a2` | STDLOG (kv logger; L4b folded — uses `$$now^STDDATE()`) |
| `v0.0.5` | 2026-05-05 | `1ec3b00` | STDDATE (ISO-8601 datetime + duration arithmetic) |
| `v0.0.6` | 2026-05-05 | `0f7de40` | STDCSV (RFC-4180 parser/writer + file I/O) |
| `v0.0.7` | 2026-05-05 | `c98d5a1` | STDARGS (argparse: long/short/grouped/positional/`--`) |

## [v0.0.1] — 2026-04-30

**Bootstrap release.** STDASSERT + STDUUID — the assertion library
that anchors every subsequent test suite, plus the first
non-`STDASSERT` module to validate the per-module §9 acceptance gate
end-to-end.

- **[`STDASSERT`](../modules/stdassert.md)** — assertion library; output protocol mirrors `^TESTRUN` byte-for-byte so m-cli's `m test` runner accepts STDASSERT-driven suites unchanged. Internal `pass`/`fail` helpers renamed to `recordPass`/`recordFail` to dissolve the M-MOD-020 label/formal name-shadow warning ([`discoveries.md` 2026-04-30 P3](discoveries.md)).
- **[`STDUUID`](../modules/stduuid.md)** — RFC-4122 v4 + RFC-9562 v7 UUIDs.
- **`tools/init-db.sh` bumped to `KEY_SIZE=1019` + `BLOCK_SIZE=4096`** so YDB's `view "TRACE"` can capture deep `FOR_LOOP/*CHILDREN` subscripts without `%YDB-E-GVSUBOFLOW` ([`discoveries.md` 2026-04-30 P2](discoveries.md)).
- **Per-module gate (§9):** 166/166 assertions across 2 suites, 22/22 labels (100%), 0E lint, fmt clean. IRIS portability fail-soft (CI re-add deferred to v0.0.4).
- Tag: `v0.0.1`.

## [Phase 0] — 2026-04-30 (commit `347a938`)

**Project skeleton.** Devcontainer, CI, Makefile, license, README,
STDASSERT bootstrap probe (single-test sanity check that the m-cli
`m test` runner accepts STDASSERT-style assertions under the existing
`^TESTRUN` output-protocol parser).

---

## See also

- [`README.md`](README.md) — the four-bucket doc model this changelog follows.
- [`module-tracker.md`](module-tracker.md) — canonical per-module tracker (Summary table + closed-ticket archaeology).
- [`discoveries.md`](discoveries.md) — discoveries register (in-project pivots + external toolchain findings).
- [`../modules/`](../modules/) — per-module reference; each module has a § History section with deep implementation narrative.
- [`../plans/m-stdlib-implementation-plan.md`](../plans/m-stdlib-implementation-plan.md) — per-module specs and §9 acceptance gate.
- [`../plans/future-modules-plan.md`](../plans/future-modules-plan.md) — proposal pipeline.
