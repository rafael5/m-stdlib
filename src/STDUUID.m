STDUUID ; m-stdlib — UUID v4 + v7 (RFC 4122 / RFC 9562).
        ;
        ; Five public extrinsics:
        ;   $$v4^STDUUID()         — random UUID v4 ("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx")
        ;   $$v7^STDUUID()         — time-ordered UUID v7
        ;   $$valid^STDUUID(u)     — 1 if u is canonical 36-char hex form
        ;   $$version^STDUUID(u)   — integer 1..15 from the version nibble, "" if invalid
        ;   $$variant^STDUUID(u)   — "ncs" | "rfc4122" | "microsoft" | "future" | ""
        ;
        ; v4 randomness is from $RANDOM (Mersenne Twister) — NOT cryptographically
        ; strong. Adequate for distributed primary keys; do not use for tokens.
        ; v7 timestamp is ms since 1970-01-01 UTC (48 bits): high 48 bits encode
        ; the timestamp so byte-wise sort = generation order.
        ;
        ; All output is lowercase hex per RFC 9562 §4 recommendation.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
v4()    ; Return a new RFC-4122 v4 UUID.
        ; doc: @returns       string  canonical 36-char hex UUID v4 (lowercase, hyphenated)
        ; doc: @example       set id=$$v4^STDUUID()  ; "550e8400-e29b-41d4-a716-446655440000"
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           $$v7^STDUUID, $$valid^STDUUID, $$version^STDUUID
        ; doc: 122 bits of randomness; version nibble='4'; variant nibble in 8/9/a/b.
        ; doc: Randomness is from $RANDOM (Mersenne Twister) — adequate for distributed
        ; doc: primary keys; not cryptographically strong (do not use for tokens).
        new b1,b2,b3,b4,b5
        set b1=$$randomHex(8)
        set b2=$$randomHex(4)
        set b3="4"_$$randomHex(3)
        set b4=$extract("89ab",$random(4)+1)_$$randomHex(3)
        set b5=$$randomHex(12)
        quit b1_"-"_b2_"-"_b3_"-"_b4_"-"_b5
        ;
v7()    ; Return a new RFC-9562 v7 UUID (time-ordered).
        ; doc: @returns       string  canonical 36-char hex UUID v7; byte-wise sort = generation order
        ; doc: @example       set id=$$v7^STDUUID()  ; sorts in generation order
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           $$v4^STDUUID, $$valid^STDUUID
        ; doc: First 48 bits = ms-since-Unix-epoch (sortable). 12-bit rand_a,
        ; doc: variant nibble (8/9/a/b), 12-bit rand_b, 50-bit rand_c.
        new ms,tsHex,b1,b2,b3,b4,b5
        set ms=$$unixMs()
        set tsHex=$$toHex(ms,12)
        set b1=$extract(tsHex,1,8)
        set b2=$extract(tsHex,9,12)
        set b3="7"_$$randomHex(3)
        set b4=$extract("89ab",$random(4)+1)_$$randomHex(3)
        set b5=$$randomHex(12)
        quit b1_"-"_b2_"-"_b3_"-"_b4_"-"_b5
        ;
valid(u)        ; Return 1 iff u is a canonical 36-char hex UUID; else 0.
        ; doc: @param u       string  candidate UUID text
        ; doc: @returns       bool    1 iff canonical 36-char hex; 0 otherwise
        ; doc: @example       write $$valid^STDUUID(id)  ; 1 or 0
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           $$version^STDUUID, $$variant^STDUUID
        ; doc: Accepts both lowercase and uppercase hex. Hyphens must sit
        ; doc: at exactly positions 9, 14, 19, 24.
        if $length(u)'=36 quit 0
        if $extract(u,9)'="-" quit 0
        if $extract(u,14)'="-" quit 0
        if $extract(u,19)'="-" quit 0
        if $extract(u,24)'="-" quit 0
        new clean
        set clean=$translate(u,"-","")
        if $length(clean)'=32 quit 0
        ; All remaining chars must be hex (0-9, a-f, A-F).
        if $translate(clean,"0123456789abcdefABCDEF")'="" quit 0
        quit 1
        ;
version(u)      ; Return integer version (1..15) from position 15, or "" if invalid.
        ; doc: @param u       string  candidate UUID
        ; doc: @returns       int     1..15 from the version nibble; "" if `u` is not valid
        ; doc: @example       write $$version^STDUUID($$v4^STDUUID())  ; 4
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           $$valid^STDUUID, $$variant^STDUUID
        ; doc: For a v4 UUID this returns 4; for v7, 7. Empty string for malformed.
        if '$$valid(u) quit ""
        new v,p
        set v=$translate($extract(u,15),"ABCDEF","abcdef")
        set p=$find("0123456789abcdef",v)
        if p<2 quit ""
        quit p-2
        ;
variant(u)      ; Classify UUID variant from the high bits of position 20.
        ; doc: @param u       string  candidate UUID
        ; doc: @returns       string  one of "ncs", "rfc4122", "microsoft", "future"; "" if `u` invalid
        ; doc: @example       write $$variant^STDUUID($$v4^STDUUID())  ; "rfc4122"
        ; doc: @since         v0.0.1
        ; doc: @stable        stable
        ; doc: @see           $$valid^STDUUID, $$version^STDUUID
        ; doc: "ncs" (high bit 0), "rfc4122" (high 10), "microsoft" (high 110),
        ; doc: "future" (high 111). Empty string for malformed input.
        if '$$valid(u) quit ""
        new v
        set v=$translate($extract(u,20),"ABCDEF","abcdef")
        if "01234567"[v quit "ncs"
        if "89ab"[v quit "rfc4122"
        if "cd"[v quit "microsoft"
        if "ef"[v quit "future"
        quit ""
        ;
        ; ---------- internal helpers ----------
        ;
randomHex(n)    ; Return n lowercase hex chars from $RANDOM.
        ; doc: @internal
        ; doc: Composes UUID nibbles. n nibbles = n*4 random bits.
        new s,i
        set s=""
        for i=1:1:n set s=s_$extract("0123456789abcdef",$random(16)+1)
        quit s
        ;
toHex(n,width)  ; Integer n -> lowercase hex, left-padded to 'width' chars.
        ; doc: @internal
        ; doc: Encodes the v7 48-bit timestamp.
        new s,d
        set s=""
        if 'n set s="0"
        for  quit:n<1  set d=n#16,n=n\16,s=$extract("0123456789abcdef",d+1)_s
        for  quit:$length(s)'<width  set s="0"_s
        quit s
        ;
unixMs()        ; Current ms since 1970-01-01T00:00:00Z (Unix epoch).
        ; doc: @internal
        ; doc: Drives v7's time-ordered prefix.
        ; doc: $HOROLOG day 0 = 1840-12-31; day 47117 = 1970-01-01.
        ; doc: $ZHOROLOG adds microsecond and tz-offset pieces.
        ; YDB-only path; an IRIS arm using $ZTIMESTAMP lands when STDDATE ships.
        new dh,d,s,us
        ; m-lint: disable-next-line=M-MOD-022
        set dh=$zhorolog
        set d=$piece(dh,",",1)
        set s=$piece(dh,",",2)
        set us=$piece(dh,",",3)
        quit (d-47117)*86400000+(s*1000)+(us\1000)
