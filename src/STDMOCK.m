STDMOCK ; m-stdlib — opt-in test-time call interception (mock registry).
        ;
        ; Three procedure-form labels:
        ;   register^STDMOCK(target,replacement)  — record a redirect
        ;   unregister^STDMOCK(target)            — remove one redirect
        ;   clear^STDMOCK                         — wipe every registration
        ;
        ; Three extrinsics:
        ;   $$resolve^STDMOCK(target)             — replacement, or target
        ;   $$called^STDMOCK(target)              — call count since clear
        ;   $$args^STDMOCK(target,n,i)            — arg i of call n
        ;
        ; And one procedure that exercises the redirect + records the call:
        ;   invoke^STDMOCK(target,.args)          — record + call resolve(target)
        ;
        ; Mechanism — opt-in at the call site. Production code that wants
        ; to be mockable calls invoke^STDMOCK("LBL^ROU",.args) instead of
        ; do ^LBL^ROU(.args), or uses do @$$resolve^STDMOCK("LBL^ROU")(.args)
        ; for the same effect without recording. Tests register a stub and
        ; the indirection picks it up.
        ;
        ; Storage — process-scoped (no cross-process leakage):
        ;   ^STDLIB($job,"stdmock","reg",target)        = replacement
        ;   ^STDLIB($job,"stdmock","cnt",target)        = call count
        ;   ^STDLIB($job,"stdmock","arg",target,n,i)    = arg i of call n
        ;
        ; Note on transactions: the registry lives in a transactional
        ; global, so a TROLLBACK reverts mock registrations. v0.1.2 does
        ; not provide rollback-immune mocks. The m-cli runner clears the
        ; registry between tests so cross-test leakage is also a non-issue.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
register(target,replacement)    ; Record a target -> replacement redirect.
        ; doc: Procedure-form. Overwrites any prior registration for target.
        ; doc: Example: do register^STDMOCK("EN^DIE","stub^DIETST")
        set ^STDLIB($job,"stdmock","reg",target)=replacement
        quit
        ;
unregister(target)      ; Remove one redirect (idempotent).
        ; doc: Procedure-form. Also drops the call count and recorded args
        ; doc: for that target so a subsequent re-register starts fresh.
        kill ^STDLIB($job,"stdmock","reg",target)
        kill ^STDLIB($job,"stdmock","cnt",target)
        kill ^STDLIB($job,"stdmock","arg",target)
        quit
        ;
clear   ; Remove every redirect, counter, and recorded args list.
        ; doc: Procedure-form. Idempotent. The m-cli test runner calls
        ; doc: this between tests so registrations don't leak across cases.
        kill ^STDLIB($job,"stdmock")
        quit
        ;
resolve(target) ; Return the replacement if registered, else target itself.
        ; doc: Single-level lookup; chains are NOT followed. If target is
        ; doc: registered to A and A is registered to B, $$resolve(target)
        ; doc: returns A, not B.
        ; doc: Example: write $$resolve^STDMOCK("EN^DIE")  ; "stub^DIETST"
        quit $get(^STDLIB($job,"stdmock","reg",target),target)
        ;
invoke(target,args)     ; Record this call + invoke resolve(target).
        ; doc: Procedure-form. .args is passed by reference to the resolved
        ; doc: target. Records the call (count + arg copy) before calling.
        ; doc: Example: new a  set a(1)=42  do invoke^STDMOCK("LBL^ROU",.a)
        new resolved,callN,key
        set resolved=$$resolve(target)
        set callN=$increment(^STDLIB($job,"stdmock","cnt",target))
        set key=""
        for  set key=$order(args(key)) quit:key=""  do
        . set ^STDLIB($job,"stdmock","arg",target,callN,key)=args(key)
        ; m-lint: disable-next-line=M-MOD-036
        do @resolved@(.args)  ; indirection-of-registered-target is the point of invoke().
        quit
        ;
called(target)  ; Number of invocations for target since clear / unregister.
        ; doc: Returns 0 for never-invoked targets.
        quit $get(^STDLIB($job,"stdmock","cnt",target),0)
        ;
args(target,n,i)        ; Return arg i of call n for target; "" if absent.
        ; doc: 1-indexed for both call number and argument position.
        ; doc: Example: $$args^STDMOCK("LBL",1,2) — second arg of first call.
        quit $get(^STDLIB($job,"stdmock","arg",target,n,i),"")
