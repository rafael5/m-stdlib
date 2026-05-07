---
title: m-stdlib — TDD user's guide
status: live (2026-05-05)
audience: M developers building production code (VistA, FIS-GT.M heritage projects, IRIS sites) who want a runtime-library substrate and a CI/CD-friendly TDD workflow.
companion: m-stdlib-implementation-plan.md (per-module specs); parallel-tracks.md (dispatch view); modules/index.md (canonical inventory).
---

# m-stdlib — TDD user's guide

## 1. What this library is

`m-stdlib` is a pure-M runtime library that fills the highest-impact
gaps in MUMPS / M's standard library: things every other modern
runtime ships out-of-the-box (assertions, UUIDs, base64, JSON, regex,
collections, datetime, logging, CSV, URL parsing, argparse) but that
M historically shipped only as ad-hoc per-site routines, packages,
or — most often — not at all.

The library is:

- **Pure-M for Phases 1 and 2** (`STDASSERT` … `STDURL`). No host
  callouts, no platform-specific globals. Routines are upper-case
  six-or-fewer character names per the M routine-name convention,
  prefixed `STD*` (the prefix is reserved family-wide).
- **Selectively `$ZF`-bound for Phase 3** (`STDHTTP`, `STDCRYPTO`,
  `STDCOMPRESS`). A vendored build-callouts harness
  (`tools/build-callouts.sh`) compiles per-platform shared objects
  into `so/<platform>/`.
- **YottaDB-first; IRIS-portable where reasonable.** Every module
  passes against the `intersystemsdc/iris-community:latest` image in
  fail-soft CI (`.github/workflows/ci.yml` → `iris-portability-check`)
  except where a feature is structurally engine-specific (e.g. YDB
  `view "TRACE"` for coverage).
- **Sibling to `m-cli`** (the toolchain), `m-standard` (the modern-M
  style guide), and `tree-sitter-m` (the parser). Architectural rule:
  **m-stdlib has priority over m-cli**. When both projects need a
  utility it lands here first; m-cli imports.

### Non-goals

- **Not a framework.** No global registries, no init hook, no
  dependency injection. Each module is a flat routine; you `do`-call
  or `$$`-call public labels.
- **Not a compatibility shim.** Does not paper over differences
  between YDB and IRIS — `STDREGEX` will run a Thompson-NFA on YDB
  and (eventually) dispatch to native `$MATCH`/`$LOCATE` on IRIS,
  but the public API is what's portable, not the implementation.
- **Not a security boundary.** Nothing in m-stdlib enforces
  authentication, authorisation, or input sanitisation across trust
  domains. Treat it as a library, not a gateway.

## 2. Why test-driven, why a library, why now

### TDD-first because the language is unforgiving

M's runtime is forgiving in dangerous ways. Undefined locals are not
an error — `IF undef'=""` quietly evaluates to `0`. Misspelled labels
silently fall through. By-reference parameter passing is a syntactic
choice (`.x` vs `x`) the compiler does not check. The fastest way to
learn that a function is wrong is to call it from production. A test
suite written *before* the implementation flips that sequence: the
fastest way is to assert the contract, watch it fail red, then make
it pass green.

Every module in m-stdlib was built TDD-first:

