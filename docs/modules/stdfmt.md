---
module: STDFMT
tag: v0.0.3
phase: Phase 1
stable: stable
since: v0.0.3
synopsis: 'printf-style formatter (subset of Python str.format)'
labels: ['f', 'fn']
errors: ['U-STDFMT-MISSING-ARG', 'U-STDFMT-UNCLOSED-BRACE', 'U-STDFMT-UNESCAPED-RBRACE', 'U-STDFMT-UNKNOWN-TYPE']
conformance: []
see_also: []
created: 2026-05-05
last_modified: 2026-05-10
revisions: 5
doc_type: [REFERENCE]
---

# `STDFMT` — printf-style formatter

A subset of Python's `str.format`: positional and named placeholders,
fill / align / width / precision, types `s d f x X o b`, and braces
escaped with `{{` / `}}`. Pure-M; no host-call.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `f` | `$$f^STDFMT(template, a1, a2, ..., a9)` | The rendered template, using up to 9 positional args. |
| `fn` | `$$fn^STDFMT(template, .args)` | The rendered template, looking up named placeholders in the passed local array. |

Up to nine positional args are supported in `f` (matching the
practical limit of M's argument list). For more args or for named
substitution, use `fn`.

## Format spec

The substitution syntax is a subset of Python's `str.format`:

```
{[field][:[fill][align][width][.precision][type]]}
```

| Element | Allowed values | Notes |
|---|---|---|
| `field` | empty / `0..N` / name | Empty auto-numbers; digits are positional indices; otherwise a name (lookup in `.args` for `fn`). |
| `fill` | any one character | Defaults to space. Required if `align` is preceded by anything. |
| `align` | `<` / `>` / `^` | Left / right / center. Default: left for strings, right for numbers. |
| `width` | digits | Minimum field width. Values longer than `width` are not truncated. |
| `precision` | digits after `.` | For `f`: decimals (rounded via `$FNUMBER`). For `s` / no type: max length of string. |
| `type` | `s d f x X o b` | String / decimal / float / lower hex / upper hex / octal / binary. |

`{{` and `}}` are literal `{` and `}`. Any other use of `{` or `}`
that doesn't form a complete placeholder sets `$ECODE`.

## Examples

```m
; positional, auto-numbered
WRITE $$f^STDFMT("hello {}","world"),!         ; "hello world"

; positional, indexed (and reused)
WRITE $$f^STDFMT("{0} {1} {0}","x","y"),!      ; "x y x"

; named (via fn)
NEW a SET a("name")="Ada"
WRITE $$fn^STDFMT("Hi, {name}!",.a),!          ; "Hi, Ada!"

; types
WRITE $$f^STDFMT("{:d}",42),!                  ; "42"
WRITE $$f^STDFMT("{:.3f}",3.14159),!           ; "3.142"
WRITE $$f^STDFMT("{:x}",255),!                 ; "ff"
WRITE $$f^STDFMT("{:X}",3735928559),!          ; "DEADBEEF"
WRITE $$f^STDFMT("{:o}",64),!                  ; "100"
WRITE $$f^STDFMT("{:b}",5),!                   ; "101"

; width + alignment + fill
WRITE $$f^STDFMT("{:>5}","hi"),!               ; "   hi"
WRITE $$f^STDFMT("{:<5d}",42),!                ; "42   "
WRITE $$f^STDFMT("{:^6}","hi"),!               ; "  hi  "
WRITE $$f^STDFMT("{:*>5}","x"),!               ; "****x"
WRITE $$f^STDFMT("{:0>5d}",42),!               ; "00042"

; precision (string truncate)
WRITE $$f^STDFMT("{:.3s}","hello"),!           ; "hel"

; combined
WRITE $$f^STDFMT("{:*^10.4s}","abcdefgh"),!    ; "***abcd***"
WRITE $$f^STDFMT("{:->8.2f}",3.14159),!        ; "----3.14"

; literal braces
WRITE $$f^STDFMT("{{}}"),!                     ; "{}"
```

## Default alignment

Without an explicit `align`, the alignment depends on the type:

- **Left-align** for `s` (string) and no-type — matches Python.
- **Right-align** for `d f x X o b` (numeric) — matches Python.

## Negative numbers

`d`, `x`, `X`, `o`, `b` render negative integers with a leading `-`:

```m
WRITE $$f^STDFMT("{:d}",-42),!                 ; "-42"
WRITE $$f^STDFMT("{:x}",-255),!                ; "-ff"
WRITE $$f^STDFMT("{:b}",-2),!                  ; "-10"
```

For `f`, `$FNUMBER` handles the sign natively.

## Float precision

`{:f}` defaults to 6 decimal places (matching Python). Explicit
precision via `{:.Nf}` rounds via `$FNUMBER`'s standard semantics:

```m
WRITE $$f^STDFMT("{:f}",3.14),!                ; "3.140000"
WRITE $$f^STDFMT("{:.0f}",3.7),!               ; "4"        — rounded
WRITE $$f^STDFMT("{:.3f}",3.14159),!           ; "3.142"    — round up
WRITE $$f^STDFMT("{:.3f}",3.14149),!           ; "3.141"    — round down
```

## Errors (`$ECODE`)

The following malformed inputs set `$ECODE`:

| Code | Trigger |
|---|---|
| `,U-STDFMT-MISSING-ARG,` | `{}` or `{N}` references an unsupplied positional, or `{name}` references a key not in `.args`. |
| `,U-STDFMT-UNCLOSED-BRACE,` | `{` without a matching `}`. |
| `,U-STDFMT-UNESCAPED-RBRACE,` | A lone `}` (not part of `}}`). |
| `,U-STDFMT-UNKNOWN-TYPE,` | A type character that isn't one of `s d f x X o b`. |

These error paths are **specified and behave correctly when called
from production procedure-form code**, but they are not unit-tested
via `raises^STDASSERT` — see below.

### Why no error-path tests in v0.0.3

`STDASSERT.raises` uses an arg-less `QUIT` in its `$ETRAP` handler.
That handler runs in the routine where the error fired. STDFMT's
public surface (`f`, `fn`) is reached via an extrinsic-function chain
(`$$f → $$render → $$expand → $$apply → $$convert`), so when one of
those extrinsics sets `$ECODE`, the trap's arg-less `QUIT` fires
`%YDB-E-NOTEXTRINSIC` (M17) and the captured `$ECODE` is clobbered
by the cascade. STDB64 / STDUUID don't surface this because they
have no error-path assertions today; STDASSERT's own raises-tests
trigger errors via `set x=1/0` in procedure-form context.

This is a **toolchain limitation in STDASSERT.raises**, not a STDFMT
bug, and is filed in [`discoveries.md`](../tracking/discoveries.md).
The fix (use `ZGOTO`-based unwind in the trap, or document a separate
extrinsic-aware variant `raisesx`) is a v0.0.5-or-later change.
Production code that wants to catch STDFMT errors uses `$ETRAP` with
`ZGOTO` rather than arg-less `QUIT`.

Until that lands, STDFMT's error paths are documented here and
exercised at the call-site by hand. Anyone implementing
extrinsic-style stdlib modules with `$ECODE` errors will want to
either:

1. Not use `raises^STDASSERT` for those error paths (defer until the
   trap is fixed).
2. Wrap the extrinsic chain in a procedure-form caller that
   intercepts the trap explicitly with `ZGOTO`.

## Edge cases

- **Empty template.** `$$f^STDFMT("")` returns `""`.
- **Width < `|value|`.** When the rendered value is already at least
  `width` characters, the value is returned unchanged (no truncation
  unless `precision` is also set).
- **String precision = 0.** `{:.0s}` returns the empty string.
- **Reused references.** `{0}` may appear multiple times; the same
  arg is rendered each time. Auto-numbered `{}` advances the counter
  each occurrence, even if the same arg ends up at multiple
  positions.
- **Mixed numbering.** Mixing `{}` (auto) and `{0}` (explicit) in the
  same template is permitted; auto-numbering advances independently.

## Conformance / lookup table

| Spec | Input | Output |
|---|---|---|
| `{}` | `"x"` | `"x"` |
| `{0}` | `"x"` | `"x"` |
| `{name}` (fn) | `args("name")="x"` | `"x"` |
| `{:s}` | `42` | `"42"` |
| `{:d}` | `42` | `"42"` |
| `{:f}` | `3.14` | `"3.140000"` |
| `{:.2f}` | `3.14` | `"3.14"` |
| `{:x}` | `255` | `"ff"` |
| `{:X}` | `255` | `"FF"` |
| `{:o}` | `8` | `"10"` |
| `{:b}` | `5` | `"101"` |
| `{:>5}` | `"hi"` | `"   hi"` |
| `{:<5}` | `"hi"` | `"hi   "` |
| `{:^6}` | `"hi"` | `"  hi  "` |
| `{:^5}` | `"hi"` | `" hi  "` |
| `{:*>5}` | `"x"` | `"****x"` |
| `{:0>5d}` | `42` | `"00042"` |
| `{:.3s}` | `"hello"` | `"hel"` |
| `{:*^10.4s}` | `"abcdefgh"` | `"***abcd***"` |

## See also

- [`STDB64`](stdb64.md), [`STDHEX`](stdhex.md) — string encoders that
  pair with `STDFMT` for log lines and structured output.
- `STDLOG` (v0.0.4) — structured logger that consumes `STDFMT`-style
  templates for its `event` argument.
- `STDDATE` (v0.0.5) — ISO-8601 helpers that compose with `STDFMT`
  for human-readable timestamps.
