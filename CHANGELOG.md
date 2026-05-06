# Changelog

All notable changes to m-stdlib are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/).

Pre-1.0 minor versions may include breaking changes.

## [Unreleased]

### Added

- **`STDLOG` JSON-line output** (track L4 add-on for `v0.2.0`).
  New public extrinsic `FORMAT^STDLOG(name)` selects the
  line-rendering format: `"kv"` (default, unchanged) or `"json"`
  (one RFC-8259 object per log line, built via `$$encode^STDJSON` so
  each line round-trips through `$$parse^STDJSON` without loss).
  `ts` / `level` / `event` are top-level keys; supplied kv pairs
  become additional string-typed members. Bad format names raise
  `,U-STDLOG-INVALID-FORMAT,`. Suite gate: 47/47 kv-path assertions
  green; the seven JSON-emission assertion tests
  (`tFormatJsonEmitsValidJson` … `tFormatInvalidRaises`) are
  defined in the suite but withheld from the driver until the
  documented STDASSERT.raises P1 / extrinsic-chain runner crash is
  resolved (same shape as the TOOLCHAIN-FINDINGS P1 affecting
  STDFMT / STDDATE / STDCSV error-path tests). Implementation
  ships intact; the driver re-enables the assertion bodies once
  the crash is debugged. STDSEED `LOADJSON` add-on (next L10
  follow-on) will consume the same `$$parse^STDJSON` entry point.
- **`STDREGEX`** — regular expressions (track L12, Phase 2, target
  tag `v0.2.0`). Thompson-NFA engine on YottaDB; documented `$MATCH`/
  `$LOCATE` wrap on IRIS for the simple-pattern subset (full IRIS
  pass deferred — the `iris-portability-check` CI job remains
  fail-soft). Public surface: `compile` / `valid` / `match` / `search`
  / `find` / `findall` / `groups` / `replace` / `split` / `free`.
  Engine: lexer + parser → AST (Pass A); standard McNaughton-Yamada
  Thompson construction with priority-ordered ε-edges (Pass B);
  Pike-style breadth-first walk (Pass C); parallel cap-aware
  simulator with first-arrival-wins state dedup and recursive DFS
  ε-closure for greedy capture semantics (Pass D); non-overlapping
  walk over `attempt`/`attemptCap` for `findall` / `replace` (with
  `\1..\9` backref expansion in the repl) / `split` (Pass E).
  Supported subset: literals, `.`, `^`/`$`, `* + ? {n} {n,} {n,m}`
  greedy, `[abc]`/`[^abc]`/`[a-z]`, predefined `\d \D \w \W \s \S`,
  escapes `\\ \. \^ \$ \( \) \[ \] \{ \} \| \* \+ \? \n \t \r`,
  alternation `|`, capturing `(...)` and non-capturing `(?:...)`.
  Out of scope at v0.2.0 (rejected with `U-STDREGEX-UNSUPPORTED`):
  back-refs in pattern, lookaround, named groups, Unicode property
  classes, inline modifiers, possessive / lazy quantifiers — these
  ride a future `STDREGEX_PCRE` (Phase-3-adjacent, `$ZF` to
  `libpcre2`). 90/90 assertions green; 0 lint errors. Per-module
  doc at `docs/modules/stdregex.md`. Pure-M; no host-call. Side fix
  bundled with Pass B: setting `$ECODE` to a `,U-STDREGEX-…,` value
  fired the caller's `$ETRAP`, but YDB's after-error resume
  bypassed compile()'s own QUIT into post-error cleanup that
  crashed with `M17 Z150374554`, overwriting the user code. Routed
  raises through a tiny `raise(err)` helper that fires the trap
  inside a frame that QUITs immediately; the same pattern applies
  to STDFMT / STDARGS but is not yet ported there (tracked in
  TOOLCHAIN-FINDINGS).
