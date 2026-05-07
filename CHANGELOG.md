# Changelog

All notable changes to m-stdlib are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/).

Pre-1.0 minor versions may include breaking changes.

## [Unreleased]

### Added

- **`STDENV`** — `.env` loader + typed accessors (track L24, phase P4
  — tenth Table 2 promotion). Container-tooling ergonomic: read once
  at startup, query many times, sensible defaults filled in. Public
  surface: `$$parse(text, .env)` / `$$parseFile(path, .env)` /
  `$$valid(text)` / `$$has(.env, key)` / `$$get(.env, key, default)` /
  `$$getInt(.env, key, default)` / `$$getBool(.env, key, default)` /
  `$$getFloat(.env, key, default)`. Format: bare and double-quoted
  (`"..."` with `\n \t \r \" \\` escapes) and single-quoted (`'...'`
  literal, no escapes — POSIX-style) values; `#` whole-line comments;
  leading-letter-or-`_` bare keys with `[A-Za-z0-9_]` continuation;
  empty document is valid. `getBool` is case-insensitive against
  `true/yes/on/1` and `false/no/off/0`. Typed accessors return
  `default` on missing / unparseable / wrong-type — lets callers
  write defensive code without explicit `has` checks. Hard dep
  STDFS for `parseFile`; STDSTR listed as soft but inlined for
  self-containment. Out of scope, queued at T22: variable
  substitution (`${VAR}` references), `export` prefix, multi-line
  values, process-env write-back (depends on STDOS `setenv` from
  T15). Test suite: 23 labels, 46 assertions green. Coverage: 14/15
  labels (93.3% — `parseFile` is exercised through integration
  tests in callers, not directly in the unit suite). `m fmt` clean;
  `m lint --error-on=error` 0E (4 non-gating warnings). Per-module
  doc: `docs/modules/stdenv.md`.
