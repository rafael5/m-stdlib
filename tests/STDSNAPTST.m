STDSNAPTST      ; Test suite for STDSNAP (v0.2.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tSerializeEmptyTree(.pass,.fail)
        do tSerializeSingleLeaf(.pass,.fail)
        do tSerializeMultiLeaf(.pass,.fail)
        do tSerializeNested(.pass,.fail)
        do tSerializeNumericSubscript(.pass,.fail)
        do tSerializeIsDeterministic(.pass,.fail)
        do tSerializeQuotesContainQuote(.pass,.fail)
        do tSaveThenMatches(.pass,.fail)
        do tMatchesDetectsValueChange(.pass,.fail)
        do tMatchesDetectsAddedKey(.pass,.fail)
        do tMatchesDetectsRemovedKey(.pass,.fail)
        do tMatchesMissingFileIsZero(.pass,.fail)
        do tAssertsRecordsPassOnMatch(.pass,.fail)
        do tAssertsRecordsFailOnMismatch(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- helpers ----
sandboxPath(suffix)     ; Build a unique path under /tmp for this test process.
        quit "/tmp/m-stdlib-snaptest-"_$job_"-"_suffix
        ;
        ; ---- serialize ----
tSerializeEmptyTree(pass,fail)  ;@TEST "serialize() of an empty tree returns ''"
        new data
        do eq^STDASSERT(.pass,.fail,$$serialize^STDSNAP(.data),"","empty tree → empty string")
        quit
        ;
tSerializeSingleLeaf(pass,fail) ;@TEST "serialize one leaf produces one line"
        new data,text,want
        set data("name")="alice"
        set text=$$serialize^STDSNAP(.data)
        set want="(""name"")=""alice"""
        do eq^STDASSERT(.pass,.fail,text,want,"one-leaf canonical form")
        quit
        ;
tSerializeMultiLeaf(pass,fail)  ;@TEST "serialize multiple leaves produces sorted lines"
        new data,text,lines,n
        set data("a")="apple"
        set data("b")="banana"
        set data("c")="cherry"
        set text=$$serialize^STDSNAP(.data)
        ; Lines should be in $ORDER → alphabetical for plain string subscripts
        set n=$length(text,$char(10))
        do eq^STDASSERT(.pass,.fail,n,3,"three lines (no trailing LF)")
        do eq^STDASSERT(.pass,.fail,$piece(text,$char(10),1),"(""a"")=""apple""","line 1")
        do eq^STDASSERT(.pass,.fail,$piece(text,$char(10),2),"(""b"")=""banana""","line 2")
        do eq^STDASSERT(.pass,.fail,$piece(text,$char(10),3),"(""c"")=""cherry""","line 3")
        quit
        ;
tSerializeNested(pass,fail)     ;@TEST "serialize a nested tree emits leaf-only paths"
        new data,text
        set data("user","name")="alice"
        set data("user","age")=42
        set data("system")="ok"
        set text=$$serialize^STDSNAP(.data)
        ; Order: ("system") then ("user","age") then ("user","name") via $ORDER
        do contains^STDASSERT(.pass,.fail,text,"(""system"")=""ok""","system leaf")
        do contains^STDASSERT(.pass,.fail,text,"(""user"",""age"")=42","nested numeric leaf")
        do contains^STDASSERT(.pass,.fail,text,"(""user"",""name"")=""alice""","nested string leaf")
        quit
        ;
tSerializeNumericSubscript(pass,fail)   ;@TEST "numeric subscripts are emitted unquoted"
        new data,text
        set data(1)="first"
        set data(2)="second"
        set data(10)="tenth"
        set text=$$serialize^STDSNAP(.data)
        ; M $ORDER on numeric-string subscripts gives natural numeric sort: 1,2,10.
        do eq^STDASSERT(.pass,.fail,$piece(text,$char(10),1),"(1)=""first""","numeric 1 unquoted")
        do eq^STDASSERT(.pass,.fail,$piece(text,$char(10),2),"(2)=""second""","numeric 2 unquoted")
        do eq^STDASSERT(.pass,.fail,$piece(text,$char(10),3),"(10)=""tenth""","numeric 10 unquoted")
        quit
        ;
tSerializeIsDeterministic(pass,fail)    ;@TEST "two serialize() calls on the same tree return identical text"
        new data,a,b
        set data("x")="1",data("y")="2",data("z")="3"
        set a=$$serialize^STDSNAP(.data)
        set b=$$serialize^STDSNAP(.data)
        do eq^STDASSERT(.pass,.fail,a,b,"two passes match exactly")
        quit
        ;
tSerializeQuotesContainQuote(pass,fail) ;@TEST "string values containing \" are doubled per M convention"
        new data,text
        set data("k")="say ""hi"""
        set text=$$serialize^STDSNAP(.data)
        do eq^STDASSERT(.pass,.fail,text,"(""k"")=""say """"hi""""""","double-quote escape")
        quit
        ;
        ; ---- save / matches ----
tSaveThenMatches(pass,fail)     ;@TEST "save then matches against the same data returns 1"
        new path,data
        set path=$$sandboxPath("rt")
        set data("k")="v"
        set data("n")=42
        do save^STDSNAP(path,.data)
        do true^STDASSERT(.pass,.fail,$$matches^STDSNAP(path,.data),"saved snapshot matches original data")
        do remove^STDFS(path)
        quit
        ;
tMatchesDetectsValueChange(pass,fail)   ;@TEST "matches() returns 0 if a value changed since save"
        new path,data
        set path=$$sandboxPath("vchg")
        set data("k")="v"
        do save^STDSNAP(path,.data)
        set data("k")="changed"
        do false^STDASSERT(.pass,.fail,$$matches^STDSNAP(path,.data),"value-change detected")
        do remove^STDFS(path)
        quit
        ;
tMatchesDetectsAddedKey(pass,fail)      ;@TEST "matches() returns 0 if a new key was added"
        new path,data
        set path=$$sandboxPath("addk")
        set data("a")="1"
        do save^STDSNAP(path,.data)
        set data("b")="2"
        do false^STDASSERT(.pass,.fail,$$matches^STDSNAP(path,.data),"added-key detected")
        do remove^STDFS(path)
        quit
        ;
tMatchesDetectsRemovedKey(pass,fail)    ;@TEST "matches() returns 0 if a key was removed"
        new path,data
        set path=$$sandboxPath("rmk")
        set data("a")="1",data("b")="2"
        do save^STDSNAP(path,.data)
        kill data("b")
        do false^STDASSERT(.pass,.fail,$$matches^STDSNAP(path,.data),"removed-key detected")
        do remove^STDFS(path)
        quit
        ;
tMatchesMissingFileIsZero(pass,fail)    ;@TEST "matches() against a missing file returns 0"
        new path,data
        set path=$$sandboxPath("never-saved")
        if $$exists^STDFS(path) do remove^STDFS(path)
        set data("k")="v"
        do false^STDASSERT(.pass,.fail,$$matches^STDSNAP(path,.data),"missing file → no match")
        quit
        ;
        ; ---- asserts ----
tAssertsRecordsPassOnMatch(pass,fail)   ;@TEST "asserts() routes a match to recordPass"
        new path,data,p,f
        set path=$$sandboxPath("apass")
        set data("k")="v"
        do save^STDSNAP(path,.data)
        set p=0,f=0
        do asserts^STDSNAP(.p,.f,path,.data,"snapshot match")
        do eq^STDASSERT(.pass,.fail,p,1,"pass=1 after match")
        do eq^STDASSERT(.pass,.fail,f,0,"fail=0 after match")
        do remove^STDFS(path)
        quit
        ;
tAssertsRecordsFailOnMismatch(pass,fail)        ;@TEST "asserts() routes a mismatch to recordFail"
        new path,data,p,f
        set path=$$sandboxPath("afail")
        set data("k")="v"
        do save^STDSNAP(path,.data)
        set data("k")="changed"
        set p=0,f=0
        do asserts^STDSNAP(.p,.f,path,.data,"snapshot mismatch")
        do eq^STDASSERT(.pass,.fail,p,0,"pass=0 after mismatch")
        do eq^STDASSERT(.pass,.fail,f,1,"fail=1 after mismatch")
        do remove^STDFS(path)
        quit
