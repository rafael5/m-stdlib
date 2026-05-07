STDMATHTST      ; Test suite for STDMATH (v0.3.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tClampWithinRangeReturnsX(.pass,.fail)
        do tClampBelowLoReturnsLo(.pass,.fail)
        do tClampAboveHiReturnsHi(.pass,.fail)
        do tClampAtBoundariesReturnsBoundary(.pass,.fail)
        do tClampSupportsFloats(.pass,.fail)
        do tClampSupportsNegatives(.pass,.fail)
        do tMinReturnsSmallest(.pass,.fail)
        do tMinHandlesNegatives(.pass,.fail)
        do tMinSingleElement(.pass,.fail)
        do tMinEmptyReturnsEmptyString(.pass,.fail)
        do tMinAcceptsStringSubscripts(.pass,.fail)
        do tMinFloats(.pass,.fail)
        do tMaxReturnsLargest(.pass,.fail)
        do tMaxHandlesNegatives(.pass,.fail)
        do tMaxSingleElement(.pass,.fail)
        do tMaxEmptyReturnsEmptyString(.pass,.fail)
        do tSumOfArrayValues(.pass,.fail)
        do tSumEmptyIsZero(.pass,.fail)
        do tSumSingleElement(.pass,.fail)
        do tSumFloats(.pass,.fail)
        do tSumNegativesNet(.pass,.fail)
        do tCountReturnsElementCount(.pass,.fail)
        do tCountEmptyIsZero(.pass,.fail)
        do tMeanOfThreeValues(.pass,.fail)
        do tMeanEmptyReturnsEmptyString(.pass,.fail)
        do tMeanSingleElementIsValue(.pass,.fail)
        do tMeanFloats(.pass,.fail)
        do tMeanNonNumericCoercesToZero(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- clamp ----
tClampWithinRangeReturnsX(pass,fail)    ;@TEST "clamp(5,1,10) is 5 (already in range)"
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(5,1,10),5,"5 within [1,10]")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(7,1,10),7,"7 within [1,10]")
        quit
        ;
tClampBelowLoReturnsLo(pass,fail)       ;@TEST "clamp below lo returns lo"
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(-3,0,10),0,"-3 clamps to 0")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(0,5,10),5,"0 below floor 5")
        quit
        ;
tClampAboveHiReturnsHi(pass,fail)       ;@TEST "clamp above hi returns hi"
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(99,0,10),10,"99 clamps to 10")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(11,0,10),10,"just-over clamps to ceiling")
        quit
        ;
tClampAtBoundariesReturnsBoundary(pass,fail)    ;@TEST "clamp at exact boundaries returns the boundary value"
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(0,0,10),0,"x=lo")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(10,0,10),10,"x=hi")
        quit
        ;
tClampSupportsFloats(pass,fail) ;@TEST "clamp works with fractional values"
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(2.5,0,5),2.5,"2.5 within [0,5]")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(-0.5,0,5),0,"-0.5 clamps to 0")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(5.0001,0,5),5,"5.0001 clamps to 5")
        quit
        ;
tClampSupportsNegatives(pass,fail)      ;@TEST "clamp respects negative ranges"
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(-7,-10,-1),-7,"within negative range")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(-15,-10,-1),-10,"clamp to negative floor")
        do eq^STDASSERT(.pass,.fail,$$clamp^STDMATH(0,-10,-1),-1,"clamp positive to negative ceiling")
        quit
        ;
        ; ---- min ----
tMinReturnsSmallest(pass,fail)  ;@TEST "min over [3,1,4,1,5,9,2,6] is 1"
        new arr
        set arr(1)=3,arr(2)=1,arr(3)=4,arr(4)=1,arr(5)=5,arr(6)=9,arr(7)=2,arr(8)=6
        do eq^STDASSERT(.pass,.fail,$$min^STDMATH(.arr),1,"min of digits-of-pi prefix")
        quit
        ;
tMinHandlesNegatives(pass,fail) ;@TEST "min picks the most-negative value"
        new arr
        set arr(1)=2,arr(2)=-7,arr(3)=0,arr(4)=-3
        do eq^STDASSERT(.pass,.fail,$$min^STDMATH(.arr),-7,"-7 is min")
        quit
        ;
tMinSingleElement(pass,fail)    ;@TEST "min of a single-element array is that element"
        new arr
        set arr(1)=42
        do eq^STDASSERT(.pass,.fail,$$min^STDMATH(.arr),42,"single value")
        quit
        ;
tMinEmptyReturnsEmptyString(pass,fail)  ;@TEST "min of an empty array returns ''"
        new arr
        do eq^STDASSERT(.pass,.fail,$$min^STDMATH(.arr),"","empty -> empty")
        quit
        ;
tMinAcceptsStringSubscripts(pass,fail)  ;@TEST "min walks $ORDER regardless of subscript shape"
        new arr
        set arr("a")=10,arr("b")=3,arr("c")=7
        do eq^STDASSERT(.pass,.fail,$$min^STDMATH(.arr),3,"string-subscripted")
        quit
        ;
tMinFloats(pass,fail)   ;@TEST "min over fractional values"
        new arr
        set arr(1)=1.5,arr(2)=0.25,arr(3)=2.75
        do eq^STDASSERT(.pass,.fail,$$min^STDMATH(.arr),0.25,"fractional min")
        quit
        ;
        ; ---- max ----
