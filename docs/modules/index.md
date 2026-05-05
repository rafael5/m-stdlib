# m-stdlib modules

Regenerated at the **v0.1.0** Phase 1 release (2026-05-05). One row
per shipped module. Phase 1b modules (`STDMOCK`, `STDSEED`) and
Phase 2 modules (`STDCOLL`, `STDREGEX`, `STDJSON`, `STDURL`, ...)
are not in this index; they appear once their respective milestone
releases.

## Phase 1 (v0.1.0)

| Module | Tag | Purpose | Per-module doc |
|---|---|---|---|
| [`STDASSERT`](stdassert.md) | `v0.0.1` | Assertion library — 9 extrinsics + `silent` toggle, `^TESTRUN`-compatible output protocol so `m test` accepts STDASSERT-driven suites unchanged. | [stdassert.md](stdassert.md) |
| [`STDUUID`](stduuid.md) | `v0.0.1` | RFC-4122 v4 + RFC-9562 v7 UUIDs. v7 timestamp-prefix sorts in generation order. | [stduuid.md](stduuid.md) |
| [`STDB64`](stdb64.md) | `v0.0.2` | RFC-4648 Base64 — standard + URL-safe alphabets, RFC §10 vectors as conformance corpus. | [stdb64.md](stdb64.md) |
| [`STDHEX`](stdhex.md) | `v0.0.2` | RFC-4648 §8 hex — lowercase default, uppercase variant, case-insensitive decode. | [stdhex.md](stdhex.md) |
| [`STDFMT`](stdfmt.md) | `v0.0.3` | Printf-style formatter — subset of Python `str.format`: fill / align / width / precision / type (`s d f x X o b`), `{{`/`}}` escapes. | [stdfmt.md](stdfmt.md) |
| [`STDLOG`](stdlog.md) | `v0.0.4` | Structured `key=value` logger — five levels, four sinks, `$$now^STDDATE()` timestamp. | [stdlog.md](stdlog.md) |
| [`STDDATE`](stddate.md) | `v0.0.5` | ISO-8601 datetime + duration arithmetic — `now` / `fromh` / `toh` / `strftime` / `strptime` / `add` / `diff` over proleptic Gregorian. | [stddate.md](stddate.md) |
| [`STDCSV`](stdcsv.md) | `v0.0.6` | RFC-4180 CSV parser/writer — every §2 clause, optional file I/O, RFC §2 conformance corpus. | [stdcsv.md](stdcsv.md) |
| [`STDARGS`](stdargs.md) | `v0.0.7` | argparse — long/short/grouped flags, positionals, sub-commands, `--` terminator, four actions (`store_true` / `store` / `count` / `append`). | [stdargs.md](stdargs.md) |

**Phase 1 totals**: 9 modules; 527/527 assertions green across the
test suites (STDASSERT 35, STDUUID 131, STDB64 55, STDHEX 49, STDFMT
56, STDLOG 45, STDDATE 60, STDCSV 59, STDARGS 37); per-module coverage
≥ 95% (most at 100%); 0 lint errors across `src/` and `tests/`.

## Conformance corpora

| Path | Vectors | Used by |
|---|---|---|
| `tests/conformance/b64/` | RFC-4648 §10 (standard + URL-safe) | `STDB64` |
| `tests/conformance/csv/` | RFC-4180 §2 + excel-quirks + LF-only + UTF-8 BOM | `STDCSV` |

(`tests/conformance/json/` and `tests/conformance/url/` directories
are reserved for Phase 2 modules.)

## Cross-module dependencies (runtime)

Per [parallel-tracks.md §2](../parallel-tracks.md#2-dependency-map),
the only Phase 1 cross-edge is **STDLOG → STDDATE** (`STDLOG` calls
`$$now^STDDATE()` for the line-leading timestamp). All other Phase 1
modules are independent at runtime.
