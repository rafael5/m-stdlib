STDSEED ; m-stdlib — declarative test data loader (v0.1.3).
        ;
        ; Public API:
        ;   load^STDSEED(path,filer)         ; load TSV manifest via `filer`
        ;                                      (default: fileViaDie -> FILE^DIE)
        ;   $$loaded^STDSEED(path)           ; 1 iff path is currently tracked
        ;   clear^STDSEED(path)              ; drop bookkeeping for path
        ;   $$validate^STDSEED(path)         ; 1 if manifest parses; raises on syntax
        ;   loadJson^STDSEED(jsonText)       ; STUB — waits for STDJSON (Phase 2)
        ;
        ; Manifest format (TSV, one row per record):
        ;   <file>\t<field>=<value>\t<field>=<value>...
        ; Lines beginning with '#' are comments. Whitespace-only lines skip.
        ;
        ; Filer hook: the optional `filer` argument is a "tag^routine"
        ; reference invoked once per row as
        ;   do @filer@(file,.fda,.iens)
        ; with fda(file,"+1,",field)=value and `iens` an output IEN. The
        ; default — when filer is empty — calls FILE^DIE; that path
        ; assumes FileMan is loaded in the runtime environment.
        ;
        ; State per loaded path lives under ^STDLIB($job,"stdseed",path,...).
        ; clear() drops it. STDSEED does NOT open its own transaction;
        ; callers wanting rollback semantics wrap in STDFIX (v0.1.1+).
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDSEED-FILE-NOT-FOUND,
        ;   ,U-STDSEED-MISSING-FILE,
        ;   ,U-STDSEED-MISSING-FIELD,
        ;   ,U-STDSEED-FILER-ERROR,
        ;   ,U-STDSEED-NOT-IMPLEMENTED,
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
load(path,filer)        ; Load manifest at `path` via `filer` (default FILE^DIE).
        ; doc: Each parsed row is dispatched once. Errors propagate via $ECODE.
        ; doc: Example: do load^STDSEED("/etc/seed.tsv")
        new f
        set f=$get(filer)
        if f="" set f="fileViaDie^STDSEED"
        do walk(path,f,1)
        quit
        ;
loaded(path)    ; Predicate — 1 iff `path` is currently loaded.
        ; doc: Example: write $$loaded^STDSEED("/etc/seed.tsv")
        quit $select($data(^STDLIB($job,"stdseed",path)):1,1:0)
        ;
clear(path)     ; Drop bookkeeping for `path`. Idempotent.
        ; doc: Best-effort — does not delete already-filed records (caller's
        ; doc: responsibility, typically via STDFIX rollback).
        ; doc: Example: do clear^STDSEED("/etc/seed.tsv")
        kill ^STDLIB($job,"stdseed",path)
        quit
        ;
validate(path)  ; Parse-only check — return 1 on success; raise on syntax error.
        ; doc: Never invokes the filer. Use as a pre-flight before load().
        ; doc: Example: write $$validate^STDSEED("/etc/seed.tsv")
        do walk(path,"",0)
        quit 1
        ;
loadJson(jsonText)      ; Stub — JSON manifest loading waits for STDJSON.
        ; doc: Sets $ECODE to ,U-STDSEED-NOT-IMPLEMENTED,. Replaced once
        ; doc: STDJSON ships in Phase 2.
        set $ecode=",U-STDSEED-NOT-IMPLEMENTED,"
        quit
        ;
        ; ---------- internal: manifest walk ----------
        ;
walk(path,filer,doFile) ; Read TSV at `path`; dispatch per non-blank/non-comment row.
        ; doc: Internal — load() and validate() share this; doFile=0 skips the
        ; doc: filer call and the bookkeeping write.
        new line,trimmed,opened
        do tryOpen(path,.opened)
        if 'opened set $ecode=",U-STDSEED-FILE-NOT-FOUND," quit
        use path
        for  read line  quit:$zeof  do  quit:$ecode'=""
        . if $extract(line,$length(line))=$char(13) set line=$extract(line,1,$length(line)-1)
        . set trimmed=$$trim(line)
        . if trimmed="" quit
        . if $extract(trimmed,1)="#" quit
        . do processRow(path,line,filer,doFile)
        close path
        quit
        ;
