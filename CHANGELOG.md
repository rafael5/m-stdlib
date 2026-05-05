# Changelog

All notable changes to m-stdlib are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/).

Pre-1.0 minor versions may include breaking changes.

## [Unreleased]

### Added

- **`STDB64`** — RFC-4648 Base64 encoding (standard alphabet `+ /`,
  with `=` padding) and URL-safe variant (`- _`, no padding —
  RFC-4648 §5, JWT convention). Five public extrinsics: `encode`,
  `decode`, `urlencode`, `urldecode`, `valid`. RFC-4648 §10 vectors
  vendored to `tests/conformance/b64/` (standard + URL-safe). 55/55
  assertions green; 100% label coverage; 0 lint errors.
- **`STDHEX`** — RFC-4648 §8 hex encoding. Four public extrinsics:
  `encode` (lowercase default), `encodeu` (uppercase), `decode`
  (case-insensitive), `valid` (even length + hex digits, accepts any
  case). 49/49 assertions green; 100% label coverage; 0 lint errors.
- **`STDCSV`** — RFC-4180 CSV parser/writer. Four public entry points:
  `$$parse^STDCSV(text,.rows)`, `$$write^STDCSV(.rows)`,
  `parseFile^STDCSV(path,callback)`, `writeFile^STDCSV(path,.rows)`.
  Covers every RFC-4180 §2 clause (CRLF/LF/lone-CR record separators,
  optional trailing terminator, optional `"..."` field wrapping,
  embedded `,` / CRLF / `""` escape) and strips a leading UTF-8 BOM
  on input. YottaDB-only file I/O at v0.0.6 (uses SEQ-device
  `readonly` / `newversion:stream:nowrap` deviceparams). 59/59
  assertions green; 100% label coverage (6/6); 0 lint errors.
  Per-module doc at `docs/modules/stdcsv.md`. RFC-4180 §2 audit-trail
  corpus vendored to `tests/conformance/csv/`.
- **Per-module docs**: `docs/modules/stdb64.md`,
  `docs/modules/stdhex.md`, `docs/modules/stdcsv.md`.
- **Conformance corpus skeleton**: `tests/conformance/b64/` populated
  with the §10 vectors; `tests/conformance/csv/` populated with the
  RFC-4180 §2 vectors; `tests/conformance/{json,uuid}/` directories
  created for future modules.
- **`STDFMT`** — printf-style formatter (subset of Python `str.format`).
  Two public extrinsics: `f` (up to 9 positional) and `fn` (named
  via local array). Format spec covers fill / align / width /
  precision / type (`s d f x X o b`). `{{` and `}}` escape literal
  braces. Float precision uses `$FNUMBER` rounding. Errors set
  `$ECODE` to documented `U-STDFMT-*` codes. 56/56 assertions green;
  100% label coverage (11/11); 0 lint errors. Per-module doc at
  `docs/modules/stdfmt.md`. Error-path unit tests deferred — see
  TOOLCHAIN-FINDINGS P1 against `STDASSERT.raises`.
- **`STDARGS`** — argparse for M scripts (Phase 1, `v0.0.7`). Long
  flags (`--verbose`), short flags (`-v`), grouped count flags
  (`-vvv`), positionals, sub-commands, `--` end-of-flags terminator.
  Four actions: `store_true`, `store`, `count`, `append`. Args source
  is `$ZCMDLINE` on YDB, an explicit string elsewhere. Tokenisation
  is whitespace-only; quoting is the shell's job. Parser state lives
  per handle under `^STDLIB($job,"stdargs",p,...)`; `free()` drops
  it. Errors set `$ECODE` to documented `U-STDARGS-*` codes. 37/37
  assertions green; 100% label coverage (14/14); 0 lint errors.
  Per-module doc at `docs/modules/stdargs.md`. Real-project demo at
  `examples/stdargs-demo.m`.
- **`STDDATE`** — ISO-8601 datetime + duration arithmetic (track L5,
  `v0.0.5`). Seven public extrinsics: `now` (current UTC, ms
  precision, trailing `Z`), `fromh` ($HOROLOG → ISO-8601, accepts
  2/3/4-piece input), `toh` (ISO-8601 → $HOROLOG, emits 2/3/4-piece
  per subsecond + tz presence), `strftime` / `strptime` (`%Y %m %d
  %H %M %S %j %z %%`), `add` (ISO-8601 duration `P[nY][nM][nW][nD][T[nH][nM][nS]]`,
  with `-P...` for negative durations and Feb-29 → Feb-28 day-clamp
  on `+P1Y`), `diff` (h2 − h1 → `PnDTnHnMnS`, sign-prefixed).
  Civil ↔ day-count uses Howard Hinnant's `days_from_civil` over
  proleptic Gregorian (verified for years 1840 − 2400 incl. all
  leap-year edge cases). Errors set `$ECODE` to `U-STDDATE-BAD-HOROLOG`
  / `U-STDDATE-BAD-ISO` / `U-STDDATE-BAD-DUR`. 60/60 assertions green.
  Per-module doc at `docs/modules/stddate.md`. Error-path unit tests
  deferred — see TOOLCHAIN-FINDINGS P1 against `STDASSERT.raises`.
