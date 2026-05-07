STDTOML ; m-stdlib — TOML 1.0 parser (deliberately narrow v1 subset).
        ;
        ; Public extrinsics:
        ;   $$parse^STDTOML(text,.root) — parse TOML doc into root tree; return 1/0
        ;   $$valid^STDTOML(text)       — predicate: 1 iff parse succeeds
        ;   $$get^STDTOML(.root,key)    — value lookup; "section.key" addresses tables
        ;   $$type^STDTOML(.root,key)   — "string" / "integer" / "float" / "bool" / ""
        ;
        ; Tree representation:
        ;   root("v",path)              — value (the M scalar after coercion)
        ;   root("t",path)              — type tag ("string"/"integer"/"float"/"bool")
        ;   path is the dotted address: "k" for top-level, "section.k" for sectioned.
        ;
        ; Grammar (TOML 1.0 subset shipped in v1):
        ;   <doc>        ::= (<line> NL)*
        ;   <line>       ::= <blank> | <comment> | <table> | <pair>
        ;   <comment>    ::= "#" .* (whole-line or trailing — stripped before pair parse)
        ;   <table>      ::= "[" <bare-key> "]"
        ;   <pair>       ::= <bare-key> "=" <value>
        ;   <bare-key>   ::= [A-Za-z0-9_-]+
        ;   <value>      ::= <basic-string> | <integer> | <float> | <bool>
        ;   <basic-string> ::= '"' (chars with \n \t \r \" \\ escapes) '"'
        ;   <integer>    ::= "-"? [0-9]+
        ;   <float>      ::= "-"? [0-9]+ "." [0-9]+
        ;   <bool>       ::= "true" | "false"
        ;
        ; Out of scope (queued for v0.x.y under T18):
        ;   - arrays, inline tables, dotted keys, [[array-of-tables]]
        ;   - literal strings ('...'), multi-line strings ("""..." or '''...''')
        ;   - integer literals with underscores, hex/oct/bin int prefixes
        ;   - special floats (inf, -inf, nan)
        ;   - exponent notation in floats (1.5e3)
        ;   - datetime values (TOML offset / local datetime / local date / local time)
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
parse(text,root)        ; Parse TOML text into root tree; return 1 on success, 0 on parse error.
        ; doc: root is by-reference; on failure, root is left in whatever
        ; doc: partial state the parse achieved (caller may want to KILL it).
        ; doc: Example: do  set rc=$$parse^STDTOML(text,.cfg)
        kill root
        new n,i,line,section,trimmed,key,rc
        set section="",rc=1
        ; Split doc on LF; CR stripping happens per-line below.
        set n=$length(text,$char(10))
        for i=1:1:n quit:'rc  do
        . set line=$piece(text,$char(10),i)
        . if $extract(line,$length(line))=$char(13) set line=$extract(line,1,$length(line)-1)
        . set trimmed=$$trimWs(line)
        . if trimmed="" quit
        . if $extract(trimmed,1)="#" quit
        . if $extract(trimmed,1)="[" do  quit
        . . set key=$$parseTable(trimmed)
        . . if key="" set rc=0 quit
        . . set section=key
        . do parsePair(trimmed,section,.root,.rc)
        quit rc
        ;
valid(text)     ; Return 1 iff text parses as valid TOML; else 0.
        ; doc: Same as parse() but discards the resulting tree.
        ; doc: Example: write $$valid^STDTOML("k = 1")  ; 1
        new tmp
        quit $$parse(text,.tmp)
        ;
get(root,key)   ; Return the value at key (dotted path); "" if absent.
        ; doc: For a top-level key just pass the key; for a sectioned value
        ; doc: pass "section.key".
        ; doc: Example: write $$get^STDTOML(.cfg,"server.port")
        if '$data(root("v",key)) quit ""
        quit root("v",key)
        ;
type(root,key)  ; Return the type tag at key, or "" if absent.
        ; doc: Tags are "string" / "integer" / "float" / "bool".
        ; doc: Example: write $$type^STDTOML(.cfg,"server.port")  ; "integer"
        if '$data(root("t",key)) quit ""
        quit root("t",key)
        ;
        ; ---------- internal: line-level dispatch ----------
        ;
parseTable(line)        ; Return the bare-key inside [...] or "" on malformed input.
        ; doc: Internal — called when the trimmed line begins with "[".
        new inner,key
        if $extract(line,$length(line))'="]" quit ""
        set inner=$$trimWs($extract(line,2,$length(line)-1))
        if inner="" quit ""
        if '$$validBareKey(inner) quit ""
        quit inner
        ;
parsePair(line,section,root,rc) ; Parse a key=value line; populate root or set rc=0.
        ; doc: Internal — called for non-blank, non-comment, non-table lines.
        new eq,key,raw,value,vtype,path
        set value="",vtype=""
        set eq=$find(line,"=")
        if eq<2 set rc=0 quit
        set key=$$trimWs($extract(line,1,eq-2))
        if '$$validBareKey(key) set rc=0 quit
        set raw=$$stripTrailingComment($extract(line,eq,$length(line)))
        set raw=$$trimWs(raw)
        if raw="" set rc=0 quit
        if '$$decodeValue(raw,.value,.vtype) set rc=0 quit
        set path=$select(section="":key,1:section_"."_key)
        if $data(root("v",path)) set rc=0 quit
        set root("v",path)=value
        set root("t",path)=vtype
        quit
        ;
        ; ---------- internal: value decoding ----------
        ;
decodeValue(raw,value,vtype)    ; Coerce raw value text into (value, vtype); return 1/0.
        ; doc: Internal — driven by parsePair. raw is whitespace-trimmed.
        if raw="" quit 0
        if $extract(raw,1)="""" quit $$decodeString(raw,.value,.vtype)
        if raw="true" set value=1,vtype="bool" quit 1
        if raw="false" set value=0,vtype="bool" quit 1
        if raw["." quit $$decodeFloat(raw,.value,.vtype)
        quit $$decodeInteger(raw,.value,.vtype)
        ;
decodeString(raw,value,vtype)   ; Decode a TOML basic string literal.
        ; doc: Internal — accepts \n \t \r \" \\ escapes; bare " ends the string.
        new n,i,c,out,prev,ok
        if $extract(raw,1)'="""" quit 0
        if $extract(raw,$length(raw))'="""" quit 0
        if $length(raw)<2 quit 0
        set n=$length(raw),i=2,out="",ok=1
        for  quit:i'<n  quit:'ok  do
        . set c=$extract(raw,i)
        . if c="""" set ok=0 quit
        . if c="\" do  quit
        . . set i=i+1
        . . if i'<n set ok=0 quit
        . . set prev=$extract(raw,i)
        . . if prev="n" set out=out_$char(10),i=i+1 quit
        . . if prev="t" set out=out_$char(9),i=i+1 quit
        . . if prev="r" set out=out_$char(13),i=i+1 quit
        . . if prev="""" set out=out_"""",i=i+1 quit
        . . if prev="\" set out=out_"\",i=i+1 quit
        . . set ok=0
        . set out=out_c,i=i+1
        if 'ok quit 0
        set value=out,vtype="string"
        quit 1
        ;
decodeInteger(raw,value,vtype)  ; Decode a signed decimal integer literal.
        ; doc: Internal — accepts optional leading "-" and one or more digits.
        new s,digits
        set s=raw
        if $extract(s,1)="-" set s=$extract(s,2,$length(s))
        if s="" quit 0
        if '$$isAllDigits(s) quit 0
        set value=+raw,vtype="integer"
        quit 1
        ;
decodeFloat(raw,value,vtype)    ; Decode a signed decimal float literal (no exponent).
        ; doc: Internal — accepts optional "-", one or more digits, ".", one or more digits.
        new s,intPart,fracPart
        set s=raw
        if $extract(s,1)="-" set s=$extract(s,2,$length(s))
        if $length(s,".")'=2 quit 0
        set intPart=$piece(s,".",1)
        set fracPart=$piece(s,".",2)
        if intPart="" quit 0
        if fracPart="" quit 0
        if '$$isAllDigits(intPart) quit 0
        if '$$isAllDigits(fracPart) quit 0
        set value=+raw,vtype="float"
        quit 1
        ;
        ; ---------- internal: helpers ----------
        ;
trimWs(s)       ; Strip leading and trailing space / tab.
        ; doc: Internal — TOML leaves LF/CR as line terminators.
        new t
        set t=s
        for  quit:t=""  quit:'($extract(t,1)?1(1" ",1C))  set t=$extract(t,2,$length(t))
        for  quit:t=""  quit:'($extract(t,$length(t))?1(1" ",1C))  set t=$extract(t,1,$length(t)-1)
        quit t
        ;
stripTrailingComment(s) ; Remove a trailing # comment unless inside a basic string.
        ; doc: Internal — scans s; tracks whether we're inside "..." quotes.
        new i,n,c,inStr,esc,found,foundAt
        set n=$length(s),inStr=0,esc=0,found=0,foundAt=0
        for i=1:1:n quit:found  do
        . set c=$extract(s,i)
        . if esc set esc=0 quit
        . if inStr,c="\" set esc=1 quit
        . if c="""" set inStr='inStr quit
        . if c="#",'inStr set found=1,foundAt=i
        if 'found quit s
        quit $extract(s,1,foundAt-1)
        ;
validBareKey(s) ; True iff s is a non-empty TOML bare key (A-Za-z0-9_-).
        ; doc: Internal — TOML §3 bare keys.
        new alpha
        if s="" quit 0
        set alpha="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-"
        quit $select($translate(s,alpha)="":1,1:0)
        ;
isAllDigits(s)  ; True iff s is non-empty and every char is 0-9.
        if s="" quit 0
        quit $select($translate(s,"0123456789")="":1,1:0)
