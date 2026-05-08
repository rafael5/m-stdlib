STDENV  ; m-stdlib — .env file loader with typed accessors.
        ;
        ; Public extrinsics:
        ;   $$parse^STDENV(text, .env)            — parse .env-formatted text
        ;   $$parseFile^STDENV(path, .env)        — readFile then parse
        ;   $$valid^STDENV(text)                  — predicate (parse without populate)
        ;   $$has^STDENV(.env, key)               — 1 iff key was set
        ;   $$get^STDENV(.env, key, default)      — string fetch with default
        ;   $$getInt^STDENV(.env, key, default)   — integer; default if missing or non-numeric
        ;   $$getBool^STDENV(.env, key, default)  — bool from {true,yes,on,1} / {false,no,off,0}
        ;   $$getFloat^STDENV(.env, key, default) — float; default if missing or non-numeric
        ;
        ; Format (typical .env subset):
        ;   <line>      ::= <comment> | <blank> | <pair>
        ;   <comment>   ::= "#" .*           (whole-line; trailing not stripped)
        ;   <pair>      ::= <key> "=" <value>
        ;   <key>       ::= [A-Za-z_][A-Za-z0-9_]*
        ;   <value>     ::= <bare> | <dq-string> | <sq-string>
        ;   <bare>      ::= raw chars (whitespace-trimmed)
        ;   <dq-string> ::= "..." with \n \t \r \" \\ escapes
        ;   <sq-string> ::= '...' (no escape processing — POSIX-style)
        ;
        ; Out of scope (queued for v0.x.y under T22):
        ;   - variable substitution (`$VAR` / `${VAR}` references)
        ;   - export prefix (Bash `export FOO=bar`)
        ;   - multi-line values (PEM keys etc.)
        ;   - process-environment integration (write parsed env back into
        ;     $ZTRNLNM space — needs setenv() callout from T15)
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
parse(text,env) ; Parse .env text into env tree; return 1 on success, 0 on parse error.
        ; doc: @param text    string  .env-formatted text
        ; doc: @param env     array   by-ref local; killed then populated as env(KEY)=value
        ; doc: @returns       bool    1 on success; 0 on parse error
        ; doc: @example       do  set rc=$$parse^STDENV(text,.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$parseFile^STDENV, $$valid^STDENV
        ; doc: On failure, env is left in whatever partial state the parse achieved.
        kill env
        new n,i,line,trimmed,key,raw,value,rc
        set rc=1
        set n=$length(text,$char(10))
        for i=1:1:n quit:'rc  do
        . set line=$piece(text,$char(10),i)
        . if $extract(line,$length(line))=$char(13) set line=$extract(line,1,$length(line)-1)
        . set trimmed=$$trimWs(line)
        . if trimmed="" quit
        . if $extract(trimmed,1)="#" quit
        . do parsePair(trimmed,.env,.rc)
        quit rc
        ;
parseFile(path,env)     ; Read path via STDFS and parse the contents.
        ; doc: @param path    string  filesystem path to a .env file
        ; doc: @param env     array   by-ref local; populated as env(KEY)=value
        ; doc: @returns       bool    1 on success; 0 if file is missing or parse fails
        ; doc: @raises        U-STDFS-OPEN-FAIL  could not read `path` (propagated from STDFS)
        ; doc: @example       do  set rc=$$parseFile^STDENV(".env",.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$parse^STDENV
        ; doc: A missing file returns 0 without raising; an unreadable file raises.
        new text
        if '$$exists^STDFS(path) quit 0
        set text=$$readFile^STDFS(path)
        quit $$parse(text,.env)
        ;
valid(text)     ; Return 1 iff text is parseable as .env. Discards the result.
        ; doc: @param text    string  candidate .env text
        ; doc: @returns       bool    1 iff parseable; 0 otherwise
        ; doc: @example       write $$valid^STDENV(".env line\nA=1")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$parse^STDENV
        new tmp
        quit $$parse(text,.tmp)
        ;
has(env,key)    ; Return 1 iff key is defined in env; else 0.
        ; doc: @param env     array   by-ref env tree from $$parse^STDENV
        ; doc: @param key     string  env key
        ; doc: @returns       bool    1 iff key is defined; 0 otherwise
        ; doc: @example       if $$has^STDENV(.cfg,"DATABASE_URL") ...
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$get^STDENV
        quit $select($data(env(key)):1,1:0)
        ;
get(env,key,default)    ; Return env(key); else default.
        ; doc: @param env       array   by-ref env tree
        ; doc: @param key       string  env key
        ; doc: @param default   string  fallback when key is absent
        ; doc: @returns         string  env(key) or default
        ; doc: @example         set host=$$get^STDENV(.cfg,"HOST","localhost")
        ; doc: @since           v0.3.0
        ; doc: @stable          stable
        ; doc: @see             $$getInt^STDENV, $$getBool^STDENV, $$getFloat^STDENV
        quit $get(env(key),default)
        ;
getInt(env,key,default) ; Return env(key) coerced to integer; default if missing or non-numeric.
        ; doc: @param env       array   by-ref env tree
        ; doc: @param key       string  env key
        ; doc: @param default   int     fallback when key is absent or non-integer
        ; doc: @returns         int     parsed integer or default
        ; doc: @example         set port=$$getInt^STDENV(.cfg,"PORT",8080)
        ; doc: @since           v0.3.0
        ; doc: @stable          stable
        ; doc: @see             $$get^STDENV, $$getFloat^STDENV
        ; doc: Floats and non-numeric values yield the default.
        new v
        if '$data(env(key)) quit default
        set v=env(key)
        if v="" quit default
        if '$$isNumeric(v) quit default
        if v\1'=v quit default  ; reject floats
        quit +v
        ;
getFloat(env,key,default)       ; Return env(key) coerced to float; default if missing or non-numeric.
        ; doc: @param env       array   by-ref env tree
        ; doc: @param key       string  env key
        ; doc: @param default   num     fallback when key is absent or non-numeric
        ; doc: @returns         num     parsed float or default
        ; doc: @example         set ratio=$$getFloat^STDENV(.cfg,"RATIO",1.0)
        ; doc: @since           v0.3.0
        ; doc: @stable          stable
        ; doc: @see             $$get^STDENV, $$getInt^STDENV
        new v
        if '$data(env(key)) quit default
        set v=env(key)
        if v="" quit default
        if '$$isNumeric(v) quit default
        quit +v
        ;
getBool(env,key,default)        ; Return env(key) interpreted as boolean; default if missing or unrecognized.
        ; doc: @param env       array   by-ref env tree
        ; doc: @param key       string  env key
        ; doc: @param default   bool    fallback when key is absent or unrecognized
        ; doc: @returns         bool    parsed boolean or default
        ; doc: @example         set debug=$$getBool^STDENV(.cfg,"DEBUG",0)
        ; doc: @since           v0.3.0
        ; doc: @stable          stable
        ; doc: @see             $$get^STDENV
        ; doc: Truthy: "true" / "yes" / "on" / "1" (case-insensitive).
        ; doc: Falsy:  "false" / "no" / "off" / "0" (case-insensitive).
        new v
        if '$data(env(key)) quit default
        set v=$$lower(env(key))
        if ",true,yes,on,1,"[(","_v_",") quit 1
        if ",false,no,off,0,"[(","_v_",") quit 0
        quit default
        ;
        ; ---------- internal helpers ----------
        ;
parsePair(line,env,rc)  ; Parse a key=value line; populate env or set rc=0.
        ; doc: @internal
        ; doc: Called for non-blank, non-comment lines.
        new eq,key,raw,value
        set value=""
        set eq=$find(line,"=")
        if eq<2 set rc=0 quit
        set key=$$trimWs($extract(line,1,eq-2))
        if '$$validKey(key) set rc=0 quit
        set raw=$$trimWs($extract(line,eq,$length(line)))
        if '$$decodeValue(raw,.value) set rc=0 quit
        set env(key)=value
        quit
        ;
decodeValue(raw,value)  ; Strip optional surrounding quotes and (if double-quoted) decode escapes.
        ; doc: @internal
        ; doc: Empty string is valid.
        new first,last,inner
        if raw="" set value="" quit 1
        set first=$extract(raw,1)
        set last=$extract(raw,$length(raw))
        if first="""",last="""" set inner=$extract(raw,2,$length(raw)-1) quit $$decodeDqString(inner,.value)
        if first="'",last="'" set value=$extract(raw,2,$length(raw)-1) quit 1
        set value=raw
        quit 1
        ;
decodeDqString(raw,value)       ; Decode escapes in a stripped double-quoted value.
        ; doc: @internal
        ; doc: Accepts \n \t \r \" \\.
        new n,i,c,out,prev,ok
        set n=$length(raw),i=1,out="",ok=1
        for  quit:i>n  quit:'ok  do
        . set c=$extract(raw,i)
        . if c="\" do  quit
        . . set i=i+1
        . . if i>n set ok=0 quit
        . . set prev=$extract(raw,i)
        . . if prev="n" set out=out_$char(10),i=i+1 quit
        . . if prev="t" set out=out_$char(9),i=i+1 quit
        . . if prev="r" set out=out_$char(13),i=i+1 quit
        . . if prev="""" set out=out_"""",i=i+1 quit
        . . if prev="\" set out=out_"\",i=i+1 quit
        . . set ok=0
        . set out=out_c,i=i+1
        if 'ok quit 0
        set value=out
        quit 1
        ;
validKey(s)     ; True iff s is a non-empty .env-style key.
        ; doc: @internal
        ; doc: First char letter or _; subsequent letters/digits/_.
        new alpha,first,rest
        if s="" quit 0
        set first=$extract(s,1)
        set alpha="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_"
        if alpha'[first quit 0
        set rest=$extract(s,2,$length(s))
        if rest="" quit 1
        set alpha=alpha_"0123456789"
        quit $select($translate(rest,alpha)="":1,1:0)
        ;
isNumeric(v)    ; True iff v is a non-empty canonical M numeric form.
        ; doc: @internal
        ; doc: Relies on M's `+v=v` canonicalisation.
        if v="" quit 0
        quit $select(+v=v:1,1:0)
        ;
trimWs(s)       ; Strip leading and trailing space/tab.
        ; doc: @internal
        ; doc: STDSTR.trim variant.
        new t
        set t=s
        for  quit:t=""  quit:'($extract(t,1)?1(1" ",1C))  set t=$extract(t,2,$length(t))
        for  quit:t=""  quit:'($extract(t,$length(t))?1(1" ",1C))  set t=$extract(t,1,$length(t)-1)
        quit t
        ;
lower(s)        ; ASCII A-Z → a-z.
        ; doc: @internal
        ; doc: getBool uses this for case-insensitive matching.
        quit $translate(s,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")
