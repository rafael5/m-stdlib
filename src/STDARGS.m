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
        ; doc: Returns a positive integer; pass to addflag/addpos/addsub/parse/help/free.
        ; doc: Example: set p=$$new^STDARGS("widget","frob the widget")
        new p
        set p=$increment(^STDLIB($job,"stdargs"))
        set ^STDLIB($job,"stdargs",p,"prog")=$get(prog)
        set ^STDLIB($job,"stdargs",p,"desc")=$get(desc)
        quit p
        ;
free(p) ; Release a parser's state.
        ; doc: Idempotent. The handle must not be reused after free().
        ; doc: Example: do free^STDARGS(p)
        kill ^STDLIB($job,"stdargs",p)
        quit
        ;
addflag(p,long,short,action,dest)       ; Register a flag.
        ; doc: action ∈ {store_true, store, count, append}. Unknown action
        ; doc: sets $ECODE to ,U-STDARGS-UNKNOWN-ACTION,. short may be empty.
        ; doc: Example: do addflag^STDARGS(p,"--verbose","-v","store_true","verbose")
        new n
        if action'="store_true",action'="store",action'="count",action'="append" set $ecode=",U-STDARGS-UNKNOWN-ACTION," quit
        set ^STDLIB($job,"stdargs",p,"flag",long,"short")=$get(short)
        set ^STDLIB($job,"stdargs",p,"flag",long,"action")=action
        set ^STDLIB($job,"stdargs",p,"flag",long,"dest")=dest
        if $get(short)'="" set ^STDLIB($job,"stdargs",p,"short",short)=long
        set n=$increment(^STDLIB($job,"stdargs",p,"flagN"))
        set ^STDLIB($job,"stdargs",p,"flagOrder",n)=long
        quit
        ;
addpos(p,name,dest)     ; Register a positional argument.
        ; doc: Positionals are filled in addpos() declaration order.
        ; doc: Example: do addpos^STDARGS(p,"path","path")
        new n
        set n=$increment(^STDLIB($job,"stdargs",p,"posN"))
        set ^STDLIB($job,"stdargs",p,"pos",n,"name")=name
        set ^STDLIB($job,"stdargs",p,"pos",n,"dest")=dest
        quit
        ;
addsub(p,name,sub)      ; Register a sub-command -> sub-parser handle.
        ; doc: When a parser has any sub-commands, the first non-flag token
        ; doc: must name one (or $ECODE U-STDARGS-UNKNOWN-SUBCOMMAND fires).
        ; doc: Example: do addsub^STDARGS(p,"add",subHandle)
        set ^STDLIB($job,"stdargs",p,"sub",name)=sub
        quit
        ;
parse(p,argline,ns)     ; Parse argline; populate ns(dest)=value.
        ; doc: ns is by-reference. On parse error sets $ECODE to one of the
        ; doc: documented codes; otherwise returns silently.
        ; doc: Example: do parse^STDARGS(p,$zcmdline,.ns)
        do initDefaults(p,.ns)
        do walk(p,$get(argline),.ns)
        do checkPositionals(p,.ns)
        quit
        ;
help(p) ; Return formatted help text.
        ; doc: Lists usage line, description, then flags, positionals, commands.
        ; doc: Example: write $$help^STDARGS(p)
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
        ; doc: Internal — so absent flags are observable as 0 rather than undef.
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
        ; doc: Internal — sets $ECODE on first missing positional.
        new n,dest
        set n=0
        for  set n=$order(^STDLIB($job,"stdargs",p,"pos",n)) quit:n=""  do
        . set dest=$get(^STDLIB($job,"stdargs",p,"pos",n,"dest"))
        . if '$data(ns(dest)) set $ecode=",U-STDARGS-MISSING-POSITIONAL,"
        quit
        ;
        ; ---------- internal: walker ----------
        ;
