STDCSV  ; m-stdlib — RFC-4180 CSV parser/writer (pure-M).
        ; m-lint: disable-file=M-MOD-024
        ; M-MOD-024 false positives: the linter parses YDB OPEN/CLOSE
        ; deviceparams (readonly, newversion, stream, nowrap, delete) as
        ; local-variable reads, then cascades read-of-undefined complaints
        ; through the rest of parseFile/writeFile. Tracked as a P2 in
        ; TOOLCHAIN-FINDINGS.md.
        ;
        ; Four public entry points:
        ;   $$parse^STDCSV(text,.rows)    — text → rows(i,j); returns row count
        ;   $$write^STDCSV(.rows)         — rows(i,j) → RFC-4180 CSV text
        ;   parseFile^STDCSV(path,cb)     — read path; dispatch cb(row,.fields) per record
        ;   writeFile^STDCSV(path,.rows)  — write rows(i,j) to path as RFC-4180 CSV
        ;
        ; Behaviours (RFC-4180 §2):
        ;   §2.1 — records separated by CRLF; LF-only and lone-CR are also
        ;          accepted on input. write() emits CRLF.
        ;   §2.2 — trailing line terminator on the last record is optional
        ;          on input; write() always emits one.
        ;   §2.3 — header rows have the same shape as data rows; the parser
        ;          does not distinguish them.
        ;   §2.4 — spaces inside fields are preserved verbatim.
        ;   §2.5 — fields may optionally be wrapped in '"..."'; the wrapping
        ;          quotes are not part of the value.
        ;   §2.6 — quoted fields may contain ',', CR, or LF as literals.
        ;   §2.7 — '""' inside a quoted field decodes to a single '"';
        ;          write() doubles any embedded '"' and wraps the field.
        ;
        ; Extension over the RFC: a leading UTF-8 BOM (EF BB BF) is stripped
        ; from the input by parse(). write() never emits a BOM.
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDCSV-OPEN-FAIL,
        ;
        ; Input is treated as a string of bytes (one M character per byte —
        ; values 0..255 via $ASCII / $CHAR). Embedded NUL bytes are not
        ; supported (M strings cannot represent them portably).
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
parse(text,rows)        ; Parse CSV text into rows(i,j); return row count.
        ; doc: Strips a leading UTF-8 BOM. Accepts CRLF, LF, or lone CR
        ; doc: as record terminators. Quoted fields may contain commas,
        ; doc: CRLF, and "" escapes (RFC-4180 §2.5–§2.7). The caller's
        ; doc: rows array is killed before population so stale subscripts
        ; doc: do not leak across calls.
        ; doc: Example: set n=$$parse^STDCSV("a,b,c"_$char(13,10),.r)
        new i,n,c,nc,state,field,row,col,bom,cr,lf,q
        kill rows
        if text="" quit 0
        set bom=$char(239,187,191),cr=$char(13),lf=$char(10),q=""""
        set i=1,n=$length(text)
        if $extract(text,1,3)=bom set i=4
        set state=0,field="",row=1,col=1
        for  quit:i>n  do
        . set c=$extract(text,i)
        . if state=0 do  quit
        . . if c="," set rows(row,col)=field,field="",col=col+1,i=i+1 quit
        . . if c=cr do  quit
        . . . if (col>1)!(field'="") set rows(row,col)=field,row=row+1
        . . . set field="",col=1
        . . . set nc=$extract(text,i+1)
        . . . set i=$select(nc=lf:i+2,1:i+1)
        . . if c=lf do  quit
        . . . if (col>1)!(field'="") set rows(row,col)=field,row=row+1
        . . . set field="",col=1,i=i+1
        . . if (c=q)&(field="") set state=1,i=i+1 quit
        . . set field=field_c,i=i+1
        . ; state=1 — inside a quoted field
        . if c=q do  quit
        . . if $extract(text,i+1)=q set field=field_q,i=i+2 quit
        . . set state=0,i=i+1
        . set field=field_c,i=i+1
        ; flush trailing partial record (no terminator at EOF)
        if (col>1)!(field'="") set rows(row,col)=field,row=row+1
        quit row-1
        ;
write(rows)     ; Serialise rows(i,j) to RFC-4180 CSV text.
        ; doc: Each populated row is emitted with a CRLF terminator. Fields
        ; doc: containing ',', '"', CR, or LF are wrapped in '"..."' with
        ; doc: embedded '"' doubled per RFC-4180 §2.7. An empty rows array
        ; doc: yields the empty string. Sparse columns walk via $order, so
        ; doc: ragged rows are emitted with as many fields as are defined.
        ; doc: Example: set r(1,1)="a",r(1,2)="b" write $$write^STDCSV(.r)
        new out,r,c,first,crlf
        set out="",crlf=$char(13,10)
        set r=$order(rows(""))
        for  quit:r=""  do  set r=$order(rows(r))
        . set first=1
        . set c=$order(rows(r,""))
        . for  quit:c=""  do  set c=$order(rows(r,c))
        . . if 'first set out=out_","
        . . set out=out_$$emit(rows(r,c))
        . . set first=0
        . set out=out_crlf
        quit out
        ;
parseFile(path,callback)        ; Parse file at path; dispatch callback per record.
        ; doc: Reads path line-by-line, accumulating across record boundaries
        ; doc: when a quoted field contains an embedded line break (RFC-4180
        ; doc: §2.6). For each completed record, calls the callback as
        ; doc:   do @callback@(rownum, .fields)
        ; doc: where fields(j) holds the j'th field (1-based) and rownum is
        ; doc: the 1-based record index. The callback identifier is the
        ; doc: usual "label^routine" form passed to indirection.
        ; doc: Sets $ECODE=,U-STDCSV-OPEN-FAIL, on open failure.
        ; doc: Example: do parseFile^STDCSV("foo.csv","onrow^MYAPP")
        new buf,line,curRow,nrows,rows,j,fields
        set buf="",curRow=0
        open path:(readonly):5  else  set $ecode=",U-STDCSV-OPEN-FAIL," quit
        use path
        for  read line  quit:$zeof  do
        . ; YDB's default SEQ READ strips LF but not CR — drop a trailing
        . ; CR so we can re-inject canonical CRLF between accumulated lines.
        . if $extract(line,$length(line))=$char(13) set line=$extract(line,1,$length(line)-1)
        . set buf=$select(buf="":line,1:buf_$char(13,10)_line)
        . if ($length(buf,"""")-1)#2 quit
        . set nrows=$$parse(buf,.rows)
        . set buf=""
        . if nrows<1 quit
        . set curRow=curRow+1
        . kill fields
        . set j=""
        . for  set j=$order(rows(1,j)) quit:j=""  set fields(j)=rows(1,j)
        . do @callback@(curRow,.fields)
        close path
        if buf'="" do
        . set nrows=$$parse(buf,.rows)
        . if nrows<1 quit
        . set curRow=curRow+1
        . kill fields
        . set j=""
        . for  set j=$order(rows(1,j)) quit:j=""  set fields(j)=rows(1,j)
        . do @callback@(curRow,.fields)
        quit
        ;
