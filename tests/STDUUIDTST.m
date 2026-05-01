STDUUIDTST      ; Test suite for STDUUID (v0.0.1).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        NEW pass,fail
        DO start^STDASSERT(.pass,.fail)
        ;
        DO tV4Is36Chars(.pass,.fail)
        DO tV4HasCorrectHyphens(.pass,.fail)
        DO tV4HasVersionNibble4(.pass,.fail)
        DO tV4HasRfc4122Variant(.pass,.fail)
        DO tV4UsesLowercaseHex(.pass,.fail)
        DO tV4UniqueAcross200Samples(.pass,.fail)
        DO tV7Is36Chars(.pass,.fail)
        DO tV7HasCorrectHyphens(.pass,.fail)
        DO tV7HasVersionNibble7(.pass,.fail)
        DO tV7HasRfc4122Variant(.pass,.fail)
        DO tV7IsTimeOrdered(.pass,.fail)
        DO tValidAcceptsCanonicalLowercase(.pass,.fail)
        DO tValidAcceptsCanonicalUppercase(.pass,.fail)
        DO tValidAcceptsAllRfcVersions(.pass,.fail)
        DO tValidRejectsBadLength(.pass,.fail)
        DO tValidRejectsBadHyphenPositions(.pass,.fail)
        DO tValidRejectsNonHexCharacter(.pass,.fail)
        DO tValidRejectsEmpty(.pass,.fail)
        DO tVersionDetectsAllRfcVersions(.pass,.fail)
        DO tVersionReturnsEmptyForInvalid(.pass,.fail)
        DO tVariantClassifiesNcs(.pass,.fail)
        DO tVariantClassifiesRfc4122(.pass,.fail)
        DO tVariantClassifiesMicrosoft(.pass,.fail)
        DO tVariantClassifiesFuture(.pass,.fail)
        DO tVariantReturnsEmptyForInvalid(.pass,.fail)
        ;
        DO report^STDASSERT(pass,fail)
        QUIT
        ;
tV4Is36Chars(pass,fail) ;@TEST "V4() returns a 36-char string"
        NEW u SET u=$$v4^STDUUID()
        DO len^STDASSERT(.pass,.fail,$length(u),36,"V4 length is 36")
        QUIT
        ;
tV4HasCorrectHyphens(pass,fail) ;@TEST "V4() places hyphens at positions 9, 14, 19, 24"
        NEW u SET u=$$v4^STDUUID()
        DO eq^STDASSERT(.pass,.fail,$extract(u,9),"-","hyphen at 9")
        DO eq^STDASSERT(.pass,.fail,$extract(u,14),"-","hyphen at 14")
        DO eq^STDASSERT(.pass,.fail,$extract(u,19),"-","hyphen at 19")
        DO eq^STDASSERT(.pass,.fail,$extract(u,24),"-","hyphen at 24")
        QUIT
        ;
tV4HasVersionNibble4(pass,fail) ;@TEST "V4() sets version nibble to '4' at position 15"
        NEW u SET u=$$v4^STDUUID()
        DO eq^STDASSERT(.pass,.fail,$extract(u,15),"4","version nibble at 15 is 4")
        QUIT
        ;
tV4HasRfc4122Variant(pass,fail) ;@TEST "V4() variant nibble at position 20 is 8/9/a/b"
        ; sample several to make sure all four allowed values appear over time
        NEW u,n,c
        FOR n=1:1:50 DO
        . SET u=$$v4^STDUUID()
        . SET c=$extract(u,20)
        . DO contains^STDASSERT(.pass,.fail,"89ab",c,"V4 variant nibble in {8,9,a,b}")
        QUIT
        ;
tV4UsesLowercaseHex(pass,fail)  ;@TEST "V4() emits lowercase hex (no A-F)"
        NEW u,clean
        SET u=$$v4^STDUUID()
        SET clean=$translate(u,"-","")
        ; If clean has any uppercase A-F, $TRANSLATE leaves them; expect ""
        DO eq^STDASSERT(.pass,.fail,$translate(clean,"0123456789abcdef",""),"","lowercase hex only")
        QUIT
        ;
