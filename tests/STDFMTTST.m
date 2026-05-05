STDFMTTST       ; Test suite for STDFMT (v0.0.3).
        ; m-lint: disable-file=M-MOD-020
        ;
        ; Note on error-path coverage: STDFMT sets $ECODE on malformed
        ; templates / unknown types / missing args. Those error paths are
        ; specified and behave correctly when called from production
        ; procedure-form code, but they cannot be unit-tested via
        ; raises^STDASSERT today because STDASSERT.raises uses an arg-less
        ; QUIT in its $ETRAP handler, which fires M17 NOTEXTRINSIC when the
        ; error originates inside an extrinsic chain (which STDFMT is). See
        ; TOOLCHAIN-FINDINGS.md (filed against STDASSERT). The $ECODE
        ; contract for STDFMT is documented in docs/modules/stdfmt.md.
        ;
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tEmptyTemplate(.pass,.fail)
        do tLiteralOnly(.pass,.fail)
        do tEscapedBraces(.pass,.fail)
        do tEscapedBracesAdjacent(.pass,.fail)
        do tAutoPositional(.pass,.fail)
        do tIndexedPositional(.pass,.fail)
        do tIndexedReuse(.pass,.fail)
        do tIndexedOutOfOrder(.pass,.fail)
        do tNamedSimple(.pass,.fail)
        do tNamedMultiple(.pass,.fail)
        do tNamedReuse(.pass,.fail)
        do tTypeStringExplicit(.pass,.fail)
        do tTypeDecimal(.pass,.fail)
        do tTypeFloatDefaultPrecision(.pass,.fail)
        do tTypeFloatExplicitPrecision(.pass,.fail)
        do tTypeFloatRounding(.pass,.fail)
        do tTypeHexLower(.pass,.fail)
        do tTypeHexUpper(.pass,.fail)
        do tTypeOctal(.pass,.fail)
        do tTypeBinary(.pass,.fail)
        do tTypeNegativeNumbers(.pass,.fail)
        do tTypeZero(.pass,.fail)
        do tWidthRightAlignDefault(.pass,.fail)
        do tWidthLeftAlignString(.pass,.fail)
        do tWidthExplicitRight(.pass,.fail)
        do tWidthExplicitLeft(.pass,.fail)
        do tWidthCenter(.pass,.fail)
        do tWidthShorterThanValue(.pass,.fail)
        do tFillCharRight(.pass,.fail)
        do tFillCharLeft(.pass,.fail)
        do tFillCharCenter(.pass,.fail)
        do tFillZeroForNumbers(.pass,.fail)
        do tStringPrecisionTruncates(.pass,.fail)
        do tCombinedSpec(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tEmptyTemplate(pass,fail)       ;@TEST "f() with empty template returns empty"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT(""),"","empty in -> empty out")
        quit
        ;
tLiteralOnly(pass,fail) ;@TEST "f() with no placeholders is identity"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("hello world"),"hello world","passthrough")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("123"),"123","numeric literal")
        quit
        ;
tEscapedBraces(pass,fail)       ;@TEST "f() escapes {{ -> { and }} -> }"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{{}}"),"{}","both escapes")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("a{{b}}c"),"a{b}c","interleaved")
        quit
        ;
tEscapedBracesAdjacent(pass,fail)       ;@TEST "f() handles escapes around real placeholders"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{{{}}}","x"),"{x}","escape, sub, escape")
        quit
        ;
tAutoPositional(pass,fail)      ;@TEST "f() auto-numbers consecutive {} fields"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{} {}","hello","world"),"hello world","two args")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{}{}{}","a","b","c"),"abc","three args, no sep")
        quit
        ;
tIndexedPositional(pass,fail)   ;@TEST "f() honours {N} explicit indices"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{0} {1}","a","b"),"a b","0 then 1")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{1} {0}","a","b"),"b a","reversed")
        quit
        ;
tIndexedReuse(pass,fail)        ;@TEST "f() reuses indexed args"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{0} {0} {0}","x"),"x x x","one arg, three references")
        quit
        ;
tIndexedOutOfOrder(pass,fail)   ;@TEST "f() permits indices in any order"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{2}-{0}-{1}","a","b","c"),"c-a-b","2,0,1")
        quit
        ;
tNamedSimple(pass,fail) ;@TEST "fn() substitutes named placeholders"
        new args
        set args("name")="alice"
        do eq^STDASSERT(.pass,.fail,$$fn^STDFMT("hello {name}",.args),"hello alice","name lookup")
        quit
        ;
tNamedMultiple(pass,fail)       ;@TEST "fn() handles multiple distinct names"
        new args
        set args("first")="Ada"
        set args("last")="Lovelace"
        do eq^STDASSERT(.pass,.fail,$$fn^STDFMT("{first} {last}",.args),"Ada Lovelace","two names")
        quit
        ;
