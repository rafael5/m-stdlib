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
        QUIT
        ;
        ; ---------- public API ----------
        ;
v4()    ; Return a new RFC-4122 v4 UUID.
        ; doc: 122 bits of randomness; version nibble='4'; variant nibble in 8/9/a/b.
        ; doc: Example: set id=$$v4^STDUUID()  ; "550e8400-e29b-41d4-a716-446655440000"
        NEW b1,b2,b3,b4,b5
        SET b1=$$randomHex(8)
        SET b2=$$randomHex(4)
        SET b3="4"_$$randomHex(3)
        SET b4=$extract("89ab",$random(4)+1)_$$randomHex(3)
        SET b5=$$randomHex(12)
        QUIT b1_"-"_b2_"-"_b3_"-"_b4_"-"_b5
        ;
v7()    ; Return a new RFC-9562 v7 UUID (time-ordered).
        ; doc: First 48 bits = ms-since-Unix-epoch (sortable). 12-bit rand_a,
        ; doc: variant nibble (8/9/a/b), 12-bit rand_b, 50-bit rand_c.
        ; doc: Example: set id=$$v7^STDUUID()  ; sorts in generation order
        NEW ms,tsHex,b1,b2,b3,b4,b5
        SET ms=$$unixMs()
        SET tsHex=$$toHex(ms,12)
        SET b1=$extract(tsHex,1,8)
        SET b2=$extract(tsHex,9,12)
        SET b3="7"_$$randomHex(3)
        SET b4=$extract("89ab",$random(4)+1)_$$randomHex(3)
        SET b5=$$randomHex(12)
        QUIT b1_"-"_b2_"-"_b3_"-"_b4_"-"_b5
        ;
valid(u)        ; Return 1 iff u is a canonical 36-char hex UUID; else 0.
        ; doc: Accepts both lowercase and uppercase hex. Hyphens must sit
        ; doc: at exactly positions 9, 14, 19, 24.
        ; doc: Example: write $$valid^STDUUID(id)  ; 1 or 0
        IF $length(u)'=36 QUIT 0
        IF $extract(u,9)'="-" QUIT 0
        IF $extract(u,14)'="-" QUIT 0
        IF $extract(u,19)'="-" QUIT 0
        IF $extract(u,24)'="-" QUIT 0
        NEW clean
        SET clean=$translate(u,"-","")
        IF $length(clean)'=32 QUIT 0
        ; All remaining chars must be hex (0-9, a-f, A-F).
        IF $translate(clean,"0123456789abcdefABCDEF")'="" QUIT 0
        QUIT 1
        ;
version(u)      ; Return integer version (1..15) from position 15, or "" if invalid.
        ; doc: For a v4 UUID this returns 4; for v7, 7. Empty string for malformed.
        ; doc: Example: write $$version^STDUUID($$v4^STDUUID())  ; 4
        IF '$$valid(u) QUIT ""
        NEW v,p
        SET v=$translate($extract(u,15),"ABCDEF","abcdef")
        SET p=$find("0123456789abcdef",v)
        IF p<2 QUIT ""
        QUIT p-2
        ;
variant(u)      ; Classify UUID variant from the high bits of position 20.
        ; doc: Returns "ncs" (high bit 0), "rfc4122" (high 10), "microsoft"
        ; doc: (high 110), "future" (high 111), or "" if invalid.
        ; doc: Example: write $$variant^STDUUID($$v4^STDUUID())  ; "rfc4122"
        IF '$$valid(u) QUIT ""
        NEW v
        SET v=$translate($extract(u,20),"ABCDEF","abcdef")
        IF "01234567"[v QUIT "ncs"
        IF "89ab"[v QUIT "rfc4122"
        IF "cd"[v QUIT "microsoft"
        IF "ef"[v QUIT "future"
        QUIT ""
        ;
        ; ---------- internal helpers ----------
        ;
randomHex(n)    ; Return n lowercase hex chars from $RANDOM.
        ; doc: Internal — composes UUID nibbles. n nibbles = n*4 random bits.
        NEW s,i
        SET s=""
        FOR i=1:1:n SET s=s_$extract("0123456789abcdef",$random(16)+1)
        QUIT s
        ;
toHex(n,width)  ; Integer n -> lowercase hex, left-padded to 'width' chars.
        ; doc: Internal — encodes the v7 48-bit timestamp.
        NEW s,d
        SET s=""
        IF 'n SET s="0"
        FOR  QUIT:n<1  SET d=n#16,n=n\16,s=$extract("0123456789abcdef",d+1)_s
        FOR  QUIT:$length(s)'<width  SET s="0"_s
        QUIT s
        ;
unixMs()        ; Current ms since 1970-01-01T00:00:00Z (Unix epoch).
        ; doc: Internal — drives v7's time-ordered prefix.
        ; doc: $HOROLOG day 0 = 1840-12-31; day 47117 = 1970-01-01.
        ; doc: $ZHOROLOG adds microsecond and tz-offset pieces.
        ; YDB-only path; an IRIS arm using $ZTIMESTAMP lands when STDDATE ships.
        NEW dh,d,s,us
        ; m-lint: disable-next-line=M-MOD-022
        SET dh=$zhorolog
        SET d=$piece(dh,",",1)
        SET s=$piece(dh,",",2)
        SET us=$piece(dh,",",3)
        QUIT (d-47117)*86400000+(s*1000)+(us\1000)
