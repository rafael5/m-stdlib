---
module: STDTOML
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'TOML 1.0 parser (deliberately narrow v1 subset)'
labels: ['get', 'parse', 'type', 'valid']
errors: []
conformance: []
see_also: []
---

# `STDTOML` — TOML 1.0 (subset)

A deliberately narrow TOML parser for per-project config files.
v1 covers the practical subset used by `pyproject.toml` /
`Cargo.toml` / `.m-cli.toml`-style configs: top-level key/value
pairs, `[section]` headers, the four primitive scalar types,
comments. Arrays, dotted keys, nested tables, and datetime are
out of scope (queued for a follow-up).

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `parse` | `$$parse^STDTOML(text, .root)` | `1` on success, `0` on parse error; populates `root` tree. |
| `valid` | `$$valid^STDTOML(text)` | `1` iff text parses as valid TOML; else `0`. |
| `get` | `$$get^STDTOML(.root, key)` | Value at `key` (dotted path for tables); `""` if absent. |
| `type` | `$$type^STDTOML(.root, key)` | `"string"` / `"integer"` / `"float"` / `"bool"` / `""`. |

## Examples

```m
; load and inspect a config
SET cfg=" \
title = ""m-stdlib"" \
[server] \
host = ""localhost"" \
port = 8080 \
enabled = true \
" ; (use $C(10) joins in real code; this is illustrative)

DO  SET rc=$$parse^STDTOML(cfg,.cfg)
WRITE $$get^STDTOML(.cfg,"title"),!         ; "m-stdlib"
WRITE $$get^STDTOML(.cfg,"server.host"),!   ; "localhost"
WRITE $$get^STDTOML(.cfg,"server.port"),!   ; 8080
WRITE $$get^STDTOML(.cfg,"server.enabled"),! ; 1   (booleans coerce to 1/0)
WRITE $$type^STDTOML(.cfg,"server.port"),!   ; "integer"

; predicate
IF '$$valid^STDTOML(text) DO error^MYAPP("bad config")
```

## Tree representation

After a successful parse:

| Path | Holds |
|---|---|
| `root("v", path)` | The decoded scalar value at `path`. |
| `root("t", path)` | The type tag (`"string"` / `"integer"` / `"float"` / `"bool"`). |

`path` is the dotted address: `"key"` for a top-level pair,
`"section.key"` for a sectioned pair. `get` and `type` are thin
wrappers over `$DATA(root("v", path))` / `$DATA(root("t", path))`.

## Grammar (v1 subset)

```
<doc>          ::= (<line> NL)*
<line>         ::= <blank> | <comment> | <table> | <pair>
<comment>      ::= "#" .*           ; whole-line or trailing
<table>        ::= "[" <bare-key> "]"
<pair>         ::= <bare-key> WS? "=" WS? <value> (<comment>)?
<bare-key>     ::= [A-Za-z0-9_-]+
<value>        ::= <basic-string> | <integer> | <float> | <bool>
<basic-string> ::= '"' (chars with \n \t \r \" \\ escapes) '"'
<integer>      ::= "-"? [0-9]+
<float>        ::= "-"? [0-9]+ "." [0-9]+
<bool>         ::= "true" | "false"
```

### String escapes

`decodeString` honours five backslash escapes:

| Escape | Char |
|---|---|
| `\n` | `$C(10)` (LF) |
| `\t` | `$C(9)` (tab) |
| `\r` | `$C(13)` (CR) |
| `\"` | `"` |
| `\\` | `\` |

Any other backslash sequence is a parse error. Unicode `\uXXXX` /
`\UXXXXXXXX` escapes are not handled in v1 (deferred under T18).

### Trailing comments

Trailing `#` comments after a value are stripped before the value
is decoded:

```
port = 80  # http port
```

The comment-strip is **string-aware**: a `#` inside `"..."` is
preserved verbatim, so

```
prompt = "say # hello"
```

decodes correctly.

## Out of scope (queued at T18)

- **Arrays.** `colors = ["red", "green", "blue"]`.
- **Inline tables.** `point = { x = 1, y = 2 }`.
- **Dotted keys.** `physical.color = "red"` at the top level.
- **`[[array-of-tables]]`.** Repeated section headers building a list.
- **Multi-line strings.** `"""..."""` and `'''...'''`.
- **Literal strings.** `'...'` (no escape processing).
- **Integer literals with underscores** (`1_000_000`), hex / oct / bin
  prefixes (`0xff` / `0o755` / `0b1010`).
- **Special floats:** `inf`, `-inf`, `nan`.
- **Exponent notation in floats:** `1.5e3`, `2E-10`.
- **Datetime values:** TOML offset / local datetime / local date /
  local time. STDDATE could host the parsing once T18 lands.

The v1 surface is enough to ingest `pyproject.toml`-shaped config
files where the values are scalars and the sections form a single
level of nesting — which covers ~80% of real-world `.toml` use in
this orbit (`.m-cli.toml`, `pyproject.toml`'s `[tool.*]` sections,
`Cargo.toml`'s `[dependencies]` when each value is a string).

## Edge cases

- **Empty document is valid.** `$$parse^STDTOML("",.root)` returns `1`
  with `root` left empty (kill-then-set semantics).
- **Duplicate key in same scope** is a parse error (returns `0`).
  TOML §1 explicitly forbids duplicate keys; STDTOML enforces this
  per-scope (top-level + each `[section]` is its own scope).
- **`get` of an absent key returns `""`,** not `$ECODE`. Callers
  that need to distinguish "absent" from "present-but-empty-string"
  should use `$DATA(root("v", path))` directly or call `type` first.
- **Boolean values surface as `1`/`0` in M.** `type` returns `"bool"`
  to disambiguate from integers `1`/`0`. The `1`/`0` representation
  is M-idiomatic and works correctly with M's truthiness operators.
- **Whitespace within a value.** Strings preserve internal
  whitespace verbatim; integer / float / bool values are
  whitespace-trimmed before decoding.

## Engine portability

Pure-M — no `$Z*` extensions, no STDREGEX dep, no STDDATE dep.
Runs unchanged on YDB and IRIS. The test suite (59 assertions
across 28 labels) is the conformance gate.

## See also

- [`STDARGS`](stdargs.md) — closes the configuration loop: parse
  `[tool.app]` defaults from `.app.toml`, then layer CLI flags on
  top via STDARGS.
- [`STDDATE`](stddate.md) — will gain TOML datetime decode support
  alongside T18.
- [`STDSTR`](stdstr.md) — STDTOML's whitespace and case handling
  could rebase onto STDSTR helpers in a future cleanup pass; v1
  inlines them for self-containment.
- TOML 1.0 spec: <https://toml.io/en/v1.0.0>.
