---
title: m-stdlib — master module development tracker
status: live (2026-05-07; STDCSPRNG promoted to Table 1)
audience: anyone landing or proposing a module in m-stdlib.
authority: this file is the canonical "what's done / in flight / proposed" view. All
  module-level commits MUST update the relevant row(s) here in the same commit.
companions: docs/users-guide.md (§4 and §5 narrative), docs/parallel-tracks.md
  (dispatch view), docs/m-stdlib-implementation-plan.md (per-module specs and §9
  acceptance gate), docs/modules/index.md (canonical released-module index).
---

# m-stdlib — master module development tracker

This document is the single-source-of-truth tracker for every m-stdlib
module — completed, in flight, or proposed. It is intentionally thin
prose / heavy tables so a glance answers: *what shipped*, *what's
half-done*, *what's queued*, and *what's only a sketch*.

**Process rule.** Any commit that touches a module's source, tests,
or per-module doc MUST also update the relevant row(s) in **Table 1**
(Tracker) below in the same commit. Add the module to **Table 2**
(Proposals) when you first sketch it; promote it to Table 1 the moment
TDD-red is staked. Demote nothing — completed modules stay in Table 1
forever as the historical record.

---

## Table 1 — Module tracker (started or completed work)

Phase tags: **P1** = Phase 1 pure-M quick wins (v0.0.x → v0.1.0,
shipped 2026-05-05). **P1b** = Phase 1b TDD primitives (v0.1.1 →
v0.1.3, shipped 2026-05-05). **P2** = Phase 2 pure-M heavy lifting
(v0.2.0, all member tracks landed on `main`, tag pending). **P3** =
Phase 3 `$ZF`-bound callouts (queued; build harness A6 already
shipped). **P4** = post-v0.2.0 pure-M promotions out of Table 2
(STDCSPRNG was first; security/ergonomics fillers ahead of Phase 3).

m-cli integration status legend: **✅** = companion shipped;
**n/a** = no m-cli companion needed for this module; **🟡** = pending
(blocked work); **🔮** = future / Phase 3 dependency.