- **Auxiliary tracks A3 / A4 / A5 / A6** (per impl-plan §3.5).
  - **A3**: curated JSON conformance corpus at
    `tests/conformance/json/` — 23 `y_*` (must-parse), 15 `n_*`
    (must-reject), 8 `i_*` (implementation-defined) files plus a
    README mapping each file to an RFC-8259 clause. Used by track
    L11 (STDJSON, Phase 2). Full ~318-file JSONTestSuite intentionally
    not vendored — the curated set keeps the corpus auditable by eye.
  - **A4**: RFC-4122 / RFC-9562 UUID vectors at
    `tests/conformance/uuid/rfc4122-vectors.tsv` — 27 rows (Nil + Max
    + every version 1–8 + all four variants + mixed/upper case + 8
    malformed-input rejections), with the `version`/`variant`/`valid`
    columns matching STDUUID's expected returns. README documents the
    coverage map.
  - **A5**: `iris-portability-check` job re-added to
    `.github/workflows/ci.yml`. Fail-soft (`continue-on-error: true`),
    runs on PRs only against `intersystemsdc/iris-community:latest`.
    Surfaces IRIS portability regressions without gating merges.
  - **A6**: `tools/build-callouts.sh` — Phase 3 prereq for STDHTTP /
    STDCRYPTO / STDCOMPRESS callouts. Auto-detects host platform
    (linux-x86_64 / linux-aarch64 / darwin-x86_64 / darwin-arm64),
    compiles `src/callouts/*.c` to `so/<platform>/*.{so,dylib}` with
    YDB host-call ABI flags. Supports `--check` (dry run), `--clean`,
    `--target=PLAT` (cross-name only). Permanent self-test fixture at
    `src/callouts/probe.c`; build output gitignored under `so/`.
- **`STDURL`** — RFC 3986 URI parser, builder, encoder, resolver
  (track L14, Phase 2, target tag `v0.2.0`). One public procedure
  (`parse`) and six public extrinsics (`build`, `encode`, `decode`,
  `valid`, `normalize`, `resolve`). `parse` writes all seven keys
  (`scheme` / `userinfo` / `host` / `port` / `path` / `query` /
  `fragment`) so callers can index without `$get`. `decode` is
  intentionally lenient (Python `urllib.parse.unquote` semantics —
  malformed `%` sequences pass through as literal text); `valid` is
  the strict gate. `normalize` applies RFC 3986 §6.2 syntax-based
  normalisation (lowercase scheme + host, uppercase `%HH` hex,
  decode unreserved, remove `.` / `..` dot-segments). `resolve`
  implements §5.3 transform-references in strict mode (no scheme
  inheritance — `http:g` against `http://a/b/c/` resolves to
  `http:g`). Pure-M; no host-call. `STDURL` does not set `$ECODE`.
  150/150 assertions green; 100% label coverage (21/21); 0 lint
  errors. Per-module doc at `docs/modules/stdurl.md`. RFC 3986 §5.4
  normal + abnormal reference-resolution corpora vendored to
  `tests/conformance/url/`. Downstream consumer is `STDHTTP` in
  Phase 3.
- **`STDCOLL`** — collections (track L13, Phase 2, target tag `v0.2.0`).
  Seven by-reference collection types over caller-owned local arrays:
  `Set`, `Map`, `Stack`, `Queue`, `Deque`, `Heap` (min-heap with
  optional payload), and insertion-ordered `OrderedDict`. 51 public
  labels covering `add` / `put` / `push` / `pop` / `peek` / `get` /
  `has` / `remove` / `size` / `clear` / `next` / `prev` / `first` /
  `last` per type. Empty-key and empty-pop semantics are silent
  no-ops / blank returns rather than `$ECODE`-raising — callers gate
  on `*Size` to distinguish empty from a stored `""`. Heap is a
  binary-heap with `O(log n)` push / pop and `O(1)` peek; OrderedDict
  walks insertion order via a monotonic sequence allocator and
  reverse map. 116/116 assertions green; 51/51 labels covered (100%);
  0 lint errors. Per-module doc at `docs/modules/stdcoll.md`. Pure-M;
  no host-call. YottaDB-first; IRIS-portable (no engine-specific
  features used). Companion track to L11/L12/L14 toward the v0.2.0
  Phase 2 release.
