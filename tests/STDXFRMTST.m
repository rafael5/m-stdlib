STDXFRMTST      ; Test suite for STDXFRM (v0.3.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tMapDoublesEachValue(.pass,.fail)
        do tMapPreservesSubscripts(.pass,.fail)
        do tMapEmptyInputProducesEmptyOutput(.pass,.fail)
        do tMapStringExpression(.pass,.fail)
        do tMapHasAccessToKey(.pass,.fail)
        do tMapStringSubscriptsRespected(.pass,.fail)
        do tMapClearsOutputFirst(.pass,.fail)
        do tFilterKeepsTruthy(.pass,.fail)
        do tFilterDropsFalsy(.pass,.fail)
        do tFilterEmptyInputProducesEmptyOutput(.pass,.fail)
        do tFilterPredicateOnKey(.pass,.fail)
        do tFilterPreservesValuesNotJustKeys(.pass,.fail)
        do tFilterClearsOutputFirst(.pass,.fail)
        do tReduceSumsValues(.pass,.fail)
        do tReduceWithEmptyInputReturnsInit(.pass,.fail)
        do tReduceConcatenatesStrings(.pass,.fail)
        do tReduceProductOfValues(.pass,.fail)
        do tReduceCountsViaIncrement(.pass,.fail)
        do tReduceUsesKey(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- map ----
tMapDoublesEachValue(pass,fail) ;@TEST "map doubles each value"
        new in,out
        set in(1)=1,in(2)=2,in(3)=3
        do map^STDXFRM(.in,"value*2",.out)
        do eq^STDASSERT(.pass,.fail,$get(out(1)),2,"out(1)=2")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),4,"out(2)=4")
        do eq^STDASSERT(.pass,.fail,$get(out(3)),6,"out(3)=6")
        quit
        ;
tMapPreservesSubscripts(pass,fail)      ;@TEST "map preserves caller's subscripts"
        new in,out
        set in("a")=1,in("b")=2
        do map^STDXFRM(.in,"value+10",.out)
        do eq^STDASSERT(.pass,.fail,$get(out("a")),11,"out(a)=11")
        do eq^STDASSERT(.pass,.fail,$get(out("b")),12,"out(b)=12")
        quit
        ;
tMapEmptyInputProducesEmptyOutput(pass,fail)    ;@TEST "map over empty input leaves output empty"
        new in,out
        set out(1)="stale"
        do map^STDXFRM(.in,"value*2",.out)
        do false^STDASSERT(.pass,.fail,$data(out(1)),"out cleared")
        quit
        ;
tMapStringExpression(pass,fail) ;@TEST "map evaluates an arbitrary M expression"
        new in,out
        set in(1)="hello",in(2)="world"
        do map^STDXFRM(.in,"$length(value)",.out)
        do eq^STDASSERT(.pass,.fail,$get(out(1)),5,"len('hello')=5")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),5,"len('world')=5")
        quit
        ;
tMapHasAccessToKey(pass,fail)   ;@TEST "lambda sees the current key local"
        new in,out
        set in("a")=10,in("b")=20
        do map^STDXFRM(.in,"key_""=""_value",.out)
        do eq^STDASSERT(.pass,.fail,$get(out("a")),"a=10","key+value")
        do eq^STDASSERT(.pass,.fail,$get(out("b")),"b=20","key+value")
        quit
        ;
tMapStringSubscriptsRespected(pass,fail)        ;@TEST "string and integer subscripts both walked"
        new in,out
        set in(1)=100,in("k")=200,in(7)=300
        do map^STDXFRM(.in,"value+1",.out)
        do eq^STDASSERT(.pass,.fail,$get(out(1)),101,"int sub")
        do eq^STDASSERT(.pass,.fail,$get(out(7)),301,"int sub 7")
        do eq^STDASSERT(.pass,.fail,$get(out("k")),201,"string sub")
        quit
        ;
tMapClearsOutputFirst(pass,fail)        ;@TEST "map kills any pre-existing entries in out"
        new in,out
        set in(1)=1,in(2)=2
        set out("ghost")="leftover",out(99)="leftover"
        do map^STDXFRM(.in,"value*2",.out)
        do false^STDASSERT(.pass,.fail,$data(out("ghost")),"ghost gone")
        do false^STDASSERT(.pass,.fail,$data(out(99)),"99 gone")
        do eq^STDASSERT(.pass,.fail,$get(out(1)),2,"out(1)=2")
        quit
        ;
        ; ---- filter ----
tFilterKeepsTruthy(pass,fail)   ;@TEST "filter keeps elements where predicate is truthy"
        new in,out
        set in(1)=5,in(2)=15,in(3)=8,in(4)=20
        do filter^STDXFRM(.in,"value>10",.out)
        do false^STDASSERT(.pass,.fail,$data(out(1)),"5 dropped")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),15,"15 kept")
        do false^STDASSERT(.pass,.fail,$data(out(3)),"8 dropped")
        do eq^STDASSERT(.pass,.fail,$get(out(4)),20,"20 kept")
        quit
        ;
