STDMOCKTST      ; Test suite for STDMOCK (v0.1.2).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; the
        ; mock-subject helpers (realFn / mockFn / otherFn) record their
        ; invocation under ^TMP("STDMOCKTST") so each test can verify
        ; which label actually ran.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tResolveReturnsTargetWhenNoMock(.pass,.fail)
        do tResolveReturnsReplacementWhenRegistered(.pass,.fail)
        do tResolveIsSingleLevel(.pass,.fail)
        do tRegisterOverwrites(.pass,.fail)
        ;
        do tInvokeCallsRealWhenNoMock(.pass,.fail)
        do tInvokeCallsMockWhenRegistered(.pass,.fail)
        do tInvokeForwardsArgsByReference(.pass,.fail)
        ;
        do tCalledStartsAtZero(.pass,.fail)
        do tCalledCountsInvocations(.pass,.fail)
        ;
        do tArgsRecordsArgsForCall(.pass,.fail)
        do tArgsRecordsAcrossMultipleCalls(.pass,.fail)
        do tArgsForUnknownTargetIsEmpty(.pass,.fail)
        do tArgsBeyondLastCallIsEmpty(.pass,.fail)
        do tArgsBeyondLastIndexIsEmpty(.pass,.fail)
        ;
        do tUnregisterRemovesOne(.pass,.fail)
        do tUnregisterAlsoClearsCounters(.pass,.fail)
        do tClearRemovesAll(.pass,.fail)
        do tClearResetsCallCount(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- mock-subject helpers + reset ----------
        ;
reset   ; Wipe STDMOCK state and the test scratchpad. Idempotent.
        kill ^STDLIB($job,"stdmock")
        kill ^TMP("STDMOCKTST")
        quit
        ;
realFn(args)    ; Subject helper #1 — records 'real' invocation + first arg.
        set ^TMP("STDMOCKTST","real")=$get(^TMP("STDMOCKTST","real"))+1
        set ^TMP("STDMOCKTST","realArg1")=$get(args(1))
        quit
        ;
mockFn(args)    ; Subject helper #2 — records 'mock' invocation + first arg.
        set ^TMP("STDMOCKTST","mock")=$get(^TMP("STDMOCKTST","mock"))+1
        set ^TMP("STDMOCKTST","mockArg1")=$get(args(1))
        quit
        ;
otherFn(args)   ; Subject helper #3 — distinct counter, used in chain test.
        set ^TMP("STDMOCKTST","other")=$get(^TMP("STDMOCKTST","other"))+1
        quit
        ;
        ; ---------- resolve / register ----------
        ;
tResolveReturnsTargetWhenNoMock(pass,fail)      ;@TEST "$$resolve passes through when no mock"
        do reset
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("realFn^STDMOCKTST"),"realFn^STDMOCKTST","passthrough")
        quit
        ;
tResolveReturnsReplacementWhenRegistered(pass,fail)     ;@TEST "$$resolve returns replacement when registered"
        do reset
        do register^STDMOCK("realFn^STDMOCKTST","mockFn^STDMOCKTST")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("realFn^STDMOCKTST"),"mockFn^STDMOCKTST","redirected")
        quit
        ;
tResolveIsSingleLevel(pass,fail)        ;@TEST "$$resolve does not chain through registered replacements"
        do reset
        do register^STDMOCK("realFn^STDMOCKTST","mockFn^STDMOCKTST")
        do register^STDMOCK("mockFn^STDMOCKTST","otherFn^STDMOCKTST")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("realFn^STDMOCKTST"),"mockFn^STDMOCKTST","first hop only")
        quit
        ;
tRegisterOverwrites(pass,fail) ;@TEST "register replaces a prior registration"
        do reset
        do register^STDMOCK("realFn^STDMOCKTST","mockFn^STDMOCKTST")
        do register^STDMOCK("realFn^STDMOCKTST","otherFn^STDMOCKTST")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("realFn^STDMOCKTST"),"otherFn^STDMOCKTST","latest wins")
        quit
        ;
        ; ---------- invoke ----------
        ;
tInvokeCallsRealWhenNoMock(pass,fail)   ;@TEST "invoke calls the real label when no mock is registered"
        do reset
        new args
        do invoke^STDMOCK("realFn^STDMOCKTST",.args)
        do eq^STDASSERT(.pass,.fail,$get(^TMP("STDMOCKTST","real")),1,"real ran once")
        do eq^STDASSERT(.pass,.fail,$get(^TMP("STDMOCKTST","mock")),"","mock did not run")
        quit
        ;
tInvokeCallsMockWhenRegistered(pass,fail)       ;@TEST "invoke calls the mock when one is registered"
        do reset
        new args
        do register^STDMOCK("realFn^STDMOCKTST","mockFn^STDMOCKTST")
        do invoke^STDMOCK("realFn^STDMOCKTST",.args)
        do eq^STDASSERT(.pass,.fail,$get(^TMP("STDMOCKTST","mock")),1,"mock ran once")
        do eq^STDASSERT(.pass,.fail,$get(^TMP("STDMOCKTST","real")),"","real did not run")
        quit
        ;