- **`STDLOG`** — structured key=value logger (track L4, `v0.0.4`).
  Five level entry points (`DEBUG`/`INFO`/`WARN`/`ERROR`/`FATAL`),
  each accepting an `event` string and up to 5 kv pairs.
  Configuration: `LEVEL` (per-process threshold) and `SINK`
  (`stderr` / `stdout` / `global` / `global:^GREF`). Output line
  format: `<ISO ts> level=<NAME> event=<event> k=v k=v ...`; values
  are emitted raw when clean, otherwise wrapped in `"..."` with
  `\\` and `\"` escaping. Errors set `$ECODE` to
  `U-STDLOG-INVALID-LEVEL` or `U-STDLOG-INVALID-SINK`. Ships an
  inline ISO-8601 timestamp helper (replaced by `$$now^STDDATE()`
  in track L4b once STDDATE merges at v0.0.5). 45/45 assertions
  green; 100% label coverage (18/18); 0 lint errors. Per-module doc
  at `docs/modules/stdlog.md`. Pending sub-track (per impl-plan
  §8.6): re-introduce IRIS `iris-portability-check` job in CI
  (fail-soft) — auxiliary track A5.
- **`STDMOCK`** — opt-in test-time call interception (track L9, Phase
  1b TDD primitive, target tag `v0.1.2`). Three procedures
  (`register` / `unregister` / `clear`), three extrinsics (`$$resolve`
  / `$$called` / `$$args`), and one indirection-driven procedure
  (`invoke`). Registry under `^STDLIB($job,"stdmock",...)`. Single-
  level resolution (no chained replacement). Records call count and
  per-call arg subscripts so tests can verify what the production
  code passed. Production code opts in by calling `invoke^STDMOCK`
  (or `do @$$resolve^STDMOCK(t)@(.args)`) at injection points. m-cli
  runner companion track X will call `do clear^STDMOCK` between
  tests. 26/26 assertions green; 100% label coverage (7/7); 0 lint
  errors (one M-MOD-036 line is suppressed with justification — the
  documented purpose of `invoke` is registered-target indirection).
  Per-module doc at `docs/modules/stdmock.md`.

## [v0.0.1] — 2026-04-30

### Added

- **`STDASSERT`** — full assertion library. 9 public extrinsics
  (`start`, `report`, `eq`, `ne`, `true`, `false`, `near`, `raises`,
  `contains`, `len`) plus a `silent` toggle for self-tests of
  negative paths. Output protocol mirrors `^TESTRUN` byte-for-byte
  so m-cli's `m test` runner accepts STDASSERT-driven suites
  unchanged. 35 / 35 self-tests green.
- **`STDUUID`** — RFC-4122 v4 and RFC-9562 v7 UUIDs. 5 public
  extrinsics (`v4`, `v7`, `valid`, `version`, `variant`). v7
  timestamp prefix is 48 bits of ms-since-Unix-epoch; lexicographic
  sort = generation order. 131 / 131 tests green, including a
  200-sample v4 uniqueness check and a v7 monotonicity check.
- **Per-module docs**: `docs/modules/stdassert.md`,
  `docs/modules/stduuid.md`.
- **`tools/init-db.sh` bumped `KEY_SIZE=1019` + `BLOCK_SIZE=4096`**
  so YDB's `view "TRACE"` can capture deep `FOR_LOOP/*CHILDREN`
  subscripts without `%YDB-E-GVSUBOFLOW`. Required for the
  per-module coverage gate to measure FOR-loop-heavy tests.

### Changed

- `STDASSERT.m` probe stub (Phase 0) replaced with the v0.0.1 full
  module. Internal `pass`/`fail` helpers renamed to `recordPass` /
  `recordFail` to dissolve the M-MOD-020 label/formal name-shadow
  warning carried over from `^TESTRUN`.
- Makefile `ci` target now passes explicit `tests/` and
  `--routines src --tests tests` to `m test` / `m coverage` (m-cli
  defaults to m-tools' `routines/tests/` layout, which we don't use).

### Per-module gate (§9 of the implementation plan)

- ✅ `m fmt --check` clean
- ✅ `m lint --error-on=error` 0 findings
- ✅ `m test` — 166 / 166 assertions across 2 suites
- ✅ `m coverage --min-percent=85` — **22 / 22 labels (100%)**
- ✅ Per-module docs written
- ⏭️ IRIS portability — fail-soft, omitted from CI until v0.0.4

## [Phase 0] — 2026-04-30 (commit 347a938)

### Added

- Project skeleton, devcontainer, CI, Makefile, license, README.
- `STDASSERT` bootstrap probe (single-test sanity check that the
  m-cli `m test` runner accepts STDASSERT-style assertions under
  the existing `t<UpperCase>(pass,fail)` discovery convention).
