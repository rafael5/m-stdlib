# m-stdlib modules

Regenerated at the **v0.2.0** Phase 2 release (2026-05-07). One
row per shipped module. The canonical "what's done / in flight /
proposed" view lives in [`docs/module-tracker.md`](../module-tracker.md);
this file is the released-module catalogue.

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

**Phase 1 totals**: 9 modules; 527/527 assertions green; per-module
coverage ≥ 95% (most at 100%); 0 lint errors.

## Phase 1b (v0.1.1 – v0.1.3)

| Module | Tag | Purpose | Per-module doc |
|---|---|---|---|
| [`STDFIX`](stdfix.md) | `v0.1.1` | Fixture lifecycle — `with` / `invoke` one-shot transactional scopes; powers per-test `tstart` / `trollback` isolation. | [stdfix.md](stdfix.md) |
| [`STDMOCK`](stdmock.md) | `v0.1.2` | Test-time call interception — `register` / `invoke` / `$$resolve` / `$$called` / `$$args`. | [stdmock.md](stdmock.md) |
| [`STDSEED`](stdseed.md) | `v0.1.3` | Declarative TSV manifest loader for FileMan record fixtures + pluggable filer hook (`fileViaDie` default). | [stdseed.md](stdseed.md) |

## Phase 2 (v0.2.0)

| Module | Tag | Purpose | Per-module doc |
|---|---|---|---|
| [`STDJSON`](stdjson.md) | `v0.2.0` | RFC 8259 JSON parser + serialiser — one M-tree node per JSON value (`o` / `a` / `s:` / `n:` / `t` / `f` / `z`). | [stdjson.md](stdjson.md) |
| [`STDREGEX`](stdregex.md) | `v0.2.0` | Thompson-NFA regex on YDB — full v0.2.0 subset (literals, classes, groups, alternation, greedy quantifiers, capture, replace, split). 102/102 assertions; 100% per-module label coverage. | [stdregex.md](stdregex.md) |
| [`STDCOLL`](stdcoll.md) | `v0.2.0` | Collections — Set / Map / Stack / Queue / Deque / Heap / OrderedDict over caller-owned arrays. | [stdcoll.md](stdcoll.md) |
| [`STDURL`](stdurl.md) | `v0.2.0` | RFC 3986 URI parse / build / encode / decode / valid / normalize / resolve. | [stdurl.md](stdurl.md) |

**v0.2.0 add-ons (no new modules):**

- **STDLOG `FORMAT(kv|json)`** — JSON-line output via
  `$$encode^STDJSON` (consumes L11). `kv` remains the default.
- **STDSEED `loadJson`** — JSON-array manifest loader via
  `$$parse^STDJSON`. Replaces the v0.1.3
  `U-STDSEED-NOT-IMPLEMENTED` stub.

**Phase 2 totals**: 4 new modules + 2 add-ons; ~600 new assertions
across STDJSON, STDREGEX, STDCOLL, STDURL; per-module label
coverage ≥ 95% (most at 100%); 0 lint errors.

## Conformance corpora

| Path | Vectors | Used by |
|---|---|---|
| `tests/conformance/b64/` | RFC-4648 §10 (standard + URL-safe) | `STDB64` |
| `tests/conformance/csv/` | RFC-4180 §2 + excel-quirks + LF-only + UTF-8 BOM | `STDCSV` |
| `tests/conformance/json/` | Curated subset of JSONTestSuite (23 `y_`, 15 `n_`, 8 `i_` files) mapped to RFC 8259 clauses | `STDJSON` |
| `tests/conformance/url/` | RFC 3986 §5.4 normal + abnormal reference-resolution vectors | `STDURL` |
| `tests/conformance/uuid/` | RFC-4122 / RFC-9562 vectors (every version 1–8, all four variants, 8 malformed-input rejections) | `STDUUID` |

## Cross-module dependencies (runtime)

Per [parallel-tracks.md §2](../parallel-tracks.md#2-dependency-map):

- **STDLOG → STDDATE** — `$$now^STDDATE()` for line-leading
  timestamp.
- **STDLOG `FORMAT="json"` → STDJSON** — `$$encode^STDJSON` for
  JSON-line emission (v0.2.0 add-on).
- **STDSEED `loadJson` → STDJSON** — `$$parse^STDJSON` for JSON
  manifest parsing (v0.2.0 add-on).

All other modules are runtime-independent.
