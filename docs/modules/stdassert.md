---
module: STDASSERT
tag: v0.0.1
phase: Phase 1
stable: stable
since: v0.0.1
synopsis: ""
labels: ['contains', 'eq', 'false', 'len', 'ne', 'near', 'quote', 'raises', 'raisesUnwound', 'recordFail', 'recordPass', 'report', 'silent', 'start', 'true']
errors: []
conformance: []
see_also: ['STDSNAP']
---

# `STDASSERT` — assertion library

The cornerstone of every test suite in m-stdlib (and the recommended
assertion vocabulary for any M project that wants a richer API than
m-tools `^TESTRUN`).

Output mirrors `^TESTRUN`'s line protocol byte-for-byte so m-cli's
`m test` runner accepts STDASSERT-driven suites unchanged. See [§7.6
of the implementation plan](../plans/m-stdlib-implementation-plan.md#7-phase-0--bootstrap-done-2026-04-30)
for the bootstrap rationale.

## Suite shape

```m
STDASSERTTST    ;
        NEW pass,fail
        DO start^STDASSERT(.pass,.fail)
        ;
        DO tMyCase(.pass,.fail)
        DO tAnotherCase(.pass,.fail)
        ;
        DO report^STDASSERT(pass,fail)
        QUIT
        ;
tMyCase(pass,fail)      ;@TEST "what this verifies"
        DO eq^STDASSERT(.pass,.fail,$$myFn^MYROUTINE("input"),"expected","got expected output")
        QUIT
```

The `t<UpperCase>(pass,fail)` label convention is the m-cli `m test`
discovery contract — keep it. The `;@TEST "..."` comment provides a
human-readable description picked up by LSP and TAP output.

## Public API

| Label | Signature | Asserts |
|---|---|---|
| `start` | `start(p,f)` | Initialise counters: sets `p=0,f=0`. |
| `report` | `report(p,f)` | Print summary; `HALT` with non-zero exit if `f>0`. |
| `eq` | `eq(p,f,actual,expected,desc)` | `actual=expected` (string). |
| `ne` | `ne(p,f,actual,expected,desc)` | `actual'=expected`. |
| `true` | `true(p,f,cond,desc)` | `cond` is truthy (numeric prefix non-zero). |
| `false` | `false(p,f,cond,desc)` | `cond` is falsy (numeric prefix zero or empty). |
| `near` | `near(p,f,a,b,eps,desc)` | `\|a-b\|<=eps` (use for floats). |
| `raises` | `raises(p,f,code,errno,desc)` | XECUTEing `code` sets `$ECODE` containing `errno`. |
| `contains` | `contains(p,f,haystack,needle,desc)` | `haystack[needle` (M's substring operator). |
| `len` | `len(p,f,actual,n,desc)` | `actual=n` — caller computes the length. |
| `silent` | `silent(on)` | **Internal.** Toggles output suppression for self-tests. |

All assertion labels accept counters by reference (`.pass,.fail`),
update them, and print one PASS/FAIL line per call. They never halt
or throw — `report` is the single point of process exit.

## Examples

```m
; equality
DO eq^STDASSERT(.pass,.fail,$LENGTH(s),5,"5-char string")

; inequality
DO ne^STDASSERT(.pass,.fail,oldId,newId,"id rotated")

; truthiness (succeeds for any non-zero numeric prefix)
DO true^STDASSERT(.pass,.fail,$DATA(arr),"arr defined")

; float comparison with tolerance
DO near^STDASSERT(.pass,.fail,sum,3.14,0.01,"approx pi")

; expected error
DO raises^STDASSERT(.pass,.fail,"NEW x SET x=1/0",",M9,","DIVZERO ecode")

; substring containment
DO contains^STDASSERT(.pass,.fail,output,"OK","status line present")

; length comparison
DO len^STDASSERT(.pass,.fail,$LENGTH(arr),3,"3-element array")
```

## Output protocol (parser contract)

Every assertion emits exactly one of:

```
  PASS  <desc>
```

or:

```
  FAIL  <desc>
         expected: <expected>
         actual:   <actual>
```

Two leading spaces before `PASS`/`FAIL`; nine leading spaces before
`expected:`/`actual:`. `report` emits:

```
Results: <total> tests  <p> passed  <f> failed
All tests passed.
```

(or `<n> test(s) FAILED.` followed by `HALT`).

m-cli's `m test` runner parses this protocol verbatim
([m-cli/src/m_cli/test/runner.py:69-78](../../../m-cli/src/m_cli/test/runner.py#L69-L78)).
**Don't change the format.** If you add new assertion helpers, route
their output through `recordPass` / `recordFail` so the protocol stays
single-sourced.

## Edge cases

- **`raises` and `$ECODE`.** `$ECODE` is a special variable and cannot
  be `NEW`ed. The implementation explicitly clears it before and after
  the `XECUTE`. The XECUTE-of-arg pattern is the documented purpose;
  m-cli's M-MOD-036 (taint→XECUTE) is suppressed at that line.
- **`true`/`false` semantics.** M evaluates strings as numbers when
  used in conditional contexts: `"abc"` is `0` (false), `"7abc"` is
  `7` (true). `true()` and `false()` use this M-native semantic.
- **`contains` with empty needle.** `"abc"["" ` is true in M — empty
  needle always matches. `contains` mirrors this.
- **Self-test of failure paths.** Tests that need to verify the FAIL
  branch (e.g. "does `eq` increment `fail` when actual!=expected?")
  use `silent(1)` to suppress the deliberate FAIL line, then verify
  the counters with another `eq` call. `silent(0)` resumes output.
- **Counter scope.** All assertion helpers update `p`/`f` by reference.
  Pass them with the leading dot: `do eq^STDASSERT(.pass,.fail,...)`.
  Forgetting the dot silently disconnects the counters from the
  outer report.

## Error codes

`STDASSERT` itself doesn't set `$ECODE`. Failing assertions only
increment `f`; control returns to the caller. `report` `HALT`s the
process with a non-zero status when `f>0`, which is what propagates
exit failure to `m test` / CI.

## Lint suppressions

Test suites that delegate `(pass,fail)` to STDASSERT helpers should
file-disable `M-MOD-020` at the top:

```m
STDFOOTST       ; ...
        ; m-lint: disable-file=M-MOD-020
        ; (m-cli's by-ref analyzer can't see writes through STDASSERT helpers.)
        NEW pass,fail
        ...
```

This is the canonical idiom — see
[`tests/STDASSERTTST.m`](../../tests/STDASSERTTST.m).

## See also

- [`STDUUID`](stduuid.md) — first consumer of STDASSERT.
- Implementation plan §8.1 — the API spec.
- m-tools/`^TESTRUN` — the legacy assertion library STDASSERT replaces.
  STDASSERT is a drop-in with a richer vocabulary; whole-suite
  execution under `m test` works without m-cli changes.