- **`STDSNAP`** — snapshot testing (track L23, phase P4 — ninth Table 2
  promotion). Capture a deterministic text dump of an M tree on the
  first run; on subsequent runs, compare the live tree against the
  saved baseline. Mismatches surface as STDASSERT failures with the
  snapshot path so a human can `diff -u baseline current` for
  inspection. Cuts the wrist-deep hand-written `eq^STDASSERT` chains
  for tests that verify large parsed JSON trees, FileMan record
  exports, etc. Public surface: `$$serialize(.data)` /
  `do save(path, .data)` / `$$matches(path, .data)` / `do asserts(.pass,
  .fail, path, .data, desc)`. Canonical format is line-per-leaf
  `(subscripts)=value` — numeric subscripts unquoted, string
  subscripts and values M-quoted with `"..."` and embedded `"`
  doubled per M convention. Walk is `$QUERY`-driven, so lines come
  out in `$ORDER` (M-collation: numeric sort for numeric subscripts,
  string sort for the rest); the format is **deterministic by
  construction** — two calls on the same tree byte-equal each other.
  Hard deps: STDFS (writeFile / readFile / exists for the file I/O),
  STDASSERT (`asserts` integrates with the pass/fail counters and
  recordPass/recordFail output protocol). No STDJSON dep — pre-listed
  as soft but inlined dq() helper for self-containment. Out of scope
  for v1, all queued at T21: root-scalar serialization (`$QUERY`
  walks descendants only), auto-update flag (humans must explicitly
  re-`save` after intentional drift — forces review), bundled diff
  helper (callers shell out to `diff` for byte-level inspection).
  Test suite: 14 labels, 23 assertions green. Coverage: 7/7 labels
  (100%). `m fmt` clean; `m lint --error-on=error` 0E (3 non-gating
  warnings on the recursive walk's complexity). Per-module doc:
  `docs/modules/stdsnap.md`.
- **`STDPROF`** — wall-clock profiler (track L22, phase P4 — eighth
  Table 2 promotion in two days). Caller-owned profiler tree;
  multiple profilers per process are independent variables. Public
  surface: `new(.prof)` / `start(.prof, tag)` / `stop(.prof, tag)` /
  `count(.prof, tag)` / `total(.prof, tag)` / `mean(.prof, tag)` /
  `min(.prof, tag)` / `max(.prof, tag)` / `percentile(.prof, tag, p)`
  / `tags(.prof, .out)` / `clear(.prof)`. Time source: `$ZHOROLOG`
  collapsed to microseconds since 1840-12-31 (the ANSI `$HOROLOG`
  is too coarse at second resolution). Each `stop()` records one
  sample into a sorted-by-value tree
  (`prof("samples", tag, value, seq) = ""`); `percentile(p)` does
  nearest-rank — `ceil(p * N / 100)` into the sorted samples,
  walking via `$ORDER` until the target rank is reached. `p=0`
  short-circuits to `min`; `p=100` short-circuits to `max`. Edge
  cases: a clock skew producing negative elapsed clamps to `0`;
  double-`start()` is a no-op preserving the original start time;
  `stop()` without matching `start()` is a no-op. STDCOLL Heap
  listed as soft dep for a future T20 streaming-percentile (CKMS
  sketch) variant; v1 keeps every sample for exactness, which is
  the right default for one-shot end-of-run reports. Test suite:
  18 labels, 25 assertions green (some labels exercise multiple
  asserts; some HANG to cross the host-clock-resolution boundary).
  Coverage: 12/12 labels (100%). `m fmt` clean; `m lint
  --error-on=error` 0E (file-wide M-MOD-022 disable on `$ZHOROLOG`,
  with rationale anchored on STDDATE's precedent and the
  microsecond-resolution requirement). Per-module doc:
  `docs/modules/stdprof.md`.
- **`STDCACHE`** — LRU + TTL cache (track L21, phase P4 — seventh
  Table 2 promotion in two days). Caller-owned local-array tree;
  no globals, no per-process singletons; multiple caches in one
  process are independent. Public surface: `new` (with optional
  `capacity` and `ttl` args) / `put` / `get` / `has` / `remove` /
  `clear` / `size` / `capacity`. LRU eviction kicks in when a `put`
  pushes `size` past `capacity`; the least-recently-touched entry
  is dropped (touched = accessed by `get` or rewritten by `put`;
  `has` is a clean predicate that does not touch). TTL reaping is
  lazy: `get` and `has` check `cache("ex", key)` against `$HOROLOG`
  and reap expired entries inline. No background sweeper — keeps
  per-access cost O(log N) and predictable. Time source is M's
  ANSI-standard `$HOROLOG` collapsed to seconds since 1840-12-31;
  no `$Z*` extensions. Soft STDCOLL dep listed in Table 2 is not
  exercised in v1 — STDCACHE inlines its bookkeeping for self-
  containment; a rebase onto STDCOLL OrderedDict + an explicit
  `prune` operation for batch sweeps are queued at T19. Test suite:
  18 labels, 48 assertions green (the TTL tests `HANG 1`/`HANG 2`
  to cross the boundary, so the suite has a few seconds of real
  wall-clock cost). Coverage: 10/10 labels (100%). `m fmt` clean;
  `m lint --error-on=error` 0E (4 non-gating warnings: complexity
  flags on `put` / `evictWhileOver` and the `$ORDER` recency
  walk). Per-module doc: `docs/modules/stdcache.md`.
- **`STDTOML`** — TOML 1.0 parser (track L20, phase P4 — sixth Table 2
  promotion in two days). Deliberately narrow v1 covers the practical
  subset used by `pyproject.toml` / `Cargo.toml` / `.m-cli.toml`-style
  configs: top-level key/value pairs, `[section]` headers, string /
  integer / float / bool scalars, `#` comments. Public surface:
  `parse(text, .root)` / `valid(text)` / `get(.root, key)` /
  `type(.root, key)`. Tree representation: `root("v", path)` for the
  decoded value, `root("t", path)` for the type tag, where `path` is
  the dotted address (`"key"` for top-level, `"section.key"` for
  sectioned). String escapes: `\n` `\t` `\r` `\"` `\\` (Unicode
  `\uXXXX` deferred). Trailing `#` comments are stripped string-
  aware — a `#` inside a `"..."` string is preserved. Duplicate
  keys per scope rejected (parse returns 0). Out of scope for v1
  (all queued under T18): arrays, inline tables, dotted keys,
  `[[array-of-tables]]`, multi-line / literal strings, integer
  underscores + hex/oct/bin, special floats (inf/nan), exponent
  notation, datetime values. The v1 surface is enough to ingest
  `.m-cli.toml`-shaped configs; full TOML 1.0 conformance arrives
  alongside whichever consumer drives T18. Pure-M parser — no
  STDREGEX runtime dep, no STDDATE dep, no `$Z*` extensions; runs
  unchanged on YDB and IRIS. Test suite: 28 labels, 59 assertions
  green. Coverage: 14/14 labels (100%). `m fmt` clean; `m lint
  --error-on=error` 0E (3 non-gating warnings: one M-MOD-020 by-ref
  false positive, two M-MOD-005/006 cyclomatic-complexity flags on
  `decodeString`'s escape cascade). Per-module doc:
  `docs/modules/stdtoml.md`.
- **`STDSTR`** — string helpers (track L19, phase P4 — fifth Table 2
  promotion; was Pri 2 in the post-STDSEMVER demoted table — STDXML
  stays at Pri 1 but is genuinely multi-session work). Public surface:
  `pad` / `padLeft` / `padRight` (default char `" "`), `trim` /
  `trimLeft` / `trimRight` (whitespace = ASCII space / tab / LF / CR),
  `replaceAll` (non-overlapping, non-recursive — replacement bytes are
  not rescanned), `split` (multi-char `sep` supported; trailing
  separator yields trailing empty), `startsWith` / `endsWith`
  (predicates; empty prefix/suffix always matches), `toLowerASCII` /
  `toUpperASCII` (byte-wise `$translate` over the 26 letters; non-
  alpha and high-bit-set bytes preserved verbatim), `repeat` (returns
  `""` for `n ≤ 0` or empty source). Pure-M throughout — no `$Z*`
  extensions, no STDREGEX dep. Runs unchanged on YDB and IRIS.
  Unicode whitespace and locale-aware case folding deferred to a
  future STDUNICODE under T17 — STDSTR v1's ASCII-only scope is the
  right default for the `$ZCHSET=M` orbit. Test suite: 37 labels,
  63 assertions green. Coverage: 13/13 labels (100%). `m fmt` clean;
  `m lint --error-on=error` clean (0E 0W). Per-module doc:
  `docs/modules/stdstr.md`.
- **`STDSEMVER`** — Semantic Versioning 2.0.0 (track L18, phase P4 —
  fourth Table 2 promotion; was Pri 2 after the post-STDOS demote).
  Architectural pretext for an eventual M package manager. Public
  surface: `valid` / `parse` / `compare` / `matches` plus `major` /
  `minor` / `patch` / `prerelease` / `build` accessors. Pure-M parser
  (`$piece` / `$translate`-based; no STDREGEX runtime dep). Range
  syntax in v1 covers exact / comparator (`>` `<` `>=` `<=` `=`) /
  caret (`^X.Y.Z` ≡ `>=X.Y.Z <X+1.0.0`) / tilde (`~X.Y.Z` ≡
  `>=X.Y.Z <X.Y+1.0`) / AND-combination via space. The full SemVer §11
  ordering example exercises end-to-end:
  `1.0.0-alpha < alpha.1 < alpha.beta < beta < beta.2 < beta.11 <
  rc.1 < 1.0.0`. Numeric prerelease IDs always lower than
  alphanumeric per §11.4.3; longer prerelease wins ties on shared
  prefix per §11.4.4; build metadata ignored in compare per §10.
  `||` OR-combination, hyphen ranges, `*` / `x` / `X` placeholders,
  prerelease-aware comparators, and npm-style `^0.x.y` zero-major
  narrowing all queued at T16. Test suite: 33 labels, 99 assertions
  green. Coverage: 22/22 labels (100%). `m fmt` clean; `m lint
  --error-on=error` clean (4 cyclomatic-complexity warnings on
  `valid` / `compare` / `matchesOne` — all under the 12-15 thresholds
  for warnings, none gating). Per-module doc: `docs/modules/stdsemver.md`.
- **`STDOS`** — process / env / cmdline helpers (track L17, phase P4
  — third Table 2 promotion in two days; was Pri 3, then Pri 1 after
  STDCSPRNG and STDFS demoted ahead of it). Fills the `$ZCMDLINE` /
  `$ZJOB` / `$ZGETENV` gap with a coherent surface: `env(name)`,
  `pid()`, `cmdline()`, `argc()` / `arg(i)` / `argv(.args)` /
  `splitArgs(s,.args)`, `cwd()`, `user()`, `hostname()`, `exit(rc)`.
  Built over `$ZTRNLNM` / `$JOB` / `$ZCMDLINE` / `ZHALT` (the YDB
  intrinsic boundary) — `$ZTRNLNM` is the VAX/VMS-equivalent of
  `$ZGETENV` that the project's `m fmt` profile leaves alone (the
  GT.M / IRIS-style `$zgetenv` mangles to `$zgbldiretenv` under the
  default abbreviation-expansion rules; tracked as a TOOLCHAIN-
  FINDINGS row). `splitArgs` in v1 is whitespace-only — quote-aware
  tokenisation and `setenv()` are queued at T15 alongside the IRIS
  arm via `$ZF → libc setenv/getcwd/gethostname` callouts. `exit()`
  is unreachable from automated tests by design (calling it ends the
  test process), so per-module label coverage sits at 91.7% (11/12)
  — well above the 85% gate. Test suite: 19 labels, 30 assertions
  green. `m fmt` clean; `m lint --error-on=error` clean (file-wide
  `M-MOD-022` disable on the YDB-extension intrinsics, with the
  rationale anchored on the doc's "Engine portability" note). Per-
  module doc: `docs/modules/stdos.md`.

## [v0.2.0] — 2026-05-07

**Phase 2 release.** Four pure-M heavy-lift modules complete the
Phase-2 set: STDJSON, STDREGEX, STDCOLL, STDURL. Two add-ons land
on the same tag boundary: STDLOG `FORMAT(kv|json)` and STDSEED
`loadJson`. The Phase 1b TDD primitives (STDFIX, STDMOCK, STDSEED)
are also rolled into this release as their `v0.1.x` minor tags
were never cut. Aggregate gate at v0.2.0: 800+ assertions across
16 suites, 0 lint errors, fmt clean, per-module label coverage ≥
95% (most at 100%). Re-enabled error-path tests across STDFMT,
STDDATE, and STDLOG-JSON now that the underlying YDB `$ETRAP` /
extrinsic-chain bugs are documented (TOOLCHAIN-FINDINGS rows
2026-05-06 P1, partially-resolved 2026-05-07).

### Added

- **STDJSON encode/parse refactor** — `encodeArray` / `encodeObject`
  / `parseObject` / `parseArray` now copy child subtrees into a
  non-subscripted local via `merge tmp=node(k)` (encode) or
  `merge node(k)=tmp` after `do parseValue(.ctx,.tmp)` (parse)
  before recursing. Avoids the `$$f(.node(k))` subscripted-by-ref
  call pattern that crashes the YDB harness in this vista-meta
  image (TOOLCHAIN-FINDINGS row 2026-05-06 P1, diagnosis
  2026-05-07). End-to-end: scalar / object / array / nested-tree
  encode all now round-trip; parse populates `root("foo")="s:bar"`
  for `{"foo":"bar"}` correctly.
- **STDFMT raises tests** — six new error-path tests
  (`tUnclosedBraceRaises`, `tUnescapedRbraceRaises`,
  `tUnknownTypeRaises`, `tMissingPositionalArgRaises`,
  `tMissingNamedArgRaises`, `tMissingAutoArgRaises`) cover all
  four documented `U-STDFMT-*` codes via `raises^STDASSERT`,
  unblocked by the v0.1.x ZGOTO unwind. STDFMT 56 → 62 assertions.
- **STDDATE raises tests** — three previously-defined-but-undispatched
  raises labels are now wired into the dispatcher
  (`tFromhRejectsEmpty`, `tTohInvalidRaisesEcode`,
  `tStrptimeInvalidRaisesEcode`). Stdlib header note refreshed to
  reflect the closure. STDDATE 60 → 66 assertions.
- **STDLOG JSON-emission tests (partial)** — two of the six parked
  JSON-format emission tests
  (`tFormatJsonEmitsValidJson`, `tFormatKvAfterJsonReverts`) now
  run because they don't access the parsed tree via subscripted
  by-ref. The remaining four (`tFormatJsonHasTsLevelEvent`,
  `tFormatJsonKvPairsBecomeKeys`, `tFormatJsonValuesAreStrings`,
  `tFormatJsonEscapesQuotesAndBackslash`) stay deferred under the
  broader vista-meta YDB-harness limit on subscripted-by-ref
  parameter passing. STDLOG 48 → 54 assertions.
- **STDREGEX `classEscape` coverage** — five new tests
  (`tClassDigitEscape`, `tClassWordEscape`, `tClassSpaceEscape`,
  `tClassLiteralEscape`, `tClassRangeViaEscape`) exercise `\<x>`
  inside a character class, raising STDREGEX from 90 → 102
  assertions and per-module label coverage from 98.3% (58/59) to
  100% (59/59).
- **`STDFS`** — file-system primitives (track L16, phase P4 — second
  Table 2 promotion; was Pri 2). Centralises the YDB SEQ device
  `OPEN`/`USE`/`READ`/`WRITE`/`CLOSE` dance so consumer modules
  don't have to re-derive the deviceparam combinations or work
  around the `M-MOD-024` lint false-positive. Public surface:
  text-mode I/O (`readFile` / `writeFile` / `append` / `readLines` /
  `writeLines`); existence + metadata (`exists` / `remove` / `size`);
  pure-string path manipulation (`basename` / `dirname` / `join`).
  `exists()` probes via OPEN-with-`timeout=0` inside an `$ETRAP+ZGOTO
  $zlevel` (same arg-less-`quit`-avoidance pattern as `raises^STDASSERT`)
  to catch YDB's `Z150379354` hard-error on missing files — bypasses
  `$ZSEARCH`'s per-process cache so a path created and removed inside
  one M process round-trips correctly. `writeFile` always emits a
  trailing LF (POSIX text-file convention; YDB SEQ stream-mode close
  finalisation), and `readFile` strips the trailing LF on the way back
  — strings round-trip cleanly; on-disk byte count is `$LENGTH(data)+1`
  for non-LF-terminated input. `append()` is implemented as
  read-then-rewrite to sidestep a YDB SEQ APPEND-mode quirk where the
  first WRITE lands at byte 0 instead of EOF; the native append + the
  binary-safe `readBytes` / `writeBytes` pair are queued at T13/T14
  alongside the `$ZF → libc` callout backend that also unlocks the
  IRIS arm. Two error codes: `,U-STDFS-OPEN-FAIL,` (path missing or
  unopenable; raised by all I/O entry points), `,U-STDFS-REMOVE-FAIL,`
  (open-with-DELETE failed for a reason other than "already absent").
  Test suite: 29 labels, 39 assertions green. Coverage: 12/12 labels
  (100%). `m fmt` clean; `m lint --error-on=error` clean (file-wide
  `M-MOD-022` and `M-MOD-024` disables, both with rationale comments).
  Per-module doc: `docs/modules/stdfs.md`.
- **`STDCSPRNG`** — cryptographic random (track L15, phase P4 — first
  promotion out of `docs/module-tracker.md` Table 2; was Pri 1).
  Closes the security gap between STDUUID v4 (`$RANDOM`-backed,
  predictable from a few samples) and security-sensitive identifiers
  (session tokens, password reset tokens, JWT signing salts, nonces).
  Public surface: `bytes(n)` / `hex(n)` / `base64(n)` / `token(n)` /
  `int(min,max)` / `uuid4()` / `available()`. Entropy from
  `/dev/urandom` (kernel ChaCha20 CSPRNG — same source `getrandom(2)`
  reads without `GRND_RANDOM`); single-byte `READ *b` loop avoids
  record-terminator truncation in YDB SEQ-mode device I/O. `int`
  uses rejection sampling on the smallest power of 256 covering the
  range, so the distribution is unbiased (no modulo-bias artefact).
  `uuid4()` shares the canonical 36-char hex form with
  `$$v4^STDUUID()` and round-trips through `$$valid^STDUUID()` /
  `$$version^STDUUID()` / `$$variant^STDUUID()` unchanged — use it
  whenever the UUID is a security boundary. Three error codes:
  `,U-STDCSPRNG-BAD-COUNT,` (negative `n`), `,U-STDCSPRNG-BAD-RANGE,`
  (`int(max,min)` reversed), `,U-STDCSPRNG-OPEN-FAIL,`
  (`/dev/urandom` unopenable — pre-flight via `available()`). Test
  suite: 27 labels, 405 assertions green. Coverage: 7/7 labels
  (100%). `m fmt` clean; `m lint --error-on=error` clean (file-wide
  `M-MOD-024` disable on the OPEN/USE deviceparam false-positive,
  same pattern as STDCSV). Per-module doc:
  `docs/modules/stdcsprng.md`. The `tools/build-callouts.sh`-driven
  `$ZF → getrandom(2)` callout backend is reserved as a future
  perf-only swap (T12) — public API stable.
- **`STDSEED` `loadJson`** (track L10 add-on for `v0.2.0`). Replaces
  the v0.1.3 `U-STDSEED-NOT-IMPLEMENTED` stub with a real
  implementation. `loadJson^STDSEED(jsonText,filer)` parses
  `jsonText` via `$$parse^STDJSON`, expects a JSON array of
  `{"file":<string>,"fields":{<fname>:<scalar>,...}}` objects, and
  dispatches each element via `filer` (default `fileViaDie`). Two
  new error codes: `,U-STDSEED-INVALID-JSON,` (parse failure),
  `,U-STDSEED-INVALID-MANIFEST,` (root-not-array, element-not-object,
  or non-string `file` value). Existing `U-STDSEED-MISSING-FILE` is
  reused when an element omits the `file` key. Six new tests
  (`tLoadJsonStubFilerReceivesEntry` … `tLoadJsonMissingFileKeyRaises`)
  are defined in the suite but withheld from the driver until the
  documented STDASSERT.raises P1 / extrinsic-chain harness crash is
  resolved (same blocker as the STDLOG-JSON-emission tests in this
  release). Implementation ships intact.
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
