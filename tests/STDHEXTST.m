STDHEXTST       ; Test suite for STDHEX (v0.0.2).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tEncodeKnownVectors(.pass,.fail)
        do tDecodeKnownVectors(.pass,.fail)
        do tEncodeEmptyString(.pass,.fail)
        do tDecodeEmptyString(.pass,.fail)
        do tEncodeIsLowercaseByDefault(.pass,.fail)
        do tEncodeUppercaseVariant(.pass,.fail)
        do tDecodeAcceptsLowercase(.pass,.fail)
        do tDecodeAcceptsUppercase(.pass,.fail)
        do tDecodeAcceptsMixedCase(.pass,.fail)
        do tRoundTripAscii(.pass,.fail)
        do tRoundTripBinaryBytes(.pass,.fail)
        do tRoundTripRandomLengths(.pass,.fail)
        do tValidAcceptsLowercase(.pass,.fail)
        do tValidAcceptsUppercase(.pass,.fail)
        do tValidAcceptsMixedCase(.pass,.fail)
        do tValidAcceptsEmpty(.pass,.fail)
        do tValidRejectsOddLength(.pass,.fail)
        do tValidRejectsNonHex(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tEncodeKnownVectors(pass,fail)  ;@TEST "encode() emits well-known hex strings"
        do eq^STDASSERT(.pass,.fail,$$encode^STDHEX("f"),"66","f")
        do eq^STDASSERT(.pass,.fail,$$encode^STDHEX("fo"),"666f","fo")
        do eq^STDASSERT(.pass,.fail,$$encode^STDHEX("foo"),"666f6f","foo")
        do eq^STDASSERT(.pass,.fail,$$encode^STDHEX("foob"),"666f6f62","foob")
        do eq^STDASSERT(.pass,.fail,$$encode^STDHEX("fooba"),"666f6f6261","fooba")
        do eq^STDASSERT(.pass,.fail,$$encode^STDHEX("foobar"),"666f6f626172","foobar")
        quit
        ;
tDecodeKnownVectors(pass,fail)  ;@TEST "decode() inverts well-known hex strings"
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("66"),"f","f")
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("666f"),"fo","fo")
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("666f6f"),"foo","foo")
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("666f6f62"),"foob","foob")
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("666f6f6261"),"fooba","fooba")
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("666f6f626172"),"foobar","foobar")
        quit
        ;
tEncodeEmptyString(pass,fail)   ;@TEST "encode() of empty string is empty"
        do eq^STDASSERT(.pass,.fail,$$encode^STDHEX(""),"","empty in -> empty out")
        do eq^STDASSERT(.pass,.fail,$$encodeu^STDHEX(""),"","empty in -> empty out")
        quit
        ;
tDecodeEmptyString(pass,fail)   ;@TEST "decode() of empty string is empty"
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX(""),"","empty in -> empty out")
        quit
        ;
tEncodeIsLowercaseByDefault(pass,fail)  ;@TEST "encode() emits a..f, never A..F"
        new s,n,h
        ; All bytes 0..255 must encode without producing any uppercase letter.
        ; Pattern code 'U' is uppercase-only (cf. 'A' which is case-insensitive).
        set s=""
        for n=0:1:255 set s=s_$char(n)
        set h=$$encode^STDHEX(s)
        do false^STDASSERT(.pass,.fail,h?.E1U.E,"encode emits no uppercase letter")
        quit
        ;
tEncodeUppercaseVariant(pass,fail)      ;@TEST "encodeu() emits A..F, never a..f"
        new s,n,h
        set s=""
        for n=0:1:255 set s=s_$char(n)
        set h=$$encodeu^STDHEX(s)
        do false^STDASSERT(.pass,.fail,h?.E1L.E,"encodeu emits no lowercase letter")
        do eq^STDASSERT(.pass,.fail,$$encodeu^STDHEX("foo"),"666F6F","foo uppercase")
        quit
        ;