processRow(path,line,filer,doFile)      ; Parse one TSV row; build FDA; dispatch.
        ; doc: Internal — sets $ECODE on syntax errors. When doFile=0 only
        ; doc: validates the row's shape.
        new file,fda,col,piece,fname,fval,iens,seq
        set file=$piece(line,$char(9),1)
        if file="" set $ecode=",U-STDSEED-MISSING-FILE," quit
        for col=2:1:$length(line,$char(9)) do  quit:$ecode'=""
        . set piece=$piece(line,$char(9),col)
        . if piece="" quit
        . if piece'["=" set $ecode=",U-STDSEED-MISSING-FIELD," quit
        . set fname=$piece(piece,"=",1)
        . set fval=$piece(piece,"=",2,$length(piece,"="))
        . set fda(file,"+1,",fname)=fval
        if 'doFile quit
        do dispatch(path,file,.fda,filer)
        quit
        ;
dispatch(path,file,fda,filer)   ; Invoke `filer` and book-keep the result.
        ; doc: Internal — wraps the filer call and translates any $ECODE the
        ; doc: filer raises into U-STDSEED-FILER-ERROR.
        new iens,seq
        ; m-lint: disable-next-line=M-MOD-036
        do @filer@(file,.fda,.iens)
        if $ecode'="" set $ecode=",U-STDSEED-FILER-ERROR," quit
        set seq=$increment(^STDLIB($job,"stdseed",path,"seq"))
        set ^STDLIB($job,"stdseed",path,"row",seq,"file")=file
        set ^STDLIB($job,"stdseed",path,"row",seq,"iens")=$get(iens)
        quit
        ;
fileViaDie(file,fda,iens)       ; Default filer — call FILE^DIE.
        ; doc: Internal default. Assumes FileMan available. After FILE^DIE,
        ; doc: ^TMP("DIERR",$JOB) is checked; on error sets $ECODE which
        ; doc: dispatch() relays as U-STDSEED-FILER-ERROR. Real-environment
        ; doc: integration is the v0.1.4 follow-on; this label compiles and
        ; doc: runs against any FileMan host but is not unit-tested.
        new ien,sub,fld
        kill ^TMP("STDSEED",$job,"FDA"),^TMP("STDSEED",$job,"IEN"),^TMP("DIERR",$job)
        set sub=""
        for  set sub=$order(fda(file,sub)) quit:sub=""  do
        . set fld=""
        . for  set fld=$order(fda(file,sub,fld)) quit:fld=""  do
        . . set ^TMP("STDSEED",$job,"FDA",file,sub,fld)=fda(file,sub,fld)
        ; m-lint: disable-next-line=M-MOD-036
        do FILE^DIE("","^TMP(""STDSEED"","_$job_",""FDA"")","^TMP(""STDSEED"","_$job_",""IEN"")")
        if $data(^TMP("DIERR",$job)) set $ecode=",U-STDSEED-FILER-DIE-ERROR," quit
        set iens=$get(^TMP("STDSEED",$job,"IEN",1))
        kill ^TMP("STDSEED",$job)
        quit
        ;
        ; ---------- internal: helpers ----------
        ;
tryOpen(path,opened)    ; Attempt OPEN with timeout; trap IO errors.
        ; doc: Internal — sets opened=1 on success, 0 on any IO failure
        ; doc: (missing file, permission denied, etc.). Lets walk() decide
        ; doc: whether to raise FILE-NOT-FOUND.
        new $etrap
        set opened=0
        set $etrap="set $ecode="""" quit"
        ; m-lint: disable-next-line=M-MOD-024
        open path:(readonly):2
        if $test set opened=1
        quit
        ;
trim(s) ; Strip leading and trailing ASCII whitespace (space, tab, CR, LF).
        ; doc: Internal — TSV manifest hygiene.
        new ws,n,start,fin
        set ws=" "_$char(9)_$char(13)_$char(10)
        set n=$length(s)
        set start=1
        for  quit:start>n  quit:ws'[$extract(s,start)  set start=start+1
        set fin=n
        for  quit:fin<start  quit:ws'[$extract(s,fin)  set fin=fin-1
        quit $extract(s,start,fin)