tFilterDropsFalsy(pass,fail)    ;@TEST "filter drops elements where predicate is 0"
        new in,out
        set in(1)=2,in(2)=4,in(3)=5,in(4)=8
        do filter^STDXFRM(.in,"value#2=0",.out)        ; even-only
        do eq^STDASSERT(.pass,.fail,$get(out(1)),2,"2 kept")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),4,"4 kept")
        do false^STDASSERT(.pass,.fail,$data(out(3)),"5 dropped")
        do eq^STDASSERT(.pass,.fail,$get(out(4)),8,"8 kept")
        quit
        ;
tFilterEmptyInputProducesEmptyOutput(pass,fail) ;@TEST "filter over empty input produces empty output"
        new in,out
        set out(1)="stale"
        do filter^STDXFRM(.in,"value>0",.out)
        do false^STDASSERT(.pass,.fail,$data(out(1)),"out cleared")
        quit
        ;
tFilterPredicateOnKey(pass,fail)        ;@TEST "filter predicate may inspect the key"
        new in,out
        set in("apple")=1,in("banana")=2,in("apricot")=3
        do filter^STDXFRM(.in,"$extract(key,1)=""a""",.out)
        do eq^STDASSERT(.pass,.fail,$get(out("apple")),1,"apple kept")
        do eq^STDASSERT(.pass,.fail,$get(out("apricot")),3,"apricot kept")
        do false^STDASSERT(.pass,.fail,$data(out("banana")),"banana dropped")
        quit
        ;
tFilterPreservesValuesNotJustKeys(pass,fail)    ;@TEST "filter copies values verbatim, not predicate result"
        new in,out
        set in(1)=42,in(2)=99
        do filter^STDXFRM(.in,"value>0",.out)
        do eq^STDASSERT(.pass,.fail,$get(out(1)),42,"raw value 42")
        do eq^STDASSERT(.pass,.fail,$get(out(2)),99,"raw value 99")
        quit
        ;
tFilterClearsOutputFirst(pass,fail)     ;@TEST "filter kills any pre-existing entries in out"
        new in,out
        set in(1)=10
        set out("ghost")="leftover"
        do filter^STDXFRM(.in,"value>0",.out)
        do false^STDASSERT(.pass,.fail,$data(out("ghost")),"ghost gone")
        quit
        ;
        ; ---- reduce ----
tReduceSumsValues(pass,fail)    ;@TEST "reduce folds a sum across values"
        new in
        set in(1)=1,in(2)=2,in(3)=3,in(4)=4
        do eq^STDASSERT(.pass,.fail,$$reduce^STDXFRM(.in,"acc+value",0),10,"sum 1..4 = 10")
        quit
        ;
tReduceWithEmptyInputReturnsInit(pass,fail)     ;@TEST "reduce over empty array returns the init seed unchanged"
        new in
        do eq^STDASSERT(.pass,.fail,$$reduce^STDXFRM(.in,"acc+value",42),42,"empty -> init")
        do eq^STDASSERT(.pass,.fail,$$reduce^STDXFRM(.in,"acc_value",""),"","empty -> empty init")
        quit
        ;
tReduceConcatenatesStrings(pass,fail)   ;@TEST "reduce can concatenate values"
        new in
        set in(1)="a",in(2)="b",in(3)="c"
        do eq^STDASSERT(.pass,.fail,$$reduce^STDXFRM(.in,"acc_value",""),"abc","abc concat")
        quit
        ;
tReduceProductOfValues(pass,fail)       ;@TEST "reduce computes a product"
        new in
        set in(1)=2,in(2)=3,in(3)=4
        do eq^STDASSERT(.pass,.fail,$$reduce^STDXFRM(.in,"acc*value",1),24,"2*3*4=24")
        quit
        ;
tReduceCountsViaIncrement(pass,fail)    ;@TEST "reduce can count by incrementing acc"
        new in
        set in(1)=10,in(2)=20,in("k")=30
        do eq^STDASSERT(.pass,.fail,$$reduce^STDXFRM(.in,"acc+1",0),3,"three elements")
        quit
        ;
tReduceUsesKey(pass,fail)       ;@TEST "reduce expression sees both value and key locals"
        new in
        set in("a")=1,in("b")=2,in("c")=3
        ; concat key:value pairs separated by | with leading | from init
        do eq^STDASSERT(.pass,.fail,$$reduce^STDXFRM(.in,"acc_""|""_key_"":""_value",""),"|a:1|b:2|c:3","kv pairs")
        quit
