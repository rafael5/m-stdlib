STDSTR  ; m-stdlib — String helpers (pad / trim / split / replaceAll / case / repeat).
        ;
        ; Public extrinsics:
        ;   $$pad^STDSTR(s,n,c?)         — alias for padLeft (numeric formatting default)
        ;   $$padLeft^STDSTR(s,n,c?)     — left-pad s to width n with c (default " ")
        ;   $$padRight^STDSTR(s,n,c?)    — right-pad s to width n with c (default " ")
        ;   $$trim^STDSTR(s)             — strip leading and trailing whitespace
        ;   $$trimLeft^STDSTR(s)         — strip leading whitespace only
        ;   $$trimRight^STDSTR(s)        — strip trailing whitespace only
        ;   $$replaceAll^STDSTR(s,find,repl) — replace every non-overlapping occurrence
        ;   $$split^STDSTR(s,sep,.out)   — split on sep; populate out(1..N); return N
        ;   $$startsWith^STDSTR(s,prefix) — predicate: does s begin with prefix?
        ;   $$endsWith^STDSTR(s,suffix)  — predicate: does s end with suffix?
        ;   $$toLowerASCII^STDSTR(s)     — A-Z → a-z (ASCII only; preserves non-alpha)
        ;   $$toUpperASCII^STDSTR(s)     — a-z → A-Z (ASCII only; preserves non-alpha)
        ;   $$repeat^STDSTR(s,n)         — concatenate s with itself n times
        ;
        ; Whitespace for trim/trimLeft/trimRight is the four ASCII characters
        ; space ($C(32)), tab ($C(9)), LF ($C(10)), CR ($C(13)). Unicode
        ; whitespace classes (NBSP, ideographic space, etc.) are deliberately
        ; not stripped — keeps trim() byte-faithful and idempotent under any
        ; $ZCHSET mode.
        ;
        ; Pure-M throughout: $translate, $piece, $find, $extract, $length —
        ; no STDREGEX dep, no $Z* extensions. Runs unchanged on YDB and IRIS.
        ;
        quit
        ;
        ; ---------- public API: padding ----------
        ;
pad(s,n,c)      ; Alias for padLeft — common numeric-formatting shorthand.
        ; doc: Example: write $$pad^STDSTR("5",3,"0")  ; "005"
        quit $$padLeft(s,n,$get(c," "))
        ;
