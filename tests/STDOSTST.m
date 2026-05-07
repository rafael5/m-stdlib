STDOSTST        ; Test suite for STDOS (v0.2.x — was Table 2 Pri 3, Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tEnvReturnsPathValue(.pass,.fail)
        do tEnvReturnsEmptyForUnset(.pass,.fail)
        do tEnvReturnsEmptyForEmptyName(.pass,.fail)
        do tPidIsPositiveInt(.pass,.fail)
        do tPidEqualsDollarJ(.pass,.fail)
        do tCmdlineMatchesZcmdline(.pass,.fail)
        do tSplitArgsEmpty(.pass,.fail)
        do tSplitArgsSingle(.pass,.fail)
        do tSplitArgsThree(.pass,.fail)
        do tSplitArgsCollapsesRuns(.pass,.fail)
        do tSplitArgsLeadingTrailingSpace(.pass,.fail)
        do tArgcMatchesCmdlineSplit(.pass,.fail)
        do tArgvMatchesCmdlineSplit(.pass,.fail)
        do tArgFetchesByIndex(.pass,.fail)
        do tArgOutOfBoundsReturnsEmpty(.pass,.fail)
        do tCwdIsNonEmpty(.pass,.fail)
        do tCwdIsAbsolutePath(.pass,.fail)
        do tUserIsNonEmpty(.pass,.fail)
        do tHostnameNeverRaises(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- env ----
tEnvReturnsPathValue(pass,fail) ;@TEST "env('PATH') returns a non-empty string"
        new pathVal
        set pathVal=$$env^STDOS("PATH")
        do true^STDASSERT(.pass,.fail,pathVal'="","PATH is set")
        do contains^STDASSERT(.pass,.fail,pathVal,"/","PATH contains a slash")
        quit
        ;
tEnvReturnsEmptyForUnset(pass,fail)     ;@TEST "env('UNSET_VAR_...') returns the empty string"
        do eq^STDASSERT(.pass,.fail,$$env^STDOS("M_STDLIB_DEFINITELY_UNSET_2026"),"","unset var returns empty")
        quit
        ;
tEnvReturnsEmptyForEmptyName(pass,fail) ;@TEST "env('') returns the empty string"
        do eq^STDASSERT(.pass,.fail,$$env^STDOS(""),"","empty name returns empty")
        quit
        ;
        ; ---- pid ----
tPidIsPositiveInt(pass,fail)    ;@TEST "pid() returns a positive integer"
        new processId
        set processId=$$pid^STDOS()
        do true^STDASSERT(.pass,.fail,processId>0,"pid is positive")
        do eq^STDASSERT(.pass,.fail,processId\1,processId,"pid is integer")
        quit
        ;
tPidEqualsDollarJ(pass,fail)    ;@TEST "pid() agrees with $J"
        do eq^STDASSERT(.pass,.fail,$$pid^STDOS(),+$job,"pid matches $J")
        quit
        ;
        ; ---- cmdline ----
tCmdlineMatchesZcmdline(pass,fail)      ;@TEST "cmdline() returns the raw $ZCMDLINE string"
        ; m-lint: disable-next-line=M-MOD-022
        do eq^STDASSERT(.pass,.fail,$$cmdline^STDOS(),$zcmdline,"cmdline matches $ZCMDLINE")
        quit
        ;
        ; ---- splitArgs ----
tSplitArgsEmpty(pass,fail)      ;@TEST "splitArgs('') populates 0 args"
        new args,n
        set n=$$splitArgs^STDOS("",.args)
        do eq^STDASSERT(.pass,.fail,n,0,"empty cmdline yields 0 args")
        do false^STDASSERT(.pass,.fail,$data(args(1)),"args(1) undefined")
        quit
        ;
tSplitArgsSingle(pass,fail)     ;@TEST "splitArgs('solo') yields one arg"
        new args,n
        set n=$$splitArgs^STDOS("solo",.args)
        do eq^STDASSERT(.pass,.fail,n,1,"one arg")
        do eq^STDASSERT(.pass,.fail,$get(args(1)),"solo","args(1)=solo")
        quit
        ;
tSplitArgsThree(pass,fail)      ;@TEST "splitArgs('a b c') yields three args"
        new args,n
        set n=$$splitArgs^STDOS("a b c",.args)
        do eq^STDASSERT(.pass,.fail,n,3,"three args")
        do eq^STDASSERT(.pass,.fail,$get(args(1)),"a","args(1)=a")
        do eq^STDASSERT(.pass,.fail,$get(args(2)),"b","args(2)=b")
        do eq^STDASSERT(.pass,.fail,$get(args(3)),"c","args(3)=c")
        quit
        ;
tSplitArgsCollapsesRuns(pass,fail)      ;@TEST "splitArgs('a   b') treats runs of spaces as one separator"
        new args,n
        set n=$$splitArgs^STDOS("a   b",.args)
        do eq^STDASSERT(.pass,.fail,n,2,"two args after collapse")
        do eq^STDASSERT(.pass,.fail,$get(args(1)),"a","args(1)")
        do eq^STDASSERT(.pass,.fail,$get(args(2)),"b","args(2)")
        quit
        ;
tSplitArgsLeadingTrailingSpace(pass,fail)       ;@TEST "splitArgs('  alpha beta  ') ignores boundary whitespace"
        new args,n
        set n=$$splitArgs^STDOS("  alpha beta  ",.args)
        do eq^STDASSERT(.pass,.fail,n,2,"two args, no boundary blanks")
        do eq^STDASSERT(.pass,.fail,$get(args(1)),"alpha","args(1)")
        do eq^STDASSERT(.pass,.fail,$get(args(2)),"beta","args(2)")
        quit
        ;
        ; ---- argc / arg / argv against $ZCMDLINE ----
tArgcMatchesCmdlineSplit(pass,fail)     ;@TEST "argc() agrees with splitArgs($ZCMDLINE)"
        ; m-lint: disable-next-line=M-MOD-022
        new args,n  set n=$$splitArgs^STDOS($zcmdline,.args)
        do eq^STDASSERT(.pass,.fail,$$argc^STDOS(),n,"argc matches split count")
        quit
        ;
tArgvMatchesCmdlineSplit(pass,fail)     ;@TEST "argv() populates the same array as splitArgs($ZCMDLINE)"
        new args,argv,i,n
        ; m-lint: disable-next-line=M-MOD-022
        set n=$$splitArgs^STDOS($zcmdline,.args)
        do argv^STDOS(.argv)
        for i=1:1:n  do eq^STDASSERT(.pass,.fail,$get(argv(i)),$get(args(i)),"argv("_i_") matches")
        quit
        ;
tArgFetchesByIndex(pass,fail)   ;@TEST "arg(i) returns the i-th element of splitArgs($ZCMDLINE)"
        new args,i,n
        ; m-lint: disable-next-line=M-MOD-022
        set n=$$splitArgs^STDOS($zcmdline,.args)
        if n=0 quit  ; no args → nothing to fetch
        for i=1:1:n  do eq^STDASSERT(.pass,.fail,$$arg^STDOS(i),$get(args(i)),"arg("_i_") matches")
        quit
        ;
tArgOutOfBoundsReturnsEmpty(pass,fail)  ;@TEST "arg(0) and arg(largeIndex) return ''"
        do eq^STDASSERT(.pass,.fail,$$arg^STDOS(0),"","arg(0) empty")
        do eq^STDASSERT(.pass,.fail,$$arg^STDOS(99999),"","arg(99999) empty")
        do eq^STDASSERT(.pass,.fail,$$arg^STDOS(-3),"","arg(-3) empty")
        quit
        ;
        ; ---- cwd ----
tCwdIsNonEmpty(pass,fail)       ;@TEST "cwd() returns a non-empty string"
        do true^STDASSERT(.pass,.fail,$$cwd^STDOS()'="","cwd non-empty")
        quit
        ;
tCwdIsAbsolutePath(pass,fail)   ;@TEST "cwd() returns a path starting with /"
        do eq^STDASSERT(.pass,.fail,$extract($$cwd^STDOS(),1),"/","cwd is absolute")
        quit
        ;
        ; ---- user ----
tUserIsNonEmpty(pass,fail)      ;@TEST "user() returns a non-empty string"
        do true^STDASSERT(.pass,.fail,$$user^STDOS()'="","user non-empty")
        quit
        ;
        ; ---- hostname ----
tHostnameNeverRaises(pass,fail) ;@TEST "hostname() returns a string (possibly empty in stripped containers)"
        ; HOSTNAME may be unset inside containerised YDB (e.g. vista-meta);
        ; the contract is "never raises", not "always non-empty".
        new hostName
        set hostName=$$hostname^STDOS()
        do true^STDASSERT(.pass,.fail,$length(hostName)'<0,"hostname returns a string")
        quit