walk(p,argline,ns)      ; Walk tokens of argline; dispatch flags / positionals / sub.
        ; doc: Internal — handles "--" terminator, sub-commands, grouped shorts.
        new tokens,n,i,tok,terminator,posIdx,subname,subRest,subP,j
        do tokenize(argline,.tokens,.n)
        ; Sub-command dispatch: any sub registered → first token must match.
        if $data(^STDLIB($job,"stdargs",p,"sub")),n>0 do  quit
        . set subname=tokens(1)
        . if '$data(^STDLIB($job,"stdargs",p,"sub",subname)) set $ecode=",U-STDARGS-UNKNOWN-SUBCOMMAND," quit
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
        ; doc: Internal — runs of whitespace collapse; leading/trailing trim.
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
        ; doc: Internal — dispatches by action; advances i for store/append.
        new long,action,dest,k
        set long=tok
        if '$data(^STDLIB($job,"stdargs",p,"flag",long,"action")) set $ecode=",U-STDARGS-UNKNOWN-FLAG," quit
        set action=^STDLIB($job,"stdargs",p,"flag",long,"action")
        set dest=^STDLIB($job,"stdargs",p,"flag",long,"dest")
        if action="store_true" set ns(dest)=1 quit
        if action="count" set ns(dest)=$get(ns(dest))+1 quit
        if action="store" do  quit
        . if i>=n set $ecode=",U-STDARGS-MISSING-VALUE," quit
        . set i=i+1,ns(dest)=tokens(i)
        if action="append" do  quit
        . if i>=n set $ecode=",U-STDARGS-MISSING-VALUE," quit
        . set i=i+1
        . set k=$increment(ns(dest,0))
        . set ns(dest,k)=tokens(i)
        quit
        ;
handleShort(p,tok,ns,tokens,i,n)        ; Process a "-x" or grouped "-xyz" token.
        ; doc: Internal — single char dispatches by action; multi-char body
        ; doc: requires every char to map to a count flag (-vvv form).
        new body,len,j,short,long,action,dest,k
        set body=$extract(tok,2,$length(tok)),len=$length(body)
        if len=1 do  quit
        . set short=tok
        . if '$data(^STDLIB($job,"stdargs",p,"short",short)) set $ecode=",U-STDARGS-UNKNOWN-FLAG," quit
        . set long=^STDLIB($job,"stdargs",p,"short",short)
        . set action=^STDLIB($job,"stdargs",p,"flag",long,"action")
        . set dest=^STDLIB($job,"stdargs",p,"flag",long,"dest")
        . if action="store_true" set ns(dest)=1 quit
        . if action="count" set ns(dest)=$get(ns(dest))+1 quit
        . if action="store" do  quit
        . . if i>=n set $ecode=",U-STDARGS-MISSING-VALUE," quit
        . . set i=i+1,ns(dest)=tokens(i)
        . if action="append" do  quit
        . . if i>=n set $ecode=",U-STDARGS-MISSING-VALUE," quit
        . . set i=i+1
        . . set k=$increment(ns(dest,0))
        . . set ns(dest,k)=tokens(i)
        for j=1:1:len  quit:$ecode'=""  do
        . set short="-"_$extract(body,j)
        . if '$data(^STDLIB($job,"stdargs",p,"short",short)) set $ecode=",U-STDARGS-UNKNOWN-FLAG," quit
        . set long=^STDLIB($job,"stdargs",p,"short",short)
        . set action=^STDLIB($job,"stdargs",p,"flag",long,"action")
        . set dest=^STDLIB($job,"stdargs",p,"flag",long,"dest")
        . if action'="count" set $ecode=",U-STDARGS-UNKNOWN-FLAG," quit
        . set ns(dest)=$get(ns(dest))+1
        quit
        ;
assignPositional(p,posIdx,tok,ns)       ; Assign tok to the posIdx-th positional.
        ; doc: Internal — extra tokens past the last declared positional are
        ; doc: silently ignored at v0.0.7 (no varargs / nargs+ yet).
        new dest
        if '$data(^STDLIB($job,"stdargs",p,"pos",posIdx,"dest")) quit
        set dest=^STDLIB($job,"stdargs",p,"pos",posIdx,"dest")
        set ns(dest)=tok
        quit