padLeft(s,n,c)  ; Left-pad s to width n with c (default " "). Returns s unchanged
        ; doc: if $LENGTH(s) ≥ n. c may be multi-char; pad is built by char-wise
        ; doc: replication of $EXTRACT(c,1).
        ; doc: Example: write $$padLeft^STDSTR("ab",6,"-")  ; "----ab"
        new ch,need
        set ch=$select($data(c)#10:c,1:" ")
        if ch="" set ch=" "
        set need=n-$length(s)
        if need'>0 quit s
        quit $$repeat($extract(ch,1),need)_s
        ;
padRight(s,n,c) ; Right-pad s to width n with c (default " "). Returns s unchanged
        ; doc: if $LENGTH(s) ≥ n.
        ; doc: Example: write $$padRight^STDSTR("ab",6,"-")  ; "ab----"
        new ch,need
        set ch=$select($data(c)#10:c,1:" ")
        if ch="" set ch=" "
        set need=n-$length(s)
        if need'>0 quit s
        quit s_$$repeat($extract(ch,1),need)
        ;
        ; ---------- public API: trimming ----------
        ;
trim(s) ; Strip leading and trailing whitespace (space / tab / LF / CR).
        ; doc: Internal whitespace is preserved verbatim. Empty input returns "".
        ; doc: Example: write $$trim^STDSTR("  hello  ")  ; "hello"
        quit $$trimRight($$trimLeft(s))
        ;
trimLeft(s)     ; Strip leading whitespace only.
        ; doc: Example: write $$trimLeft^STDSTR("  x  ")  ; "x  "
        new t,ws
        set ws=" "_$char(9,10,13)
        set t=s
        for  quit:t=""  quit:'($extract(t,1)?1(1" ",1C))  set t=$extract(t,2,$length(t))
        quit t
        ;
trimRight(s)    ; Strip trailing whitespace only.
        ; doc: Example: write $$trimRight^STDSTR("  x  ")  ; "  x"
        new t
        set t=s
        for  quit:t=""  quit:'($extract(t,$length(t))?1(1" ",1C))  set t=$extract(t,1,$length(t)-1)
        quit t
        ;
        ; ---------- public API: replacement ----------
        ;
replaceAll(s,find,repl) ; Replace every non-overlapping left-to-right occurrence.
        ; doc: An empty `find` returns s unchanged (no infinite loop).
        ; doc: Replacement is non-recursive — the new bytes inserted by `repl`
        ; doc: are not rescanned for further matches.
        ; doc: Implementation: $piece-based join — split s on find, rejoin with repl.
        ; doc: Example: write $$replaceAll^STDSTR("a-b-c","-","+")  ; "a+b+c"
        if find="" quit s
        new n,i,out
        set n=$length(s,find)
        if n<2 quit s
        set out=$piece(s,find,1)
        for i=2:1:n  set out=out_repl_$piece(s,find,i)
        quit out
        ;
        ; ---------- public API: splitting ----------
        ;
split(s,sep,out)        ; Split s on sep; populate out(1..N); return N.
        ; doc: Empty input returns 0 with out untouched (post-kill).
        ; doc: Multi-char `sep` is supported — splits on the literal sequence.
        ; doc: Trailing separator yields a trailing empty element; "a,b," → 3 pieces.
        ; doc: Example: set n=$$split^STDSTR("a,b,c",",",.out)  ; n=3
        kill out
        if s="" quit 0
        if sep="" quit 0
        new n,i
        set n=$length(s,sep)
        for i=1:1:n  set out(i)=$piece(s,sep,i)
        quit n
        ;
        ; ---------- public API: predicates ----------
        ;
startsWith(s,prefix)    ; Return 1 iff s begins with prefix; else 0. Empty prefix → 1.
        ; doc: Example: write $$startsWith^STDSTR("hello world","hello")  ; 1
        if prefix="" quit 1
        if $length(prefix)>$length(s) quit 0
        quit $select($extract(s,1,$length(prefix))=prefix:1,1:0)
        ;
endsWith(s,suffix)      ; Return 1 iff s ends with suffix; else 0. Empty suffix → 1.
        ; doc: Example: write $$endsWith^STDSTR("hello world","world")  ; 1
        new sl,fl
        if suffix="" quit 1
        set sl=$length(s),fl=$length(suffix)
        if fl>sl quit 0
        quit $select($extract(s,sl-fl+1,sl)=suffix:1,1:0)
        ;
        ; ---------- public API: case conversion ----------
        ;
toLowerASCII(s) ; A-Z → a-z; preserves all other characters.
        ; doc: Operates byte-wise — no locale awareness, no Unicode handling.
        ; doc: For full Unicode case folding wait on a future STDUNICODE.
        ; doc: Example: write $$toLowerASCII^STDSTR("Hello-World")  ; "hello-world"
        quit $translate(s,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")
        ;
toUpperASCII(s) ; a-z → A-Z; preserves all other characters.
        ; doc: Operates byte-wise — no locale awareness, no Unicode handling.
        ; doc: Example: write $$toUpperASCII^STDSTR("Hello-World")  ; "HELLO-WORLD"
        quit $translate(s,"abcdefghijklmnopqrstuvwxyz","ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        ;
        ; ---------- public API: repetition ----------
        ;
repeat(s,n)     ; Concatenate s with itself n times. Returns "" for n ≤ 0 or s="".
        ; doc: Example: write $$repeat^STDSTR("ab",3)  ; "ababab"
        if n'>0 quit ""
        if s="" quit ""
        new out,i
        set out=""
        for i=1:1:n  set out=out_s
        quit out
