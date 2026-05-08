# `STDFIX` — fixture lifecycle and per-test isolation

Pure-M test-isolation primitive built on YDB nested transactions:
each fixture scope wraps its body in `tstart` / `trollback` so every
global mutation made by the body is rolled back automatically when
the scope ends. Pairs with the `m test` runner protocol described in
[`docs/tdd-orchestration-plan.md` §6.4](../plans/tdd-orchestration-plan.md).

## Public API

| Label | Signature | Returns |
|---|---|---|
| `with` | `do with^STDFIX(tag, code)` | (proc) — XECUTEs `code` inside an auto-managed transaction scope. |
| `active` | `$$active^STDFIX()` | `1` if any nested transaction is open, `0` otherwise. |
| `register` | `do register^STDFIX(tag, setupCode, teardownCode)` | (proc) — declares a reusable fixture under `tag`. |
| `invoke` | `do invoke^STDFIX(tag, code)` | (proc) — runs `tag`'s registered setup, then `code`, then `tag`'s registered teardown — all in one rolled-back scope. |
| `cleanup` | `do cleanup^STDFIX` | (proc) — best-effort rollback of any leaked transaction scope. |

## Why one-shot wrappers (no standalone setup/teardown)

YDB enforces **TPQUIT**: a routine cannot return (`quit`) with an
unbalanced `tstart`. The `tstart` and matching `trollback` (or
`tcommit`) MUST live in the same routine frame. STDFIX therefore
cannot expose the standalone `setup(tag)` / `teardown(tag)` pair
described in the orchestration-plan sketch — every transaction-bearing
label is a one-shot wrapper that opens AND closes the scope before
returning. The runner-side wiring in `m test` (see [§6.4 of the
orchestration plan](../plans/tdd-orchestration-plan.md)) consumes
`with`/`invoke`, not raw `setup`/`teardown`.

## Examples

```m
; ---- with: explicit one-shot scope ----
do with^STDFIX("scope","do setupSchema^DDL set ^MyData(1)=42")
; ^MyData(1) is rolled back; ^DDL changes too if they wrote globals

; ---- active: predicate ----
write $$active^STDFIX(),!                       ; 0 outside a scope
do with^STDFIX("scope","write $$active^STDFIX(),!")  ; 1 inside

; ---- register + invoke: reusable fixture ----
do register^STDFIX("dbReset",
.   "do reset^DB",
.   "do verify^DB")
do invoke^STDFIX("dbReset","do tCheck^MYTST(.p,.f)")
; setup hook ran, body ran, teardown hook ran — all rolled back

; ---- cleanup: defensive rollback ----
do cleanup^STDFIX                               ; idempotent at $tlevel=0
```

## Nested scopes

`with` and `invoke` use `trollback $tlevel-1` (target = caller's
$tlevel) rather than bare `trollback` (which targets $tlevel=0), so
nested calls roll back **only their own level** and leave any outer
transaction intact:

```m
do with^STDFIX("outer", "set ^X(1)=""outer-val""  do with^STDFIX(""inner"",""set ^X(2)=""""inner-val"""""")")
; After inner trollback: ^X(2) gone, ^X(1)=outer-val still visible.
; After outer trollback: ^X(1) gone too.
```

The scope tag is recorded in `^STDLIB($job,"FIX","STACK",$tlevel)`
while the scope is open — useful for diagnostics or for callers that
need to distinguish their own scopes from foreign transactions.

## Local variables survive rollback

`tstart` (the form STDFIX uses — no `*` and no var-list) does **not**
restore local variables on `trollback`. This is the intended
semantic: STDASSERT's `pass`/`fail` counters, runner-side bookkeeping,
and any probe variables used in tests all survive the rollback. Only
global writes (and other transaction-covered state) are undone.

```m
; idiomatic probe pattern: read inside the scope, assert outside
new probedActive,probedTag
do with^STDFIX("myScope",
.   "set probedActive=$$active^STDFIX(),"_
.   "probedTag=$get(^STDLIB($job,""FIX"",""STACK"",$tlevel))")
; probedActive=1, probedTag="myScope" — both survived the trollback
```

## Errors

| `$ECODE` | When |
|---|---|
| `,U-STDFIX-EMPTY-TAG,` | `with` / `register` called with an empty `tag`. |
| `,U-STDFIX-UNREGISTERED-TAG,` | `invoke` called with a `tag` that was never `register`ed. |

`with` and `invoke` install a private `$ETRAP` that rolls back the
scope before re-raising the original `$ECODE` so the caller's trap
sees it. (One follow-on caveat: re-raising `$ECODE` from a trap that
also rolled back its own transaction does not always propagate
through the next outer `$ETRAP` in current YDB — see
[`TOOLCHAIN-FINDINGS.md`](../tracking/TOOLCHAIN-FINDINGS.md) row
2026-05-05 P2 against YottaDB. The **rollback** itself is
unconditionally observable; the **re-raise** contract is
documented-but-unverified pending an upstream YottaDB fix or a
parallel-frame workaround.)

## Storage

All STDFIX state lives under `^STDLIB($job,"FIX",...)`:

| Path | Contents |
|---|---|
| `^STDLIB($job,"FIX","STACK",N)` | scope tag at $tlevel `N` (set inside the scope, rolled back on exit). |
| `^STDLIB($job,"FIX","REG",tag,"SETUP")` | setup code registered for `tag`. |
| `^STDLIB($job,"FIX","REG",tag,"TEARDOWN")` | teardown code registered for `tag`. |

Registered fixtures are written outside any STDFIX scope, so they
persist across `with`/`invoke` rollbacks and survive between tests in
the same process. Killing `^STDLIB($job,"FIX")` directly is the
between-suite reset hook used by the test runner (and by
`reset` in `STDFIXTST.m`).

## IRIS portability

IRIS supports `tstart`/`trollback` with the same per-frame balance
requirement and the same nested-savepoint semantics. The `($tlevel-1)`
target form for `trollback` is also supported. STDFIX should be
portable as-is once the IRIS CI job (track A5 / L4 sub-track) is
re-introduced.

## Caveats

- `cleanup` rolls back **every** open transaction, including any
  non-STDFIX ones the caller's stack might own. Call it only at a
  top-level frame that owns no enclosing `tstart`. The test runner
  uses it as a defensive between-tests reset; production code should
  not need it.
- The error-path tests for `with`'s re-raise are deferred (see
  Errors above and `TOOLCHAIN-FINDINGS.md` P1). The 28 happy-path
  assertions exercise every public label; the contract that
  `with`/`invoke` propagate `$ECODE` to the caller after rollback
  ships unverified by automated test until that fix lands.
