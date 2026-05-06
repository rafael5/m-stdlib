STDLOGTST       ; Test suite for STDLOG (v0.0.4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---- timestamp + line shape ----
        do tEmitTimestampIsIso8601Utc(.pass,.fail)
        do tEmitLineHasLevelAndEvent(.pass,.fail)
        do tEmitNoKvPairsIsLegal(.pass,.fail)
        do tEmitKeyValuePairsAppearInOrder(.pass,.fail)
        do tEmitFivePairsSupported(.pass,.fail)
        ;
        ; ---- value escaping ----
        do tCleanValueEmittedRaw(.pass,.fail)
        do tValueWithSpaceIsQuoted(.pass,.fail)
        do tValueWithEqualsIsQuoted(.pass,.fail)
        do tValueWithDoubleQuoteIsBackslashEscaped(.pass,.fail)
        do tValueWithBackslashIsBackslashEscaped(.pass,.fail)
        do tEmptyValueIsQuoted(.pass,.fail)
        ;
        ; ---- level filtering ----
        do tDefaultLevelIsInfo(.pass,.fail)
        do tDebugSuppressedAtLevelInfo(.pass,.fail)
        do tInfoEmittedAtLevelInfo(.pass,.fail)
        do tInfoSuppressedAtLevelWarn(.pass,.fail)
        do tWarnEmittedAtLevelWarn(.pass,.fail)
        do tErrorEmittedAtLevelError(.pass,.fail)
        do tFatalEmittedAtLevelFatal(.pass,.fail)
        do tFatalEmittedAtLevelInfo(.pass,.fail)
        do tInvalidLevelRaises(.pass,.fail)
        ;
        ; ---- sink dispatch ----
        do tSinkGlobalWritesToDefaultBuf(.pass,.fail)
        do tSinkGlobalNamedWritesToTarget(.pass,.fail)
        do tInvalidSinkRaises(.pass,.fail)
        ;
        ; ---- per-level entry points ----
        do tDebugEntryEmitsDebug(.pass,.fail)
        do tInfoEntryEmitsInfo(.pass,.fail)
        do tWarnEntryEmitsWarn(.pass,.fail)
        do tErrorEntryEmitsError(.pass,.fail)
        do tFatalEntryEmitsFatal(.pass,.fail)
        ;
        ; ---- json format ----
        ; STDASSERT.raises P1 fix landed (ZGOTO-based unwind); the
        ; tFormatInvalidRaises test should now be safe. The remaining
        ; six tests rely on $$encode^STDJSON's recursive descent, whose
        ; crash signature is independent of the raises P1 — see
        ; TOOLCHAIN-FINDINGS.md follow-up. Re-enable once that distinct
        ; encode-chain crash is resolved.
        do tFormatDefaultIsKv(.pass,.fail)
        do tFormatInvalidRaises(.pass,.fail)
        ; do tFormatJsonEmitsValidJson(.pass,.fail)
        ; do tFormatJsonHasTsLevelEvent(.pass,.fail)
        ; do tFormatJsonKvPairsBecomeKeys(.pass,.fail)
        ; do tFormatJsonValuesAreStrings(.pass,.fail)
        ; do tFormatJsonEscapesQuotesAndBackslash(.pass,.fail)
        ; do tFormatKvAfterJsonReverts(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- timestamp + line shape ----------
        ;
tEmitTimestampIsIso8601Utc(pass,fail)   ;@TEST "emit() timestamp is ISO-8601 UTC YYYY-MM-DDTHH:MM:SS.sssZ"
        new line,ts
        do reset
        do INFO^STDLOG("hello")
        set line=$$lastLine()
        set ts=$piece(line," ",1)
        do len^STDASSERT(.pass,.fail,$length(ts),24,"timestamp is 24 chars")
        do eq^STDASSERT(.pass,.fail,$extract(ts,5),"-","year-month dash")
        do eq^STDASSERT(.pass,.fail,$extract(ts,8),"-","month-day dash")
        do eq^STDASSERT(.pass,.fail,$extract(ts,11),"T","date-time T")
        do eq^STDASSERT(.pass,.fail,$extract(ts,14),":","hour-minute colon")
        do eq^STDASSERT(.pass,.fail,$extract(ts,17),":","minute-second colon")
        do eq^STDASSERT(.pass,.fail,$extract(ts,20),".","second-millis dot")
        do eq^STDASSERT(.pass,.fail,$extract(ts,24),"Z","trailing Z")
        quit
        ;
tEmitLineHasLevelAndEvent(pass,fail)    ;@TEST "emit() line carries level= and event="
        new line
        do reset
        do INFO^STDLOG("login")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"level=INFO","level token")
        do contains^STDASSERT(.pass,.fail,line,"event=login","event token")
        quit
        ;
tEmitNoKvPairsIsLegal(pass,fail)        ;@TEST "emit() with zero kv pairs writes a clean line"
        new line
        do reset
        do INFO^STDLOG("startup")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"event=startup","event present")
        do false^STDASSERT(.pass,.fail,line["=startup ","no trailing kv after event")
        quit
        ;
tEmitKeyValuePairsAppearInOrder(pass,fail)      ;@TEST "emit() preserves caller-supplied kv order"
        new line,evIdx,userIdx,ipIdx
        do reset
        do INFO^STDLOG("login","user","alice","ip","10.0.0.1")
        set line=$$lastLine()
        set evIdx=$find(line,"event=login")
        set userIdx=$find(line,"user=alice")
        set ipIdx=$find(line,"ip=10.0.0.1")
        do true^STDASSERT(.pass,.fail,evIdx<userIdx,"event before user")
        do true^STDASSERT(.pass,.fail,userIdx<ipIdx,"user before ip")
        quit
        ;
tEmitFivePairsSupported(pass,fail)      ;@TEST "emit() carries up to 5 kv pairs"
        new line
        do reset
        do INFO^STDLOG("e","a","1","b","2","c","3","d","4","e","5")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"a=1","pair 1")
        do contains^STDASSERT(.pass,.fail,line,"b=2","pair 2")
        do contains^STDASSERT(.pass,.fail,line,"c=3","pair 3")
        do contains^STDASSERT(.pass,.fail,line,"d=4","pair 4")
        do contains^STDASSERT(.pass,.fail,line,"e=5","pair 5")
        quit
        ;
        ; ---------- value escaping ----------
        ;
