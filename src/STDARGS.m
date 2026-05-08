STDARGS ; m-stdlib — argparse (v0.0.7).
        ;
        ; Public API. The parser handle is a positive integer keyed under
        ; ^STDLIB($job,"stdargs",p,...); state is per-process and per-handle.
        ;
        ;   $$new^STDARGS(prog,desc)                   — alloc parser, return p
        ;   addflag^STDARGS(p,long,short,action,dest)  — register a flag
        ;   addpos^STDARGS(p,name,dest)                — register a positional
        ;   addsub^STDARGS(p,name,subParserHandle)     — register a sub-command
        ;   parse^STDARGS(p,argline,.ns)               — parse argline into ns
        ;   $$help^STDARGS(p)                          — formatted help text
        ;   free^STDARGS(p)                            — drop parser state
        ;
        ; Actions:
        ;   store_true   ns(dest)=1 if flag seen; default 0
        ;   store        ns(dest)=<next token>
        ;   count        ns(dest)+=1 per occurrence; default 0; "-vvv" expands
        ;   append       $increment(k); ns(dest,k)=<next token>
        ;
        ; "--" terminates flag parsing — subsequent tokens are positional even
        ; when they start with "-".
        ;
        ; Sub-commands: when any sub is registered, the first non-flag token
        ; must match a sub name; the remainder is re-parsed by the sub-parser
        ; against the same ns. The chosen sub name is recorded as ns("__sub__").
        ;
        ; Args source: $ZCMDLINE on YDB; an explicit string elsewhere.
        ; Tokenisation is whitespace-only — quoting is the shell's job.
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDARGS-UNKNOWN-ACTION,
        ;   ,U-STDARGS-UNKNOWN-FLAG,
        ;   ,U-STDARGS-UNKNOWN-SUBCOMMAND,
        ;   ,U-STDARGS-MISSING-VALUE,
        ;   ,U-STDARGS-MISSING-POSITIONAL,
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
new(prog,desc)  ; Allocate a fresh parser handle.
        ; doc: @param prog    string  program name (rendered into the help banner)
        ; doc: @param desc    string  one-line description (rendered into the help banner)
        ; doc: @returns       int     positive parser handle; pass to addflag / addpos / addsub / parse / help / free
        ; doc: @example       set p=$$new^STDARGS("widget","frob the widget")
        ; doc: @since         v0.0.7
        ; doc: @stable        stable
        ; doc: @see           do free^STDARGS, do addflag^STDARGS, do addpos^STDARGS, do parse^STDARGS
        new p
        set p=$increment(^STDLIB($job,"stdargs"))
        set ^STDLIB($job,"stdargs",p,"prog")=$get(prog)
        set ^STDLIB($job,"stdargs",p,"desc")=$get(desc)
        quit p
        ;
free(p) ; Release a parser's state.
        ; doc: @param p       int     parser handle from new()
        ; doc: @example       do free^STDARGS(p)
        ; doc: @since         v0.0.7
        ; doc: @stable        stable
        ; doc: @see           $$new^STDARGS
        ; doc: Idempotent. The handle must not be reused after free().
        kill ^STDLIB($job,"stdargs",p)
        quit
        ;
addflag(p,long,short,action,dest)       ; Register a flag.
        ; doc: @param p       int     parser handle from new()
        ; doc: @param long    string  long form including "--" prefix (e.g. "--verbose")
        ; doc: @param short   string  short form including "-" prefix; "" if no short
        ; doc: @param action  string  one of: store_true, store, count, append
        ; doc: @param dest    string  ns(dest) subscript that the parsed value lands in
        ; doc: @raises        U-STDARGS-UNKNOWN-ACTION  `action` is not one of the four documented values
        ; doc: @example       do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        ; doc: @since         v0.0.7
        ; doc: @stable        stable
        ; doc: @see           do addpos^STDARGS, do addsub^STDARGS
        new n
        if action'="store_true",action'="store",action'="count",action'="append" do raise("UNKNOWN-ACTION") quit
        set ^STDLIB($job,"stdargs",p,"flag",long,"short")=$get(short)
        set ^STDLIB($job,"stdargs",p,"flag",long,"action")=action
        set ^STDLIB($job,"stdargs",p,"flag",long,"dest")=dest
        if $get(short)'="" set ^STDLIB($job,"stdargs",p,"short",short)=long
        set n=$increment(^STDLIB($job,"stdargs",p,"flagN"))
        set ^STDLIB($job,"stdargs",p,"flagOrder",n)=long
        quit
        ;
