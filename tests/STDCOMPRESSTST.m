STDCOMPRESSTST  ; Test suite for STDCOMPRESS (v0.3.x — Phase 3 H2).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tAvailable(.pass,.fail)
        ;
        do tGzipMagicBytes(.pass,.fail)
        do tGzipRoundTripAscii(.pass,.fail)
        do tGzipRoundTripEmpty(.pass,.fail)
        do tGzipRoundTripBinary(.pass,.fail)
        do tGzipRoundTripLarge(.pass,.fail)
        do tGzipDefaultLevelMatchesSix(.pass,.fail)
        do tGzipBadLevelLowReturnsZero(.pass,.fail)
        do tGzipBadLevelHighReturnsZero(.pass,.fail)
        do tGunzipRejectsNonGzip(.pass,.fail)
        do tGunzipRejectsTruncated(.pass,.fail)
        ;
        do tDeflateRoundTripAscii(.pass,.fail)
        do tDeflateRoundTripEmpty(.pass,.fail)
        do tDeflateRoundTripBinary(.pass,.fail)
        do tInflateRejectsGarbage(.pass,.fail)
        ;
        do tZstdMagicBytes(.pass,.fail)
        do tZstdRoundTripAscii(.pass,.fail)
        do tZstdRoundTripEmpty(.pass,.fail)
        do tZstdRoundTripBinary(.pass,.fail)
        do tZstdRoundTripLarge(.pass,.fail)
        do tZstdDefaultLevelMatchesThree(.pass,.fail)
        do tZstdBadLevelLowReturnsZero(.pass,.fail)
        do tZstdBadLevelHighReturnsZero(.pass,.fail)
        do tZstdDecompressRejectsGarbage(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- helpers ----
        ;
mkBinary(n)     ; Build an n-byte string of bytes 0..255 cycling.
        ; doc: $ZCHAR for byte semantics regardless of $ZCHSET.
        new s,i
        set s=""
        for i=0:1:n-1 set s=s_$zchar(i#256)
        quit s
        ;
mkRepeated(unit,times)  ; Build unit repeated `times` times — highly compressible.
        new s,i
        set s=""
        for i=1:1:times set s=s_unit
        quit s
        ;
        ; ---- available() ----
        ;
tAvailable(pass,fail)   ;@TEST "available() reports both libz and libzstd are loaded"
        do eq^STDASSERT(.pass,.fail,$$available^STDCOMPRESS(),"","both backends present")
        quit
        ;
        ; ---- gzip / gunzip ----
        ;
tGzipMagicBytes(pass,fail)      ;@TEST "gzip output begins with the RFC 1952 magic bytes 1F 8B"
        new buf,ok
        set ok=$$gzip^STDCOMPRESS("hello",.buf)
        do true^STDASSERT(.pass,.fail,ok,"gzip succeeded")
        do eq^STDASSERT(.pass,.fail,$zascii($extract(buf,1)),31,"byte 1 = 0x1F")
        do eq^STDASSERT(.pass,.fail,$zascii($extract(buf,2)),139,"byte 2 = 0x8B")
        quit
        ;
tGzipRoundTripAscii(pass,fail)  ;@TEST "gzip -> gunzip round-trips an ASCII string"
        new buf,raw
        do true^STDASSERT(.pass,.fail,$$gzip^STDCOMPRESS("the quick brown fox jumps over the lazy dog",.buf),"compress")
        do true^STDASSERT(.pass,.fail,$$gunzip^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,"the quick brown fox jumps over the lazy dog","round-trip")
        quit
        ;
tGzipRoundTripEmpty(pass,fail)  ;@TEST "gzip -> gunzip round-trips the empty string"
        new buf,raw
        do true^STDASSERT(.pass,.fail,$$gzip^STDCOMPRESS("",.buf),"compress empty")
        do true^STDASSERT(.pass,.fail,$$gunzip^STDCOMPRESS(buf,.raw),"decompress empty")
        do eq^STDASSERT(.pass,.fail,raw,"","empty round-trip")
        quit
        ;
tGzipRoundTripBinary(pass,fail) ;@TEST "gzip -> gunzip preserves bytes 0x00..0xFF"
        new src,buf,raw
        set src=$$mkBinary(256)
        do true^STDASSERT(.pass,.fail,$$gzip^STDCOMPRESS(src,.buf),"compress 256-byte cycle")
        do true^STDASSERT(.pass,.fail,$$gunzip^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,src,"binary round-trip")
        quit
        ;
tGzipRoundTripLarge(pass,fail)  ;@TEST "gzip -> gunzip handles a highly-compressible 10KB string"
        new src,buf,raw
        set src=$$mkRepeated("abcdefghij",1000)
        do true^STDASSERT(.pass,.fail,$$gzip^STDCOMPRESS(src,.buf),"compress 10KB")
        do true^STDASSERT(.pass,.fail,$length(buf)<200,"compressed size << 10KB")
        do true^STDASSERT(.pass,.fail,$$gunzip^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,src,"large round-trip")
        quit
        ;
tGzipDefaultLevelMatchesSix(pass,fail)  ;@TEST "gzip() default level equals gzip(...,6)"
        new a,b
        do true^STDASSERT(.pass,.fail,$$gzip^STDCOMPRESS("foobar",.a),"default-level compress")
        do true^STDASSERT(.pass,.fail,$$gzip^STDCOMPRESS("foobar",.b,6),"explicit level 6 compress")
        do eq^STDASSERT(.pass,.fail,a,b,"default = level 6")
        quit
        ;
tGzipBadLevelLowReturnsZero(pass,fail)  ;@TEST "gzip() with level=0 raises BAD-LEVEL"
        do raises^STDASSERT(.pass,.fail,"new buf set buf=$$gzip^STDCOMPRESS(""x"",.buf,0)","BAD-LEVEL","level 0 rejected with BAD-LEVEL")
        quit
        ;
tGzipBadLevelHighReturnsZero(pass,fail) ;@TEST "gzip() with level=10 raises BAD-LEVEL"
        do raises^STDASSERT(.pass,.fail,"new buf set buf=$$gzip^STDCOMPRESS(""x"",.buf,10)","BAD-LEVEL","level 10 rejected with BAD-LEVEL")
        quit
        ;
tGunzipRejectsNonGzip(pass,fail)        ;@TEST "gunzip() of non-gzip bytes raises LIBZ-FAIL"
        do raises^STDASSERT(.pass,.fail,"new raw set raw=$$gunzip^STDCOMPRESS(""not a gzip stream"",.raw)","LIBZ-FAIL","non-gzip raises LIBZ-FAIL")
        quit
        ;
tGunzipRejectsTruncated(pass,fail)      ;@TEST "gunzip() of a truncated gzip frame raises LIBZ-FAIL"
        new buf
        do true^STDASSERT(.pass,.fail,$$gzip^STDCOMPRESS("the quick brown fox",.buf),"valid compress")
        set buf=$extract(buf,1,$length(buf)-4)
        do raises^STDASSERT(.pass,.fail,"new raw set raw=$$gunzip^STDCOMPRESS(buf,.raw)","LIBZ-FAIL","truncated raises LIBZ-FAIL")
        quit
        ;
        ; ---- deflate / inflate (raw RFC 1951) ----
        ;
tDeflateRoundTripAscii(pass,fail)       ;@TEST "deflate -> inflate round-trips an ASCII string"
        new buf,raw
        do true^STDASSERT(.pass,.fail,$$deflate^STDCOMPRESS("the quick brown fox",.buf),"compress")
        do true^STDASSERT(.pass,.fail,$$inflate^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,"the quick brown fox","round-trip")
        quit
        ;
tDeflateRoundTripEmpty(pass,fail)       ;@TEST "deflate -> inflate round-trips the empty string"
        new buf,raw
        do true^STDASSERT(.pass,.fail,$$deflate^STDCOMPRESS("",.buf),"compress empty")
        do true^STDASSERT(.pass,.fail,$$inflate^STDCOMPRESS(buf,.raw),"decompress empty")
        do eq^STDASSERT(.pass,.fail,raw,"","empty round-trip")
        quit
        ;
tDeflateRoundTripBinary(pass,fail)      ;@TEST "deflate -> inflate preserves bytes 0x00..0xFF"
        new src,buf,raw
        set src=$$mkBinary(256)
        do true^STDASSERT(.pass,.fail,$$deflate^STDCOMPRESS(src,.buf),"compress")
        do true^STDASSERT(.pass,.fail,$$inflate^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,src,"binary round-trip")
        quit
        ;
tInflateRejectsGarbage(pass,fail)       ;@TEST "inflate() of garbage bytes raises LIBZ-FAIL"
        do raises^STDASSERT(.pass,.fail,"new raw set raw=$$inflate^STDCOMPRESS($zchar(0,0,0,0,0),.raw)","LIBZ-FAIL","garbage raises LIBZ-FAIL")
        quit
        ;
        ; ---- zstd ----
        ;
tZstdMagicBytes(pass,fail)      ;@TEST "zstd output begins with the RFC 8478 magic 28 B5 2F FD"
        new buf,ok
        set ok=$$zstdCompress^STDCOMPRESS("hello",.buf)
        do true^STDASSERT(.pass,.fail,ok,"zstd compress succeeded")
        do eq^STDASSERT(.pass,.fail,$zascii($extract(buf,1)),40,"byte 1 = 0x28")
        do eq^STDASSERT(.pass,.fail,$zascii($extract(buf,2)),181,"byte 2 = 0xB5")
        do eq^STDASSERT(.pass,.fail,$zascii($extract(buf,3)),47,"byte 3 = 0x2F")
        do eq^STDASSERT(.pass,.fail,$zascii($extract(buf,4)),253,"byte 4 = 0xFD")
        quit
        ;
tZstdRoundTripAscii(pass,fail)  ;@TEST "zstdCompress -> zstdDecompress round-trips ASCII"
        new buf,raw
        do true^STDASSERT(.pass,.fail,$$zstdCompress^STDCOMPRESS("the quick brown fox jumps over the lazy dog",.buf),"compress")
        do true^STDASSERT(.pass,.fail,$$zstdDecompress^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,"the quick brown fox jumps over the lazy dog","round-trip")
        quit
        ;
tZstdRoundTripEmpty(pass,fail)  ;@TEST "zstd round-trips the empty string"
        new buf,raw
        do true^STDASSERT(.pass,.fail,$$zstdCompress^STDCOMPRESS("",.buf),"compress empty")
        do true^STDASSERT(.pass,.fail,$$zstdDecompress^STDCOMPRESS(buf,.raw),"decompress empty")
        do eq^STDASSERT(.pass,.fail,raw,"","empty round-trip")
        quit
        ;
tZstdRoundTripBinary(pass,fail) ;@TEST "zstd preserves bytes 0x00..0xFF"
        new src,buf,raw
        set src=$$mkBinary(256)
        do true^STDASSERT(.pass,.fail,$$zstdCompress^STDCOMPRESS(src,.buf),"compress")
        do true^STDASSERT(.pass,.fail,$$zstdDecompress^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,src,"binary round-trip")
        quit
        ;
tZstdRoundTripLarge(pass,fail)  ;@TEST "zstd handles a highly-compressible 10KB string"
        new src,buf,raw
        set src=$$mkRepeated("abcdefghij",1000)
        do true^STDASSERT(.pass,.fail,$$zstdCompress^STDCOMPRESS(src,.buf),"compress 10KB")
        do true^STDASSERT(.pass,.fail,$length(buf)<200,"compressed size << 10KB")
        do true^STDASSERT(.pass,.fail,$$zstdDecompress^STDCOMPRESS(buf,.raw),"decompress")
        do eq^STDASSERT(.pass,.fail,raw,src,"large round-trip")
        quit
        ;
tZstdDefaultLevelMatchesThree(pass,fail)        ;@TEST "zstdCompress() default level equals level=3"
        new a,b
        do true^STDASSERT(.pass,.fail,$$zstdCompress^STDCOMPRESS("foobar",.a),"default-level")
        do true^STDASSERT(.pass,.fail,$$zstdCompress^STDCOMPRESS("foobar",.b,3),"explicit 3")
        do eq^STDASSERT(.pass,.fail,a,b,"default = 3")
        quit
        ;
tZstdBadLevelLowReturnsZero(pass,fail)  ;@TEST "zstdCompress() with level=0 raises BAD-LEVEL"
        do raises^STDASSERT(.pass,.fail,"new buf set buf=$$zstdCompress^STDCOMPRESS(""x"",.buf,0)","BAD-LEVEL","level 0 rejected with BAD-LEVEL")
        quit
        ;
tZstdBadLevelHighReturnsZero(pass,fail) ;@TEST "zstdCompress() with level=23 raises BAD-LEVEL"
        do raises^STDASSERT(.pass,.fail,"new buf set buf=$$zstdCompress^STDCOMPRESS(""x"",.buf,23)","BAD-LEVEL","level 23 rejected with BAD-LEVEL")
        quit
        ;
tZstdDecompressRejectsGarbage(pass,fail)        ;@TEST "zstdDecompress() of non-zstd bytes raises LIBZSTD-FAIL"
        do raises^STDASSERT(.pass,.fail,"new raw set raw=$$zstdDecompress^STDCOMPRESS(""not a zstd frame"",.raw)","LIBZSTD-FAIL","non-zstd raises LIBZSTD-FAIL")
        quit
        ;
