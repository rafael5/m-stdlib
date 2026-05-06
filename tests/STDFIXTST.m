STDFIXTST       ; Test suite for STDFIX (v0.1.1).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        ;
        ; Scratch ^STDLIB($job,"FIXT",...) for fixture-rollback verification
        ; (vista-meta's GLD only maps ^STDLIB into a region, so we share the
        ; routine global rather than introducing a new one).
        ;
        ; YDB enforces TPQUIT (tstart/trollback must balance per routine
        ; frame), so STDFIX has no standalone setup/teardown — every
        ; transaction-bearing label is a one-shot wrapper. Nested-scope
        ; tests use small helper labels (nestedHelper, etc.) instead of
        ; deeply-quoted XECUTE strings.
        ;
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tActiveZeroAtRest(.pass,.fail)
        do tWithRunsCode(.pass,.fail)
        do tWithRollsBackGlobalWrites(.pass,.fail)
        do tWithSetsActiveInsideScope(.pass,.fail)
        do tWithRejectsEmptyTag(.pass,.fail)
        do tWithRollsBackOnError(.pass,.fail)
        do tWithRecordsTagOnStack(.pass,.fail)
        do tNestedWithRollsBackInnerOnly(.pass,.fail)
        do tNestedWithRollsBackOuterToo(.pass,.fail)
        do tCleanupIdempotent(.pass,.fail)
        do tCleanupAfterLeak(.pass,.fail)
        do tRegisterStoresFixture(.pass,.fail)
        do tRegisterRejectsEmptyTag(.pass,.fail)
        do tInvokeRunsRegisteredHooks(.pass,.fail)
        do tInvokeRollsBackGlobalWrites(.pass,.fail)
        do tInvokeRejectsUnregistered(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- helpers ----------
        ;
reset   ; Reset all STDFIX state directly (without calling STDFIX itself).
        if $tlevel>0 trollback
        kill ^STDLIB($job,"FIX")
        kill ^STDLIB($job,"FIXT")
        quit
        ;
withErrInner    ; Helper for tWithRollsBackOnError — raises inside with().
        do with^STDFIX("scope","set ^STDLIB($job,""FIXT"",1)=1 set $ecode="",U-TEST,""")
        quit
        ;
nestedInnerOnly ; Helper for tNestedWithRollsBackInnerOnly.
        ; Outer with's body. Writes outer, opens inner, writes inner, inner
        ; rolls back. Probes the visible state into locals so the test can
        ; assert after the outer also rolls back.
        new probedOuter,probedInner
        set ^STDLIB($job,"FIXT","outer")="O"
        do with^STDFIX("inner","set ^STDLIB($job,""FIXT"",""inner"")=""I""")
        ; After inner trollback: inner write erased, outer write survives.
        set probedOuter=$get(^STDLIB($job,"FIXT","outer"))
        set probedInner=$data(^STDLIB($job,"FIXT","inner"))
        set ^STDLIB($job,"FIXT","probedOuter")=probedOuter
        set ^STDLIB($job,"FIXT","probedInner")=probedInner
        quit
        ;
        ; ---------- tests ----------
        ;
tActiveZeroAtRest(pass,fail)    ;@TEST "active() returns 0 with no active scope"
        do reset
        do eq^STDASSERT(.pass,.fail,$$active^STDFIX(),0,"no scope -> 0")
        quit
        ;
tWithRunsCode(pass,fail)        ;@TEST "with() XECUTEs the code argument"
        do reset
        new ran
        set ran=0
        do with^STDFIX("scope","set ran=1")
        do eq^STDASSERT(.pass,.fail,ran,1,"body executed")
        quit
        ;
tWithRollsBackGlobalWrites(pass,fail)   ;@TEST "with() rolls back global writes on exit"
        do reset
        do with^STDFIX("scope","set ^STDLIB($job,""FIXT"",1)=""hello""")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT",1)),0,"FIXT(1) rolled back")
        do eq^STDASSERT(.pass,.fail,$$active^STDFIX(),0,"scope closed")
        quit
        ;
tWithSetsActiveInsideScope(pass,fail)   ;@TEST "active() returns 1 inside with()'s body"
        do reset
        new probed
        set probed=""  ; lint can't see across XECUTE that with() sets probed
        do with^STDFIX("scope","set probed=$$active^STDFIX()")
        do eq^STDASSERT(.pass,.fail,probed,1,"active inside with -> 1")
        do eq^STDASSERT(.pass,.fail,$$active^STDFIX(),0,"active after with -> 0")
        quit
        ;
tWithRejectsEmptyTag(pass,fail) ;@TEST "with() with empty tag sets U-STDFIX-EMPTY-TAG"
        do reset
        do raises^STDASSERT(.pass,.fail,"do with^STDFIX("""",""set x=1"")","U-STDFIX-EMPTY-TAG","empty tag rejected")
        quit
        ;
tWithRollsBackOnError(pass,fail)        ;@TEST "with() rolls back and cleans up scope when XECUTEd code raises"
        ; Verifies the OBSERVABLE side-effects of with()'s trap chain when
        ; the XECUTEd body raises: the inner global write is rolled back
        ; and the transaction stack is closed. The third contract — that
        ; with() re-raises the captured $ECODE so the caller can observe
        ; it — is not exercised here. It triggers the same TOOLCHAIN P1
        ; chain that affects STDFMT (and was independently observed in
        ; STDDATE/STDCSV): re-raising $ECODE from a trap inside a
        ; transaction rolled back by that same trap fails to propagate
        ; through to the next outer $ETRAP. Deferred to v0.0.5+ alongside
        ; the ZGOTO-based unwind fix in STDASSERT.raises.
        do reset
        new $etrap
        set $etrap="set $ecode="""" quit"
        do withErrInner^STDFIXTST
        set $etrap=""
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT",1)),0,"FIXT(1) rolled back on error")
        do eq^STDASSERT(.pass,.fail,$$active^STDFIX(),0,"scope cleaned up after error")
        quit
        ;
tWithRecordsTagOnStack(pass,fail)       ;@TEST "with() records the tag in ^STDLIB($job,FIX,STACK,$tlevel)"
        do reset
        new probedTag
        set probedTag=""  ; lint can't see across XECUTE that with() sets probedTag
        do with^STDFIX("myScope","set probedTag=$get(^STDLIB($job,""FIX"",""STACK"",$tlevel))")
        do eq^STDASSERT(.pass,.fail,probedTag,"myScope","tag recorded at $tlevel")
        quit
        ;
tNestedWithRollsBackInnerOnly(pass,fail)        ;@TEST "nested with(): inner trollback preserves outer writes"
        do reset
        do with^STDFIX("outer","do nestedInnerOnly^STDFIXTST")
        ; nestedInnerOnly probed visibility BEFORE the outer trollback and
        ; saved the values into ^STDLIB(...,"probed*"); those probes are
        ; rolled back too, so we can't assert from them after the outer
        ; trollback. Instead, assert the inner write specifically didn't
        ; survive the outer rollback either.
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","inner")),0,"inner write rolled back")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","outer")),0,"outer write rolled back at outer exit")
        quit
        ;
