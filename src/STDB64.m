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
        quit
        ;
        ; ---------- public API ----------
        ;
encode(data)    ; Standard base64 (RFC-4648 §4) with padding.
        ; doc: @param data    string  byte string to encode (one M char per byte)
        ; doc: @returns       string  base64 with '=' padding; "" for empty input
        ; doc: @example       write $$encode^STDB64("foobar")  ; "Zm9vYmFy"
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$decode^STDB64, $$urlencode^STDB64, $$valid^STDB64
        ; doc: Returns the empty string for empty input.
        quit $$encodeImpl(data,$$alpha(),1)
        ;
decode(text)    ; Inverse of encode(); accepts standard alphabet + '=' padding.
        ; doc: @param text    string  base64-encoded text (standard alphabet, with padding)
        ; doc: @returns       string  decoded byte string; "" for empty input
        ; doc: @example       write $$decode^STDB64("Zm9vYmFy")  ; "foobar"
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$encode^STDB64, $$valid^STDB64
        ; doc: Returns the empty string for empty input.
        quit $$decodeImpl(text,$$alpha())
        ;
urlencode(data) ; URL-safe base64 (RFC-4648 §5) without padding.
        ; doc: @param data    string  byte string to encode
        ; doc: @returns       string  URL-safe base64 ('-' / '_' alphabet, no padding)
        ; doc: @example       write $$urlencode^STDB64("f")  ; "Zg" (no padding)
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$urldecode^STDB64, $$encode^STDB64
        ; doc: Uses '-' / '_' instead of '+' / '/'; drops trailing '=' (JWT
        ; doc: convention). Use urldecode() to invert.
        quit $$encodeImpl(data,$$urlAlpha(),0)
        ;
urldecode(text) ; Decode URL-safe base64; padding may be present or omitted.
        ; doc: @param text    string  URL-safe base64 (padding optional)
        ; doc: @returns       string  decoded byte string; "" for empty input
        ; doc: @example       write $$urldecode^STDB64("Zg")  ; "f"
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$urlencode^STDB64, $$decode^STDB64
        ; doc: Trailing '=' is stripped before decoding so input from JWT
        ; doc: producers (no padding) and Python's urlsafe_b64encode (padded)
        ; doc: both work.
        quit $$decodeImpl(text,$$urlAlpha())
        ;
valid(text)     ; True iff text is well-formed standard base64 with padding.
        ; doc: @param text    string  candidate base64 text
        ; doc: @returns       bool    1 iff well-formed; 0 otherwise
        ; doc: @example       write $$valid^STDB64("Zg==")  ; 1
        ; doc: @since         v0.0.2
        ; doc: @stable        stable
        ; doc: @see           $$decode^STDB64, $$urldecode^STDB64
        ; doc: Length must be a multiple of 4. Padding ('=') only at the end,
        ; doc: at most two characters. Body characters must all be in the
        ; doc: standard alphabet. Empty string is valid.
        new n,padlen,body
        set n=$length(text)
        if n=0 quit 1
        if n#4 quit 0
        set padlen=0
        if $extract(text,n)="=" set padlen=1
        if $extract(text,n-1,n)="==" set padlen=2
        set body=$extract(text,1,n-padlen)
        if $translate(body,$$alpha())'="" quit 0
        quit 1
        ;
        ; ---------- internal helpers ----------
        ;
alpha() ; Standard base64 alphabet (RFC-4648 §4 Table 1).
        ; doc: @internal
        ; doc: Index 1..64 maps to 6-bit values 0..63.
        quit "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        ;
urlAlpha()      ; URL-safe alphabet (RFC-4648 §5 Table 2).
        ; doc: @internal
        ; doc: Same as alpha() but with '-' / '_' replacing '+' / '/'.
        quit "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        ;
encodeImpl(data,alpha,pad)      ; Encode data using the supplied alphabet.
        ; doc: @internal
        ; doc: pad=1 emits '=' padding; pad=0 omits it.
        new out,i,n,b1,b2,b3,c1,c2,c3,c4
        set out=""
        set n=$length(data)
        for i=1:3:n do
        . set b1=$ascii($extract(data,i))
        . set b2=$select(i+1>n:0,1:$ascii($extract(data,i+1)))
        . set b3=$select(i+2>n:0,1:$ascii($extract(data,i+2)))
        . set c1=b1\4
        . set c2=((b1#4)*16)+(b2\16)
        . set c3=((b2#16)*4)+(b3\64)
        . set c4=b3#64
        . set out=out_$extract(alpha,c1+1)_$extract(alpha,c2+1)
        . if i+1>n set out=out_$select(pad:"==",1:"") quit
        . set out=out_$extract(alpha,c3+1)
        . if i+2>n set out=out_$select(pad:"=",1:"") quit
        . set out=out_$extract(alpha,c4+1)
        quit out
        ;
decodeImpl(text,alpha)  ; Decode text using the supplied alphabet.
        ; doc: @internal
        ; doc: Strips '=' padding before processing. Tolerates input lengths
        ; doc: not a multiple of 4 (drops trailing partial group).
        new clean,n,out,i,c1,c2,c3,c4,b1,b2,b3,rem
        set clean=$translate(text,"=","")
        set n=$length(clean)
        set out=""
        if n=0 quit ""
        for i=1:4:n do
        . set rem=n-i+1
        . set c1=$find(alpha,$extract(clean,i))-2
        . set c2=$select(rem<2:0,1:$find(alpha,$extract(clean,i+1))-2)
        . set c3=$select(rem<3:0,1:$find(alpha,$extract(clean,i+2))-2)
        . set c4=$select(rem<4:0,1:$find(alpha,$extract(clean,i+3))-2)
        . set b1=(c1*4)+(c2\16)
        . set b2=((c2#16)*16)+(c3\4)
        . set b3=((c3#4)*64)+c4
        . set out=out_$char(b1)
        . if rem>2 set out=out_$char(b2)
        . if rem>3 set out=out_$char(b3)
        quit out