tDecodeAcceptsLowercase(pass,fail)      ;@TEST "decode() accepts lowercase hex"
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("deadbeef"),$char(222)_$char(173)_$char(190)_$char(239),"deadbeef")
        quit
        ;
tDecodeAcceptsUppercase(pass,fail)      ;@TEST "decode() accepts uppercase hex"
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("DEADBEEF"),$char(222)_$char(173)_$char(190)_$char(239),"DEADBEEF")
        quit
        ;
tDecodeAcceptsMixedCase(pass,fail)      ;@TEST "decode() accepts mixed case"
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("DeAdBeEf"),$char(222)_$char(173)_$char(190)_$char(239),"mixed")
        do eq^STDASSERT(.pass,.fail,$$decode^STDHEX("deADBeef"),$char(222)_$char(173)_$char(190)_$char(239),"mixed 2")
        quit
        ;
tRoundTripAscii(pass,fail)      ;@TEST "encode -> decode round-trips ASCII strings"
        new s,r
        for s="Hello, World!","abc","abcd","abcde","The quick brown fox" do
        . set r=$$decode^STDHEX($$encode^STDHEX(s))
        . do eq^STDASSERT(.pass,.fail,r,s,"round-trip "_s)
        quit
        ;
tRoundTripBinaryBytes(pass,fail)        ;@TEST "encode/decode round-trips bytes 1..127"
        ; Skip 0 — M strings are null-terminated in some contexts; safer to
        ; test the printable + control range.
        new s,n,r
        set s=""
        for n=1:1:127 set s=s_$char(n)
        set r=$$decode^STDHEX($$encode^STDHEX(s))
        do eq^STDASSERT(.pass,.fail,r,s,"round-trip 1..127 byte string")
        quit
        ;
tRoundTripRandomLengths(pass,fail)      ;@TEST "round-trip preserves random-length strings"
        new len,s,n,r
        for len=1,7,16,32,100,255 do
        . set s=""
        . for n=1:1:len set s=s_$char($random(95)+32)
        . set r=$$decode^STDHEX($$encode^STDHEX(s))
        . do eq^STDASSERT(.pass,.fail,r,s,"round-trip length "_len)
        quit
        ;
tValidAcceptsLowercase(pass,fail)       ;@TEST "valid() accepts lowercase hex"
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX("0123456789abcdef"),"all lowercase nibbles")
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX("deadbeef"),"deadbeef")
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX("00"),"00")
        quit
        ;
tValidAcceptsUppercase(pass,fail)       ;@TEST "valid() accepts uppercase hex"
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX("0123456789ABCDEF"),"all uppercase nibbles")
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX("DEADBEEF"),"DEADBEEF")
        quit
        ;
tValidAcceptsMixedCase(pass,fail)       ;@TEST "valid() accepts mixed case"
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX("DeAdBeEf"),"mixed")
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX("aB12cD34"),"mixed 2")
        quit
        ;
tValidAcceptsEmpty(pass,fail)   ;@TEST "valid() accepts empty string"
        do true^STDASSERT(.pass,.fail,$$valid^STDHEX(""),"empty is valid")
        quit
        ;
tValidRejectsOddLength(pass,fail)       ;@TEST "valid() rejects odd-length strings"
        do false^STDASSERT(.pass,.fail,$$valid^STDHEX("a"),"length 1")
        do false^STDASSERT(.pass,.fail,$$valid^STDHEX("abc"),"length 3")
        do false^STDASSERT(.pass,.fail,$$valid^STDHEX("abcde"),"length 5")
        quit
        ;
tValidRejectsNonHex(pass,fail)  ;@TEST "valid() rejects non-hex characters"
        do false^STDASSERT(.pass,.fail,$$valid^STDHEX("gh"),"contains g,h")
        do false^STDASSERT(.pass,.fail,$$valid^STDHEX("00gg"),"contains g")
        do false^STDASSERT(.pass,.fail,$$valid^STDHEX("ab!c"),"contains !")
        do false^STDASSERT(.pass,.fail,$$valid^STDHEX("abxy"),"contains x,y")
        quit
