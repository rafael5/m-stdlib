STDPROFTST      ; Test suite for STDPROF (v0.2.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tNewEmptyProfiler(.pass,.fail)
        do tStartStopOneCycle(.pass,.fail)
        do tStartStopMultipleCycles(.pass,.fail)
        do tCountTracksCycles(.pass,.fail)
        do tElapsedIncreasesWithHang(.pass,.fail)
        do tMeanIsTotalOverCount(.pass,.fail)
        do tMinTracksFastestSample(.pass,.fail)
        do tMaxTracksSlowestSample(.pass,.fail)
        do tPercentileMedian(.pass,.fail)
        do tPercentile95(.pass,.fail)
        do tPercentileAt100ReturnsMax(.pass,.fail)
        do tPercentileAt0ReturnsMin(.pass,.fail)
        do tTagsListsTrackedTags(.pass,.fail)
        do tTagsEmptyForNewProfiler(.pass,.fail)
        do tClearResetsAggregates(.pass,.fail)
        do tStopWithoutStartIsNoOp(.pass,.fail)
        do tIndependentTagsTracked(.pass,.fail)
        do tCountOfMissingTagIsZero(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- new / count ----
tNewEmptyProfiler(pass,fail)    ;@TEST "new() yields a profiler with zero tags"
        new prof
        do new^STDPROF(.prof)
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"any"),0,"count(any)=0")
        quit
        ;
tCountOfMissingTagIsZero(pass,fail)     ;@TEST "count() of an untracked tag returns 0"
        new prof
        do new^STDPROF(.prof)
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"never-started"),0,"untracked tag")
        quit
        ;
        ; ---- start / stop ----
tStartStopOneCycle(pass,fail)   ;@TEST "start then stop produces one complete cycle"
        new prof
        do new^STDPROF(.prof)
        do start^STDPROF(.prof,"work")
        do stop^STDPROF(.prof,"work")
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"work"),1,"count=1")
        quit
        ;
tStartStopMultipleCycles(pass,fail)     ;@TEST "five start/stop cycles produce count=5"
        new prof,i
        do new^STDPROF(.prof)
        for i=1:1:5 do start^STDPROF(.prof,"loop") do stop^STDPROF(.prof,"loop")
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"loop"),5,"count=5")
        quit
        ;
tCountTracksCycles(pass,fail)   ;@TEST "count() reflects number of completed start/stop pairs"
        new prof
        do new^STDPROF(.prof)
        do start^STDPROF(.prof,"a") do stop^STDPROF(.prof,"a")
        do start^STDPROF(.prof,"a") do stop^STDPROF(.prof,"a")
        do start^STDPROF(.prof,"a") do stop^STDPROF(.prof,"a")
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"a"),3,"count=3")
        quit
        ;
        ; ---- elapsed / total / mean ----
