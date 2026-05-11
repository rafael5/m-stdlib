---
module: STDENV
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: '.env file loader with typed accessors'
labels: ['get', 'getBool', 'getFloat', 'getInt', 'has', 'parse', 'parseFile', 'valid']
errors: ['U-STDFS-OPEN-FAIL']
conformance: []
see_also: ['STDFS']
created: 2026-05-07
last_modified: 2026-05-10
revisions: 4
doc_type: [REFERENCE]
---

# `STDENV` — `.env` loader + typed accessors

Parse `.env`-formatted text or files into a caller-owned tree.
Typed accessors (`getInt`, `getBool`, `getFloat`) coerce values
with a default-on-miss-or-mistype convention. Built for the
container-tooling ergonomic where `.env` files configure a
service: read once, query many times, defaults filled in.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `parse` | `$$parse^STDENV(text, .env)` | `1` on success, `0` on parse error; populates `env`. |
| `parseFile` | `$$parseFile^STDENV(path, .env)` | `parse` over the file at `path` via STDFS. |
| `valid` | `$$valid^STDENV(text)` | `1` iff text parses as `.env`; else `0`. |
| `has` | `$$has^STDENV(.env, key)` | `1` iff key is defined; else `0`. |
| `get` | `$$get^STDENV(.env, key, default)` | String value or `default`. |
| `getInt` | `$$getInt^STDENV(.env, key, default)` | Integer value or `default` if missing/non-integer. |
| `getFloat` | `$$getFloat^STDENV(.env, key, default)` | Float value or `default` if missing/non-numeric. |
| `getBool` | `$$getBool^STDENV(.env, key, default)` | `1` for `true`/`yes`/`on`/`1`, `0` for `false`/`no`/`off`/`0`, else `default` (case-insensitive). |

## Examples

```m
; load a .env file once at startup
NEW cfg
DO  SET rc=$$parseFile^STDENV(".env",.cfg)
IF 'rc DO bail^MYAPP("invalid .env")

; query with defaults
SET host=$$get^STDENV(.cfg,"HOST","localhost")
SET port=$$getInt^STDENV(.cfg,"PORT",8080)
SET ratio=$$getFloat^STDENV(.cfg,"RATIO",1.0)
SET debug=$$getBool^STDENV(.cfg,"DEBUG",0)

; predicate before a typed access if you need to distinguish missing from default
IF $$has^STDENV(.cfg,"DATABASE_URL") DO ...
```

## Format

```
<doc>     ::= (<line> NL)*
<line>    ::= <comment> | <blank> | <pair>
<comment> ::= "#" .*           ; whole-line; trailing # is NOT stripped
<pair>    ::= <key> "=" <value>
<key>     ::= [A-Za-z_][A-Za-z0-9_]*
<value>   ::= <bare> | <dq> | <sq>
<bare>    ::= raw chars (whitespace-trimmed)
<dq>      ::= '"' (chars with \n \t \r \" \\ escapes) '"'
<sq>      ::= "'" raw chars "'"   ; no escape processing (POSIX literal)
```

### Whitespace

Leading and trailing whitespace around both the key and the value
is stripped. Internal whitespace inside a quoted value is preserved
verbatim:

```
KEY = value             ; same as KEY=value
MSG = "hello world"     ; preserves the embedded space
```

### Quoting

| Form | Behaviour |
|---|---|
| `KEY=bare value` | Whitespace-trimmed, no escape processing. |
| `KEY="..."` | Decodes `\n` `\t` `\r` `\"` `\\`. |
| `KEY='...'` | Literal — no escape processing. |

`#` inside a bare value is **not** treated as a comment marker
(differs from TOML's behaviour). If you need a `#` to be excluded
from the value, use quotes:

```
TOKEN=abc#xyz       ; value is the literal "abc#xyz"
TOKEN="abc#xyz"     ; same
```

## Typed accessors

| Accessor | Truthy / numeric forms | Otherwise |
|---|---|---|
| `getInt` | Canonical decimal integer (no decimal point). | `default` |
| `getFloat` | Any numeric in M's canonical form (`+v=v`). | `default` |
| `getBool` | `true` / `yes` / `on` / `1` → `1`; `false` / `no` / `off` / `0` → `0` (case-insensitive). | `default` |

The "default on missing or unparseable" convention lets callers
write defensive code without explicit `has` checks:

```m
SET threads=$$getInt^STDENV(.cfg,"WORKER_THREADS",4)
; threads is 4 if WORKER_THREADS is missing OR non-numeric OR a float
```

## Edge cases

- **Empty document is valid.** `$$parse^STDENV("", .env)` returns `1`
  with `env` left empty.
- **Bare `=value` is a parse error.** Empty key is rejected.
- **Leading-digit keys are rejected** per the typical shell-variable
  convention. `1FOO=bar` returns `0`. Keys starting with `_` are
  allowed; subsequent characters may be alphanumeric or `_`.
- **`#` inside a bare value is preserved.** Use quotes if you don't
  want this behaviour.
- **Trailing `#` comments on a `KEY=value` line are NOT stripped.**
  This differs from TOML's behaviour but matches dotenv conventions.
- **`getBool` is case-insensitive.** `"True"`, `"YES"`, `"oN"` all
  decode to `1`.
- **Single-quoted values do NOT process escapes.** `KEY='\n'` stores
  the literal two-character string `\n`, not a newline.

## Out of scope (queued at T22)

- **Variable substitution.** `KEY=${OTHER}` and `KEY=$OTHER`
  references — would need an order-preserving parse and a lookup
  fallback chain (parsed env → process env via STDOS).
- **`export` prefix.** Bash-style `export FOO=bar`.
- **Multi-line values.** PEM-key blobs, JWT keys, etc., wrapped
  in `"..."` spanning multiple lines.
- **Process-environment integration.** Writing the parsed env back
  into `$ZTRNLNM` space — needs `setenv()` from STDOS T15.

These extensions land alongside whichever consumer drives them —
v1 covers the practical 80% case for container `.env` files.

## Engine portability

Pure-M throughout: `$piece` / `$translate` / `$find` / `$extract`
/ `$select`. ANSI-standard. Hard dep on STDFS for `parseFile`.
Runs unchanged on YDB and IRIS.

## See also

- [`STDOS`](stdos.md) — `env(name)` is the read-the-process-env
  primitive. STDENV is for `.env` *files*; STDOS is for the
  process's own environment.
- [`STDFS`](stdfs.md) — `parseFile` uses `readFile` for the I/O.
- [`STDTOML`](stdtoml.md) — TOML is the structured-config
  alternative; `.env` is flatter but more idiomatic for runtime
  configuration.

## History

`.env` loader + typed accessors: parse / parseFile / valid / has /
get / getInt / getBool / getFloat. Format: bare values (whitespace-
trimmed), double-quoted with `\n \t \r \" \\` escapes, single-quoted
POSIX-literal (no escape processing), `#` whole-line comments, blank
lines tolerated. `getBool` is case-insensitive against
`{true,yes,on,1}`/`{false,no,off,0}`. Default-on-miss-or-mistype
convention for typed accessors.

**Optional add-on (T22, deferred):** variable substitution (`${VAR}`),
`export` prefix, multi-line values, process-environment write-back
(depends on STDOS `setenv` from T15). Activates when a concrete `.env`
consumer needs full POSIX shell `.env` semantics.