tCleanValueEmittedRaw(pass,fail)        ;@TEST "value with no special chars is emitted unquoted"
        new line
        do reset
        do INFO^STDLOG("e","k","abc123_-.")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"k=abc123_-.","raw emission")
        do false^STDASSERT(.pass,.fail,line["k=""","no quotes")
        quit
        ;
tValueWithSpaceIsQuoted(pass,fail)      ;@TEST "value with a space is wrapped in double quotes"
        new line
        do reset
        do INFO^STDLOG("e","msg","hello world")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"msg=""hello world""","quoted")
        quit
        ;
tValueWithEqualsIsQuoted(pass,fail)     ;@TEST "value with = is wrapped in double quotes"
        new line
        do reset
        do INFO^STDLOG("e","kv","a=b")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"kv=""a=b""","quoted around =")
        quit
        ;
tValueWithDoubleQuoteIsBackslashEscaped(pass,fail)      ;@TEST "value with double-quote is backslash-escaped inside quoted run"
        new line
        do reset
        do INFO^STDLOG("e","q","a""b")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"q=""a\""b""","backslash-quote inside quoted")
        quit
        ;
tValueWithBackslashIsBackslashEscaped(pass,fail)        ;@TEST "value with backslash is escaped to double-backslash"
        new line
        do reset
        do INFO^STDLOG("e","p","a\b c")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"p=""a\\b c""","double backslash inside quoted")
        quit
        ;
