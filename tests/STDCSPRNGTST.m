STDCSPRNGTST    ; Test suite for STDCSPRNG (v0.2.x — Pri 1, Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tAvailable(.pass,.fail)
        do tUseCalloutReturnsBoolean(.pass,.fail)
        do tBytesEmptyForZero(.pass,.fail)
        do tBytesExactLength(.pass,.fail)
        do tBytesDistinctAcrossCalls(.pass,.fail)
        do tBytesCoversByteRange(.pass,.fail)
        do tBytesNegativeRaises(.pass,.fail)
        do tHexEmptyForZero(.pass,.fail)
        do tHexLengthIsTwiceN(.pass,.fail)
        do tHexLowercaseAlphabet(.pass,.fail)
        do tBase64EmptyForZero(.pass,.fail)
        do tBase64UrlSafeAlphabet(.pass,.fail)
        do tBase64NoPadding(.pass,.fail)
        do tTokenEmptyForZero(.pass,.fail)
        do tTokenExactLength(.pass,.fail)
        do tTokenUrlSafeAlphabet(.pass,.fail)
        do tTokenNegativeRaises(.pass,.fail)
        do tIntSingletonRange(.pass,.fail)
        do tIntDieRollInRange(.pass,.fail)
        do tIntDieRollHitsAllValues(.pass,.fail)
        do tIntLargeRangeInBounds(.pass,.fail)
        do tIntBadRangeRaises(.pass,.fail)
        do tIntNegativeBoundsOk(.pass,.fail)
        do tUuid4Is36Chars(.pass,.fail)
        do tUuid4HasCorrectHyphens(.pass,.fail)
        do tUuid4HasVersionNibble4(.pass,.fail)
        do tUuid4HasRfc4122Variant(.pass,.fail)
        do tUuid4PassesValidate(.pass,.fail)
        do tUuid4UniqueAcross200Samples(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tAvailable(pass,fail)   ;@TEST "available() reports /dev/urandom is readable in this env"
        do true^STDASSERT(.pass,.fail,$$available^STDCSPRNG(),"/dev/urandom present")
        quit
        ;
tUseCalloutReturnsBoolean(pass,fail)    ;@TEST "useCallout() returns 0 or 1 without raising"
        ; Probe never raises; result depends on whether ydb_xc_std_csprng /
        ; cs_random.so are deployed. Either value is acceptable — the test
        ; just pins the contract that the probe is total over the
        ; deployment matrix.
        new v
        set v=$$useCallout^STDCSPRNG()
        do true^STDASSERT(.pass,.fail,(v=0)!(v=1),"useCallout() in {0,1}")
        quit
        ;
tBytesEmptyForZero(pass,fail)   ;@TEST "bytes(0) returns the empty string"
        do eq^STDASSERT(.pass,.fail,$$bytes^STDCSPRNG(0),"","bytes(0) is empty")
        quit
        ;
tBytesExactLength(pass,fail)    ;@TEST "bytes(n) returns a string of exactly n characters"
        new b
        set b=$$bytes^STDCSPRNG(1)
        do len^STDASSERT(.pass,.fail,$length(b),1,"bytes(1) length")
        set b=$$bytes^STDCSPRNG(16)
        do len^STDASSERT(.pass,.fail,$length(b),16,"bytes(16) length")
        set b=$$bytes^STDCSPRNG(64)
        do len^STDASSERT(.pass,.fail,$length(b),64,"bytes(64) length")
        quit
        ;
tBytesDistinctAcrossCalls(pass,fail)    ;@TEST "two consecutive bytes(32) draws differ"
        ; Collision probability between two 32-byte CSPRNG draws is 2^-256.
        new b1,b2
        set b1=$$bytes^STDCSPRNG(32)
        set b2=$$bytes^STDCSPRNG(32)
        do ne^STDASSERT(.pass,.fail,b1,b2,"two 32-byte draws differ")
        quit
        ;
tBytesCoversByteRange(pass,fail)        ;@TEST "bytes() output spans low and high byte values"
        ; Over 256 random bytes, the chance that no byte exceeds 127 is
        ; (128/256)^256 = 2^-256. Same for missing every byte under 128.
        new b,n,c,sawLow,sawHigh,i
        set b=$$bytes^STDCSPRNG(256)
        set sawLow=0,sawHigh=0
        for i=1:1:256 do
        . set c=$ascii(b,i)
        . if c<128 set sawLow=1
        . if c>127 set sawHigh=1
        do true^STDASSERT(.pass,.fail,sawLow,"saw byte <128")
        do true^STDASSERT(.pass,.fail,sawHigh,"saw byte >=128")
        quit
        ;
tBytesNegativeRaises(pass,fail) ;@TEST "bytes(-1) sets $ECODE=,U-STDCSPRNG-BAD-COUNT,"
        do raises^STDASSERT(.pass,.fail,"set x=$$bytes^STDCSPRNG(-1)","U-STDCSPRNG-BAD-COUNT","negative count rejected")
        quit
        ;
tHexEmptyForZero(pass,fail)     ;@TEST "hex(0) returns the empty string"
        do eq^STDASSERT(.pass,.fail,$$hex^STDCSPRNG(0),"","hex(0) is empty")
        quit
        ;
tHexLengthIsTwiceN(pass,fail)   ;@TEST "hex(n) returns 2n characters"
        do len^STDASSERT(.pass,.fail,$length($$hex^STDCSPRNG(1)),2,"hex(1) length")
        do len^STDASSERT(.pass,.fail,$length($$hex^STDCSPRNG(16)),32,"hex(16) length")
        do len^STDASSERT(.pass,.fail,$length($$hex^STDCSPRNG(32)),64,"hex(32) length")
        quit
        ;
tHexLowercaseAlphabet(pass,fail)        ;@TEST "hex(n) emits only lowercase 0-9a-f"
        new h
        set h=$$hex^STDCSPRNG(64)
        do eq^STDASSERT(.pass,.fail,$translate(h,"0123456789abcdef",""),"","lowercase hex only")
        quit
        ;
tBase64EmptyForZero(pass,fail)  ;@TEST "base64(0) returns the empty string"
        do eq^STDASSERT(.pass,.fail,$$base64^STDCSPRNG(0),"","base64(0) is empty")
        quit
        ;
tBase64UrlSafeAlphabet(pass,fail)       ;@TEST "base64(n) uses URL-safe alphabet (- and _, no + or /)"
        new t,alpha
        set alpha="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        set t=$$base64^STDCSPRNG(96)
        do eq^STDASSERT(.pass,.fail,$translate(t,alpha,""),"","URL-safe alphabet only")
        quit
        ;
tBase64NoPadding(pass,fail)     ;@TEST "base64(n) emits no '=' padding"
        new t
        set t=$$base64^STDCSPRNG(33)  ; 33 bytes -> 44 chars before padding strip
        do false^STDASSERT(.pass,.fail,t["=","no padding char")
        quit
        ;
tTokenEmptyForZero(pass,fail)   ;@TEST "token(0) returns the empty string"
        do eq^STDASSERT(.pass,.fail,$$token^STDCSPRNG(0),"","token(0) is empty")
        quit
        ;
tTokenExactLength(pass,fail)    ;@TEST "token(n) returns exactly n characters"
        do len^STDASSERT(.pass,.fail,$length($$token^STDCSPRNG(1)),1,"token(1) length")
        do len^STDASSERT(.pass,.fail,$length($$token^STDCSPRNG(22)),22,"token(22) length")
        do len^STDASSERT(.pass,.fail,$length($$token^STDCSPRNG(64)),64,"token(64) length")
        quit
        ;
tTokenUrlSafeAlphabet(pass,fail)        ;@TEST "token(n) uses only [A-Za-z0-9_-]"
        new t,alpha
        set alpha="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
        set t=$$token^STDCSPRNG(128)
        do eq^STDASSERT(.pass,.fail,$translate(t,alpha,""),"","alphabet [A-Za-z0-9_-]")
        quit
        ;
tTokenNegativeRaises(pass,fail) ;@TEST "token(-1) sets $ECODE=,U-STDCSPRNG-BAD-COUNT,"
        do raises^STDASSERT(.pass,.fail,"set x=$$token^STDCSPRNG(-1)","U-STDCSPRNG-BAD-COUNT","negative count rejected")
        quit
        ;
tIntSingletonRange(pass,fail)   ;@TEST "int(n,n) returns n without sampling"
        do eq^STDASSERT(.pass,.fail,$$int^STDCSPRNG(7,7),7,"int(7,7) is 7")
        do eq^STDASSERT(.pass,.fail,$$int^STDCSPRNG(0,0),0,"int(0,0) is 0")
        do eq^STDASSERT(.pass,.fail,$$int^STDCSPRNG(-3,-3),-3,"int(-3,-3) is -3")
        quit
        ;
tIntDieRollInRange(pass,fail)   ;@TEST "int(1,6) draws stay in [1,6]"
        new v,n
        for n=1:1:200 do
        . set v=$$int^STDCSPRNG(1,6)
        . do true^STDASSERT(.pass,.fail,(v'<1)&(v'>6),"die roll in [1,6]: "_v)
        quit
        ;
tIntDieRollHitsAllValues(pass,fail)     ;@TEST "int(1,6) over 600 draws hits every value 1..6"
        ; Probability of missing any single value over 600 draws is
        ; (5/6)^600 < 10^-47.
        new seen,n,v,i,missing
        for n=1:1:600 set seen($$int^STDCSPRNG(1,6))=""
        set missing=""
        for i=1:1:6 if '$data(seen(i)) set missing=missing_i_","
        do eq^STDASSERT(.pass,.fail,missing,"","every die face seen")
        quit
        ;
tIntLargeRangeInBounds(pass,fail)       ;@TEST "int(1000000,9999999) draws fit the 7-digit range"
        new v,n
        for n=1:1:50 do
        . set v=$$int^STDCSPRNG(1000000,9999999)
        . do true^STDASSERT(.pass,.fail,(v'<1000000)&(v'>9999999),"large-range int in bounds: "_v)
        quit
        ;
tIntBadRangeRaises(pass,fail)   ;@TEST "int(max,min) with max<min sets $ECODE=,U-STDCSPRNG-BAD-RANGE,"
        do raises^STDASSERT(.pass,.fail,"set x=$$int^STDCSPRNG(10,5)","U-STDCSPRNG-BAD-RANGE","reversed range rejected")
        quit
        ;
tIntNegativeBoundsOk(pass,fail) ;@TEST "int() accepts negative bounds"
        new v,n
        for n=1:1:50 do
        . set v=$$int^STDCSPRNG(-10,-1)
        . do true^STDASSERT(.pass,.fail,(v'<-10)&(v'>-1),"negative-range int in bounds: "_v)
        quit
        ;
tUuid4Is36Chars(pass,fail)      ;@TEST "uuid4() returns a 36-char string"
        do len^STDASSERT(.pass,.fail,$length($$uuid4^STDCSPRNG()),36,"uuid4 length is 36")
        quit
        ;
tUuid4HasCorrectHyphens(pass,fail)      ;@TEST "uuid4() places hyphens at positions 9, 14, 19, 24"
        new u set u=$$uuid4^STDCSPRNG()
        do eq^STDASSERT(.pass,.fail,$extract(u,9),"-","hyphen at 9")
        do eq^STDASSERT(.pass,.fail,$extract(u,14),"-","hyphen at 14")
        do eq^STDASSERT(.pass,.fail,$extract(u,19),"-","hyphen at 19")
        do eq^STDASSERT(.pass,.fail,$extract(u,24),"-","hyphen at 24")
        quit
        ;
tUuid4HasVersionNibble4(pass,fail)      ;@TEST "uuid4() sets version nibble to '4' at position 15"
        new u,n
        for n=1:1:20 do
        . set u=$$uuid4^STDCSPRNG()
        . do eq^STDASSERT(.pass,.fail,$extract(u,15),"4","version nibble at 15 is 4")
        quit
        ;
tUuid4HasRfc4122Variant(pass,fail)      ;@TEST "uuid4() variant nibble at 20 is 8/9/a/b"
        new u,n
        for n=1:1:50 do
        . set u=$$uuid4^STDCSPRNG()
        . do contains^STDASSERT(.pass,.fail,"89ab",$extract(u,20),"variant nibble in {8,9,a,b}")
        quit
        ;
tUuid4PassesValidate(pass,fail) ;@TEST "uuid4() output is accepted by valid^STDUUID"
        do true^STDASSERT(.pass,.fail,$$valid^STDUUID($$uuid4^STDCSPRNG()),"valid^STDUUID accepts uuid4")
        quit
        ;
tUuid4UniqueAcross200Samples(pass,fail) ;@TEST "uuid4() does not collide across 200 samples"
        new seen,n,u,collisions
        set collisions=0
        for n=1:1:200 do
        . set u=$$uuid4^STDCSPRNG()
        . if $data(seen(u)) set collisions=$increment(collisions)
        . set seen(u)=""
        do eq^STDASSERT(.pass,.fail,collisions,0,"no collisions over 200 uuid4()")
        quit