tElapsedIncreasesWithHang(pass,fail)    ;@TEST "a hang(1) cycle produces total >= 500000 us"
        new prof,total
        do new^STDPROF(.prof)
        do start^STDPROF(.prof,"slow")
        hang 1
        do stop^STDPROF(.prof,"slow")
        set total=$$total^STDPROF(.prof,"slow")
        do true^STDASSERT(.pass,.fail,total'<500000,"total >= 500ms in microseconds: "_total)
        do true^STDASSERT(.pass,.fail,total<5000000,"total < 5s (sanity bound): "_total)
        quit
        ;
tMeanIsTotalOverCount(pass,fail)        ;@TEST "mean equals total\\count (integer floor)"
        new prof,i,total,count,mean
        do new^STDPROF(.prof)
        for i=1:1:3 do start^STDPROF(.prof,"x") do stop^STDPROF(.prof,"x")
        set total=$$total^STDPROF(.prof,"x")
        set count=$$count^STDPROF(.prof,"x")
        set mean=$$mean^STDPROF(.prof,"x")
        do eq^STDASSERT(.pass,.fail,mean,total\count,"mean = total\\count")
        quit
        ;
        ; ---- min / max ----
tMinTracksFastestSample(pass,fail)      ;@TEST "min() reflects the fastest sample seen"
        new prof,min
        do new^STDPROF(.prof)
        ; one fast sample (no hang)
        do start^STDPROF(.prof,"mix") do stop^STDPROF(.prof,"mix")
        ; one slow sample
        do start^STDPROF(.prof,"mix") hang 1 do stop^STDPROF(.prof,"mix")
        set min=$$min^STDPROF(.prof,"mix")
        do true^STDASSERT(.pass,.fail,min<500000,"min < 500ms: "_min)
        quit
        ;
tMaxTracksSlowestSample(pass,fail)      ;@TEST "max() reflects the slowest sample seen"
        new prof,max
        do new^STDPROF(.prof)
        do start^STDPROF(.prof,"mix") do stop^STDPROF(.prof,"mix")
        do start^STDPROF(.prof,"mix") hang 1 do stop^STDPROF(.prof,"mix")
        set max=$$max^STDPROF(.prof,"mix")
        do true^STDASSERT(.pass,.fail,max'<500000,"max >= 500ms: "_max)
        quit
        ;
        ; ---- percentile ----
tPercentileMedian(pass,fail)    ;@TEST "p50 is the median of three known samples"
        ; We can't stub the clock, but we CAN stub samples directly via
        ; STDPROF's private API for testing — just record() three values.
        ; If record() is internal-only, the test exercises start/stop with
        ; varied hang times; we use the latter for the public-API contract.
        new prof,i,p50
        do new^STDPROF(.prof)
        ; three cycles, mixing fast and slow — median should be in between
        do start^STDPROF(.prof,"p") do stop^STDPROF(.prof,"p")
        do start^STDPROF(.prof,"p") hang 0.1 do stop^STDPROF(.prof,"p")
        do start^STDPROF(.prof,"p") hang 1 do stop^STDPROF(.prof,"p")
        set p50=$$percentile^STDPROF(.prof,"p",50)
        ; The median should be the middle sample, ~50-150ms; verify it lies
        ; strictly between the fastest (p0) and the slowest (p100).
        do true^STDASSERT(.pass,.fail,p50>$$min^STDPROF(.prof,"p"),"p50 > min")
        do true^STDASSERT(.pass,.fail,p50<$$max^STDPROF(.prof,"p"),"p50 < max")
        quit
        ;
tPercentile95(pass,fail)        ;@TEST "p95 is at least p50 for a multi-sample distribution"
        new prof,i,p50,p95
        do new^STDPROF(.prof)
        for i=1:1:5 do start^STDPROF(.prof,"r") do stop^STDPROF(.prof,"r")
        do start^STDPROF(.prof,"r") hang 1 do stop^STDPROF(.prof,"r")
        set p50=$$percentile^STDPROF(.prof,"r",50)
        set p95=$$percentile^STDPROF(.prof,"r",95)
        do true^STDASSERT(.pass,.fail,p95'<p50,"p95 >= p50")
        quit
        ;
tPercentileAt100ReturnsMax(pass,fail)  ;@TEST "p100 equals max"
        new prof,i
        do new^STDPROF(.prof)
        for i=1:1:4 do start^STDPROF(.prof,"q") do stop^STDPROF(.prof,"q")
        do eq^STDASSERT(.pass,.fail,$$percentile^STDPROF(.prof,"q",100),$$max^STDPROF(.prof,"q"),"p100=max")
        quit
        ;
tPercentileAt0ReturnsMin(pass,fail)     ;@TEST "p0 equals min"
        new prof,i
        do new^STDPROF(.prof)
        for i=1:1:4 do start^STDPROF(.prof,"q") do stop^STDPROF(.prof,"q")
        do eq^STDASSERT(.pass,.fail,$$percentile^STDPROF(.prof,"q",0),$$min^STDPROF(.prof,"q"),"p0=min")
        quit
        ;
        ; ---- tags / clear ----
tTagsListsTrackedTags(pass,fail)        ;@TEST "tags() returns every tag that has at least one cycle"
        new prof,out,n
        do new^STDPROF(.prof)
        do start^STDPROF(.prof,"alpha") do stop^STDPROF(.prof,"alpha")
        do start^STDPROF(.prof,"beta") do stop^STDPROF(.prof,"beta")
        do start^STDPROF(.prof,"gamma") do stop^STDPROF(.prof,"gamma")
        set n=$$tags^STDPROF(.prof,.out)
        do eq^STDASSERT(.pass,.fail,n,3,"three tags")
        ; tags are returned in $ORDER (alphabetical for plain strings)
        do eq^STDASSERT(.pass,.fail,$get(out(1)),"alpha","alpha first")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),"beta","beta second")
        do eq^STDASSERT(.pass,.fail,$get(out(3)),"gamma","gamma third")
        quit
        ;
tTagsEmptyForNewProfiler(pass,fail)     ;@TEST "tags() returns 0 for a fresh profiler"
        new prof,out,n
        do new^STDPROF(.prof)
        set n=$$tags^STDPROF(.prof,.out)
        do eq^STDASSERT(.pass,.fail,n,0,"no tags")
        quit
        ;
tClearResetsAggregates(pass,fail)       ;@TEST "clear() drops every tag's data"
        new prof,i,out
        do new^STDPROF(.prof)
        for i=1:1:3 do start^STDPROF(.prof,"x") do stop^STDPROF(.prof,"x")
        do clear^STDPROF(.prof)
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"x"),0,"count=0 after clear")
        do eq^STDASSERT(.pass,.fail,$$tags^STDPROF(.prof,.out),0,"no tags after clear")
        quit
        ;
        ; ---- error paths ----
tStopWithoutStartIsNoOp(pass,fail)      ;@TEST "stop() without a matching start is a no-op (count stays 0)"
        new prof
        do new^STDPROF(.prof)
        do stop^STDPROF(.prof,"never-started")
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"never-started"),0,"count=0")
        quit
        ;
        ; ---- multi-tag isolation ----
tIndependentTagsTracked(pass,fail)      ;@TEST "two tags are tracked independently"
        new prof,i
        do new^STDPROF(.prof)
        for i=1:1:2 do start^STDPROF(.prof,"fast") do stop^STDPROF(.prof,"fast")
        for i=1:1:5 do start^STDPROF(.prof,"slow") do stop^STDPROF(.prof,"slow")
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"fast"),2,"fast count=2")
        do eq^STDASSERT(.pass,.fail,$$count^STDPROF(.prof,"slow"),5,"slow count=5")
        quit