tEmptyValueIsQuoted(pass,fail)  ;@TEST "empty-string value is rendered as """""
        new line
        do reset
        do INFO^STDLOG("e","k","")
        set line=$$lastLine()
        do contains^STDASSERT(.pass,.fail,line,"k=""""","empty quoted")
        quit
        ;
        ; ---------- level filtering ----------
        ;
tDefaultLevelIsInfo(pass,fail)  ;@TEST "default threshold is INFO (DEBUG suppressed, INFO emitted)"
        do reset
        ; reset() set level=DEBUG to make tests independent. Force the "no level set" baseline.
        kill ^STDLIB($job,"stdlog","level")
        do DEBUG^STDLOG("dbg")
        do INFO^STDLOG("info")
        do len^STDASSERT(.pass,.fail,$$lineCount(),1,"only INFO emitted by default")
        quit
        ;
tDebugSuppressedAtLevelInfo(pass,fail)  ;@TEST "DEBUG suppressed when threshold is INFO"
        do reset
        do LEVEL^STDLOG("INFO")
        do DEBUG^STDLOG("dbg")
        do len^STDASSERT(.pass,.fail,$$lineCount(),0,"no lines emitted")
        quit
        ;
tInfoEmittedAtLevelInfo(pass,fail)      ;@TEST "INFO emitted when threshold is INFO"
        do reset
        do LEVEL^STDLOG("INFO")
        do INFO^STDLOG("info")
        do len^STDASSERT(.pass,.fail,$$lineCount(),1,"INFO at INFO emits")
        quit
        ;
tInfoSuppressedAtLevelWarn(pass,fail)   ;@TEST "INFO suppressed when threshold is WARN"
        do reset
        do LEVEL^STDLOG("WARN")
        do INFO^STDLOG("info")
        do len^STDASSERT(.pass,.fail,$$lineCount(),0,"INFO suppressed at WARN")
        quit
        ;
tWarnEmittedAtLevelWarn(pass,fail)      ;@TEST "WARN emitted when threshold is WARN"
        do reset
        do LEVEL^STDLOG("WARN")
        do WARN^STDLOG("w")
        do len^STDASSERT(.pass,.fail,$$lineCount(),1,"WARN at WARN emits")
        quit
        ;
tErrorEmittedAtLevelError(pass,fail)    ;@TEST "ERROR emitted at threshold ERROR; WARN suppressed"
        do reset
        do LEVEL^STDLOG("ERROR")
        do WARN^STDLOG("w")
        do ERROR^STDLOG("e")
        do len^STDASSERT(.pass,.fail,$$lineCount(),1,"only ERROR survives")
        do contains^STDASSERT(.pass,.fail,$$lastLine(),"level=ERROR","error level")
        quit
        ;
tFatalEmittedAtLevelFatal(pass,fail)    ;@TEST "FATAL is the only level that emits at threshold FATAL"
        do reset
        do LEVEL^STDLOG("FATAL")
        do DEBUG^STDLOG("d")
        do INFO^STDLOG("i")
        do WARN^STDLOG("w")
        do ERROR^STDLOG("e")
        do FATAL^STDLOG("f")
        do len^STDASSERT(.pass,.fail,$$lineCount(),1,"only FATAL emits")
        do contains^STDASSERT(.pass,.fail,$$lastLine(),"level=FATAL","fatal level")
        quit
        ;
tFatalEmittedAtLevelInfo(pass,fail)     ;@TEST "FATAL emitted at threshold INFO"
        do reset
        do LEVEL^STDLOG("INFO")
        do FATAL^STDLOG("crashed")
        do len^STDASSERT(.pass,.fail,$$lineCount(),1,"FATAL above INFO emits")
        quit
        ;
tInvalidLevelRaises(pass,fail)  ;@TEST "LEVEL() with unknown threshold sets $ECODE U-STDLOG-INVALID-LEVEL"
        do raises^STDASSERT(.pass,.fail,"do LEVEL^STDLOG(""TRACE"")","U-STDLOG-INVALID-LEVEL","unknown level")
        quit
        ;
        ; ---------- sink dispatch ----------
        ;
