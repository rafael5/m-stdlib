---
title: m-stdlib — TDD user's guide
status: live
audience: M developers building production code (VistA, FIS-GT.M heritage projects, IRIS sites) who want a runtime-library substrate and a CI/CD-friendly TDD workflow.
companion: modules/index.md (canonical inventory); module-tracker.md (live work board); m-stdlib-implementation-plan.md (per-module specs).
---

# m-stdlib — TDD user's guide

## 1. What this library is

`m-stdlib` is a runtime library that fills the highest-impact gaps in
MUMPS / M's standard library: things every other modern runtime ships
out-of-the-box — assertions, UUIDs, base64, JSON, regex, collections,
datetime, logging, CSV, URL parsing, argparse, XML, and more — but
that M historically shipped only as ad-hoc per-site routines, packages,
or, most often, not at all.

The library is:

- **Pure-M** for the entire shipped surface. No host callouts, no
  platform-specific globals. Routines are upper-case six-or-fewer
  character names per the M routine-name convention, prefixed `STD*`
  (the prefix is reserved family-wide). A vendored build-callouts
  harness (`tools/build-callouts.sh`) is in place for future
  `$ZF`-bound modules; see `docs/module-tracker.md` for what is
  queued behind it.
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
  between YDB and IRIS — `STDREGEX` runs a Thompson-NFA on every
  engine, but the public API is what's portable, not the
  implementation.
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

The artefact this discipline produces is a CI/CD-friendly test corpus
that any downstream consumer inherits — replayable on YDB *and* IRIS
in a few seconds.

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

