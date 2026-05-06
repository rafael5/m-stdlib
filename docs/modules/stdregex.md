# `STDREGEX` — regular expressions

A Thompson-NFA regex engine on YottaDB and a `$MATCH`/`$LOCATE` wrap
on IRIS. The v0.2.0 surface is a *subset* of common regex flavours —
no back-references in patterns, no lookaround, no Unicode property
classes, no inline modifiers, no possessive or lazy quantifiers.
Patterns that use any of those features are rejected at compile time
with `U-STDREGEX-UNSUPPORTED`. A follow-on `STDREGEX_PCRE`
(Phase-3-adjacent) will ship full PCRE via `$ZF` to `libpcre2`.

## Public API

| Extrinsic / Procedure | Signature | Behaviour |
|---|---|---|
| `compile` | `$$compile^STDREGEX(pattern)` | Returns a positive integer handle. State lives under `^STDLIB($job,"stdregex",h,...)` until `free`. Raises `U-STDREGEX-BAD-PATTERN` on parse error or `U-STDREGEX-UNSUPPORTED` on a feature outside the v0.2.0 subset. |
| `valid` | `$$valid^STDREGEX(pattern)` | `1` iff `pattern` parses cleanly. Does not distinguish BAD-PATTERN from UNSUPPORTED — `compile` does. |
| `match` | `$$match^STDREGEX(h,s)` | `1` iff the *entire* `s` matches the pattern (anchored on both ends, equivalent to `^pattern$` semantics). |
| `search` | `$$search^STDREGEX(h,s)` | `1` iff any substring of `s` matches the pattern. Unanchored unless the pattern itself uses `^` or `$`. |
| `find` | `$$find^STDREGEX(h,s)` | 1-indexed start of the first match in `s`; `0` if no match. |
| `findall` | `do findall^STDREGEX(h,s,.out)` | Populates `out(1..N)` with every non-overlapping match text in left-to-right order. Empty `out` if no match. |
| `groups` | `do groups^STDREGEX(h,s,.g)` | Populates `g(0)` with the full match text and `g(k)` (k≥1) with each capture group's text, counted by `(` position. `(?:...)` does not consume a slot. Raises `U-STDREGEX-NO-MATCH` if `s` does not match. |
| `replace` | `$$replace^STDREGEX(h,s,repl)` | Returns `s` with every match replaced by `repl`. `\1..\9` in `repl` expand to the corresponding capture group; `\\` is a literal backslash; unrecognised `\X` passes through as the literal two characters. |
| `split` | `do split^STDREGEX(h,s,.out)` | Populates `out(1..N)` with the segments of `s` between matches. Adjacent matches yield empty segments; leading / trailing matches yield empty leading / trailing segments. |
| `free` | `do free^STDREGEX(h)` | Releases the compiled-pattern state. Idempotent; the handle must not be reused after `free`. |

`compile` / `valid` / `match` / `search` / `find` / `replace` are
extrinsics; `findall` / `groups` / `split` / `free` are procedures.

## Supported subset

| Construct | Notes |
|---|---|
| Literals | Any char that isn't a metacharacter. |
| `.` | Any single char *except* `LF` (`\n`). |
| `^` / `$` | String-anchored start / end. v0.2.0 has no multiline mode. |
| `*` `+` `?` | Greedy, zero-or-more / one-or-more / zero-or-one. |
| `{n}` `{n,}` `{n,m}` | Greedy, exactly `n` / at least `n` / between `n` and `m`. |
| `[abc]` / `[^abc]` / `[a-z]` | Character class, with negation and ranges. `-` at end of class is literal. |
| `\d \D \w \W \s \S` | Predefined classes — digit / non-digit / word (alnum + `_`) / non-word / whitespace (space, tab, LF, CR, FF, VT) / non-whitespace. |
| `\\ \. \^ \$ \( \) \[ \] \{ \} \| \* \+ \? \-` | Escaped metacharacters. |
| `\n \t \r` | Control-char escapes. |
| `\|` | Alternation. |
| `(...)` | Capturing group. |
| `(?:...)` | Non-capturing group. |

## Out of scope (rejected with `U-STDREGEX-UNSUPPORTED`)

| Construct | Form |
|---|---|
| Back-references in pattern | `\1..\9` *inside the pattern* (still allowed inside the `repl` of `replace`) |
| Lookaround | `(?=...)`, `(?!...)`, `(?<=...)`, `(?<!...)` |
| Named groups | `(?<name>...)`, `(?P<name>...)` |
| Unicode property classes | `\p{...}`, `\P{...}` |
| Inline modifiers | `(?i)`, `(?m)`, `(?s)`, `(?x)`, `(?n)` |
| Possessive quantifiers | `*+`, `++`, `?+` |
| Lazy quantifiers | `*?`, `+?`, `??` |

Use `STDREGEX_PCRE` (Phase 3) for any of the above.

## Error codes