tNamedReuse(pass,fail)  ;@TEST "fn() reuses named args"
        new args
        set args("x")=42
        do eq^STDASSERT(.pass,.fail,$$fn^STDFMT("{x}+{x}={x}",.args),"42+42=42","reuse three times")
        quit
        ;
tTypeStringExplicit(pass,fail)  ;@TEST "{:s} renders as string"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:s}","hello"),"hello","explicit s")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:s}",42),"42","s coerces non-string")
        quit
        ;
tTypeDecimal(pass,fail) ;@TEST "{:d} renders integer in base 10"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:d}",42),"42","positive")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:d}",0),"0","zero")
        quit
        ;
tTypeFloatDefaultPrecision(pass,fail)   ;@TEST "{:f} default precision is 6"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:f}",3.14),"3.140000","pad to 6")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:f}",1),"1.000000","integer arg")
        quit
        ;
tTypeFloatExplicitPrecision(pass,fail)  ;@TEST "{:.Nf} sets precision to N"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:.2f}",3.14),"3.14","two places")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:.0f}",3.7),"4","zero places, rounds")
        quit
        ;
tTypeFloatRounding(pass,fail)   ;@TEST "{:.Nf} uses $FNUMBER rounding"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:.3f}",3.14159),"3.142","round up")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:.3f}",3.14149),"3.141","round down")
        quit
        ;
tTypeHexLower(pass,fail)        ;@TEST "{:x} renders integer in lowercase hex"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:x}",255),"ff","255")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:x}",16),"10","16")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:x}",0),"0","zero")
        quit
        ;
tTypeHexUpper(pass,fail)        ;@TEST "{:X} renders integer in uppercase hex"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:X}",255),"FF","255")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:X}",3735928559),"DEADBEEF","32-bit value")
        quit
        ;
tTypeOctal(pass,fail)   ;@TEST "{:o} renders integer in base 8"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:o}",8),"10","8 in octal")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:o}",64),"100","64 in octal")
        quit
        ;
tTypeBinary(pass,fail)  ;@TEST "{:b} renders integer in base 2"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:b}",5),"101","5 in binary")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:b}",255),"11111111","255 in binary")
        quit
        ;
tTypeNegativeNumbers(pass,fail) ;@TEST "negative integers render with leading '-'"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:d}",-42),"-42","decimal")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:x}",-255),"-ff","hex")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:b}",-2),"-10","binary")
        quit
        ;
tTypeZero(pass,fail)    ;@TEST "zero renders as '0' in every numeric base"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:d}",0),"0","decimal")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:x}",0),"0","hex")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:o}",0),"0","octal")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:b}",0),"0","binary")
        quit
        ;
tWidthRightAlignDefault(pass,fail)      ;@TEST "numeric defaults to right-align with space fill"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:5d}",42),"   42","width 5, default >")
        quit
        ;
tWidthLeftAlignString(pass,fail)        ;@TEST "string defaults to left-align with space fill"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:5}","hi"),"hi   ","width 5, default <")
        quit
        ;
tWidthExplicitRight(pass,fail)  ;@TEST "{:>N} forces right-align"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:>5}","hi"),"   hi","string right-aligned")
        quit
        ;
tWidthExplicitLeft(pass,fail)   ;@TEST "{:<N} forces left-align"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:<5d}",42),"42   ","number left-aligned")
        quit
        ;
tWidthCenter(pass,fail) ;@TEST "{:^N} centers"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:^6}","hi"),"  hi  ","even pad split")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:^5}","hi")," hi  ","odd pad: extra goes right")
        quit
        ;
tWidthShorterThanValue(pass,fail)       ;@TEST "width < |value| does not truncate"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:3}","longer"),"longer","value preserved")
        quit
        ;
tFillCharRight(pass,fail)       ;@TEST "{:X>N} fills with custom char"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:*>5}","x"),"****x","star fill, right-align")
        quit
        ;
tFillCharLeft(pass,fail)        ;@TEST "{:X<N} fills with custom char on the right"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:.<5}","x"),"x....","dot fill, left-align")
        quit
        ;
tFillCharCenter(pass,fail)      ;@TEST "{:X^N} fills both sides with custom char"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:-^5}","x"),"--x--","dash fill, center")
        quit
        ;
tFillZeroForNumbers(pass,fail)  ;@TEST "{:0>Nd} zero-pads numeric"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:0>5d}",42),"00042","zero-pad to 5")
        quit
        ;
tStringPrecisionTruncates(pass,fail)    ;@TEST "{:.Ns} truncates string to N chars"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:.3s}","hello"),"hel","truncate to 3")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:.0s}","hello"),"","truncate to 0")
        quit
        ;
tCombinedSpec(pass,fail)        ;@TEST "fill + align + width + precision + type compose"
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:*^10.4s}","abcdefgh"),"***abcd***","center width 10, prec 4")
        do eq^STDASSERT(.pass,.fail,$$f^STDFMT("{:->8.2f}",3.14159),"----3.14","dash-pad width 8, prec 2")
        quit