addpos(p,name,dest)     ; Register a positional argument.
        ; doc: @param p       int     parser handle from new()
        ; doc: @param name    string  positional's display name (rendered into help)
        ; doc: @param dest    string  ns(dest) subscript that the value lands in
        ; doc: @example       do addpos^STDARGS(p,"path","path")
        ; doc: @since         v0.0.7
        ; doc: @stable        stable
        ; doc: @see           do addflag^STDARGS, do parse^STDARGS
        ; doc: Positionals are filled in addpos() declaration order.
        new n
        set n=$increment(^STDLIB($job,"stdargs",p,"posN"))
        set ^STDLIB($job,"stdargs",p,"pos",n,"name")=name
        set ^STDLIB($job,"stdargs",p,"pos",n,"dest")=dest
        quit
        ;
addsub(p,name,sub)      ; Register a sub-command -> sub-parser handle.
        ; doc: @param p       int     parser handle from new()
        ; doc: @param name    string  sub-command name (matched against the first non-flag token)
        ; doc: @param sub     int     parser handle from a separate new() call — the sub-parser
        ; doc: @example       do addsub^STDARGS(p,"add",subHandle)
        ; doc: @since         v0.0.7
        ; doc: @stable        stable
        ; doc: @see           do parse^STDARGS
        ; doc: When a parser has any sub-commands, the first non-flag token
        ; doc: must name one — `parse` raises U-STDARGS-UNKNOWN-SUBCOMMAND otherwise.
        set ^STDLIB($job,"stdargs",p,"sub",name)=sub
        quit
        ;
parse(p,argline,ns)     ; Parse argline; populate ns(dest)=value.
        ; doc: @param p       int     parser handle from new()
        ; doc: @param argline string  the raw command line (e.g. $ZCMDLINE on YDB)
        ; doc: @param ns      array   by-ref local; populated as ns(dest)=value
        ; doc: @raises        U-STDARGS-UNKNOWN-FLAG        token starts with "-" but isn't a registered flag
        ; doc: @raises        U-STDARGS-UNKNOWN-SUBCOMMAND  first non-flag token doesn't match any addsub() name
        ; doc: @raises        U-STDARGS-MISSING-VALUE       a `store` / `append` flag has no value token after it
        ; doc: @raises        U-STDARGS-MISSING-POSITIONAL  a registered positional was not supplied
        ; doc: @example       do parse^STDARGS(p,$zcmdline,.ns)
        ; doc: @since         v0.0.7
        ; doc: @stable        stable
        ; doc: @see           $$help^STDARGS
        ; doc: ns is by-reference. On parse error sets $ECODE to one of the
        ; doc: documented codes; otherwise returns silently.
        do initDefaults(p,.ns)
        do walk(p,$get(argline),.ns)
        do checkPositionals(p,.ns)
        quit
        ;
help(p) ; Return formatted help text.
        ; doc: @param p       int     parser handle from new()
        ; doc: @returns       string  multi-line help banner — usage line, description, flags, positionals, commands
        ; doc: @example       write $$help^STDARGS(p)
        ; doc: @since         v0.0.7
        ; doc: @stable        stable
        ; doc: @see           $$new^STDARGS, do parse^STDARGS
        ; doc: Lists usage line, description, then flags, positionals, commands.
        new out,prog,desc,n,long,short,name,sub
        set prog=$get(^STDLIB($job,"stdargs",p,"prog"))
        set desc=$get(^STDLIB($job,"stdargs",p,"desc"))
        set out="usage: "_prog_$char(10)
        if desc'="" set out=out_$char(10)_desc_$char(10)
        if $data(^STDLIB($job,"stdargs",p,"flagOrder")) do
        . set out=out_$char(10)_"flags:"_$char(10)
        . set n=0
        . for  set n=$order(^STDLIB($job,"stdargs",p,"flagOrder",n)) quit:n=""  do
        . . set long=^STDLIB($job,"stdargs",p,"flagOrder",n)
        . . set short=$get(^STDLIB($job,"stdargs",p,"flag",long,"short"))
        . . set out=out_"  "_long
        . . if short'="" set out=out_", "_short
        . . set out=out_$char(10)
        if $data(^STDLIB($job,"stdargs",p,"pos")) do
        . set out=out_$char(10)_"positional:"_$char(10)
        . set n=0
        . for  set n=$order(^STDLIB($job,"stdargs",p,"pos",n)) quit:n=""  do
        . . set name=$get(^STDLIB($job,"stdargs",p,"pos",n,"name"))
        . . set out=out_"  "_name_$char(10)
        if $data(^STDLIB($job,"stdargs",p,"sub")) do
        . set out=out_$char(10)_"commands:"_$char(10)
        . set sub=""
        . for  set sub=$order(^STDLIB($job,"stdargs",p,"sub",sub)) quit:sub=""  do
        . . set out=out_"  "_sub_$char(10)
        quit out
        ;
        ; ---------- internal: defaults / positionals ----------
        ;