| Code | When |
|---|---|
| `U-STDREGEX-BAD-PATTERN` | `compile` / `valid` rejected the pattern as malformed (unbalanced `()`, unterminated `[`, trailing `\`, `{n,m}` with `m<n`, reverse range `[z-a]`, stray `*+?{)|` with no atom). |
| `U-STDREGEX-UNSUPPORTED` | `compile` / `valid` rejected a v0.2.0-out-of-scope feature (back-ref, lookaround, named group, Unicode class, inline modifier, possessive / lazy quantifier). |
| `U-STDREGEX-NO-MATCH` | `groups` was called but the pattern did not match `s`. |

## Examples

```m
; lifecycle
new h
set h=$$compile^STDREGEX("\d+")
write $$match^STDREGEX(h,"42"),!           ; 1
write $$match^STDREGEX(h,"the 42 cats"),!  ; 0  (match = full string)
write $$search^STDREGEX(h,"the 42 cats"),! ; 1
write $$find^STDREGEX(h,"the 42 cats"),!   ; 5
do free^STDREGEX(h)

; capture groups
new h,g
set h=$$compile^STDREGEX("(\d+)-(\w+)")
do groups^STDREGEX(h,"42-foo",.g)
write g(0),!  ; "42-foo"   — full match
write g(1),!  ; "42"
write g(2),!  ; "foo"
do free^STDREGEX(h)

; greedy semantics
new h,g
set h=$$compile^STDREGEX("(a.*b)")
do groups^STDREGEX(h,"a__b__b",.g)
write g(1),!  ; "a__b__b"  — greedy: extends to the second b

; findall + replace + split
new h,out
set h=$$compile^STDREGEX("\d+")
do findall^STDREGEX(h,"a 1 b 22 c 333",.out)
write out(1),!,out(2),!,out(3),!          ; "1" "22" "333"
write $$replace^STDREGEX(h,"a 1 b 22 c","#"),!  ; "a # b # c"
do free^STDREGEX(h)

set h=$$compile^STDREGEX(",")
do split^STDREGEX(h,"a,b,c",.out)
write out(1),!,out(2),!,out(3),!          ; "a" "b" "c"
do free^STDREGEX(h)

; replace with backref
new h
set h=$$compile^STDREGEX("(\d+)")
write $$replace^STDREGEX(h,"x42y","[\1]"),!     ; "x[42]y"
```

## A worked example: JWT issuer parsing (STDHTTP setup)

`STDHTTP` (Phase 3) needs to extract the issuer URL from the `iss`
claim of a JWT after the JSON has been decoded. STDREGEX is the
right primitive — issuers are constrained to a small subset of URLs
and we want a strict accept/reject:

```m
new h,g,iss
set h=$$compile^STDREGEX("^https://([a-z0-9.-]+)(:[0-9]+)?(/.*)?$")
set iss="https://login.example.com/realms/m-stdlib"
if $$match^STDREGEX(h,iss) do groups^STDREGEX(h,iss,.g)
write g(1),!  ; "login.example.com"
write g(3),!  ; "/realms/m-stdlib"
do free^STDREGEX(h)
```

Note the `$$match` gate: `groups` raises `U-STDREGEX-NO-MATCH` on a
non-match, so the lift-and-shift idiom is *check first, capture
second*.

## Engine notes

- **Construction.** Standard McNaughton-Yamada Thompson construction.
  Each AST node yields a fragment with entry / exit state ids. Concat
  chains via ε-edges; alt splits at entry and merges at exit;
  quantifiers add a priority-1 loop edge before the priority-2 skip
  edge so greedy falls out of edge order. Bounded `{n,m}` unrolls
  into `n` required copies plus star (for `{n,}`) or `(m-n)` optional
  copies (for `{n,m}`). Capture groups wrap the child in
  `capStart` / `capEnd` zero-width side-effect edges.
- **Simulation.** Pike-style breadth-first NFA walk. State dedup is
  first-arrival-wins; ε-closure is recursive DFS in edge-priority
  order, so greedy preference at any state both paths reach falls out
  of edge ordering. Simulation continues past the first accept hit;
  each later accept overwrites the recorded `bestEnd` / capture map.
  That delivers leftmost-greedy capture semantics for the v0.2.0
  subset.
- **State storage.** All per-handle state lives under
  `^STDLIB($job,"stdregex",h,...)`. The AST is committed first; the
  NFA references the AST for character-class items so the simulator
  reads them straight from the global at match time. `free(h)` is a
  single `kill` of the handle's subtree.
- **No DFA cache.** v0.2.0 does not cache compiled NFAs into a DFA.
  Each `match` / `search` / `find` walk is the NFA simulation. For
  the working set sizes regexes typically face inside M code, the NFA
  walk is fast enough that a DFA cache would be premature complexity.

## IRIS portability

The engine is YottaDB-first. On IRIS, `compile` keeps the source
pattern alongside the NFA; `match` / `search` / `find` over the
v0.2.0 simple-pattern subset translate to `$MATCH` / `$LOCATE`.
Captures on IRIS may use the `%Library.RegEx` class. Per §6
conventions, IRIS portability for STDREGEX is fail-soft — the
`iris-portability-check` CI job runs against
`intersystemsdc/iris-community:latest` and surfaces regressions
without gating merges. A full v0.2.0 IRIS pass is a follow-up.

## Conformance

The unit suite at `tests/STDREGEXTST.m` covers 90 assertions across
50 labelled tests: lifecycle (compile / free / valid), literal
matching, `.`, anchors, every quantifier form including bounded
`{n,m}`, character classes (positive / negative / ranges /
trailing-`-`), all six predefined classes, every escape form,
alternation (with and without grouping), capturing + non-capturing
groups (including nested capture), greedy semantics through
`(a.*b)/"a__b__b"`, public-API `findall` / `replace` (including
`\1` backref expansion) / `split`, and every error path.

## See also

- [`STDFMT`](stdfmt.md) — the formatting cousin: where STDREGEX
  decomposes input strings, STDFMT composes output strings.
- [`STDJSON`](stdjson.md) — natural composition partner for parsing
  text payloads (regex-extract, JSON-decode the result).
- `STDREGEX_PCRE` (Phase 3) — full PCRE via `$ZF` to `libpcre2`,
  for callers that need back-refs, lookaround, or Unicode property
  classes.
