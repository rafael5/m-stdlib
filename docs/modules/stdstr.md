---
module: STDSTR
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'String helpers (pad / trim / split / replaceAll / case / repeat)'
labels: ['endsWith', 'pad', 'padLeft', 'padRight', 'repeat', 'replaceAll', 'split', 'startsWith', 'toLowerASCII', 'toUpperASCII', 'trim', 'trimLeft', 'trimRight']
errors: []
conformance: []
see_also: []
---

# `STDSTR` — String helpers

A small set of string-manipulation primitives that show up
repeatedly across other modules: pad, trim, replace, split,
prefix / suffix predicates, ASCII case conversion, repeat.
Pure-M throughout — no `$Z*` extensions, no STDREGEX dep — so
runs unchanged on YDB and IRIS.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `pad` | `$$pad^STDSTR(s, n, c?)` | Alias for `padLeft` (numeric-formatting default). |
| `padLeft` | `$$padLeft^STDSTR(s, n, c?)` | s left-padded with c (default `" "`) to width n. |
| `padRight` | `$$padRight^STDSTR(s, n, c?)` | s right-padded to width n. |
| `trim` | `$$trim^STDSTR(s)` | s with leading and trailing whitespace stripped. |
| `trimLeft` | `$$trimLeft^STDSTR(s)` | s with leading whitespace stripped. |
| `trimRight` | `$$trimRight^STDSTR(s)` | s with trailing whitespace stripped. |
| `replaceAll` | `$$replaceAll^STDSTR(s, find, repl)` | s with every non-overlapping `find` replaced by `repl`. |
| `split` | `$$split^STDSTR(s, sep, .out)` | Splits s on sep; populates `out(1..N)`; returns N. |
| `startsWith` | `$$startsWith^STDSTR(s, prefix)` | `1` iff s begins with prefix. |
| `endsWith` | `$$endsWith^STDSTR(s, suffix)` | `1` iff s ends with suffix. |
| `toLowerASCII` | `$$toLowerASCII^STDSTR(s)` | A-Z → a-z; non-alpha preserved. |
| `toUpperASCII` | `$$toUpperASCII^STDSTR(s)` | a-z → A-Z; non-alpha preserved. |
| `repeat` | `$$repeat^STDSTR(s, n)` | s concatenated with itself n times. |

## Examples

```m
; padding (numeric formatting)
WRITE $$pad^STDSTR("5",3,"0"),!         ; "005"
WRITE $$padRight^STDSTR("ab",6,"-"),!   ; "ab----"
WRITE $$padLeft^STDSTR("x",4),!         ; "   x"  (default char is space)

; whitespace
WRITE $$trim^STDSTR("  hello  "),!      ; "hello"
WRITE $$trim^STDSTR($CHAR(9)_"hi"_$CHAR(10,13,32)),!  ; "hi"

; substitution
WRITE $$replaceAll^STDSTR("a-b-c","-","+"),!     ; "a+b+c"
WRITE $$replaceAll^STDSTR("foofoofoo","foo","bar"),!  ; "barbarbar"

; tokenisation
DO  SET n=$$split^STDSTR("a,b,c",",",.out)
WRITE n,!                                ; 3
WRITE out(1),"|",out(2),"|",out(3),!    ; a|b|c

; predicates
WRITE $$startsWith^STDSTR("hello world","hello"),!  ; 1
WRITE $$endsWith^STDSTR("hello world","world"),!    ; 1

; case-folding (ASCII only)
WRITE $$toLowerASCII^STDSTR("Hello-World"),!  ; "hello-world"
WRITE $$toUpperASCII^STDSTR("Hello-World"),!  ; "HELLO-WORLD"

; rep
WRITE $$repeat^STDSTR("-",10),!              ; "----------"
```

## Whitespace definition

`trim` / `trimLeft` / `trimRight` strip the four ASCII whitespace
characters: space (`$C(32)`), tab (`$C(9)`), LF (`$C(10)`), CR
(`$C(13)`). Internal whitespace is **always preserved**:

| Input | `trim` |
|---|---|
| `"  hello  "` | `"hello"` |
| `"  a  b  "` | `"a  b"` |
| `" \t\n\r hi \r\n\t "` | `"hi"` |
| `"     "` | `""` |
| `""` | `""` |

Unicode whitespace classes (NBSP, ideographic space, Mongolian
vowel separator, etc.) are **not** stripped. This keeps `trim`
byte-faithful and idempotent under any `$ZCHSET` mode — Unicode-
aware whitespace handling waits on a future `STDUNICODE` module.

## `replaceAll` semantics

- Empty `find` returns `s` unchanged (no infinite loop).
- Scan is **non-overlapping greedy left-to-right**:
  `replaceAll("aaaa", "aa", "b")` is `"bb"`, not `"ba"`.
- Replacement is **non-recursive**: bytes inserted by `repl` are
  not rescanned. `replaceAll("aa", "a", "aa")` is `"aaaa"`, not
  an infinite expansion.
- Implementation is `$piece`-based — split `s` on `find`, rejoin
  with `repl`. O(N) in input length.

## `split` semantics

- Empty input returns 0 with `out` cleared.
- Empty separator returns 0 (avoids infinite loop; matches
  Python's `str.split` with no separator argument behaving
  differently — STDSTR's split deliberately requires an explicit
  separator).
- Multi-char `sep` matches the literal sequence (`"a::b::c"` with
  `sep="::"` yields three pieces).
- Trailing separator yields a trailing empty element: `"a,b,"`
  with `sep=","` yields `["a", "b", ""]`.
- Implementation: `$piece`-walk.

## ASCII case conversion

`toLowerASCII` / `toUpperASCII` are byte-wise `$translate`
operations on the 26 letters `A-Z` ↔ `a-z`. They preserve
**every other byte** including digits, punctuation, whitespace,
and high-bit-set bytes. They are **not** locale-aware:
`toLowerASCII("Ä")` returns `"Ä"` (the byte sequence is preserved
verbatim). Use these for case-insensitive comparisons of
machine-generated identifiers (env var names, hex strings,
HTTP method tokens) where only the ASCII letter range matters.

## Engine portability

Pure-M, no `$Z*` extensions. Runs unchanged on YDB and IRIS. The
test suite (63 assertions across 37 labels) is the conformance
gate.

## See also

- [`STDFMT`](stdfmt.md) — printf-style formatter; has its own
  width / fill / alignment handling and does not use STDSTR.pad.
- [`STDARGS`](stdargs.md) — has its own quote-aware tokeniser
  (an upgrade over `split`); STDSTR.split is for one-pass simple
  separators.
- [`STDOS`](stdos.md) — `splitArgs` is whitespace-only and has
  the same shape as STDSTR.split with `sep=" "` plus run-collapse;
  the two will likely merge under a single tokeniser when STDOS
  picks up quote-aware splitting (T15).

## History

ASCII-only by design — pad / padLeft / padRight, trim / trimLeft /
trimRight, replaceAll, split, startsWith / endsWith, toLowerASCII /
toUpperASCII, repeat. Pure-M (`$translate` / `$piece` / `$find` /
`$extract`); no `$Z*` extensions, no STDREGEX dep.

**Optional add-on (T17, deferred):** Unicode whitespace + locale-aware
case folding. Deferred behind a future `STDUNICODE`. Activates when a
concrete consumer hits the ASCII-only limit.
