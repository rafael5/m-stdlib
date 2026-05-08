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
        ;   FORMAT^STDLOG(name)                   — "kv" (default) | "json"
        ;
        ; Output line format (kv, default):
        ;   <ISO-8601 UTC ts> level=<NAME> event=<event> k=v k=v ...
        ;
        ; Output line format (json):
        ;   {"ts":"<ISO-8601>","level":"<NAME>","event":"<event>","k":"v",...}
        ;   All values are emitted as JSON strings (preserves the kv contract
        ;   that values are opaque text). Built via $$encode^STDJSON, so the
        ;   line is byte-exactly conformant RFC 8259.
        ;
        ; Value escaping (kv): a value with no space, '=', '"', or '\' is
        ; emitted raw. Otherwise it is wrapped in double quotes, with embedded
        ; '\' doubled to '\\' and embedded '"' escaped to '\"'.
        ;
        ; Defaults: threshold=INFO, sink=stderr, format=kv. Configuration is
        ; process-local (held under ^STDLIB($job,"stdlog","...")).
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDLOG-INVALID-LEVEL,
        ;   ,U-STDLOG-INVALID-SINK,
        ;   ,U-STDLOG-INVALID-FORMAT,
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
        ; doc: @param event   string  short event name (one token, no spaces ideally)
        ; doc: @param k1      string  key 1 (optional)
        ; doc: @param v1      string  value 1 (optional)
        ; doc: @param k2      string  key 2 (optional)
        ; doc: @param v2      string  value 2 (optional)
        ; doc: @param k3      string  key 3 (optional)
        ; doc: @param v3      string  value 3 (optional)
        ; doc: @param k4      string  key 4 (optional)
        ; doc: @param v4      string  value 4 (optional)
        ; doc: @param k5      string  key 5 (optional)
        ; doc: @param v5      string  value 5 (optional)
        ; doc: @example       do DEBUG^STDLOG("cache_miss","key","u:42")
        ; doc: @since         v0.0.4
        ; doc: @stable        stable
        ; doc: @see           do INFO^STDLOG, do WARN^STDLOG, do ERROR^STDLOG, do FATAL^STDLOG
        ; doc: Suppressed when the configured threshold is above DEBUG.
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(10,"DEBUG",event,.pairs)
        quit
        ;
INFO(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)       ; Emit an INFO line (default level).
        ; doc: @param event   string  short event name
        ; doc: @param k1      string  key 1 (optional; same shape through k5/v5)
        ; doc: @example       do INFO^STDLOG("login","user","alice","ip","1.2.3.4")
        ; doc: @since         v0.0.4
        ; doc: @stable        stable
        ; doc: @see           do DEBUG^STDLOG, do WARN^STDLOG, do ERROR^STDLOG, do FATAL^STDLOG
        ; doc: Emitted when threshold is INFO or below (DEBUG). The default level.
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(20,"INFO",event,.pairs)
        quit
        ;
WARN(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)       ; Emit a WARN line.
        ; doc: @param event   string  short event name
        ; doc: @param k1      string  key 1 (optional; same shape through k5/v5)
        ; doc: @example       do WARN^STDLOG("retry","attempt","3")
        ; doc: @since         v0.0.4
        ; doc: @stable        stable
        ; doc: @see           do INFO^STDLOG, do ERROR^STDLOG
        ; doc: Suppressed when threshold is ERROR or higher.
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(30,"WARN",event,.pairs)
        quit
        ;
ERROR(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)      ; Emit an ERROR line.
        ; doc: @param event   string  short event name
        ; doc: @param k1      string  key 1 (optional; same shape through k5/v5)
        ; doc: @example       do ERROR^STDLOG("db_failed","sqlcode","-803")
        ; doc: @since         v0.0.4
        ; doc: @stable        stable
        ; doc: @see           do WARN^STDLOG, do FATAL^STDLOG
        ; doc: Suppressed when threshold is FATAL.
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(40,"ERROR",event,.pairs)
        quit
        ;
