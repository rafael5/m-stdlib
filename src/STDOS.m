STDOS   ; m-stdlib — Process / env / cmdline helpers (YDB-only v1).
        ; m-lint: disable-file=M-MOD-020
        ; m-lint: disable-file=M-MOD-021
        ; m-lint: disable-file=M-MOD-022
        ; m-lint: disable-file=M-MOD-023
        ; M-MOD-020: splitArgs writes to its by-ref second formal `args` but
        ; not to `s`; the by-ref analyzer flags every caller as a candidate
        ; without seeing the `args` write inside splitArgs.
        ; M-MOD-021/022/023: STDOS is a thin layer over $ZTRNLNM / $J /
        ; $ZCMDLINE / ZHALT — all YDB extensions to the M standard. v0.2.x
        ; ships YDB-only by design; the IRIS arm lands when STDOS gets its
        ; $CLASSMETHOD-driven helpers (T15, post-v0.3.0).
        ;
        ; Public extrinsics:
        ;   $$env^STDOS(name)            — environment variable lookup ("" if unset)
        ;   $$pid^STDOS()                — current process ID (integer)
        ;   $$cmdline^STDOS()            — raw $ZCMDLINE
        ;   $$splitArgs^STDOS(s,.args)   — populate args(1..N), return N
        ;   $$argc^STDOS()               — count of $ZCMDLINE arguments
        ;   $$arg^STDOS(i)               — i-th $ZCMDLINE arg (1-indexed; "" out of bounds)
        ;   argv^STDOS(.args)            — populate args(1..N) from $ZCMDLINE
        ;   $$cwd^STDOS()                — current working directory (from $PWD)
        ;   $$user^STDOS()               — current username (from $USER)
        ;   $$hostname^STDOS()           — host name (from $HOSTNAME; may be "")
        ;   exit^STDOS(rc)               — terminate the process with exit code rc
        ;
        ; Argument splitting in v1 is whitespace-only — runs of spaces are
        ; collapsed to a single separator and leading / trailing whitespace
        ; is dropped. Quote handling (single and double quotes preserving
        ; embedded spaces) lands in v0.2.y when STDARGS' quote-aware
        ; tokeniser is back-ported. For now, callers that need quote-aware
        ; parsing should pre-tokenise via the shell or use STDARGS directly.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
env(name)       ; Return the value of environment variable `name`, or "" if unset.
        ; doc: Empty `name` returns "" without consulting the environment.
        ; doc: Example: write $$env^STDOS("HOME")
        if name="" quit ""
        quit $ztrnlnm(name)
        ;
pid()   ; Return the current process ID as an integer.
        ; doc: Equivalent to YDB's $J / $JOB special variable.
        ; doc: Example: write $$pid^STDOS()  ; e.g. 12345
        quit +$job
        ;
cmdline()       ; Return the raw $ZCMDLINE string.
        ; doc: This is the whole command-line tail (post-`-run ENTRY`) as
        ; doc: one un-tokenised string. Use argc/arg/argv for split access.
        ; doc: Example: write $$cmdline^STDOS()
        quit $zcmdline
        ;
splitArgs(s,args)       ; Tokenise `s` on whitespace; populate args(1..N); return N.
        ; doc: Runs of spaces collapse; leading and trailing whitespace
        ; doc: are dropped. Tab and LF are NOT treated as separators in v1
        ; doc: (cmdline tails rarely contain them). Empty input yields 0.
        ; doc: Example: set n=$$splitArgs^STDOS("a b c",.args)  ; args(1..3)
        kill args
        new trimmed,n,i,token,start
        if s="" quit 0
        ; Trim leading and trailing spaces.
        set trimmed=s
        for  quit:$extract(trimmed,1)'=" "  set trimmed=$extract(trimmed,2,$length(trimmed))
        for  quit:$extract(trimmed,$length(trimmed))'=" "  set trimmed=$extract(trimmed,1,$length(trimmed)-1)
        if trimmed="" quit 0
        ; Collapse runs of spaces and split via $piece.
        for  quit:trimmed'["  "  set trimmed=$$replaceDouble(trimmed)
        set n=$length(trimmed," ")
        for i=1:1:n  set args(i)=$piece(trimmed," ",i)
        quit n
        ;
argc()  ; Return the number of $ZCMDLINE arguments.
        ; doc: Example: if $$argc^STDOS()<2 do usage^MYAPP
        new args
        quit $$splitArgs($zcmdline,.args)
        ;
arg(i)  ; Return the i-th $ZCMDLINE argument (1-indexed); "" if out of bounds.
        ; doc: Example: set inputPath=$$arg^STDOS(1)
        new args,n
        if i<1 quit ""
        set n=$$splitArgs($zcmdline,.args)
        if i>n quit ""
        quit args(i)
        ;
argv(args)      ; Populate args(1..N) from $ZCMDLINE; N is the implicit return.
        ; doc: Example: do argv^STDOS(.args)
        new n
        kill args
        set n=$$splitArgs($zcmdline,.args)
        quit
        ;
cwd()   ; Return the current working directory (from $PWD).
        ; doc: For container environments where $PWD is unset, this returns
        ; doc: ""; callers that need stat-based getcwd() should wait on the
        ; doc: $ZF→getcwd(2) callout backend.
        ; doc: Example: write $$cwd^STDOS()  ; "/home/user/project"
        quit $ztrnlnm("PWD")
        ;
user()  ; Return the current username (from $USER).
        ; doc: Falls back to $LOGNAME if $USER is unset (System V convention).
        ; doc: Returns "" only if neither is set.
        ; doc: Example: write $$user^STDOS()  ; "alice"
        new u
        set u=$ztrnlnm("USER")
        if u="" set u=$ztrnlnm("LOGNAME")
        quit u
        ;
hostname()      ; Return the host name (from $HOSTNAME) or "" if unset.
        ; doc: $HOSTNAME is exported by some shells (bash) but stripped in
        ; doc: minimal containers; callers that always need a value should
        ; doc: wait on the $ZF→gethostname(2) callout backend.
        ; doc: Example: write $$hostname^STDOS()  ; "vista-meta-1"
        quit $ztrnlnm("HOSTNAME")
        ;
exit(rc)        ; Terminate the YDB process with exit code rc (default 0).
        ; doc: Implemented via ZHALT. The process exits immediately; no
        ; doc: $ETRAP fires, no cleanup runs, no further M code executes.
        ; doc: Example: do exit^STDOS(2)  ; rc=2 to the calling shell
        zhalt $get(rc,0)
        ;
        ; ---------- internal helpers ----------
        ;
replaceDouble(s)        ; Collapse one occurrence of "  " (two spaces) to " ".
        ; doc: Internal — driven by splitArgs's run-collapse loop. The loop
        ; doc: re-checks containment so multi-run collapse converges in
        ; doc: O(log n) iterations.
        new before,after
        set before=$piece(s,"  ",1)
        set after=$piece(s,"  ",2,$length(s,"  "))
        quit before_" "_after