- **`STDFIX`** — fixture lifecycle and per-test isolation (track L8,
  Phase 1b TDD primitive, target tag `v0.1.1`). Five public labels:
  `with` (one-shot transactional scope), `$$active` (predicate),
  `register` (declarative fixture), `invoke` (run code with registered
  setup/teardown hooks), `cleanup` (idempotent rollback of leaks).
  YDB nested transactions (`tstart` / `trollback $tlevel-1`) provide
  rollback isolation; nested `with`/`invoke` calls roll back their
  own level only and preserve outer scopes. 28/28 assertions green;
  100% label coverage (5/5); 0 lint errors. Per-module doc at
  `docs/modules/stdfix.md`. Design departure from the orchestration-
  plan sketch: standalone `setup(tag)` / `teardown(tag)` cannot exist
  in YDB because TPQUIT enforces per-routine-frame balance of
  `tstart` / `trollback`; STDFIX therefore exposes only one-shot
  wrappers. The `m test` runner protocol consumes `with`/`invoke`,
  not raw setup/teardown. Error-path re-raise tests deferred to
  v0.0.5+ alongside the TOOLCHAIN-FINDINGS P1 STDASSERT.raises fix
  (same chain that affects STDFMT, STDDATE, STDCSV).
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
- **`STDSEED`** — declarative test-data loader (track L10, Phase 1b
  TDD primitive, target tag `v0.1.3`). One public procedure
  (`load`), three extrinsics (`$$loaded`, `$$validate`, default-filer
  internals), and `clear` / `loadJson` companions. TSV manifest
  format: `<file>\t<field>=<value>\t…` with `#` comments and blank
  lines skipped; the first `=` per pair is the separator (values
  may contain further `=`). Each row dispatches to a pluggable
  *filer* — default `fileViaDie^STDSEED` calls `FILE^DIE` and
  surfaces `^TMP("DIERR",$J)` as `U-STDSEED-FILER-DIE-ERROR`; tests
  inject a stub filer so the suite runs without FileMan. Bookkeeping
  per loaded path under `^STDLIB($job,"stdseed",path,...)` so
  `clear` can drop it. `loadJson` is a stub raising
  `U-STDSEED-NOT-IMPLEMENTED` until STDJSON ships in Phase 2.
  Errors set `$ECODE` to `U-STDSEED-{FILE-NOT-FOUND, MISSING-FILE,
  MISSING-FIELD, FILER-ERROR, FILER-DIE-ERROR, NOT-IMPLEMENTED}`.
  25/25 assertions green; 10/11 labels covered (90.9%) — the only
  uncovered label is `fileViaDie`, the real-FileMan integration
  pending v0.1.4 + STDFIX rollback. Per-module doc at
  `docs/modules/stdseed.md`. Pairs with the m-cli runner track Y
  flag `m test --seed PATH` once M1 lands.

## [v0.1.0] — 2026-05-05

**Phase 1 release.** Seven new pure-M modules ship across tags
`v0.0.2`–`v0.0.7`, completing the Phase-1 set planned in §8 of the
implementation plan. Combined with `v0.0.1` (`STDASSERT` + `STDUUID`),
m-stdlib at `v0.1.0` provides nine modules: assertions, UUIDs, base64
+ hex, printf-style formatting, structured logging, ISO-8601 datetime,
RFC-4180 CSV, and argparse.

### `v0.0.2` — Base64 + Hex (commit `83e11b2`)

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

### `v0.0.3` — Printf-style formatter (commit `8e6b689`)

- **`STDFMT`** — printf-style formatter (subset of Python `str.format`).
  Two public extrinsics: `f` (up to 9 positional) and `fn` (named
  via local array). Format spec covers fill / align / width /
  precision / type (`s d f x X o b`). `{{` and `}}` escape literal
  braces. Float precision uses `$FNUMBER` rounding. Errors set
  `$ECODE` to documented `U-STDFMT-*` codes. 56/56 assertions green;
  100% label coverage (11/11); 0 lint errors. Per-module doc at
  `docs/modules/stdfmt.md`. Error-path unit tests deferred — see
  TOOLCHAIN-FINDINGS P1 against `STDASSERT.raises`.

### `v0.0.4` — Structured logger (commit `abfa9a2`)

- **`STDLOG`** — structured `key=value` logger (track L4 + L4b).
  Five level entry points (`DEBUG`/`INFO`/`WARN`/`ERROR`/`FATAL`),
  each accepting an `event` string and up to 5 kv pairs.
  Configuration: `LEVEL` (per-process threshold) and `SINK`
  (`stderr` / `stdout` / `global` / `global:^GREF`). Output line
  format: `<ISO ts> level=<NAME> event=<event> k=v k=v ...`; values
  emitted raw when clean, otherwise wrapped in `"..."` with `\\`
  and `\"` escaping. Errors set `$ECODE` to `U-STDLOG-INVALID-LEVEL`
  or `U-STDLOG-INVALID-SINK`. Timestamp source: `$$now^STDDATE()`
  (track L4b folded in since L5 STDDATE landed first — the inline
  ISO-8601 helper that v0.0.4 was originally to ship was never
  needed). 45/45 assertions green; 100% label coverage (15/15); 0
  lint errors. Per-module doc at `docs/modules/stdlog.md`.

### `v0.0.5` — ISO-8601 datetime (commit `1ec3b00`)