initDefaults(p,ns)      ; Pre-fill ns(dest) for store_true and count flags.
        ; doc: @internal
        ; doc: Absent flags are observable as 0 rather than undef.
        new n,long,action,dest
        set n=0
        for  set n=$order(^STDLIB($job,"stdargs",p,"flagOrder",n)) quit:n=""  do
        . set long=^STDLIB($job,"stdargs",p,"flagOrder",n)
        . set action=$get(^STDLIB($job,"stdargs",p,"flag",long,"action"))
        . set dest=$get(^STDLIB($job,"stdargs",p,"flag",long,"dest"))
        . if action="store_true" set ns(dest)=0
        . if action="count" set ns(dest)=0
        quit
        ;
checkPositionals(p,ns)  ; Confirm every registered positional was filled.
        ; doc: @internal
        ; doc: Sets $ECODE on first missing positional.
        new n,dest
        set n=0
        for  set n=$order(^STDLIB($job,"stdargs",p,"pos",n)) quit:n=""  do
        . set dest=$get(^STDLIB($job,"stdargs",p,"pos",n,"dest"))
        . if '$data(ns(dest)) do raise("MISSING-POSITIONAL")
        quit
        ;
        ; ---------- internal: walker ----------
        ;
walk(p,argline,ns)      ; Walk tokens of argline; dispatch flags / positionals / sub.
        ; doc: @internal
        ; doc: Handles "--" terminator, sub-commands, grouped shorts.
        new tokens,n,i,tok,terminator,posIdx,subname,subRest,subP,j
        do tokenize(argline,.tokens,.n)
        ; Sub-command dispatch: any sub registered → first token must match.
        if $data(^STDLIB($job,"stdargs",p,"sub")),n>0 do  quit
        . set subname=tokens(1)
        . if '$data(^STDLIB($job,"stdargs",p,"sub",subname)) do raise("UNKNOWN-SUBCOMMAND") quit
        . set subP=^STDLIB($job,"stdargs",p,"sub",subname)
        . set ns("__sub__")=subname
        . set subRest=""
        . for j=2:1:n set subRest=subRest_$select(j=2:"",1:" ")_tokens(j)
        . do parse(subP,subRest,.ns)
        ; No sub-command match path — linear flag/positional walk.
        set terminator=0,posIdx=0,i=0
        for  quit:i'<n  do  quit:$ecode'=""
        . set i=i+1
        . set tok=tokens(i)
        . if 'terminator,tok="--" set terminator=1 quit
        . if 'terminator,$extract(tok,1,2)="--" do handleLong(p,tok,.ns,.tokens,.i,n) quit
        . if 'terminator,$extract(tok,1)="-",$length(tok)>1 do handleShort(p,tok,.ns,.tokens,.i,n) quit
        . set posIdx=posIdx+1
        . do assignPositional(p,posIdx,tok,.ns)
        quit
        ;
