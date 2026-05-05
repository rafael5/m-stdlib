STDLOG  ; m-stdlib — structured key=value logger (v0.0.4).
        ; m-lint: disable-file=M-MOD-024
        ; M-MOD-024 false positives: the linter parses YDB OPEN deviceparams
        ; (e.g. APPEND) in writeLine() as local-variable reads. Same cause as
        ; STDCSV's file-wide disable; tracked in TOOLCHAIN-FINDINGS.md.
        ;
        ; Public entry points:
        ;   DEBUG^STDLOG(event,k1,v1,...,k5,v5)   — up to 5 kv pairs
        ;   INFO^STDLOG(event,...)
        ;   WARN^STDLOG(event,...)
        ;   ERROR^STDLOG(event,...)
        ;   FATAL^STDLOG(event,...)
        ;   LEVEL^STDLOG(threshold)               — "DEBUG"|"INFO"|"WARN"|"ERROR"|"FATAL"
        ;   SINK^STDLOG(target)                   — "stderr"|"stdout"|"global"|"global:^GREF"
        ;
        ; Output line format:
        ;   <ISO-8601 UTC ts> level=<NAME> event=<event> k=v k=v ...
        ;
        ; Value escaping: a value with no space, '=', '"', or '\' is emitted
        ; raw. Otherwise it is wrapped in double quotes, with embedded '\'
        ; doubled to '\\' and embedded '"' escaped to '\"'.
        ;
        ; Defaults: threshold=INFO, sink=stderr. Configuration is process-
        ; local (held under ^STDLIB($job,"stdlog","...")).
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDLOG-INVALID-LEVEL,
        ;   ,U-STDLOG-INVALID-SINK,
        ;
        ; Timestamp source: $$now^STDDATE() (millisecond-precision ISO-8601
        ; UTC ending in Z). v0.0.4 shipped an inline helper; track L4b
        ; (this commit) bumps to STDDATE now that v0.0.5 is in.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
DEBUG(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)      ; Emit a DEBUG line.
        ; doc: Suppressed when the configured threshold is above DEBUG.
        ; doc: Example: do DEBUG^STDLOG("cache_miss","key","u:42")
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(10,"DEBUG",event,.pairs)
        quit
        ;
INFO(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)       ; Emit an INFO line (default level).
        ; doc: Example: do INFO^STDLOG("login","user","alice","ip","1.2.3.4")
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(20,"INFO",event,.pairs)
        quit
        ;
WARN(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)       ; Emit a WARN line.
        ; doc: Example: do WARN^STDLOG("retry","attempt","3")
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(30,"WARN",event,.pairs)
        quit
        ;
ERROR(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)      ; Emit an ERROR line.
        ; doc: Example: do ERROR^STDLOG("db_failed","sqlcode","-803")
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(40,"ERROR",event,.pairs)
        quit
        ;
FATAL(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)      ; Emit a FATAL line.
        ; doc: Example: do FATAL^STDLOG("crash","reason","oom")
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(50,"FATAL",event,.pairs)
        quit
        ;
LEVEL(threshold)        ; Set the runtime threshold. Levels at or above pass.
        ; doc: Accepts "DEBUG", "INFO", "WARN", "ERROR", "FATAL". Bad
        ; doc: values raise ,U-STDLOG-INVALID-LEVEL,.
        ; doc: Example: do LEVEL^STDLOG("WARN")  ; suppress DEBUG and INFO
        new n
        set n=$$levelNum(threshold)
        if n=0 set $ecode=",U-STDLOG-INVALID-LEVEL," quit
        set ^STDLIB($job,"stdlog","level")=n
        quit
        ;
SINK(target)    ; Configure where log lines go.
        ; doc: "stderr" / "stdout" — write to /dev/stderr or current device.
        ; doc: "global" — write to ^STDLIB($job,"stdlog","buf",N).
        ; doc: "global:^FOO" — write to ^FOO(N) using $increment for N.
        ; doc: Anything else raises ,U-STDLOG-INVALID-SINK,.
        new gref
        if (target="stderr")!(target="stdout")!(target="global") set ^STDLIB($job,"stdlog","sink")=target quit
        if $extract(target,1,7)'="global:" set $ecode=",U-STDLOG-INVALID-SINK," quit
        set gref=$extract(target,8,$length(target))
        if $extract(gref,1)'="^" set $ecode=",U-STDLOG-INVALID-SINK," quit
        set ^STDLIB($job,"stdlog","sink")=target
        quit
        ;
        ; ---------- internal: arg collection ----------
        ;
