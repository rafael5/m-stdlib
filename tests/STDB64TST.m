STDB64TST       ; Test suite for STDB64 (v0.0.2).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        NEW pass,fail
        DO start^STDASSERT(.pass,.fail)
        ;
        DO tEncodeRfcVectors(.pass,.fail)
        DO tDecodeRfcVectors(.pass,.fail)
        DO tEncodeEmptyString(.pass,.fail)
        DO tDecodeEmptyString(.pass,.fail)
        DO tRoundTripAscii(.pass,.fail)
        DO tRoundTripWithBinaryBytes(.pass,.fail)
        DO tRoundTripRandomLengths(.pass,.fail)
        DO tUrlEncodeDropsPadding(.pass,.fail)
        DO tUrlEncodeUsesDashUnderscore(.pass,.fail)
        DO tUrlDecodeAcceptsBothPaddedAndUnpadded(.pass,.fail)
        DO tUrlRoundTrip(.pass,.fail)
        DO tValidAcceptsRfcVectors(.pass,.fail)
        DO tValidRejectsBadLength(.pass,.fail)
        DO tValidRejectsBadAlphabet(.pass,.fail)
        DO tValidRejectsMisplacedPadding(.pass,.fail)
        DO tValidAcceptsEmpty(.pass,.fail)
        ;
        DO report^STDASSERT(pass,fail)
        QUIT
        ;
tEncodeRfcVectors(pass,fail)    ;@TEST "encode() matches RFC-4648 §10 vectors"
        DO eq^STDASSERT(.pass,.fail,$$encode^STDB64("f"),"Zg==","f")
        DO eq^STDASSERT(.pass,.fail,$$encode^STDB64("fo"),"Zm8=","fo")
        DO eq^STDASSERT(.pass,.fail,$$encode^STDB64("foo"),"Zm9v","foo")
        DO eq^STDASSERT(.pass,.fail,$$encode^STDB64("foob"),"Zm9vYg==","foob")
        DO eq^STDASSERT(.pass,.fail,$$encode^STDB64("fooba"),"Zm9vYmE=","fooba")
        DO eq^STDASSERT(.pass,.fail,$$encode^STDB64("foobar"),"Zm9vYmFy","foobar")
        QUIT
        ;
tDecodeRfcVectors(pass,fail)    ;@TEST "decode() inverts RFC-4648 §10 vectors"
        DO eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zg=="),"f","f")
        DO eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm8="),"fo","fo")
        DO eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9v"),"foo","foo")
        DO eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9vYg=="),"foob","foob")
        DO eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9vYmE="),"fooba","fooba")
        DO eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9vYmFy"),"foobar","foobar")
        QUIT
        ;
tEncodeEmptyString(pass,fail)   ;@TEST "encode() of empty string is empty"
        DO eq^STDASSERT(.pass,.fail,$$encode^STDB64(""),"","empty in -> empty out")
        QUIT
        ;
tDecodeEmptyString(pass,fail)   ;@TEST "decode() of empty string is empty"
        DO eq^STDASSERT(.pass,.fail,$$decode^STDB64(""),"","empty in -> empty out")
        QUIT
        ;
tRoundTripAscii(pass,fail)      ;@TEST "encode -> decode round-trips ASCII strings"
        ; Mix of lengths to hit each padding case (n%3 = 0, 1, 2).
        NEW s,r
        FOR s="Hello, World!","abc","abcd","abcde","The quick brown fox" DO
        . SET r=$$decode^STDB64($$encode^STDB64(s))
        . DO eq^STDASSERT(.pass,.fail,r,s,"round-trip "_s)
        QUIT
        ;
tRoundTripWithBinaryBytes(pass,fail)    ;@TEST "encode/decode round-trips bytes 0x00-0x7F"
        ; Build a string of every ASCII byte 1..127 (skip 0 — M strings are
        ; null-terminated in some contexts; safer to test the printable range).
        NEW s,n,r
        SET s=""
        FOR n=1:1:127 SET s=s_$CHAR(n)
        SET r=$$decode^STDB64($$encode^STDB64(s))
        DO eq^STDASSERT(.pass,.fail,r,s,"round-trip 1..127 byte string")
        QUIT
        ;
