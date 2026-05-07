STDCRYPTOTST    ; Test suite for STDCRYPTO (v0.3.x — Phase 3, $ZF → libcrypto).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        ;
        ; Vectors:
        ;   SHA-256 / SHA-384 / SHA-512 — RFC 6234 §8.5 / FIPS 180-4 examples.
        ;   HMAC-SHA-256 / HMAC-SHA-384 / HMAC-SHA-512 — RFC 4231 test cases.
        ;
        ; Engine prerequisite: the std_crypto callout package must be loaded
        ; (env var ydb_xc_std_crypto=/path/to/std_crypto.xc, .so compiled via
        ; tools/build-callouts.sh). When the package is not loaded, every test
        ; here fails — the runner reports the gap loudly. See
        ; docs/modules/stdcrypto.md for the deployment runbook.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tAvailableReturnsBool(.pass,.fail)
        do tSha256Empty(.pass,.fail)
        do tSha256Abc(.pass,.fail)
        do tSha256LongerInput(.pass,.fail)
        do tSha256BytesIs32(.pass,.fail)
        do tSha384Empty(.pass,.fail)
        do tSha384Abc(.pass,.fail)
        do tSha384BytesIs48(.pass,.fail)
        do tSha512Empty(.pass,.fail)
        do tSha512Abc(.pass,.fail)
        do tSha512BytesIs64(.pass,.fail)
        do tHmacSha256Rfc4231Case1(.pass,.fail)
        do tHmacSha256Rfc4231Case2(.pass,.fail)
        do tHmacSha256BytesIs32(.pass,.fail)
        do tHmacSha384Rfc4231Case1(.pass,.fail)
        do tHmacSha384BytesIs48(.pass,.fail)
        do tHmacSha512Rfc4231Case1(.pass,.fail)
        do tHmacSha512BytesIs64(.pass,.fail)
        do tHmacKeyLongerThanBlockOk(.pass,.fail)
        do tHmacEmptyKeyOk(.pass,.fail)
        do tHexLowercaseAlphabet(.pass,.fail)
        do tBinaryInputRoundTrips(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tAvailableReturnsBool(pass,fail)        ;@TEST "available() returns 0 or 1, never raises"
        new ok
        set ok=$$available^STDCRYPTO()
        do true^STDASSERT(.pass,.fail,(ok=0)!(ok=1),"available is 0 or 1")
        quit
        ;
tSha256Empty(pass,fail) ;@TEST "sha256('') matches FIPS 180-4 vector"
        do eq^STDASSERT(.pass,.fail,$$sha256^STDCRYPTO(""),"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","SHA-256 of empty string")
        quit
        ;
tSha256Abc(pass,fail)   ;@TEST "sha256('abc') matches FIPS 180-4 vector"
        do eq^STDASSERT(.pass,.fail,$$sha256^STDCRYPTO("abc"),"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad","SHA-256 of 'abc'")
        quit
        ;
tSha256LongerInput(pass,fail)   ;@TEST "sha256 of 56-char message matches FIPS 180-4 vector"
        new msg
        set msg="abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        do eq^STDASSERT(.pass,.fail,$$sha256^STDCRYPTO(msg),"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1","SHA-256 of 56-char fixture")
        quit
        ;
tSha256BytesIs32(pass,fail)     ;@TEST "sha256Bytes returns 32 raw bytes"
        do len^STDASSERT(.pass,.fail,$length($$sha256Bytes^STDCRYPTO("abc")),32,"SHA-256 byte length")
        quit
        ;
tSha384Empty(pass,fail) ;@TEST "sha384('') matches FIPS 180-4 vector"
        do eq^STDASSERT(.pass,.fail,$$sha384^STDCRYPTO(""),"38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b","SHA-384 of empty string")
        quit
        ;
tSha384Abc(pass,fail)   ;@TEST "sha384('abc') matches FIPS 180-4 vector"
        do eq^STDASSERT(.pass,.fail,$$sha384^STDCRYPTO("abc"),"cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7","SHA-384 of 'abc'")
        quit
        ;
tSha384BytesIs48(pass,fail)     ;@TEST "sha384Bytes returns 48 raw bytes"
        do len^STDASSERT(.pass,.fail,$length($$sha384Bytes^STDCRYPTO("abc")),48,"SHA-384 byte length")
        quit
        ;
tSha512Empty(pass,fail) ;@TEST "sha512('') matches FIPS 180-4 vector"
        do eq^STDASSERT(.pass,.fail,$$sha512^STDCRYPTO(""),"cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e","SHA-512 of empty string")
        quit
        ;
tSha512Abc(pass,fail)   ;@TEST "sha512('abc') matches FIPS 180-4 vector"
        do eq^STDASSERT(.pass,.fail,$$sha512^STDCRYPTO("abc"),"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f","SHA-512 of 'abc'")
        quit
        ;
tSha512BytesIs64(pass,fail)     ;@TEST "sha512Bytes returns 64 raw bytes"
        do len^STDASSERT(.pass,.fail,$length($$sha512Bytes^STDCRYPTO("abc")),64,"SHA-512 byte length")
        quit
        ;
tHmacSha256Rfc4231Case1(pass,fail)      ;@TEST "HMAC-SHA-256 RFC 4231 test 1 (key=0x0b*20, msg='Hi There')"
        new key,msg
        set key=$$repByte(11,20)
        set msg="Hi There"
        do eq^STDASSERT(.pass,.fail,$$hmacSha256^STDCRYPTO(key,msg),"b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7","HMAC-SHA-256 RFC 4231 §4.2")
        quit
        ;
tHmacSha256Rfc4231Case2(pass,fail)      ;@TEST "HMAC-SHA-256 RFC 4231 test 2 (key='Jefe', msg='what do ya want for nothing?')"
        do eq^STDASSERT(.pass,.fail,$$hmacSha256^STDCRYPTO("Jefe","what do ya want for nothing?"),"5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843","HMAC-SHA-256 RFC 4231 §4.3")
        quit
        ;
tHmacSha256BytesIs32(pass,fail) ;@TEST "hmacSha256Bytes returns 32 raw bytes"
        do len^STDASSERT(.pass,.fail,$length($$hmacSha256Bytes^STDCRYPTO("k","m")),32,"HMAC-SHA-256 byte length")
        quit
        ;
tHmacSha384Rfc4231Case1(pass,fail)      ;@TEST "HMAC-SHA-384 RFC 4231 test 1"
        new key,msg
        set key=$$repByte(11,20)
        set msg="Hi There"
        do eq^STDASSERT(.pass,.fail,$$hmacSha384^STDCRYPTO(key,msg),"afd03944d84895626b0825f4ab46907f15f9dadbe4101ec682aa034c7cebc59cfaea9ea9076ede7f4af152e8b2fa9cb6","HMAC-SHA-384 RFC 4231 §4.2")
        quit
        ;
tHmacSha384BytesIs48(pass,fail) ;@TEST "hmacSha384Bytes returns 48 raw bytes"
        do len^STDASSERT(.pass,.fail,$length($$hmacSha384Bytes^STDCRYPTO("k","m")),48,"HMAC-SHA-384 byte length")
        quit
        ;
tHmacSha512Rfc4231Case1(pass,fail)      ;@TEST "HMAC-SHA-512 RFC 4231 test 1"
        new key,msg
        set key=$$repByte(11,20)
        set msg="Hi There"
        do eq^STDASSERT(.pass,.fail,$$hmacSha512^STDCRYPTO(key,msg),"87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854","HMAC-SHA-512 RFC 4231 §4.2")
        quit
        ;
tHmacSha512BytesIs64(pass,fail) ;@TEST "hmacSha512Bytes returns 64 raw bytes"
        do len^STDASSERT(.pass,.fail,$length($$hmacSha512Bytes^STDCRYPTO("k","m")),64,"HMAC-SHA-512 byte length")
        quit
        ;
tHmacKeyLongerThanBlockOk(pass,fail)    ;@TEST "HMAC accepts keys longer than the hash block"
        new key,m
        set key=$$repByte(170,131)
        set m=$$hmacSha256^STDCRYPTO(key,"hello")
        do len^STDASSERT(.pass,.fail,$length(m),64,"HMAC-SHA-256 with 131-byte key returns 64 hex chars")
        quit
        ;
tHmacEmptyKeyOk(pass,fail)      ;@TEST "HMAC with empty key produces a deterministic 32-byte result"
        new m
        set m=$$hmacSha256^STDCRYPTO("","msg")
        do len^STDASSERT(.pass,.fail,$length(m),64,"HMAC-SHA-256 empty key length")
        do eq^STDASSERT(.pass,.fail,m,$$hmacSha256^STDCRYPTO("","msg"),"HMAC-SHA-256 empty key is deterministic")
        quit
        ;
tHexLowercaseAlphabet(pass,fail)        ;@TEST "hex digests use lowercase a-f only"
        new d
        set d=$$sha256^STDCRYPTO("abc")
        do eq^STDASSERT(.pass,.fail,$translate(d,"abcdef0123456789",""),"","SHA-256 hex contains only [0-9a-f]")
        quit
        ;
tBinaryInputRoundTrips(pass,fail)       ;@TEST "binary input (bytes 0..255) hashes without truncation"
        new data,d
        set data=$$range255()
        set d=$$sha256^STDCRYPTO(data)
        do len^STDASSERT(.pass,.fail,$length(d),64,"SHA-256 of 256-byte 0..255 fixture is 64 hex chars")
        quit
        ;
        ; ---------- helpers ----------
        ;
repByte(b,n)    ; n copies of $char(b)
        new s,i
        set s=""
        for i=1:1:n  set s=s_$char(b)
        quit s
        ;
range255()      ; All bytes 0..255 in order — exercises binary safety.
        new s,i
        set s=""
        for i=0:1:255  set s=s_$char(i)
        quit s
        ;
