STDUUIDTST      ; Test suite for STDUUID (v0.0.1).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tV4Is36Chars(.pass,.fail)
        do tV4HasCorrectHyphens(.pass,.fail)
        do tV4HasVersionNibble4(.pass,.fail)
        do tV4HasRfc4122Variant(.pass,.fail)
        do tV4UsesLowercaseHex(.pass,.fail)
        do tV4UniqueAcross200Samples(.pass,.fail)
        do tV7Is36Chars(.pass,.fail)
        do tV7HasCorrectHyphens(.pass,.fail)
        do tV7HasVersionNibble7(.pass,.fail)
        do tV7HasRfc4122Variant(.pass,.fail)
        do tV7IsTimeOrdered(.pass,.fail)
        do tValidAcceptsCanonicalLowercase(.pass,.fail)
        do tValidAcceptsCanonicalUppercase(.pass,.fail)
        do tValidAcceptsAllRfcVersions(.pass,.fail)
        do tValidRejectsBadLength(.pass,.fail)
        do tValidRejectsBadHyphenPositions(.pass,.fail)
        do tValidRejectsNonHexCharacter(.pass,.fail)
        do tValidRejectsEmpty(.pass,.fail)
        do tVersionDetectsAllRfcVersions(.pass,.fail)
        do tVersionReturnsEmptyForInvalid(.pass,.fail)
        do tVariantClassifiesNcs(.pass,.fail)
        do tVariantClassifiesRfc4122(.pass,.fail)
        do tVariantClassifiesMicrosoft(.pass,.fail)
        do tVariantClassifiesFuture(.pass,.fail)
        do tVariantReturnsEmptyForInvalid(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tV4Is36Chars(pass,fail) ;@TEST "V4() returns a 36-char string"
        new u set u=$$v4^STDUUID()
        do len^STDASSERT(.pass,.fail,$length(u),36,"V4 length is 36")
        quit
        ;
tV4HasCorrectHyphens(pass,fail) ;@TEST "V4() places hyphens at positions 9, 14, 19, 24"
        new u set u=$$v4^STDUUID()
        do eq^STDASSERT(.pass,.fail,$extract(u,9),"-","hyphen at 9")
        do eq^STDASSERT(.pass,.fail,$extract(u,14),"-","hyphen at 14")
        do eq^STDASSERT(.pass,.fail,$extract(u,19),"-","hyphen at 19")
        do eq^STDASSERT(.pass,.fail,$extract(u,24),"-","hyphen at 24")
        quit
        ;
tV4HasVersionNibble4(pass,fail) ;@TEST "V4() sets version nibble to '4' at position 15"
        new u set u=$$v4^STDUUID()
        do eq^STDASSERT(.pass,.fail,$extract(u,15),"4","version nibble at 15 is 4")
        quit
        ;
tV4HasRfc4122Variant(pass,fail) ;@TEST "V4() variant nibble at position 20 is 8/9/a/b"
        ; sample several to make sure all four allowed values appear over time
        new u,n,c
        for n=1:1:50 do
        . set u=$$v4^STDUUID()
        . set c=$extract(u,20)
        . do contains^STDASSERT(.pass,.fail,"89ab",c,"V4 variant nibble in {8,9,a,b}")
        quit
        ;
tV4UsesLowercaseHex(pass,fail)  ;@TEST "V4() emits lowercase hex (no A-F)"
        new u,clean
        set u=$$v4^STDUUID()
        set clean=$translate(u,"-","")
        ; If clean has any uppercase A-F, $TRANSLATE leaves them; expect ""
        do eq^STDASSERT(.pass,.fail,$translate(clean,"0123456789abcdef",""),"","lowercase hex only")
        quit
        ;
tV4UniqueAcross200Samples(pass,fail)    ;@TEST "V4() does not collide across 200 samples"
        new seen,n,u,collisions
        set collisions=0
        for n=1:1:200 do
        . set u=$$v4^STDUUID()
        . if $data(seen(u)) set collisions=$increment(collisions)
        . set seen(u)=""
        do eq^STDASSERT(.pass,.fail,collisions,0,"no collisions over 200 V4s")
        quit
        ;
tV7Is36Chars(pass,fail) ;@TEST "V7() returns a 36-char string"
        new u set u=$$v7^STDUUID()
        do len^STDASSERT(.pass,.fail,$length(u),36,"V7 length is 36")
        quit
        ;
tV7HasCorrectHyphens(pass,fail) ;@TEST "V7() places hyphens at positions 9, 14, 19, 24"
        new u set u=$$v7^STDUUID()
        do eq^STDASSERT(.pass,.fail,$extract(u,9),"-","hyphen at 9")
        do eq^STDASSERT(.pass,.fail,$extract(u,14),"-","hyphen at 14")
        do eq^STDASSERT(.pass,.fail,$extract(u,19),"-","hyphen at 19")
        do eq^STDASSERT(.pass,.fail,$extract(u,24),"-","hyphen at 24")
        quit
        ;
tV7HasVersionNibble7(pass,fail) ;@TEST "V7() sets version nibble to '7' at position 15"
        new u set u=$$v7^STDUUID()
        do eq^STDASSERT(.pass,.fail,$extract(u,15),"7","version nibble at 15 is 7")
        quit
        ;
tV7HasRfc4122Variant(pass,fail) ;@TEST "V7() variant nibble at position 20 is 8/9/a/b"
        new u,n
        for n=1:1:20 do
        . set u=$$v7^STDUUID()
        . do contains^STDASSERT(.pass,.fail,"89ab",$extract(u,20),"V7 variant nibble")
        quit
        ;
tV7IsTimeOrdered(pass,fail)     ;@TEST "V7() output sorts in generation order"
        ; Generate a batch with a short delay and confirm string sort matches
        ; generation order. The first 48 bits are ms-since-epoch, so two UUIDs
        ; generated in different milliseconds must sort correctly.
        ;
        ; M's "]" operator does string-collation comparison ("a]b" iff a sorts
        ; after b). Don't use "<": that does numeric comparison and reduces
        ; UUIDs to their leading numeric prefix.
        new u1,u2,u3
        set u1=$$v7^STDUUID()
        hang 0.005
        set u2=$$v7^STDUUID()
        hang 0.005
        set u3=$$v7^STDUUID()
        do true^STDASSERT(.pass,.fail,u2]u1,"u2 sorts after u1")
        do true^STDASSERT(.pass,.fail,u3]u2,"u3 sorts after u2")
        quit
        ;