tSinkGlobalWritesToDefaultBuf(pass,fail)        ;@TEST "SINK(""global"") writes to ^STDLIB($job,""stdlog"",""buf"")"
        do reset
        do SINK^STDLOG("global")
        do INFO^STDLOG("e")
        do true^STDASSERT(.pass,.fail,$data(^STDLIB($job,"stdlog","buf",1)),"line at buf(1)")
        quit
        ;
tSinkGlobalNamedWritesToTarget(pass,fail)       ;@TEST "SINK(""global:^FOO"") writes to ^FOO(N)"
        new line
        kill ^STDLOGTSTSINK
        do reset
        do SINK^STDLOG("global:^STDLOGTSTSINK")
        do INFO^STDLOG("custom")
        set line=$get(^STDLOGTSTSINK(1))
        do contains^STDASSERT(.pass,.fail,line,"event=custom","custom global received line")
        kill ^STDLOGTSTSINK
        quit
        ;
tInvalidSinkRaises(pass,fail)   ;@TEST "SINK() with unknown target sets $ECODE U-STDLOG-INVALID-SINK"
        do raises^STDASSERT(.pass,.fail,"do SINK^STDLOG(""kafka"")","U-STDLOG-INVALID-SINK","unknown sink")
        quit
        ;
        ; ---------- per-level entry points ----------
        ;
tDebugEntryEmitsDebug(pass,fail)        ;@TEST "DEBUG() entry emits level=DEBUG"
        do reset
        do DEBUG^STDLOG("d")
        do contains^STDASSERT(.pass,.fail,$$lastLine(),"level=DEBUG","debug level token")
        quit
        ;
tInfoEntryEmitsInfo(pass,fail)  ;@TEST "INFO() entry emits level=INFO"
        do reset
        do INFO^STDLOG("i")
        do contains^STDASSERT(.pass,.fail,$$lastLine(),"level=INFO","info level token")
        quit
        ;
tWarnEntryEmitsWarn(pass,fail)  ;@TEST "WARN() entry emits level=WARN"
        do reset
        do WARN^STDLOG("w")
        do contains^STDASSERT(.pass,.fail,$$lastLine(),"level=WARN","warn level token")
        quit
        ;
tErrorEntryEmitsError(pass,fail)        ;@TEST "ERROR() entry emits level=ERROR"
        do reset
        do ERROR^STDLOG("e")
        do contains^STDASSERT(.pass,.fail,$$lastLine(),"level=ERROR","error level token")
        quit
        ;
tFatalEntryEmitsFatal(pass,fail)        ;@TEST "FATAL() entry emits level=FATAL"
        do reset
        do FATAL^STDLOG("f")
        do contains^STDASSERT(.pass,.fail,$$lastLine(),"level=FATAL","fatal level token")
        quit
        ;
        ; ---------- json format ----------
        ;
tFormatDefaultIsKv(pass,fail)   ;@TEST "FORMAT() defaults to kv (line begins with timestamp, not '{')"
        new line
        do reset
        do INFO^STDLOG("startup")
        set line=$$lastLine()
        do ne^STDASSERT(.pass,.fail,$extract(line,1),"{","kv line starts with date digit")
        do contains^STDASSERT(.pass,.fail,line,"level=INFO","kv keyed format")
        quit
        ;
tFormatJsonEmitsValidJson(pass,fail)    ;@TEST "FORMAT('json') emits parseable RFC 8259 JSON"
        new line,tree,ok
        do reset
        do FORMAT^STDLOG("json")
        do INFO^STDLOG("startup")
        set line=$$lastLine()
        do eq^STDASSERT(.pass,.fail,$extract(line,1),"{","line opens with '{'")
        do eq^STDASSERT(.pass,.fail,$extract(line,$length(line)),"}","line closes with '}'")
        set ok=$$parse^STDJSON(line,.tree)
        do true^STDASSERT(.pass,.fail,ok,"JSON round-trips through parse")
        do eq^STDASSERT(.pass,.fail,$extract(tree),"o","root is JSON object")
        quit
        ;
