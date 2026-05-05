STDFIX  ; m-stdlib — fixture lifecycle and per-test isolation.
        ;
        ; YDB nested-transaction-based isolation. YDB enforces TPQUIT:
        ; ``tstart`` and the matching ``trollback`` MUST live in the same
        ; routine frame. STDFIX therefore exposes only one-shot wrappers —
        ; ``with`` and ``invoke`` open AND close their scope before
        ; returning. There is no standalone setup() / teardown() pair.
        ;
        ; Public labels:
        ;   with(tag,code)         ; XECUTEs code inside an auto-managed
        ;                            transaction scope; rolls back on exit
        ;                            and re-raises any error code raised
        ;                            inside ``code``.
        ;   $$active()             ; → 1 if any nested transaction is open
        ;                            (any TSTART, not just STDFIX-owned).
        ;   register(tag,setupCode,teardownCode)  ; declarative fixture
        ;   invoke(tag,code)       ; fixture-aware variant of with(): runs
        ;                            registered setup hook, then code, then
        ;                            registered teardown hook — all inside
        ;                            one rolled-back scope.
        ;   cleanup                ; idempotent rollback of any leaked
        ;                            transaction scope; safe at $tlevel=0.
        ;
        ; State layout (under ^STDLIB($job,"FIX",...)):
        ;   STACK,$tlevel = tag    ; one entry per open scope, set inside
        ;                            the transaction so TROLLBACK erases it.
        ;   REG,tag,"SETUP"        ; registered setup code
        ;   REG,tag,"TEARDOWN"     ; registered teardown code
        ;
        ; ``trollback $tlevel-1`` rolls back exactly the level this frame
        ; opened, so nested with()/invoke() pairs roll back inner-only —
        ; bare ``trollback`` (which targets level 0) would unbalance every
        ; outer transaction.
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDFIX-EMPTY-TAG,
        ;   ,U-STDFIX-UNREGISTERED-TAG,
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
with(tag,code)  ; XECUTE code inside an auto-managed transaction scope.
        ; doc: Opens a YDB transaction, sets the scope tag in the stack,
        ; doc: XECUTEs code, then ``trollback $tlevel-1`` to roll back
        ; doc: exactly this scope. If code raises, the trap rolls back the
        ; doc: scope and re-raises so the caller can observe the original
        ; doc: $ECODE.
        ; doc: Example: do with^STDFIX("scope","do migrate^DDL")
        new $etrap,saved,target
        if tag="" set $ecode=",U-STDFIX-EMPTY-TAG," quit
        set saved="",target=$tlevel
        set $etrap="set saved=$ecode set $ecode="""" if $tlevel>target trollback target  set $ecode=saved quit"
        tstart
        set ^STDLIB($job,"FIX","STACK",$tlevel)=tag
        ; m-lint: disable-next-line=M-MOD-036
        xecute code  ; XECUTE-of-arg is the documented purpose of with().
        ; m-lint: disable-next-line=M-MOD-009
        trollback target  ; matches the tstart above; preserves outer scopes.
        quit
        ;
active()        ; Predicate — is any nested transaction currently open?
        ; doc: Returns 1 if $tlevel > 0, 0 otherwise. STDFIX-managed scopes
        ; doc: also appear in ^STDLIB($job,"FIX","STACK",N) for callers
        ; doc: that need to distinguish their own from foreign transactions.
        ; doc: Example: write $$active^STDFIX()  ; 0
        quit $select($tlevel>0:1,1:0)
        ;
register(tag,setupCode,teardownCode)    ; Declare a reusable setup/teardown pair.
        ; doc: Persists the code strings under ^STDLIB($job,"FIX","REG",tag,...)
        ; doc: so later invoke(tag,...) calls can run them. Empty tags raise
        ; doc: U-STDFIX-EMPTY-TAG.
        ; doc: Example: do register^STDFIX("db","do reset^X","do drop^X")
        if tag="" set $ecode=",U-STDFIX-EMPTY-TAG," quit
        set ^STDLIB($job,"FIX","REG",tag,"SETUP")=setupCode
        set ^STDLIB($job,"FIX","REG",tag,"TEARDOWN")=teardownCode
        quit
        ;
invoke(tag,code)        ; Run code with registered hooks wrapping it.
        ; doc: Looks up registered setup/teardown for tag, then runs:
        ; doc: setup hook (if any), code, teardown hook (if any) — all
        ; doc: inside one transaction that rolls back on exit. Raises
        ; doc: U-STDFIX-UNREGISTERED-TAG if tag was never register()ed.
        ; doc: Example: do invoke^STDFIX("dbReset","do tCheck^MYTST")
        new $etrap,saved,target,setup,teardown
        if '$data(^STDLIB($job,"FIX","REG",tag)) set $ecode=",U-STDFIX-UNREGISTERED-TAG," quit
        set saved="",target=$tlevel
        set $etrap="set saved=$ecode set $ecode="""" if $tlevel>target trollback target  set $ecode=saved quit"
        set setup=$get(^STDLIB($job,"FIX","REG",tag,"SETUP"))
        set teardown=$get(^STDLIB($job,"FIX","REG",tag,"TEARDOWN"))
        tstart
        set ^STDLIB($job,"FIX","STACK",$tlevel)=tag
        ; m-lint: disable-next-line=M-MOD-036
        if setup'="" xecute setup
        ; m-lint: disable-next-line=M-MOD-036
        xecute code
        ; m-lint: disable-next-line=M-MOD-036
        if teardown'="" xecute teardown
        ; m-lint: disable-next-line=M-MOD-009
        trollback target  ; matches the tstart above; preserves outer scopes.
        quit
        ;
cleanup ; Best-effort rollback of any leaked transaction scope.
        ; doc: TROLLBACKs all the way to $tlevel=0 if any transaction is
        ; doc: open; safe to call at $tlevel=0 (no-op). Useful as a
        ; doc: defensive between-tests reset in runner code. Note: this
        ; doc: rolls back NON-STDFIX transactions too — call only at a
        ; doc: top-level frame that owns no enclosing tstart.
        ; doc: Example: do cleanup^STDFIX
        ; m-lint: disable-next-line=M-MOD-009
        if $tlevel>0 trollback
        quit
        ;