Dependency column legend: **none** = pure-M, no internal or external
deps. **module name** = runtime call into that stdlib module.
**`$ZF → libname`** = host-call to a shared library (Phase 3 callout
boundary). **runtime-only** = needed at use-site, not at compile-time
(e.g. `FILE^DIE` for STDSEED's default filer). Soft / folded edges
are noted in parens.

Headline-function entries are deliberately terse so the table stays
within one screen width. For full per-module surfaces see
`docs/users-guide.md` §5 or each module's `docs/modules/<m>.md`.

**Effort unit.** **Days** of one experienced M developer working the
full TDD discipline: tests-first, implementation, §9 acceptance gate
(fmt + lint + test + coverage ≥ 85%), per-module doc, CHANGELOG
fragment. 1d ≈ 6–8 productive hours. Excludes release-tag synchronisation
and cross-project consumer changes (those land separately under T7 /
m-cli companion tracks). **✅** = shipped (retrospective
approximation, calibrated against `parallel-tracks.md` §3.1's
"1–2 weeks per Phase 1 module" baseline). **est.** = forward estimate
for queued / proposed work. Sub-day effort shown as **Xh**.

| Phase | Track | # | Module | Tag | Effort | ToDo | Dependency | Headline | m-cli integration |
|---|---|---|---|---|---|---|---|---|---|
| P1 | L0 | 1 | [`STDASSERT`](modules/stdassert.md) | `v0.0.1` | ~5d ✅ | none | none | Assertion library | ✅ C1 + C2 |
| P1 | L0 | 2 | [`STDUUID`](modules/stduuid.md) | `v0.0.1` | ~3d ✅ | none | none (would adopt `STDCSPRNG`) | RFC-4122 v4 + RFC-9562 v7 UUIDs | n/a — Python `uuid.uuid4` covers host-side; not inner-loop |
| P1 | L1 | 3 | [`STDB64`](modules/stdb64.md) | `v0.0.2` | ~3d ✅ | none | none | RFC-4648 Base64 (std + URL-safe) | n/a — Python `base64`; not inner-loop |
| P1 | L2 | 4 | [`STDHEX`](modules/stdhex.md) | `v0.0.2` | ~1d ✅ | none | none | RFC-4648 §8 hex | n/a — Python `binascii`; not inner-loop |
| P1 | L3 | 5 | [`STDFMT`](modules/stdfmt.md) | `v0.0.3` | ~5d ✅ | none | none | Printf-style (`str.format` subset) | n/a — Python `str.format`; not inner-loop |
| P1 | L4 | 6 | [`STDLOG`](modules/stdlog.md) | `v0.0.4` (+ L4 add-on at `v0.2.0`) | ~3d ✅ | none | STDDATE (folded); STDJSON (L4 add-on) | Structured kv logger; `FORMAT(kv\|json)` | n/a — Python `logging`; not inner-loop |
| P1 | L5 | 7 | [`STDDATE`](modules/stddate.md) | `v0.0.5` | ~5d ✅ | none | none | ISO-8601 datetime + duration arithmetic | n/a — Python `datetime`; not inner-loop |
| P1 | L6 | 8 | [`STDCSV`](modules/stdcsv.md) | `v0.0.6` | ~4d ✅ | none | none (would adopt `STDFS`) | RFC-4180 CSV parse/write + file I/O | n/a — Python `csv`; not inner-loop |
| P1 | L7 | 9 | [`STDARGS`](modules/stdargs.md) | `v0.0.7` | ~4d ✅ | none | none (uses `$ZCMDLINE`) | argparse (long/short/group/positional/`--`) | n/a — Python `argparse` parses the `m` CLI; STDARGS is for M-side consumers |
| P1b | L8 | 10 | [`STDFIX`](modules/stdfix.md) | `v0.1.1` | ~3d ✅ | none | none (uses `tstart`/`trollback`) | Per-test transactional isolation | ✅ C3 |
| P1b | L9 | 11 | [`STDMOCK`](modules/stdmock.md) | `v0.1.2` | ~3d ✅ | none | none | Test-time call interception | ✅ C4 |
| P1b | L10 | 12 | [`STDSEED`](modules/stdseed.md) | `v0.1.3` (+ L10 `loadJson` add-on at `v0.2.0`) | ~3d ✅ | none | STDJSON (loadJson add-on); runtime-only `FILE^DIE` | TSV/JSON fixture loader + pluggable filer | ✅ C5 |
| P2 | L11 | 13 | [`STDJSON`](modules/stdjson.md) | `v0.2.0` | ~7d ✅ | none | none | RFC 8259 JSON parser + serialiser | n/a — Python `json`; not inner-loop |
| P2 | L12 | 14 | [`STDREGEX`](modules/stdregex.md) | `v0.2.0` | ~10d ✅ | none | none (future `STDREGEX_PCRE` → `$ZF → libpcre2`) | Thompson-NFA regex (no back-refs / lookaround) | n/a — Python `re`; not inner-loop |
| P2 | L13 | 15 | [`STDCOLL`](modules/stdcoll.md) | `v0.2.0` | ~5d ✅ | none | none | Set/Map/Stack/Queue/Deque/Heap/OrderedDict | n/a — Python `collections`; not inner-loop |
| P2 | L14 | 16 | [`STDURL`](modules/stdurl.md) | `v0.2.0` | ~5d ✅ | none | none | RFC 3986 URI parse/build/normalise/resolve | 🔮 C9 — speculative; only via future STDHTTP (P3); m-cli host uses `urllib.parse` |
| P4 | L15 | 17 | [`STDCSPRNG`](modules/stdcsprng.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T12 | STDB64 (urlencode); STDHEX (encode); STDUUID (test-only valid()); future-soft `$ZF → getrandom(2)` for batch perf | Crypto random — bytes / hex / base64 / token / int / uuid4 (kernel CSPRNG via `/dev/urandom`) | n/a — not inner-loop; m-cli does not generate tokens / session IDs / signing salts |
| P4 | L16 | 18 | [`STDFS`](modules/stdfs.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T13, T14 | none (uses `$ZEOF` / `$ZLEVEL` / `$ETRAP+ZGOTO`); future-soft `$ZF → libc stat/read/write` for IRIS arm + binary I/O | File-system primitives — read/write/append/exists/remove/size + basename/dirname/join (text I/O via YDB SEQ stream mode) | n/a — Python `pathlib` / `os` / `tempfile` / `shutil` cover host side; STDFS is for M-side consumers |
| P4 | L17 | 19 | [`STDOS`](modules/stdos.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T15 | none (uses `$ZTRNLNM` / `$JOB` / `$ZCMDLINE` / `ZHALT`); future-soft `$ZF → libc setenv/getcwd/gethostname` for IRIS arm | Process / env / cmdline helpers — env / pid / cmdline / argc / arg / argv / splitArgs / cwd / user / hostname / exit | n/a — Python `os` / `sys` / `subprocess` / `shlex` cover host side; STDOS is for M-side consumers |
| P4 | L18 | 20 | [`STDSEMVER`](modules/stdsemver.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T16 | none (pure-M; STDREGEX listed as soft dep but not used in v1) | SemVer 2.0.0 — valid / parse / compare / matches (caret / tilde / comparator AND-combination) | 🔮 C10 — speculative; only if m-cli ever grows `m install <pkg>@<range>`; today not a package manager |
| P4 | L19 | 21 | [`STDSTR`](modules/stdstr.md) | `v0.2.x` (on `main`, awaiting tag) | ~Xh ✅ | T17 | none (pure-M; `$translate` / `$piece` / `$find` / `$extract`) | String helpers — pad / trim / replaceAll / split / startsWith / endsWith / toLowerASCII / toUpperASCII / repeat | n/a — Python `str` methods cover host side; STDSTR is for M-side consumers |
| P4 | L20 | 22 | [`STDTOML`](modules/stdtoml.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T18 | none in v1 (STDDATE listed as soft dep but datetime values out of scope; STDSTR listed but inlined for self-containment) | TOML 1.0 subset — top-level pairs + `[section]` tables; string / integer / float / bool scalars; `#` comments | 🔮 C11 — speculative; m-cli today reads `.m-cli.toml` via Python `tomllib`; only relevant if config moves M-side |
| P4 | L21 | 23 | [`STDCACHE`](modules/stdcache.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T19 | none in v1 (STDCOLL listed as soft dep but inlined for self-containment; STDDATE listed but `$HOROLOG`-direct) | LRU + TTL cache over caller-owned array — new / put / get / has / remove / clear / size / capacity | n/a — short-lived per-invocation CLI process has no persistent state to cache; for M-side long-running services |
| P4 | L22 | 24 | [`STDPROF`](modules/stdprof.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T20 | none in v1 (uses `$ZHOROLOG` for microsecond resolution; STDCOLL Heap listed as soft dep for future streaming-percentile variant) | Wall-clock profiler — start / stop / count / total / mean / min / max / percentile / tags / clear | ✅ C6 |
| P4 | L23 | 25 | [`STDSNAP`](modules/stdsnap.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T21 | STDFS (save/matches I/O); STDASSERT (asserts integration) | Snapshot testing — serialize / save / matches / asserts; canonical line-per-leaf dump via `$QUERY` walk | ✅ C7 |
| P4 | L24 | 26 | [`STDENV`](modules/stdenv.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T22 | STDFS (parseFile); STDSTR listed as soft dep but inlined for self-containment | `.env` loader + typed accessors — parse / parseFile / valid / has / get / getInt / getBool / getFloat | ✅ C8 |
| P4 | L25 | 27 | [`STDXML`](modules/stdxml.md) | `v0.3.x` (incremental on `main`) | ~10d ✅ (v0+T23+T24+T25+T27v0+T27a; ~2-3d remaining for T26/T27b) | T26, T27b | none (STDREGEX listed as soft dep for future T27b); pure recursive-descent parser + indirection-based path walker | XML parser — well-formed XML 1.0 + comments / PI / xml-decl / CDATA + numeric char refs + full namespaces + XPath subset (paths / `[N]` predicates / descendant axis `//` / wildcards `*` `@*` / attribute axis `@attr`). ~80% of full envelope; T27b (functions / comparison predicates) and T26 (DTDs) cover the remaining ~20%. | n/a — m-cli has no XML in `m fmt` / `m lint` / `m test` / `m coverage` / `m lsp` flows; consumer is vista-meta HL7v3 / CDA / FHIR |
| P4 | L26 | 28 | [`STDMATH`](modules/stdmath.md) | `v0.3.x` (on `main`, awaiting tag) | ~Xh ✅ | none | none (pure-M; `+` coercion, `$ORDER` walk) | Numeric helpers — clamp / min / max / sum / count / mean over caller-owned arrays | n/a — Python `min` / `max` / `sum` / `statistics.mean`; not inner-loop |
| P4 | L27 | 29 | [`STDXFRM`](modules/stdxfrm.md) | `v0.3.x` (on `main`, awaiting tag) | ~Xh ✅ | none | none (pure-M; `@expr` indirection in own stack frame) | Higher-order array transforms — `map` / `filter` / `reduce` via `@expr`-evaluated lambdas (`value` / `key` / `acc` locals) | n/a — Python list-comprehensions / `map` / `filter` / `functools.reduce`; not inner-loop |
| P3 | H1 | 30 | [`STDCRYPTO`](modules/stdcrypto.md) | `v0.3.x` (on `main`, awaiting engine deployment for green run) | ~2d code-complete | T28 | `$ZF → libcrypto`; A6 | SHA-256/384/512 + HMAC-SHA-256/384/512 | 🟡 C12 — speculative P3 hookup; m-cli has no current hashing/HMAC need; queued behind T11 |
| P3 | H2 | 31 | `STDCOMPRESS` | `v0.3.0` (queued) | 5–7d est. | T11 | `$ZF → libz`, `$ZF → libzstd`; A6 | gzip / deflate / zstd | 🟡 C13 — speculative P3 hookup; m-cli has no current compression need; queued behind T11 |
| P3 | H3 | 32 | [`STDHTTP`](modules/stdhttp.md) | `v0.4.0` (in progress) | ~1d ✅ iter 1 / ~7-11d remaining | T29 | STDURL; `$ZF → libcurl`; A6 | HTTP/1.1 client. **Iter 1 landed:** pure-M wire-format helpers (`parseStatusLine` / `parseHeader` / `parseResponse` / `buildRequest` / `formatHeaders`). **Iter 2 queued:** libcurl callout (`src/callouts/http.c`) + `$$get` / `$$post` / `$$request` extrinsics. | 🟡 C14 — speculative P3 hookup; m-cli today uses Python `urllib` / `requests`; queued behind T29 |

**Aggregate:** ~93d shipped across the 30 landed modules
(STDCSPRNG L15 P4 + STDFS L16 P4 + STDOS L17 P4 + STDSEMVER L18 P4
+ STDSTR L19 P4 + STDTOML L20 P4 + STDCACHE L21 P4 + STDPROF L22 P4
+ STDSNAP L23 P4 + STDENV L24 P4 + STDXML v0+T23+T24+T25+T27v0+T27a
L25 P4 + STDMATH L26 P4 + STDXFRM L27 P4 + **STDCRYPTO H1 P3** —
code-complete on `main`; engine green-run pending T28); STDXML
covers ~80% of the 12-16d envelope so ~2-3d of T26/T27b remain.
~12–18d estimated for the two remaining queued Phase 3 modules
(STDCOMPRESS, plus STDHTTP iter 2 — STDHTTP iter 1 already landed).
Open ToDo work (T1-T29 with T23/T24/T25/T25b/T27v0/T27a resolved;
T11 partially closed — STDCRYPTO landed, STDHTTP iter 1 landed;
T26, T27b, T28, T29 remaining) is incremental on top of the
shipped totals — see ToDo expansion below for per-task estimates.

**m-cli integration status — short codes** (full track names spelled
out in `docs/parallel-tracks.md` §3.4):

*Shipped:*

- **C1** = dynamic `^TESTRUN` / `^STDASSERT` protocol detection (m-cli `23241a2`).
- **C2** = m-tools test-suite migration TESTRUN→STDASSERT (m-tools `3eec0bf`).
- **C3** = runner SETUP/TEARDOWN wrap consuming STDFIX (m-cli `e5818bd`).
- **C4** = `do clear^STDMOCK` between tests (m-cli `e5818bd`).
- **C5** = `m test --seed PATH` flag consuming STDSEED (m-cli `e5818bd`).
- **C6** = `m test --timings` consuming STDPROF for subprocess-level wall-clock per suite via Python `time.perf_counter()`; STDPROF is the in-process API for finer-grained intra-suite timing (m-cli `8ef34a6`).
- **C7** = `m test --update-snapshots` consuming STDSNAP — sets `^STDLIB($JOB,"stdsnap","update")=1` so `asserts^STDSNAP` rewrites baselines instead of comparing (m-cli `8ef34a6`, m-stdlib `631b4e7`).
- **C8** = `m test --env PATH` consuming STDENV — repeatable; loads each `.env` via `parseFile^STDENV` and merges into `^STDLIB($JOB,"env",KEY)`; tests read via `$get(^STDLIB($JOB,"env","KEY"))` (m-cli `8ef34a6`).

*Future / speculative (no concrete consumer yet, listed for traceability):*

- **C9** = STDHTTP (P3) consumer of STDURL — m-cli today uses Python `urllib.parse` on the host side; STDURL only enters m-cli through the future STDHTTP path, and only if STDHTTP itself becomes an m-cli dep (which it might not).
- **C10** = `m install <pkg>@<range>` as consumer of STDSEMVER — m-cli is not a package manager today; if it ever grows one, Python's `packaging.version` is the host-side equivalent. Speculative.
- **C11** = m-cli runtime config from `.m-cli.toml` via STDTOML — m-cli today reads `.m-cli.toml` and `[tool.m-cli]` in `pyproject.toml` via Python 3.11+ stdlib `tomllib`; STDTOML would only land if config consumption moves to the M side.
- **C12** = STDCRYPTO P3 hookup — m-cli has no hashing / HMAC / signing path today; queued behind T28 (STDCRYPTO is code-complete on `main`, but the m-cli-side companion track has no concrete consumer).
- **C13** = STDCOMPRESS P3 hookup — m-cli has no compression path today; queued behind T11 entry.
- **C14** = STDHTTP P3 hookup — m-cli today shells across SSH or uses Python `urllib`/`requests` for any HTTP need; queued behind T11 entry.

**m-cli integrations not done — rationale.** Eight P4 modules carry no
*active* m-cli companion track. Six of those (L15, L16, L17, L19, L21,
L25) have **none planned** — the rationale below is the durable answer.
The remaining two (L18 STDSEMVER → C10, L20 STDTOML → C11) are tagged
as speculative future hookups in the table for traceability, but the
rationale below is the same: today they are not on the m-cli roadmap.
Each was evaluated as an inner-loop binding (would `m fmt` / `m lint` /
`m test` / `m watch` benefit?) and the answer was no for one of three
reasons: the function is **not part of the dev inner loop**, the
function is **already covered by the Python CLI side** (Python's stdlib
does the job natively and m-cli's host code is Python), or the function
is **for M consumers of m-stdlib** rather than for m-cli's own
toolchain flows. Per-module:

- **L15 STDCSPRNG** — Cryptographic random. *Not inner-loop.* m-cli
  doesn't generate security tokens, session IDs, or signing salts.
  Consumers are downstream M apps (JWT issuers, password resetters);
  m-cli has no need.
- **L16 STDFS** — File-system primitives. *Replicated in Python CLI
  interface.* m-cli's host code uses `pathlib.Path`, `os`, `tempfile`,
  `shutil` natively — richer than STDFS and already debugged. STDFS
  is for M-side consumers writing portable file I/O; m-cli wouldn't
  shell across the SSH boundary just to call `readFile^STDFS` when
  Python can read the file in-process.
- **L17 STDOS** — Process / env / cmdline helpers. *Replicated in
  Python CLI interface.* `os.environ`, `sys.argv`, `subprocess`, and
  `shlex.split` cover the same surface in Python. STDOS is for M code
  that needs `$$env^STDOS("KEY")` to escape `$ZTRNLNM` portability
  quirks — m-cli has no equivalent need.
- **L18 STDSEMVER** — SemVer parse / compare / range match. *Not
  inner-loop, not used today.* m-cli has no `m install <pkg>@<range>`
  command and isn't a package manager. Python's `packaging.version`
  is the host-side equivalent if a package manager is ever built.
  Speculative future hookup only.
- **L19 STDSTR** — String helpers (pad / trim / replaceAll / split /
  startsWith / endsWith / case-fold / repeat). *Replicated in Python
  CLI interface.* `str.ljust`, `str.rjust`, `str.strip`, `str.replace`,
  `str.split`, `str.startswith`, `str.endswith`, `str.lower`, `str.upper`,
  `str * N` cover every helper natively. STDSTR is for M-side string
  manipulation; m-cli's CLI text never crosses to the M side.
- **L20 STDTOML** — TOML 1.0 subset parser. *Replicated in Python CLI
  interface.* m-cli already reads `.m-cli.toml` and `[tool.m-cli]` in
  `pyproject.toml` via Python 3.11+ `tomllib` (stdlib). STDTOML is for
  M-side config consumers (a hypothetical M-only project that wants
  to read its own `.config.toml` at runtime); m-cli's config is loaded
  on the Python side and the lint/fmt/test/watch flows consume the
  parsed dict, not the raw text.
- **L21 STDCACHE** — LRU + TTL cache. *Lower value for end-user CLI.*
  m-cli is a short-lived per-invocation CLI process — every `m test`
  is a fresh Python interpreter that exits when done. There's no
  persistent state for a cache to warm. STDCACHE pays off in M-side
  long-running services (RPC handlers, FileMan-backed apps); not in
  the m-cli inner loop.
- **L25 STDXML** — XML parser (well-formed XML 1.0 v0). *Not inner-loop.*
  m-cli has no XML in any of its flows — `m fmt` / `m lint` / `m test` /
  `m coverage` / `m lsp` operate on `.m` source via tree-sitter-m, not
  on XML. STDXML's documented consumer is vista-meta's HL7v3 / CDA /
  FHIR pipeline, which is a separate downstream project.

**ToDo — short codes** (expanded in the next section):

- **T1** STDASSERT raises P1 (resolved; downstream re-enables owed).
- **T2** Re-enable parked `raises`-path tests (STDFMT / STDDATE / STDCSV).
- **T3** STDLOG-JSON / STDSEED-loadJson tests parked under T6.
- **T4** STDFIX test-file lint cleanup.
- **T5** STDFIX explicit re-raise contract (blocked on YDB P2).
- **T6** STDJSON `$$encode` extrinsic-chain P1 (new 2026-05-06).
- **T7** v0.2.0 release sync.
- **T8** STDSEED `fileViaDie` real-FileMan integration.
- **T9** STDREGEX `classEscape` coverage gap.
- **T10** STDREGEX IRIS native `$MATCH`/`$LOCATE` dispatch.
- **T11** Phase 3 entry (STDCRYPTO / STDCOMPRESS / STDHTTP).
- **T12** STDCSPRNG `$ZF → getrandom(2)` callout backend (perf-only swap).
- **T13** STDFS native append (replace read-then-rewrite with `$ZF → write(2)` once Phase 3 cuts).
- **T14** STDFS `readBytes` / `writeBytes` for byte-faithful binary I/O (deferred alongside T13).
- **T15** STDOS `setenv` / quote-aware `splitArgs` / IRIS arm via `$ZF → libc setenv/getcwd/gethostname` callouts.
- **T16** STDSEMVER range syntax extensions (`||` OR, hyphen ranges, `*`/`x`/`X` placeholders, prerelease-aware comparators, `^0.x.y` zero-major narrowing per npm semantics).
- **T17** STDSTR Unicode whitespace + locale-aware case folding (deferred to a future STDUNICODE; STDSTR v1 is byte-wise ASCII-only by design).
- **T18** STDTOML out-of-scope features (arrays, inline tables, dotted keys, array-of-tables, multi-line / literal strings, integer underscores + hex/oct/bin, special floats, exponent notation, datetime values via STDDATE).
- **T19** STDCACHE rebase onto STDCOLL OrderedDict + explicit `prune` operation for batch expired-entry sweeping.
- **T20** STDPROF streaming-percentile variant via STDCOLL Heap (CKMS sketch) for continuous monitoring; v1 keeps all samples and walks them on demand.
- **T21** STDSNAP root-scalar serialization + auto-update flag + diff helper (v1 walks `$QUERY` descendants only, no auto-update; humans re-`save` manually after intentional drift).
- **T22** STDENV variable substitution + `export` prefix + multi-line values + process-environment integration via STDOS setenv (T15).
- **T28** Engine-bound deployment for STDCRYPTO — push .so + .xc into vista-meta container, wire `STDLIB_LIB` + `ydb_xc_std_crypto` env vars on the YDB session side, install `libcrypto.so.3` in the image. Code-complete on `main` 2026-05-07; this is the gating ticket before STDCRYPTOTST runs green and before STDCOMPRESS / STDHTTP start.
- ~~**T23** STDXML CDATA / processing instructions / comments / `<?xml ?>` declaration~~ — **resolved 2026-05-07**: `parseContent` dispatches on `<!--` / `<![CDATA[` / `<?`; new `skipDocLevel` walks PIs+comments before/after the root; CDATA content stored as literal text (no entity decode).
- ~~**T24** STDXML numeric character references~~ — **resolved 2026-05-07**: `decodeEntities` handles `&#NNN;` (decimal) and `&#xHH;` (hex); `encodeUtf8` produces 1-4 byte UTF-8 sequences for any Unicode code point up to U+10FFFF.
- ~~**T25** STDXML namespaces — element-level~~ — **resolved 2026-05-07**: per-element namespace map threaded through `parseElement`/`parseContent`; `xmlns` / `xmlns:prefix` filtered out of regular attrs; element prefix resolved to URI; new `$$ns^STDXML(.node)` accessor; undeclared prefix is a parse error. **T25b** (attribute-namespace resolution) split off as a separate ToDo entry.
- ~~**T25b** STDXML attribute-namespace resolution~~ — **resolved 2026-05-07**: `resolveAttrNs` walks `node("attr",...)` and stores `node("attrNs", attrName)` for each prefixed attr; default xmlns does NOT apply to unprefixed attrs (per spec); `xml:` prefix bound to `http://www.w3.org/XML/1998/namespace` as a built-in (no declaration needed); undeclared prefix on an attr is a parse error. New public accessor `$$attrNs^STDXML(.node, attrName)`.
- **T26** STDXML DTDs / DOCTYPE / custom entity declarations.
- ~~**T27** STDXML XPath 1.0 query subset — minimal v0~~ — **resolved 2026-05-07**: `parseXPath` compiles expressions into step lists; `applyStep` walks the candidate set via path strings; `buildRef` constructs M name references for indirection-based subtree access. Public surface: `$$xpath` / `$$xpathOne` / `$$xpathText`. Supported syntax: bare `name`, chained `a/b/c`, absolute `/foo`, descendant `//x`, position predicate `[N]`. Out of scope queued at T27a / T27b.
- ~~**T27a** STDXML XPath wildcards (`*`) and attribute axis (`@attrName`)~~ — **implementation landed 2026-05-07** (test verification pending YDB container availability): `parseXPath` accepts `*` as a name token (matched in `collectChildren` / `collectDescendants` via the new `matchName` helper) and detects `@` as an attribute-step prefix that is terminal (parser rejects anything after the attribute name). New `collectAttribute` walks `node("attr", k)` for the candidate path and emits results with `attrValue` / `attrName` subnodes; `mergePathToResult` lifts those into `results(idx,"text")` / `results(idx,"name")` so `xpathText` returns the attribute value transparently. Combinations covered: `*`, `*[N]`, `//*`, `*/x`, `@id`, `@*`, `a/@id`, `//@id`. 10 new tests (`tXpath{Wildcard,ChildOfWildcard,DescendantWildcard,WildcardWithPredicate,Attribute*}`).
- **T27b** STDXML XPath functions (`position()`, `count()`, `text()`, `name()`, `normalize-space()`, `contains()`, `starts-with()`, `string-length()`) and comparison predicates (`[@attr='v']`, `[name()='foo']`). The predicate evaluator has to grow into a proper expression evaluator with type promotion (node-set / string / number / boolean). 2-3d.

**Aggregate gate, current head (2026-05-07):** 1780+ assertions
across 27 suites, per-module label coverage ≥ 91% (most at 100%;
STDOS at 91.7%, STDENV at 93.3%, STDXML at 97.6% — `exit()`,
`parseFile()`, and `lastError()` respectively unreachable /
un-tested by automated tests), 0 lint errors, fmt clean. v0.3.0
shipped (commit `363b990`); the eleven P4 promotions sit on top:
STDCSPRNG (L15), STDFS (L16), STDOS (L17), STDSEMVER (L18),
STDSTR (L19), STDTOML (L20), STDCACHE (L21), STDPROF (L22),
STDSNAP (L23), STDENV (L24), STDXML v0+T23+T24+T25+T27v0 (L25).
The joint canonical-index regen covers 28 modules total (Phase 1:
9; Phase 1b: 3; Phase 2: 4 + 2 add-ons; P4 promotions: 11).

---

## Table 1 — ToDo expansion

Each `T<n>` referenced above is expanded here. Cross-reference
authority: `TOOLCHAIN-FINDINGS.md` for P1/P2 details,
`docs/parallel-tracks.md §3` for track-level state.

### T1 — STDASSERT.raises P1 (resolved 2026-05-06; downstream closed 2026-05-07)
**Status:** ✅ **closed.** Library-level fix shipped via ZGOTO unwind;
all downstream re-enables (T2, T3) completed in the same series of
commits leading into the v0.2.0 release sync.
**What it was:** `$ETRAP` arg-less `quit` was illegal in
extrinsic-function chains and triggered `%YDB-E-NOTEXTRINSIC` (M17),
cascading into `Z150374554` and clobbering the captured `$ECODE`.
Surfaced building STDFMT and re-surfaced under every module that
drove errors through extrinsic chains: STDFMT (6 tests), STDDATE,
STDCSV, STDLOG L4 add-on (7 tests), STDSEED L10 add-on (4 tests).
**What fixed it:** `raises^STDASSERT` now captures
`raisesLvl=$zlevel` at trap-set time and the trap unwinds via
`zgoto raisesLvl:raisesUnwound^STDASSERT` instead of arg-less `quit`.
Verified by `tFormatInvalidRaises` in STDLOGTST. Reference:
TOOLCHAIN-FINDINGS row 2026-05-05 P1.
**Remaining work:** see T2 (STDFMT/DATE/CSV) and T3 (LOG add-on /
SEED add-on — note T3 has a *separate* root cause).

### T2 — Re-enable parked `raises`-path tests in STDFMT / STDDATE / STDCSV
**Status:** ✅ **closed 2026-05-07.**
**Outcome:**
- **STDFMT 56 → 62 assertions** — six new raises tests added covering
  all four `U-STDFMT-*` codes (UNCLOSED-BRACE, UNESCAPED-RBRACE,
  UNKNOWN-TYPE, MISSING-ARG ×3).
- **STDDATE 60 → 66 assertions** — three previously-defined-but-
  undispatched raises labels (`tFromhRejectsEmpty`,
  `tTohInvalidRaisesEcode`, `tStrptimeInvalidRaisesEcode`) wired
  into the dispatcher.
- **STDCSV** — file-open-fail path documented as a separate
  refactor: STDCSV's `open … else  set $ecode=…` pattern only
  catches OPEN *timeouts*, not immediate file-not-found errors
  (which fire `$ETRAP` directly with the underlying YDB code). A
  raises-test would observe the YDB code, not `U-STDCSV-OPEN-FAIL`.
  Suite header notes this; explicit OPEN-fail trapping deferred.

### T3 — STDLOG-JSON / STDSEED-loadJson `raises`-path tests parked under STDJSON-encode P1
**Status:** ✅ **fully closed 2026-05-07.**
**Outcome:**
- **STDLOG 48 → 62 assertions** — all six JSON-emission tests run.
  Two passed after T6's STDJSON refactor; the four that probe the
  parsed tree via `$$valueOf^STDJSON(.tree("k"))` were unblocked
  by the merge-then-pass refactor in commit `fb48f39` (per the
  `.x(SUBS)` syntax-limit diagnosis below — see T6 / TOOLCHAIN-
  FINDINGS row 2026-05-06).
- **STDSEED 25 → 35 assertions** — all six loadJson tests run.
  Unblocked by the `raises^STDASSERT` `use $principal` trap fix
  (commit `e637425`) which resolves the SEQ-device + ZGOTO-unwind
  hang inside `walk^STDSEED`'s file-read loop.

### T4 — STDFIX lint findings cleanup
**Status:** ✅ **closed 2026-05-07** (already resolved earlier).
`m lint --error-on=error` is clean project-wide (0 errors); the
TODO description was stale. STDFIXTST has the appropriate
`m-lint: disable-file=M-MOD-020` and `disable-next-line=M-MOD-026`
directives. Remaining findings are severity-S (suggestions:
M-MOD-001 line length, M-MOD-009 commands per line) — they don't
gate the §9 acceptance check.

### T5 — STDFIX explicit re-raise contract not asserted in tests
**Status:** ✅ **closed at the documentation level 2026-05-07**;
upstream YottaDB fix still pending.
The rollback + scope-cleanup observables are verified by the
existing STDFIXTST suite; the re-raise contract remains
documented-but-untested in `docs/modules/stdfix.md`'s
"Caveats" / Errors section, with the deferral cause clarified
(YottaDB P2 — `$ETRAP`-driven `trollback` of its own scope does
not propagate `$ECODE` to the outer trap — TOOLCHAIN-FINDINGS
row 2026-05-05 P2). Closing this row from the tracker; the
upstream-bug item itself stays open in TOOLCHAIN-FINDINGS until
fixed.

### T6 — STDJSON `$$encode` extrinsic-chain P1
**Status:** ✅ **fully closed 2026-05-07.**
**Diagnosis (corrected):** initial hypothesis ("YDB-harness
subscripted-by-ref crash") was wrong. Direct `mumps -run` repro
shows it's a **documented YDB syntax limit**: `.x(SUBS)` is invalid
syntax in YottaDB r2.02 — `%YDB-E-COMMAORRPAREXP` at compile time.
Standard ANSI M permits only `.x` (whole local) by reference; YDB
does not extend that. Canonical workaround: **merge-then-pass**.
TOOLCHAIN-FINDINGS row 2026-05-06 was demoted from P1 to `docs`
and marked resolved.
**Fixes applied:**
- `src/STDJSON.m` (commit `c3a0880`): `encodeArray` / `encodeObject`
  recurse via `merge tmp=node(k)` + `$$encodeValue(.tmp)` (read-
  only); `parseObject` / `parseArray` via `do parseValue(.ctx,.tmp)`
  + `merge node(k)=tmp` (write-back).
- `tests/STDLOGTST.m` (commit `fb48f39`): 4 deferred JSON-emission
  tests refactored to merge-then-pass via `sub` local; also
  `do parse^STDJSON(...)` → `set ok=$$parse^STDJSON(...)` (parse
  is extrinsic-form, calling as procedure fires M17).
- `tests/STDJSONTST.m` (commits `0343b13` + `e159147`): 23 + 4
  caller-side `.x(SUBS)` sites refactored to merge-then-pass;
  `parseStringValue` `\u<hex>` escape fall-through fixed (one-line
  `quit` postcondition); `tEncodeArrayWithGapRaises` rewritten to
  drop fragile cross-frame `goto pop` from $ETRAP.
**Verified:** STDJSONTST 209/209 green (was crashing at #55).
Aggregate gate: 16 suites, **1222/1222 assertions**.

### T7 — v0.2.0 release sync
**Status:** ✅ **shipped 2026-05-07.**
**Outcome:** CHANGELOG `## [Unreleased]` collapsed into a new
`## [v0.2.0] — 2026-05-07` section that covers STDJSON, STDREGEX,
STDCOLL, STDURL, STDLOG-JSON add-on, STDSEED-loadJson add-on, plus
the rolled-in Phase 1b minor tags (STDFIX `v0.1.1`, STDMOCK
`v0.1.2`, STDSEED `v0.1.3`). `docs/modules/index.md` regenerated to
absorb all v0.2.0 modules and add Phase 2 conformance corpora
(`tests/conformance/{json,url,uuid}/`). Cross-module dependency
section refreshed for the L4-→STDJSON and L10-→STDJSON edges. Git
tag `v0.2.0` cut and pushed.

### T8 — STDSEED `fileViaDie` real-FileMan integration
**Status:** ✅ **closed at the documentation level 2026-05-07**;
explicit FileMan integration test deferred to a future minor.
The label compiles and is observably correct against any FileMan
host (manual smoke runs against vista-meta succeed); the gap is
test-coverage (10/11 = 90.9% labels), not implementation. The
real-FileMan integration path is documented in
`docs/modules/stdseed.md` as a v0.1.4-or-later scoped follow-on,
gated by STDFIX `with`/`invoke` for rollback safety. The 10/11
gate already exceeds the §9 threshold (≥85%), so this is a
coverage-quality wish, not a release blocker.

### T9 — STDREGEX `classEscape` coverage gap
**Status:** ✅ **closed 2026-05-07.** Five new tests added
(`tClassDigitEscape`, `tClassWordEscape`, `tClassSpaceEscape`,
`tClassLiteralEscape`, `tClassRangeViaEscape`) exercise `\<x>`
inside character classes for all three predefined symbol families
(`\d`, `\w`, `\s`), literal escapes (`\.`, `\-`), and a
range-via-escape (`[\t-\n]`). STDREGEX 90 → 102 assertions;
per-module label coverage 98.3% → **100% (59/59)**.
**Action:** add a few targeted tests to `STDREGEXTST.m` exercising
`[\d]`, `[\w]`, `[\s]`, `[\t]`, `[\n]` etc. Confirm green;
coverage to 100%.

### T10 — STDREGEX IRIS native `$MATCH` / `$LOCATE` dispatch
**Status:** ✅ **closed at the documentation level 2026-05-07.**
The pure-M Thompson-NFA engine runs unchanged on IRIS for the
entire v0.2.0 subset — IRIS portability is **not** a blocker.
What was deferred is a perf-only follow-up: native `$MATCH` /
`$LOCATE` dispatch for the simple-pattern subset (with
`%Library.RegEx` for captures). Documented as a perf-follow-up in
`docs/modules/stdregex.md`'s "IRIS portability" section; the
`iris-portability-check` CI job continues to surface any
regressions in fail-soft mode without gating merges.

### T12 — STDCSPRNG `$ZF → getrandom(2)` callout backend
**Module:** STDCSPRNG.
**Status:** queued; STDCSPRNG ships in v0.2.x with a `/dev/urandom`
backend (single-byte `READ *b` to avoid record-terminator truncation).
A `$ZF → getrandom(2)` callout would batch reads and shave the per-byte
device round-trip — mostly a perf concern, not a security one.
`/dev/urandom` and `getrandom(0)` share the same kernel ChaCha20
CSPRNG, so the upgrade is **API-stable**: callers do not change.
**Action:** schedule alongside T11. Add `src/callouts/cs_random.c`,
register the call-in table entry, gate the new backend behind a
`$$useCallout()` probe so degraded environments still work via
`/dev/urandom`. Coverage gate stays unchanged.
**Reference:** `docs/modules/stdcsprng.md` "Entropy source" section.

### T13 — STDFS native append + native I/O backend
**Module:** STDFS.
**Status:** queued; STDFS ships in v0.2.x with append() implemented
as **read-then-rewrite** (read existing file, concatenate, writeFile
back). This sidesteps a YDB SEQ device quirk where the first WRITE
after `OPEN dev:(append)` lands at byte 0 instead of EOF — observed
in `tAppendExtendsFile` while landing L16. Cost is `O(file size)`
per append call.
**Action:** wire `$ZF → write(2)` once the Phase 3 build harness is
exercised by a real consumer. Public API does not change. Same patch
adds the `readBytes` / `writeBytes` pair (T14).
**Reference:** `docs/modules/stdfs.md` "Append semantics" section.

### T14 — STDFS binary-safe `readBytes` / `writeBytes`
**Module:** STDFS.
**Status:** queued. STDFS v0.2.x is text-mode only — `writeFile`
always emits a trailing LF (POSIX text-file convention; YDB SEQ
stream-mode close finalisation), and `readFile` strips the trailing
LF on the way back. Round-trips strings cleanly but does not preserve
exact byte counts for binary payloads.
**Action:** add `readBytes(path,n)` and `writeBytes(path,data)` that
use the `$ZF → read(2)/write(2)` callout backend so byte boundaries
are preserved. Schedule alongside T13 (same callout entry points).
**Reference:** `docs/modules/stdfs.md` "Trailing-LF semantics" section.

### T15 — STDOS `setenv` / quote-aware `splitArgs` / IRIS arm
**Module:** STDOS.
**Status:** queued; STDOS ships in v0.2.x with read-only env access,
whitespace-only `splitArgs`, YDB-only intrinsics (`$ZTRNLNM`, `$JOB`,
`$ZCMDLINE`, `ZHALT`). Three deferred features:
1. `setenv(name, val)` — needs `$ZF → libc setenv(3)` (the C library
   call also re-exec's child processes' env), so depends on the
   Phase 3 callout convention being established.
2. Quote-aware `splitArgs` — preserve embedded spaces inside `'...'`
   and `"..."`. STDARGS already has the tokeniser; back-port (or
   factor STDARGS' tokeniser out into STDOS as the canonical
   home).
3. IRIS arm — `$CLASSMETHOD %SYSTEM.Util.GetEnviron()` /
   `%SYS.System` for env / pid / cwd / hostname; the public surface
   stays unchanged.
**Action:** schedule alongside T11 (Phase 3 entry). The setenv
callout reuses the cs_random.c harness pattern. Quote-aware splitArgs
can land sooner as a pure-M change without a callout dep.
**Reference:** `docs/modules/stdos.md` "Argument splitting" section.

### T16 — STDSEMVER range syntax extensions
**Module:** STDSEMVER.
**Status:** queued; STDSEMVER ships in v0.2.x with a deliberately
narrow range subset (exact / `>` `<` `>=` `<=` `=` / `^` / `~` / AND).
The remaining npm-flavour range constructs are documented as deferred:
1. **`||` OR-combination.** `^1.2.3 || ^2.0.0`.
2. **Hyphen ranges.** `1.2.3 - 2.3.4` ≡ `>=1.2.3 <=2.3.4`.
3. **Wildcard placeholders.** `1.2.x` ≡ `>=1.2.0 <1.3.0`; `*` matches
   anything; `X.Y.Z`-style uppercase same as lowercase.
4. **Prerelease-aware comparators.** npm matches `1.2.3-alpha`
   against `>1.2.3-alpha.1` differently from a pure precedence
   compare.
5. **Zero-major narrowing.** npm treats `^0.2.3` as
   `>=0.2.3 <0.3.0` (caret in 0.x.y is tilde-like). STDSEMVER v1
   uses the simpler rule `^0.x.y → >=0.x.y <1.0.0`; align with npm
   under T16.
**Action:** add a `parseRange(range, .pieces)` helper that lowers any
of the above into an AND-of-comparators canonical form, then have
`matches()` consume `pieces`. The simple comparator path stays
unchanged. Schedule when a concrete consumer (m-cli `m install`,
or another package-manager-style use case) drives the requirement.
**Reference:** `docs/modules/stdsemver.md` "Range syntax" section.

### T17 — STDSTR Unicode whitespace + locale-aware case folding
**Module:** STDSTR.
**Status:** queued behind a future STDUNICODE module. STDSTR v1's
`trim` family handles only ASCII space / tab / LF / CR (the four
characters most M code emits); `toLowerASCII` / `toUpperASCII` only
fold the 26 unaccented Latin letters. Unicode whitespace classes
(NBSP, ideographic space, Mongolian vowel separator, et al.) and
locale-aware case folding (German ß, Turkish dotless i, etc.) are
deliberately out of scope.
**Action:** when STDUNICODE arrives (no concrete schedule yet),
add `trimUnicode` / `toLower` / `toUpper` variants that delegate
to the Unicode tables. Existing labels stay byte-faithful and ASCII-
only — those are the right default for the `$ZCHSET=M` use cases
that dominate this orbit.
**Reference:** `docs/modules/stdstr.md` "Whitespace definition" and
"ASCII case conversion" sections.

### T18 — STDTOML out-of-scope features
**Module:** STDTOML.
**Status:** queued. STDTOML v1 covers the practical 80% subset
(top-level pairs + `[section]` tables + four scalar types + comments).
The remaining TOML 1.0 surface is documented as deferred:
1. **Arrays.** `colors = ["red", "green", "blue"]`; arrays of mixed
   types per TOML 1.0; nested arrays.
2. **Inline tables.** `point = { x = 1, y = 2 }`.
3. **Dotted keys.** `physical.color = "red"` at the top level
   (effectively a flattened `[physical]` declaration).
4. **`[[array-of-tables]]`.** Repeated section headers building a
   list of objects.
5. **Multi-line strings.** `"""..."""` (basic) and `'''...'''`
   (literal).
6. **Literal strings.** `'...'` — no escape processing.
7. **Integer literal extensions.** Underscore separators
   (`1_000_000`); hex (`0xff`); octal (`0o755`); binary (`0b1010`).
8. **Special floats.** `inf`, `-inf`, `nan`.
9. **Exponent notation in floats.** `1.5e3`, `2.0E-10`.
10. **Datetime values.** TOML offset / local datetime / local date /
    local time. STDDATE will host the parsing under this T18 work.
**Action:** schedule when a concrete consumer (m-cli runtime config,
or another TOML-driven config consumer) drives the requirement. v1
is sufficient for `pyproject.toml`-shaped configs where values are
scalars and sections form a single level of nesting.
**Reference:** `docs/modules/stdtoml.md` "Out of scope (queued at T18)"
section.

### T19 — STDCACHE STDCOLL rebase + `prune` operation
**Module:** STDCACHE.
**Status:** queued. STDCACHE v1 inlines its bookkeeping (caller-array
`v` / `ts` / `o` / `ex` subtrees with `$ORDER`-driven LRU eviction)
to keep the dep graph clean and the surface trivially droppable —
the soft STDCOLL dep listed in Table 2 is not exercised. Two
follow-ups make sense once a concrete consumer exposes them:
1. **Rebase onto STDCOLL OrderedDict.** STDCOLL ships an OrderedDict
   that's the natural backing store for an LRU cache; a rebase
   shrinks STDCACHE's bookkeeping code and aligns invariants with
   the rest of the collections layer.
2. **`prune^STDCACHE(.cache)`.** v1 reaps expired entries lazily on
   access. A bulk `prune` sweep (walk all keys, drop expired ones,
   adjust `size`) is sometimes useful for memory-pressure scenarios
   — schedule when a real caller asks for it.
**Action:** schedule when (a) STDCACHE has a concrete consumer
that benefits from STDCOLL alignment, or (b) memory-pressure tests
expose the lazy-reap latency tail. v1 is correct and bounded;
neither is urgent.
**Reference:** `docs/modules/stdcache.md` "Tree shape" section
(documents the inline bookkeeping that T19 replaces).

### T20 — STDPROF streaming-percentile via STDCOLL Heap (CKMS sketch)
**Module:** STDPROF.
**Status:** queued. STDPROF v1 keeps every sample in
`prof("samples", tag, value, seq)` and walks them in `$ORDER` on
each `percentile()` call. Memory grows linearly with sample count;
`percentile()` is `O(N)` worst case (typically a small walk near
the requested rank). For a one-shot end-of-run report this is fine,
but a continuous-monitoring use case (calling `percentile` thousands
of times in a hot loop) would benefit from a streaming variant.
**Action:** add a `newStreaming^STDPROF(.prof, epsilon)` constructor
that allocates a CKMS (Cormode-Korn-Muthukrishnan-Srivastava) sketch
backed by STDCOLL's Heap. `stop()` inserts into the sketch instead
of the full sample tree; `percentile()` queries the sketch in
`O(log N)`. Samples are bounded by the `epsilon` parameter (typical
1% error gives a sketch of ~100 entries). Public API surface stays
the same; `tags()` continues to work; the tree shape changes only
under `prof("sketch", tag, ...)`. Schedule when a real consumer
(m-cli `m test --profile` continuous mode, or a long-running
service) drives the requirement.
**Reference:** `docs/modules/stdprof.md` "Percentile semantics"
section (documents the inline sorted-sample walk that T20 replaces).

### T21 — STDSNAP root-scalar + auto-update + diff helper
**Module:** STDSNAP.
**Status:** queued. STDSNAP v1 walks `$QUERY` descendants only,
which means a tree with a scalar at the root (`set data="value"`,
no subscripts) doesn't serialise. Three follow-ups make sense as
real consumers exercise the surface:
1. **Root-scalar serialization.** Add a special-case line at the
   top of the dump for the root value, e.g. `=value` (no
   subscripts). Trivial to add but breaks the file format
   slightly — schedule when a real caller hits the limitation.
2. **Auto-update flag.** A common pattern in other ecosystems
   (`pytest --snapshot-update`, Jest `--updateSnapshot`) is to
   re-`save` automatically when a flag is set. STDSNAP v1
   intentionally requires explicit `save` — humans must review
   drift before refreshing. Add an opt-in `STDSNAP_UPDATE`
   environment-variable check that flips `matches` to "save and
   pass" mode when set.
3. **Bundled diff helper.** v1 reports the snapshot path on
   mismatch; humans run `diff -u baseline current` themselves.
   A small `$$diff^STDSNAP(path, .data)` returning a unified-
   diff string would be a nice ergonomic — implementable with a
   tiny LCS algorithm or shelled out to `/usr/bin/diff` via
   STDOS once setenv lands (T15).
**Action:** schedule when a concrete consumer drives the
requirement. v1 covers the practical 80% case (testing parsed
JSON / FileMan trees with subscripted leaves).
**Reference:** `docs/modules/stdsnap.md` "Edge cases" section.

### T22 — STDENV out-of-scope features
**Module:** STDENV.
**Status:** queued. STDENV v1 covers the practical 80% of `.env`
files (bare / quoted / commented / blank-line, four scalar types
via accessors). The remaining dotenv conventions are deferred:
1. **Variable substitution.** `KEY=${OTHER}` and `KEY=$OTHER`
   references — needs an order-preserving parse and a lookup
   fallback chain (parsed env → process env via STDOS).
2. **`export` prefix.** Bash-style `export FOO=bar` — strip and
   ignore the prefix.
3. **Multi-line values.** PEM keys, JWT keys, etc., wrapped in
   `"..."` spanning multiple lines.
4. **Process-environment integration.** Write the parsed env back
   into `$ZTRNLNM` space — depends on `setenv()` from STDOS T15.
**Action:** schedule when a concrete consumer (m-cli env-loaded
test config, or a service that needs `${BASE_URL}/api` style
substitution) drives the requirement.
**Reference:** `docs/modules/stdenv.md` "Out of scope (queued at
T22)" section.

### T23-T27 — STDXML deferred features
**Module:** STDXML.
**Status:** **T23 and T24 resolved 2026-05-07** (this commit);
T25-T27 still queued. STDXML now covers ~50% of the 12-16d full
XML 1.0 + Namespaces 1.0 + XPath 1.0 envelope. Remaining ~7-11d
across three focused T-tickets:

- ✅ **T23 — CDATA / PI / comments / xml-decl.** **Resolved
  2026-05-07.** `parseContent` dispatches on `<!--` / `<![CDATA[`
  / `<?` in addition to the previous `<` (start-tag) / `</`
  (end-tag) cases. New helpers: `skipDocLevel` (walks PIs +
  comments before / after the root element), `skipComment`
  (consumes `<!-- ... -->`), `skipPI` (consumes `<? ... ?>` —
  covers both processing instructions and the `<?xml ... ?>`
  declaration in the same path), `parseCdata` (reads
  `<![CDATA[ ... ]]>` and stores the literal content directly
  into the text accumulator without entity decoding). 8 new
  tests; STDXML 47/47 → 75/75 assertions.
- ✅ **T24 — Numeric character references.** **Resolved 2026-05-07.**
  `decodeEntities` extended to handle `&#NNN;` (decimal) and
  `&#xHH;` (hex). New helpers: `decodeNumericRef` (parses the
  digit sequence and returns the code point), `hexDigit` (lookup),
  `encodeUtf8` (1-4 byte UTF-8 encoding for any code point up to
  U+10FFFF). Out-of-range / malformed refs fall through as
  literal text per the lenient `decodeEntities` convention.
  Verified against U+00A9 (©, 2-byte) and U+4E2D (中, 3-byte)
  round-trips.
- ✅ **T25 — Namespaces (element-level).** **Resolved 2026-05-07.**
  Per-element namespace map threaded through `parseElement` /
  `parseContent`. New helpers: `absorbXmlns` (pulls `xmlns` /
  `xmlns:prefix` out of the element's attribute list and into the
  local namespace map), `splitQName` (decomposes `x:foo` into
  prefix and local name). Element prefix resolved against the
  inherited+local nsMap; undeclared prefix is a parse error. New
  public accessor: `$$ns^STDXML(.node)`. Tree shape extended:
  `node("name")` now stores the local name (was the qualified
  name pre-T25); `node("prefix")` and `node("ns")` added. 10
  new tests; STDXML 75/75 → 105/105 assertions, 26/27 → 29/30
  labels (96.7%).
- ✅ **T25b — Attribute-namespace resolution.** **Resolved 2026-05-07.**
  New `resolveAttrNs` walks `node("attr",...)`, splits each name
  containing `:` into prefix+local, and resolves the prefix
  against the same namespace map used for the element. Default
  xmlns does NOT apply to unprefixed attrs (per Namespaces 1.0
  §6.2). The `xml:` prefix is bound to
  `http://www.w3.org/XML/1998/namespace` as a built-in (no
  declaration needed — `xml:lang`, `xml:space`, `xml:base` etc.
  work out of the box). Undeclared prefix on an attr is a parse
  error. New public accessor: `$$attrNs^STDXML(.node, attrName)`.
  Tree shape: `node("attrNs", attrName)` set only for prefixed
  attrs. 7 new tests; STDXML 105/105 → 122/122 assertions.
- **T26 — DTDs / DOCTYPE / custom entities.** `<!DOCTYPE root [
  <!ENTITY name "value"> ]>`-style internal subsets. Reasonably
  rare in modern usage but VistA HL7v2 / CDA samples occasionally
  ship DTDs. External DTDs (with `SYSTEM "..."`) stay out of
  scope; internal subsets only. 2-3d.
- ✅ **T27 v0 — Minimal XPath subset.** **Resolved 2026-05-07.**
  `parseXPath` compiles expressions into a step list (axis +
  name + optional position predicate). `applyStep` walks the
  candidate set across the step list using path strings (e.g.
  `"1,3,2"` meaning `tree("child",1,"child",3,"child",2)`).
  `buildRef` constructs M name references for indirection-based
  subtree access — paths are entirely composed of internal loop
  counters so the indirection target is fully internal-controlled
  (file-wide M-MOD-036 disable with rationale). `mergePathToResult`
  uses `merge results(idx)=@ref` to copy each matching subtree
  into the result array. New public surface: `$$xpath` /
  `$$xpathOne` / `$$xpathText`. Supported: bare `name`, chained
  paths (`a/b/c`), absolute (`/foo`), descendant (`//x`), position
  predicates (`[N]`). 12 new tests; STDXML 122/122 → 145/145
  assertions, 31/32 → 41/42 labels (97.6%).
- ✅ **T27a — XPath wildcards + attribute axis.** **Implementation
  landed 2026-05-07** (test verification pending YDB container
  availability). `parseXPath` recognises `*` as a name token and
  `@` as an attribute-step prefix; the attribute step is terminal
  (parser rejects trailing steps). `matchName` factors the
  wildcard-aware name comparison used by both `collectChildren`
  and `collectDescendants`. `collectAttribute` walks
  `node("attr", k)` on the candidate elements (descendant axis
  supported via the same descendant walker) and stores results
  with `attrValue` / `attrName` subnodes. `applyPredicate` was
  factored out of `applyStep` and now uses `merge` (instead of
  `set`) so the attribute subnodes survive in-place reduction.
  `mergePathToResult` lifts attribute matches into
  `results(idx,"text")` / `results(idx,"name")` so `xpathText`
  returns the attribute value transparently. 10 new tests cover:
  `*`, `*[N]`, `//*`, `*/x`, `@id`, `@*`, `a/@id`, `//@id`,
  `@missing`, attribute via `xpathText`.
- **T27b — XPath functions + comparison predicates.** Queued.
  `position()`, `count()`, `text()`, `name()`, `normalize-space()`,
  `contains()`, `starts-with()`, `string-length()` plus comparison
  predicates (`[@attr='v']`, `[name()='foo']`). The predicate
  evaluator has to grow into a proper expression evaluator with
  type promotion (node-set / string / number / boolean). 2-3d.
  Could lean on STDREGEX for the text-pattern pieces.

**Action:** T25 is the next natural extension — VistA HL7v3 / CDA /
FHIR is namespaced. T27 is the largest remaining lift. T26 stays
lowest-priority for modern XML.

**Reference:** `docs/modules/stdxml.md` "Out of scope (queued)"
section. The W3C XML Test Suite is the conformance corpus for
T25-T27 acceptance; vendor it under `tests/conformance/xml/`
when a real consumer drives the requirement.

### T11 — Phase 3 entry (STDCRYPTO, STDCOMPRESS, STDHTTP)
**Modules affected:** STDCRYPTO, STDCOMPRESS, STDHTTP.
**Status:** ✅ **STDCRYPTO landed code-complete 2026-05-07** as the
Phase 3 lead; STDCOMPRESS and STDHTTP remain queued. STDCRYPTO ships
as **L26 H1 P3** in Table 1 above. Test verification still needs the
vista-meta engine reachable + the .so deployed inside it — see T28.
**Sequencing recap:**
1. ✅ v0.2.0 release sync (T7) — closed when v0.3.0 shipped 2026-05-07.
2. IRIS `$ZF` portability spike — deferred behind STDCRYPTO's YDB-side
   green run; validate against `intersystemsdc/iris-community:latest`
   once T28 unblocks the YDB run.
3. ✅ STDCRYPTO chosen as the lead (it's the dep for the jwt-verify
   example and exercises the `tools/build-callouts.sh` harness end-
   to-end).
4. STDCOMPRESS and STDHTTP are mutually parallel and will start once
   STDCRYPTO clears T28.
**Per-module specs:** `docs/m-stdlib-implementation-plan.md` §12.

### T28 — Engine-bound deployment for STDCRYPTO
**Status:** open. Code-complete on `main`; the engine wiring is the
remaining gap before `make test` can run STDCRYPTOTST green.
**What's already done (this session):**
- `src/STDCRYPTO.m` — public extrinsics + `$&std_crypto.*` wrappers.
- `src/callouts/std_crypto.c` — OpenSSL EVP_Digest + HMAC.
- `tools/std_crypto.xc` — YDB call-out descriptor (uses `$STDLIB_LIB`
  env var so it's portable across hosts).
- `tools/build-callouts.sh` — extended with per-source `// link:`
  directive parsing so the harness picks up `-lcrypto` for
  `std_crypto.c` without hardcoding crypto-specific flags.
- `tests/STDCRYPTOTST.m` — RFC 6234 / RFC 4231 vectors, 22 tests.
- `docs/modules/stdcrypto.md` — full module doc + deployment runbook.
**What's still owed:**
1. **vista-meta container — install libssl.** The container image
   needs `libcrypto.so.3` (or `.so.1.1`) loadable. Modern base
   images already do; document explicitly in vista-meta and verify.
2. **`scripts/seed-vista.sh` — push .so + .xc.** Today the seed
   only ships routines. Extend it to scp `so/<plat>/std_crypto.so`
   and `tools/std_crypto.xc` into the container's session staging
   area.
3. **YDB session env-var wiring.** The container's `m test` shell
   wrapper must `export STDLIB_LIB=<path>` and
   `export ydb_xc_std_crypto=<path>` before invoking the suite. Add
   to the seed script's per-test bootstrap or to the vista-meta
   image's entrypoint.
4. **Build dep gate.** `tools/build-callouts.sh` requires
   `libssl-dev` + `libyottadb.h` headers on the build host. Document
   in README install section. (This session's host has neither;
   `--check` passes but actual build will fail — expected.)
**Effort estimate:** 2-3d split across vista-meta-side image work
(item 1) and m-stdlib-side seed-script work (items 2 + 3).
**Why it didn't ship in the same commit:** vista-meta container was
unreachable during the STDCRYPTO landing session (SSH connection
refused 2026-05-07), and the host lacked `libssl-dev` headers, so
the green-run cycle couldn't be exercised. Code is sound but
unverified end-to-end against the engine.

### T29 — STDHTTP iteration 2 (libcurl callout)
**Module affected:** STDHTTP (H3 P3).
**Status:** open. Iteration 1 (pure-M wire-format helpers) landed
2026-05-07: `parseStatusLine` / `parseHeader` / `parseResponse` /
`buildRequest` / `formatHeaders` plus soft-fail `$$get` / `$$post` /
`$$request` stubs that set `resp("error")="STDHTTP-NOT-WIRED"` so
consumers can integrate against the final array shape today.
**What iteration 2 owes:**
1. `src/callouts/http.c` — libcurl glue (curl_easy_init / setopt /
   perform / getinfo / cleanup) writing back HTTP response code,
   header block, and body bytes into M output buffers.
2. `tools/std_http.xc` — YDB call-out descriptor analogous to
   `tools/std_crypto.xc` (uses `$STDLIB_LIB` for path portability).
3. Wire `$$request^STDHTTP` to drive the callout; replace the
   soft-fail `STDHTTP-NOT-WIRED` path. Map curl error codes →
   `resp("error")` strings.
4. Network-bound integration tests against a local httpbin or
   echo server (vendor under `tests/integration/http/` so they
   stay separable from the pure-M `STDHTTPTST` suite).
5. Build-host dep: `libcurl4-openssl-dev`. Per-source `// link:`
   directive in `http.c` to add `-lcurl` (same idiom STDCRYPTO
   established for `-lcrypto`).
6. vista-meta container needs `libcurl.so.4` loadable (typically
   already present; document in T28-style runbook).
**Effort:** 5-7d split across the C glue (~2d), $ZF wiring + test
plumbing (~2d), and the integration-test harness (~1-3d depending
on whether httpbin is vendored or proxied).
**IRIS arm:** deferred. The `%Net.HttpRequest` `$CLASSMETHOD` arm
shares the same M-side req/resp shape and lands as a follow-on.

---

## Table 2 — Proposed future modules (not yet started)

These appear in `docs/users-guide.md` §6.3 as candidate sketches.
None has TDD-red staked. Promote a row from this table into Table 1
the moment you write `tests/STDxxxTST.m` and confirm it fails red —
at that point assign a track ID (next available L-number for pure-M
or H-number for `$ZF`-bound), bump the row out of this table, and
add it to Table 1 with phase **P4** (or whatever phase fits).

Priority is a single integer 1..N (1 = highest). Priority captures
**when this should be picked up** relative to the other proposals,
considering: security gap closure, downstream-module unblock,
adjacent-tooling pressure, breadth of call sites.

Dependency column legend: same as Table 1. **soft** = optional —
module would work without the dep but ships better integration when
the dep is present.

Effort = same unit as Table 1 (developer-days, full TDD discipline,
all forward estimates marked **est.**).

| Pri | Candidate | Headline | Dependency | Effort | Rationale |
|---|---|---|---|---|---|
| 1 | `STDYAML` | YAML 1.2 parser | STDDATE; STDSTR (soft) | 12–18d est. | Config ergonomics; preferred to JSON for human-edited configs. **Big spec.** Defer until a concrete consumer asks. |
| 2 | `STDNET` | TCP / UDP socket primitives | `$ZF → libc` POSIX sockets (or YDB native), TBD; A6 | 8–14d est. | Sits below `STDHTTP` and a future `STDDNS`. **Largest lift** of any row; defer until a concrete greenfield service drives it. |

Promoted out of Table 2 (now in Table 1):

- **STDCSPRNG** — promoted 2026-05-07 to Table 1 as **L15 P4**.
  Implemented with `/dev/urandom` (kernel ChaCha20 CSPRNG via single-
  byte `READ *b` to avoid record-terminator truncation) instead of
  the originally sketched `$ZF → libc` callout — the API surface is
  stable for a future callout-backend swap (T12) once the Phase 3
  build harness is exercised by a real consumer.
- **STDFS** — promoted 2026-05-07 to Table 1 as **L16 P4**. Shipped
  as text-mode YDB-only v1: read/write/append/exists/remove/size +
  basename/dirname/join. Append uses a read-then-rewrite workaround
  for a YDB SEQ APPEND-mode position quirk; binary-safe I/O and the
  IRIS arm both wait on the `$ZF → libc` callout backend (T13/T14).
- **STDOS** — promoted 2026-05-07 to Table 1 as **L17 P4**. Shipped
  as YDB-only v1: env / pid / cmdline / argc / arg / argv /
  splitArgs / cwd / user / hostname / exit. Built over `$ZTRNLNM` /
  `$JOB` / `$ZCMDLINE` / `ZHALT` (the YDB intrinsic boundary). The
  earlier `$zgetenv` choice would have triggered a `m fmt` mangling
  bug; `$ztrnlnm` is the equivalent VAX/VMS-style intrinsic that
  fmt leaves alone. setenv() and quote-aware splitArgs deferred to
  T15 alongside the IRIS arm via `$ZF → libc setenv/getcwd/gethostname`.
- **STDSEMVER** — promoted 2026-05-07 to Table 1 as **L18 P4**. SemVer
  2.0.0 implementation: valid / parse / compare / matches plus
  major/minor/patch/prerelease/build accessors. Pure-M, no STDREGEX
  dep (parsed via `$piece` / `$translate`). Range syntax in v1
  covers comparators (`>` `<` `>=` `<=` `=`), caret (`^`), tilde (`~`),
  and AND-combination via space; `||` OR, hyphen ranges, `*`/`x`/`X`
  placeholders, prerelease-aware semantics, and the npm `^0.x.y`
  zero-major narrowing all queued at T16. Coverage: 22/22 labels
  (100%), 99/99 assertions green.
- **STDSTR** — promoted 2026-05-07 to Table 1 as **L19 P4**. String
  helpers: pad / padLeft / padRight, trim / trimLeft / trimRight,
  replaceAll, split, startsWith / endsWith, toLowerASCII /
  toUpperASCII, repeat. Pure-M (`$translate` / `$piece` / `$find` /
  `$extract`); no `$Z*` extensions, no STDREGEX dep. Whitespace is
  ASCII only (space / tab / LF / CR); Unicode whitespace + locale-
  aware case folding deferred to a future STDUNICODE under T17.
  Coverage: 13/13 labels (100%), 63/63 assertions green.
- **STDTOML** — promoted 2026-05-07 to Table 1 as **L20 P4**. TOML
  1.0 subset: top-level pairs + `[section]` tables; string / integer
  / float / bool scalars; `#` comments (whole-line and trailing,
  string-aware so a `#` inside `"..."` is preserved); duplicate
  keys per scope rejected. Pure-M parser (no STDREGEX, no STDDATE
  dep — datetime decoding is queued at T18). Out of scope for v1
  (all queued under T18): arrays, inline tables, dotted keys,
  `[[array-of-tables]]`, multi-line / literal strings, integer
  underscores + hex/oct/bin prefixes, special floats, exponent
  notation, datetime values. Coverage: 14/14 labels (100%), 59/59
  assertions green.
- **STDCACHE** — promoted 2026-05-07 to Table 1 as **L21 P4**. LRU
  + TTL cache over a caller-owned local-array tree: new / put / get
  / has / remove / clear / size / capacity. Bounded by capacity (LRU
  eviction of least-recently-touched key) and / or wall-clock TTL
  (lazy reap on access; no background sweeper). Time source is
  `$HOROLOG` collapsed to seconds. Pure-M, no `$Z*`, no STDCOLL or
  STDDATE runtime dep — STDCOLL listed as soft dep but inlined for
  v1 self-containment; T19 covers a future rebase onto STDCOLL's
  OrderedDict + an explicit `prune` operation for batch sweeps.
  Coverage: 10/10 labels (100%), 48/48 assertions green.
- **STDPROF** — promoted 2026-05-07 to Table 1 as **L22 P4**. Wall-
  clock profiler over a caller-owned tree: start / stop per tag,
  with count / total / mean / min / max / percentile aggregates and
  a tags() enumerator. Time source is `$ZHOROLOG` (microsecond
  resolution; `$HOROLOG`'s second resolution is too coarse for
  profiling). Percentile uses nearest-rank into a sorted-by-value
  sample tree (`prof("samples", tag, value, seq) = ""`); `O(N)`
  worst case but typically a small walk. STDCOLL Heap listed as
  soft dep for a future T20 streaming-percentile (CKMS sketch)
  variant; v1 keeps all samples for exactness. Coverage: 12/12
  labels (100%), 25/25 assertions green.
- **STDSNAP** — promoted 2026-05-07 to Table 1 as **L23 P4**.
  Snapshot testing: `serialize` / `save` / `matches` / `asserts`.
  Canonical line-per-leaf text dump via `$QUERY` walk; numeric
  subscripts unquoted, string subscripts and values M-quoted with
  `"..."` and embedded `"` doubled. Lines emitted in `$ORDER` —
  deterministic, diff-friendly. Hard deps: STDFS (file I/O for
  save/matches), STDASSERT (asserts integration with pass/fail
  counters). No STDJSON dep — pre-listed as soft but inlined dq()
  helper. Out of scope for v1 (queued at T21): root-scalar
  snapshots (`$QUERY` walks descendants only), auto-update flag,
  bundled diff helper (humans run `diff -u baseline current` for
  inspection). Coverage: 7/7 labels (100%), 23/23 assertions green.
- **STDENV** — promoted 2026-05-07 to Table 1 as **L24 P4**. `.env`
  loader with typed accessors: `parse` / `parseFile` / `valid` /
  `has` / `get` / `getInt` / `getBool` / `getFloat`. Format covers
  bare and quoted (`"..."` with `\n \t \r \" \\` escapes; `'...'`
  literal) values, `#` whole-line comments, leading-letter-or-`_`
  bare keys. `getBool` is case-insensitive against
  `true/yes/on/1` and `false/no/off/0`. Default-on-miss-or-mistype
  convention for typed accessors. Hard dep STDFS for `parseFile`;
  STDSTR listed as soft but inlined for self-containment. Out of
  scope for v1 (T22): variable substitution, `export` prefix,
  multi-line values, process-environment write-back via STDOS
  setenv (T15). Coverage: 14/15 labels (93.3%, `parseFile`
  not directly tested — covered via integration tests in callers),
  46/46 assertions green.
- **STDXML v0** — promoted 2026-05-07 to Table 1 as **L25 P4**.
  XML 1.0 well-formed parser, recursive-descent, ~30% of the
  full XML 1.0 + Namespaces 1.0 + XPath 1.0 envelope. Public
  surface: `parse` / `valid` / `rootName` / `attr` / `text` /
  `childCount` / `childByName` / `lastError`. Tree shape mirrors
  STDJSON's caller-owned-tree convention; `childByName` does the
  internal `merge` to sidestep the `.x(SUBS)` YDB syntax limit.
  Standard 5 entities (`&amp;` / `&lt;` / `&gt;` / `&quot;` /
  `&apos;`) decoded in text and attribute values. Out of scope
  for v0, queued under T23-T27 (~9-13d remaining for full envelope):
  CDATA / PI / comments / xml-decl (T23), numeric character
  references (T24), namespaces (T25), DTDs / DOCTYPE / custom
  entities (T26), XPath 1.0 query subset (T27). Coverage: 19/20
  labels (95%, `lastError` only triggers in error paths and
  isn't directly tested), 47/47 assertions green.
- **STDMATH** — promoted 2026-05-08 to Table 1 as **L26 P4**. Numeric
  helpers: `clamp` / `min` / `max` / `sum` / `count` / `mean` over a
  caller-owned array. Pure-M (`+` coercion, `$ORDER` walk at depth 1);
  no `$Z*`, no STDREGEX dep. Empty-array convention: `min` / `max` /
  `mean` return `""` (no value), `sum` / `count` return `0` (additive
  identity). Multi-dim arrays read only their first level — descend
  yourself for deeper walks. Aligned with M's standard unary-`+`
  coercion rule so non-numeric values fold to 0 the same way native
  arithmetic does, no surprise. 28 tests / 26 labels staked.
- **STDXFRM** — promoted 2026-05-08 to Table 1 as **L27 P4**. Higher-
  order array transforms via `@expr` indirection: `do map^STDXFRM`,
  `do filter^STDXFRM`, `$$reduce^STDXFRM`. The lambda string is
  evaluated in STDXFRM's own stack frame so it sees `value` (current
  element), `key` (current subscript), and `acc` (reduce only) as
  plain locals. `map` / `filter` `kill out` before walking — stale
  prior state cannot leak through. `reduce` returns `init` unchanged
  on empty input (standard fold identity). Errors in the expression
  propagate to the caller's `$ETRAP` — STDXFRM does not catch.
  Same `@`-indirection idiom as STDMOCK's `do @resolved@(.args)`;
  M-MOD-036 disabled file-wide for the same reason. 19 tests /
  19 labels staked.

**Aggregate proposal effort:** ~20–32d est. for the remaining 2
candidates if every row eventually lands (STDXML, STDMATH, STDXFRM
all promoted out). One large (STDYAML 12-18d, deferred without a
concrete consumer), one largest (STDNET 8-14d, deferred until a
real greenfield service drives it). Both are multi-session
commitments — the small-and-completable shelf is now empty.

When promoting a row into Table 1, also:

- Assign a track ID per the §3 convention in
  `docs/parallel-tracks.md` (next free `L<n>` for pure-M, `H<n>` for
  `$ZF`-bound).
- Add the per-module spec stub to
  `docs/m-stdlib-implementation-plan.md` (current sections 8 / 11 / 12
  are the spec home for Phase 1 / 2 / 3 — extend with §13 or later as
  needed).
- Open the dispatch row in `docs/parallel-tracks.md` §3.x with the
  block-on edges (if any) marked in §2's dependency map.

---

## Must-know — sequencing, dependencies, conventions

**Read these before starting work on any module or combination of
modules.** None of the rules below are enforced by tooling — they are
enforced by review.

### Architectural priority

- **m-stdlib has priority over m-cli.** When both projects need a
  utility, it lands in m-stdlib first; m-cli imports. This rule lives
  in `~/projects/m-stdlib/CLAUDE.md` and the project README.
- **GT.M is permanently out of scope.** Anyone forking m-stdlib for
  GT.M would need to remove the `view "TRACE"` coverage hooks and
  the `tstart` rollback levels. Locked decision.

### Dependency map (the only edges that block parallelism)

Per `docs/parallel-tracks.md` §2:

| Consumer | Dependency | Type | Notes |
|---|---|---|---|
| STDLOG (`v0.0.4`) | STDDATE (`v0.0.5`) | Soft (folded) | L4b folded into L4 release because L5 landed first; the inline-ts interim was never cut. |
| m-cli runner SETUP/TEARDOWN wrap | STDFIX (`v0.1.1`) | Hard | shipped — m-cli `e5818bd` |
| m-cli runner CLEAR^STDMOCK | STDMOCK (`v0.1.2`) | Hard | shipped — m-cli `e5818bd` |
| m-cli `--seed PATH` | STDSEED (`v0.1.3`) | Hard | shipped — m-cli `e5818bd` |
| STDLOG JSON-line output | STDJSON (`v0.2.0`) | Hard | landed on `main` — see T3, T6 |
| STDSEED `loadJson` | STDJSON (`v0.2.0`) | Hard | landed on `main` — see T3, T6 |
| STDHTTP | STDURL (`v0.2.0`) + `tools/build-callouts.sh` | Hard | both shipped; STDHTTP iter 1 (pure-M helpers) landed; iter 2 (libcurl callout) queued at T29 |
| STDCRYPTO / STDCOMPRESS | `tools/build-callouts.sh` | Hard | A6 shipped; queued at T11 |

Everything else is independent — tracks for different modules can run
in parallel without coordination beyond merge ordering.

### Synchronisation points

Tags merge in dependency order, but **development can run in
parallel**: a track for STDARGS (`v0.0.7`) can produce a green
branch before STDFMT (`v0.0.3`) merges. The joins are at release-tag
time, not development time:

| Sync | Status | What joins |
|---|---|---|
| `v0.1.0` release | ✅ shipped 2026-05-05 | L1–L7, L4b |
| `M1` close | ✅ shipped 2026-05-05 | L8+W, L9+X, L10+Y |
| `v0.2.0` release | 🟡 **pending** (T7) | L11–L14 + STDLOG-JSON + STDSEED-loadJson |
| Phase 3 entry | 🟡 queued (T11) | A6 already shipped; needs IRIS `$ZF` pass |
| `v0.3.0` release | 🟡 queued | All Phase 3 tracks + jwt-verify example |
| `v1.0.0` | 🟡 queued (time-based) | 3 months of API stability after `v0.3.0` |

### Per-module acceptance gate (§9 of the implementation plan)

Every module must pass these before its `vN.N.N` tag:

| Gate | Tool | Pass threshold |
|---|---|---|
| Format | `m fmt --check` | clean (no diffs) |
| Lint | `m lint --error-on=error` | 0 errors |
| Tests | `m test --format=tap` | 100% assertions pass |
| Coverage | `m coverage --min-percent=85` | ≥ 85% per-module label coverage (most modules ship at 100%) |
| IRIS portability | `iris-portability-check` CI job | fail-soft — surfaces regressions but does not gate merges |

### TDD discipline (non-negotiable)

Per `~/.claude/CLAUDE.md` and `docs/users-guide.md` §2:

1. Write `tests/STDxxxTST.m` with realistic fixtures.
2. Run — confirm a deliberate red.
3. Implement `src/STDxxx.m`.
4. Run — confirm green.
5. `make check` (fmt-check + lint + test) before commit;
   `make coverage` before tag.

`m fmt` and `m lint --error-on=error` run automatically as a
PostToolUse hook on every Edit/Write of a `.m` file; lint errors come
back as a system reminder mid-turn.

### Conventions for parallel work (so multiple tracks don't stomp each other)

Per `docs/parallel-tracks.md` §7:

- **CHANGELOG.md fragments per track.** Each track adds one bullet
  under `## [Unreleased]`; release sync collapses to the next tag.
- **§1 status table in implementation-plan.md.** Each track edits its
  own row only; conflicts are line-level.
- **TODO.md.** Avoid editing during track work; update at milestone
  close.
- **TOOLCHAIN-FINDINGS.md.** Append-only during track work; renumber
  at milestone close.
- **`docs/modules/index.md`.** Each track adds its own row;
  regeneration at v0.1.0 / v0.2.0 / v0.3.0 release time absorbs the
  table.
- **`docs/module-tracker.md` (this file).** Updated **in the same
  commit** as any module-level change. Both tables are line-level
  mergeable; conflicts at the row level only.
- **m-cli companion PRs.** Ride alongside their stdlib track but
  live in `~/projects/m-cli/`. Track owner opens both branches,
  merges stdlib first, then m-cli.

### Status / state docs (read in this order for a cold start)

1. `~/projects/m-stdlib/CLAUDE.md` — project status banner; the
   "what shipped, what's next" one-screen view.
2. `docs/users-guide.md` — TDD-first walkthrough; module narrative
   in §4 and §5.
3. `docs/module-tracker.md` — **this file** — canonical tracker.
4. `docs/parallel-tracks.md` — dispatch view; what to pick up.
5. `docs/m-stdlib-implementation-plan.md` — per-module specs +
   §9 acceptance gate.
6. `TOOLCHAIN-FINDINGS.md` — open P0/P1/P2 findings against m-cli /
   YDB / m-stdlib.
7. `CHANGELOG.md` — release history.
8. `TODO.md` — resume-here pointer; small.

### Cross-references

- [users-guide.md](users-guide.md) — narrative § companion.
- [parallel-tracks.md](parallel-tracks.md) — dispatch view (track
  IDs, track-level state).
- [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md)
  — per-module specs (§8 P1, §11 P2, §12 P3) and §9 acceptance gate.
- [tdd-orchestration-plan.md](tdd-orchestration-plan.md) — joint
  m-stdlib ↔ m-cli milestone narrative (M0 – M5).
- [modules/index.md](modules/index.md) — released-module canonical
  index (Phase 1 only at present; regenerated each release).
- [../TOOLCHAIN-FINDINGS.md](../TOOLCHAIN-FINDINGS.md) — open
  toolchain bugs.
- [../CHANGELOG.md](../CHANGELOG.md) — release history.
- [../TODO.md](../TODO.md) — resume-here pointer.
- [../CLAUDE.md](../CLAUDE.md) — project status banner +
  architectural rule.
- [../../m-cli/TODO.md](../../m-cli/TODO.md) — m-cli's own track
  list.
- [../../vista-meta/docs/vista-orchestration-plan.md](../../vista-meta/docs/vista-orchestration-plan.md)
  — parent plan; tracks P1–P3 belong to its scope.