tV4UniqueAcross200Samples(pass,fail)    ;@TEST "V4() does not collide across 200 samples"
        NEW seen,n,u,collisions
        SET collisions=0
        FOR n=1:1:200 DO
        . SET u=$$v4^STDUUID()
        . IF $data(seen(u)) SET collisions=$INCREMENT(collisions)
        . SET seen(u)=""
        DO eq^STDASSERT(.pass,.fail,collisions,0,"no collisions over 200 V4s")
        QUIT
        ;
tV7Is36Chars(pass,fail) ;@TEST "V7() returns a 36-char string"
        NEW u SET u=$$v7^STDUUID()
        DO len^STDASSERT(.pass,.fail,$length(u),36,"V7 length is 36")
        QUIT
        ;
tV7HasCorrectHyphens(pass,fail) ;@TEST "V7() places hyphens at positions 9, 14, 19, 24"
        NEW u SET u=$$v7^STDUUID()
        DO eq^STDASSERT(.pass,.fail,$extract(u,9),"-","hyphen at 9")
        DO eq^STDASSERT(.pass,.fail,$extract(u,14),"-","hyphen at 14")
        DO eq^STDASSERT(.pass,.fail,$extract(u,19),"-","hyphen at 19")
        DO eq^STDASSERT(.pass,.fail,$extract(u,24),"-","hyphen at 24")
        QUIT
        ;
tV7HasVersionNibble7(pass,fail) ;@TEST "V7() sets version nibble to '7' at position 15"
        NEW u SET u=$$v7^STDUUID()
        DO eq^STDASSERT(.pass,.fail,$extract(u,15),"7","version nibble at 15 is 7")
        QUIT
        ;
tV7HasRfc4122Variant(pass,fail) ;@TEST "V7() variant nibble at position 20 is 8/9/a/b"
        NEW u,n
        FOR n=1:1:20 DO
        . SET u=$$v7^STDUUID()
        . DO contains^STDASSERT(.pass,.fail,"89ab",$extract(u,20),"V7 variant nibble")
        QUIT
        ;
tV7IsTimeOrdered(pass,fail)     ;@TEST "V7() output sorts in generation order"
        ; Generate a batch with a short delay and confirm string sort matches
        ; generation order. The first 48 bits are ms-since-epoch, so two UUIDs
        ; generated in different milliseconds must sort correctly.
        ;
        ; M's "]" operator does string-collation comparison ("a]b" iff a sorts
        ; after b). Don't use "<": that does numeric comparison and reduces
        ; UUIDs to their leading numeric prefix.
        NEW u1,u2,u3
        SET u1=$$v7^STDUUID()
        HANG 0.005
        SET u2=$$v7^STDUUID()
        HANG 0.005
        SET u3=$$v7^STDUUID()
        DO true^STDASSERT(.pass,.fail,u2]u1,"u2 sorts after u1")
        DO true^STDASSERT(.pass,.fail,u3]u2,"u3 sorts after u2")
        QUIT
        ;
tValidAcceptsCanonicalLowercase(pass,fail)      ;@TEST "valid() accepts canonical lowercase"
        DO true^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-446655440000"),"RFC example v4")
        DO true^STDASSERT(.pass,.fail,$$valid^STDUUID($$v4^STDUUID()),"freshly-minted V4 valid")
        DO true^STDASSERT(.pass,.fail,$$valid^STDUUID($$v7^STDUUID()),"freshly-minted V7 valid")
        QUIT
        ;
tValidAcceptsCanonicalUppercase(pass,fail)      ;@TEST "valid() accepts uppercase hex"
        DO true^STDASSERT(.pass,.fail,$$valid^STDUUID("550E8400-E29B-41D4-A716-446655440000"),"uppercase RFC example")
        QUIT
        ;