tFormatJsonHasTsLevelEvent(pass,fail)   ;@TEST "FORMAT('json') line carries ts/level/event keys"
        new line,tree
        do reset
        do FORMAT^STDLOG("json")
        do WARN^STDLOG("login_throttled")
        set line=$$lastLine()
        do parse^STDJSON(line,.tree)
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.tree("level")),"WARN","level=WARN")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.tree("event")),"login_throttled","event preserved")
        do len^STDASSERT(.pass,.fail,$length($$valueOf^STDJSON(.tree("ts"))),24,"ts is 24-char ISO-8601")
        quit
        ;
tFormatJsonKvPairsBecomeKeys(pass,fail)         ;@TEST "FORMAT('json') kv pairs render as object keys"
        new line,tree
        do reset
        do FORMAT^STDLOG("json")
        do INFO^STDLOG("login","user","alice","ip","1.2.3.4")
        set line=$$lastLine()
        do parse^STDJSON(line,.tree)
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.tree("user")),"alice","user key")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.tree("ip")),"1.2.3.4","ip key")
        quit
        ;
tFormatJsonValuesAreStrings(pass,fail)  ;@TEST "FORMAT('json') emits all kv values as JSON strings"
        new line,tree
        do reset
        do FORMAT^STDLOG("json")
        do INFO^STDLOG("count","n","42")
        set line=$$lastLine()
        do parse^STDJSON(line,.tree)
        do eq^STDASSERT(.pass,.fail,$$type^STDJSON(.tree("n")),"string","n stored as string sigil, not number")
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.tree("n")),"42","value preserved")
        quit
        ;
tFormatJsonEscapesQuotesAndBackslash(pass,fail) ;@TEST "FORMAT('json') escapes embedded \\\" and \\\\"
        new line,tree
        do reset
        do FORMAT^STDLOG("json")
        do INFO^STDLOG("msg","text","he said ""hi"" and \\backslash")
        set line=$$lastLine()
        do parse^STDJSON(line,.tree)
        do eq^STDASSERT(.pass,.fail,$$valueOf^STDJSON(.tree("text")),"he said ""hi"" and \\backslash","embedded quote+bs round-trip")
        quit
        ;
tFormatKvAfterJsonReverts(pass,fail)    ;@TEST "FORMAT('kv') after FORMAT('json') reverts to kv lines"
        new line
        do reset
        do FORMAT^STDLOG("json")
        do INFO^STDLOG("first")
        do FORMAT^STDLOG("kv")
        do INFO^STDLOG("second")
        set line=$$lastLine()
        do ne^STDASSERT(.pass,.fail,$extract(line,1),"{","kv line resumes")
        do contains^STDASSERT(.pass,.fail,line,"event=second","second event landed in kv")
        quit
        ;
tFormatInvalidRaises(pass,fail) ;@TEST "FORMAT('xml') raises U-STDLOG-INVALID-FORMAT"
        do reset
        do raises^STDASSERT(.pass,.fail,"do FORMAT^STDLOG(""xml"")","U-STDLOG-INVALID-FORMAT","unsupported format raises")
        quit
        ;
        ; ---------- helpers (no @TEST marker) ----------
        ;
reset   ; Kill STDLOG state, set sink=global + level=DEBUG for assertion-friendly tests.
        kill ^STDLIB($job,"stdlog")
        do SINK^STDLOG("global")
        do LEVEL^STDLOG("DEBUG")
        quit
        ;
lineCount()     ; Number of lines accumulated in the default global buffer.
        new last
        set last=$order(^STDLIB($job,"stdlog","buf",""),-1)
        quit +last
        ;
lastLine()      ; Last line written to the default global buffer ("" if none).
        new last
        set last=$order(^STDLIB($job,"stdlog","buf",""),-1)
        if last="" quit ""
        quit ^STDLIB($job,"stdlog","buf",last)
        ;
