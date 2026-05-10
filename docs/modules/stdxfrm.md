---
module: STDXFRM
tag: v0.4.0
phase: Phase 3 + post-P4 wave
stable: stable
since: v0.4.0
synopsis: 'Higher-order array transforms (map / filter / reduce via @-indirection lambdas)'
labels: ['filter', 'map', 'reduce']
errors: []
conformance: []
see_also: []
---

# `STDXFRM` — `map` / `filter` / `reduce` over caller-owned arrays

A small higher-order-function trio that modernises the standard
`$ORDER`-loop idiom. The transformation is supplied as an M
expression string and evaluated via `XECUTE "set <target>="_expr`
in the module's stack frame — the lambda sees `value` and `key`
(and `acc`, for `reduce`) as plain locals. Pure-M throughout;
runs unchanged on YDB and IRIS.

## Public API

| Entry | Signature | Returns |
|---|---|---|
| `map` | `do map^STDXFRM(.in, expr, .out)` | (procedure) populates `out(k)` for each `k` in `in`. |
| `filter` | `do filter^STDXFRM(.in, expr, .out)` | (procedure) copies `in(k)→out(k)` iff `expr` is truthy. |
| `reduce` | `$$reduce^STDXFRM(.in, expr, init)` | the final accumulator after walking `in`. |

## Examples

```m
; double every element
NEW a,out  SET a(1)=1,a(2)=2,a(3)=3
DO map^STDXFRM(.a, "value*2", .out)
; out(1)=2, out(2)=4, out(3)=6

; format key:value pairs
NEW a,out  SET a("x")=10,a("y")=20
DO map^STDXFRM(.a, "key_""=""_value", .out)
; out("x")="x=10", out("y")="y=20"

; even-only
NEW a,out  SET a(1)=2,a(2)=4,a(3)=5,a(4)=8
DO filter^STDXFRM(.a, "value#2=0", .out)
; out(1)=2, out(2)=4, out(4)=8 (5 dropped)

; predicate on key
NEW a,out  SET a("apple")=1,a("banana")=2,a("apricot")=3
DO filter^STDXFRM(.a, "$extract(key,1)=""a""", .out)
; out("apple")=1, out("apricot")=3 (banana dropped)

; sum
NEW a  SET a(1)=1,a(2)=2,a(3)=3,a(4)=4
WRITE $$reduce^STDXFRM(.a, "acc+value", 0),!  ; 10

; product
WRITE $$reduce^STDXFRM(.a, "acc*value", 1),!  ; 24

; count via increment
WRITE $$reduce^STDXFRM(.a, "acc+1", 0),!      ; 4
```

## Lambda locals

The expression is evaluated via `XECUTE "set <target>="_expr`
inside STDXFRM's stack frame, so it sees these locals:

| Local | Visible to | Holds |
|---|---|---|
| `value` | `map`, `filter`, `reduce` | the current element's value (`in(k)`) |
| `key` | `map`, `filter`, `reduce` | the current subscript |
| `acc` | `reduce` only | the accumulator carried forward (initialised to `init`) |

The expression must be a single M expression (the right-hand side
of an implicit `set`), not a multi-command code string. For
multi-statement transforms, write a dedicated routine and call it
from the expression: `"$$transform^MYAPP(value,key)"`.

## Walk discipline

- `$ORDER`-walk at **depth 1 only**. Multi-dimensional arrays
  (`in(i, j)`) read only the first level — the lambda sees
  `value` as the empty string when called on a strictly
  subscripted-only node, so descend yourself if you need a
  deeper walk.
- Subscript shape doesn't matter: integer, string, sparse,
  whatever the caller built up.
- For `map` and `filter`, `out` is killed before the walk —
  stale entries from a prior call cannot leak through.
- For `reduce`, the empty-input case returns `init` unchanged
  (no special-case error; the standard fold identity).

## Error semantics

If `expr` raises (compile error, division by zero, undefined
variable, custom `$ECODE`, etc.) the error **propagates to the
caller's `$ETRAP` unmodified**. STDXFRM does not catch — that's
the right default for a building-block primitive. If you want a
sandbox, wrap your call:

```m
NEW $ETRAP  SET $ETRAP="SET errored=1 QUIT"
NEW errored  SET errored=0
DO map^STDXFRM(.in, "value*2", .out)
IF errored ...
```

## When to reach for STDXFRM vs a hand-rolled loop

- **Use STDXFRM when** the transformation is a one-liner expression
  and the loop body is purely "compute next value / decide keep /
  fold." It's roughly half the keystrokes of the equivalent
  `for set k=$order(in(k)) quit:k="" ...` and the intent is more
  readable at the call site.
- **Skip STDXFRM when** the loop needs early-out (`quit` mid-walk
  on some condition), needs to mutate two outputs at once, or
  involves a multi-statement body. The hand-rolled loop stays
  faster and clearer in those cases.

## Performance

The dispatch builds the `set <target>="_expr` command string
once per call (outside the `$ORDER` walk) and `XECUTE`s it per
element. YDB caches the compiled form of an `XECUTE` argument
when the same string is reused, so the per-element overhead
collapses to a constant after the first iteration. Slower than
a hand-rolled loop with a static expression but adequate for
the typical workload (config transforms, FileMan record
munging, report aggregations). For hot loops over millions of
elements, write the loop directly.

## Why XECUTE and not `@expr`?

The original v1 implementation used `set result=@expr`. That
form is **name-indirection** in M — `@expr` resolves to a single
expratom (a glvn / literal / unary / parenthesised expression),
not an arbitrary expression. So `@"value*2"` fires
`%YDB-E-INDEXTRACHARS` because `*2` parses as trailing junk
after the name `value`. The XECUTE form accepts any expression
that's valid on the right-hand side of `set` — which is what
the documented contract advertises.

## Engine portability

Pure-M, no `$Z*` extensions. `XECUTE` is ANSI M standard. Runs
unchanged on YDB and IRIS. The test suite (38 assertions across
19 labels) is the conformance gate.

## See also

- [`STDMATH`](stdmath.md) — pre-built reductions (`min` / `max`
  / `sum` / `mean`) that don't need a lambda. Use these when the
  reduction is one of the built-ins.
- [`STDCOLL`](stdcoll.md) — collection types (Set / Map / Stack
  / Queue / Heap). STDXFRM operates on plain arrays; if your
  input is already a STDCOLL container, the equivalent is to
  iterate via that container's own `keys` / `values` enumerator
  and use STDXFRM only after you've extracted a flat array.
- [`STDMOCK`](stdmock.md) — same `@`-indirection idiom but for
  call interception (`do @resolved@(.args)`).

## History

Higher-order array transforms — map / filter / reduce. The original
implementation (commit `8e6b689`-era) used `@expr` name-indirection in
own stack frame (`value` / `key` / `acc` locals visible to the
lambda); same idiom as STDMOCK's `do @resolved@(.args)`.

Engine run on 2026-05-08 hit `%YDB-E-INDEXTRACHARS` on `value*2` —
name-indirection is **expratom-only** on this engine, doesn't accept
arbitrary RHS-of-set expressions. Migrated to **XECUTE-evaluated
lambdas** (`set <target>=<expr>`) which accepts any RHS. M-MOD-036
disabled file-wide for the intentional indirection. Public API
unchanged. STDXFRMTST 38/38 green.

Companion fix in `tMapHasAccessToKey` test typo: `"key_'='_value"` (M
parses `'=` as not-equals operator) → `"key_""=""_value"` (canonical M
double-quote string).