collect(pairs,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)    ; Pack supplied kv formals into pairs(N,"k"|"v").
        ; doc: Internal — $data() detects which formals the caller actually
        ; doc: passed. Missing values default to "" via $get().
        new n set n=0
        if $data(k1) set n=n+1,pairs(n,"k")=k1,pairs(n,"v")=$get(v1)
        if $data(k2) set n=n+1,pairs(n,"k")=k2,pairs(n,"v")=$get(v2)
        if $data(k3) set n=n+1,pairs(n,"k")=k3,pairs(n,"v")=$get(v3)
        if $data(k4) set n=n+1,pairs(n,"k")=k4,pairs(n,"v")=$get(v4)
        if $data(k5) set n=n+1,pairs(n,"k")=k5,pairs(n,"v")=$get(v5)
        quit
        ;
        ; ---------- internal: line assembly + dispatch ----------
        ;
emitLine(num,name,event,pairs)  ; Build a log line at level (num,name) and dispatch.
        ; doc: Internal — short-circuits when num < threshold.
        new threshold,line,i
        set threshold=$get(^STDLIB($job,"stdlog","level"),20)
        if num<threshold quit
        set line=$$now^STDDATE()_" level="_name_" event="_$$kvVal(event)
        set i=""
        for  set i=$order(pairs(i)) quit:i=""  do
        . set line=line_" "_pairs(i,"k")_"="_$$kvVal(pairs(i,"v"))
        do writeLine(line)
        quit
        ;
writeLine(line) ; Send a fully-rendered line to the configured sink.
        ; doc: Internal — sink defaults to stderr when unset. The "global"
        ; doc: sinks use $increment so concurrent emitters get unique slots.
        new sink,gref,idx,io
        set sink=$get(^STDLIB($job,"stdlog","sink"),"stderr")
        if sink="global" do  quit
        . set idx=$increment(^STDLIB($job,"stdlog","cnt"))
        . set ^STDLIB($job,"stdlog","buf",idx)=line
        if $extract(sink,1,7)="global:" do  quit
        . set gref=$extract(sink,8,$length(sink))
        . set idx=$increment(^STDLIB($job,"stdlog","cnt","g",gref))
        . set @gref@(idx)=line
        if sink="stderr" do  quit
        . set io=$io
        . ; m-lint: disable-next-line=M-MOD-022
        . open "/dev/stderr":(append):0
        . use "/dev/stderr" write line,!
        . use io
        ; default / "stdout" — emit to current device
        write line,!
        quit
        ;
        ; ---------- internal: kv formatting ----------
        ;
kvVal(s)        ; Render a value: raw if "clean", else quoted-and-escaped.
        ; doc: Internal — a value is "clean" iff it has at least one char
        ; doc: and contains none of [space, '=', '"', '\']. Empty strings
        ; doc: render as the two-character literal "".
        if s="" quit """"""
        if $$needsQuote(s) quit """"_$$escape(s)_""""
        quit s
        ;
needsQuote(s)   ; True iff s contains any byte that forces quoting.
        ; doc: Internal — space, '=', '"', or '\' triggers quoting.
        if s[" " quit 1
        if s["=" quit 1
        if s["""" quit 1
        if s["\" quit 1
        quit 0
        ;
escape(s)       ; Backslash-escape '\' (-> '\\') and '"' (-> '\"') in s.
        ; doc: Internal — order matters: replace '\' first, then '"'.
        new t
        set t=$translate(s,"","")
        set t=$$replace(t,"\","\\")
        set t=$$replace(t,"""","\""")
        quit t
        ;
replace(haystack,from,to)       ; Naive scan-and-replace. Returns rebuilt string.
        ; doc: Internal — used by escape(). $TRANSLATE only replaces single
        ; doc: chars and can't expand '\' to '\\'.
        new out,n,i,fLen,c
        set out="",n=$length(haystack),fLen=$length(from),i=1
        for  quit:i>n  do
        . set c=$extract(haystack,i,i+fLen-1)
        . if c=from set out=out_to,i=i+fLen quit
        . set out=out_$extract(haystack,i),i=i+1
        quit out
        ;
        ; ---------- internal: level mapping ----------
        ;
levelNum(name)  ; Map a level name to its numeric priority. 0 if unknown.
        ; doc: Internal — used by LEVEL() to validate input and by emit
        ; doc: to compare against the threshold.
        if name="DEBUG" quit 10
        if name="INFO" quit 20
        if name="WARN" quit 30
        if name="ERROR" quit 40
        if name="FATAL" quit 50
        quit 0
        ;
