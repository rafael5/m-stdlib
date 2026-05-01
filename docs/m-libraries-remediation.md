---
title: M libraries — remediation strategy and prioritised roadmap
status: planning complete — decisions locked (§11), plan finalised (§12), questions answered (§13). Phase 0 implementation deferred to a future session.
last-reviewed: 2026-04-30
upstream: docs/m-libraries-survey.md
adjacent-projects:
  - m-cli (formatter, linter, test runner, coverage, LSP)
  - tree-sitter-m (grammar, VS Code extension)
  - m-standard (this repo — provenance, schemas, conflicts)
  - m-tools (legacy reference, ^TESTRUN assertion library)
---

# M libraries — remediation strategy and prioritised roadmap

> Companion to [m-libraries-survey.md](m-libraries-survey.md). The
> survey enumerated the gaps in the M standard library across ANSI,
> IRIS-M, and YottaDB. This report turns that into a build plan: what
> to write, in what order, with what tools, and what tooling-gap work
> has to land alongside it.

---

## Table of contents

1. [Executive summary](#1-executive-summary)
2. [Prioritisation framework — impact × difficulty](#2-prioritisation-framework--impact--difficulty)
3. [ANSI on-paper surface in 2026 — implement, polyfill, or skip?](#3-ansi-on-paper-surface-in-2026--implement-polyfill-or-skip)
4. [Phase 0 — toolchain readiness](#4-phase-0--toolchain-readiness)
5. [Phase 1 — pure-M quick wins](#5-phase-1--pure-m-quick-wins)
6. [Phase 2 — pure-M heavy lifting](#6-phase-2--pure-m-heavy-lifting)
7. [Phase 3 — host-call integrations](#7-phase-3--host-call-integrations)
8. [Recommended dev environment](#8-recommended-dev-environment)
9. [CI/CD reference design](#9-cicd-reference-design)
10. [Dev-tooling gap list (prioritised)](#10-dev-tooling-gap-list-prioritised)
11. [Decisions](#11-decisions)
12. [Finalised implementation plan](#12-finalised-implementation-plan)
13. [Final implementation answers](#13-final-implementation-answers)

---

## 1. Executive summary

The recommended remediation is a **new sibling project, `m-stdlib`** —
a pure-M (and selectively `$ZF`-based) library that fills the highest-impact
gaps from the survey, written **in a Pythonic project shape** (TDD-first,
ruff-class linter, branch-protected CI, signed releases) using the
`m-cli` toolchain at every step. The library is itself the proof that
the toolchain is production-grade.

**Three load-bearing observations.**

1. **The toolchain is more mature than it looks.** `m-cli` already
   ships `m fmt` (canonical formatter), `m lint` (37 XINDEX rules + 35
   M-MOD modernisation rules across 7 profiles), `m test` (parser-aware
   discovery with TAP/JSON/text outputs), `m watch`, `m coverage`
   (lcov/json/text), and `m lsp` (full pygls-based LSP with hover,
   completion, formatting, code actions, definition, references,
   document symbols, code lens, folding, signature help, document
   highlight). A VS Code extension wires it up. **No new tools are
   required for Phase 1.** Publication of `m-cli` (PyPI) and
   `tree-sitter-m` (npm/PyPI/crates.io/Go) is **deliberately deferred
   until after Phase 1.** m-stdlib is the validation harness for the
   toolchain; shipping `0.1.0` artifacts to strangers before the API
   surface has been stress-tested by 8 real modules just produces a
   churn of patch releases for fixes nobody outside is waiting on. In
   the meantime, m-stdlib's CI and devcontainer install both from git
   checkouts (`pip install -e` from a clone) — see §8.2 and §9.1.

2. **The ANSI on-paper surface is not worth implementing in 2026.**
   §3 walks the 6 functions / 14 commands / 1 ISV item by item. None
   of them retain real-world utility today — most are 1995 hopes for
   features that overtaking technologies (JSON, structured exceptions,
   modern source control, OS signals) handled differently. A two-line
   `$TYPE` polyfill could be supplied for code-archaeology
   compatibility, but is not in the critical path.

3. **The biggest productivity wins are pure-M and small.** The Phase 1
   set in §5 (UUID, hex/base64, ISO-8601 datetime, printf-style
   formatter, structured logger, CSV, argparse, assertion helpers) is
   eight modules of ~100–400 M lines each. Each one targets a top-15
   survey gap, exercises every part of the m-cli toolchain, and ships
   in days, not weeks. Phase 2 (JSON, regex shim, collections,
   url-encoding) is harder but achievable in pure M. Phase 3 (HTTP,
   crypto, compression) needs `$ZF` callouts to libcurl / OpenSSL /
   libz — that's not a tooling problem, it's a binding problem.

**Recommended sequencing.**

| Phase | Modules | Effort | Why this order |
|---|---|---|---|
| **0** | pin assertion library; container ready | ~half day | bootstrap m-stdlib |
| **1** | UUID, B64/HEX, ISO-8601 datetime, printf, structured logger, CSV, argparse, ASSERT | ~2 weeks | high impact + low difficulty + exercises every m-cli capability |
| **2** | JSON, URL, collections (Set/Map/Stack/Queue/Heap), regex shim | ~6 weeks | high impact, harder; depends on Phase 1 (assertions, formatter) |
| **3** | HTTP client, crypto (SHA, HMAC, AES, Ed25519), compression (gzip/zstd) | ~6 weeks | high impact, requires `$ZF` and per-platform build |
| **skip** | ANSI on-paper surface; locale/i18n; pub-sub | — | low or zero return |

---

## 2. Prioritisation framework — impact × difficulty

The 20-rank gap list in `m-libraries-survey.md §11` is a 1-D ranking by
productivity impact. To turn it into a build plan we add a second axis:
**implementation difficulty in M as it exists in 2026.** Difficulty
factors:

- **Pure-M vs needs `$ZF`.** Pure-M is portable, testable in CI without
  C toolchains, and demos the m-cli capabilities cleanly. `$ZF` work
  drags in build-system complexity and per-platform variance.
- **Spec size and edge cases.** A correct CSV parser is ~300 lines; a
  correct JSON parser is ~1500; a correct regex engine is ~5000. UUID
  is ~80.
- **Conformance pressure.** "Good-enough" UUID is fine. "Good-enough"
  JSON is not — anything talking JSON to the outside world has to be
  RFC-8259 compliant on Unicode escapes, number ranges, and nesting.
- **Cross-vendor portability cost.** YDB-only and IRIS-only differ in
  byte-vs-char string handling (`$ZASCII` vs `$ASCII`), in datetime
  primitives, and in how `$ZF` is configured. A library that targets
  both takes ~1.5× the work of one that targets one engine.

### 2.1 The matrix

```
                     Implementation difficulty →
                     LOW                            HIGH
                     ┌────────────────────┐       ┌──────────────────────┐
            HIGH    │ PHASE 1 (do first)  │       │ PHASE 2 / 3          │
              ▲     │ • UUID v4 / v7      │       │ • JSON parser/serial │
              │     │ • Base64 / Hex      │       │ • Regex engine (YDB) │
              │     │ • ISO-8601 datetime │       │ • Collections (gen)  │
              │     │ • Printf-style fmt  │       │ • HTTP client (TLS)  │
   Impact     │     │ • Structured logger │       │ • Crypto (SHA/HMAC/  │
   on dev     │     │ • CSV (RFC-4180)    │       │   AES/Ed25519)       │
   productivity     │ • Argparse          │       │ • Compression        │
              │     │ • Assertion lib     │       │ • Url parsing        │
              │     │                     │       │                      │
              │     ├─────────────────────┤       ├──────────────────────┤
              │     │ PHASE 3-late /      │       │ SKIP                 │
              │     │ niche               │       │ • $DEXTRACT/$DPIECE  │
              │     │ • Path utils        │       │ • ABLOCK/ASTART/...  │
              ▼     │ • $TYPE polyfill    │       │ • RLOAD/RSAVE        │
            LOW     │ • Compression flags │       │ • Locale / i18n      │
                    │ • CLI scaffolder    │       │ • Async file watcher │
                    └─────────────────────┘       └──────────────────────┘
```

The sequencing rule is: **ship the top-left quadrant first.** It produces
the assertion infrastructure (M's missing testing primitive) that every
later phase needs, and it builds confidence that the m-cli toolchain
covers the full edit→lint→test→coverage→ship cycle. The top-right
quadrant ships next, leaning on the Phase 1 assertion library and
structured logger. The bottom-left quadrant fills in opportunistically.
The bottom-right quadrant is permanently skipped.

### 2.2 What goes where, and why

| Survey rank | Gap | Phase | Why |
|---:|---|---|---|
| 1 | Serialisation (JSON / CSV / XML) | 1 (CSV) + 2 (JSON) | CSV is small + RFC-clean; JSON is the keystone of Phase 2 |
| 2 | HTTP client/server | 3 | TLS forces a `$ZF` binding |
| 3 | Regex | 2 | YDB needs an in-language engine; IRIS already has `$MATCH` |
| 4 | Datetime + timezone | 1 | Pure M arithmetic on `$HOROLOG`; medium-sized |
| 5 | Printf / formatting | 1 | Pure M; small; unblocks logging and error formatting |
| 6 | Testing framework | 1 | Assertion lib is the cornerstone — every phase calls it |
| 7 | Structured logging | 1 | Pure M; small; depends on printf |
| 8 | Crypto | 3 | Has to be `$ZF` binding to OpenSSL/libsodium |
| 9 | Path / filesystem | 3-late | Modest impact, easy when needed |
| 10 | Encoding (base64/hex) | 1 | Pure M, ~150 lines each, tested against RFC vectors |
| 11 | Concurrency primitives | (defer) | Globals + JOB + LOCK is *adequate* for M's idioms |
| 12 | Structured exceptions | (defer) | TRY/CATCH is an IRIS command, not a library; YDB's `$ETRAP` patterns are well-established |
| 13 | Iterators / map / filter | (defer) | Stylistic; M's `$ORDER` loop is fine |
| 14 | Type introspection | n/a | Not realistically achievable without a static type system |
| 15 | UUID | 1 | Pure M, small; depends on `$ZHOROLOG` + `$RANDOM` |
| 16 | CSV | 1 | (see rank 1) |
| 17 | Compression | 3 | `$ZF` to libz/libzstd |
| 18 | Argparse | 1 | Pure M; small; depends on YDB `$ZCMDLINE` or IRIS equivalent |
| 19 | Locale / i18n | skip | Most M deployments are single-locale |
| 20 | Async file watch | skip | Niche |

---

## 3. ANSI on-paper surface in 2026 — implement, polyfill, or skip?

The survey identified **6 intrinsic functions, 14 commands, and 1 ISV**
that AnnoStd defines but no current engine implements. The question:
should `m-stdlib` provide M-language polyfills for any of them?

### 3.1 Walkthrough

| Item | What ANSI defined it for | Relevance in 2026 | Recommendation |
|---|---|---|---|
| `$DEXTRACT` | extract field from delimited fixed-width record | record formats with type templates were the 1980s answer to JSON. Modern equivalents: JSON, protobuf, Avro. | **Skip.** A user with a fixed-width parser need is better served by `STDFMT` + `$EXTRACT`. |
| `$DPIECE` | piece extraction with init-record argument | same. | **Skip.** |
| `$HOROLOG(intexpr)` | functional form returning a date string for an offset | superseded by `$ZDATE` (multi-vendor) and the Phase 1 ISO-8601 module. | **Skip.** The Phase 1 module covers the use case better. |
| `$MUMPS(expr)` | "is this a syntactically-valid M expression" predicate | could be implemented via the `tree-sitter-m` parser. Useful for *code-analysis tools*, not application code. | **Skip in stdlib.** Could appear as `m parse` in m-cli if anyone wants it; not a library function. |
| `$TYPE(expr)` | introspect the locator-class of an expression | always weak in M (no static types). `$DATA` covers the only commonly-needed flavor. | **Optional ~10-line polyfill** in `STDTYPE.m` returning `"number"/"string"/"oref"/"undef"`. Cheap, non-essential. |
| `$Z` (open) | open-ended Z-namespace placeholder | meaningless in 2026 — every vendor populated `$Z*` themselves. | **Skip.** |
| `ABLOCK`, `AUNBLOCK`, `ASTART`, `ASTOP`, `ASSIGN` | block / start / stop the asynchronous-event mechanism | the asynchronous-event mechanism was never implemented by any vendor. The 2026 equivalents — POSIX signals (`$ZSIGPROC`), interrupts (`$ZINTERRUPT`), triggers (`$ZTRIGGER`) — solved the problem differently. | **Skip.** No coherent way to polyfill an event mechanism that the engine doesn't support. |
| `ESTART`, `ESTOP`, `ETRIGGER` | event-spec management for the same async system | same. | **Skip.** |
| `KSUBSCRIPTS`, `KVALUE` | selective KILL flavors | superseded by `ZKILL` (multi-vendor) and the `KILL (lvn,...)` exclusive form. | **Skip.** Document the modern equivalent in `STDDB.m` if/when collections module covers it. |
| `RLOAD`, `RSAVE` | load/save routine source as data | superseded by ordinary file I/O + `ZLINK` / `ZCOMPILE` and modern source control. | **Skip.** |
| `THEN` | line-continuation token | parser-level concept never used in real code. | **Skip.** |
| `Z` (open meta-command) | open-ended Z-namespace placeholder | same logic as `$Z`. | **Skip.** |
| `$ZUNSPECIFIED` | open-ended Z ISV placeholder | same. | **Skip.** |

### 3.2 Aggregate verdict

**Implement: zero.**
**Polyfill: at most one** (`$TYPE` as a 10-line convenience in `STDTYPE.m`).
**Skip: 20 of 21.**

The one borderline case is **selective-kill**. ANSI's `KSUBSCRIPTS` and
`KVALUE` are conceptually present in the modern world (kill-only-children,
kill-only-value) — but the M syntax for them already exists as `ZKILL`
(multi-vendor) and `KILL (lvn,...)` (exclusive form, ANSI). A library
function adds nothing.

The on-paper surface is essentially **historical residue** of an
abandoned 1995 standardisation effort. Modern M code uses none of it,
and `m-stdlib` resources are better spent on Phase 1.

---

## 4. Phase 0 — toolchain readiness

### 4.1 What already exists (per memory and m-cli docs)

| Capability | Tool | Status |
|---|---|---|
| Format M source | `m fmt` (canonical layer) | shipped |
| Lint M source | `m lint` (37 XINDEX + 35 M-MOD rules, 7 profiles) | shipped |
| Run unit tests | `m test` (parser-aware discovery, TAP/JSON output) | shipped |
| Watch + re-test | `m watch` | shipped |
| Code coverage | `m coverage` (lcov/json/text/lines) | shipped |
| LSP for editor | `m lsp` (10 capabilities advertised) | shipped |
| VS Code extension | `tree-sitter-m-vscode` | shipped |
| Pre-commit hook scaffold | `.pre-commit-hooks.yaml` | shipped (`language: system`) |
| Project config | `.m-cli.toml`, `[tool.m-cli]` in `pyproject.toml` | shipped |
| Tree-sitter grammar | `tree-sitter-m` v0.1, 4 bindings green | shipped (publish pending) |

That's an unusually complete stack. The "Pythonic" half of "modern
Pythonic dev workflow" is already in place — m-cli ships behind `uv`
+ `ruff` + `mypy` + `pytest` and follows the project's Tier-1 TDD rule.

### 4.2 What still has to land before m-stdlib starts

There is exactly one P0 prerequisite — the assertion-library decision,
**resolved in §11.4**:

1. **STDASSERT is canonical.** `m test`'s discovery convention
   (`t<UpperCase>(pass,fail)`) is unchanged; only the assertion
   vocabulary inside test labels switches from `^TESTRUN` to STDASSERT.
   m-stdlib does not depend on m-tools. See §13.2 for the open
   sub-question on whether m-cli needs a STDASSERT-aware recogniser
   before v0.0.1.

**Publication of `m-cli` and `tree-sitter-m` is explicitly NOT a Phase 0
task.** Both already install today from a git checkout via
`pip install -e`, which is what the Dockerfile in §8.2 and the CI
workflow in §9.1 use as the active install path. The premise of
m-stdlib is that it stress-tests the toolchain by writing eight real
modules against it; releasing public artifacts before that validation
ships unproven code to strangers. The right time to publish is **after
Phase 1 ships and the API surface has survived eight modules of real
use** — see §10's post-Phase-1 tier.

### 4.3 What to defer

These are real gaps but not P0 for starting m-stdlib:

- DAP debugger for VS Code (`m debug` would be a nice m-cli
  subcommand — not on the critical path; `ZBREAK` from the terminal
  works).
- Documentation generator (`m docs` would extract `; doc:` comments
  from labels — could ship at v1.0 after the API surface stabilises).
- Project scaffolder (`m new <project>` — convenience, not a blocker).
- Mutation testing, fuzzing — niche.

§10 enumerates these with priorities.

---

## 5. Phase 1 — pure-M quick wins

Eight modules. Each module is a single M routine plus its `*TST.m` test
suite, written test-first, documented in `docs/modules/<name>.md`,
covered by `m coverage`, and exercised in CI on a YottaDB container.

**Naming convention proposed.** Routines use prefix `STD` for "M stdlib"
to avoid collisions with VistA's package-prefix conventions and the
IRIS `%` system-routine namespace. Test suites add the `TST` suffix
that `m test` discovery already understands. Library globals use
`^STDLIB($J,...)` for per-process state and `^STDLIBC(...)` for shared
config.

| # | Module | Routine | Solves survey rank | LoC est. | Tests |
|--:|---|---|---|---:|---:|
| 5.1 | UUID v4 + v7 | `STDUUID.m` | #15 | ~120 | ~30 |
| 5.2 | Base64 + Hex | `STDB64.m` + `STDHEX.m` | #10 | ~200 each | ~40 each |
| 5.3 | ISO-8601 datetime | `STDDATE.m` | #4 | ~400 | ~80 |
| 5.4 | Printf-style formatter | `STDFMT.m` | #5 | ~300 | ~60 |
| 5.5 | Structured logger | `STDLOG.m` | #7 | ~200 | ~40 |
| 5.6 | CSV (RFC-4180) | `STDCSV.m` | #16 / #1 | ~300 | ~50 |
| 5.7 | Argparse | `STDARGS.m` | #18 | ~400 | ~50 |
| 5.8 | Assertion library | `STDASSERT.m` | #6 | ~150 | ~40 |

**Total: ~2300 LoC of M, ~430 test cases.** At a sustained TDD pace
this is roughly two weeks of focused work for one developer.

### 5.1 STDUUID — UUID v4 and v7

```m
STDUUID ; M UUID generator (RFC 4122) ; 2026-04-30
        QUIT
        ;
V4()    ; Generate a v4 UUID. Returns "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".
        ; Random bytes from $RANDOM (NOT cryptographically strong).
        NEW r,i,b S r=""
        F i=1:1:16  S b=$R(256),r=r_$$HEX(b)
        ...

V7()    ; Generate a v7 UUID (time-ordered).
        ; First 48 bits = ms since epoch (from $ZHOROLOG on YDB,
        ; $ZTIMESTAMP on IRIS), remaining 80 bits = random.
        ...
```

**Why it's the first module to ship.** UUID is *small*, *useful*, and
*touches every m-cli capability in one suite*: `$RANDOM` and string
manipulation (lints clean), pure-M output (formatter loves), well-known
RFC test vectors (assertions are unambiguous), runs in <1 ms (coverage
captures per-line), and the API is single-function (LSP hover surfaces
clean documentation). Treat it as the toolchain shakedown.

### 5.2 STDB64 + STDHEX — encoding

RFC-4648 base64 (standard alphabet + `-_` URL-safe alphabet) and
lowercase/uppercase hex. Pure M; the hot loop is `$EXTRACT` + table
lookup in a fixed alphabet string. Test vectors come from RFC-4648
section 10. **Replaces** YDB's idiosyncratic `ZYENCODE`/`ZYDECODE`
with an interoperable encoding.

### 5.3 STDDATE — ISO-8601 datetime

Convert between `$HOROLOG` and `"2026-04-30T15:30:00Z"`. Handles:

- Timezone offsets (`+HH:MM`, `-HH:MM`, `Z`).
- Date-only forms (`YYYY-MM-DD`), time-only forms (`HH:MM:SS`).
- Sub-second precision (`.SSS`, `.SSSSSS`).
- Leap-day arithmetic (`$HOROLOG` is days since 1840-12-31 — proleptic
  Gregorian).
- Duration arithmetic (`P1DT2H30M` ↔ seconds).

Why ship this in Phase 1. Logs, audit, billing — everything timestamps.
YDB has nothing for ISO-8601; IRIS has format codes but not a clean
`STRFTIME^STDDATE($H, "%Y-%m-%dT%H:%M:%S%z")` API. **Single best
candidate to demo the toolchain on a non-trivial problem.**

### 5.4 STDFMT — printf-style formatter

API:

```m
S out=$$F^STDFMT("Hello, {}! You have {} messages.","Alice",42)
S out=$$F^STDFMT("Score: {:>10.2f}",3.14159)   ; right-align, 2 decimals
S out=$$F^STDFMT("{user}: {msg}",.subs)         ; named args from local
```

**Builds on:** `$JUSTIFY`, `$FNUMBER`. **Used by:** `STDLOG`, every
later module's error messages.

### 5.5 STDLOG — structured logger

Levelled logger (`DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`) with two
output formats: `key=value` text and JSON-line (the latter requires
`STDJSON` from Phase 2 — until then, ship text-only).

```m
D INFO^STDLOG("user.created","user_id",1234,"email","a@b.c")
;; 2026-04-30T15:30:00.123Z INFO  user.created user_id=1234 email=a@b.c
```

**Builds on:** `STDFMT`, `STDDATE`. **Used by:** every later module.

### 5.6 STDCSV — RFC-4180 CSV

Parser that handles quoted fields, embedded `,` and `\n`, and `""`
escapes. Writer that emits RFC-clean output. Field-callback or
list-result API. ~300 lines.

Why Phase 1. CSV is *the* lingua franca for tabular data exchange and
is one of the few formats where "good enough" parsing is genuinely bad
(broken on quoted commas).

### 5.7 STDARGS — argparse

Long flags (`--verbose`), short flags (`-v`), grouped short flags
(`-vvv`), positional args, sub-commands, `--` terminator. Reads from
`$ZCMDLINE` on YDB; on IRIS, takes the args list explicitly.

```m
N parser S parser=$$NEW^STDARGS("mytool","Process M routines.")
D ADDFLAG^STDARGS(parser,"--verbose","-v","count","verbosity")
D ADDPOS^STDARGS(parser,"input","filename")
N args S args=$$PARSE^STDARGS(parser,$ZCMDLINE)
W "verbose=",$P(args,"\v",1),!
```

### 5.8 STDASSERT — assertion library

The cornerstone of every later test suite. Compatible with `m test`'s
`t<UpperCase>(pass,fail)` convention.

```m
STDASSERT ;
        QUIT
        ;
EQ(pass,fail,actual,expected,msg) ; assert actual == expected
        I actual=expected S pass=pass+1 Q
        S fail=fail+1
        W "FAIL ",$G(msg),": expected ",expected,", got ",actual,!
        Q
        ;
TRUE(pass,fail,cond,msg) ...
RAISES(pass,fail,code,errno,msg) ; XECUTEs code, asserts $ECODE includes errno
        ...
NEAR(pass,fail,a,b,eps,msg) ; for floating-point comparisons
        ...
```

**Decision (§4.2 item 3):** make `STDASSERT` canonical. Have the
`m test` runner detect both `^TESTRUN`-style PASS/FAIL strings and
`STDASSERT`-style; `m-stdlib` self-hosts on the new one.

### 5.9 Phase-1 acceptance gate

A Phase 1 module ships only when:

- [ ] `m fmt --check` is clean
- [ ] `m lint --error-on=fatal` is clean (default profile +
      `--target-engine=any`)
- [ ] `m test` is green on YottaDB **and** (where reachable) on IRIS
- [ ] `m coverage --min-percent=85 --uncovered` is green for the new module
- [ ] LSP surfaces hover docs for every public label (`m lsp` Stage-4 test)
- [ ] `docs/modules/<name>.md` is written, with example, edge cases, and
      link to the survey gap it addresses

If any of these gates falls down on a module, the toolchain weakness it
exposes becomes a P0 follow-up for m-cli or tree-sitter-m. **m-stdlib
is the regression suite for the toolchain.**

---

## 6. Phase 2 — pure-M heavy lifting

Three large modules (JSON, regex, collections) plus URL.

### 6.1 STDJSON — JSON parser/serialiser (RFC 8259)

The keystone of Phase 2. ~1200–1500 lines of M. Stores JSON in M
**globals natively**: an object becomes a tree of subscripts, an array
becomes numerically-subscripted children, scalars become leaves with a
type-tag in the value.

```
^STDJSON($J,"users",1,"name")="Alice"
^STDJSON($J,"users",1,"age")=30
^STDJSON($J,"users",1,"_type")="object"
^STDJSON($J,"users",2,"name")="Bob"
^STDJSON($J,"users","_type")="array"
```

Why globals: lets the user stream-parse multi-megabyte JSON without
buffering it in M strings (which max out at 32K on YDB / 3.6M on
IRIS). The same API surface is preserved (parse/dump/get/set/walk).

API sketch:

```m
S handle=$$PARSE^STDJSON("""[{""name"":""Alice""},{""name"":""Bob""}]""")
F i=1:1 Q:'$D(@handle@(i))  W $$GET^STDJSON(handle,i,"name"),!
S text=$$DUMP^STDJSON(handle,1)   ; pretty-print
D FREE^STDJSON(handle)
```

**Surveyed gap rank #1.** Test suite: every conformance file from the
JSONTestSuite project, plus property-based round-trip checks (parse →
dump → parse equals original).

**Difficulty risers:** Unicode escape handling (`\uXXXX` surrogate
pairs), number range (M numbers truncate at engine-specific precision —
need to preserve textual representation for round-trip), null vs
empty-string distinction (M's classic conflation problem; solved by
`$ZYISSQLNULL` on YDB, by `$ISOBJECT` distinguishing on IRIS, and by
the `_type` sentinel here).

### 6.2 STDREGEX — regex (YDB-targeting subset)

YDB lacks `$MATCH` and `$LOCATE`. IRIS has them. Two options:

- **Option A — Pure-M regex engine.** Implement a Thompson-NFA-style
  engine in M (~1500–2500 lines). Subset of PCRE: character classes,
  groups, alternation, `?`, `*`, `+`, `{m,n}`, anchors. **No
  back-references, no lookaround, no Unicode property classes** (those
  are 4× the work).
- **Option B — `$ZF` to PCRE2.** ~50 lines of M + ~80 lines of C
  callout. Conformance immediately at PCRE2-level. Cost: per-platform
  build, libpcre2 dependency.

**Recommendation: ship A first** as `STDREGEX` (the engine). Add B
later as `STDREGEX_PCRE` (the bridge) for users who need full PCRE.
Most application regex needs are within the A subset.

On IRIS, `STDREGEX` thinly wraps `$MATCH`/`$LOCATE` instead of
re-implementing — the engine then becomes a YDB-only fallback.

### 6.3 STDCOLL — collections

Set, Map, Stack, Queue, Deque, Heap, OrderedDict — all stored in
globals at `^STDLIB($J,"coll",<id>,...)` (per-process default;
overridable to a named global for shared collections).

```m
S s=$$NEW^STDCOLL("set")       ; or "map","stack","queue","heap","odict"
D ADD^STDCOLL(s,"apple")
D ADD^STDCOLL(s,"banana")
W $$LEN^STDCOLL(s),!           ; 2
W $$IN^STDCOLL(s,"apple"),!    ; 1
F  S elem=$$NEXT^STDCOLL(s)  Q:elem=""  W elem,!
```

**Why ship this.** M's hierarchical-database surface is *almost*
collections — `$ORDER` is a Set iterator, `$DATA` is `__contains__`,
SET / KILL are insert / remove. But every project re-codes the
boilerplate. A library version with consistent API saves the
boilerplate everywhere.

**Difficulty:** modest individually. The work is **API consistency
across types** — ensuring `LEN`, `ADD`, `REMOVE`, `CLEAR`, `ITER`,
`COPY`, `EQ` behave the same way regardless of underlying type.

### 6.4 STDURL — URL parsing and encoding

RFC-3986 parse/format, percent-encoding/decoding, query-string parse.
~250 lines. Phase-2 because Phase 3's HTTP client depends on it.

---

## 7. Phase 3 — host-call integrations

Three modules. All require `$ZF` callouts (YDB) or class-method
bridging (IRIS) to existing host libraries. **No reimplementation in
M of TLS, AES, or zlib** — that's research, not engineering.

### 7.1 STDHTTP — HTTP/1.1 + HTTPS client

YDB binding to libcurl through `$ZF`. IRIS path: thin wrapper around
`%Net.HttpRequest` accessed via `$CLASSMETHOD`. Single API:

```m
S resp=$$GET^STDHTTP("https://api.example.com/users",.headers)
W $P(resp,$C(10),1),!  ; "200 OK"
```

Build system: `tools/build-callouts.sh` produces a per-platform
shared object linked against system libcurl + libssl. Distributed via
release tarballs, one per supported platform (linux-x86_64,
linux-aarch64, macOS); IRIS users skip this step entirely.

### 7.2 STDCRYPTO — SHA-256, HMAC, AES-GCM, Ed25519

`$ZF` binding to libsodium (preferred — fewer footguns) or OpenSSL.
API:

```m
S digest=$$SHA256^STDCRYPTO("hello world")
S mac=$$HMACSHA256^STDCRYPTO(key,msg)
S ciphertext=$$AESGCMENCRYPT^STDCRYPTO(key,nonce,plaintext,aad)
```

**Survey rank #8.** Without this, every M codebase that integrates
with modern auth (JWT, signed webhooks, OAuth) shells out to
openssl(1) or carries a host-language sidecar. Big productivity win.

### 7.3 STDCOMPRESS — gzip / zstd

`$ZF` binding to libz and libzstd. Streaming API for large payloads.

```m
S compressed=$$GZIP^STDCOMPRESS(plaintext)
S original=$$GUNZIP^STDCOMPRESS(compressed)
```

---

## 8. Recommended dev environment

**Goal:** every contributor's first command is `code .` on a fresh
clone, and within 60 seconds they have full LSP, formatter, linter,
test runner, coverage, and a working YottaDB instance running their
code. No host-system setup other than Docker + VS Code.

### 8.1 Devcontainer (`.devcontainer/devcontainer.json`)

```jsonc
{
  "name": "m-stdlib dev",
  "build": { "dockerfile": "Dockerfile" },
  "remoteUser": "yottadb",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ],
  "containerEnv": {
    "ydb_dist": "/opt/yottadb",
    "ydb_routines": "/workspace/src /workspace/tests /workspace/.objects",
    "ydb_gbldir": "/workspace/.ydb/m-stdlib.gld",
    "PATH": "/opt/m-cli/.venv/bin:${containerEnv:PATH}"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "rafael5.tree-sitter-m-vscode",
        "github.vscode-github-actions",
        "redhat.vscode-yaml",
        "ms-azuretools.vscode-docker",
        "eamodio.gitlens"
      ],
      "settings": {
        "m-cli.enabled": true,
        "m-cli.path": "/opt/m-cli/.venv/bin/m",
        "editor.formatOnSave": true,
        "[m]": {
          "editor.tabSize": 1,
          "editor.insertSpaces": true,
          "editor.detectIndentation": false
        }
      }
    }
  },
  "postCreateCommand": "make setup-ydb && make install-test-deps",
  "forwardPorts": []
}
```

### 8.2 Container image (`.devcontainer/Dockerfile`)

```dockerfile
FROM yottadb/yottadb-base:latest-master

USER root

# Python toolchain for m-cli
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3-pip git build-essential \
        libssl-dev libcurl4-openssl-dev libsodium-dev zlib1g-dev libpcre2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install m-cli into a system venv. Once published, swap to `pip install m-cli`.
RUN git clone https://github.com/rafael5/m-cli /opt/m-cli && \
    cd /opt/m-cli && \
    python3.12 -m venv .venv && \
    .venv/bin/pip install -e .[lsp]

# tree-sitter-m Python binding (m-cli's parser dependency)
RUN /opt/m-cli/.venv/bin/pip install tree-sitter-m

USER yottadb
WORKDIR /workspace
```

When `m-cli` and `tree-sitter-m` ship to PyPI, the `git clone` becomes
`pip install m-cli[lsp]` and the image shrinks by ~150 MB.

### 8.3 Workspace settings (`.m-cli.toml`)

```toml
[fmt]
rules = "canonical"

[lint]
rules = "default"
disable = []
severity = { "M-XINDX-057" = "INFO" }   # mixed-case lvn — STDFMT/STDJSON parametrised
target-engine = "any"

[lsp]
hover.format = "markdown"
```

### 8.4 Project layout

```
m-stdlib/
├── README.md
├── LICENSE                       # AGPL-3.0 (matches the project family)
├── .devcontainer/
│   ├── Dockerfile
│   └── devcontainer.json
├── .github/workflows/
│   ├── ci.yml                    # see §9
│   └── release.yml               # tags → GitHub release + tarball
├── .pre-commit-config.yaml       # uses m-cli's .pre-commit-hooks.yaml
├── .m-cli.toml
├── Makefile                      # see §8.5
├── docs/
│   ├── design.md
│   └── modules/
│       ├── stdassert.md
│       ├── stduuid.md
│       └── ...
├── src/
│   ├── STDASSERT.m
│   ├── STDUUID.m
│   ├── STDB64.m
│   ├── STDHEX.m
│   ├── STDDATE.m
│   ├── STDFMT.m
│   ├── STDLOG.m
│   ├── STDCSV.m
│   ├── STDARGS.m
│   ├── STDJSON.m
│   ├── STDREGEX.m
│   ├── STDCOLL.m
│   ├── STDURL.m
│   ├── STDHTTP.m
│   ├── STDCRYPTO.m
│   └── STDCOMPRESS.m
├── tests/
│   ├── STDASSERTTST.m
│   ├── STDUUIDTST.m
│   └── ...                       # one TST per src
├── examples/
│   └── ...                       # runnable demos used in docs/
├── tools/
│   └── build-callouts.sh         # Phase 3 only
└── tests/conformance/
    ├── json/                     # JSONTestSuite vendored
    ├── csv/                      # RFC-4180 corner cases
    └── b64/                      # RFC-4648 §10 vectors
```

### 8.5 `Makefile` (Pythonic-style, targets-on-targets)

```makefile
.PHONY: all setup-ydb install-test-deps fmt lint test coverage check ci clean

all: check

setup-ydb:
	@mkdir -p .ydb .objects
	@if [ ! -f .ydb/m-stdlib.gld ]; then \
		. /opt/yottadb/ydb_env_set && mumps -run GDE <<EOF ; \
		change -region DEFAULT -dynamic_segment=DEFAULT ; \
		change -segment DEFAULT -file_name=.ydb/m-stdlib.dat ; \
		exit ; \
EOF \
		mupip create ; \
	fi

install-test-deps:
	@/opt/m-cli/.venv/bin/m --version

fmt:
	m fmt src/ tests/

fmt-check:
	m fmt --check src/ tests/

lint:
	m lint --error-on=fatal src/ tests/

test:
	m test tests/

coverage:
	m coverage --min-percent=85 --format=lcov > coverage.lcov

check: fmt-check lint test coverage
	@echo "OK"

ci: check
	@m test --format=tap > test-results.tap
	@m coverage --format=json > coverage.json

clean:
	rm -rf .ydb .objects coverage.lcov test-results.tap coverage.json
```

### 8.6 Pre-commit config (`.pre-commit-config.yaml`)

```yaml
repos:
  - repo: https://github.com/rafael5/m-cli       # post-publish: switch to package
    rev: v0.1.0
    hooks:
      - id: m-fmt
      - id: m-lint
        args: ["--error-on=fatal"]
```

### 8.7 What this lives up to

The project lays out the same way a Python project does (src/, tests/,
docs/, .devcontainer, .github/workflows, Makefile, pre-commit). The
*tools* are M-specific (`m fmt` not `ruff`, `m test` not `pytest`),
but the *workflow* is identical: edit → format on save (via LSP) →
test on save (via `m watch`) → commit (pre-commit gates) → push (CI
gates) → release. **That's the "modern Pythonic dev workflow" applied
to M.**

---

## 9. CI/CD reference design

### 9.1 GitHub Actions (`.github/workflows/ci.yml`)

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  m-stdlib:
    runs-on: ubuntu-latest
    container: yottadb/yottadb-base:latest-master
    strategy:
      fail-fast: false
      matrix:
        ydb-version: ["r2.02", "latest-master"]
    steps:
      - uses: actions/checkout@v4

      - name: Install Python toolchain
        run: |
          apt-get update && apt-get install -y python3.12 python3.12-venv git
          python3.12 -m venv /tmp/venv
          /tmp/venv/bin/pip install --upgrade pip

      - name: Install m-cli (from git until post-Phase-1 publication)
        run: |
          git clone --depth=1 https://github.com/rafael5/m-cli /tmp/m-cli
          /tmp/venv/bin/pip install -e /tmp/m-cli[lsp]
        # Post-Phase-1 swap:
        # run: /tmp/venv/bin/pip install 'm-cli[lsp]==0.1.0'

      - name: Initialise YDB
        run: . /opt/yottadb/ydb_env_set && make setup-ydb

      - name: Format check
        run: . /opt/yottadb/ydb_env_set && PATH=/tmp/venv/bin:$PATH make fmt-check

      - name: Lint
        run: . /opt/yottadb/ydb_env_set && PATH=/tmp/venv/bin:$PATH make lint

      - name: Test (TAP output)
        run: |
          . /opt/yottadb/ydb_env_set
          PATH=/tmp/venv/bin:$PATH m test --format=tap | tee test-results.tap

      - name: Upload TAP
        uses: actions/upload-artifact@v4
        with:
          name: tap-${{ matrix.ydb-version }}
          path: test-results.tap

      - name: Coverage (lcov)
        run: |
          . /opt/yottadb/ydb_env_set
          PATH=/tmp/venv/bin:$PATH m coverage --format=lcov > coverage.lcov

      - name: Upload coverage
        if: matrix.ydb-version == 'latest-master'
        uses: codecov/codecov-action@v4
        with:
          files: coverage.lcov
          fail_ci_if_error: true

  iris-portability-check:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    container: intersystemsdc/iris-community:latest
    continue-on-error: true     # fail-soft until IRIS support is contracted
    steps:
      - uses: actions/checkout@v4
      - name: Run smoke tests on IRIS
        run: irissession ... # invoke STDASSERT-driven smoke tests
```

### 9.2 What this gates

- **Fmt + lint + test + coverage** on every push, every PR.
- **Coverage uploaded to Codecov** on main only (so PR previews
  don't accidentally drop the threshold).
- **Matrix on YDB versions** — pinned + latest-master.
- **IRIS portability check** runs on PRs but doesn't block merge —
  shows divergence as it appears, doesn't gate on it. (Switch to
  `continue-on-error: false` when m-stdlib commits to IRIS support.)

### 9.3 Release workflow (`.github/workflows/release.yml`)

```yaml
name: Release
on:
  push:
    tags: ["v*.*.*"]
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Build distributable
        run: |
          mkdir -p dist
          tar czf "dist/m-stdlib-${GITHUB_REF_NAME}-src.tar.gz" \
              --transform "s,^,m-stdlib-${GITHUB_REF_NAME#v}/," \
              src tests docs README.md LICENSE
      - name: GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*
          generate_release_notes: true
```

---

## 10. Dev-tooling gap list (prioritised)

What's still missing from the "modern Pythonic" experience for M,
ranked by how badly it pinches `m-stdlib` development.

### P0 — blockers for m-stdlib bootstrap

| # | Gap | Owner | Effort | Status |
|---:|---|---|---|---|
| 1 | Canonicalise an assertion library convention compatible with `m test` | m-cli + m-stdlib | ~1 day | **decided (§11.4): STDASSERT canonical, m-stdlib does not depend on m-tools.** Pending sub-question §13.2 on m-cli recogniser. |

### Post-Phase 1 — public-release prerequisites

These were originally listed as P0 "blockers for external consumption,"
but m-stdlib has no external consumers in Phase 1 — it consumes the
toolchain itself. Until Phase 1 has shipped and the toolchain has been
validated by eight real modules, publishing produces churn rather than
value. Both items move here:

| # | Gap | Owner | Effort | Status |
|---:|---|---|---|---|
| 2 | Publish `m-cli` to PyPI | m-cli | hours | needs creds; defer until Phase 1 ships |
| 3 | Publish `tree-sitter-m` to npm + PyPI + crates.io + Go module | tree-sitter-m | hours | needs creds (RELEASE.md exists); defer until Phase 1 ships |

### P1 — significant friction during development

| # | Gap | Why it matters | Suggested home |
|---:|---|---|---|
| 4 | **No M package manager.** Consumers of m-stdlib install via git submodule + `ydb_routines` env var. There is no `pip install m-stdlib`-equivalent. | Every downstream M project re-invents installation. | New project (`m-pkg`?) — large enough to defer; document submodule convention in m-stdlib README until then. |
| 5 | **No DAP (Debug Adapter Protocol) bridge** for VS Code. `m lsp` covers editing but not interactive debugging. | M debugging today: `ZBREAK` from a terminal session attached to the running job. Workable but not editor-integrated. | Future m-cli feature: `m debug` exposing DAP over stdio, bridging to YDB's `ZBREAK`/`ZSTEP`/`ZCONTINUE`. ~2-3 weeks. |
| 6 | **No documentation generator.** API docs for `STDJSON` should be readable on a website without opening source. | Today: hand-written `docs/modules/<name>.md`. Fine for 8 modules, painful past 30. | Future m-cli feature: `m docs` extracts `; doc:` comments from labels, emits Markdown / mkdocs / sphinx. ~1 week. |
| 7 | **No `$ZF` build harness** for cross-platform native callouts. | Phase 3 modules need shared objects per-platform; current m-cli has no `m build` to coordinate this. | Future m-cli feature: `m build --target=so` driving a CMake or Meson skeleton; or simply a `tools/build-callouts.sh` per-project. Project-level for now; promote to m-cli if pain grows. |

### P2 — nice-to-have, not on the critical path

| # | Gap | Suggested home |
|---:|---|---|
| 8 | Project scaffolder (`m new <name>` writes the layout from §8.4) | m-cli, ~2-3 days |
| 9 | Property-based testing helpers in STDASSERT (Hypothesis-style) | m-stdlib STDASSERT |
| 10 | Mutation testing | not on roadmap; revisit at v1.0 |
| 11 | Fuzzer harness (AFL-class) for STDJSON / STDCSV / STDREGEX | tools/fuzz/ ad-hoc; promote if useful |
| 12 | Benchmark harness (`m bench`) | future m-cli feature; today `time .venv/bin/m test --suites=BENCH` works |
| 13 | Pre-built Docker image for m-cli + ydb (`ghcr.io/rafael5/m-dev:latest`) | publish from m-cli's CI; consumer-friendly devcontainer base |
| 14 | A **VistA-corpus regression smoke** for m-stdlib (does any STD routine break VistA's parser/lint output?) | m-cli's `make vista-canonical` gate, extended |

### P3 — long-tail ecosystem

| # | Gap | Notes |
|---:|---|---|
| 15 | M language server (LSP) for **other editors** (Neovim, Helix, Emacs) | `m lsp` is editor-agnostic; the editor side (extension, tree-sitter-m bindings) is the missing piece. tree-sitter-m's `queries/highlights.scm` ships in v0.1 — Helix and Neovim consumers can use it today. |
| 16 | A **standard error-code registry** for M libraries (analogous to errno.h) | docs/error-codes.md per project today; cross-project convention work for someday |
| 17 | An **`m security` audit subcommand** (CVE-style scanning for deprecated patterns) | future m-cli feature |

### Aggregate verdict on dev-tooling gaps

- **1 P0 item** (assertion-library convention) is ~1 day and **gates
  m-stdlib's first commit**.
- **2 post-Phase-1 items** (PyPI / npm publication) are hours each and
  **gate the v0.1.0 public release**, not Phase 1 development itself.
- **4 P1 items** are weeks each and can ship alongside Phase 1/2/3 as
  the need surfaces.
- **Everything else** is opportunistic.

The toolchain is already in remarkably good shape; the dev-tooling
gap list is shorter than the library gap list (10 P1+ items vs. 20+
library gaps). **Building m-stdlib will surface real toolchain
weaknesses** — that's the point of doing the two together. Treat each
m-cli regression that m-stdlib finds as a P0 m-cli ticket.

---

## 11. Decisions

Locked 2026-04-30. Items below were open questions; each is now
resolved. The original recommendation is preserved as background; the
**Decision** line is binding.

### 11.1 Project boundary — sibling project

- **Decision.** **m-stdlib ships as a sibling** of m-cli, m-standard,
  and tree-sitter-m. Independent repo (`~/projects/m-stdlib`,
  `github.com/rafael5/m-stdlib`), independent versioning, independent
  release cadence.
- **Implication.** m-stdlib has its own CI, its own pre-commit, its
  own license file. It depends on m-cli (for fmt/lint/test/coverage)
  and on m-standard (transitively, via m-cli's keyword tables and
  tree-sitter-m's grammar) but does not vendor either.

### 11.2 Vendor scope — YottaDB first, IRIS portable where reasonable

- **Decision.** **YottaDB is the primary target.** IRIS portability
  is preserved where the cost is reasonable (i.e. dispatching to
  `$ZASCII` vs `$ASCII`, `$ZTIMESTAMP` vs `$ZHOROLOG`, `$ZF` vs
  `$CLASSMETHOD`); IRIS is not a release blocker.
- **CI.** The `iris-portability-check` job in §9.1 stays
  `continue-on-error: true` (fail-soft) for now. Flip to gating only
  if/when an IRIS deployment commits to consuming m-stdlib.
- **GT.M.** Out of scope, permanently.

### 11.3 Naming convention — `STD*` prefix

- **Decision.** **All public routines use the `STD` prefix.** Tests
  use the `STD…TST` suffix that m-cli's discovery already recognises.
  Library globals: `^STDLIB($J,…)` for per-process state,
  `^STDLIBC(…)` for shared config.
- **Reserved.** `STD` as a routine prefix is hereby reserved for
  m-stdlib across the project family. Project-specific code in other
  repos must not introduce `STD*` routines.

### 11.4 Assertion library — STDASSERT canonical, migrate off m-tools

- **Decision.** **STDASSERT is the canonical assertion library** for
  m-stdlib *and* for the project family going forward. **m-stdlib does
  not depend on m-tools.** New m-cli / tree-sitter-m / m-standard test
  code that needs a richer assertion vocabulary than `t<UpperCase>(pass,fail)`
  switches to STDASSERT once it ships in Phase 1.
- **Migration off m-tools.** Existing test suites in m-cli and
  tree-sitter-m that currently use `^TESTRUN` from m-tools migrate to
  STDASSERT once Phase 1 ships STDASSERT. m-cli's `m test` runner
  keeps the `t<UpperCase>(pass,fail)` discovery convention (that's the
  test-shape contract, not an assertion-vocabulary contract) so the
  migration is mechanical: replace `^TESTRUN`-style PASS/FAIL string
  comparisons with `STDASSERT` calls.
- **Backward compat in `m test`.** The runner does *not* need
  permanent `^TESTRUN` support — m-tools is legacy and the family is
  moving off it. m-cli may keep one transitional release that
  recognises both, then drop `^TESTRUN` recognition once the migration
  is done.
- **VistA test suites.** Out of scope for this migration. VistA's own
  `^TESTRUN` users continue to work because `^TESTRUN` itself is not
  being removed from m-tools — m-stdlib just stops depending on it.

### 11.5 License — AGPL-3.0

- **Decision.** **AGPL-3.0**, matching m-standard, m-cli, and
  tree-sitter-m. Family-wide consistency wins over closed-source IRIS
  uptake.
- **Per-module relicense escape hatch.** If a specific module (e.g.
  STDHTTP for embedding into a closed-source IRIS app) needs a more
  permissive license, treat it as a per-module decision at the time
  the case arises. Default is AGPL-3.0.

### 11.6 Versioning — SemVer

- **Decision.** **Semantic versioning.** Tags: `vMAJOR.MINOR.PATCH`.
- **Milestone tags.**
  - `v0.0.1` — first commit (CI green + STDASSERT + STDUUID, per §11.7).
  - `v0.1.0` — Phase 1 complete (all eight modules shipped + docs).
  - `v0.2.0` — Phase 2 complete.
  - `v0.3.0` — Phase 3 complete.
  - `v1.0.0` — API surface stable for 3 months after `v0.3.0`.
- **Pre-1.0 stability.** Minor versions may include breaking changes
  (standard SemVer pre-1.0 semantics). Document each in `CHANGELOG.md`.

### 11.7 First commit — CI green + STDASSERT + STDUUID together

- **Decision.** **First commit = repo skeleton with CI passing, plus
  STDASSERT and STDUUID and their test suites.** Smallest commit that
  exercises every part of the toolchain cycle (fmt, lint, test,
  coverage, LSP) end-to-end. Tagged `v0.0.1`.
- **Subsequent commits.** One module per PR thereafter, in this
  order: STDB64 → STDHEX → STDFMT → STDLOG → STDDATE → STDCSV →
  STDARGS. (STDFMT before STDLOG, STDLOG before STDDATE only by
  convenience — STDDATE is independent and can ship in parallel.)
- **Phase 1 done = `v0.1.0` tag** when all eight modules pass §5.9's
  acceptance gate.

---

## 12. Finalised implementation plan

With §11 locked in, the work breaks into the following ordered tasks.
Each task has a definition of done; nothing on a later step starts
until the earlier steps are green.

### 12.1 Phase 0 — bootstrap (target: ~half day)

| Step | Action | DoD |
|---:|---|---|
| 0.1 | Create `~/projects/m-stdlib` from a Pythonic template skeleton (no Python source — just the project shape: `src/`, `tests/`, `docs/`, `.devcontainer/`, `.github/workflows/`, `Makefile`, `LICENSE` (AGPL-3.0), `README.md`, `.m-cli.toml`, `.pre-commit-config.yaml`, `CHANGELOG.md`). | `git init` + first commit; tree matches §8.4. |
| 0.2 | Wire devcontainer per §8.1–§8.2. Build locally and confirm `m --version` resolves. | `code .` → reopen in container → `m --version` prints. |
| 0.3 | Land CI workflow per §9.1 with empty `src/` (no modules yet). Allow it to be green on a no-op build (fmt-check / lint / test all pass on empty inputs). | `.github/workflows/ci.yml` green on `main`. |
| 0.4 | Initial `README.md` ≤ 1 page: what the project is, the §11.6 milestone tags, the §11.5 license, install-from-git instructions, link back to this plan. | README in repo root. |
| 0.5 | First m-cli prerequisite: confirm `m test` already works when STDASSERT-style assertions are used as plain M code (no special recogniser needed in v0.0.1 — STDASSERT writes to `pass`/`fail` counters via the existing `t<UpperCase>(pass,fail)` discovery convention). If it does, no m-cli change is required to bootstrap. | Verified by writing one trivial `STDASSERTTST.m` and running `m test`. |

**Phase 0 done when:** empty repo + CI green + devcontainer
reproduces locally + first STDASSERTTST stub runs (and fails) under
`m test`.

### 12.2 Phase 1 commit-by-commit plan

| Tag / PR | Contents | DoD (per §5.9) |
|---|---|---|
| `v0.0.1` | STDASSERT + STDUUID + their TST suites + docs/modules/{stdassert,stduuid}.md | fmt-check / lint / test / coverage all green; both modules documented |
| `v0.0.2` | STDB64 + STDHEX + tests + docs | per §5.9 |
| `v0.0.3` | STDFMT + tests + docs | per §5.9 |
| `v0.0.4` | STDLOG + tests + docs | per §5.9 (text-only output until STDJSON ships) |
| `v0.0.5` | STDDATE + tests + docs | per §5.9 |
| `v0.0.6` | STDCSV + tests + RFC-4180 conformance corpus + docs | per §5.9 |
| `v0.0.7` | STDARGS + tests + docs | per §5.9 |
| `v0.1.0` | Phase 1 release: CHANGELOG, GitHub Release, source tarball, docs/index regenerated | tag pushed; release.yml runs; tarball downloadable |

**Each PR carries:** the module + its TST + the per-module doc page +
a CHANGELOG entry. No module merges without all four.

### 12.3 Side effects on adjacent projects (per §11.4)

When STDASSERT lands in `v0.0.1`, file three follow-up issues — one
each on m-cli, tree-sitter-m, and (if applicable) m-standard — to
migrate their existing `^TESTRUN`-based test suites onto STDASSERT.
These are P2 cleanups, not blockers. Track them in the respective
project's build-log.

### 12.4 Phase 2/3 plan (not started until v0.1.0 tagged)

Phase 2 PRs follow the same shape as Phase 1: STDJSON →
STDREGEX → STDCOLL → STDURL, each on the §5.9 acceptance gate. Phase
3 (STDHTTP, STDCRYPTO, STDCOMPRESS) requires the `tools/build-callouts.sh`
infrastructure from §10 P1 #7 plus a per-platform release process; that
infrastructure work lands in a `v0.2.x` patch release between Phase 2
and Phase 3.

### 12.5 Toolchain feedback loop (per §10 last paragraph)

For every Phase 1 module, log toolchain weaknesses found during
development to a `TOOLCHAIN-FINDINGS.md` in m-stdlib. Each finding is
filed as a P0 issue against m-cli or tree-sitter-m. The toolchain
publication gate (post-Phase-1, §10 items 2 & 3) is "no open
P0/P1 toolchain findings from m-stdlib."

### 12.6 What does *not* change in m-standard / m-cli / tree-sitter-m

- m-standard schemas, TSVs, and `docs/spec.md` are unchanged by this
  work.
- m-cli's CLI surface is unchanged. The `m test` discovery convention
  (`t<UpperCase>(pass,fail)`) is unchanged. Internal recognisers may
  add STDASSERT support but the CLI does not gain new flags for it.
- tree-sitter-m grammar is unchanged. STDASSERT and STDUUID parse as
  ordinary M.

---

## 13. Final implementation answers

All resolved 2026-04-30. This section was a Q&A; each item is now an
**Answer** that binds the implementation plan in §12.

### 13.1 Repo location and host — confirmed

- Local: `~/projects/m-stdlib`.
- Remote: `github.com/rafael5/m-stdlib`, public, AGPL-3.0.

### 13.2 m-cli evolves in parallel; m-stdlib takes naming priority

**Answer.** m-cli evolves alongside m-stdlib. **m-stdlib has priority
in naming and conventions; m-cli inherits.** Whenever m-stdlib
introduces an assertion vocabulary, error-code shape, log format, or
module convention, m-cli adapts to consume it — not the other way
around.

Operationally: don't try to make STDASSERT work under m-cli's
existing recogniser only. Instead, develop STDASSERT in m-stdlib to
the API shape that's right *for m-stdlib*, and add the matching
recogniser in m-cli in parallel. If a v0.0.1 STDASSERT shape works
out-of-the-box under the existing `t<UpperCase>(pass,fail)` runner,
great; if it doesn't, the m-cli change is a normal companion PR, not
a blocker.

This inverts the usual "library serves the tooling" assumption:
**m-cli is a consumer of m-stdlib artifacts**, so m-stdlib's
conventions are upstream of m-cli's.

### 13.3 IRIS — drop from CI until v0.0.4

**Answer.** Drop the `iris-portability-check` job from CI in
v0.0.1–v0.0.3. Add it back at v0.0.4 (when enough modules exist for
portability testing to be meaningful). Use a fail-soft
(`continue-on-error: true`) job when reintroduced.

### 13.4 YottaDB image pin — pick the most reliable, verify first

**Answer.** Image choice is unconfirmed. **Verification step:** before
landing CI in Phase 0, pull the candidate images
(`yottadb/yottadb-base:latest-master`, `yottadb/yottadb`, the
`r2.02`/newer tagged releases) locally and confirm which one (a)
exists on Docker Hub, (b) starts cleanly, and (c) has `mumps`/`mupip`
on `PATH`. Use the most reliable. Document the choice in the m-stdlib
README + CI yaml comment so the next maintainer knows why that image.

### 13.5 `^TESTRUN` in m-cli — defer; m-stdlib has priority

**Answer.** Don't decide yet. **m-stdlib has priority over m-cli; m-cli
is a downstream consumer.** The right time to decide is when m-cli is
adapting to consume m-stdlib's STDASSERT, not now. Default posture
until then: m-cli keeps `^TESTRUN` recognition for as long as the
m-cli/tree-sitter-m migration to STDASSERT is in flight. Drop it
when m-cli no longer has any internal `^TESTRUN`-using suite.

### 13.6 Pre-commit hooks — `repo: local` until m-cli is published

**Answer.** Use `repo: local` pre-commit hooks that shell out to
`/opt/m-cli/.venv/bin/m fmt` and `m lint` directly. Carry a TODO
comment to swap to a released `repo:` once m-cli ≥ v0.1.0 publishes.

### 13.7 First commit timing — defer; this is a planning session

**Answer.** Defer. Phase 0 implementation does **not** start in this
session. Action this session: create the `~/projects/m-stdlib`
directory, drop a copy of this document inside, and write a
resume-here `TODO.md` so the next session can pick up at §12.1
without re-deriving context.

---

## Appendix — relationship to the broader project family

```
                ┌───────────────────────────┐
                │ m-standard (this repo)    │
                │ Reference, schemas, TSV   │
                │ Source of truth for       │
                │ keyword tables.           │
                └────────────┬──────────────┘
                             │ provides
                             ▼
                ┌───────────────────────────┐
                │ tree-sitter-m             │
                │ Grammar; AD-03 stamping   │
                │ from m-standard.          │
                └────────────┬──────────────┘
                             │ provides
                             ▼
                ┌───────────────────────────┐
                │ m-cli                     │
                │ fmt, lint, test, watch,   │
                │ coverage, lsp, VS Code.   │
                │ Reads m-standard for      │
                │ keyword sets; uses        │
                │ tree-sitter-m for parse.  │
                └────────────┬──────────────┘
                             │ exercised by
                             ▼
                ┌───────────────────────────┐
                │ m-stdlib (NEW)            │
                │ Pure-M (Phase 1+2),       │
                │ $ZF-bound (Phase 3)       │
                │ runtime library.          │
                │ Self-hosted on STDASSERT. │
                │ Drives toolchain hardening│
                │ via real-use regressions. │
                └───────────────────────────┘
```

m-stdlib is the **first downstream consumer** of the full project
stack. Every toolchain weakness that real library development exposes
becomes a sharpening opportunity for m-cli, m-standard, and
tree-sitter-m. That feedback loop — *building real M code with the
toolchain to find the toolchain's blind spots* — is itself a primary
deliverable, alongside the library itself.
