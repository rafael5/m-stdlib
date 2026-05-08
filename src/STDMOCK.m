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
        ; doc: @param target       string  M call-site to intercept (e.g. "EN^DIE")
        ; doc: @param replacement  string  M call-site to invoke instead
        ; doc: @example            do register^STDMOCK("EN^DIE","stub^DIETST")
        ; doc: @since              v0.1.2
        ; doc: @stable             stable
        ; doc: @see                do unregister^STDMOCK, $$resolve^STDMOCK, do invoke^STDMOCK
        ; doc: Overwrites any prior registration for target.
        set ^STDLIB($job,"stdmock","reg",target)=replacement
        quit
        ;
unregister(target)      ; Remove one redirect (idempotent).
        ; doc: @param target  string  M call-site previously register()ed
        ; doc: @example       do unregister^STDMOCK("EN^DIE")
        ; doc: @since         v0.1.2
        ; doc: @stable        stable
        ; doc: @see           do register^STDMOCK, do clear^STDMOCK
        ; doc: Drops the call count and recorded args for that target so a
        ; doc: subsequent re-register starts fresh.
        kill ^STDLIB($job,"stdmock","reg",target)
        kill ^STDLIB($job,"stdmock","cnt",target)
        kill ^STDLIB($job,"stdmock","arg",target)
        quit
        ;
clear   ; Remove every redirect, counter, and recorded args list.
        ; doc: @example       do clear^STDMOCK
        ; doc: @since         v0.1.2
        ; doc: @stable        stable
        ; doc: @see           do unregister^STDMOCK
        ; doc: Idempotent. The m-cli test runner calls this between tests
        ; doc: so registrations don't leak across cases.
        kill ^STDLIB($job,"stdmock")
        quit
        ;
resolve(target) ; Return the replacement if registered, else target itself.
        ; doc: @param target  string  M call-site
        ; doc: @returns       string  registered replacement; target itself if no registration
        ; doc: @example       write $$resolve^STDMOCK("EN^DIE")  ; "stub^DIETST"
        ; doc: @since         v0.1.2
        ; doc: @stable        stable
        ; doc: @see           do register^STDMOCK, do invoke^STDMOCK
        ; doc: Single-level lookup; chains are NOT followed.
        quit $get(^STDLIB($job,"stdmock","reg",target),target)
        ;
invoke(target,args)     ; Record this call + invoke resolve(target).
        ; doc: @param target  string  M call-site
        ; doc: @param args    array   by-ref local; passed verbatim to the resolved target
        ; doc: @example       new a  set a(1)=42  do invoke^STDMOCK("LBL^ROU",.a)
        ; doc: @since         v0.1.2
        ; doc: @stable        stable
        ; doc: @see           $$resolve^STDMOCK, $$called^STDMOCK, $$args^STDMOCK
        ; doc: Records the call (count + arg copy) before calling.
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
        ; doc: @param target  string  M call-site
        ; doc: @returns       int     invocation count; 0 if never invoked
        ; doc: @example       write $$called^STDMOCK("EN^DIE")  ; 3
        ; doc: @since         v0.1.2
        ; doc: @stable        stable
        ; doc: @see           do invoke^STDMOCK, $$args^STDMOCK
        quit $get(^STDLIB($job,"stdmock","cnt",target),0)
        ;
args(target,n,i)        ; Return arg i of call n for target; "" if absent.
        ; doc: @param target  string  M call-site
        ; doc: @param n       int     1-based call number
        ; doc: @param i       int     1-based argument position
        ; doc: @returns       string  recorded arg value; "" if absent
        ; doc: @example       $$args^STDMOCK("LBL",1,2) — second arg of first call.
        ; doc: @since         v0.1.2
        ; doc: @stable        stable
        ; doc: @see           $$called^STDMOCK, do invoke^STDMOCK
        quit $get(^STDLIB($job,"stdmock","arg",target,n,i),"")
