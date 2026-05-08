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
        ; doc: @param name    string  environment variable name
        ; doc: @returns       string  value, or "" if `name` is empty or unset
        ; doc: @example       write $$env^STDOS("HOME")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$user^STDOS, $$cwd^STDOS, $$hostname^STDOS
        if name="" quit ""
        quit $ztrnlnm(name)
        ;
pid()   ; Return the current process ID as an integer.
        ; doc: @returns       int     process ID
        ; doc: @example       write $$pid^STDOS()  ; e.g. 12345
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: Equivalent to YDB's $J / $JOB special variable.
        quit +$job
        ;
cmdline()       ; Return the raw $ZCMDLINE string.
        ; doc: @returns       string  whole command-line tail (post-`-run ENTRY`), un-tokenised
        ; doc: @example       write $$cmdline^STDOS()
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$argc^STDOS, $$arg^STDOS, do argv^STDOS, $$splitArgs^STDOS
        quit $zcmdline
        ;
splitArgs(s,args)       ; Tokenise `s` on whitespace; populate args(1..N); return N.
        ; doc: @param s       string  input string
        ; doc: @param args    array   by-ref local; killed then populated as args(1..N)
        ; doc: @returns       int     number of tokens
        ; doc: @example       set n=$$splitArgs^STDOS("a b c",.args)  ; args(1..3)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           do argv^STDOS, $$cmdline^STDOS
        ; doc: Runs of spaces collapse; leading and trailing whitespace are
        ; doc: dropped. Tab and LF are NOT treated as separators in v1
        ; doc: (cmdline tails rarely contain them). Empty input yields 0.
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
        ; doc: @returns       int     count of whitespace-separated tokens in $ZCMDLINE
        ; doc: @example       if $$argc^STDOS()<2 do usage^MYAPP
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$arg^STDOS, do argv^STDOS
        new args
        quit $$splitArgs($zcmdline,.args)
        ;
arg(i)  ; Return the i-th $ZCMDLINE argument (1-indexed); "" if out of bounds.
        ; doc: @param i       int     1-based argument index
        ; doc: @returns       string  the i-th token, or "" if i is out of bounds
        ; doc: @example       set inputPath=$$arg^STDOS(1)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$argc^STDOS, do argv^STDOS
        new args,n
        if i<1 quit ""
        set n=$$splitArgs($zcmdline,.args)
        if i>n quit ""
        quit args(i)
        ;
argv(args)      ; Populate args(1..N) from $ZCMDLINE; N is the implicit return.
        ; doc: @param args    array   by-ref local; killed then populated from $ZCMDLINE tokens
        ; doc: @example       do argv^STDOS(.args)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$argc^STDOS, $$arg^STDOS, $$splitArgs^STDOS
        new n
        kill args
        set n=$$splitArgs($zcmdline,.args)
        quit
        ;
cwd()   ; Return the current working directory (from $PWD).
        ; doc: @returns       path    value of $PWD; "" if unset
        ; doc: @example       write $$cwd^STDOS()  ; "/home/user/project"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$env^STDOS
        ; doc: For container environments where $PWD is unset, this returns
        ; doc: ""; callers that need stat-based getcwd() should wait on the
        ; doc: $ZF→getcwd(2) callout backend.
        quit $ztrnlnm("PWD")
        ;
user()  ; Return the current username (from $USER).
        ; doc: @returns       string  $USER if set; otherwise $LOGNAME; "" if neither
        ; doc: @example       write $$user^STDOS()  ; "alice"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$env^STDOS, $$hostname^STDOS
        ; doc: Falls back to $LOGNAME if $USER is unset (System V convention).
        new u
        set u=$ztrnlnm("USER")
        if u="" set u=$ztrnlnm("LOGNAME")
        quit u
        ;
hostname()      ; Return the host name (from $HOSTNAME) or "" if unset.
        ; doc: @returns       string  value of $HOSTNAME; "" if unset
        ; doc: @example       write $$hostname^STDOS()  ; "vista-meta-1"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$env^STDOS, $$user^STDOS
        ; doc: $HOSTNAME is exported by some shells (bash) but stripped in
        ; doc: minimal containers; callers that always need a value should
        ; doc: wait on the $ZF→gethostname(2) callout backend.
        quit $ztrnlnm("HOSTNAME")
        ;
exit(rc)        ; Terminate the YDB process with exit code rc (default 0).
        ; doc: @param rc      int     exit code; defaults to 0 if unsupplied
        ; doc: @example       do exit^STDOS(2)  ; rc=2 to the calling shell
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: Implemented via ZHALT. The process exits immediately; no
        ; doc: $ETRAP fires, no cleanup runs, no further M code executes.
        zhalt $get(rc,0)
        ;
        ; ---------- internal helpers ----------
        ;
replaceDouble(s)        ; Collapse one occurrence of "  " (two spaces) to " ".
        ; doc: @internal
        ; doc: Driven by splitArgs's run-collapse loop. The loop re-checks
        ; doc: containment so multi-run collapse converges in O(log n)
        ; doc: iterations.
        new before,after
        set before=$piece(s,"  ",1)
        set after=$piece(s,"  ",2,$length(s,"  "))
        quit before_" "_after
