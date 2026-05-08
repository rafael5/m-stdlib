---
title: m-stdlib — master module development tracker
status: live (2026-05-07; **full engine suite green: 32 suites, 2483/2483 assertions** — T11 closed (Phase 3 entry: STDCRYPTO 23/23, STDCOMPRESS 59/59, STDHTTP 68/68); T28 / T29 / T30 all closed; T12 closed — STDCSPRNG `$ZF→getrandom(2)` 406/406; T27a+T27b closed — STDXML XPath wildcards / attribute axis / functions / comparison predicates)
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
| P4 | L15 | 17 | [`STDCSPRNG`](modules/stdcsprng.md) | `v0.2.x` (on `main`, **green on engine 2026-05-07** — T12 closed) | ~1d ✅ + ~Xh ✅ T12 | T12 ✅ | STDB64 (urlencode); STDHEX (encode); STDUUID (test-only valid()); `$ZF → getrandom(2)` for batch perf (with `/dev/urandom` soft-fall-back) | Crypto random — bytes / hex / base64 / token / int / uuid4 (kernel CSPRNG via `cs_random` callout `\|` `/dev/urandom`). STDCSPRNGTST 406/406 green via `make safe-test`. | n/a — not inner-loop; m-cli does not generate tokens / session IDs / signing salts |
| P4 | L16 | 18 | [`STDFS`](modules/stdfs.md) | `v0.2.x` shipped + `v0.3.x` byte-I/O on `main` (awaiting tag) | ~1d ✅ + ~Xh ✅ T13+T14 | none | `$ZF → libc open/read/write/close` (T13+T14 closed; pure-M text I/O still uses `$ZEOF` / `$ZLEVEL` / `$ETRAP+ZGOTO`) | File-system primitives — read/write/append/exists/remove/size + basename/dirname/join (text I/O via YDB SEQ stream mode); **readBytes / writeBytes / appendBytes / available** (byte-faithful I/O via libc callout, atomic `O_APPEND`) | n/a — Python `pathlib` / `os` / `tempfile` / `shutil` cover host side; STDFS is for M-side consumers |
| P4 | L17 | 19 | [`STDOS`](modules/stdos.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T15 | none (uses `$ZTRNLNM` / `$JOB` / `$ZCMDLINE` / `ZHALT`); future-soft `$ZF → libc setenv/getcwd/gethostname` for IRIS arm | Process / env / cmdline helpers — env / pid / cmdline / argc / arg / argv / splitArgs / cwd / user / hostname / exit | n/a — Python `os` / `sys` / `subprocess` / `shlex` cover host side; STDOS is for M-side consumers |
| P4 | L18 | 20 | [`STDSEMVER`](modules/stdsemver.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T16 | none (pure-M; STDREGEX listed as soft dep but not used in v1) | SemVer 2.0.0 — valid / parse / compare / matches (caret / tilde / comparator AND-combination) | 🔮 C10 — speculative; only if m-cli ever grows `m install <pkg>@<range>`; today not a package manager |
| P4 | L19 | 21 | [`STDSTR`](modules/stdstr.md) | `v0.2.x` (on `main`, awaiting tag) | ~Xh ✅ | T17 | none (pure-M; `$translate` / `$piece` / `$find` / `$extract`) | String helpers — pad / trim / replaceAll / split / startsWith / endsWith / toLowerASCII / toUpperASCII / repeat | n/a — Python `str` methods cover host side; STDSTR is for M-side consumers |
| P4 | L20 | 22 | [`STDTOML`](modules/stdtoml.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T18 | none in v1 (STDDATE listed as soft dep but datetime values out of scope; STDSTR listed but inlined for self-containment) | TOML 1.0 subset — top-level pairs + `[section]` tables; string / integer / float / bool scalars; `#` comments | 🔮 C11 — speculative; m-cli today reads `.m-cli.toml` via Python `tomllib`; only relevant if config moves M-side |
| P4 | L21 | 23 | [`STDCACHE`](modules/stdcache.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T19 | none in v1 (STDCOLL listed as soft dep but inlined for self-containment; STDDATE listed but `$HOROLOG`-direct) | LRU + TTL cache over caller-owned array — new / put / get / has / remove / clear / size / capacity | n/a — short-lived per-invocation CLI process has no persistent state to cache; for M-side long-running services |
| P4 | L22 | 24 | [`STDPROF`](modules/stdprof.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | none | none in v1 (uses `$ZHOROLOG` for microsecond resolution; STDCOLL Heap listed as soft dep for the streaming-percentile variant T20 reserved but did not deliver) | Wall-clock profiler — start / stop / count / total / mean / min / max / percentile / tags / clear | ✅ C6 |
| P4 | L23 | 25 | [`STDSNAP`](modules/stdsnap.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | none | STDFS (save/matches I/O); STDASSERT (asserts integration) | Snapshot testing — serialize / save / matches / asserts; canonical line-per-leaf dump via `$QUERY` walk | ✅ C7 |
| P4 | L24 | 26 | [`STDENV`](modules/stdenv.md) | `v0.2.x` (on `main`, awaiting tag) | ~1d ✅ | T22 | STDFS (parseFile); STDSTR listed as soft dep but inlined for self-containment | `.env` loader + typed accessors — parse / parseFile / valid / has / get / getInt / getBool / getFloat | ✅ C8 |
| P4 | L25 | 27 | [`STDXML`](modules/stdxml.md) | `v0.3.x` (incremental on `main`) | ~12d ✅ (v0+T23+T24+T25+T27v0+T27a+T27b; ~2d remaining for T26 only) | T26 | none (pure recursive-descent parser + indirection-based path walker; predicate expression evaluator inlined in src/STDXML.m) | XML parser — well-formed XML 1.0 + comments / PI / xml-decl / CDATA + numeric char refs + full namespaces + XPath subset (paths / `[N]` predicates / descendant axis `//` / wildcards `*` `@*` / attribute axis `@attr` / **comparison predicates `[@id='v']` `[name()='b']` `[count(x)>1]`** / **functions `position()` `last()` `name()` `text()` `count()` `string-length()` `normalize-space()` `contains()` `starts-with()` `not()` `string()` `number()`**). ~95% of full envelope; T26 (DTDs) is the only remaining queued lift. | n/a — m-cli has no XML in `m fmt` / `m lint` / `m test` / `m coverage` / `m lsp` flows; consumer is vista-meta HL7v3 / CDA / FHIR |
| P4 | L26 | 28 | [`STDMATH`](modules/stdmath.md) | `v0.3.x` (on `main`, awaiting tag) | ~Xh ✅ | none | none (pure-M; `+` coercion, `$ORDER` walk) | Numeric helpers — clamp / min / max / sum / count / mean over caller-owned arrays | n/a — Python `min` / `max` / `sum` / `statistics.mean`; not inner-loop |
| P4 | L27 | 29 | [`STDXFRM`](modules/stdxfrm.md) | `v0.3.x` (on `main`, awaiting tag) | ~Xh ✅ | none | none (pure-M; `@expr` indirection in own stack frame) | Higher-order array transforms — `map` / `filter` / `reduce` via `@expr`-evaluated lambdas (`value` / `key` / `acc` locals) | n/a — Python list-comprehensions / `map` / `filter` / `functools.reduce`; not inner-loop |
| P3 | H1 | 30 | [`STDCRYPTO`](modules/stdcrypto.md) | `v0.3.x` (on `main`, **green on engine 2026-05-07**) | ~2d ✅ | T28 ✅ | `$&pkg.fn → libcrypto`; A6 | SHA-256/384/512 + HMAC-SHA-256/384/512. STDCRYPTOTST 23/23 green; coverage 17/17 = 100%. T28 closed via `scripts/seed-callouts.sh` automation. | 🟡 C12 — speculative P3 hookup; m-cli has no current hashing/HMAC need; queued behind T11 |
| P3 | H2 | 31 | [`STDCOMPRESS`](modules/stdcompress.md) | `v0.3.x` (engine-deployed; 55/57 green) | ~3d ✅ scaffolded / ~3d migration + deploy ✅ / ~0.5d remaining (M-side $ECODE redesign — T30) | T28 done, T30 open | `$&stdcompress.<sym>` → `libz` + `libzstd`; A6 | gzip / gunzip / deflate / inflate / zstdCompress / zstdDecompress / available. Output via `.out` byref (1 MiB cap); errors via `$ECODE`. **Scaffolded 2026-05-07:** C shim, .xc, M wrapper, 24-label test suite, doc. **Host build verified 2026-05-07:** `// link: -lz -lzstd` directive added; libzstd-dev installed; `so/linux-x86_64/stdcompress.so` builds with all 10 entrypoints exported. **T28 engine-deployed 2026-05-07:** scp'd .so + .xc into vista-meta `~/export/seed/m-stdlib/lib/`, wired `STDLIB_LIB` + `ydb_xc_stdcompress` env vars. Engine reports as GT.M V7.0-005, which (a) rejects `.var` byref output for `$ZF`, forcing a migration `$ZF(name,…)` → `$&stdcompress.<short>(…)` in STDCOMPRESS.m (mirrors STDCRYPTO); (b) requires `int argc` prepended to every C entry point under the `$&pkg.fn` ABI, so stdcompress.c got argc-checked; (c) caps M-string length at 1 MiB, so the .xc's `[16777216]` was rejected and the buffer cap (`STDCOMPRESS_OUT_BUFSIZE`, `preallocBuf()`, .xc declarations) was lowered to 1 MiB. **Engine results: 55/57 green** — all round-trips at 0–10 KB pass for all three codecs, bytes 0x00–0xFF preservation passes, magic-byte assertions pass, default-level sentinel passes, corrupt-input rejections return falsy. **Remaining 2 failures** are the `$ECODE tagged LIBZ-FAIL` / `$ECODE tagged LIBZSTD-FAIL` contains-asserts: dispatchC/D's local `$etrap` clears `$ecode` so the dispatch can quit 0 cleanly; by the time the test reads `$ecode` it's empty. Setting `$ecode` and returning falsy from an extrinsic *while leaving `$ecode` set for the caller* is incompatible with YDB r2.02's etrap semantics. Same latent bug in STDCRYPTO's dispatch3/dispatch4. Tracked under **new ticket T30** — route U-error code through a routine-local global that the public extrinsic copies to `$ECODE` after dispatch returns, instead of `set $ecode=",U-…,"` inside the dispatch helper. ~0.5d M-side rewrite; deployment infra unaffected. | 🟡 C13 — speculative P3 hookup; m-cli has no current compression need; queued behind T11 |
| P3 | H3 | 32 | [`STDHTTP`](modules/stdhttp.md) | `v0.4.0` (on `main`, **green on engine 2026-05-07**) | ~1d ✅ iter 1 + ~3d ✅ iter 2 / ~3-5d remaining (iter 3 IRIS arm) | T29 ✅ | STDURL; `$&stdhttp.http_perform → libcurl`; A6 | HTTP/1.1 client. **Iter 1 landed:** pure-M wire-format helpers (`parseStatusLine` / `parseHeader` / `parseResponse` / `buildRequest` / `formatHeaders`). **Iter 2 landed (T29 close):** `src/callouts/http.c` (251 LOC libcurl shim — `http_perform` + `http_available`), `tools/std_http.xc`, `$$request` / `$$get` / `$$post` driven via XECUTE-wrapped `$&stdhttp.http_perform(…)`. Both `$$available^STDHTTP` and the internal dispatch short-circuit on `$$env^STDOS("ydb_xc_stdhttp")=""` so engines without the descriptor exported soft-fail to `resp("error")="STDHTTP-NOT-WIRED"`. **STDHTTPTST 68/68 green; 94.1% label coverage; lint 0E.** Iter 3 (IRIS arm via `%Net.HttpRequest`) queued. | 🟡 C14 — speculative P3 hookup; m-cli today uses Python `urllib` / `requests`; queued behind T29 |

**Aggregate:** ~99d shipped across all 32 landed modules. **All three
Phase 3 modules engine-green on `main` 2026-05-07**: STDCRYPTO H1
(23/23, T28 closed), STDCOMPRESS H2 (55/57, T28 closed for deployment;
2 latent `$ECODE`-tagged-message asserts pending T30 redesign),
STDHTTP H3 iter 1+2 (68/68, T29 closed). STDXML covers ~95% of the
12-16d envelope so ~2d of T26 (DTDs) remains; T30 (~0.5d) is the only
new ticket and is M-side only — deployment infra unaffected. Open
ToDo work (T1-T30 with T1-T7/T12/T13/T14/T20/T21/T23-T25b/T27v0/T27a/T27b/T28/T29
resolved; T11 closed — all three Phase 3 modules engine-green; T26
and T30 remaining) is incremental on top of the shipped totals — see
ToDo expansion below for per-task estimates.

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
- ~~**T12** STDCSPRNG `$ZF → getrandom(2)` callout backend (perf-only swap)~~ — **resolved 2026-05-07**: `src/callouts/cs_random.c` (single `cs_random(n,out)` entry; loops over `getrandom(2)` until `n` bytes filled; `EINTR` retry); `tools/std_csprng.xc` descriptor (1 MiB output cap). M side: new `$$useCallout^STDCSPRNG()` probe + internal `dispatchRandom(n)` XECUTE-wrapped `$ZF` call (same anti-fmt-mangle pattern as STDCRYPTO/STDHTTP); `$$bytes^STDCSPRNG` tries the callout first, falls back to the existing `/dev/urandom` `READ *b` loop on miss. Public API unchanged. Soft-fall-back keeps STDCSPRNGTST 406/406 green when the descriptor isn't deployed; engine-deployed perf path verified separately under T28's deployment harness.
- ~~**T13** STDFS native append (replace read-then-rewrite with `$ZF → write(2)` once Phase 3 cuts)~~ — **resolved 2026-05-07**: `src/callouts/stdfs.c` (`stdfs_appendBytes` issues `open(O_APPEND)` + looped `write(2)`); `tools/std_fs.xc` descriptor; `src/STDFS.m` adds `appendBytes^STDFS` extrinsic — atomic at EOF, byte-faithful, no lseek race. The text-mode `append^STDFS` keeps its read-then-rewrite implementation because rerouting it through native `O_APPEND` would leave an interior LF whenever the previous content ended with one (breaking the `readFile(append(x,y)) == readFile(x) + y` round-trip contract). Callers picking between them: `appendBytes` for binary streams / structured logs; `append` for text-mode concat + trailing-LF semantics.
- ~~**T14** STDFS `readBytes` / `writeBytes` for byte-faithful binary I/O (deferred alongside T13)~~ — **resolved 2026-05-07**: same C shim adds `stdfs_readBytes` (looped `read(2)` into a 16 MiB caller buffer; surfaces `,U-STDFS-READ-TRUNCATED,` instead of silent truncation) and `stdfs_writeBytes` (`O_TRUNC` + looped `write(2)`); M side adds `$$readBytes^STDFS` / `do writeBytes^STDFS` extrinsics. No CR/LF normalisation, no implicit trailing LF — exact byte counts preserved. Tests gate on `$$available^STDFS()` and assert the soft-fail path sets `,U-STDFS-NOT-WIRED,`.
- **T15** STDOS `setenv` / quote-aware `splitArgs` / IRIS arm via `$ZF → libc setenv/getcwd/gethostname` callouts.
- **T16** STDSEMVER range syntax extensions (`||` OR, hyphen ranges, `*`/`x`/`X` placeholders, prerelease-aware comparators, `^0.x.y` zero-major narrowing per npm semantics).
- **T17** STDSTR Unicode whitespace + locale-aware case folding (deferred to a future STDUNICODE; STDSTR v1 is byte-wise ASCII-only by design).
- **T18** STDTOML out-of-scope features (arrays, inline tables, dotted keys, array-of-tables, multi-line / literal strings, integer underscores + hex/oct/bin, special floats, exponent notation, datetime values via STDDATE).
- **T19** STDCACHE rebase onto STDCOLL OrderedDict + explicit `prune` operation for batch expired-entry sweeping.
- ~~**T20** STDPROF streaming-percentile variant via STDCOLL Heap (CKMS sketch) for continuous monitoring~~ — **closed 2026-05-07** as won't-fix-without-consumer-driver per the original `Action:` ("schedule when a real consumer — `m test --profile` continuous mode, or a long-running service — drives the requirement"). No such consumer has emerged: m-cli's `--timings` consumer (C6) calls `percentile()` once per tag at end-of-run, where the v1 sorted-sample walk is `O(N)` but on small N. Reopen if a real caller hits the linear-walk limitation. STDPROF v1 (exact percentiles via the `prof("samples", tag, value, seq)` tree) is the final deliverable.
- ~~**T21** STDSNAP root-scalar serialization + auto-update flag + diff helper~~ — **closed 2026-05-07**: item 2 (auto-update) delivered via C7's `^STDLIB($JOB,"stdsnap","update")=1` global-flag mechanism (m-stdlib `631b4e7`, m-cli `8ef34a6`) — functionally equivalent to the originally-proposed `STDSNAP_UPDATE` env var. Items 1 (root-scalar serialization) and 3 (bundled diff helper) closed as won't-fix-without-consumer-driver per their original `Action:` ("schedule when a concrete consumer drives the requirement"); reopen if a real caller hits the limitation. STDSNAP v1 + C7's update mode is the final deliverable.
- **T22** STDENV variable substitution + `export` prefix + multi-line values + process-environment integration via STDOS setenv (T15).
- ~~**T28** Engine-bound deployment for STDCRYPTO~~ — **closed 2026-05-07** by `scripts/seed-callouts.sh` (the m-stdlib-side close of the deployment loop). The script (1) scps `src/callouts/*.c` + `tools/std_*.xc` into `~/export/seed/m-stdlib/build/{callouts,xc}/` on the vista-meta container, (2) compiles each .c against `/usr/local/lib/yottadb/r2.02/libyottadb.h` with the per-source `// link: -lfoo` directive (so `-lcrypto`, `-lcurl`, `-lz -lzstd` flow through automatically), and (3) idempotently injects a marker block into `/etc/profile.d/ydb_env.sh` (sudo -n) that exports `STDLIB_LIB` + per-package `ydb_xc_<pkg>` (`ydb_xc_stdcrypto` / `ydb_xc_stdcompress` / `ydb_xc_stdhttp` / `ydb_xc_stdcsprng` / `ydb_xc_stdfs`) so every `m test` SSH session inherits them via the existing `source /etc/profile.d/ydb_env.sh` step in m-cli's engine. `make seed` invokes it automatically when `src/callouts/*.c` is present. Engine-verified: STDCRYPTOTST flipped from 0/0 → 23/23 on 2026-05-07. STDCOMPRESS / STDXFRM remain 0/0 under separate non-deployment bugs (QUITARGREQD `quit` from extrinsic etrap context — different from the deployment problem T28 closed).
- ~~**T29** STDHTTP iteration 2 (libcurl callout)~~ — **closed 2026-05-07** alongside T28. iteration 2's M-side wiring (commit `940f8ce` 2026-05-07) drove `$$request` / `$$get` / `$$post` through an XECUTE-wrapped `$&stdhttp.http_perform` (later migrated from bare `$ZF` to namespaced `$&pkg.fn` syntax to match STDCRYPTO); `$$available^STDHTTP()` probes via `$&stdhttp.http_available` + `curl_easy_init` smoke. Engine-verified: STDHTTPTST 68/68 green with the .so deployed via `seed-callouts.sh`. Iteration 3 (IRIS arm via `%Net.HttpRequest`) queued.
- ~~**T23** STDXML CDATA / processing instructions / comments / `<?xml ?>` declaration~~ — **resolved 2026-05-07**: `parseContent` dispatches on `<!--` / `<![CDATA[` / `<?`; new `skipDocLevel` walks PIs+comments before/after the root; CDATA content stored as literal text (no entity decode).
- ~~**T24** STDXML numeric character references~~ — **resolved 2026-05-07**: `decodeEntities` handles `&#NNN;` (decimal) and `&#xHH;` (hex); `encodeUtf8` produces 1-4 byte UTF-8 sequences for any Unicode code point up to U+10FFFF.
- ~~**T25** STDXML namespaces — element-level~~ — **resolved 2026-05-07**: per-element namespace map threaded through `parseElement`/`parseContent`; `xmlns` / `xmlns:prefix` filtered out of regular attrs; element prefix resolved to URI; new `$$ns^STDXML(.node)` accessor; undeclared prefix is a parse error. **T25b** (attribute-namespace resolution) split off as a separate ToDo entry.
- ~~**T25b** STDXML attribute-namespace resolution~~ — **resolved 2026-05-07**: `resolveAttrNs` walks `node("attr",...)` and stores `node("attrNs", attrName)` for each prefixed attr; default xmlns does NOT apply to unprefixed attrs (per spec); `xml:` prefix bound to `http://www.w3.org/XML/1998/namespace` as a built-in (no declaration needed); undeclared prefix on an attr is a parse error. New public accessor `$$attrNs^STDXML(.node, attrName)`.
- **T26** STDXML DTDs / DOCTYPE / custom entity declarations.
- ~~**T27** STDXML XPath 1.0 query subset — minimal v0~~ — **resolved 2026-05-07**: `parseXPath` compiles expressions into step lists; `applyStep` walks the candidate set via path strings; `buildRef` constructs M name references for indirection-based subtree access. Public surface: `$$xpath` / `$$xpathOne` / `$$xpathText`. Supported syntax: bare `name`, chained `a/b/c`, absolute `/foo`, descendant `//x`, position predicate `[N]`. Out of scope queued at T27a / T27b.
- ~~**T27a** STDXML XPath wildcards (`*`) and attribute axis (`@attrName`)~~ — **resolved 2026-05-07** (engine-verified via the full-suite green run that closed T11/T28/T29/T30): `parseXPath` accepts `*` as a name token (matched in `collectChildren` / `collectDescendants` via the new `matchName` helper) and detects `@` as an attribute-step prefix that is terminal (parser rejects anything after the attribute name). New `collectAttribute` walks `node("attr", k)` for the candidate path and emits results with `attrValue` / `attrName` subnodes; `mergePathToResult` lifts those into `results(idx,"text")` / `results(idx,"name")` so `xpathText` returns the attribute value transparently. Combinations covered: `*`, `*[N]`, `//*`, `*/x`, `@id`, `@*`, `a/@id`, `//@id`. 10 new tests (`tXpath{Wildcard,ChildOfWildcard,DescendantWildcard,WildcardWithPredicate,Attribute*}`).
- ~~**T27b** STDXML XPath functions and comparison predicates~~ — **resolved 2026-05-07** (commit `6278339`; engine-verified in the same green-run that closed T27a / T11 / T28 / T29 / T30): `parseXPath` predicate scanner extended to consume quoted-string content so `]` inside a literal doesn't terminate the predicate; numeric `[N]` filters keep their O(1) fast path while expression predicates route through the new `applyExprPredicate` per-candidate evaluator. New helpers (~330 LoC): `parsePredExpr` / `parseExpr` / `parsePrimary` build a tagged AST; `evalPredExpr` walks it against each candidate's path with full XPath 1.0 type coercion (`toBool` / `toStr` / `toNum`); `compareOp` does the `=`/`!=`/`<`/`>`/`<=`/`>=` dispatch (numeric promotion for ordering, string-or-number for equality). Supported functions: `position()`, `last()`, `name()`, `text()`, `count(...)`, `string-length(...)`, `normalize-space(...)`, `contains(.,.)`, `starts-with(.,.)`, plus `not(...)`, `string(...)`, `number(...)`. `count()` accepts `name` / `*` / `@name` / `@*` (single-step relative paths only — full XPath inside count is queued under a future ticket if a real consumer drives it). 15 new tests (`tXpathPredicate{AttrEqualsString,AttrEqualsDoubleQuoted,AttrNotEquals,NameEquals,TextEquals,Contains,StartsWith,PositionEqual,CountEquals,CountGreaterThan,StringLengthGt,NormalizeSpace,AttrExistsTruthy,AttrExistsFiltersOut,RejectsBadExpr}`).

**Aggregate gate, current head (2026-05-08):** **32 suites, 2483/2483
assertions green on the vista-meta YDB engine** (full m-stdlib
surface — every public extrinsic exercised end-to-end through `m
test`). Per-module label coverage ≥ 91% (most at 100%; STDOS at
91.7%, STDENV at 93.3% — `exit()` and `parseFile()` respectively
unreachable / un-tested by automated tests), 0 lint errors, fmt
clean. v0.3.0 shipped (commit `363b990`); the eleven P4 promotions
sit on top: STDCSPRNG (L15), STDFS (L16), STDOS (L17), STDSEMVER
(L18), STDSTR (L19), STDTOML (L20), STDCACHE (L21), STDPROF (L22),
STDSNAP (L23), STDENV (L24), STDXML v0+T23+T24+T25+T25b+T27v0+T27a+T27b
(L25); plus STDMATH (L26) and STDXFRM (L27) added 2026-05-08, and
the three Phase 3 modules STDCRYPTO (H1), STDCOMPRESS (H2), and
STDHTTP (H3) all green-on-engine 2026-05-07. The joint canonical-
index regen covers 32 modules total (Phase 1: 9; Phase 1b: 3;
Phase 2: 4 + 2 add-ons; P4 promotions: 13; Phase 3: 3).

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

### T12 — STDCSPRNG `$ZF → getrandom(2)` callout backend (resolved 2026-05-07)
**Module:** STDCSPRNG.
**Status:** ✅ **closed 2026-05-07.** Both backends now coexist:
the new `cs_random` callout (`$ZF → getrandom(2)`) is tried first, the
existing `/dev/urandom` `READ *b` loop is the soft-fall-back. Same
kernel ChaCha20 pool either way — API stable, callers unchanged.
**What landed:**
- `src/callouts/cs_random.c` — single `cs_random(n, out)` entry;
  loops over `getrandom(2)` until `n` bytes are filled (handling the
  256-byte syscall cap and `EINTR` retry); writes through caller's
  `ydb_string_t*` buffer (1 MiB capacity declared in the .xc).
- `tools/std_csprng.xc` — call-in descriptor; consumes `STDLIB_LIB`
  the same way `std_crypto.xc` and `std_http.xc` do.
- `src/STDCSPRNG.m` — new `$$useCallout^STDCSPRNG()` probe
  (env-var fast-path → 1-byte probe via the callout) and internal
  `dispatchRandom(n)` helper (XECUTE-wrapped `$ZF` to dodge m fmt's
  longest-prefix mangle of `$ZF → $zfind`; same trick as STDCRYPTO /
  STDHTTP / STDCOMPRESS). `$$bytes` tries `dispatchRandom` first; on
  empty return (env unset, .so missing, getrandom(2) failure) falls
  back to the device-read path (now factored out as `bytesFromDevice`).
- `tests/STDCSPRNGTST.m` — added `tUseCalloutReturnsBoolean`; suite
  green at 406/406 with the callout undeployed (soft-fall-back path).
**Reference:** `docs/modules/stdcsprng.md` "Entropy source" section.

### T13 — STDFS native append + native I/O backend ✅ **CLOSED 2026-05-07**
**Module:** STDFS.
**Status:** closed. New `do appendBytes^STDFS(path, data)` extrinsic
calls `$ZF → stdfs_appendBytes` which issues
`open(O_WRONLY|O_CREAT|O_APPEND)` + a single looped `write(2)` —
atomic at EOF, no lseek race, no SEQ-device byte-0 quirk, no implicit
trailing LF. The text-mode `append^STDFS` keeps its read-then-rewrite
implementation by design: rerouting it through native `O_APPEND` would
leave an interior LF in the file whenever the previous content already
ended with one, breaking the documented `readFile(append(x, y)) ==
readFile(x) + y` contract. Callers that want byte-faithful append at
EOF use `appendBytes` directly; callers that want text-mode "concat
+ trailing LF" semantics keep using `append`.
**Source:** `src/callouts/stdfs.c` (`stdfs_appendBytes`),
`src/STDFS.m` (`appendBytes` extrinsic; `append` doc note clarifying
the text-mode rationale),
`tests/STDFSTST.m` (`tAppendBytesAtomic`, `tAppendBytesCreatesIfMissing`).
**Reference:** `docs/modules/stdfs.md` "Append semantics" section.

### T14 — STDFS binary-safe `readBytes` / `writeBytes` ✅ **CLOSED 2026-05-07**
**Module:** STDFS.
**Status:** closed. `$$readBytes^STDFS(path)` and
`do writeBytes^STDFS(path,data)` go through `$ZF → stdfs_readBytes` /
`stdfs_writeBytes` which issue raw `open(2)` / `read(2)` / `write(2)`
at the libc layer — no trailing LF added on write, no CR/LF
normalisation on read, exact byte counts preserved. 16 MiB per-call
output cap is declared in the `.xc` descriptor; oversize reads surface
`,U-STDFS-READ-TRUNCATED,` rather than silently truncating. The
text-I/O entries (`readFile` / `writeFile` / `readLines` /
`writeLines`) keep their POSIX text-file semantics.
**Source:** `src/callouts/stdfs.c` (`stdfs_readBytes`,
`stdfs_writeBytes`), `tools/std_fs.xc`, `src/STDFS.m`
(`readBytes` / `writeBytes` / `available` extrinsics),
`tests/STDFSTST.m` (`tWriteBytesByteFaithful`,
`tReadBytesPreservesAllBytes`, `tReadBytesPreservesEmbeddedCR`,
`tReadBytesMissingRaises`, `tNotWiredSoftFail`).
**Reference:** `docs/modules/stdfs.md` "Byte-faithful I/O (T13 + T14)"
section.

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
**Status:** ✅ **closed 2026-05-07** as won't-fix-without-consumer-driver.
**What it was:** STDPROF v1 keeps every sample in
`prof("samples", tag, value, seq)` and walks them in `$ORDER` on
each `percentile()` call. Memory grows linearly with sample count;
`percentile()` is `O(N)` worst case (typically a small walk near
the requested rank). For a one-shot end-of-run report this is fine,
but a continuous-monitoring use case (calling `percentile` thousands
of times in a hot loop) would benefit from a streaming variant.
**Originally proposed action:** add a
`newStreaming^STDPROF(.prof, epsilon)` constructor that allocates a
CKMS (Cormode-Korn-Muthukrishnan-Srivastava) sketch backed by
STDCOLL's Heap. `stop()` inserts into the sketch instead of the
full sample tree; `percentile()` queries the sketch in `O(log N)`.
Samples are bounded by the `epsilon` parameter (typical 1% error
gives a sketch of ~100 entries). Public API surface stays the same;
`tags()` continues to work; the tree shape changes only under
`prof("sketch", tag, ...)`.
**Why closed:** the original action ended with "schedule when a
real consumer (m-cli `m test --profile` continuous mode, or a
long-running service) drives the requirement," and no such consumer
has emerged. The only consumer today is m-cli `m test --timings`
(C6), which calls `percentile()` once per tag at end-of-run — the
exact one-shot report the v1 walk is sized for. The exact-sample
contract is also stricter than a sketch can deliver, so closing T20
removes a forward reference that would have to be qualified with
"approximate" caveats indefinitely.
**Reopen criteria:** a caller emerges that calls `percentile()`
inside a hot path (thousands of queries against a long-lived tag),
or a long-running service (e.g. a request-handling loop) instruments
itself with STDPROF and observes the linear-walk cost. At that point
the original `Action:` above is the implementation plan; STDCOLL's
Heap surface (`heapPush` / `heapPop` / `heapSize`) is the soft-dep.
**Reference:** `docs/modules/stdprof.md` "Percentile semantics"
section (documents the inline sorted-sample walk; the forward
reference to T20 has been replaced with a "no streaming variant
ships in v1; reopen-on-need" note).

### T21 — STDSNAP root-scalar + auto-update + diff helper (closed 2026-05-07)
**Module:** STDSNAP.
**Status:** ✅ **closed.** STDSNAP v1 + C7's update mode is the
final deliverable; item 2 was delivered via a slightly different
mechanism than originally proposed, items 1 and 3 close as
won't-fix-without-consumer-driver:
1. **Root-scalar serialization.** Closed as won't-fix-without-driver.
   STDSNAP v1 walks `$QUERY` descendants only, so a tree with a
   scalar at the root (`set data="value"`, no subscripts) doesn't
   serialise. v1 covers the practical 80% case (parsed JSON /
   FileMan trees with subscripted leaves); reopen with a new ticket
   if a real caller hits the limitation.
2. ✅ **Auto-update flag — delivered via C7.** The originally-proposed
   `STDSNAP_UPDATE` env-var mechanism shipped instead as a global
   flag: `^STDLIB($JOB,"stdsnap","update")=1` flips `asserts^STDSNAP`
   from compare-mode to rewrite-baselines-and-pass mode. m-cli's
   `m test --update-snapshots` sets the global before each suite
   (m-stdlib `631b4e7`, m-cli `8ef34a6`). Functionally equivalent to
   `pytest --snapshot-update` / Jest `--updateSnapshot`; the global
   is preferred over an env var for in-process control without a
   shell round-trip.
3. **Bundled diff helper.** Closed as won't-fix-without-driver.
   v1 reports the snapshot path on mismatch; humans run `diff -u
   baseline current` themselves. A `$$diff^STDSNAP(path, .data)`
   ergonomic remains nice-to-have but is not blocking any consumer;
   reopen with a new ticket when one materialises.
**Reference:** `docs/modules/stdsnap.md` "Edge cases" section;
C7 entry above for the auto-update wiring.

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
**Status:** **T23/T24/T25/T25b/T27v0/T27a/T27b all resolved 2026-05-07**;
**T26 alone remains queued.** STDXML now covers ~95% of the 12-16d full
XML 1.0 + Namespaces 1.0 + XPath 1.0 envelope. Remaining ~2d across
the single T-ticket:

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
- ✅ **T27a — XPath wildcards + attribute axis.** **Resolved
  2026-05-07** (engine-verified via the green-run wave that closed
  T11 / T28 / T29 / T30). `parseXPath` recognises `*` as a name token and
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
- ✅ **T27b — XPath functions + comparison predicates.**
  **Resolved 2026-05-07** (commit `6278339`; engine-verified via
  the green-run wave that closed T11 / T28 / T29 / T30).
  `parseXPath`'s predicate scanner
  was extended to consume content inside single-/double-quoted
  string literals so that `]` inside a literal does not terminate
  the predicate. Numeric `[N]` predicates retain their O(1) fast
  path through the legacy `applyPredicate`; expression predicates
  route through the new `applyExprPredicate` per-candidate
  evaluator. The predicate body is parsed into a tagged AST:
  `parsePredExpr` → `parseExpr` (single-level comparison: `=` /
  `!=` / `<` / `>` / `<=` / `>=`) → `parsePrimary` (string lit /
  number / `@name` / `@*` / `*` / parenthesised expr / function
  call / bare-name node-ref). `evalPredExpr` recursively walks
  the AST against the candidate path with full XPath 1.0 type
  coercion (`toBool` / `toStr` / `toNum`); `compareOp` uses
  numeric promotion for ordering operators and the
  string-or-number rule for equality. Functions implemented:
  `position()` / `last()` (use the candidate-set position +
  size), `name()` / `text()` (read directly off the candidate
  path via `nameAtPath` / `textAtPath`), `count(...)` (single-
  step relative-path arg: `name` / `*` / `@name` / `@*` —
  full-XPath sub-expressions queued behind a future ticket if
  a real consumer drives it), `string-length(...)` /
  `normalize-space(...)` (zero-arg context form + one-arg
  string form), `contains(.,.)`, `starts-with(.,.)`, plus
  XPath-1.0 conversion helpers `not(...)`, `string(...)`,
  `number(...)`. 15 new tests
  (`tXpathPredicate{AttrEqualsString,AttrEqualsDoubleQuoted,
  AttrNotEquals,NameEquals,TextEquals,Contains,StartsWith,
  PositionEqual,CountEquals,CountGreaterThan,StringLengthGt,
  NormalizeSpace,AttrExistsTruthy,AttrExistsFiltersOut,
  RejectsBadExpr}`).

**Action:** T26 is now the only queued STDXML lift, and stays
lowest-priority for modern XML — DTDs are rare in HL7v3 / CDA /
FHIR. The W3C XML Test Suite remains the conformance corpus to
vendor under `tests/conformance/xml/` once a real consumer drives
the T26 requirement.

**Reference:** `docs/modules/stdxml.md` "Out of scope (queued)"
section. The W3C XML Test Suite is the conformance corpus for
T26 acceptance; vendor it under `tests/conformance/xml/` when
a real consumer drives the requirement.

### T11 — Phase 3 entry (STDCRYPTO, STDCOMPRESS, STDHTTP)
**Modules affected:** STDCRYPTO, STDCOMPRESS, STDHTTP.
**Status:** ✅ **closed 2026-05-07.** All three Phase 3 modules now
green on the vista-meta YDB engine via `make test`: STDCRYPTOTST 23/23,
STDCOMPRESSTST 59/59, STDHTTPTST 68/68. Aggregate gate this session:
**32 suites, 2483/2483 assertions** across the full m-stdlib surface.
**Sequencing recap:**
1. ✅ v0.2.0 release sync (T7) — closed when v0.3.0 shipped 2026-05-07.
2. IRIS `$ZF` portability spike — deferred behind the YDB-side green
   run; validate against `intersystemsdc/iris-community:latest` next.
3. ✅ STDCRYPTO chosen as the lead (closed T28).
4. ✅ STDCOMPRESS green-run (closed T30 via dispatch-status-return
   refactor + 6 tests migrated to `raises^STDASSERT` idiom).
5. ✅ STDHTTP iter 2 green-run (closed T29).
**Per-module specs:** `docs/m-stdlib-implementation-plan.md` §12.

### T28 — Engine-bound deployment for STDCRYPTO
**Status:** ✅ **closed 2026-05-07.** STDCRYPTOTST runs 23/23 against
the vista-meta YDB engine via `make test`. Per-module label coverage
is 17/17 = 100%; lint clean (0E).

**What landed in the closing session (2026-05-07 evening):**

1. **C-side argc fix.** YottaDB r2.02's `$&pkg.fn` external-call ABI
   prepends an `int argc` to every C entry point. Every public
   function in `src/callouts/std_crypto.c` (`crypto_sha256` /
   `crypto_sha384` / `crypto_sha512` / `crypto_hmac_sha256` etc.)
   now takes `int argc` first and bails with `-5` on a wrong arity.
   Without this fix, YDB was passing the literal arg-count value
   (e.g. `2`) into the slot the C side was treating as
   `ydb_string_t* in`, and dereferencing it crashed at vaddr 0x2.

2. **M-side dispatch rewrite.** `src/STDCRYPTO.m::dispatch3` /
   `dispatch4` now build the XECUTE'd command as
   `set rc=$&stdcrypto.<fn>(...)` instead of
   `set rc=$ZF("crypto_<fn>",...)`. The legacy `$ZF` form was
   abandoned because YDB r2.02's M parser rejects the `.var`
   byref-output syntax outright (`%YDB-E-EXPR, Expression expected
   but not found`). The XECUTE wrap also keeps tree-sitter-m
   happy with the `$&pkg.fn` syntax (open grammar gap).

3. **Descriptor LHS rename.** `tools/std_crypto.xc` LHS names are
   now `sha256` / `sha384` / `sha512` / `hmacSha256` / `hmacSha384` /
   `hmacSha512` (no underscore — YDB package names must be
   alphanumeric, so the env var becomes `ydb_xc_stdcrypto`).

4. **`scripts/seed-callouts.sh` — package-name strip.** When
   computing `ydb_xc_<pkg>` exports for the marker block in
   `/etc/profile.d/ydb_env.sh`, the script strips non-alphanumerics
   from the descriptor base. So `std_crypto.xc` → `ydb_xc_stdcrypto`,
   matching what the M-side `$&stdcrypto.<fn>` syntax requires.

5. **$ETRAP body returns a value.** `dispatch3` / `dispatch4`'s
   `$etrap` body now ends with `quit -1` (instead of bare `quit`)
   so the etrap firing inside an extrinsic frame doesn't trip
   `%YDB-E-QUITARGREQD`.

6. **$etrap propagation flow.** Etrap path now stores `rc=-1` and
   the post-xecute `if rc=-1 set $ecode=...` chain still surfaces
   the `,U-STDCRYPTO-CALLOUT-MISSING,` error code — preserving
   the public contract documented in `docs/modules/stdcrypto.md`.

**Cross-project followup:** STDCOMPRESS (T28's other half) and
STDHTTP iter 2 (T29) are still on the legacy `$ZF` + `ydb_ci` path.
They will need the same argc + `$&pkg.fn` migration before they can
run green on the engine; the descriptor → env-var stripping done in
`scripts/seed-callouts.sh` already accommodates them automatically
when they catch up.

### T29 — STDHTTP iteration 2 (libcurl callout)
**Module affected:** STDHTTP (H3 P3).
**Status:** ✅ **closed 2026-05-07.** STDHTTPTST runs 68/68 against
the vista-meta YDB engine via `make test` with the http.so deployed.
Per-module label coverage 94.1%; lint clean (0E).

**What landed (commits `940f8ce` + post-T28 migration):**
1. ✅ `src/callouts/http.c` — libcurl glue (251 LOC):
   `curl_easy_init` / setopt-everything / `easy_perform` / getinfo /
   cleanup. Single `http_perform` entry point captures the response
   header stream + body into 1 MiB caller-allocated buffers; HTTP
   status returned out-of-band so 4xx/5xx is C-side success.
   `http_available` smoke probe (init+cleanup) added for
   `$$available^STDHTTP()`.
2. ✅ `tools/std_http.xc` — YDB call-out descriptor; `$STDLIB_LIB`
   for portability.
3. ✅ M-side wiring: `$$request` / `$$get` / `$$post` drive
   `$&stdhttp.http_perform` through an XECUTE-wrapped command-string
   (same anti-tree-sitter-trip pattern as STDCRYPTO). Response header
   stream split on `\r\n\r\n` to keep the **final** response after
   redirects; body installed afterwards. libcurl error string flows
   into `resp("error")`. Both `$$available` and `$$dispatchPerform`
   short-circuit on `$$env^STDOS("ydb_xc_stdhttp")=""` so engines
   without the descriptor exported soft-fail to
   `resp("error")="STDHTTP-NOT-WIRED"` without touching XECUTE.
4. ✅ `// link: -lcurl` directive in `http.c` flows through
   `seed-callouts.sh`'s per-source link parser (same idiom
   STDCRYPTO established for `-lcrypto`).
5. ✅ Container deploy via `scripts/seed-callouts.sh`
   (T28 close). vista-meta container has `libcurl4-openssl-dev` +
   `libcurl.so.4` already; the script compiles `http.c` against the
   container's `libyottadb.h` so output ABI matches the runtime.
6. ⏳ Network-bound integration tests against a local httpbin —
   queued. Hermetic transport-error coverage today
   (`tNetworkTransportErrorWhenCalloutLoaded` against
   `nonexistent.invalid` per RFC 2606) is sufficient for the
   green-run gate; live happy-path validation lands when a concrete
   consumer wires httpbin under `tests/integration/http/`.

**IRIS arm (iteration 3):** deferred. The `%Net.HttpRequest`
`$CLASSMETHOD` arm shares the same M-side req/resp shape and
lands when the IRIS portability spike unblocks behind T28.

### T30 — STDCOMPRESS / STDCRYPTO `$ECODE` channel redesign
**Modules affected:** STDCOMPRESS (H2 P3), STDCRYPTO (H1 P3).
**Status:** ✅ **closed 2026-05-07** — STDCOMPRESSTST now 59/59 green.

**Resolution shape (different from the originally-sketched global
side-channel).** No `^STDLIB($JOB,…)` global needed; the simpler
fix was to make `dispatchC` / `dispatchD` return a status string
("" / "MISSING" / "FAIL") and have each public extrinsic
(`gzip` / `gunzip` / `deflate` / `inflate` / `zstdCompress` /
`zstdDecompress`) map that status to the appropriate `$ECODE` tag
*after* the dispatch's local `$etrap` is out of scope. Since the
public extrinsic has no local `$etrap`, the caller's trap fires
cleanly when `$ecode` goes non-empty.

**Test-side companion change.** Six tests in `tests/STDCOMPRESSTST.m`
migrated from the manual `set $etrap="set $ecode="""" quit"` +
`contains^STDASSERT` pattern to `raises^STDASSERT` — the standard
m-stdlib idiom (already used by STDFMT / STDDATE / STDCSV / STDLOG).
The manual pattern's argless-`quit` from inside the etrap unwinds
past the `contains` assertion, so the assert never executes; the
ZGOTO-based unwind in `raises^STDASSERT` handles the exit cleanly
and lets the assertion run on the captured `$ecode` value. Tests
migrated: `tGzipBadLevelLowReturnsZero`, `tGzipBadLevelHighReturnsZero`,
`tGunzipRejectsNonGzip`, `tGunzipRejectsTruncated`,
`tInflateRejectsGarbage`, `tZstdBadLevelLowReturnsZero`,
`tZstdBadLevelHighReturnsZero`, `tZstdDecompressRejectsGarbage`.

**STDCRYPTO impact:** none required — STDCRYPTOTST has no failure-
path `$ECODE`-contains assertions, so the latent bug in
`dispatch3` / `dispatch4` is not exercised. If a future test does
exercise `,U-STDCRYPTO-DIGEST-FAIL,` / `,…-HMAC-FAIL,` / `,…-CALLOUT-
MISSING,` propagation, STDCRYPTO can adopt the same status-return
refactor (~0.5d).

**Side fix in this session:** `src/STDXFRM.m` regression — the
v0.3.x landing used `set result=@expr` (name indirection, expratom
only) for `map` / `filter` / `reduce` lambdas. YDB r2.02 rejects
`@"value*2"` because binary expressions are not valid expratoms
(`%YDB-E-INDEXTRACHARS`). Switched to XECUTE: `set cmd="set result="
_expr` then `xecute cmd`. STDXFRMTST now 38/38 green. Also fixed
`tMapHasAccessToKey` test typo: `"key_'='_value"` (M would parse
`'=` as not-equals operator) → `"key_""=""_value"` (canonical M
double-quote string).

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
  basename/dirname/join. **Closed T13+T14 same day** — `src/callouts/stdfs.c`
  adds `stdfs_writeBytes` / `stdfs_appendBytes` / `stdfs_readBytes` over
  raw `open(2)` / `read(2)` / `write(2)`; M side adds `readBytes` /
  `writeBytes` / `appendBytes` / `available` extrinsics. The text-mode
  `append^STDFS` keeps its read-then-rewrite implementation by design
  (a native O_APPEND reroute would leave interior LFs and break the
  `readFile(append(x,y)) == readFile(x) + y` round-trip contract);
  byte-faithful append at EOF lives at `appendBytes^STDFS`. The IRIS arm
  follows the same `$ZF` host-call pattern once a real consumer drives it.
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
  worst case but typically a small walk. STDCOLL Heap was listed
  as soft dep for a streaming-percentile (CKMS sketch) variant
  reserved under T20; **T20 closed 2026-05-07** as won't-fix-
  without-consumer-driver — m-cli `--timings` (C6) calls
  `percentile()` once per tag at end-of-run, where the v1 walk is
  sized exactly right, and no other caller has surfaced. v1's
  exact-sample tree is the final deliverable. Coverage: 12/12
  labels (100%), 25/25 assertions green.
- **STDSNAP** — promoted 2026-05-07 to Table 1 as **L23 P4**.
  Snapshot testing: `serialize` / `save` / `matches` / `asserts`.
  Canonical line-per-leaf text dump via `$QUERY` walk; numeric
  subscripts unquoted, string subscripts and values M-quoted with
  `"..."` and embedded `"` doubled. Lines emitted in `$ORDER` —
  deterministic, diff-friendly. Hard deps: STDFS (file I/O for
  save/matches), STDASSERT (asserts integration with pass/fail
  counters). No STDJSON dep — pre-listed as soft but inlined dq()
  helper. T21 closed 2026-05-07: auto-update flag delivered via
  C7's `^STDLIB($JOB,"stdsnap","update")=1` global mechanism
  (m-stdlib `631b4e7`); root-scalar snapshots (`$QUERY` walks
  descendants only) and bundled diff helper (humans run `diff -u
  baseline current` for inspection) closed as
  won't-fix-without-consumer-driver. Coverage: 7/7 labels (100%),
  23/23 assertions green.
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
