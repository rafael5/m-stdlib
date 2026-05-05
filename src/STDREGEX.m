STDREGEX        ; m-stdlib — regular expressions (track L12, target tag v0.2.0).
        ;
        ; Public API. The compiled-pattern handle is a positive integer keyed
        ; under ^STDLIB($job,"stdregex",h,...); state is per-process and
        ; per-handle. free() drops it.
        ;
        ;   $$compile^STDREGEX(pattern)        — alloc handle, return h
        ;   $$valid^STDREGEX(pattern)          — 1 iff pattern parses
        ;   $$match^STDREGEX(h,s)              — 1 iff the entire s matches
        ;   $$search^STDREGEX(h,s)             — 1 iff any substring matches
        ;   $$find^STDREGEX(h,s)               — 1-indexed start of 1st match (0 = none)
        ;   findall^STDREGEX(h,s,.out)         — out(n)=match-string for every non-overlap
        ;   groups^STDREGEX(h,s,.g)            — g(0)=full match; g(k)=k-th capture group
        ;   $$replace^STDREGEX(h,s,repl)       — every match replaced by repl (\1..\9 in repl)
        ;   split^STDREGEX(h,s,.out)           — out(n)=segments between matches
        ;   free^STDREGEX(h)                   — release state
        ;
        ; Engine: Thompson-NFA on YDB; wraps $MATCH / $LOCATE on IRIS.
        ; (At this scaffolding stage all bodies are stubs that return safe
        ; defaults and do not yet recognise patterns. Implementation lands
        ; incrementally in v0.2.0 follow-on commits per
        ; docs/parallel-tracks.md L12.)
        ;
        ; v0.2.0 supported subset:
        ;   Literals, "." (any char except newline), "^"/"$" (string-anchor),
        ;   quantifiers "*", "+", "?", "{n}", "{n,}", "{n,m}" (greedy),
        ;   character classes "[abc]" / "[^abc]" / "[a-z]", predefined
        ;   classes \d \D \w \W \s \S, escapes \\ \. \^ \$ \( \) \[ \]
        ;   \{ \} \| \* \+ \? \n \t \r, alternation "|", grouping "(...)"
        ;   (capturing) and "(?:...)" (non-capturing).
        ;
        ; Out of scope at v0.2.0 — compile() will reject with
        ; U-STDREGEX-UNSUPPORTED once the parser lands:
        ;   Back-references (\1..\9 in pattern), lookaround ((?=...),
        ;   (?!...), (?<=...), (?<!...)), Unicode property classes
        ;   (\p{...}), inline modifiers ((?i), (?m), …), possessive
        ;   quantifiers (*+, ++, ?+).
        ; A follow-on STDREGEX_PCRE (Phase 3-adjacent) ships full PCRE
        ; via $ZF to libpcre2.
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDREGEX-BAD-PATTERN,        — parse error in pattern
        ;   ,U-STDREGEX-UNSUPPORTED,        — feature recognised but not in v0.2.0 subset
        ;   ,U-STDREGEX-NO-MATCH,           — groups() called but pattern did not match
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
compile(pattern)        ; Compile pattern into a handle.
        ; doc: Returns a positive integer; pass to match/search/find/findall/
        ; doc: groups/replace/split/free. Sets $ECODE to U-STDREGEX-BAD-PATTERN
        ; doc: on parse error or U-STDREGEX-UNSUPPORTED on a feature outside
        ; doc: the v0.2.0 subset.
        ; doc: Example: set h=$$compile^STDREGEX("\d+")
        ; Stub: allocate a handle and stash the source pattern. The lexer /
        ; parser / NFA construction land in the implementation passes.
        new handle
        set handle=$increment(^STDLIB($job,"stdregex"))
        set ^STDLIB($job,"stdregex",handle,"src")=$get(pattern)
        quit handle
        ;
free(h) ; Release the compiled-pattern state.
        ; doc: Idempotent. The handle must not be reused after free().
        ; doc: Example: do free^STDREGEX(h)
        kill ^STDLIB($job,"stdregex",h)
        quit
        ;
valid(pattern)  ; True iff pattern parses cleanly under the v0.2.0 subset.
        ; doc: Returns 1 for a parseable pattern, 0 otherwise. Does not
        ; doc: distinguish BAD-PATTERN from UNSUPPORTED — compile() does.
        ; doc: Example: write $$valid^STDREGEX("[a-z]+")  ; 1
        ; Stub: returns 0 unconditionally; replaced once the parser lands.
        quit 0
        ;
match(h,s)      ; True iff the entire string s matches the pattern.
        ; doc: Anchored on both ends — equivalent to "^pattern$" semantics.
        ; doc: Example: write $$match^STDREGEX(h,"42")  ; 1 if h compiled "\d+"
        ; Stub: returns 0; replaced by the NFA simulation.
        quit 0
        ;
search(h,s)     ; True iff any substring of s matches the pattern.
        ; doc: Unanchored unless the pattern itself uses ^ or $.
        ; doc: Example: write $$search^STDREGEX(h,"the 42 cats")  ; 1 for "\d+"
        ; Stub: returns 0; replaced by the NFA simulation.
        quit 0
        ;
find(h,s)       ; 1-indexed start of the first match in s; 0 if no match.
        ; doc: Example: write $$find^STDREGEX(h,"the 42 cats")  ; 5 for "\d+"
        ; Stub: returns 0; replaced by the NFA simulation.
        quit 0
        ;
findall(h,s,out)        ; Populate out(1..N) with every non-overlapping match text.
        ; doc: out is by-reference. After return, $order(out("")) walks the
        ; doc: matches in left-to-right order. Empty out if no match.
        ; doc: Example: do findall^STDREGEX(h,"a 1 b 22",.out)
        ; Stub: leaves out empty; replaced by the NFA simulation.
        quit
        ;
groups(h,s,g)   ; Populate g(0..N) with the full match text and each capture group.
        ; doc: g is by-reference. g(0) is the full match; g(k) for k>=1 is
        ; doc: the k-th capture group counted by '(' position. Capture-group
        ; doc: numbering ignores (?:...) non-capturing groups. Sets $ECODE to
        ; doc: U-STDREGEX-NO-MATCH if pattern does not match s.
        ; doc: Example: do groups^STDREGEX(h,"42-foo",.g)
        ; Stub: leaves g empty; replaced by the NFA simulation.
        quit
        ;
replace(h,s,repl)       ; Return s with every match replaced by repl.
        ; doc: \1..\9 in repl are expanded to the corresponding capture group
        ; doc: text. \\ in repl is a literal backslash.
        ; doc: Example: write $$replace^STDREGEX(h,"x42y","[\1]")  ; "x[42]y"
        ; Stub: returns s unchanged; replaced by the NFA simulation.
        quit $get(s)
        ;
split(h,s,out)  ; Populate out(1..N) with the segments of s between matches.
        ; doc: out is by-reference. Adjacent matches produce empty segments;
        ; doc: leading/trailing matches produce a leading/trailing empty
        ; doc: segment. Empty pattern is a parse error.
        ; doc: Example: do split^STDREGEX(h,"a,b,c",.out)
        ; Stub: leaves out empty; replaced by the NFA simulation.
        quit
        ;