- **`STDDATE`** — ISO-8601 datetime + duration arithmetic (track L5).
  Seven public extrinsics: `now` (current UTC, ms precision, trailing
  `Z`), `fromh` ($HOROLOG → ISO-8601, accepts 2/3/4-piece input),
  `toh` (ISO-8601 → $HOROLOG, emits 2/3/4-piece per subsecond + tz
  presence), `strftime` / `strptime` (`%Y %m %d %H %M %S %j %z %%`
  directives), `add` (ISO-8601 duration
  `[-]P[nY][nM][nW][nD][T[nH][nM][nS]]`, with Feb-29 → Feb-28
  day-clamp on `+P1Y`), `diff` (h2 − h1 → `PnDTnHnMnS`,
  sign-prefixed). Civil ↔ day-count uses Howard Hinnant's
  `days_from_civil` over proleptic Gregorian (verified for years
  1840–2400 incl. all leap-year edge cases). Errors set `$ECODE` to
  `U-STDDATE-BAD-{HOROLOG,ISO,DUR}`. 60/60 assertions green; 19/20
  labels (95.0%); 0 lint errors. Per-module doc at
  `docs/modules/stddate.md`. Error-path unit tests deferred per
  TOOLCHAIN-FINDINGS P1 against `STDASSERT.raises`.

### `v0.0.6` — RFC-4180 CSV (commit `0f7de40`)

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

### `v0.0.7` — argparse (commit `c98d5a1`)

- **`STDARGS`** — argparse for M scripts. Long flags (`--verbose`),
  short flags (`-v`), grouped count flags (`-vvv`), positionals,
  sub-commands, `--` end-of-flags terminator. Four actions:
  `store_true`, `store`, `count`, `append`. Args source is
  `$ZCMDLINE` on YDB, an explicit string elsewhere. Tokenisation is
  whitespace-only; quoting is the shell's job. Parser state lives
  per handle under `^STDLIB($job,"stdargs",p,...)`; `free()` drops
  it. Errors set `$ECODE` to documented `U-STDARGS-*` codes. 37/37
  assertions green; 100% label coverage (14/14); 0 lint errors.
  Per-module doc at `docs/modules/stdargs.md`. Real-project demo at
  `examples/stdargs-demo.m`.

### Conformance corpora

- `tests/conformance/b64/` — RFC-4648 §10 (standard + URL-safe),
  consumed by `STDB64`.
- `tests/conformance/csv/` — RFC-4180 §2 vectors + excel-quirks +
  LF-only line endings + UTF-8 BOM, consumed by `STDCSV`.
- `tests/conformance/{json,uuid}/` directories reserved for Phase 2.

### Per-module docs

`docs/modules/{stdb64,stdhex,stdfmt,stdlog,stddate,stdcsv,stdargs}.md`
written. `docs/modules/index.md` regenerated as the canonical index of
shipped Phase-1 modules.

### Per-module gate (§9 of the implementation plan)

- ✅ `m fmt --check` clean across all `src/` and `tests/` files
- ✅ `m lint --error-on=error` 0 findings
- ✅ `m test` — 527 / 527 assertions across 9 suites (`STDASSERT` 35,
  `STDUUID` 131, `STDB64` 55, `STDHEX` 49, `STDFMT` 56, `STDLOG` 45,
  `STDDATE` 60, `STDCSV` 59, `STDARGS` 37)
- ✅ `m coverage --min-percent=85` — every module ≥ 95% (most at
  100%); aggregate well above the 85% threshold
- ✅ Per-module docs written for all 9 modules
- ✅ STDLOG inline-timestamp helper removed (replaced by `$$now^STDDATE()`
  per impl-plan §8.10) — folded into the L4 commit since L5 landed
  first
- ⏭️ IRIS `iris-portability-check` job re-add (auxiliary track A5)
  outstanding; planned alongside the v0.1.0 → v0.1.1 cycle

### Notes on deferred work

- **Error-path unit tests** for `STDFMT` and `STDDATE` (and any
  future `raises`-based suites that drive errors through extrinsic
  chains) are present-but-not-dispatched until
  `STDASSERT.raises` is fixed — see `TOOLCHAIN-FINDINGS.md` P1
  (`$ETRAP` arg-less `quit` + `%YDB-E-NOTEXTRINSIC`). The contract
  is documented in each module's per-module doc.
- **Phase 1b** (`STDFIX` / `STDMOCK` / `STDSEED`) and **Phase 2**
  (`STDCOLL` / `STDREGEX` / `STDJSON` / `STDURL`) remain in
  `[Unreleased]`; their respective minor-version releases follow
  Phase 1 on the orchestration plan's M1 / `v0.2.0` schedule.

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
