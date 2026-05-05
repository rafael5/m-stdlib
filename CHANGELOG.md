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
- **Per-module docs**: `docs/modules/stdb64.md`,
  `docs/modules/stdhex.md`.
- **Conformance corpus skeleton**: `tests/conformance/b64/` populated
  with the §10 vectors; `tests/conformance/{csv,json,uuid}/`
  directories created for future modules.

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
