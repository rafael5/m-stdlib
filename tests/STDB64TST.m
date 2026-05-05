STDB64TST       ; Test suite for STDB64 (v0.0.2).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tEncodeRfcVectors(.pass,.fail)
        do tDecodeRfcVectors(.pass,.fail)
        do tEncodeEmptyString(.pass,.fail)
        do tDecodeEmptyString(.pass,.fail)
        do tRoundTripAscii(.pass,.fail)
        do tRoundTripWithBinaryBytes(.pass,.fail)
        do tRoundTripRandomLengths(.pass,.fail)
        do tUrlEncodeDropsPadding(.pass,.fail)
        do tUrlEncodeUsesDashUnderscore(.pass,.fail)
        do tUrlDecodeAcceptsBothPaddedAndUnpadded(.pass,.fail)
        do tUrlRoundTrip(.pass,.fail)
        do tValidAcceptsRfcVectors(.pass,.fail)
        do tValidRejectsBadLength(.pass,.fail)
        do tValidRejectsBadAlphabet(.pass,.fail)
        do tValidRejectsMisplacedPadding(.pass,.fail)
        do tValidAcceptsEmpty(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tEncodeRfcVectors(pass,fail)    ;@TEST "encode() matches RFC-4648 §10 vectors"
        do eq^STDASSERT(.pass,.fail,$$encode^STDB64("f"),"Zg==","f")
        do eq^STDASSERT(.pass,.fail,$$encode^STDB64("fo"),"Zm8=","fo")
        do eq^STDASSERT(.pass,.fail,$$encode^STDB64("foo"),"Zm9v","foo")
        do eq^STDASSERT(.pass,.fail,$$encode^STDB64("foob"),"Zm9vYg==","foob")
        do eq^STDASSERT(.pass,.fail,$$encode^STDB64("fooba"),"Zm9vYmE=","fooba")
        do eq^STDASSERT(.pass,.fail,$$encode^STDB64("foobar"),"Zm9vYmFy","foobar")
        quit
        ;
tDecodeRfcVectors(pass,fail)    ;@TEST "decode() inverts RFC-4648 §10 vectors"
        do eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zg=="),"f","f")
        do eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm8="),"fo","fo")
        do eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9v"),"foo","foo")
        do eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9vYg=="),"foob","foob")
        do eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9vYmE="),"fooba","fooba")
        do eq^STDASSERT(.pass,.fail,$$decode^STDB64("Zm9vYmFy"),"foobar","foobar")
        quit
        ;
tEncodeEmptyString(pass,fail)   ;@TEST "encode() of empty string is empty"
        do eq^STDASSERT(.pass,.fail,$$encode^STDB64(""),"","empty in -> empty out")
        quit
        ;
tDecodeEmptyString(pass,fail)   ;@TEST "decode() of empty string is empty"
        do eq^STDASSERT(.pass,.fail,$$decode^STDB64(""),"","empty in -> empty out")
        quit
        ;
tRoundTripAscii(pass,fail)      ;@TEST "encode -> decode round-trips ASCII strings"
        ; Mix of lengths to hit each padding case (n%3 = 0, 1, 2).
        new s,r
        for s="Hello, World!","abc","abcd","abcde","The quick brown fox" do
        . set r=$$decode^STDB64($$encode^STDB64(s))
        . do eq^STDASSERT(.pass,.fail,r,s,"round-trip "_s)
        quit
        ;
tRoundTripWithBinaryBytes(pass,fail)    ;@TEST "encode/decode round-trips bytes 0x00-0x7F"
        ; Build a string of every ASCII byte 1..127 (skip 0 — M strings are
        ; null-terminated in some contexts; safer to test the printable range).
        new s,n,r
        set s=""
        for n=1:1:127 set s=s_$char(n)
        set r=$$decode^STDB64($$encode^STDB64(s))
        do eq^STDASSERT(.pass,.fail,r,s,"round-trip 1..127 byte string")
        quit
        ;
tRoundTripRandomLengths(pass,fail)      ;@TEST "round-trip preserves random-length strings"
        new len,s,n,r
        for len=1,7,16,32,100,255 do
        . set s=""
        . for n=1:1:len set s=s_$char($random(95)+32)
        . set r=$$decode^STDB64($$encode^STDB64(s))
        . do eq^STDASSERT(.pass,.fail,r,s,"round-trip length "_len)
        quit
        ;
tUrlEncodeDropsPadding(pass,fail)       ;@TEST "urlencode() omits = padding"
        do eq^STDASSERT(.pass,.fail,$$urlencode^STDB64("f"),"Zg","no padding")
        do eq^STDASSERT(.pass,.fail,$$urlencode^STDB64("fo"),"Zm8","no padding")
        do eq^STDASSERT(.pass,.fail,$$urlencode^STDB64("foo"),"Zm9v","aligned, no pad needed")
        quit
        ;
tUrlEncodeUsesDashUnderscore(pass,fail) ;@TEST "urlencode() emits - and _ instead of + and /"
        ; Bytes 0xFB 0xEF 0xFF encode to "++" and "//" in standard, but to
        ; "--" and "__" in URL-safe. Use an input that produces both.
        new s,std,url
        set s=$char(251)_$char(239)_$char(255)   ; 0xFB EF FF -> "++//" base64
        set std=$$encode^STDB64(s)
        set url=$$urlencode^STDB64(s)
        do false^STDASSERT(.pass,.fail,url["+","urlencode contains no '+'")
        do false^STDASSERT(.pass,.fail,url["/","urlencode contains no '/'")
        do false^STDASSERT(.pass,.fail,url["=","urlencode contains no '='")
        quit
        ;
tUrlDecodeAcceptsBothPaddedAndUnpadded(pass,fail)       ;@TEST "urldecode() works with or without padding"
        do eq^STDASSERT(.pass,.fail,$$urldecode^STDB64("Zg"),"f","unpadded")
        do eq^STDASSERT(.pass,.fail,$$urldecode^STDB64("Zg=="),"f","padded")
        quit
        ;
tUrlRoundTrip(pass,fail)        ;@TEST "urlencode -> urldecode round-trips"
        new s,r
        for s="hello","abc","abcd","abcde",$char(251)_$char(239)_$char(255) do
        . set r=$$urldecode^STDB64($$urlencode^STDB64(s))
        . do eq^STDASSERT(.pass,.fail,r,s,"url round-trip")
        quit
        ;
tValidAcceptsRfcVectors(pass,fail)      ;@TEST "valid() accepts every RFC-4648 §10 vector"
        do true^STDASSERT(.pass,.fail,$$valid^STDB64("Zg=="),"Zg==")
        do true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm8="),"Zm8=")
        do true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9v"),"Zm9v")
        do true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vYg=="),"Zm9vYg==")
        do true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vYmE="),"Zm9vYmE=")
        do true^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vYmFy"),"Zm9vYmFy")
        quit
        ;
tValidRejectsBadLength(pass,fail)       ;@TEST "valid() rejects length not divisible by 4"
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Z"),"length 1")
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm"),"length 2")
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9"),"length 3")
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm9vY"),"length 5")
        quit
        ;
tValidRejectsBadAlphabet(pass,fail)     ;@TEST "valid() rejects non-alphabet characters"
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Zg!="),"contains !")
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm-v"),"contains - (URL-safe in std)")
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Zm_v"),"contains _ (URL-safe in std)")
        quit
        ;
tValidRejectsMisplacedPadding(pass,fail)        ;@TEST "valid() rejects padding inside the body"
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("Z=g="),"= mid-body")
        do false^STDASSERT(.pass,.fail,$$valid^STDB64("===="),"all padding")
        quit
        ;
tValidAcceptsEmpty(pass,fail)   ;@TEST "valid() accepts empty string"
        do true^STDASSERT(.pass,.fail,$$valid^STDB64(""),"empty is valid")
        quit