tRoundTripRandomLengths(pass,fail)      ;@TEST "round-trip preserves random-length strings"
        NEW len,s,n,r
        FOR len=1,7,16,32,100,255 DO
        . SET s=""
        . FOR n=1:1:len SET s=s_$CHAR($RANDOM(95)+32)
        . SET r=$$decode^STDB64($$encode^STDB64(s))
        . DO eq^STDASSERT(.pass,.fail,r,s,"round-trip length "_len)
        QUIT
        ;
tUrlEncodeDropsPadding(pass,fail)       ;@TEST "urlencode() omits = padding"
        DO eq^STDASSERT(.pass,.fail,$$urlencode^STDB64("f"),"Zg","no padding")
        DO eq^STDASSERT(.pass,.fail,$$urlencode^STDB64("fo"),"Zm8","no padding")
        DO eq^STDASSERT(.pass,.fail,$$urlencode^STDB64("foo"),"Zm9v","aligned, no pad needed")
        QUIT
        ;
tUrlEncodeUsesDashUnderscore(pass,fail) ;@TEST "urlencode() emits - and _ instead of + and /"
        ; Bytes 0xFB 0xEF 0xFF encode to "++" and "//" in standard, but to
        ; "--" and "__" in URL-safe. Use an input that produces both.
        NEW s,std,url
        SET s=$CHAR(251)_$CHAR(239)_$CHAR(255)   ; 0xFB EF FF -> "++//" base64
        SET std=$$encode^STDB64(s)
        SET url=$$urlencode^STDB64(s)
        DO false^STDASSERT(.pass,.fail,url["+","urlencode contains no '+'")
        DO false^STDASSERT(.pass,.fail,url["/","urlencode contains no '/'")
        DO false^STDASSERT(.pass,.fail,url["=","urlencode contains no '='")
        QUIT
        ;
tUrlDecodeAcceptsBothPaddedAndUnpadded(pass,fail)       ;@TEST "urldecode() works with or without padding"
        DO eq^STDASSERT(.pass,.fail,$$urldecode^STDB64("Zg"),"f","unpadded")
        DO eq^STDASSERT(.pass,.fail,$$urldecode^STDB64("Zg=="),"f","padded")
        QUIT
        ;
tUrlRoundTrip(pass,fail)        ;@TEST "urlencode -> urldecode round-trips"
        NEW s,r
        FOR s="hello","abc","abcd","abcde",$CHAR(251)_$CHAR(239)_$CHAR(255) DO
        . SET r=$$urldecode^STDB64($$urlencode^STDB64(s))
        . DO eq^STDASSERT(.pass,.fail,r,s,"url round-trip")
        QUIT
        ;
tValidAcceptsRfcVectors(pass,fail)      ;@TEST "valid() accepts every RFC-4648 §10 vector"
        DO true^STDASSERT(.pass,.fail,$$valid^STDB64("Zg=="),"Zg==")
        DO true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm8="),"Zm8=")
        DO true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9v"),"Zm9v")
        DO true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vYg=="),"Zm9vYg==")
        DO true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vYmE="),"Zm9vYmE=")
        DO true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vYmFy"),"Zm9vYmFy")
        QUIT
        ;
tValidRejectsBadLength(pass,fail)       ;@TEST "valid() rejects length not divisible by 4"
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Z"),"length 1")
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm"),"length 2")
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9"),"length 3")
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vY"),"length 5")
        QUIT
        ;
tValidRejectsBadAlphabet(pass,fail)     ;@TEST "valid() rejects non-alphabet characters"
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Zg!="),"contains !")
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm-v"),"contains - (URL-safe in std)")
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm_v"),"contains _ (URL-safe in std)")
        QUIT
        ;
tValidRejectsMisplacedPadding(pass,fail)        ;@TEST "valid() rejects padding inside the body"
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("Z=g="),"= mid-body")
        DO false^STDASSERT(.pass,.fail,$$valid^STDB64("===="),"all padding")
        QUIT
        ;
tValidAcceptsEmpty(pass,fail)   ;@TEST "valid() accepts empty string"
        DO true^STDASSERT(.pass,.fail,$$valid^STDB64(""),"empty is valid")
        QUIT