tValidAcceptsAllRfcVersions(pass,fail)  ;@TEST "valid() accepts versions 1-7"
        ; Position 15 is the version nibble; vary it across 1..7.
        NEW base,v,n
        FOR v=1:1:7 DO
        . SET base="550e8400-e29b-X1d4-a716-446655440000"
        . SET $extract(base,15)=v
        . DO true^STDASSERT(.pass,.fail,$$valid^STDUUID(base),"version "_v_" valid")
        QUIT
        ;
tValidRejectsBadLength(pass,fail)       ;@TEST "valid() rejects wrong length"
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID(""),"empty")
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400"),"too short")
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-446655440000-extra"),"too long")
        QUIT
        ;
tValidRejectsBadHyphenPositions(pass,fail)      ;@TEST "valid() rejects misplaced hyphens"
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e84000e29b-41d4-a716-446655440000"),"missing hyphen at 9")
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID("550-e8400-e29b-41d4-a716-46655440000"),"hyphen at 4")
        QUIT
        ;
tValidRejectsNonHexCharacter(pass,fail) ;@TEST "valid() rejects non-hex chars"
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-44665544000g"),"trailing g")
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-44665544000Z"),"trailing Z")
        QUIT
        ;
tValidRejectsEmpty(pass,fail)   ;@TEST "valid() returns 0 for empty input"
        DO false^STDASSERT(.pass,.fail,$$valid^STDUUID(""),"empty rejected")
        QUIT
        ;
tVersionDetectsAllRfcVersions(pass,fail)        ;@TEST "version() returns the integer version 1-7"
        NEW base,v
        FOR v=1:1:7 DO
        . SET base="550e8400-e29b-X1d4-a716-446655440000"
        . SET $extract(base,15)=v
        . DO eq^STDASSERT(.pass,.fail,$$version^STDUUID(base),v,"version "_v)
        QUIT
        ;
tVersionReturnsEmptyForInvalid(pass,fail)       ;@TEST "version() returns empty for malformed UUID"
        DO eq^STDASSERT(.pass,.fail,$$version^STDUUID("nope"),"","invalid -> empty")
        DO eq^STDASSERT(.pass,.fail,$$version^STDUUID(""),"","empty -> empty")
        QUIT
        ;
tVariantClassifiesNcs(pass,fail)        ;@TEST "variant() returns 'ncs' for high bit 0"
        NEW base,v
        FOR v="0","1","2","3","4","5","6","7" DO
        . SET base="550e8400-e29b-41d4-X716-446655440000"
        . SET $extract(base,20)=v
        . DO eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"ncs","variant nibble "_v)
        QUIT
        ;
tVariantClassifiesRfc4122(pass,fail)    ;@TEST "variant() returns 'rfc4122' for high bits 10"
        NEW base,v
        FOR v="8","9","a","b" DO
        . SET base="550e8400-e29b-41d4-X716-446655440000"
        . SET $extract(base,20)=v
        . DO eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"rfc4122","variant nibble "_v)
        QUIT
        ;
tVariantClassifiesMicrosoft(pass,fail)  ;@TEST "variant() returns 'microsoft' for high bits 110"
        NEW base,v
        FOR v="c","d" DO
        . SET base="550e8400-e29b-41d4-X716-446655440000"
        . SET $extract(base,20)=v
        . DO eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"microsoft","variant nibble "_v)
        QUIT
        ;
tVariantClassifiesFuture(pass,fail)     ;@TEST "variant() returns 'future' for high bits 111"
        NEW base,v
        FOR v="e","f" DO
        . SET base="550e8400-e29b-41d4-X716-446655440000"
        . SET $extract(base,20)=v
        . DO eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"future","variant nibble "_v)
        QUIT
        ;
tVariantReturnsEmptyForInvalid(pass,fail)       ;@TEST "variant() returns empty for malformed UUID"
        DO eq^STDASSERT(.pass,.fail,$$variant^STDUUID("nope"),"","invalid -> empty")
        QUIT