1. Write the test file with realistic fixtures — `tests/STDxxxTST.m`.
2. Run — confirm a deliberate red (ImportError-equivalent: the
   public label doesn't exist yet, or stubs return safe defaults).
3. Implement — `src/STDxxx.m`.
4. Run — confirm green.
5. `make check` (fmt-check + lint + test) before committing; `make
   coverage` before tagging.

The artefact this discipline produced isn't just working modules —
it's a CI/CD-friendly test corpus that any downstream consumer
inherits. STDJSON ships with 65 tests, STDREGEX with 90 assertions,
STDURL with 150, STDCOLL with 116. Every one of those is replayable
on YDB *and* IRIS in a few seconds.

### A library because the alternative is per-site reinvention

Every M shop with more than a few engineers has a private `^XB*`,
`^DI*`, or `^%Z*` routine that does base64 encoding, JSON parsing,
date arithmetic, or string formatting. Each of those private routines
has its own bug history, its own un-versioned conventions, and its
own opinions about what to do at edge cases. m-stdlib publishes a
canonical answer per concern, with conformance corpora vendored from
the relevant RFCs (RFC-4648 for base64/hex, RFC-4180 for CSV, RFC
8259 for JSON, RFC 3986 for URLs, RFC 4122/9562 for UUIDs).

### Now because the toolchain finally supports it

The library only works because the toolchain landed first:

- **`m-cli`** ships `m fmt` (style enforcement), `m lint` (36 XINDEX
  rules + ASTGREP-driven analyses), `m test` (test discovery +
  execution + TAP/JUnit output + coverage minimums + `--changed`
  diff-driven runs), and `m coverage` (line + branch + LCOV / JSON).
- **`tree-sitter-m`** parses M into a real AST so per-module docs,
  lint rules, and coverage tooling can target language constructs
  rather than line patterns.
- **`vista-meta`** publishes a containerised YottaDB endpoint so
  `make test` runs against a real engine without a host install. CI
  layers an IRIS image on top via `iris-portability-check`.

Without `m fmt --check`, `m lint --error-on=error`, and `m coverage
--min-percent=N`, a TDD discipline at this scale wouldn't be
mechanically enforceable — only socially. The toolchain is what makes
the discipline cheap.

## 3. The CI/CD chain

Every module follows the same gate. The fast inner loop:

```bash
make check        # fmt-check + lint + test — under a minute on the dev box
```

The release-readiness loop (also what GitHub Actions runs):

```bash
make ci           # check + JUnit XML + LCOV coverage at min-percent 85
```

The per-module §9 acceptance gate, applied before any `vN.N.N` tag:

| Gate | Tool | Command | Pass threshold |
|---|---|---|---|
| Format | `m fmt --check` | `make fmt-check` | clean (no diffs) |
| Lint | `m lint --error-on=error` | `make lint` | 0 errors |
| Tests | `m test --format=tap` | `make test` | 100 % assertions pass |
| Coverage | `m coverage --min-percent=85` | `make coverage` | ≥ 85 % per-module label coverage (most modules ship at 100 %) |
| IRIS portability | `iris-portability-check` CI job | (CI only) | fail-soft — surfaces regressions but does not gate merges |

The `make check` invocation talks to vista-meta's YottaDB container
over SSH (`~/data/vista-meta/conn.env`), so there is no host YDB
install to manage. Per-test isolation is on by default (each `t<…>`
label runs inside a `tstart` / `trollback $tlevel-1` wrap via
`STDFIX`); pass `--no-isolation` to `m test` for high-test-count
suites.

## 4. Module inventory

### Phase 1 — pure-M quick wins (`v0.0.1` → `v0.1.0`, shipped 2026-05-05)

| # | Module | Tag | Headline function |
|---|---|---|---|
| 1 | [`STDASSERT`](modules/stdassert.md) | `v0.0.1` | Assertion library — `eq` / `ne` / `true` / `false` / `near` / `raises` / `contains` / `len` + counter `start` / `report`. Wire-protocol-compatible with m-tools `^TESTRUN`. |
| 2 | [`STDUUID`](modules/stduuid.md) | `v0.0.1` | RFC-4122 v4 + RFC-9562 v7 UUIDs. v7 timestamp-prefix sorts in generation order. |
| 3 | [`STDB64`](modules/stdb64.md) | `v0.0.2` | RFC-4648 Base64 — standard alphabet `+ /`, URL-safe variant `- _`, `valid` predicate. |
| 4 | [`STDHEX`](modules/stdhex.md) | `v0.0.2` | RFC-4648 §8 hex — lowercase default, uppercase variant, case-insensitive decode. |
| 5 | [`STDFMT`](modules/stdfmt.md) | `v0.0.3` | Printf-style formatter — subset of Python `str.format` (fill / align / width / precision / type `s d f x X o b`). |
| 6 | [`STDLOG`](modules/stdlog.md) | `v0.0.4` | Structured `key=value` logger — five levels, four sinks, `$$now^STDDATE()` timestamp. |
| 7 | [`STDDATE`](modules/stddate.md) | `v0.0.5` | ISO-8601 datetime + duration arithmetic (`now`, `fromh`, `toh`, `strftime`, `strptime`, `add`, `diff`). |
| 8 | [`STDCSV`](modules/stdcsv.md) | `v0.0.6` | RFC-4180 CSV parser/writer — every §2 clause, optional file I/O. |
| 9 | [`STDARGS`](modules/stdargs.md) | `v0.0.7` | argparse — long/short/grouped flags, positionals, sub-commands, `--` terminator. |

### Phase 1b — TDD primitives (`v0.1.1` → `v0.1.3`, shipped 2026-05-05)

| # | Module | Tag | Headline function |
|---|---|---|---|
| 10 | [`STDFIX`](modules/stdfix.md) | `v0.1.1` | Fixture lifecycle — `with` / `invoke` (one-shot transactional scope), `register`, `cleanup`. Powers `m test`'s default per-test isolation. |
| 11 | [`STDMOCK`](modules/stdmock.md) | `v0.1.2` | Opt-in test-time call interception — `register` / `invoke` / `$$resolve` / `$$called` / `$$args`. |
| 12 | [`STDSEED`](modules/stdseed.md) | `v0.1.3` | Declarative TSV manifest loader for FileMan record fixtures + pluggable filer hook. |

### Phase 2 — pure-M heavy lifting (substance landed; `v0.2.0` tag pending)

| # | Module | Target tag | Headline function |
|---|---|---|---|
| 13 | [`STDJSON`](modules/stdjson.md) | `v0.2.0` | RFC 8259 JSON parser + serialiser — one M tree node per JSON value. |
| 14 | [`STDREGEX`](modules/stdregex.md) | `v0.2.0` | Thompson-NFA regex engine on YDB — full subset (literals, classes, groups, alternation, greedy quantifiers, capture, replace, split). |
| 15 | [`STDCOLL`](modules/stdcoll.md) | `v0.2.0` | Collections — Set / Map / Stack / Queue / Deque / Heap / OrderedDict over caller-owned arrays. |
| 16 | [`STDURL`](modules/stdurl.md) | `v0.2.0` | RFC 3986 URI parse / build / encode / decode / valid / normalize / resolve. |

**Aggregate gate, current head**: 800+ assertions across 16 suites,
per-module label coverage ≥ 95 % (most at 100 %), 0 lint errors, fmt
clean. Phase 2 release waits on the L12 STDREGEX final closeout
(docs/CHANGELOG/release-tag sync — engine and tests already green at
90/90).

## 5. Module reference

Each subsection here is a five-minute orientation. Authoritative
detail (full label list, error codes, edge cases, API examples) lives
in the per-module document linked at the top.

### 5.1 `STDASSERT` — assertions ([detail](modules/stdassert.md))

The cornerstone every other suite uses. Eleven public labels
(`start`, `report`, `eq`, `ne`, `true`, `false`, `near`, `raises`,
`contains`, `len`, `silent`). Each assertion takes counters by
reference (`.pass,.fail`) and emits a `^TESTRUN`-compatible line
protocol so the m-cli runner accepts STDASSERT-driven suites without
adapter code.

```m
do start^STDASSERT(.pass,.fail)
do eq^STDASSERT(.pass,.fail,$$encode^STDB64("foo"),"Zm9v","RFC-4648 example")
do report^STDASSERT(pass,fail)
```

`raises` ships with a known constraint: `$ETRAP`'s arg-less `quit`
fails with `M17 NOTEXTRINSIC` when the trapped error fires deep in an
extrinsic chain. `STDFMT` / `STDDATE` / `STDCSV` ship error-path
tests deferred per the documented P1 in `TOOLCHAIN-FINDINGS.md`.

### 5.2 `STDUUID` — UUIDs ([detail](modules/stduuid.md))

Both v4 (random) and v7 (timestamp-prefix monotonic) per RFC 4122 +
RFC 9562. The v7 implementation matters: it sorts in generation
order under M's natural collation, so `^index($$v7^STDUUID(),...)`
gives you a chronologically-ordered index for free.

API: `$$v4^STDUUID()`, `$$v7^STDUUID()`, `$$valid^STDUUID(s)`,
`$$version^STDUUID(s)`, `$$variant^STDUUID(s)`, plus `parse` /
`format` helpers. Conformance corpus at
`tests/conformance/uuid/rfc4122-vectors.tsv` covers Nil, Max, every
version 1–8, all four variants, mixed/upper case, plus eight
malformed-input rejections.

### 5.3 `STDB64` — Base64 ([detail](modules/stdb64.md))

Standard and URL-safe variants. The URL-safe variant (`- _`, no `=`
padding) is the JWT convention, so STDB64 doubles as the encoding
half of a future JWT helper.

```m
write $$encode^STDB64("foobar"),!         ; Zm9vYmFy
write $$urlencode^STDB64("foo?bar=baz")   ; URL-safe, no padding
```

Five extrinsics: `encode`, `decode`, `urlencode`, `urldecode`,
`valid`. RFC-4648 §10 vectors at `tests/conformance/b64/`.

### 5.4 `STDHEX` — Hex ([detail](modules/stdhex.md))

RFC-4648 §8. Four extrinsics: `encode` (lowercase), `encodeu`
(uppercase), `decode` (case-insensitive), `valid` (even length +
hex digits).

### 5.5 `STDFMT` — printf ([detail](modules/stdfmt.md))

Subset of Python `str.format`. Two extrinsics:

- `$$f^STDFMT(template,a1,…,a9)` — up to 9 positional args.
- `$$fn^STDFMT(template,.args)` — named via local array.

Format spec: `{[name][:[fill][align][width][.precision][type]]}`,
where type ∈ `{s d f x X o b}`. `{{` / `}}` escape literal braces.

```m
write $$f^STDFMT("Hello, {0:>10}!","world"),!     ; "Hello,      world!"
write $$f^STDFMT("{0:.3f}",3.14159),!              ; "3.142"
```

### 5.6 `STDLOG` — structured logging ([detail](modules/stdlog.md))

Five level entry points (`DEBUG` / `INFO` / `WARN` / `ERROR` /
`FATAL`), each accepting an `event` and up to five `key=value` pairs.

```m
do INFO^STDLOG("user.login","userid",duz,"ip",$io,"ua",ua)
; → 2026-05-05T19:10:00.123Z level=INFO event=user.login userid=42 ip=... ua=...
```

Configuration at `^STDLIB($job,"stdlog",...)`: `LEVEL` (per-process
threshold) and `SINK` (`stderr` / `stdout` / `global` / `global:^GREF`).
Output values are emitted raw when clean, otherwise wrapped in
`"…"` with `\\` and `\"` escaping. JSON-line output (consumes
`STDJSON.encode`) is on the v0.2.0 add-on list.

### 5.7 `STDDATE` — datetime ([detail](modules/stddate.md))

Seven extrinsics covering wall-clock and arithmetic:

| Label | Purpose |
|---|---|
| `now` | Current UTC, ms precision, trailing `Z`. |
| `fromh` / `toh` | Convert `$HOROLOG` ↔ ISO 8601 (accepts 2/3/4-piece). |
| `strftime` / `strptime` | `%Y %m %d %H %M %S %j %z %%` directives. |
| `add` | `[-]P[nY][nM][nW][nD][T[nH][nM][nS]]` duration; Feb-29 day-clamp on `+P1Y`. |
| `diff` | `h2 − h1 → PnDTnHnMnS`, sign-prefixed. |

Civil-to-day conversion uses Howard Hinnant's `days_from_civil` over
proleptic Gregorian (verified 1840–2400 incl. all leap-year edge
cases).

### 5.8 `STDCSV` — RFC 4180 ([detail](modules/stdcsv.md))

Four entry points: `$$parse^STDCSV(text,.rows)`,
`$$write^STDCSV(.rows)`, `parseFile^STDCSV(path,callback)`,
`writeFile^STDCSV(path,.rows)`. Covers every RFC-4180 §2 clause
(CRLF / LF / lone-CR record separators, optional trailing
terminator, optional `"…"` field wrapping, embedded `,` / CRLF /
`""` escape) and strips a leading UTF-8 BOM on input. Conformance
corpus at `tests/conformance/csv/`.

### 5.9 `STDARGS` — argparse ([detail](modules/stdargs.md))

Long flags, short flags, grouped count flags (`-vvv`), positionals,
sub-commands, `--` end-of-flags terminator. Four actions:
`store_true` / `store` / `count` / `append`.

```m
new p,ns
set p=$$new^STDARGS()
do flag^STDARGS(p,"verbose","v","count")
do flag^STDARGS(p,"output","o","store")
do parse^STDARGS(p,$ZCMDLINE,.ns)
write ns("verbose"),!,ns("output"),!
```

Args source = `$ZCMDLINE` on YDB, explicit string elsewhere. Per-handle
state under `^STDLIB($job,"stdargs",p,...)`.

### 5.10 `STDFIX` — fixtures ([detail](modules/stdfix.md))

Five public labels enabling per-test isolation:

| Label | Purpose |
|---|---|
| `with(tag,code)` | One-shot transactional scope: opens `tstart`, runs `code`, `trollback`s on exit. |
| `invoke(tag,code)` | Like `with`, but pre-runs setup hooks registered via `register`. |
| `$$active(tag)` | Predicate — is a fixture currently held? |
| `register(tag,setupCode,teardownCode)` | Declarative fixture. |
| `cleanup` | Idempotent rollback of any leaked transactions. |

Why one-shot wrappers and not standalone `setup` / `teardown`? Because
YDB's `TPQUIT` enforces per-routine-frame balance of `tstart` /
`trollback` — a Python-style separately-scoped setup/teardown pair
is structurally impossible. The runner protocol consumes
`with` / `invoke` accordingly, and `m test --no-isolation` opts out.

### 5.11 `STDMOCK` — call interception ([detail](modules/stdmock.md))

Three procedures (`register` / `unregister` / `clear`), three
extrinsics (`$$resolve` / `$$called` / `$$args`), and one
indirection-driven procedure (`invoke`).

```m
do register^STDMOCK("get^DGFUNC","stub^MYTEST")
; production code calls do invoke^STDMOCK("get^DGFUNC",.args)
; — dispatched to stub^MYTEST instead
do clear^STDMOCK
```

The runner clears mock registry between tests automatically (m-cli's
W companion track). Single-level resolution — no chained replacement.
Per-call args recorded under `^STDLIB($job,"stdmock",...)` so tests
can assert what the production code passed.

### 5.12 `STDSEED` — fixture data ([detail](modules/stdseed.md))

TSV manifest loader for FileMan record fixtures.

```
# fixtures/test-patients.tsv
PATIENT	.01=Smith,John	.02=M	.03=2 7 80
PATIENT	.01=Doe,Jane	.02=F	.03=12 1 75
```

```bash
m test --seed fixtures/test-patients.tsv tests/
```

Pluggable filer hook — the default `fileViaDie^STDSEED` invokes
`FILE^DIE` and surfaces `^TMP("DIERR",$J)` as
`U-STDSEED-FILER-DIE-ERROR`. Tests inject a stub filer to run
without FileMan. `loadJson` add-on lands once `STDJSON` is
consumable end-to-end (currently raises `U-STDSEED-NOT-IMPLEMENTED`).

### 5.13 `STDJSON` — JSON ([detail](modules/stdjson.md))

RFC 8259 parser + serialiser. Storage convention: one M tree node per
JSON value, with the type discriminator in the leaf:

| Sigil | Type |
|---|---|
| `o` | object — children at `node(key)` |
| `a` | array — children at `node(i)` |
| `s:VALUE` | string |
| `n:VALUE` | number (canonical numeric string) |
| `t` / `f` | true / false |
| `z` | null |

```m
new root,ok
set ok=$$parse^STDJSON("{""user"":""rmr"",""active"":true}",.root)
write $$type^STDJSON(.root("user")),!         ; string
write $$valueOf^STDJSON(.root("user")),!      ; rmr
write $$encode^STDJSON(.root),!                ; round-trips
```

Curated A3 corpus (23 `y_`, 15 `n_`, 8 `i_` files) at
`tests/conformance/json/` — every vector mapped to an RFC 8259 clause
in the corpus README.

### 5.14 `STDREGEX` — regex ([detail](modules/stdregex.md))

Thompson-NFA on YottaDB; native `$MATCH` / `$LOCATE` dispatch on
IRIS (deferred — pure-M engine runs portably today). Compiled
patterns are positive-integer handles; pattern state lives at
`^STDLIB($job,"stdregex",h,...)`; `$$free^STDREGEX(h)` releases it.

```m
new h,n,out
set h=$$compile^STDREGEX("(\\w+)@(\\w+\\.\\w+)")
write $$search^STDREGEX(h,"contact rmr@example.com"),!     ; 1
do groups^STDREGEX(h,"contact rmr@example.com",.out)
write out(1),!                                              ; rmr
write out(2),!                                              ; example.com
do free^STDREGEX(h)
```

v0.2.0 supported subset: literals, `.`, `^` / `$`, greedy `*` / `+` /
`?` / `{n}` / `{n,}` / `{n,m}`, `[abc]` / `[^abc]` / `[a-z]`,
predefined classes `\d` `\w` `\s`, alternation `|`, capturing `(…)`
and non-capturing `(?:…)`, `\1..\9` backref expansion in `replace`.
Out of scope: back-refs in pattern, lookaround, named groups,
Unicode property classes, inline modifiers, possessive/lazy
quantifiers — `compile` rejects with `U-STDREGEX-UNSUPPORTED`. A
follow-on `STDREGEX_PCRE` (Phase-3-adjacent) ships full PCRE via
`$ZF` to libpcre2.

### 5.15 `STDCOLL` — collections ([detail](modules/stdcoll.md))

Seven by-reference collection types over caller-owned local arrays:

| Type | Headline labels |
|---|---|
| `Set` | `add` / `has` / `remove` / `size` / `clear` / iterate via `$ORDER` |
| `Map` | `put` / `get` / `has` / `remove` / `size` / `clear` |
| `Stack` | `push` / `pop` / `peek` / `size` |
| `Queue` | `enq` / `deq` / `peek` / `size` |
| `Deque` | `pushFront` / `pushBack` / `popFront` / `popBack` / `peekFront` / `peekBack` |
| `Heap` | min-heap with `O(log n)` push / pop, `O(1)` peek; optional payload |
| `OrderedDict` | insertion-ordered; walks via monotonic sequence + reverse map |

Empty-key and empty-pop semantics are silent no-ops / blank returns
rather than `$ECODE`-raising — callers gate on `*Size` to distinguish
empty from a stored `""`.

### 5.16 `STDURL` — URI ([detail](modules/stdurl.md))

RFC 3986. One procedure (`parse`) writes all seven components of a
URI to the caller's array (`scheme` / `userinfo` / `host` / `port` /
`path` / `query` / `fragment`); six extrinsics handle build, encode,
decode, validity, normalization, and reference resolution.