tMaxReturnsLargest(pass,fail)   ;@TEST "max over [3,1,4,1,5,9,2,6] is 9"
        new arr
        set arr(1)=3,arr(2)=1,arr(3)=4,arr(4)=1,arr(5)=5,arr(6)=9,arr(7)=2,arr(8)=6
        do eq^STDASSERT(.pass,.fail,$$max^STDMATH(.arr),9,"max of digits-of-pi prefix")
        quit
        ;
tMaxHandlesNegatives(pass,fail) ;@TEST "max picks the least-negative value"
        new arr
        set arr(1)=-2,arr(2)=-7,arr(3)=-15
        do eq^STDASSERT(.pass,.fail,$$max^STDMATH(.arr),-2,"-2 is max")
        quit
        ;
tMaxSingleElement(pass,fail)    ;@TEST "max of a single-element array is that element"
        new arr
        set arr(1)=42
        do eq^STDASSERT(.pass,.fail,$$max^STDMATH(.arr),42,"single value")
        quit
        ;
tMaxEmptyReturnsEmptyString(pass,fail)  ;@TEST "max of an empty array returns ''"
        new arr
        do eq^STDASSERT(.pass,.fail,$$max^STDMATH(.arr),"","empty -> empty")
        quit
        ;
        ; ---- sum ----
tSumOfArrayValues(pass,fail)    ;@TEST "sum over [1..5] is 15"
        new arr,i
        for i=1:1:5  set arr(i)=i
        do eq^STDASSERT(.pass,.fail,$$sum^STDMATH(.arr),15,"1+2+3+4+5=15")
        quit
        ;
tSumEmptyIsZero(pass,fail)      ;@TEST "sum of an empty array is 0"
        new arr
        do eq^STDASSERT(.pass,.fail,$$sum^STDMATH(.arr),0,"empty sum is identity")
        quit
        ;
tSumSingleElement(pass,fail)    ;@TEST "sum of a single-element array is that element"
        new arr
        set arr(1)=42
        do eq^STDASSERT(.pass,.fail,$$sum^STDMATH(.arr),42,"single value")
        quit
        ;
tSumFloats(pass,fail)   ;@TEST "sum over fractional values"
        new arr
        set arr(1)=0.1,arr(2)=0.2,arr(3)=0.3
        ; M decimal arithmetic is exact for these scales — no IEEE drift.
        do eq^STDASSERT(.pass,.fail,$$sum^STDMATH(.arr),0.6,"0.1+0.2+0.3=0.6 (decimal)")
        quit
        ;
tSumNegativesNet(pass,fail)     ;@TEST "sum nets out positive and negative values"
        new arr
        set arr(1)=10,arr(2)=-3,arr(3)=-2,arr(4)=5
        do eq^STDASSERT(.pass,.fail,$$sum^STDMATH(.arr),10,"10-3-2+5=10")
        quit
        ;
        ; ---- count ----
tCountReturnsElementCount(pass,fail)    ;@TEST "count returns the number of $ORDER-visible values"
        new arr
        set arr(1)=10,arr(2)=20,arr("k")=30
        do eq^STDASSERT(.pass,.fail,$$count^STDMATH(.arr),3,"three values")
        quit
        ;
tCountEmptyIsZero(pass,fail)    ;@TEST "count of an empty array is 0"
        new arr
        do eq^STDASSERT(.pass,.fail,$$count^STDMATH(.arr),0,"empty count")
        quit
        ;
        ; ---- mean ----
tMeanOfThreeValues(pass,fail)   ;@TEST "mean of [2,4,6] is 4"
        new arr
        set arr(1)=2,arr(2)=4,arr(3)=6
        do eq^STDASSERT(.pass,.fail,$$mean^STDMATH(.arr),4,"(2+4+6)/3=4")
        quit
        ;
tMeanEmptyReturnsEmptyString(pass,fail) ;@TEST "mean of an empty array returns ''"
        new arr
        do eq^STDASSERT(.pass,.fail,$$mean^STDMATH(.arr),"","empty -> empty (no division by 0)")
        quit
        ;
tMeanSingleElementIsValue(pass,fail)    ;@TEST "mean of a single-element array is that element"
        new arr
        set arr(1)=99
        do eq^STDASSERT(.pass,.fail,$$mean^STDMATH(.arr),99,"single value")
        quit
        ;
tMeanFloats(pass,fail)  ;@TEST "mean over fractional values"
        new arr
        set arr(1)=1.5,arr(2)=2.5
        do eq^STDASSERT(.pass,.fail,$$mean^STDMATH(.arr),2,"(1.5+2.5)/2=2")
        quit
        ;
tMeanNonNumericCoercesToZero(pass,fail) ;@TEST "non-numeric values coerce to 0 via unary +"
        ; Matches M's standard arithmetic-coercion rule: +"abc"=0, +"3.14"=3.14.
        new arr
        set arr(1)=10,arr(2)="abc",arr(3)=20
        do eq^STDASSERT(.pass,.fail,$$mean^STDMATH(.arr),10,"(10+0+20)/3=10")
        quit