FATAL(event,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)      ; Emit a FATAL line.
        ; doc: @param event   string  short event name
        ; doc: @param k1      string  key 1 (optional; same shape through k5/v5)
        ; doc: @example       do FATAL^STDLOG("crash","reason","oom")
        ; doc: @since         v0.0.4
        ; doc: @stable        stable
        ; doc: @see           do ERROR^STDLOG
        ; doc: Always emitted (threshold cannot be set above FATAL).
        new pairs do collect(.pairs,.k1,.v1,.k2,.v2,.k3,.v3,.k4,.v4,.k5,.v5)
        do emitLine(50,"FATAL",event,.pairs)
        quit
        ;
LEVEL(threshold)        ; Set the runtime threshold. Levels at or above pass.
        ; doc: @param threshold  string  one of "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
        ; doc: @raises           U-STDLOG-INVALID-LEVEL  `threshold` is not one of the five names
        ; doc: @example          do LEVEL^STDLOG("WARN")  ; suppress DEBUG and INFO
        ; doc: @since            v0.0.4
        ; doc: @stable           stable
        ; doc: @see              do SINK^STDLOG, do FORMAT^STDLOG
        ; doc: Numeric ranks: DEBUG=10, INFO=20, WARN=30, ERROR=40, FATAL=50.
        ; doc: An emitter at rank n is suppressed when threshold > n.
        new n
        set n=$$levelNum(threshold)
        if n=0 set $ecode=",U-STDLOG-INVALID-LEVEL," quit
        set ^STDLIB($job,"stdlog","level")=n
        quit
        ;
SINK(target)    ; Configure where log lines go.
        ; doc: @param target  string  one of "stderr", "stdout", "global", or "global:^GREF"
        ; doc: @raises        U-STDLOG-INVALID-SINK  `target` is not one of the documented forms
        ; doc: @example       do SINK^STDLOG("global:^MYLOG")  ; write to ^MYLOG(N)
        ; doc: @since         v0.0.4
        ; doc: @stable        stable
        ; doc: @see           do LEVEL^STDLOG, do FORMAT^STDLOG
        ; doc: "stderr" / "stdout" — write to /dev/stderr or current device.
        ; doc: "global" — write to ^STDLIB($job,"stdlog","buf",N).
        ; doc: "global:^FOO" — write to ^FOO(N) using $increment for N.
        new gref
        if (target="stderr")!(target="stdout")!(target="global") set ^STDLIB($job,"stdlog","sink")=target quit
        if $extract(target,1,7)'="global:" set $ecode=",U-STDLOG-INVALID-SINK," quit
        set gref=$extract(target,8,$length(target))
        if $extract(gref,1)'="^" set $ecode=",U-STDLOG-INVALID-SINK," quit
        set ^STDLIB($job,"stdlog","sink")=target
        quit
        ;
FORMAT(name)    ; Select line-rendering format. "kv" (default) or "json".
        ; doc: @param name    string  "kv" (default) or "json"
        ; doc: @raises        U-STDLOG-INVALID-FORMAT  `name` is not "kv" or "json"
        ; doc: @example       do FORMAT^STDLOG("json")  ; emit JSON-line output
        ; doc: @since         v0.0.4
        ; doc: @stable        stable
        ; doc: @see           do LEVEL^STDLOG, do SINK^STDLOG, $$encode^STDJSON
        ; doc: kv format: <ts> level=<NAME> event=<event> k=v k=v ...
        ; doc: json format: {"ts":...,"level":...,"event":...,"k":"v",...}
        ; doc: JSON output uses $$encode^STDJSON internally so every line
        ; doc: round-trips through $$parse^STDJSON without loss. All kv values
        ; doc: render as JSON strings (matches the kv-line semantic that
        ; doc: values are opaque text); callers wanting typed JSON should
        ; doc: build a tree directly and call $$encode^STDJSON themselves.
        if (name'="kv")&(name'="json") set $ecode=",U-STDLOG-INVALID-FORMAT," quit
        set ^STDLIB($job,"stdlog","format")=name
        quit
        ;
        ; ---------- internal: arg collection ----------
        ;