```m
new u
do parse^STDURL("https://user@example.com:8080/p?q=1#f",.u)
write u("scheme"),!,u("host"),!,u("port"),!  ; https / example.com / 8080
write $$normalize^STDURL("HTTP://Example.COM/a/./b/../c"),!
;   → http://example.com/a/c
write $$resolve^STDURL("/foo","http://a/b/c"),!
;   → http://a/foo (RFC 3986 §5.3 transform-references in strict mode)
```

`decode` is intentionally lenient (Python `urllib.parse.unquote`
semantics — malformed `%` sequences pass through as literal text);
`valid` is the strict gate.

## 6. Roadmap — what remains

### 6.1 Phase 2 close (`v0.2.0`)

Substance is on `main`; closing items are administrative or scoped
add-ons:

| Item | Track | What's left |
|---|---|---|
| L12 STDREGEX release sync | L12 | docs/CHANGELOG/tag — engine is 90/90 green. |
| STDLOG JSON-line output | L4 add-on | One-line sink switch consuming `$$encode^STDJSON`. |
| STDSEED `LOADJSON` | L10 add-on | Replace the `U-STDSEED-NOT-IMPLEMENTED` stub now that L11 has shipped. |
| `make check` cleanup | infra | Three pre-existing M-MOD-024/M-MOD-026 lint findings in `tests/STDFIXTST.m`. |