- **`m-cli`** ships `m fmt` (style enforcement), `m lint` (XINDEX
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

| # | Module | Headline |
|---|---|---|
| 1 | [`STDASSERT`](modules/stdassert.md) | Assertion library — `eq` / `ne` / `true` / `false` / `near` / `raises` / `contains` / `len` + counter `start` / `report`. Wire-protocol-compatible with the m-cli runner. |
| 2 | [`STDUUID`](modules/stduuid.md) | RFC-4122 v4 + RFC-9562 v7 UUIDs. v7 timestamp-prefix sorts in generation order. |
| 3 | [`STDB64`](modules/stdb64.md) | RFC-4648 Base64 — standard alphabet `+ /`, URL-safe variant `- _`, `valid` predicate. |
| 4 | [`STDHEX`](modules/stdhex.md) | RFC-4648 §8 hex — lowercase default, uppercase variant, case-insensitive decode. |
| 5 | [`STDFMT`](modules/stdfmt.md) | Printf-style formatter — subset of Python `str.format` (fill / align / width / precision / type `s d f x X o b`). |
| 6 | [`STDLOG`](modules/stdlog.md) | Structured logger — five levels, four sinks, `kv` or `json` line format. |
| 7 | [`STDDATE`](modules/stddate.md) | ISO-8601 datetime + duration arithmetic (`now`, `fromh`, `toh`, `strftime`, `strptime`, `add`, `diff`). |
| 8 | [`STDCSV`](modules/stdcsv.md) | RFC-4180 CSV parser/writer — every §2 clause, optional file I/O. |
| 9 | [`STDARGS`](modules/stdargs.md) | argparse — long/short/grouped flags, positionals, sub-commands, `--` terminator. |
| 10 | [`STDFIX`](modules/stdfix.md) | Fixture lifecycle — `with` / `invoke` / `register` / `cleanup`. Powers `m test`'s default per-test isolation. |
| 11 | [`STDMOCK`](modules/stdmock.md) | Test-time call interception — `register` / `invoke` / `$$resolve` / `$$called` / `$$args`. |
| 12 | [`STDSEED`](modules/stdseed.md) | TSV / JSON manifest loader for FileMan record fixtures + pluggable filer hook. |
| 13 | [`STDJSON`](modules/stdjson.md) | RFC 8259 JSON parser + serialiser — one M tree node per JSON value. |
| 14 | [`STDREGEX`](modules/stdregex.md) | Thompson-NFA regex engine (literals, classes, groups, alternation, greedy quantifiers, capture, replace, split). |
| 15 | [`STDCOLL`](modules/stdcoll.md) | Collections — Set / Map / Stack / Queue / Deque / Heap / OrderedDict over caller-owned arrays. |
| 16 | [`STDURL`](modules/stdurl.md) | RFC 3986 URI parse / build / encode / decode / valid / normalize / resolve. |
| 17 | [`STDCSPRNG`](modules/stdcsprng.md) | Cryptographic random — bytes / hex / base64 / token / int / uuid4 backed by `/dev/urandom`. |
| 18 | [`STDFS`](modules/stdfs.md) | File-system primitives — read / write / append / exists / remove / size + basename / dirname / join. |
| 19 | [`STDOS`](modules/stdos.md) | Process / env / cmdline helpers — env / pid / cmdline / argv / cwd / user / hostname / exit. |
| 20 | [`STDSEMVER`](modules/stdsemver.md) | SemVer 2.0.0 — valid / parse / compare / matches with caret, tilde, comparator AND-combination. |
| 21 | [`STDSTR`](modules/stdstr.md) | String helpers — pad / trim / replaceAll / split / startsWith / endsWith / case / repeat. |
| 22 | [`STDTOML`](modules/stdtoml.md) | TOML 1.0 subset — top-level pairs + `[section]` tables; string / int / float / bool scalars; `#` comments. |
| 23 | [`STDCACHE`](modules/stdcache.md) | LRU + TTL cache over caller-owned array — new / put / get / has / remove / clear. |
| 24 | [`STDPROF`](modules/stdprof.md) | Wall-clock profiler — start / stop / count / total / mean / min / max / percentile / tags. |
| 25 | [`STDSNAP`](modules/stdsnap.md) | Snapshot testing — serialize / save / matches / asserts; canonical line-per-leaf dump via `$QUERY`. |
| 26 | [`STDENV`](modules/stdenv.md) | `.env` loader + typed accessors — parse / parseFile / valid / has / get / getInt / getBool / getFloat. |
| 27 | [`STDXML`](modules/stdxml.md) | XML 1.0 parser — elements, attributes, CDATA, comments / PI / xml-decl, numeric char refs, namespaces, XPath subset. |

**Aggregate gate, current head:** 1230+ assertions across the suite,
per-module label coverage ≥ 91 % (most at 100 %), 0 lint errors, fmt
clean. See [`modules/index.md`](modules/index.md) for the per-module
gate breakdown and [`module-tracker.md`](module-tracker.md) for live
status, in-flight extensions, and proposed future modules.

## 5. Module reference

Each subsection here is a five-minute orientation. Authoritative
detail (full label list, error codes, edge cases, API examples) lives
in the per-module document linked at the top.

### 5.1 `STDASSERT` — assertions ([detail](modules/stdassert.md))

The cornerstone every other suite uses. Eleven public labels
(`start`, `report`, `eq`, `ne`, `true`, `false`, `near`, `raises`,
`contains`, `len`, `silent`). Each assertion takes counters by
reference (`.pass,.fail`) and emits the line protocol the m-cli
runner consumes without adapter code.

```m
do start^STDASSERT(.pass,.fail)
do eq^STDASSERT(.pass,.fail,$$encode^STDB64("foo"),"Zm9v","RFC-4648 example")
do report^STDASSERT(pass,fail)
```

`raises` captures `$ECODE` from a candidate label running under
`$ETRAP`, supporting both extrinsic chains and procedure-style calls
via a `ZGOTO`-based unwind.

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

For security tokens (session IDs, password resets, JWT salts), prefer
`$$uuid4^STDCSPRNG()` — same RFC-4122 v4 surface but kernel-CSPRNG-
backed.

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
threshold), `SINK` (`stderr` / `stdout` / `global` / `global:^GREF`),
and `FORMAT` (`kv` default, or `json` for one-line JSON-encoded
records via `$$encode^STDJSON`). Output values are emitted raw when
clean, otherwise wrapped in `"…"` with `\\` and `\"` escaping.

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

The runner clears the mock registry between tests automatically.
Single-level resolution — no chained replacement. Per-call args
recorded under `^STDLIB($job,"stdmock",...)` so tests can assert what
the production code passed.

