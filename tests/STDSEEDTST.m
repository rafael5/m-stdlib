STDSEEDTST      ; Test suite for STDSEED (v0.1.3).
        ; m-lint: disable-file=M-MOD-020
        ; Tests use a stub filer (capture^STDSEEDTST) so the suite does not
        ; depend on FileMan being installed in the runtime environment.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---- manifest parsing ----
        do tParseEmptyManifest(.pass,.fail)
        do tParseSimpleSingleRow(.pass,.fail)
        do tParseMultipleRowsSameFile(.pass,.fail)
        do tParseMultipleFiles(.pass,.fail)
        do tParseSkipsCommentLines(.pass,.fail)
        do tParseSkipsBlankLines(.pass,.fail)
        do tParseValueWithEqualsSign(.pass,.fail)
        ;
        ; ---- LOAD via filer hook ----
        do tLoadInvokesFilerOncePerRow(.pass,.fail)
        do tLoadFilerReceivesFileNumber(.pass,.fail)
        do tLoadFilerReceivesFda(.pass,.fail)
        do tLoadTracksRecordsForClear(.pass,.fail)
        do tLoadFilerErrorPropagatesEcode(.pass,.fail)
        ;
        ; ---- LOADED predicate ----
        do tLoadedFalseBeforeLoad(.pass,.fail)
        do tLoadedTrueAfterLoad(.pass,.fail)
        do tLoadedFalseAfterClear(.pass,.fail)
        ;
        ; ---- CLEAR ----
        do tClearRemovesTracking(.pass,.fail)
        do tClearIsIdempotent(.pass,.fail)
        ;
        ; ---- VALIDATE ----
        do tValidateAcceptsWellFormed(.pass,.fail)
        do tValidateRejectsRowMissingFile(.pass,.fail)
        do tValidateRejectsRowWithoutEquals(.pass,.fail)
        do tValidateDoesNotInvokeFiler(.pass,.fail)
        ;
        ; ---- LOADJSON stub ----
        do tLoadJsonRaisesNotImplemented(.pass,.fail)
        ;
        ; ---- error paths ----
        do tLoadOfMissingPathRaises(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- helpers ----------
        ;
deletePath(path)        ; Remove a temp file (best-effort).
        new $etrap
        set $etrap="set $ecode="""" quit"
        ; m-lint: disable-next-line=M-MOD-024
        open path:(newversion):0
        use path
        ; m-lint: disable-next-line=M-MOD-024
        close path:delete
        quit
        ;
capture(file,fda,iens)  ; Stub filer — records every call into ^STDLIB("seedtst",...).
        ; doc: Sequence-numbered so order can be verified. Sets the IEN to a
        ; doc: monotonically-increasing fake based on the call count.
        new k,sub,ien
        set k=$increment(^STDLIB($job,"seedtst","calls"))
        set ien=k
        set ^STDLIB($job,"seedtst","row",k,"file")=file
        set sub=""
        for  set sub=$order(fda(file,sub)) quit:sub=""  do
        . new fld
        . set fld=""
        . for  set fld=$order(fda(file,sub,fld)) quit:fld=""  do
        . . set ^STDLIB($job,"seedtst","row",k,"fda",sub,fld)=fda(file,sub,fld)
        set iens=ien
        quit
        ;
failingFiler(file,fda,iens)     ; Stub filer that simulates a FILE^DIE failure.
        ; doc: Sets $ECODE to the contractual error code; STDSEED relays.
        set $ecode=",U-STDSEED-FILER-ERROR,"
        quit
        ;
resetCaptures   ; Wipe the stub-filer scratch area.
        kill ^STDLIB($job,"seedtst")
        quit
        ;
        ; ---------- manifest parsing ----------
        ;
tParseEmptyManifest(pass,fail)  ;@TEST "LOAD on an empty manifest invokes the filer 0 times"
        new path,n
        set path="/tmp/stdseed-empty-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path)
        do load^STDSEED(path,"capture^STDSEEDTST")
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,0,"0 filer calls")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tParseSimpleSingleRow(pass,fail)        ;@TEST "single TSV row dispatches to the filer once"
        new path,n
        set path="/tmp/stdseed-one-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=DEMO PKG"_$char(9)_"1=DEMO")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,1,"1 filer call")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tParseMultipleRowsSameFile(pass,fail)   ;@TEST "two rows for the same file each dispatch once"
        new path,n
        set path="/tmp/stdseed-two-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"200"_$char(9)_".01=USER,A","200"_$char(9)_".01=USER,B")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,2,"2 filer calls")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tParseMultipleFiles(pass,fail)  ;@TEST "rows for different files all dispatch"
        new path,n
        set path="/tmp/stdseed-mix-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=PKG","200"_$char(9)_".01=USER")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,2,"2 filer calls across 2 files")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tParseSkipsCommentLines(pass,fail)      ;@TEST "lines starting with # are skipped"
        new path,n
        set path="/tmp/stdseed-cmt-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"# this is a comment","9.4"_$char(9)_".01=PKG","# trailing comment")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,1,"comments ignored")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tParseSkipsBlankLines(pass,fail)        ;@TEST "blank lines (and pure-whitespace lines) are skipped"
        new path,n
        set path="/tmp/stdseed-blk-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"","9.4"_$char(9)_".01=PKG","","   ","9.4"_$char(9)_".01=PKG2")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,2,"2 filer calls — blanks ignored")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tParseValueWithEqualsSign(pass,fail)    ;@TEST "field=value retains additional '=' characters in the value"
        new path,val
        set path="/tmp/stdseed-eq-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=KEY=VAL=MORE")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set val=$get(^STDLIB($job,"seedtst","row",1,"fda","+1,",".01"))
        do eq^STDASSERT(.pass,.fail,val,"KEY=VAL=MORE","extra equals preserved")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
        ; ---------- LOAD via filer hook ----------
        ;
tLoadInvokesFilerOncePerRow(pass,fail)  ;@TEST "filer is invoked exactly once per non-skipped row"
        new path,n
        set path="/tmp/stdseed-fcount-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=A","# skipped","","9.4"_$char(9)_".01=B","9.4"_$char(9)_".01=C")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,3,"3 calls for 3 data rows")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tLoadFilerReceivesFileNumber(pass,fail) ;@TEST "filer receives the file number as first arg"
        new path,fn1,fn2
        set path="/tmp/stdseed-fn-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=A","200"_$char(9)_".01=U")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set fn1=$get(^STDLIB($job,"seedtst","row",1,"file"))
        set fn2=$get(^STDLIB($job,"seedtst","row",2,"file"))
        do eq^STDASSERT(.pass,.fail,fn1,"9.4","row 1 file=9.4")
        do eq^STDASSERT(.pass,.fail,fn2,"200","row 2 file=200")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tLoadFilerReceivesFda(pass,fail)        ;@TEST "filer receives an FDA shaped fda(file,iens,field)=value"
        new path,v01,v1
        set path="/tmp/stdseed-fda-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=DEMO PKG"_$char(9)_"1=DEMO")
        do load^STDSEED(path,"capture^STDSEEDTST")
        set v01=$get(^STDLIB($job,"seedtst","row",1,"fda","+1,",".01"))
        set v1=$get(^STDLIB($job,"seedtst","row",1,"fda","+1,","1"))
        do eq^STDASSERT(.pass,.fail,v01,"DEMO PKG",".01 = DEMO PKG")
        do eq^STDASSERT(.pass,.fail,v1,"DEMO","1 = DEMO")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tLoadTracksRecordsForClear(pass,fail)   ;@TEST "after LOAD the bookkeeping global is populated"
        new path
        set path="/tmp/stdseed-trk-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=PKG","200"_$char(9)_".01=USER")
        do load^STDSEED(path,"capture^STDSEEDTST")
        do true^STDASSERT(.pass,.fail,$data(^STDLIB($job,"stdseed",path)),"bookkeeping defined")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tLoadFilerErrorPropagatesEcode(pass,fail)       ;@TEST "filer that sets $ECODE causes LOAD to surface U-STDSEED-FILER-ERROR"
        new path
        set path="/tmp/stdseed-err-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=PKG")
        do raises^STDASSERT(.pass,.fail,"do load^STDSEED("""_path_""",""failingFiler^STDSEEDTST"")","U-STDSEED-FILER-ERROR","filer error surfaced")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
        ; ---------- LOADED predicate ----------
        ;
tLoadedFalseBeforeLoad(pass,fail)       ;@TEST "$$loaded() returns 0 before LOAD"
        new path
        set path="/tmp/stdseed-lf1-"_$job_".tsv"
        do eq^STDASSERT(.pass,.fail,$$loaded^STDSEED(path),0,"loaded=0 before load")
        quit
        ;
tLoadedTrueAfterLoad(pass,fail) ;@TEST "$$loaded() returns 1 after LOAD"
        new path
        set path="/tmp/stdseed-lt-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=PKG")
        do load^STDSEED(path,"capture^STDSEEDTST")
        do eq^STDASSERT(.pass,.fail,$$loaded^STDSEED(path),1,"loaded=1 after load")
        do clear^STDSEED(path)
        do deletePath(path)
        quit
        ;
tLoadedFalseAfterClear(pass,fail)       ;@TEST "$$loaded() returns 0 after CLEAR"
        new path
        set path="/tmp/stdseed-lfc-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=PKG")
        do load^STDSEED(path,"capture^STDSEEDTST")
        do clear^STDSEED(path)
        do eq^STDASSERT(.pass,.fail,$$loaded^STDSEED(path),0,"loaded=0 after clear")
        do deletePath(path)
        quit
        ;
        ; ---------- CLEAR ----------
        ;
tClearRemovesTracking(pass,fail)        ;@TEST "CLEAR removes the bookkeeping global"
        new path
        set path="/tmp/stdseed-crt-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=PKG")
        do load^STDSEED(path,"capture^STDSEEDTST")
        do clear^STDSEED(path)
        do false^STDASSERT(.pass,.fail,$data(^STDLIB($job,"stdseed",path)),"bookkeeping removed")
        do deletePath(path)
        quit
        ;
tClearIsIdempotent(pass,fail)   ;@TEST "CLEAR on a path never loaded is a no-op"
        new path
        set path="/tmp/stdseed-cid-"_$job_".tsv"
        do clear^STDSEED(path)
        do false^STDASSERT(.pass,.fail,$data(^STDLIB($job,"stdseed",path)),"still empty after no-op clear")
        quit
        ;
        ; ---------- VALIDATE ----------
        ;
tValidateAcceptsWellFormed(pass,fail)   ;@TEST "$$validate() returns 1 for a well-formed manifest"
        new path
        set path="/tmp/stdseed-vok-"_$job_".tsv"
        do writeFixture(path,"9.4"_$char(9)_".01=PKG"_$char(9)_"1=DEMO","200"_$char(9)_".01=USER")
        do eq^STDASSERT(.pass,.fail,$$validate^STDSEED(path),1,"validate=1")
        do deletePath(path)
        quit
        ;
tValidateRejectsRowMissingFile(pass,fail)       ;@TEST "$$validate() raises U-STDSEED-MISSING-FILE on a row whose first col is empty"
        new path
        set path="/tmp/stdseed-vmf-"_$job_".tsv"
        do writeFixture(path,$char(9)_".01=PKG")
        do raises^STDASSERT(.pass,.fail,"do v^STDSEEDTST("""_path_""")","U-STDSEED-MISSING-FILE","empty file column rejected")
        do deletePath(path)
        quit
        ;
tValidateRejectsRowWithoutEquals(pass,fail)     ;@TEST "$$validate() raises U-STDSEED-MISSING-FIELD when a field has no '='"
        new path
        set path="/tmp/stdseed-vme-"_$job_".tsv"
        do writeFixture(path,"9.4"_$char(9)_"justaname")
        do raises^STDASSERT(.pass,.fail,"do v^STDSEEDTST("""_path_""")","U-STDSEED-MISSING-FIELD","missing '=' rejected")
        do deletePath(path)
        quit
        ;
tValidateDoesNotInvokeFiler(pass,fail)  ;@TEST "$$validate() never invokes the filer"
        new path,n
        set path="/tmp/stdseed-vnf-"_$job_".tsv"
        do resetCaptures
        do writeFixture(path,"9.4"_$char(9)_".01=PKG")
        do v^STDSEEDTST(path)
        set n=+$get(^STDLIB($job,"seedtst","calls"))
        do eq^STDASSERT(.pass,.fail,n,0,"filer not invoked during validate")
        do deletePath(path)
        quit
        ;
        ; ---------- LOADJSON stub ----------
        ;
tLoadJsonRaisesNotImplemented(pass,fail)        ;@TEST "loadJson() raises U-STDSEED-NOT-IMPLEMENTED until STDJSON ships"
        do raises^STDASSERT(.pass,.fail,"do loadJson^STDSEED(""{}"")","U-STDSEED-NOT-IMPLEMENTED","loadJson stub")
        quit
        ;
        ; ---------- error paths ----------
        ;
tLoadOfMissingPathRaises(pass,fail)     ;@TEST "load() of a path that does not exist raises U-STDSEED-FILE-NOT-FOUND"
        new path
        set path="/tmp/stdseed-no-such-"_$job_".tsv"
        do raises^STDASSERT(.pass,.fail,"do load^STDSEED("""_path_""",""capture^STDSEEDTST"")","U-STDSEED-FILE-NOT-FOUND","missing path rejected")
        quit
        ;
        ; ---------- helpers used by tests ----------
        ;
writeFixture(path,l1,l2,l3,l4,l5,l6,l7,l8)      ; Write up to 8 lines + LF to path.
        ; doc: Internal — used by parsing tests to compose tiny manifests.
        new lines,i,n
        set n=0,lines("")=""
        if $data(l1) set n=n+1,lines(n)=l1
        if $data(l2) set n=n+1,lines(n)=l2
        if $data(l3) set n=n+1,lines(n)=l3
        if $data(l4) set n=n+1,lines(n)=l4
        if $data(l5) set n=n+1,lines(n)=l5
        if $data(l6) set n=n+1,lines(n)=l6
        if $data(l7) set n=n+1,lines(n)=l7
        if $data(l8) set n=n+1,lines(n)=l8
        ; m-lint: disable-next-line=M-MOD-024
        open path:(newversion):5
        use path
        for i=1:1:n write lines(i),!
        close path
        quit
        ;
v(path) ; Helper that calls $$validate^STDSEED for use inside raises^STDASSERT XECUTE strings.
        ; doc: raises^STDASSERT can XECUTE only DO-style commands; wrapping the
        ; doc: $$validate extrinsic in a DO-callable stub makes it usable.
        new dummy
        set dummy=$$validate^STDSEED(path)
        quit