### 6.2 Phase 3 — `$ZF`-backed callout modules

Hard-blocked on `tools/build-callouts.sh` (already shipped, A6).

| Track | Module | Headline function | Notes |
|---|---|---|---|
| H1 | `STDCRYPTO` | SHA-256 / SHA-384 / SHA-512, HMAC, constant-time compare, `$ZF` to `libcrypto`. | Foundation for JWT verify, password hashing, session tokens. |
| H2 | `STDCOMPRESS` | gzip / deflate / zstd via `$ZF` to `libz` / `libzstd`. | Round-trips RFC-1952 + zstd reference vectors. |
| H3 | `STDHTTP` | HTTP/1.1 client (request / response / streaming body) via `$ZF` to `libcurl`. Consumes `STDURL`. | Server-side HTTP is explicitly deferred — separate trade-off space. |

A small reference example (jwt-verify) ships alongside Phase 3 to
exercise STDCRYPTO + STDB64 + STDJSON end-to-end.

### 6.3 Speculative future modules — portability + functional gaps

These are not on the dispatch board today but are the natural
candidates if the library expands further. Each is sketched as
"why it would matter" rather than spec'd in detail.

| Candidate | Headline function | Why it would matter |
|---|---|---|
| `STDXML` | XML parser + serialiser (subset of XPath 1.0). | VistA HL7v3 / CDA / FHIR XML handling. RFC-style conformance corpus available (W3C XML Test Suite). |
| `STDYAML` | YAML 1.2 parser. | Config file ergonomics; preferred to JSON for human-edited configs. |
| ~~`STDTOML`~~ | ~~TOML 1.0 parser.~~ | **Promoted out of this list 2026-05-07** — `STDTOML` shipped as L20 phase P4 with a deliberately narrow v1: top-level pairs + `[section]` tables + string / integer / float / bool scalars + `#` comments. See [`docs/modules/stdtoml.md`](modules/stdtoml.md). Arrays, inline tables, dotted keys, `[[array-of-tables]]`, multi-line / literal strings, integer extensions, special floats, exponent notation, and datetime values all queued at T18. |
| ~~`STDSEMVER`~~ | ~~SemVer parse / compare / range match (`>=1.2.3, <2`).~~ | **Promoted out of this list 2026-05-07** — `STDSEMVER` shipped as L18 phase P4 with valid / parse / compare / matches plus major/minor/patch/prerelease/build accessors. Range subset: `^` / `~` / comparators (`>` `<` `>=` `<=` `=`) / AND-combination. See [`docs/modules/stdsemver.md`](modules/stdsemver.md). `||` OR, hyphen ranges, wildcards, prerelease-aware comparators, and npm `^0.x.y` zero-major narrowing all queued at T16. |
| ~~`STDFS`~~ | ~~File-system primitives — read / write / atomic-replace / `mtime` / `glob`.~~ | **Promoted out of this list 2026-05-07** — `STDFS` shipped as L16 phase P4 with text-mode YDB-only v1 (read/write/append/exists/remove/size + basename/dirname/join). See [`docs/modules/stdfs.md`](modules/stdfs.md). atomic-replace, glob, and binary-safe `readBytes`/`writeBytes` queued at T13/T14 alongside the future `$ZF → libc` callout backend. |
| ~~`STDOS`~~ | ~~Process / env / signal helpers — `$$env(name)`, `$$pid()`, `$$argv()`, `$$exit(rc)`.~~ | **Promoted out of this list 2026-05-07** — `STDOS` shipped as L17 phase P4 with `env` / `pid` / `cmdline` / `argc` / `arg` / `argv` / `splitArgs` / `cwd` / `user` / `hostname` / `exit`. See [`docs/modules/stdos.md`](modules/stdos.md). `setenv`, quote-aware `splitArgs`, and the IRIS arm queued at T15 alongside the `$ZF → libc setenv/getcwd/gethostname` callouts. |
| `STDNET` | TCP / UDP socket primitives. Sits below `STDHTTP` and an eventual `STDDNS`. | Greenfield M services beyond the FileMan-backed VistA tier. |
| `STDCACHE` | LRU + TTL caches over local arrays or a global. | Memoisation, RPC-result caching, rate-limit windows. |
| ~~`STDSTR`~~ | ~~String helpers — `pad`, `trim`, `replaceAll`, `split` (non-regex), `startsWith` / `endsWith`, `toLowerASCII` / `toUpperASCII`.~~ | **Promoted out of this list 2026-05-07** — `STDSTR` shipped as L19 phase P4 with pad / padLeft / padRight, trim / trimLeft / trimRight, replaceAll, split, startsWith / endsWith, toLowerASCII / toUpperASCII, repeat. See [`docs/modules/stdstr.md`](modules/stdstr.md). Unicode whitespace + locale-aware case folding queued at T17. |
| `STDMATH` | `clamp`, `min` / `max` over arrays, `sum`, `mean`, fixed-point arithmetic. | M's native arithmetic is already strong; this is glue around the gaps. |
| `STDXFRM` | Functional list combinators — `map` / `filter` / `reduce` over local arrays via XECUTE'd lambdas. | Modernises the "loop with `$ORDER` and accumulate" idiom. |
| ~~`STDCSPRNG`~~ | ~~Seeded + true cryptographic RNG via `$ZF` to `getrandom(2)`.~~ | **Promoted out of this list 2026-05-07** — `STDCSPRNG` shipped as L15 phase P4 with a `/dev/urandom` backend (kernel ChaCha20 CSPRNG, same source `getrandom(2)` reads without `GRND_RANDOM`). See [`docs/modules/stdcsprng.md`](modules/stdcsprng.md). The `$ZF → getrandom(2)` callout backend is reserved as a future perf-only swap (T12) — public API unchanged. |
| `STDENV` | `.env` file loader for fixture / test data, with type coercion. | CI/CD ergonomic — easier than wiring container env-vars per test. |
| `STDPROF` | Wall-clock / CPU profiler — `start^STDPROF(tag)` / `stop^STDPROF(tag)`, percentile reporting. | Per-test timings inside `m test`; finds slow integration suites without adding instrumentation. |
| `STDSNAP` | Snapshot testing — capture canonical structure, diff on next run. | Reduces hand-written assertions for large data shapes (e.g. parsed JSON trees, FileMan record exports). |