tokenize(argline,tokens,n)      ; Split argline on whitespace; populate tokens(1..n).
        ; doc: @internal
        ; doc: Runs of whitespace collapse; leading/trailing trim.
        new pos,len,c,buf
        set n=0,buf="",pos=1,len=$length(argline)
        for  quit:pos>len  do
        . set c=$extract(argline,pos)
        . if (c=" ")!(c=$char(9)) do  set pos=pos+1 quit
        . . if buf'="" set n=n+1,tokens(n)=buf,buf=""
        . set buf=buf_c,pos=pos+1
        if buf'="" set n=n+1,tokens(n)=buf
        quit
        ;
handleLong(p,tok,ns,tokens,i,n) ; Process a "--name" token.
        ; doc: @internal
        ; doc: Dispatches by action; advances i for store/append.
        new long,action,dest,k
        set long=tok
        if '$data(^STDLIB($job,"stdargs",p,"flag",long,"action")) do raise("UNKNOWN-FLAG") quit
        set action=^STDLIB($job,"stdargs",p,"flag",long,"action")
        set dest=^STDLIB($job,"stdargs",p,"flag",long,"dest")
        if action="store_true" set ns(dest)=1 quit
        if action="count" set ns(dest)=$get(ns(dest))+1 quit
        if action="store" do  quit
        . if i>=n do raise("MISSING-VALUE") quit
        . set i=i+1,ns(dest)=tokens(i)
        if action="append" do  quit
        . if i>=n do raise("MISSING-VALUE") quit
        . set i=i+1
        . set k=$increment(ns(dest,0))
        . set ns(dest,k)=tokens(i)
        quit
        ;
handleShort(p,tok,ns,tokens,i,n)        ; Process a "-x" or grouped "-xyz" token.
        ; doc: @internal
        ; doc: Single char dispatches by action; multi-char body requires
        ; doc: every char to map to a count flag (-vvv form).
        new body,len,j,short,long,action,dest,k
        set body=$extract(tok,2,$length(tok)),len=$length(body)
        if len=1 do  quit
        . set short=tok
        . if '$data(^STDLIB($job,"stdargs",p,"short",short)) do raise("UNKNOWN-FLAG") quit
        . set long=^STDLIB($job,"stdargs",p,"short",short)
        . set action=^STDLIB($job,"stdargs",p,"flag",long,"action")
        . set dest=^STDLIB($job,"stdargs",p,"flag",long,"dest")
        . if action="store_true" set ns(dest)=1 quit
        . if action="count" set ns(dest)=$get(ns(dest))+1 quit
        . if action="store" do  quit
        . . if i>=n do raise("MISSING-VALUE") quit
        . . set i=i+1,ns(dest)=tokens(i)
        . if action="append" do  quit
        . . if i>=n do raise("MISSING-VALUE") quit
        . . set i=i+1
        . . set k=$increment(ns(dest,0))
        . . set ns(dest,k)=tokens(i)
        for j=1:1:len  quit:$ecode'=""  do
        . set short="-"_$extract(body,j)
        . if '$data(^STDLIB($job,"stdargs",p,"short",short)) do raise("UNKNOWN-FLAG") quit
        . set long=^STDLIB($job,"stdargs",p,"short",short)
        . set action=^STDLIB($job,"stdargs",p,"flag",long,"action")
        . set dest=^STDLIB($job,"stdargs",p,"flag",long,"dest")
        . if action'="count" do raise("UNKNOWN-FLAG") quit
        . set ns(dest)=$get(ns(dest))+1
        quit
        ;
assignPositional(p,posIdx,tok,ns)       ; Assign tok to the posIdx-th positional.
        ; doc: @internal
        ; doc: Extra tokens past the last declared positional are silently
        ; doc: ignored at v0.0.7 (no varargs / nargs+ yet).
        new dest
        if '$data(^STDLIB($job,"stdargs",p,"pos",posIdx,"dest")) quit
        set dest=^STDLIB($job,"stdargs",p,"pos",posIdx,"dest")
        set ns(dest)=tok
        quit
        ;
raise(err)      ; Raise a U-STDARGS-<err> error code via a fresh frame.
        ; doc: @internal
        ; doc: Fires the caller's $ETRAP from a nested frame so the trap's
        ; doc: QUIT-with-empty-$ECODE resumes execution at a known safe
        ; doc: point in the caller, not in the middle of post-error
        ; doc: cleanup. Same pattern as STDREGEX.raise (added in L12 Pass B).
        set $ecode=",U-STDARGS-"_err_","
        quit
        ;