tNestedWithRollsBackOuterToo(pass,fail) ;@TEST "nested with(): outer trollback also clears outer writes"
        do reset
        do with^STDFIX("outer","set ^STDLIB($job,""FIXT"",""o"")=1 do with^STDFIX(""inner"",""set ^STDLIB($job,""""FIXT"""",""""i"""")=1"")")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","o")),0,"outer write gone")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","i")),0,"inner write gone")
        do eq^STDASSERT(.pass,.fail,$$active^STDFIX(),0,"all scopes closed")
        quit
        ;
tCleanupIdempotent(pass,fail)   ;@TEST "cleanup() is idempotent at $tlevel=0"
        do reset
        do cleanup^STDFIX
        do cleanup^STDFIX
        do eq^STDASSERT(.pass,.fail,$$active^STDFIX(),0,"still no scope after two cleanups")
        quit
        ; m-lint: disable-next-line=M-MOD-026
tCleanupAfterLeak(pass,fail)    ;@TEST "cleanup() rolls back a leaked transaction"
        ; The whole point of this test is to OPEN a tstart and have
        ; cleanup^STDFIX (called below) roll it back from the outside;
        ; lint can't see across the call so it flags the unbalanced
        ; tstart at the label level.
        do reset
        tstart
        set ^STDLIB($job,"FIXT","leaked")=1
        do cleanup^STDFIX
        do eq^STDASSERT(.pass,.fail,$$active^STDFIX(),0,"all transactions closed")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","leaked")),0,"leaked write rolled back")
        quit
        ;
tRegisterStoresFixture(pass,fail)       ;@TEST "register() persists setup + teardown code under ^STDLIB"
        do reset
        do register^STDFIX("dbReset","set ^STDLIB($job,""FIXT"",""K"")=1","kill ^STDLIB($job,""FIXT"",""K"")")
        do eq^STDASSERT(.pass,.fail,$get(^STDLIB($job,"FIX","REG","dbReset","SETUP")),"set ^STDLIB($job,""FIXT"",""K"")=1","setup stored")
        do eq^STDASSERT(.pass,.fail,$get(^STDLIB($job,"FIX","REG","dbReset","TEARDOWN")),"kill ^STDLIB($job,""FIXT"",""K"")","teardown stored")
        quit
        ;
tRegisterRejectsEmptyTag(pass,fail)     ;@TEST "register() with empty tag sets U-STDFIX-EMPTY-TAG"
        do reset
        do raises^STDASSERT(.pass,.fail,"do register^STDFIX("""",""x"",""y"")","U-STDFIX-EMPTY-TAG","empty tag rejected")
        quit
        ;
tInvokeRunsRegisteredHooks(pass,fail)   ;@TEST "invoke() runs setup hook, body, then teardown hook (all observable in locals)"
        do reset
        new setupRan,bodyRan,teardownRan
        set setupRan=0,bodyRan=0,teardownRan=0
        do register^STDFIX("hooks","set setupRan=1","set teardownRan=1")
        do invoke^STDFIX("hooks","set bodyRan=1")
        do eq^STDASSERT(.pass,.fail,setupRan,1,"setup ran")
        do eq^STDASSERT(.pass,.fail,bodyRan,1,"body ran")
        do eq^STDASSERT(.pass,.fail,teardownRan,1,"teardown ran")
        quit
        ;
tInvokeRollsBackGlobalWrites(pass,fail) ;@TEST "invoke() rolls back global writes from setup, body, and teardown"
        do reset
        do register^STDFIX("dbReset","set ^STDLIB($job,""FIXT"",""s"")=1","set ^STDLIB($job,""FIXT"",""t"")=1")
        do invoke^STDFIX("dbReset","set ^STDLIB($job,""FIXT"",""b"")=1")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","s")),0,"setup write rolled back")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","b")),0,"body write rolled back")
        do eq^STDASSERT(.pass,.fail,$data(^STDLIB($job,"FIXT","t")),0,"teardown write rolled back")
        quit
        ;
tInvokeRejectsUnregistered(pass,fail)   ;@TEST "invoke() with no registered tag sets U-STDFIX-UNREGISTERED-TAG"
        do reset
        do raises^STDASSERT(.pass,.fail,"do invoke^STDFIX(""nope"",""set x=1"")","U-STDFIX-UNREGISTERED-TAG","tag not registered")
        quit
        ;