### 6.4 Toolchain gaps that gate the library

Open rows in `TOOLCHAIN-FINDINGS.md` that block or limit m-stdlib
work:

- **P1 / m-cli** — `m test FILE::tLabel` regression (single-test
  mode returns rc=253 silently after the C1 fix). Whole-suite mode
  is healthy. Dev-loop hit when iterating on one failing label.
- **P1 / m-stdlib** — `STDASSERT.raises` `$ETRAP` arg-less `quit`
  hits `M17 NOTEXTRINSIC` deep in extrinsic chains. Affects deferred
  error-path tests in STDFMT / STDDATE / STDCSV. Fix is `ZGOTO`-based
  unwind or a parallel `raisesx^STDASSERT`.
- **P2 / YDB** — `$ETRAP` that `trollback`s its own scope then
  re-raises does not propagate to outer trap. Surfaced building
  STDFIX. Worth a minimal-repro upstream report.
- **P2 / m-cli** — `M-MOD-024` false positive on `OPEN` / `CLOSE`
  device-param lists; `M-MOD-020` false positive on by-ref test-suite
  idiom. Both currently silenced by file-wide `; m-lint:` directives.
- **P3 / m-cli** — Default-isolation throughput on high-test-count
  suites + stdout buffering interaction with external `timeout` /
  `tee`. Documented workaround: `--no-isolation`.

