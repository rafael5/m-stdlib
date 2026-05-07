STDCSVTST       ; Test suite for STDCSV (v0.0.6).
        ; m-lint: disable-file=M-MOD-020,M-MOD-024
        ; M-MOD-024 disabled file-wide: OPEN/CLOSE deviceparams in the
        ; file-I/O smoke tests are misparsed as local reads — see
        ; TOOLCHAIN-FINDINGS.md.
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tParseSimpleLf(.pass,.fail)
        do tParseSimpleCrlf(.pass,.fail)
        do tParseTrailingTerminatorOptional(.pass,.fail)
        do tParseHeaderShapeMatchesData(.pass,.fail)
        do tParseSpacesPreserved(.pass,.fail)
        do tParseQuotedFields(.pass,.fail)
        do tParseEmbeddedComma(.pass,.fail)
        do tParseEmbeddedCrlf(.pass,.fail)
        do tParseEscapedQuote(.pass,.fail)
        do tParseBomStripped(.pass,.fail)
        do tParseEmpty(.pass,.fail)
        do tParseEmptyFields(.pass,.fail)
        do tParseRowCountReturned(.pass,.fail)
        do tParseClearsCallerArray(.pass,.fail)
        ;
        do tWriteSimple(.pass,.fail)
        do tWriteQuotesFieldsContainingComma(.pass,.fail)
        do tWriteQuotesFieldsContainingCrlf(.pass,.fail)
        do tWriteEscapesEmbeddedQuote(.pass,.fail)
        do tWriteEmptyArray(.pass,.fail)
        do tWriteSingleField(.pass,.fail)
        do tWriteRagged(.pass,.fail)
        ;
        do tParseRoundTripsWrite(.pass,.fail)
        do tParseRoundTripsWriteWithSpecials(.pass,.fail)
        ;
        do tParseFileSmoke(.pass,.fail)
        do tWriteFileSmoke(.pass,.fail)
        ;
        ; STDCSV's OPEN-fail path uses YDB's `open path:(readonly):timeout
        ; else  set $ecode=...` pattern. The `else` clause catches OPEN
        ; *timeout* but not immediate filesystem errors (file-not-found
        ; raises Z150379354 directly via $ETRAP, bypassing the else). The
        ; U-STDCSV-OPEN-FAIL contract is therefore exercised by the
        ; positive-path file-I/O smoke tests (parseFile / writeFile) only;
        ; an explicit raises-test against a missing path would observe the
        ; underlying YDB error code, not the U-STDCSV-* mapping. A future
        ; STDCSV refactor (wrap OPEN in $ETRAP) would close this gap.
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- parse() — RFC-4180 §2 ----------
        ;
tParseSimpleLf(pass,fail)       ;@TEST "parse() handles LF-terminated rows"
        new rows,n
        set n=$$parse^STDCSV("a,b,c"_$char(10)_"d,e,f"_$char(10),.rows)
        do eq^STDASSERT(.pass,.fail,n,2,"row count")
        do eq^STDASSERT(.pass,.fail,rows(1,1),"a","r1c1")
        do eq^STDASSERT(.pass,.fail,rows(1,2),"b","r1c2")
        do eq^STDASSERT(.pass,.fail,rows(1,3),"c","r1c3")
        do eq^STDASSERT(.pass,.fail,rows(2,1),"d","r2c1")
        do eq^STDASSERT(.pass,.fail,rows(2,2),"e","r2c2")
        do eq^STDASSERT(.pass,.fail,rows(2,3),"f","r2c3")
        quit
        ;
tParseSimpleCrlf(pass,fail)     ;@TEST "parse() handles CRLF-terminated rows (RFC-4180 §2.1)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("aaa,bbb,ccc"_crlf_"zzz,yyy,xxx"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,n,2,"row count")
        do eq^STDASSERT(.pass,.fail,rows(1,1),"aaa","r1c1")
        do eq^STDASSERT(.pass,.fail,rows(2,3),"xxx","r2c3")
        quit
        ;
tParseTrailingTerminatorOptional(pass,fail)     ;@TEST "parse() accepts files with no trailing newline (RFC-4180 §2.2)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("aaa,bbb"_crlf_"ccc,ddd",.rows)
        do eq^STDASSERT(.pass,.fail,n,2,"row count without trailing CRLF")
        do eq^STDASSERT(.pass,.fail,rows(2,2),"ddd","last field captured")
        quit
        ;