tInvokeForwardsArgsByReference(pass,fail)       ;@TEST "invoke forwards args by reference to the called label"
        do reset
        new args
        set args(1)="hello"
        do invoke^STDMOCK("realFn^STDMOCKTST",.args)
        do eq^STDASSERT(.pass,.fail,$get(^TMP("STDMOCKTST","realArg1")),"hello","arg reached helper")
        quit
        ;
        ; ---------- called counters ----------
        ;
tCalledStartsAtZero(pass,fail)  ;@TEST "$$called returns 0 for never-invoked target"
        do reset
        do eq^STDASSERT(.pass,.fail,$$called^STDMOCK("anything^anywhere"),0,"never called")
        quit
        ;
tCalledCountsInvocations(pass,fail)     ;@TEST "$$called counts each invoke per target"
        do reset
        new args
        do invoke^STDMOCK("realFn^STDMOCKTST",.args)
        do invoke^STDMOCK("realFn^STDMOCKTST",.args)
        do invoke^STDMOCK("realFn^STDMOCKTST",.args)
        do eq^STDASSERT(.pass,.fail,$$called^STDMOCK("realFn^STDMOCKTST"),3,"three calls")
        do eq^STDASSERT(.pass,.fail,$$called^STDMOCK("otherFn^STDMOCKTST"),0,"different target untouched")
        quit
        ;
        ; ---------- recorded args ----------
        ;
tArgsRecordsArgsForCall(pass,fail)      ;@TEST "$$args returns recorded args by call number"
        do reset
        new a
        set a(1)=42
        set a(2)="hello"
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("realFn^STDMOCKTST",1,1),42,"call 1 arg 1")
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("realFn^STDMOCKTST",1,2),"hello","call 1 arg 2")
        quit
        ;
tArgsRecordsAcrossMultipleCalls(pass,fail)      ;@TEST "$$args records each call independently"
        do reset
        new a
        set a(1)="first"
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        set a(1)="second"
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("realFn^STDMOCKTST",1,1),"first","call 1 arg")
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("realFn^STDMOCKTST",2,1),"second","call 2 arg")
        quit
        ;
tArgsForUnknownTargetIsEmpty(pass,fail) ;@TEST "$$args returns empty for unknown target"
        do reset
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("nothing^anywhere",1,1),"","never called")
        quit
        ;
tArgsBeyondLastCallIsEmpty(pass,fail)   ;@TEST "$$args returns empty for call number past the last"
        do reset
        new a
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("realFn^STDMOCKTST",99,1),"","beyond last call")
        quit
        ;
tArgsBeyondLastIndexIsEmpty(pass,fail)  ;@TEST "$$args returns empty for arg index past the last"
        do reset
        new a
        set a(1)="only"
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("realFn^STDMOCKTST",1,99),"","beyond last arg")
        quit
        ;
        ; ---------- unregister / clear ----------
        ;
tUnregisterRemovesOne(pass,fail)        ;@TEST "unregister removes one mock; others remain"
        do reset
        do register^STDMOCK("realFn^STDMOCKTST","mockFn^STDMOCKTST")
        do register^STDMOCK("otherFn^STDMOCKTST","mockFn^STDMOCKTST")
        do unregister^STDMOCK("realFn^STDMOCKTST")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("realFn^STDMOCKTST"),"realFn^STDMOCKTST","cleared")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("otherFn^STDMOCKTST"),"mockFn^STDMOCKTST","retained")
        quit
        ;
tUnregisterAlsoClearsCounters(pass,fail)        ;@TEST "unregister also drops call count + recorded args"
        do reset
        new a
        set a(1)=1
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do unregister^STDMOCK("realFn^STDMOCKTST")
        do eq^STDASSERT(.pass,.fail,$$called^STDMOCK("realFn^STDMOCKTST"),0,"counter dropped")
        do eq^STDASSERT(.pass,.fail,$$args^STDMOCK("realFn^STDMOCKTST",1,1),"","args dropped")
        quit
        ;
tClearRemovesAll(pass,fail)     ;@TEST "clear removes every registration"
        do reset
        do register^STDMOCK("realFn^STDMOCKTST","mockFn^STDMOCKTST")
        do register^STDMOCK("otherFn^STDMOCKTST","mockFn^STDMOCKTST")
        do clear^STDMOCK
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("realFn^STDMOCKTST"),"realFn^STDMOCKTST","real cleared")
        do eq^STDASSERT(.pass,.fail,$$resolve^STDMOCK("otherFn^STDMOCKTST"),"otherFn^STDMOCKTST","other cleared")
        quit
        ;
tClearResetsCallCount(pass,fail)        ;@TEST "clear resets every call counter"
        do reset
        new a
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do invoke^STDMOCK("realFn^STDMOCKTST",.a)
        do clear^STDMOCK
        do eq^STDASSERT(.pass,.fail,$$called^STDMOCK("realFn^STDMOCKTST"),0,"counter zeroed")
        quit