tValidAcceptsCanonicalLowercase(pass,fail)      ;@TEST "valid() accepts canonical lowercase"
        do true^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-446655440000"),"RFC example v4")
        do true^STDASSERT(.pass,.fail,$$valid^STDUUID($$v4^STDUUID()),"freshly-minted V4 valid")
        do true^STDASSERT(.pass,.fail,$$valid^STDUUID($$v7^STDUUID()),"freshly-minted V7 valid")
        quit
        ;
tValidAcceptsCanonicalUppercase(pass,fail)      ;@TEST "valid() accepts uppercase hex"
        do true^STDASSERT(.pass,.fail,$$valid^STDUUID("550E8400-E29B-41D4-A716-446655440000"),"uppercase RFC example")
        quit
        ;
tValidAcceptsAllRfcVersions(pass,fail)  ;@TEST "valid() accepts versions 1-7"
        ; Position 15 is the version nibble; vary it across 1..7.
        new base,v,n
        for v=1:1:7 do
        . set base="550e8400-e29b-X1d4-a716-446655440000"
        . set $extract(base,15)=v
        . do true^STDASSERT(.pass,.fail,$$valid^STDUUID(base),"version "_v_" valid")
        quit
        ;
tValidRejectsBadLength(pass,fail)       ;@TEST "valid() rejects wrong length"
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID(""),"empty")
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400"),"too short")
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-446655440000-extra"),"too long")
        quit
        ;
tValidRejectsBadHyphenPositions(pass,fail)      ;@TEST "valid() rejects misplaced hyphens"
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e84000e29b-41d4-a716-446655440000"),"missing hyphen at 9")
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID("550-e8400-e29b-41d4-a716-46655440000"),"hyphen at 4")
        quit
        ;
tValidRejectsNonHexCharacter(pass,fail) ;@TEST "valid() rejects non-hex chars"
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-44665544000g"),"trailing g")
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID("550e8400-e29b-41d4-a716-44665544000Z"),"trailing Z")
        quit
        ;
tValidRejectsEmpty(pass,fail)   ;@TEST "valid() returns 0 for empty input"
        do false^STDASSERT(.pass,.fail,$$valid^STDUUID(""),"empty rejected")
        quit
        ;
tVersionDetectsAllRfcVersions(pass,fail)        ;@TEST "version() returns the integer version 1-7"
        new base,v
        for v=1:1:7 do
        . set base="550e8400-e29b-X1d4-a716-446655440000"
        . set $extract(base,15)=v
        . do eq^STDASSERT(.pass,.fail,$$version^STDUUID(base),v,"version "_v)
        quit
        ;
tVersionReturnsEmptyForInvalid(pass,fail)       ;@TEST "version() returns empty for malformed UUID"
        do eq^STDASSERT(.pass,.fail,$$version^STDUUID("nope"),"","invalid -> empty")
        do eq^STDASSERT(.pass,.fail,$$version^STDUUID(""),"","empty -> empty")
        quit
        ;
tVariantClassifiesNcs(pass,fail)        ;@TEST "variant() returns 'ncs' for high bit 0"
        new base,v
        for v="0","1","2","3","4","5","6","7" do
        . set base="550e8400-e29b-41d4-X716-446655440000"
        . set $extract(base,20)=v
        . do eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"ncs","variant nibble "_v)
        quit
        ;
tVariantClassifiesRfc4122(pass,fail)    ;@TEST "variant() returns 'rfc4122' for high bits 10"
        new base,v
        for v="8","9","a","b" do
        . set base="550e8400-e29b-41d4-X716-446655440000"
        . set $extract(base,20)=v
        . do eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"rfc4122","variant nibble "_v)
        quit
        ;
tVariantClassifiesMicrosoft(pass,fail)  ;@TEST "variant() returns 'microsoft' for high bits 110"
        new base,v
        for v="c","d" do
        . set base="550e8400-e29b-41d4-X716-446655440000"
        . set $extract(base,20)=v
        . do eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"microsoft","variant nibble "_v)
        quit
        ;
tVariantClassifiesFuture(pass,fail)     ;@TEST "variant() returns 'future' for high bits 111"
        new base,v
        for v="e","f" do
        . set base="550e8400-e29b-41d4-X716-446655440000"
        . set $extract(base,20)=v
        . do eq^STDASSERT(.pass,.fail,$$variant^STDUUID(base),"future","variant nibble "_v)
        quit
        ;
tVariantReturnsEmptyForInvalid(pass,fail)       ;@TEST "variant() returns empty for malformed UUID"
        do eq^STDASSERT(.pass,.fail,$$variant^STDUUID("nope"),"","invalid -> empty")
        quit