### 6.5 Portability open questions

- **IRIS native-class dispatch**. Today the library compiles and
  passes against `iris-community:latest` because every module is
  pure-M (or, for Phase 3, behind a callout boundary). What we have
  not yet exercised: `$ZF` callouts on IRIS (the equivalent is
  `$ZF` style invocation of system functions or class-method
  bridging). Phase 3 needs an IRIS pass before `STDCRYPTO` /
  `STDCOMPRESS` / `STDHTTP` ship.
- **GT.M permanently out** — the project's locked decision. Anyone
  forking m-stdlib for GT.M would need to remove the `view "TRACE"`
  coverage hooks and the `tstart` rollback levels; non-trivial.
- **Real-corpus validation** — `m-modern-corpus` (parent-plan track
  P3) seeds 5–10 non-VA M projects whose suites should pass against
  m-stdlib unchanged. Until that lands, the library is exercised only
  against its own test corpus.

## 7. Cross-references

- [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md) — per-module specs (§8) and §9 acceptance gate (the canonical authority).
- [parallel-tracks.md](parallel-tracks.md) — dispatch view; current execution status; pick-list.
- [tdd-orchestration-plan.md](tdd-orchestration-plan.md) — joint m-stdlib ↔ m-cli milestone narrative (M0 – M5).
- [modules/index.md](modules/index.md) — canonical module inventory; one row per shipped module with conformance corpus + cross-module dependency map.
- [../TOOLCHAIN-FINDINGS.md](../TOOLCHAIN-FINDINGS.md) — open toolchain bugs with severity, status, and resolution path.
- [../CHANGELOG.md](../CHANGELOG.md) — release history.
