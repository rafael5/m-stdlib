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
        ; doc: @param s       string  the string to pad
        ; doc: @param n       int     target width (no-op if $LENGTH(s) >= n)
        ; doc: @param c       string  fill character (default " "; first char only used)
        ; doc: @returns       string  s left-padded with c to width n
        ; doc: @example       write $$pad^STDSTR("5",3,"0")  ; "005"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$padLeft^STDSTR, $$padRight^STDSTR
        quit $$padLeft(s,n,$get(c," "))
        ;
padLeft(s,n,c)  ; Left-pad s to width n with c (default " "). Returns s unchanged
        ; doc: @param s       string  the string to pad
        ; doc: @param n       int     target width
        ; doc: @param c       string  fill character (default " "; first char only used)
        ; doc: @returns       string  s left-padded; s unchanged if $LENGTH(s) >= n
        ; doc: @example       write $$padLeft^STDSTR("ab",6,"-")  ; "----ab"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$pad^STDSTR, $$padRight^STDSTR
        ; doc: if $LENGTH(s) ≥ n. c may be multi-char; pad is built by char-wise
        ; doc: replication of $EXTRACT(c,1).
        new ch,need
        set ch=$select($data(c)#10:c,1:" ")
        if ch="" set ch=" "
        set need=n-$length(s)
        if need'>0 quit s
        quit $$repeat($extract(ch,1),need)_s
        ;
padRight(s,n,c) ; Right-pad s to width n with c (default " "). Returns s unchanged
        ; doc: @param s       string  the string to pad
        ; doc: @param n       int     target width
        ; doc: @param c       string  fill character (default " "; first char only used)
        ; doc: @returns       string  s right-padded; s unchanged if $LENGTH(s) >= n
        ; doc: @example       write $$padRight^STDSTR("ab",6,"-")  ; "ab----"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$pad^STDSTR, $$padLeft^STDSTR
        ; doc: if $LENGTH(s) ≥ n.
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
        ; doc: @param s       string  the string to trim
        ; doc: @returns       string  s with outer whitespace stripped
        ; doc: @example       write $$trim^STDSTR("  hello  ")  ; "hello"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$trimLeft^STDSTR, $$trimRight^STDSTR
        ; doc: Internal whitespace is preserved verbatim. Empty input returns "".
        quit $$trimRight($$trimLeft(s))
        ;
trimLeft(s)     ; Strip leading whitespace only.
        ; doc: @param s       string  the string to trim
        ; doc: @returns       string  s with leading whitespace stripped
        ; doc: @example       write $$trimLeft^STDSTR("  x  ")  ; "x  "
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$trim^STDSTR, $$trimRight^STDSTR
        new t,ws
        set ws=" "_$char(9,10,13)
        set t=s
        for  quit:t=""  quit:'($extract(t,1)?1(1" ",1C))  set t=$extract(t,2,$length(t))
        quit t
        ;
trimRight(s)    ; Strip trailing whitespace only.
        ; doc: @param s       string  the string to trim
        ; doc: @returns       string  s with trailing whitespace stripped
        ; doc: @example       write $$trimRight^STDSTR("  x  ")  ; "  x"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$trim^STDSTR, $$trimLeft^STDSTR
        new t
        set t=s
        for  quit:t=""  quit:'($extract(t,$length(t))?1(1" ",1C))  set t=$extract(t,1,$length(t)-1)
        quit t
        ;
        ; ---------- public API: replacement ----------
        ;
replaceAll(s,find,repl) ; Replace every non-overlapping left-to-right occurrence.
        ; doc: @param s       string  the string to scan
        ; doc: @param find    string  the substring to match (multi-char allowed)
        ; doc: @param repl    string  the replacement
        ; doc: @returns       string  s with every non-overlapping match replaced
        ; doc: @example       write $$replaceAll^STDSTR("a-b-c","-","+")  ; "a+b+c"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$split^STDSTR
        ; doc: An empty `find` returns s unchanged (no infinite loop). Replacement
        ; doc: is non-recursive — the new bytes inserted by `repl` are not rescanned.
        ; doc: Implementation: $piece-based join — split s on find, rejoin with repl.
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
        ; doc: @param s       string  the string to split
        ; doc: @param sep     string  the separator (multi-char allowed)
        ; doc: @param out     array   by-ref local; killed then populated as out(1..N)
        ; doc: @returns       int     number of pieces (0 if s="" or sep="")
        ; doc: @example       set n=$$split^STDSTR("a,b,c",",",.out)  ; n=3
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$replaceAll^STDSTR
        ; doc: Trailing separator yields a trailing empty element; "a,b," → 3 pieces.
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
        ; doc: @param s       string  the string to test
        ; doc: @param prefix  string  the prefix to look for
        ; doc: @returns       bool    1 iff s begins with prefix; empty prefix returns 1
        ; doc: @example       write $$startsWith^STDSTR("hello world","hello")  ; 1
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$endsWith^STDSTR
        if prefix="" quit 1
        if $length(prefix)>$length(s) quit 0
        quit $select($extract(s,1,$length(prefix))=prefix:1,1:0)
        ;
endsWith(s,suffix)      ; Return 1 iff s ends with suffix; else 0. Empty suffix → 1.
        ; doc: @param s       string  the string to test
        ; doc: @param suffix  string  the suffix to look for
        ; doc: @returns       bool    1 iff s ends with suffix; empty suffix returns 1
        ; doc: @example       write $$endsWith^STDSTR("hello world","world")  ; 1
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$startsWith^STDSTR
        new sl,fl
        if suffix="" quit 1
        set sl=$length(s),fl=$length(suffix)
        if fl>sl quit 0
        quit $select($extract(s,sl-fl+1,sl)=suffix:1,1:0)
        ;
        ; ---------- public API: case conversion ----------
        ;
toLowerASCII(s) ; A-Z → a-z; preserves all other characters.
        ; doc: @param s       string  the string to lowercase
        ; doc: @returns       string  s with A-Z mapped to a-z (other chars unchanged)
        ; doc: @example       write $$toLowerASCII^STDSTR("Hello-World")  ; "hello-world"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$toUpperASCII^STDSTR
        ; doc: Operates byte-wise — no locale awareness, no Unicode handling.
        ; doc: For full Unicode case folding wait on a future STDUNICODE.
        quit $translate(s,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz")
        ;
toUpperASCII(s) ; a-z → A-Z; preserves all other characters.
        ; doc: @param s       string  the string to uppercase
        ; doc: @returns       string  s with a-z mapped to A-Z (other chars unchanged)
        ; doc: @example       write $$toUpperASCII^STDSTR("Hello-World")  ; "HELLO-WORLD"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$toLowerASCII^STDSTR
        ; doc: Operates byte-wise — no locale awareness, no Unicode handling.
        quit $translate(s,"abcdefghijklmnopqrstuvwxyz","ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        ;
        ; ---------- public API: repetition ----------
        ;
repeat(s,n)     ; Concatenate s with itself n times. Returns "" for n ≤ 0 or s="".
        ; doc: @param s       string  the string to repeat
        ; doc: @param n       int     repetition count (n <= 0 yields "")
        ; doc: @returns       string  s concatenated with itself n times
        ; doc: @example       write $$repeat^STDSTR("ab",3)  ; "ababab"
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$padLeft^STDSTR, $$padRight^STDSTR
        if n'>0 quit ""
        if s="" quit ""
        new out,i
        set out=""
        for i=1:1:n  set out=out_s
        quit out