### 5.12 `STDSEED` — fixture data ([detail](modules/stdseed.md))

TSV and JSON manifest loader for FileMan record fixtures.

```
# fixtures/test-patients.tsv
PATIENT	.01=Smith,John	.02=M	.03=2 7 80
PATIENT	.01=Doe,Jane	.02=F	.03=12 1 75
```

```bash
m test --seed fixtures/test-patients.tsv tests/
```

`loadJson` accepts an STDJSON-encoded array of records (same field
shape) for callers who already produce JSON fixtures. Pluggable filer
hook — the default `fileViaDie^STDSEED` invokes `FILE^DIE` and
surfaces `^TMP("DIERR",$J)` as `U-STDSEED-FILER-DIE-ERROR`. Tests
inject a stub filer to run without FileMan.

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
in the corpus README. Recursion through subscripted-by-reference locals
uses the merge-then-pass idiom (YDB's `.x(SUBS)` syntax limit), which
is fully internalised — callers see ordinary-looking
`$$encode^STDJSON(.tree)` calls.

### 5.14 `STDREGEX` — regex ([detail](modules/stdregex.md))

Thompson-NFA engine. Compiled patterns are positive-integer handles;
pattern state lives at `^STDLIB($job,"stdregex",h,...)`;
`$$free^STDREGEX(h)` releases it.

```m
new h,n,out
set h=$$compile^STDREGEX("(\\w+)@(\\w+\\.\\w+)")
write $$search^STDREGEX(h,"contact rmr@example.com"),!     ; 1
do groups^STDREGEX(h,"contact rmr@example.com",.out)
write out(1),!                                              ; rmr
write out(2),!                                              ; example.com
do free^STDREGEX(h)
```

Supported subset: literals, `.`, `^` / `$`, greedy `*` / `+` / `?` /
`{n}` / `{n,}` / `{n,m}`, `[abc]` / `[^abc]` / `[a-z]`, predefined
classes `\d` `\w` `\s`, alternation `|`, capturing `(…)` and
non-capturing `(?:…)`, `\1..\9` backref expansion in `replace`. Out
of scope: back-refs in pattern, lookaround, named groups, Unicode
property classes, inline modifiers, possessive/lazy quantifiers —
`compile` rejects with `U-STDREGEX-UNSUPPORTED`.

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

### 5.17 `STDCSPRNG` — cryptographic random ([detail](modules/stdcsprng.md))

Kernel CSPRNG via `/dev/urandom` (the same source `getrandom(2)` reads
without `GRND_RANDOM`). Use this — not `STDUUID.v4` or `$RANDOM` — for
session tokens, password reset tokens, JWT signing salts, nonces.

```m
write $$bytes^STDCSPRNG(16),!         ; 16 raw bytes (binary-unsafe in print)
write $$hex^STDCSPRNG(16),!           ; 32-char lowercase hex
write $$base64^STDCSPRNG(16),!        ; URL-safe base64 (no padding)
write $$token^STDCSPRNG(24),!         ; URL-safe token, 24 bytes of entropy
write $$int^STDCSPRNG(0,99),!         ; unbiased rejection-sampled int 0–99
write $$uuid4^STDCSPRNG(),!           ; RFC-4122 v4 backed by /dev/urandom
```

`int` rejection-samples on the smallest power of 256 covering the
range, so the distribution is unbiased (no modulo-bias artefact).
`uuid4` round-trips through `$$valid^STDUUID` / `$$version^STDUUID`
identically to `$$v4^STDUUID()` — switch over wherever the UUID is a
security boundary.

### 5.18 `STDFS` — file-system ([detail](modules/stdfs.md))

Centralises the YDB SEQ-device `OPEN`/`USE`/`READ`/`WRITE`/`CLOSE`
dance so consumers don't re-derive deviceparams or trigger the
M-MOD-024 OPEN/CLOSE-deviceparam lint false-positive. Text-mode I/O
plus existence + metadata + pure-string path manipulation.

```m
do writeFile^STDFS("/tmp/note.txt","hello world")
write $$readFile^STDFS("/tmp/note.txt"),!     ; "hello world"
do append^STDFS("/tmp/note.txt"," — line 2")
do readLines^STDFS("/tmp/note.txt",.lines)
write $$exists^STDFS("/tmp/note.txt"),!       ; 1
write $$size^STDFS("/tmp/note.txt"),!         ; byte count
do remove^STDFS("/tmp/note.txt")
write $$basename^STDFS("/a/b/c.tsv"),!        ; "c.tsv"
write $$dirname^STDFS("/a/b/c.tsv"),!         ; "/a/b"
write $$join^STDFS("/a","b","c"),!            ; "/a/b/c"
```

`exists` uses an `OPEN`-with-`timeout=0` probe inside an
`$ETRAP+ZGOTO $zlevel` so it bypasses `$ZSEARCH`'s per-process cache —
a path created and removed inside one M process round-trips correctly.
`writeFile` always emits a trailing LF (POSIX convention); `readFile`
strips it on the way back.

### 5.19 `STDOS` — process / env / cmdline ([detail](modules/stdos.md))

Fills the gaps `$ZCMDLINE` / `$ZJOB` / `$ZTRNLNM` leave behind. Useful
glue for STDARGS-driven scripts that want to inspect env, exit with a
non-zero rc, or report `$JOB` / `$cwd` / hostname.

```m
write $$env^STDOS("HOME"),!           ; ~/  ($ZTRNLNM-equivalent)
write $$pid^STDOS(),!                  ; current $JOB
write $$cmdline^STDOS(),!              ; raw $ZCMDLINE
do argv^STDOS(.args)                   ; whitespace-tokenised
write $$cwd^STDOS(),!
write $$hostname^STDOS(),!
do exit^STDOS(2)                       ; ZHALT 2
```

`splitArgs` is whitespace-only — quote-aware tokenisation tracked on
the dispatch board.

### 5.20 `STDSEMVER` — SemVer 2.0.0 ([detail](modules/stdsemver.md))

Parse / compare / range-match per SemVer 2.0.0. Pure-M (no STDREGEX
runtime dep). Architecturally load-bearing for any future M package
manager — dependency resolution can't exist without this.

```m
write $$valid^STDSEMVER("1.2.3-rc.1+build.5"),!     ; 1
write $$compare^STDSEMVER("1.2.3","1.2.4"),!        ; -1
write $$matches^STDSEMVER("1.2.3","^1.2.0"),!       ; 1 (caret)
write $$matches^STDSEMVER("1.3.0","~1.2"),!         ; 0 (tilde, minor pinned)
write $$matches^STDSEMVER("2.0.0",">=1.0 <2"),!     ; 0 (AND-combined comparators)
do parse^STDSEMVER("1.2.3-rc.1+x",.v)
write v("major"),".",v("minor"),".",v("patch"),! v("prerelease"),!,v("build"),!
```

Range syntax: comparators (`>`, `<`, `>=`, `<=`, `=`), caret (`^`),
tilde (`~`), space-separated AND. Extended range constructs (`||`
OR, hyphen ranges, wildcards, prerelease-aware comparators, npm
`^0.x.y` zero-major narrowing) are tracked in
[`module-tracker.md`](module-tracker.md).

### 5.21 `STDSTR` — string helpers ([detail](modules/stdstr.md))

The pad / trim / split / starts-with / ends-with / case-fold / repeat
basics that show up across every consumer. Pure `$translate` /
`$piece` / `$find` / `$extract` — no `$Z*`, no STDREGEX dep. ASCII-
only.

```m
write $$pad^STDSTR("x",5,"."),!                ; "x...."
write $$padLeft^STDSTR("42",5,"0"),!            ; "00042"
write $$trim^STDSTR("  hi  "),!                 ; "hi"
write $$replaceAll^STDSTR("a,b,c",",",";"),!    ; "a;b;c"
do split^STDSTR("a,b,c",",",.parts)             ; parts(1)="a",parts(2)="b",...
write $$startsWith^STDSTR("hello","he"),!       ; 1
write $$toLowerASCII^STDSTR("ABC"),!            ; "abc"
write $$repeat^STDSTR("-",10),!                  ; "----------"
```

### 5.22 `STDTOML` — TOML 1.0 subset ([detail](modules/stdtoml.md))

Top-level pairs + `[section]` tables + four scalars (string, signed
decimal int, signed decimal float, bool surfaced as 1/0) + `#`
comments. Tree shape: `root("v",path)` + `root("t",path)` where
`path` is a dotted key.

```m
new toml,cfg
set toml="[server]"_$char(10)_"host=""127.0.0.1"""_$char(10)_"port=8080"
do parse^STDTOML(toml,.cfg)
write cfg("v","server.host"),!     ; "127.0.0.1"
write cfg("v","server.port"),!     ; 8080
write cfg("t","server.port"),!     ; "int"
```

Out of scope: arrays, inline tables, dotted keys,
`[[array-of-tables]]`, multi-line / literal strings, integer
underscores + hex/oct/bin, special floats, exponent notation,
datetime values — see [`module-tracker.md`](module-tracker.md) for
the queued extensions.

### 5.23 `STDCACHE` — LRU + TTL ([detail](modules/stdcache.md))

Caller-owned cache tree (no globals). LRU via two-way `seq ↔ key`
maps; TTL is **lazy on access** (no background sweeper). Memoisation,
RPC-result caching, rate-limit windows.

```m
new cache,v
do new^STDCACHE(.cache,100,300)        ; capacity=100, ttl=300s
do put^STDCACHE(.cache,"user:42",.userTree)
if $$has^STDCACHE(.cache,"user:42") write $$get^STDCACHE(.cache,"user:42"),!
write $$size^STDCACHE(.cache),!,$$capacity^STDCACHE(.cache),!
do remove^STDCACHE(.cache,"user:42")
do clear^STDCACHE(.cache)
```

Multiple caches per process are independent (different `.cache`
locals). Time source is `$HOROLOG` collapsed to seconds.

### 5.24 `STDPROF` — wall-clock profiler ([detail](modules/stdprof.md))

Caller-owned profiler tree. `$ZHOROLOG`-backed (microsecond
resolution; ANSI `$HOROLOG` is too coarse). Aggregates: count, total,
mean, min, max, percentile.

```m
new prof,i
do start^STDPROF(.prof,"db.query")
do queryDb()                              ; whatever you're profiling
do stop^STDPROF(.prof,"db.query")
write $$count^STDPROF(.prof,"db.query"),!
write $$mean^STDPROF(.prof,"db.query"),!
write $$percentile^STDPROF(.prof,"db.query",95),!
```

`m test --timings` covers the per-suite case at the subprocess level
without needing STDPROF; STDPROF is the right tool for finer-grained
intra-suite timings (per-test, per-section).

### 5.25 `STDSNAP` — snapshot testing ([detail](modules/stdsnap.md))

Canonical line-per-leaf serialisation via a `$QUERY` walk; save +
match + assert against an on-disk baseline. Force-multiplier for
data-shape tests (parsed JSON trees, FileMan record exports,
RPC responses).

```m
new tree
set tree("a")=1
set tree("b","c")=2
do save^STDSNAP("snapshots/cfg.snap",.tree)
write $$matches^STDSNAP("snapshots/cfg.snap",.tree),!     ; 1
do asserts^STDSNAP(.pass,.fail,"snapshots/cfg.snap",.tree,"config matches")
```

Update mode: when `^STDLIB($job,"stdsnap","update")=1` is set,
`asserts` rewrites the baseline file instead of comparing. Used by
`m test --update-snapshots` to regenerate snapshots after an
intentional output change.

### 5.26 `STDENV` — `.env` loader ([detail](modules/stdenv.md))

Parses `.env` files with the standard subset: bare values
(whitespace-trimmed), double-quoted with `\n \t \r \" \\` escapes,
single-quoted POSIX-literal (no escape processing), `#` whole-line
comments, leading-letter-or-`_` keys. Typed accessors with default-
on-miss-or-mistype.

```m
new env
do parseFile^STDENV("/cfg/dev.env",.env)
write $$get^STDENV(.env,"DB_HOST","localhost"),!
write $$getInt^STDENV(.env,"PORT",5432),!
write $$getBool^STDENV(.env,"DEBUG",0),!         ; 1 for {true,yes,on,1}
```

`getBool` matches `{true, yes, on, 1}` / `{false, no, off, 0}` case-
insensitive. `m test --env PATH` loads `.env` files automatically
before each suite — see m-cli's runner docs.

### 5.27 `STDXML` — XML 1.0 ([detail](modules/stdxml.md))

XML 1.0 parser with namespace support and a useful XPath subset.
Public surface covers what a vista-meta HL7v3 / CDA / FHIR consumer
needs out of the box. Tree shape mirrors STDJSON's caller-owned-tree
convention — `node("name")` (local name) / `node("prefix")` /
`node("ns")` / `node("attr",key)` / `node("attrNs",key)` /
`node("text")` / `node("childCount")` / `node("child",N)`.

```m
new doc,sub
do parse^STDXML("<note id=""1""><body>hi</body></note>",.doc)
write $$rootName^STDXML(.doc),!                   ; "note"
write $$attr^STDXML(.doc,"id"),!                   ; "1"
do childByName^STDXML(.doc,"body",.sub)
write $$text^STDXML(.sub),!                        ; "hi"
```

What's covered:

- **Elements / attributes / text** — well-formed XML 1.0.
- **Comments / processing instructions / `<?xml ... ?>` declaration**
  — consumed and discarded (preamble, intra-document, postamble).
- **CDATA sections** — `<![CDATA[ ... ]]>` content stored verbatim
  (no entity decoding).
- **Entity references** — the five standard entities (`&amp;` `&lt;`
  `&gt;` `&quot;` `&apos;`) plus numeric character references
  (`&#NNN;` decimal, `&#xHH;` hex), with full UTF-8 encoding for
  any code point up to U+10FFFF.
- **Namespaces** — element prefix and attribute prefix both resolved
  against the inherited + local `xmlns` map; `xml:` prefix bound
  built-in. Accessors: `$$ns^STDXML(.node)`,
  `$$attrNs^STDXML(.node, attrName)`. Undeclared prefix is a parse
  error.
- **XPath subset** — `$$xpath` / `$$xpathOne` / `$$xpathText` accept
  bare `name`, chained `a/b/c`, absolute `/foo`, descendant `//x`,
  and the position predicate `[N]`. Results are subtree merges so
  callers walk them like any other parsed-tree node.

`childByName` does the internal `merge` to sidestep the YDB `.x(SUBS)`
syntax limit — recursive descent through a parsed XML tree just works
without callers needing merge-then-pass plumbing themselves. The
parser fails closed on unsupported input (`$$lastError^STDXML()`
identifies the offending construct). Out of scope: DTDs / `<!DOCTYPE>` /
custom entity declarations, XPath wildcards / attribute axis (`@attr`),
and XPath functions / comparison predicates (`[@attr='v']`,
`position()`, `count()`, …) — all tracked in
[`module-tracker.md`](module-tracker.md).

## 6. What's next

Live work — proposed modules, in-flight extensions, deferred ToDos —
is tracked in [`module-tracker.md`](module-tracker.md). Open
toolchain bugs that block or limit m-stdlib work live in
[`../TOOLCHAIN-FINDINGS.md`](../TOOLCHAIN-FINDINGS.md). Release history
is in [`../CHANGELOG.md`](../CHANGELOG.md).

## 7. Cross-references

- [modules/index.md](modules/index.md) — canonical module inventory; one row per shipped module with conformance corpus + cross-module dependency map.
- [module-tracker.md](module-tracker.md) — single-source-of-truth tracker for shipped, in-flight, and proposed modules; live ToDo board.
- [m-stdlib-implementation-plan.md](m-stdlib-implementation-plan.md) — per-module specs (§8) and §9 acceptance gate.
- [parallel-tracks.md](parallel-tracks.md) — dispatch view; current execution status.
- [../TOOLCHAIN-FINDINGS.md](../TOOLCHAIN-FINDINGS.md) — open toolchain bugs with severity, status, and resolution path.
- [../CHANGELOG.md](../CHANGELOG.md) — release history.