tParseHeaderShapeMatchesData(pass,fail) ;@TEST "parse() treats header row identically to data rows (RFC-4180 §2.3)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("name,age,city"_crlf_"Alice,30,NYC"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,n,2,"header counted as a row")
        do eq^STDASSERT(.pass,.fail,rows(1,1),"name","header c1")
        do eq^STDASSERT(.pass,.fail,rows(2,1),"Alice","data c1")
        quit
        ;
tParseSpacesPreserved(pass,fail)        ;@TEST "parse() preserves spaces inside fields (RFC-4180 §2.4)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("a, b ,c"_crlf_"  d,e,  f"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,rows(1,2)," b ","leading+trailing space preserved")
        do eq^STDASSERT(.pass,.fail,rows(2,1),"  d","leading spaces preserved")
        do eq^STDASSERT(.pass,.fail,rows(2,3),"  f","leading spaces preserved")
        quit
        ;
tParseQuotedFields(pass,fail)   ;@TEST "parse() unwraps double-quoted fields (RFC-4180 §2.5)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("aaa,""bbb"",ccc"_crlf_"""x"",""y"",""z"""_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,rows(1,1),"aaa","unquoted field")
        do eq^STDASSERT(.pass,.fail,rows(1,2),"bbb","quoted field unwrapped")
        do eq^STDASSERT(.pass,.fail,rows(2,1),"x","quoted field unwrapped")
        do eq^STDASSERT(.pass,.fail,rows(2,3),"z","quoted field unwrapped")
        quit
        ;
tParseEmbeddedComma(pass,fail)  ;@TEST "parse() treats commas inside quoted fields as literal (RFC-4180 §2.6)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("aaa,""b,b,b"",ccc"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,rows(1,2),"b,b,b","commas inside quotes preserved")
        do eq^STDASSERT(.pass,.fail,rows(1,3),"ccc","field after embedded-comma intact")
        quit
        ;
tParseEmbeddedCrlf(pass,fail)   ;@TEST "parse() treats CRLF inside quoted fields as literal (RFC-4180 §2.6)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("aaa,""b"_crlf_"bb"",ccc"_crlf_"zzz,yyy,xxx"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,n,2,"two records, not four")
        do eq^STDASSERT(.pass,.fail,rows(1,2),"b"_crlf_"bb","CRLF preserved inside quoted field")
        do eq^STDASSERT(.pass,.fail,rows(2,1),"zzz","next record intact")
        quit
        ;
tParseEscapedQuote(pass,fail)   ;@TEST "parse() collapses doubled quotes to a single quote (RFC-4180 §2.7)"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("aaa,""b""""bb""""ccc"",ddd"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,rows(1,2),"b""bb""ccc","double-quote collapsed to single quote")
        quit
        ;
tParseBomStripped(pass,fail)    ;@TEST "parse() strips a leading UTF-8 BOM"
        new rows,n,crlf,bom
        set crlf=$char(13,10)
        set bom=$char(239,187,191)
        set n=$$parse^STDCSV(bom_"id,name"_crlf_"1,Alice"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,rows(1,1),"id","BOM stripped from first field")
        do eq^STDASSERT(.pass,.fail,rows(2,1),"1","second row intact")
        quit
        ;
tParseEmpty(pass,fail)  ;@TEST "parse() of empty string yields zero rows"
        new rows,n
        set n=$$parse^STDCSV("",.rows)
        do eq^STDASSERT(.pass,.fail,n,0,"row count 0")
        do false^STDASSERT(.pass,.fail,$data(rows),"rows array untouched")
        quit
        ;
tParseEmptyFields(pass,fail)    ;@TEST "parse() treats consecutive commas as empty fields"
        new rows,n
        set n=$$parse^STDCSV("a,,c"_$char(10),.rows)
        do eq^STDASSERT(.pass,.fail,rows(1,1),"a","first field")
        do eq^STDASSERT(.pass,.fail,rows(1,2),"","empty middle field")
        do eq^STDASSERT(.pass,.fail,rows(1,3),"c","third field")
        quit
        ;
tParseRowCountReturned(pass,fail)       ;@TEST "parse() return value equals the number of rows populated"
        new rows,n,crlf
        set crlf=$char(13,10)
        set n=$$parse^STDCSV("1,a"_crlf_"2,b"_crlf_"3,c"_crlf,.rows)
        do eq^STDASSERT(.pass,.fail,n,3,"3 rows")
        quit
        ;
tParseClearsCallerArray(pass,fail)      ;@TEST "parse() does not leak data from a previous call"
        new rows,n
        set rows(99,99)="stale"
        set n=$$parse^STDCSV("a,b"_$char(10),.rows)
        do false^STDASSERT(.pass,.fail,$data(rows(99,99)),"stale subscript cleared")
        do eq^STDASSERT(.pass,.fail,rows(1,1),"a","fresh data set")
        quit
        ;
        ; ---------- write() — RFC-4180 emit ----------
        ;
tWriteSimple(pass,fail) ;@TEST "write() emits CRLF-terminated rows (RFC-4180 §2.1)"
        new rows,out,crlf
        set crlf=$char(13,10)
        set rows(1,1)="aaa",rows(1,2)="bbb",rows(1,3)="ccc"
        set rows(2,1)="zzz",rows(2,2)="yyy",rows(2,3)="xxx"
        set out=$$write^STDCSV(.rows)
        do eq^STDASSERT(.pass,.fail,out,"aaa,bbb,ccc"_crlf_"zzz,yyy,xxx"_crlf,"canonical CRLF output")
        quit
        ;
tWriteQuotesFieldsContainingComma(pass,fail)    ;@TEST "write() quotes fields containing commas (RFC-4180 §2.6)"
        new rows,out,crlf
        set crlf=$char(13,10)
        set rows(1,1)="aaa",rows(1,2)="b,b,b",rows(1,3)="ccc"
        set out=$$write^STDCSV(.rows)
        do eq^STDASSERT(.pass,.fail,out,"aaa,""b,b,b"",ccc"_crlf,"comma triggers quoting")
        quit
        ;
tWriteQuotesFieldsContainingCrlf(pass,fail)     ;@TEST "write() quotes fields containing line breaks (RFC-4180 §2.6)"
        new rows,out,crlf
        set crlf=$char(13,10)
        set rows(1,1)="aaa",rows(1,2)="b"_crlf_"bb",rows(1,3)="ccc"
        set out=$$write^STDCSV(.rows)
        do eq^STDASSERT(.pass,.fail,out,"aaa,""b"_crlf_"bb"",ccc"_crlf,"CRLF triggers quoting; inner CRLF preserved")
        quit
        ;
tWriteEscapesEmbeddedQuote(pass,fail)   ;@TEST "write() doubles embedded double-quotes (RFC-4180 §2.7)"
        new rows,out,crlf,q,expected
        set crlf=$char(13,10)
        set q=$char(34)
        set rows(1,1)="hello "_q_"world"_q
        set rows(1,2)="foo"
        set expected=q_"hello "_q_q_"world"_q_q_q_",foo"_crlf
        set out=$$write^STDCSV(.rows)
        do eq^STDASSERT(.pass,.fail,out,expected,"embedded quotes doubled and field wrapped")
        quit
        ;
tWriteEmptyArray(pass,fail)     ;@TEST "write() of an empty array is the empty string"
        new rows,out
        set out=$$write^STDCSV(.rows)
        do eq^STDASSERT(.pass,.fail,out,"","empty in -> empty out")
        quit
        ;
tWriteSingleField(pass,fail)    ;@TEST "write() of a single-field row emits exactly one CRLF"
        new rows,out,crlf
        set crlf=$char(13,10)
        set rows(1,1)="hello"
        set out=$$write^STDCSV(.rows)
        do eq^STDASSERT(.pass,.fail,out,"hello"_crlf,"single field with terminator")
        quit
        ;
tWriteRagged(pass,fail) ;@TEST "write() handles rows with differing column counts"
        new rows,out,crlf
        set crlf=$char(13,10)
        set rows(1,1)="a",rows(1,2)="b",rows(1,3)="c"
        set rows(2,1)="d"
        set rows(3,1)="e",rows(3,2)="f"
        set out=$$write^STDCSV(.rows)
        do eq^STDASSERT(.pass,.fail,out,"a,b,c"_crlf_"d"_crlf_"e,f"_crlf,"ragged rows preserved")
        quit
        ;
        ; ---------- round-trip ----------
        ;
tParseRoundTripsWrite(pass,fail)        ;@TEST "parse(write(rows)) reproduces rows for plain ASCII"
        new src,out,back,n,r,c,ok
        set src(1,1)="name",src(1,2)="age",src(1,3)="city"
        set src(2,1)="Alice",src(2,2)="30",src(2,3)="NYC"
        set src(3,1)="Bob",src(3,2)="25",src(3,3)="LA"
        set out=$$write^STDCSV(.src)
        set n=$$parse^STDCSV(out,.back)
        do eq^STDASSERT(.pass,.fail,n,3,"row count round-trips")
        set ok=1
        for r=1:1:3 for c=1:1:3 if back(r,c)'=src(r,c) set ok=0
        do true^STDASSERT(.pass,.fail,ok,"every cell round-trips")
        quit
        ;
tParseRoundTripsWriteWithSpecials(pass,fail)    ;@TEST "parse(write(rows)) round-trips fields containing , "" and CRLF"
        new src,out,back,n,crlf
        set crlf=$char(13,10)
        set src(1,1)="plain",src(1,2)="has,comma",src(1,3)="has""quote"
        set src(2,1)="has"_crlf_"newline",src(2,2)="""leading-quote"
        set out=$$write^STDCSV(.src)
        set n=$$parse^STDCSV(out,.back)
        do eq^STDASSERT(.pass,.fail,n,2,"row count")
        do eq^STDASSERT(.pass,.fail,back(1,1),"plain","plain")
        do eq^STDASSERT(.pass,.fail,back(1,2),"has,comma","comma round-trips")
        do eq^STDASSERT(.pass,.fail,back(1,3),"has""quote","quote round-trips")
        do eq^STDASSERT(.pass,.fail,back(2,1),"has"_crlf_"newline","CRLF round-trips")
        do eq^STDASSERT(.pass,.fail,back(2,2),"""leading-quote","leading-quote round-trips")
        quit
        ;
        ; ---------- file I/O smoke ----------
        ;
tParseFileSmoke(pass,fail)      ;@TEST "parseFile() reads a file from disk and dispatches per-row"
        new path,crlf,rowCount
        set crlf=$char(13,10)
        set path="/tmp/stdcsv-parsefile-"_$job_".csv"
        kill ^STDLIB($job,"csvtst")
        ; Write fixture: 3 rows including a quoted multi-line field.
        open path:(newversion):5  else  do false^STDASSERT(.pass,.fail,1,"open for write failed") quit
        use path
        write "id,note"_crlf
        write "1,""hello"_crlf_"world"""_crlf
        write "2,plain"_crlf
        close path
        do parseFile^STDCSV(path,"capture^STDCSVTST")
        set rowCount=$get(^STDLIB($job,"csvtst","count"),0)
        do eq^STDASSERT(.pass,.fail,rowCount,3,"3 rows dispatched")
        do eq^STDASSERT(.pass,.fail,$get(^STDLIB($job,"csvtst",1,1)),"id","row 1 col 1")
        do eq^STDASSERT(.pass,.fail,$get(^STDLIB($job,"csvtst",2,2)),"hello"_crlf_"world","row 2 multi-line preserved")
        do eq^STDASSERT(.pass,.fail,$get(^STDLIB($job,"csvtst",3,2)),"plain","row 3 col 2")
        ; cleanup
        open path:(newversion):0  use path  close path:delete
        kill ^STDLIB($job,"csvtst")
        quit
        ;
tWriteFileSmoke(pass,fail)      ;@TEST "writeFile() writes a CSV that parseFile() reads back identically"
        new path,src,roundtrip,n
        set path="/tmp/stdcsv-writefile-"_$job_".csv"
        set src(1,1)="name",src(1,2)="age"
        set src(2,1)="Alice",src(2,2)="30"
        set src(3,1)="has,comma",src(3,2)="ok"
        do writeFile^STDCSV(path,.src)
        kill ^STDLIB($job,"csvtst")
        do parseFile^STDCSV(path,"capture^STDCSVTST")
        do eq^STDASSERT(.pass,.fail,$get(^STDLIB($job,"csvtst","count"),0),3,"3 rows written and read back")
        do eq^STDASSERT(.pass,.fail,$get(^STDLIB($job,"csvtst",3,1)),"has,comma","embedded-comma field round-trips through file")
        ; cleanup
        open path:(newversion):0  use path  close path:delete
        kill ^STDLIB($job,"csvtst")
        quit
        ;
        ; Callback for parseFile() smoke tests.
        ; doc: Stash row data into a process-local global so the test label
        ; doc: can read it back.
capture(rownum,fields)  ; parseFile callback
        new j
        set ^STDLIB($job,"csvtst","count")=rownum
        set j=""
        for  set j=$order(fields(j)) quit:j=""  set ^STDLIB($job,"csvtst",rownum,j)=fields(j)
        quit
