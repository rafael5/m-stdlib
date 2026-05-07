# `STDMATH` — Numeric helpers

A small set of numeric primitives for the cases M's native arithmetic
doesn't directly cover: scalar `clamp`, plus reductions over a
caller-owned array (`min` / `max` / `sum` / `count` / `mean`). Pure-M
throughout — no `$Z*` extensions, no STDREGEX dep — runs unchanged on
YDB and IRIS.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `clamp` | `$$clamp^STDMATH(x, lo, hi)` | `lo` if `x < lo`, `hi` if `x > hi`, else `x`. |
| `min` | `$$min^STDMATH(.arr)` | Smallest value in `arr` (first-level `$ORDER` walk); `""` if empty. |
| `max` | `$$max^STDMATH(.arr)` | Largest value; `""` if empty. |
| `sum` | `$$sum^STDMATH(.arr)` | Sum of values; `0` if empty. |
| `count` | `$$count^STDMATH(.arr)` | Number of `$ORDER`-visible values at depth 1; `0` if empty. |
| `mean` | `$$mean^STDMATH(.arr)` | `sum / count`; `""` if empty (no division by zero). |

## Examples

```m
; scalar clamp — useful for HTTP status codes, percentages, levels
WRITE $$clamp^STDMATH(99, 0, 10),!     ; 10
WRITE $$clamp^STDMATH(-3, 0, 10),!     ; 0
WRITE $$clamp^STDMATH(2.5, 0, 5),!     ; 2.5

; array reductions — caller owns the tree
NEW arr  SET arr(1)=3,arr(2)=1,arr(3)=4,arr(4)=1,arr(5)=5,arr(6)=9,arr(7)=2,arr(8)=6
WRITE $$min^STDMATH(.arr),!            ; 1
WRITE $$max^STDMATH(.arr),!            ; 9
WRITE $$sum^STDMATH(.arr),!            ; 31
WRITE $$count^STDMATH(.arr),!          ; 8
WRITE $$mean^STDMATH(.arr),!           ; 3.875

; works with any subscript shape
NEW byKey  SET byKey("a")=10,byKey("b")=3,byKey("c")=7
WRITE $$min^STDMATH(.byKey),!          ; 3
WRITE $$count^STDMATH(.byKey),!        ; 3
```

## Empty-array convention

| Function | Empty result |
|---|---|
| `min`, `max`, `mean` | `""` (no value to report; `mean` avoids division by zero) |
| `sum`, `count` | `0` (additive identity / cardinality) |

The `""` sentinel is the ANSI-M idiom for "no value." Callers who
need an exception on empty input should test `$$count^STDMATH(.arr)>0`
before reducing — the function itself will not raise.

## Walk semantics

All array-walking entry points operate on the **first subscript
level** only via `$ORDER`. Multi-dimensional arrays (`arr(i, j)`)
read only their first level — descend yourself if you want a deeper
walk:

```m
; sum the leaves of a 2-D array
NEW total,i  SET total=0
SET i="" FOR  SET i=$ORDER(arr(i)) QUIT:i=""  SET total=total+$$sum^STDMATH(arr(i,))
```

(`arr(i,)` is invalid syntax — that's the snippet the reader has
to fill in: walk the inner level themselves and pass each leaf-
or sub-array to the right primitive.)

## Numeric coercion

Non-numeric values are coerced via M's standard unary-`+` rule:
`+"abc"=0`, `+"3.14"=3.14`, `+""=0`, `+"42-extra"=42`. This matches
how every other M arithmetic primitive (`set total=total+arr(k)`,
`if v<m`) treats string operands, so STDMATH does not surprise
callers with a different rule.

A consequence: a `mean` over `(10, "abc", 20)` is `(10+0+20)/3 = 10`,
not `(10+20)/2 = 15`. Filter the input yourself if you want to skip
non-numeric entries.

## Decimal arithmetic

YDB and IRIS both perform exact decimal arithmetic at typical scales
(unlike IEEE-754 floats). `$$sum^STDMATH` over `(0.1, 0.2, 0.3)`
returns exactly `0.6` — no `0.6000000000000001` drift. STDMATH does
not change this; it just wraps the loop.

## Engine portability

Pure-M, no `$Z*` extensions. Runs unchanged on YDB and IRIS. The
test suite (28 assertions across 26 labels) is the conformance
gate.

## See also

- [`STDCOLL`](stdcoll.md) — collection types (Set / Map / Stack /
  Queue / Heap). STDMATH operates on plain caller-owned arrays;
  if you want a sorted heap you can pull min/max from in
  `O(log N)`, build a `STDCOLL.Heap` instead of walking with
  `$$min^STDMATH` repeatedly.
- [`STDPROF`](stdprof.md) — wall-clock profiler with its own
  `min` / `max` / `mean` / `percentile` over per-tag sample
  arrays. STDPROF inlines its reductions for tag-aware bookkeeping;
  STDMATH is the generic shape.