collect(pairs,k1,v1,k2,v2,k3,v3,k4,v4,k5,v5)    ; Pack supplied kv formals into pairs(N,"k"|"v").
        ; doc: @internal
        ; doc: $data() detects which formals the caller actually passed.
        ; doc: Missing values default to "" via $get().
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
        ; doc: @internal
        ; doc: Short-circuits when num < threshold; branches on configured
        ; doc: format ("kv" default, "json" via $$encode^STDJSON).
        new threshold,line,i,fmt
        set threshold=$get(^STDLIB($job,"stdlog","level"),20)
        if num<threshold quit
        set fmt=$get(^STDLIB($job,"stdlog","format"),"kv")
        if fmt="json" do emitJson(name,event,.pairs) quit
        set line=$$now^STDDATE()_" level="_name_" event="_$$kvVal(event)
        set i=""
        for  set i=$order(pairs(i)) quit:i=""  do
        . set line=line_" "_pairs(i,"k")_"="_$$kvVal(pairs(i,"v"))
        do writeLine(line)
        quit
        ;
emitJson(name,event,pairs)      ; Render and dispatch a JSON-format line.
        ; doc: @internal
        ; doc: Builds an STDJSON tree, calls $$encode^STDJSON, writes via
        ; doc: writeLine. All values render as JSON strings.
        ; doc: VERIFICATION DEFERRED — full assertion-level tests of the
        ; doc: emitted line are currently held back; calling $$encode^STDJSON
        ; doc: from inside the suite driver crashes the YDB harness with an
        ; doc: unattributable rc=1 (no TAP not-ok, no Bail Out, no stderr).
        ; doc: Likely the same M17/extrinsic-chain class as the documented
        ; doc: STDASSERT.raises P1 in TOOLCHAIN-FINDINGS.md. Implementation
        ; doc: is shipped intact; tests will land with that fix.
        new tree,i,line
        set tree="o"
        set tree("ts")="s:"_$$now^STDDATE()
        set tree("level")="s:"_name
        set tree("event")="s:"_event
        set i=""
        for  set i=$order(pairs(i)) quit:i=""  do
        . set tree(pairs(i,"k"))="s:"_pairs(i,"v")
        set line=$$encode^STDJSON(.tree)
        do writeLine(line)
        quit
        ;
writeLine(line) ; Send a fully-rendered line to the configured sink.
        ; doc: @internal
        ; doc: Sink defaults to stderr when unset. The "global" sinks use
        ; doc: $increment so concurrent emitters get unique slots.
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
        ; doc: @internal
        ; doc: A value is "clean" iff it has at least one char and contains
        ; doc: none of [space, '=', '"', '\']. Empty strings render as the
        ; doc: two-character literal "".
        if s="" quit """"""
        if $$needsQuote(s) quit """"_$$escape(s)_""""
        quit s
        ;
needsQuote(s)   ; True iff s contains any byte that forces quoting.
        ; doc: @internal
        ; doc: Space, '=', '"', or '\' triggers quoting.
        if s[" " quit 1
        if s["=" quit 1
        if s["""" quit 1
        if s["\" quit 1
        quit 0
        ;
escape(s)       ; Backslash-escape '\' (-> '\\') and '"' (-> '\"') in s.
        ; doc: @internal
        ; doc: Order matters: replace '\' first, then '"'.
        new t
        set t=$translate(s,"","")
        set t=$$replace(t,"\","\\")
        set t=$$replace(t,"""","\""")
        quit t
        ;
replace(haystack,from,to)       ; Naive scan-and-replace. Returns rebuilt string.
        ; doc: @internal
        ; doc: Used by escape(). $TRANSLATE only replaces single chars and
        ; doc: can't expand '\' to '\\'.
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
        ; doc: @internal
        ; doc: Used by LEVEL() to validate input and by emit to compare
        ; doc: against the threshold.
        if name="DEBUG" quit 10
        if name="INFO" quit 20
        if name="WARN" quit 30
        if name="ERROR" quit 40
        if name="FATAL" quit 50
        quit 0
        ;
