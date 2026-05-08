STDHEX  ; m-stdlib — RFC-4648 §8 hex encoding (lowercase by default).
        ;
        ; Four public extrinsics:
        ;   $$encode^STDHEX(data)   — bytes → lowercase hex (a..f)
        ;   $$encodeu^STDHEX(data)  — bytes → uppercase hex (A..F)
        ;   $$decode^STDHEX(text)   — hex → bytes (case-insensitive)
        ;   $$valid^STDHEX(text)    — predicate: even length, all hex digits
        ;
        ; Algorithm: each input byte splits into two 4-bit nibbles; each
        ; nibble maps to one of "0123456789abcdef" (or the uppercase form
        ; for encodeu). decode reverses the process after normalising the
        ; input to lowercase via $TRANSLATE.
        ;
        ; Input is treated as a string of bytes (one M character per byte —
        ; values 0..255 via $ASCII / $CHAR). Always-byte semantics
        ; regardless of $ZCHSET arrive with STDCRYPTO in Phase 3.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
encode(data)    ; Lowercase hex (RFC-4648 §8 default form).
        ; doc: @param data    string  byte string to encode (one M char per byte)
        ; doc: @returns       string  lowercase hex (a..f); "" for empty input
        ; doc: @example       write $$encode^STDHEX("foo")  ; "666f6f"
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$encodeu^STDHEX, $$decode^STDHEX, $$valid^STDHEX
        ; doc: Returns the empty string for empty input.
        quit $$encodeImpl(data,$$alpha())
        ;
encodeu(data)   ; Uppercase hex.
        ; doc: @param data    string  byte string to encode
        ; doc: @returns       string  uppercase hex (A..F); "" for empty input
        ; doc: @example       write $$encodeu^STDHEX("foo")  ; "666F6F"
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$encode^STDHEX, $$decode^STDHEX
        ; doc: Returns the empty string for empty input.
        quit $$encodeImpl(data,$$alphaU())
        ;
decode(text)    ; Case-insensitive hex → bytes.
        ; doc: @param text    string  hex text (any case; even or odd length)
        ; doc: @returns       string  decoded byte string; "" for empty input
        ; doc: @example       write $$decode^STDHEX("DeAdBeEf")  ; 4 bytes
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$encode^STDHEX, $$encodeu^STDHEX, $$valid^STDHEX
        ; doc: Tolerates uppercase, lowercase, and mixed-case input.
        ; doc: Odd-length input drops the trailing nibble silently — call
        ; doc: valid() first if strict validation is required.
        new low,alpha,n,out,i,b1,b2
        set alpha=$$alpha()
        set low=$translate(text,"ABCDEF","abcdef")
        set n=$length(low)
        set out=""
        if n=0 quit ""
        for i=1:2:n-1 do
        . set b1=$find(alpha,$extract(low,i))-2
        . set b2=$find(alpha,$extract(low,i+1))-2
        . set out=out_$char((b1*16)+b2)
        quit out
        ;
valid(text)     ; True iff text is well-formed hex (any case).
        ; doc: @param text    string  candidate hex text
        ; doc: @returns       bool    1 iff well-formed; 0 otherwise
        ; doc: @example       write $$valid^STDHEX("DeAdBeEf")  ; 1
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$decode^STDHEX
        ; doc: Length must be even; every character must be 0-9, a-f, or A-F.
        ; doc: Empty string is valid.
        new low
        if text="" quit 1
        if $length(text)#2 quit 0
        set low=$translate(text,"ABCDEF","abcdef")
        if $translate(low,$$alpha())'="" quit 0
        quit 1
        ;
        ; ---------- internal helpers ----------
        ;
alpha() ; Lowercase hex alphabet (RFC-4648 §8 Table 5, lowercase form).
        ; doc: @internal
        ; doc: Index 1..16 maps to nibble values 0..15.
        quit "0123456789abcdef"
        ;
alphaU()        ; Uppercase hex alphabet.
        ; doc: @internal
        ; doc: Same as alpha() with A..F instead of a..f.
        quit "0123456789ABCDEF"
        ;
encodeImpl(data,alpha)  ; Encode data using the supplied alphabet.
        ; doc: @internal
        ; doc: alpha must be a 16-character hex alphabet.
        new out,i,n,b
        set out=""
        set n=$length(data)
        for i=1:1:n do
        . set b=$ascii($extract(data,i))
        . set out=out_$extract(alpha,(b\16)+1)_$extract(alpha,(b#16)+1)
        quit out