writeFile(path,rows)    ; Serialise rows(i,j) and write to path as RFC-4180 CSV.
        ; doc: Truncates path if it exists. Uses STREAM mode so embedded
        ; doc: CRLFs in quoted fields are written byte-faithfully.
        ; doc: Sets $ECODE=,U-STDCSV-OPEN-FAIL, on open failure.
        ; doc: Example: do writeFile^STDCSV("/tmp/out.csv",.rows)
        new text
        set text=$$write(.rows)
        open path:(newversion:stream:nowrap):5  else  set $ecode=",U-STDCSV-OPEN-FAIL," quit
        use path
        write text
        close path
        quit
        ;
        ; ---------- internal helpers ----------
        ;
emit(s) ; Render one field per RFC-4180.
        ; doc: Internal — wraps in '"..."' iff s contains ',', '"', CR, or LF;
        ; doc: doubles every embedded '"' before wrapping.
        new q,cr,lf
        set q="""",cr=$char(13),lf=$char(10)
        if (s'[",")&(s'[q)&(s'[cr)&(s'[lf) quit s
        quit q_$$dq(s)_q
        ;
dq(s)   ; Double every '"' in s — RFC-4180 §2.7 escape.
        ; doc: Internal — implemented via $piece walk so the cost is
        ; doc: linear in the input length.
        new q,n,p,out
        set q=""""
        set n=$length(s,q)
        if n<2 quit s
        set out=$piece(s,q,1)
        for p=2:1:n set out=out_q_q_$piece(s,q,p)
        quit out
