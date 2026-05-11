---
module: STDMOCK
tag: v0.1.2
phase: Phase 1b
stable: stable
since: v0.1.2
synopsis: 'opt-in test-time call interception (mock registry)'
labels: ['args', 'called', 'clear', 'invoke', 'register', 'resolve', 'unregister']
errors: []
conformance: []
see_also: []
created: 2026-05-05
last_modified: 2026-05-08
revisions: 3
doc_type: [REFERENCE]
---

# `STDMOCK` — opt-in test-time call interception

A small mock registry for unit-testing M code that needs to redirect
calls to FileMan, MailMan, KERNEL, or any tagged label without
modifying the production source. Phase 1b (M1) primitive — pairs with
`STDFIX` (per-test transaction isolation) and `STDSEED` (declarative
fixtures) to give M tests the basic ergonomics every other modern
language takes for granted.

## Public API

| Form | Signature | Returns |
|---|---|---|
| Procedure | `do register^STDMOCK(target, replacement)` | — |
| Procedure | `do unregister^STDMOCK(target)` | — |
| Procedure | `do clear^STDMOCK` | — |
| Extrinsic | `$$resolve^STDMOCK(target)` | replacement, or target itself |
| Procedure | `do invoke^STDMOCK(target, .args)` | — |
| Extrinsic | `$$called^STDMOCK(target)` | call count since last clear |
| Extrinsic | `$$args^STDMOCK(target, n, i)` | arg `i` of call `n` (`""` if absent) |

`target` and `replacement` are M label references in `LABEL^ROUTINE`
form (the same syntax `do` accepts).

## Mechanism — opt-in at the call site

STDMOCK is **not** a transparent rewriter. Production code that wants
to be mockable calls into STDMOCK explicitly:

```m
; production code, mockable
DO invoke^STDMOCK("EN^DIE",.args)
```

instead of:

```m
; production code, NOT mockable
DO EN^DIE(.args)
```

A test then registers a stub before exercising the production path:

```m
; test setup
DO register^STDMOCK("EN^DIE","stub^MYPKGTST")
DO subjectUnderTest^MYPKG()    ; calls invoke^STDMOCK("EN^DIE",.args)
                               ; -> reroutes to stub^MYPKGTST
DO unregister^STDMOCK("EN^DIE")
```

Two reasons for opt-in over transparent rewriting:

1. **No parser-aware code rewriting at lint time.** Transparent
   interception would require editing every `D`/`DO ^FOO` site at
   build time, which couples the toolchain to the source.
2. **Explicit at the call site.** Future readers see `invoke^STDMOCK`
   in the code and know "this call is a mock injection point" —
   matches how Python's `unittest.mock.patch` is explicit at the
   boundary it patches.

For zero-overhead production paths, callers can use
`do @$$resolve^STDMOCK(target)@(.args)` directly — same effect, no
call counting / arg recording.

## Examples

```m
; --- production code -----------------------------------------------
mySubject(args)
        new sendArgs
        set sendArgs(1)=args("address")
        set sendArgs(2)=args("body")
        do invoke^STDMOCK("send^MAILMAN",.sendArgs)
        quit

; --- test ----------------------------------------------------------
tSendsExpectedAddress(pass,fail)
        do clear^STDMOCK
        new args
        set args("address")="alice@example.com"
        set args("body")="hi"
        do register^STDMOCK("send^MAILMAN","stubSend^MYPKGTST")
        do mySubject^MYPKG(.args)
        do eq^STDASSERT(.pass,.fail,$$called^STDMOCK("send^MAILMAN"),1,"called once")
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("send^MAILMAN",1,1),"alice@example.com","address arg")
        quit
        ;
stubSend(args)  ; no-op stub
        quit
```

## Storage

Process-scoped under `^STDLIB($job, ...)`. No cross-process state.

| Subscript | Contents |
|---|---|
| `^STDLIB($job,"stdmock","reg",target)` | replacement label |
| `^STDLIB($job,"stdmock","cnt",target)` | call count |
| `^STDLIB($job,"stdmock","arg",target,n,i)` | arg `i` of call `n` |

`unregister(target)` drops all three subtrees for that target.
`clear` drops the entire `^STDLIB($job,"stdmock")` tree.

## Single-level resolution

`$$resolve` looks up exactly one hop. If `A → B` and `B → C` are both
registered, `$$resolve(A)` returns `B`, **not** `C`. This avoids
surprising cascades when a test registers a stub for a label that
itself happens to be registered in some other test fixture. If you
want chained replacement, register A directly to the final target.

## Transactions and isolation

The registry lives in a transactional global, so a `TROLLBACK` reverts
mock registrations. v0.1.2 does **not** provide rollback-immune
mocks. The intended pattern with `STDFIX` (Phase 1b TDD orchestration
plan) is:

- `STDFIX` opens a `TSTART` per test for global state isolation.
- Tests register their mocks (writes to `^STDLIB($job,"stdmock",...)`).
- Test runs.
- m-cli runner calls `do clear^STDMOCK` between tests.
- `STDFIX` closes the per-test transaction (`TROLLBACK` in unit mode,
  `TCOMMIT` in scenarios that want durability).

Either way, the registry doesn't leak across tests.

## Edge cases

- **Unknown target.** `$$called` returns `0`, `$$args` returns `""`,
  `$$resolve` returns the target unchanged. No `$ECODE`.
- **Re-register.** `register(target, X)` followed by
  `register(target, Y)` leaves `Y` in place; the prior `X` is silently
  overwritten. This matches Python `dict.__setitem__` semantics.
- **`unregister` of unknown target.** Idempotent no-op.
- **Resolved target doesn't exist as a label.** `do @resolved@(.args)`
  raises a YDB undefined-label error at run time. Caller's bug —
  STDMOCK doesn't validate registrations against the routine farm.
- **Args array with non-numeric subscripts.** `invoke` records
  whatever subscripts `$ORDER` returns, in collation order. Tests can
  read them back via `$$args(target, n, "key")` — the `i` parameter
  is the raw subscript, not necessarily a number.

## Lint suppression

`invoke` indirects on a value pulled from a transactional global,
which `m lint`'s data-flow analyzer (M-MOD-036) flags as code
injection. The line carries a `; m-lint: disable-next-line=M-MOD-036`
directive with a justification comment — the indirection is the
documented purpose of `invoke`, not a mistake.

## See also

- [`STDASSERT`](stdassert.md) — assertion helpers used in test bodies.
- `STDFIX` (Phase 1b, v0.1.1) — per-test transaction isolation.
- `STDSEED` (Phase 1b, v0.1.3) — declarative fixture loading.
- m-cli runner [track X](../tracking/parallel-tracks.md#34-m-cli-companion-tracks) —
  hard-blocked on STDMOCK; will call `do clear^STDMOCK` between
  tests.
