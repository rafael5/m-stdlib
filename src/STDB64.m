STDB64  ; m-stdlib — RFC-4648 Base64 (standard + URL-safe).
        ;
        ; Five public extrinsics:
        ;   $$encode^STDB64(data)      — standard alphabet (+ /), with padding
        ;   $$decode^STDB64(text)      — decode standard alphabet
        ;   $$urlencode^STDB64(data)   — URL-safe alphabet (- _), no padding
        ;   $$urldecode^STDB64(text)   — decode URL-safe; padding optional
        ;   $$valid^STDB64(text)       — well-formed standard base64 (with padding)
        ;
        ; Algorithm: take 3 bytes (24 bits) at a time, split into four 6-bit
        ; groups, map each via the 64-char alphabet. Pad with '=' when the
        ; input length is not a multiple of 3.
        ;
        ; Input is treated as a string of bytes (one M character per byte —
        ; values 0..255 via $ASCII / $CHAR). On YDB UTF-8 mode, multi-byte
        ; UTF-8 characters round-trip correctly when the producer and consumer
        ; both treat the string as M-characters. Arbitrary-binary support
        ; (always-byte semantics regardless of $ZCHSET) lands with STDCRYPTO
        ; in Phase 3 via $ZCHAR / $ZASCII helpers.
        ;
        QUIT
        ;
        ; ---------- public API ----------
        ;
encode(data)    ; Standard base64 (RFC-4648 §4) with padding.
        ; doc: Returns the empty string for empty input.
        ; doc: Example: write $$encode^STDB64("foobar")  ; "Zm9vYmFy"
        QUIT $$encodeImpl(data,$$alpha(),1)
        ;
decode(text)    ; Inverse of encode(); accepts standard alphabet + '=' padding.
        ; doc: Returns the empty string for empty input.
        ; doc: Example: write $$decode^STDB64("Zm9vYmFy")  ; "foobar"
        QUIT $$decodeImpl(text,$$alpha())
        ;
urlencode(data) ; URL-safe base64 (RFC-4648 §5) without padding.
        ; doc: Uses '-' / '_' instead of '+' / '/'; drops trailing '=' (JWT
        ; doc: convention). Use urldecode() to invert.
        ; doc: Example: write $$urlencode^STDB64("f")  ; "Zg" (no padding)
        QUIT $$encodeImpl(data,$$urlAlpha(),0)
        ;
urldecode(text) ; Decode URL-safe base64; padding may be present or omitted.
        ; doc: Trailing '=' is stripped before decoding so input from JWT
        ; doc: producers (no padding) and Python's urlsafe_b64encode (padded)
        ; doc: both work.
        QUIT $$decodeImpl(text,$$urlAlpha())
        ;
valid(text)     ; True iff text is well-formed standard base64 with padding.
        ; doc: Length must be a multiple of 4. Padding ('=') only at the end,
        ; doc: at most two characters. Body characters must all be in the
        ; doc: standard alphabet. Empty string is valid.
        ; doc: Example: write $$valid^STDB64("Zg==")  ; 1
        NEW n,padlen,body
        SET n=$LENGTH(text)
        IF n=0 QUIT 1
        IF n#4 QUIT 0
        SET padlen=0
        IF $EXTRACT(text,n)="=" SET padlen=1
        IF $EXTRACT(text,n-1,n)="==" SET padlen=2
        SET body=$EXTRACT(text,1,n-padlen)
        IF $TRANSLATE(body,$$alpha())'="" QUIT 0
        QUIT 1
        ;
        ; ---------- internal helpers ----------
        ;
alpha() ; Standard base64 alphabet (RFC-4648 §4 Table 1).
        ; doc: Internal — index 1..64 maps to 6-bit values 0..63.
        QUIT "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        ;
urlAlpha()      ; URL-safe alphabet (RFC-4648 §5 Table 2).
        ; doc: Internal — same as alpha() but with '-' / '_' replacing '+' / '/'.
        QUIT "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        ;
encodeImpl(data,alpha,pad)      ; Encode data using the supplied alphabet.
        ; doc: Internal — pad=1 emits '=' padding; pad=0 omits it.
        NEW out,i,n,b1,b2,b3,c1,c2,c3,c4
        SET out=""
        SET n=$LENGTH(data)
        FOR i=1:3:n DO
        . SET b1=$ASCII($EXTRACT(data,i))
        . SET b2=$SELECT(i+1>n:0,1:$ASCII($EXTRACT(data,i+1)))
        . SET b3=$SELECT(i+2>n:0,1:$ASCII($EXTRACT(data,i+2)))
        . SET c1=b1\4
        . SET c2=((b1#4)*16)+(b2\16)
        . SET c3=((b2#16)*4)+(b3\64)
        . SET c4=b3#64
        . SET out=out_$EXTRACT(alpha,c1+1)_$EXTRACT(alpha,c2+1)
        . IF i+1>n SET out=out_$SELECT(pad:"==",1:"") QUIT
        . SET out=out_$EXTRACT(alpha,c3+1)
        . IF i+2>n SET out=out_$SELECT(pad:"=",1:"") QUIT
        . SET out=out_$EXTRACT(alpha,c4+1)
        QUIT out
        ;
decodeImpl(text,alpha)  ; Decode text using the supplied alphabet.
        ; doc: Internal — strips '=' padding before processing. Tolerates
        ; doc: input lengths not a multiple of 4 (drops trailing partial group).
        NEW clean,n,out,i,c1,c2,c3,c4,b1,b2,b3,rem
        SET clean=$TRANSLATE(text,"=","")
        SET n=$LENGTH(clean)
        SET out=""
        IF n=0 QUIT ""
        FOR i=1:4:n DO
        . SET rem=n-i+1
        . SET c1=$FIND(alpha,$EXTRACT(clean,i))-2
        . SET c2=$SELECT(rem<2:0,1:$FIND(alpha,$EXTRACT(clean,i+1))-2)
        . SET c3=$SELECT(rem<3:0,1:$FIND(alpha,$EXTRACT(clean,i+2))-2)
        . SET c4=$SELECT(rem<4:0,1:$FIND(alpha,$EXTRACT(clean,i+3))-2)
        . SET b1=(c1*4)+(c2\16)
        . SET b2=((c2#16)*16)+(c3\4)
        . SET b3=((c3#4)*64)+c4
        . SET out=out_$CHAR(b1)
        . IF rem>2 SET out=out_$CHAR(b2)
        . IF rem>3 SET out=out_$CHAR(b3)
        QUIT out
