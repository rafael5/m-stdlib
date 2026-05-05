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
        ; Pass A (this commit) ships the lexer + parser → AST. Passes B–E
        ; land the NFA construction, simulation, capture tracking, and
        ; findall/replace/split. Until then, the engine entry points
        ; (match/search/find/findall/groups/replace/split) remain safe-
        ; default stubs so the harness can report per-pass progress.
        ;
        ; v0.2.0 supported subset:
        ;   Literals, "." (any char except newline), "^"/"$" (string-anchor),
        ;   quantifiers "*", "+", "?", "{n}", "{n,}", "{n,m}" (greedy),
        ;   character classes "[abc]" / "[^abc]" / "[a-z]", predefined
        ;   classes \d \D \w \W \s \S, escapes \\ \. \^ \$ \( \) \[ \]
        ;   \{ \} \| \* \+ \? \n \t \r, alternation "|", grouping "(...)"
        ;   (capturing) and "(?:...)" (non-capturing).
        ;
        ; Out of scope at v0.2.0 — compile() rejects with U-STDREGEX-UNSUPPORTED:
        ;   Back-references in the pattern (\1..\9), lookaround ((?=...),
        ;   (?!...), (?<=...), (?<!...), named groups (?P<...>, (?<...>)),
        ;   Unicode property classes (\p{...}, \P{...}), inline modifiers
        ;   ((?i), (?m), …), possessive (*+, ++, ?+) and lazy (*?, +?, ??)
        ;   quantifiers.
        ; A follow-on STDREGEX_PCRE (Phase 3-adjacent) ships full PCRE
        ; via $ZF to libpcre2.
        ;
        ; AST representation. After a successful parse, compile() commits the
        ; AST to ^STDLIB($job,"stdregex",h,"ast",id,...) under integer ids
        ; allocated densely from 1; ^...,h,"root") names the root id. Each
        ; node carries a "type" subscript:
        ;   literal  — char            — "char"
        ;   dot      — (no extras)
        ;   anchor   — "sym" = "^"|"$"
        ;   pred     — "sym" = d|D|w|W|s|S
        ;   klass    — "negated" = 0|1; "item",N,"kind" = char|range|pred,
        ;              with "char" or ("lo"+"hi") or "sym"
        ;   star,plus,quest — "child" = childId
        ;   range    — "min", "max" (max="" = unbounded), "child"
        ;   concat   — "child",1..N
        ;   alt      — "branch",1..N
        ;   group    — "capturing" = 0|1; "groupNum" (when capturing); "child"
        ;
        ; Errors set $ECODE to one of:
        ;   ,U-STDREGEX-BAD-PATTERN,        — parse error in pattern
        ;   ,U-STDREGEX-UNSUPPORTED,        — feature outside the v0.2.0 subset
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
        new ast,root,err,handle,src
        set src=$get(pattern)
        set err=$$parse(src,.ast,.root)
        ; Why two checks: setting $ECODE in raise() fires the caller's
        ; $ETRAP, and YDB resumes execution one physical line *below* the
        ; line that fired the trap. A single-line `do raise quit ""` would
        ; bypass its own quit, so the next line is a safety-net quit.
        if err'="" do raise(err)
        if err'="" quit ""
        set handle=$increment(^STDLIB($job,"stdregex"))
        set ^STDLIB($job,"stdregex",handle,"src")=src
        set ^STDLIB($job,"stdregex",handle,"root")=root
        merge ^STDLIB($job,"stdregex",handle,"ast")=ast
        do buildNfa(handle)
        quit handle
        ;
raise(err)      ; Raise a U-STDREGEX-<err> error code via a fresh frame.
        ; doc: Internal — fires the caller's $ETRAP from a nested frame so
        ; doc: that the trap's QUIT-with-empty-$ECODE resumes execution
        ; doc: at a known safe point in the caller (a guarded quit), not
        ; doc: in the middle of post-error cleanup.
        set $ecode=",U-STDREGEX-"_err_","
        quit
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
        new ast,root,err
        set err=$$parse($get(pattern),.ast,.root)
        quit err=""
        ;
match(h,s)      ; True iff the entire string s matches the pattern.
        ; doc: Anchored on both ends — equivalent to "^pattern$" semantics.
        ; doc: Example: write $$match^STDREGEX(h,"42")  ; 1 if h compiled "\d+"
        ; Stub: NFA simulation lands in Pass C.
        quit 0
        ;
search(h,s)     ; True iff any substring of s matches the pattern.
        ; doc: Unanchored unless the pattern itself uses ^ or $.
        ; doc: Example: write $$search^STDREGEX(h,"the 42 cats")  ; 1 for "\d+"
        ; Stub: NFA simulation lands in Pass C.
        quit 0
        ;
find(h,s)       ; 1-indexed start of the first match in s; 0 if no match.
        ; doc: Example: write $$find^STDREGEX(h,"the 42 cats")  ; 5 for "\d+"
        ; Stub: NFA simulation lands in Pass C.
        quit 0
        ;
findall(h,s,out)        ; Populate out(1..N) with every non-overlapping match text.
        ; doc: out is by-reference. After return, $order(out("")) walks the
        ; doc: matches in left-to-right order. Empty out if no match.
        ; doc: Example: do findall^STDREGEX(h,"a 1 b 22",.out)
        ; Stub: NFA simulation lands in Pass E.
        quit
        ;
groups(h,s,g)   ; Populate g(0..N) with the full match text and each capture group.
        ; doc: g is by-reference. g(0) is the full match; g(k) for k>=1 is
        ; doc: the k-th capture group counted by '(' position. Capture-group
        ; doc: numbering ignores (?:...) non-capturing groups. Sets $ECODE to
        ; doc: U-STDREGEX-NO-MATCH if pattern does not match s.
        ; doc: Example: do groups^STDREGEX(h,"42-foo",.g)
        ; Stub: capture tracking lands in Pass D.
        quit
        ;
replace(h,s,repl)       ; Return s with every match replaced by repl.
        ; doc: \1..\9 in repl are expanded to the corresponding capture group
        ; doc: text. \\ in repl is a literal backslash.
        ; doc: Example: write $$replace^STDREGEX(h,"x42y","[\1]")  ; "x[42]y"
        ; Stub: replacement lands in Pass E.
        quit $get(s)
        ;
split(h,s,out)  ; Populate out(1..N) with the segments of s between matches.
        ; doc: out is by-reference. Adjacent matches produce empty segments;
        ; doc: leading/trailing matches produce a leading/trailing empty
        ; doc: segment. Empty pattern is a parse error.
        ; doc: Example: do split^STDREGEX(h,"a,b,c",.out)
        ; Stub: split lands in Pass E.
        quit
        ;
        ; ---------- internal: parser (Pass A) ----------
        ;
        ; The parser is a recursive-descent walker over a state array `st`
        ; passed by reference. State subscripts:
        ;   st("pat")        — pattern source
        ;   st("len")        — pattern length
        ;   st("pos")        — current 1-indexed position
        ;   st("nextId")     — AST node id allocator
        ;   st("groupCount") — capture-group counter
        ;   st("err")        — "" on success; "BAD-PATTERN" or "UNSUPPORTED" on failure
        ;
parse(pattern,ast,root) ; Parse pattern into ast(...); set root id.
        ; doc: Internal — returns "" on success, "BAD-PATTERN" or
        ; doc: "UNSUPPORTED" on failure. Does not set $ECODE; callers
        ; doc: choose whether to raise or to return a soft signal.
        new st
        set st("pat")=pattern
        set st("len")=$length(pattern)
        set st("pos")=1
        set st("nextId")=0
        set st("groupCount")=0
        set st("err")=""
        set root=$$pAlt(.st,.ast)
        if st("err")'="" quit st("err")
        ; trailing input that wasn't consumed (e.g. unmatched ')') is BAD-PATTERN
        if st("pos")<=st("len") quit "BAD-PATTERN"
        quit ""
        ;
nextId(st,ast,type)     ; Allocate a fresh AST id and stamp its type.
        ; doc: Internal — every node-builder calls this first to reserve
        ; doc: an id, then writes its type-specific subscripts.
        new id
        set id=$increment(st("nextId"))
        set ast(id,"type")=type
        quit id
        ;
pAlt(st,ast)    ; alt -> concat ('|' concat)*
        ; doc: Internal — yields either the single concat node or an
        ; doc: alt node whose branches are the concats.
        new firstId,branches,n,id,i
        set firstId=$$pConcat(.st,.ast)
        if st("err")'="" quit ""
        if (st("pos")>st("len"))!($extract(st("pat"),st("pos"))'="|") quit firstId
        set branches(1)=firstId,n=1
        for  set st("pos")=st("pos")+1,n=n+1,branches(n)=$$pConcat(.st,.ast) quit:(st("err")'="")!(st("pos")>st("len"))!($extract(st("pat"),st("pos"))'="|")
        if st("err")'="" quit ""
        set id=$$nextId(.st,.ast,"alt")
        for i=1:1:n set ast(id,"branch",i)=branches(i)
        quit id
        ;
pConcat(st,ast) ; concat -> atomQuant*
        ; doc: Internal — empty input is legal and yields an empty concat
        ; doc: (epsilon match). One element collapses to that element.
        new items,n,id,i
        set n=0
        for  quit:(st("err")'="")!$$concatStops(.st)  set n=n+1,items(n)=$$pAtomQuant(.st,.ast)
        if st("err")'="" quit ""
        if n=1 quit items(1)
        set id=$$nextId(.st,.ast,"concat")
        for i=1:1:n set ast(id,"child",i)=items(i)
        quit id
        ;
concatStops(st)         ; True if the next byte ends the current concat sequence.
        ; doc: Internal — concat ends at end-of-pattern, '|', or ')'.
        new c
        if st("pos")>st("len") quit 1
        set c=$extract(st("pat"),st("pos"))
        if c="|" quit 1
        if c=")" quit 1
        quit 0
        ;
pAtomQuant(st,ast)      ; atomQuant -> atom (quantifier)?
        ; doc: Internal — wraps the atom in a star/plus/quest/range node
        ; doc: when a quantifier follows. Lazy '?' or possessive '+' after
        ; doc: a quantifier is rejected as UNSUPPORTED.
        new atomId,c,quantId
        set quantId=""
        set atomId=$$pAtom(.st,.ast)
        if st("err")'="" quit ""
        if st("pos")>st("len") quit atomId
        set c=$extract(st("pat"),st("pos"))
        if c="*" set st("pos")=st("pos")+1,quantId=$$nextId(.st,.ast,"star"),ast(quantId,"child")=atomId do checkLazyPoss(.st) quit quantId
        if c="+" set st("pos")=st("pos")+1,quantId=$$nextId(.st,.ast,"plus"),ast(quantId,"child")=atomId do checkLazyPoss(.st) quit quantId
        if c="?" set st("pos")=st("pos")+1,quantId=$$nextId(.st,.ast,"quest"),ast(quantId,"child")=atomId do checkLazyPoss(.st) quit quantId
        if c="{" set quantId=$$pRange(.st,.ast,atomId) if st("err")="" do checkLazyPoss(.st)
        if c="{" quit quantId
        quit atomId
        ;
checkLazyPoss(st)       ; Reject a trailing '?' (lazy) or '+' (possessive) modifier.
        ; doc: Internal — v0.2.0 ships greedy quantifiers only.
        new c
        if st("pos")>st("len") quit
        set c=$extract(st("pat"),st("pos"))
        if (c="?")!(c="+") set st("err")="UNSUPPORTED"
        quit
        ;
pAtom(st,ast)   ; atom -> literal | '.' | '^' | '$' | escape | klass | group
        ; doc: Internal — the unitary regex element a quantifier can attach to.
        ; doc: Stray '*' / '+' / '?' / '{' / ')' / '|' here are BAD-PATTERN.
        new c,id
        if st("pos")>st("len") set st("err")="BAD-PATTERN" quit ""
        set c=$extract(st("pat"),st("pos"))
        if "*+?{)|"[c set st("err")="BAD-PATTERN" quit ""
        if c="^" set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"anchor"),ast(id,"sym")="^" quit id
        if c="$" set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"anchor"),ast(id,"sym")="$" quit id
        if c="." set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"dot") quit id
        if c="\" quit $$pEscape(.st,.ast)
        if c="[" quit $$pClass(.st,.ast)
        if c="(" quit $$pGroup(.st,.ast)
        ; bare literal
        set st("pos")=st("pos")+1
        set id=$$nextId(.st,.ast,"literal")
        set ast(id,"char")=c
        quit id
        ;
pEscape(st,ast) ; '\' followed by one char or short class.
        ; doc: Internal — handles literal escapes, predefined classes,
        ; doc: control chars, back-refs (UNSUPPORTED), and \p / \P
        ; doc: Unicode property heads (UNSUPPORTED).
        new c,id
        set st("pos")=st("pos")+1
        if st("pos")>st("len") set st("err")="BAD-PATTERN" quit ""
        set c=$extract(st("pat"),st("pos"))
        ; pattern back-reference \1..\9 — UNSUPPORTED at v0.2.0
        if "123456789"[c set st("err")="UNSUPPORTED" quit ""
        ; Unicode property class \p{...} or \P{...} — UNSUPPORTED
        if (c="p")!(c="P") if (st("pos")<st("len"))&($extract(st("pat"),st("pos")+1)="{") set st("err")="UNSUPPORTED" quit ""
        ; predefined class
        if "dDwWsS"[c set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"pred"),ast(id,"sym")=c quit id
        ; control chars
        if c="n" set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"literal"),ast(id,"char")=$char(10) quit id
        if c="t" set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"literal"),ast(id,"char")=$char(9) quit id
        if c="r" set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"literal"),ast(id,"char")=$char(13) quit id
        ; recognised literal escapes
        if "\.^$()[]{}|*+?-/"[c set st("pos")=st("pos")+1,id=$$nextId(.st,.ast,"literal"),ast(id,"char")=c quit id
        ; everything else: unknown escape — be strict
        set st("err")="BAD-PATTERN"
        quit ""
        ;
pClass(st,ast)  ; '[' ['^'] item+ ']'
        ; doc: Internal — empty class '[]' is BAD-PATTERN. Items are bare
        ; doc: chars, escape-class items, or 'lo-hi' ranges; reverse range
        ; doc: 'z-a' is BAD-PATTERN. Final '-' is a literal.
        new id,n,lo
        set st("pos")=st("pos")+1   ; consume '['
        if st("pos")>st("len") set st("err")="BAD-PATTERN" quit ""
        set id=$$nextId(.st,.ast,"klass")
        set ast(id,"negated")=0
        if $extract(st("pat"),st("pos"))="^" set ast(id,"negated")=1,st("pos")=st("pos")+1
        set n=0
        for  quit:(st("err")'="")!(st("pos")>st("len"))!($extract(st("pat"),st("pos"))="]")  do classItem(.st,.ast,id,.n)
        if st("err")'="" quit ""
        if st("pos")>st("len") set st("err")="BAD-PATTERN" quit ""    ; ran off the end without ']'
        if n=0 set st("err")="BAD-PATTERN" quit ""                    ; '[]' or '[^]' empty class
        set st("pos")=st("pos")+1   ; consume ']'
        quit id
        ;
classItem(st,ast,id,n)  ; Read one class item — bare char, escape, range, or pred.
        ; doc: Internal — handles 'a' / '\d' / 'a-z' / '\n' / '-' (literal at end).
        new lo,c,c2
        set c=$extract(st("pat"),st("pos"))
        if c="\" do  quit
        . do classEscape(.st,.ast,id,.n)
        ; literal char (or '-' before ']')
        set lo=c
        set st("pos")=st("pos")+1
        ; check for range continuation: '-' followed by non-']'
        if (st("pos")<st("len"))&($extract(st("pat"),st("pos"))="-")&($extract(st("pat"),st("pos")+1)'="]") do  quit
        . set st("pos")=st("pos")+1
        . do classRangeHi(.st,.ast,id,.n,lo)
        ; bare char item
        set n=n+1
        set ast(id,"item",n,"kind")="char"
        set ast(id,"item",n,"char")=lo
        quit
        ;
classEscape(st,ast,id,n)        ; Handle a '\<x>' inside a character class.
        ; doc: Internal — predefined classes (\d, \w, …) become "pred" items;
        ; doc: literal escapes become "char" items (and may begin a range).
        new c,lo
        set lo=""
        set st("pos")=st("pos")+1   ; consume '\'
        if st("pos")>st("len") set st("err")="BAD-PATTERN" quit
        set c=$extract(st("pat"),st("pos"))
        ; pattern back-reference inside a class is also UNSUPPORTED
        if "123456789"[c set st("err")="UNSUPPORTED" quit
        ; Unicode property
        if (c="p")!(c="P") if (st("pos")<st("len"))&($extract(st("pat"),st("pos")+1)="{") set st("err")="UNSUPPORTED" quit
        ; predefined classes don't start a range — append and return
        if "dDwWsS"[c set st("pos")=st("pos")+1,n=n+1,ast(id,"item",n,"kind")="pred",ast(id,"item",n,"sym")=c quit
        ; literal-via-escape: control chars + recognised punctuation
        set lo=$select(c="n":$char(10),c="t":$char(9),c="r":$char(13),"\.^$()[]{}|*+?-/"[c:c,1:"")
        if lo="" set st("err")="BAD-PATTERN" quit
        set st("pos")=st("pos")+1
        ; range continuation?
        if (st("pos")<st("len"))&($extract(st("pat"),st("pos"))="-")&($extract(st("pat"),st("pos")+1)'="]") do  quit
        . set st("pos")=st("pos")+1
        . do classRangeHi(.st,.ast,id,.n,lo)
        set n=n+1
        set ast(id,"item",n,"kind")="char"
        set ast(id,"item",n,"char")=lo
        quit
        ;
classRangeHi(st,ast,id,n,lo)    ; Read the high end of a class range and append it.
        ; doc: Internal — accepts a literal char or an escape-via-literal
        ; doc: form. Reverse range (lo > hi by ASCII) is BAD-PATTERN.
        new c,hi
        if st("pos")>st("len") set st("err")="BAD-PATTERN" quit
        set c=$extract(st("pat"),st("pos"))
        if c="\" do  quit:st("err")'=""
        . set st("pos")=st("pos")+1
        . if st("pos")>st("len") set st("err")="BAD-PATTERN" quit
        . set c=$extract(st("pat"),st("pos"))
        . if c="n" set hi=$char(10)
        . else  if c="t" set hi=$char(9)
        . else  if c="r" set hi=$char(13)
        . else  if "\.^$()[]{}|*+?-/"[c set hi=c
        . else  set st("err")="BAD-PATTERN" quit
        else  set hi=c
        if st("err")'="" quit
        set st("pos")=st("pos")+1
        if $ascii(hi)<$ascii(lo) set st("err")="BAD-PATTERN" quit
        set n=n+1
        set ast(id,"item",n,"kind")="range"
        set ast(id,"item",n,"lo")=lo
        set ast(id,"item",n,"hi")=hi
        quit
        ;
pGroup(st,ast)  ; '(' [head] alt ')'
        ; doc: Internal — '(?:' non-capturing; '(?=' / '(?!' / '(?<=' /
        ; doc: '(?<!' lookaround (UNSUPPORTED); '(?<' or '(?P<' named
        ; doc: capture (UNSUPPORTED); '(?[imsxn]' inline modifier
        ; doc: (UNSUPPORTED). Plain '(' is a capturing group.
        new capturing,gnum,id,inner,c,c2
        set gnum=""
        set st("pos")=st("pos")+1   ; consume '('
        if st("pos")>st("len") set st("err")="BAD-PATTERN" quit ""
        set capturing=1
        if $extract(st("pat"),st("pos"))="?" do  quit:st("err")'="" ""
        . set st("pos")=st("pos")+1
        . if st("pos")>st("len") set st("err")="BAD-PATTERN" quit
        . set c=$extract(st("pat"),st("pos"))
        . if c=":" set capturing=0,st("pos")=st("pos")+1 quit
        . if (c="=")!(c="!") set st("err")="UNSUPPORTED" quit
        . if c="<" set st("err")="UNSUPPORTED" quit       ; (?<=, (?<!, (?<name>
        . if c="P" set st("err")="UNSUPPORTED" quit       ; (?P<name>, (?P=name)
        . if "imsxn"[c set st("err")="UNSUPPORTED" quit
        . set st("err")="BAD-PATTERN"
        if capturing set st("groupCount")=st("groupCount")+1,gnum=st("groupCount")
        set inner=$$pAlt(.st,.ast)
        if st("err")'="" quit ""
        if (st("pos")>st("len"))!($extract(st("pat"),st("pos"))'=")") set st("err")="BAD-PATTERN" quit ""
        set st("pos")=st("pos")+1   ; consume ')'
        set id=$$nextId(.st,.ast,"group")
        set ast(id,"capturing")=capturing
        if capturing set ast(id,"groupNum")=gnum
        set ast(id,"child")=inner
        quit id
        ;
pRange(st,ast,atomId)   ; '{' n [',' [m]] '}' — bounded quantifier.
        ; doc: Internal — bare '{' that isn't a valid range (no leading
        ; doc: digit, missing '}', m<n) is BAD-PATTERN; literal '{' must
        ; doc: be escaped as '\{'.
        new c,n,m,buf,id
        set st("pos")=st("pos")+1   ; consume '{'
        set buf=""
        for  quit:(st("pos")>st("len"))!('$$isDigit($extract(st("pat"),st("pos"))))  set buf=buf_$extract(st("pat"),st("pos")),st("pos")=st("pos")+1
        if buf="" set st("err")="BAD-PATTERN" quit ""
        set n=+buf
        set m=n
        if (st("pos")<=st("len"))&($extract(st("pat"),st("pos"))=",") do  quit:st("err")'="" ""
        . set st("pos")=st("pos")+1
        . set buf=""
        . for  quit:(st("pos")>st("len"))!('$$isDigit($extract(st("pat"),st("pos"))))  set buf=buf_$extract(st("pat"),st("pos")),st("pos")=st("pos")+1
        . if buf="" set m="" quit
        . set m=+buf
        if st("err")'="" quit ""
        if (st("pos")>st("len"))!($extract(st("pat"),st("pos"))'="}") set st("err")="BAD-PATTERN" quit ""
        set st("pos")=st("pos")+1   ; consume '}'
        if (m'="")&(m<n) set st("err")="BAD-PATTERN" quit ""
        set id=$$nextId(.st,.ast,"range")
        set ast(id,"min")=n
        set ast(id,"max")=m
        set ast(id,"child")=atomId
        quit id
        ;
isDigit(c)      ; True iff c is one ASCII decimal digit.
        ; doc: Internal — used by pRange for {n,m} parsing.
        quit "0123456789"[c
        ;
        ; ---------- internal: NFA construction (Pass B) ----------
        ;
        ; Standard Thompson construction: every AST node yields a fragment
        ; with an entry state and an exit state. Each NFA state owns 0..N
        ; out-edges in priority order; lower edge index = higher priority,
        ; so greedy quantifiers explore the loop edge before the skip edge.
        ; Edge kinds:
        ;   eps      — always passable, zero-width
        ;   anchor   — zero-width; passable only when input position
        ;              satisfies "^" (start) or "$" (end)
        ;   capStart — zero-width side-effect: open capture group N
        ;   capEnd   — zero-width side-effect: close capture group N
        ;   literal  — consumes one input char if it equals "char"
        ;   dot      — consumes one input char if not LF
        ;   pred     — consumes one input char satisfying \d \D \w \W \s \S
        ;   klass    — consumes one input char satisfying klass(astId)'s
        ;              "item" entries; we keep a reference to the AST id
        ;              rather than copying the items so the simulator can
        ;              read them straight out of the global at match time
        ;
        ; State storage under handle h:
        ;   ^STDLIB($job,"stdregex",h,"nfa","entry") — entry state id
        ;   ^STDLIB($job,"stdregex",h,"nfa","exit")  — accept state id
        ;   ^STDLIB($job,"stdregex",h,"nfa","next")  — last allocated state
        ;   ^STDLIB($job,"stdregex",h,"nfa","groups")— max capture group num
        ;   ^STDLIB($job,"stdregex",h,"nfa","s",S,"n")           — edge count
        ;   ^STDLIB($job,"stdregex",h,"nfa","s",S,"e",E,"kind")  — edge kind
        ;   ^STDLIB($job,"stdregex",h,"nfa","s",S,"e",E,"target")— next state
        ;   ^STDLIB($job,"stdregex",h,"nfa","s",S,"e",E,"char")  — for literal
        ;   ^STDLIB($job,"stdregex",h,"nfa","s",S,"e",E,"sym")   — for anchor/pred
        ;   ^STDLIB($job,"stdregex",h,"nfa","s",S,"e",E,"klassRef")— ast id
        ;   ^STDLIB($job,"stdregex",h,"nfa","s",S,"e",E,"group") — for capStart/End
        ;
buildNfa(h)     ; Build the NFA for handle h from its committed AST root.
        ; doc: Internal — called by compile() once parse() has committed
        ; doc: the AST. Allocates state ids densely from 1; sets entry/exit.
        new root,frag
        set ^STDLIB($job,"stdregex",h,"nfa","next")=0
        set ^STDLIB($job,"stdregex",h,"nfa","groups")=0
        set root=^STDLIB($job,"stdregex",h,"root")
        do bld(h,root,.frag)
        set ^STDLIB($job,"stdregex",h,"nfa","entry")=frag("entry")
        set ^STDLIB($job,"stdregex",h,"nfa","exit")=frag("exit")
        quit
        ;
newSt(h)        ; Allocate a fresh NFA state id under handle h.
        ; doc: Internal — every fragment-builder calls this for endpoints.
        quit $increment(^STDLIB($job,"stdregex",h,"nfa","next"))
        ;
addEps(h,s,target)      ; Append an ε-edge to state s.
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="eps"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
addAnchor(h,s,sym,target)       ; Append an anchor edge ("^" or "$").
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="anchor"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"sym")=sym
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
addCapStart(h,s,gnum,target)    ; Append a capture-group-open edge.
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="capStart"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"group")=gnum
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
addCapEnd(h,s,gnum,target)      ; Append a capture-group-close edge.
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="capEnd"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"group")=gnum
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
addLit(h,s,c,target)    ; Append a literal-char consume edge.
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="literal"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"char")=c
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
addDot(h,s,target)      ; Append a dot consume edge (any char except LF).
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="dot"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
addPred(h,s,sym,target) ; Append a predicate-class consume edge.
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="pred"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"sym")=sym
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
addKlass(h,s,ref,target)        ; Append a character-class consume edge.
        new idx
        set idx=$increment(^STDLIB($job,"stdregex",h,"nfa","s",s,"n"))
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"kind")="klass"
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"klassRef")=ref
        set ^STDLIB($job,"stdregex",h,"nfa","s",s,"e",idx,"target")=target
        quit
        ;
bld(h,id,frag)  ; Compile AST node id; populate frag("entry","exit").
        ; doc: Internal — central dispatcher. Each AST node type has a
        ; doc: matching bld* helper that allocates fresh state ids and
        ; doc: writes its edges into the NFA global.
        new t
        set t=^STDLIB($job,"stdregex",h,"ast",id,"type")
        if t="literal" do bldLit(h,id,.frag) quit
        if t="dot" do bldDotN(h,.frag) quit
        if t="anchor" do bldAnch(h,id,.frag) quit
        if t="pred" do bldPredN(h,id,.frag) quit
        if t="klass" do bldKlassN(h,id,.frag) quit
        if t="concat" do bldConcat(h,id,.frag) quit
        if t="alt" do bldAlt(h,id,.frag) quit
        if t="star" do bldStar(h,id,.frag) quit
        if t="plus" do bldPlus(h,id,.frag) quit
        if t="quest" do bldQuest(h,id,.frag) quit
        if t="range" do bldRange(h,id,.frag) quit
        if t="group" do bldGroup(h,id,.frag) quit
        quit
        ;
bldLit(h,id,frag)       ; literal — single consume edge.
        new e,x
        set e=$$newSt(h),x=$$newSt(h)
        do addLit(h,e,^STDLIB($job,"stdregex",h,"ast",id,"char"),x)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldDotN(h,frag) ; dot — single consume edge.
        new e,x
        set e=$$newSt(h),x=$$newSt(h)
        do addDot(h,e,x)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldAnch(h,id,frag)      ; anchor "^"/"$" — zero-width.
        new e,x
        set e=$$newSt(h),x=$$newSt(h)
        do addAnchor(h,e,^STDLIB($job,"stdregex",h,"ast",id,"sym"),x)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldPredN(h,id,frag)     ; predefined class \d \D \w \W \s \S.
        new e,x
        set e=$$newSt(h),x=$$newSt(h)
        do addPred(h,e,^STDLIB($job,"stdregex",h,"ast",id,"sym"),x)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldKlassN(h,id,frag)    ; user character class — refers back to AST items.
        new e,x
        set e=$$newSt(h),x=$$newSt(h)
        do addKlass(h,e,id,x)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldConcat(h,id,frag)    ; A B C ... — chain fragments through ε-edges.
        ; doc: Internal — empty concat (no children) yields a one-state
        ; doc: ε-fragment so callers can treat it uniformly.
        new n,i,prev,first,sub
        set n=0
        for  set n=n+1 quit:'$data(^STDLIB($job,"stdregex",h,"ast",id,"child",n))
        set n=n-1
        if n=0 do  quit
        . new e
        . set e=$$newSt(h)
        . set frag("entry")=e,frag("exit")=e
        do bld(h,^STDLIB($job,"stdregex",h,"ast",id,"child",1),.first)
        set frag("entry")=first("entry"),prev=first("exit")
        for i=2:1:n do
        . kill sub
        . do bld(h,^STDLIB($job,"stdregex",h,"ast",id,"child",i),.sub)
        . do addEps(h,prev,sub("entry"))
        . set prev=sub("exit")
        set frag("exit")=prev
        quit
        ;
bldAlt(h,id,frag)       ; A | B | C — split entry, merge exits.
        new n,i,e,x,sub
        set e=$$newSt(h),x=$$newSt(h)
        set n=0
        for  set n=n+1 quit:'$data(^STDLIB($job,"stdregex",h,"ast",id,"branch",n))
        set n=n-1
        for i=1:1:n do
        . kill sub
        . do bld(h,^STDLIB($job,"stdregex",h,"ast",id,"branch",i),.sub)
        . do addEps(h,e,sub("entry"))
        . do addEps(h,sub("exit"),x)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldStar(h,id,frag)      ; A* — greedy: try child first, then skip.
        new e,x,sub
        set e=$$newSt(h),x=$$newSt(h)
        do bld(h,^STDLIB($job,"stdregex",h,"ast",id,"child"),.sub)
        ; Edge order matters — priority 1 is the loop, priority 2 is the
        ; skip. The simulator walks edges in order, so "greedy" falls out
        ; of "explore the loop before the exit".
        do addEps(h,e,sub("entry"))
        do addEps(h,e,x)
        do addEps(h,sub("exit"),e)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldPlus(h,id,frag)      ; A+ — child runs once, then optional repeat.
        new e,x,sub
        do bld(h,^STDLIB($job,"stdregex",h,"ast",id,"child"),.sub)
        set x=$$newSt(h)
        do addEps(h,sub("exit"),sub("entry"))
        do addEps(h,sub("exit"),x)
        set frag("entry")=sub("entry"),frag("exit")=x
        quit
        ;
bldQuest(h,id,frag)     ; A? — split entry, no loop.
        new e,x,sub
        set e=$$newSt(h),x=$$newSt(h)
        do bld(h,^STDLIB($job,"stdregex",h,"ast",id,"child"),.sub)
        do addEps(h,e,sub("entry"))
        do addEps(h,e,x)
        do addEps(h,sub("exit"),x)
        set frag("entry")=e,frag("exit")=x
        quit
        ;
bldRange(h,id,frag)     ; {n}, {n,}, {n,m} — unrolled into n required +
        ; doc: optional copies. Test patterns use small bounds (n<=4) so
        ; doc: unrolling is fine; a future pass could special-case large m.
        new childAst,n,m,i,sub,prev,e,x
        set childAst=^STDLIB($job,"stdregex",h,"ast",id,"child")
        set n=^STDLIB($job,"stdregex",h,"ast",id,"min")
        set m=^STDLIB($job,"stdregex",h,"ast",id,"max")
        ; Build the n required copies, chained.
        if n=0 do
        . set e=$$newSt(h)
        . set frag("entry")=e,frag("exit")=e
        else  do
        . kill sub
        . do bld(h,childAst,.sub)
        . set frag("entry")=sub("entry"),prev=sub("exit")
        . for i=2:1:n do
        . . new s2
        . . do bld(h,childAst,.s2)
        . . do addEps(h,prev,s2("entry"))
        . . set prev=s2("exit")
        . set frag("exit")=prev
        ; m="" means {n,} — append a star fragment.
        if m="" do  quit
        . new se,sx,s3
        . set se=$$newSt(h),sx=$$newSt(h)
        . do bld(h,childAst,.s3)
        . do addEps(h,se,s3("entry"))
        . do addEps(h,se,sx)
        . do addEps(h,s3("exit"),se)
        . do addEps(h,frag("exit"),se)
        . set frag("exit")=sx
        ; m>n means {n,m} — append (m-n) optional copies (each a quest).
        if m>n do
        . for i=1:1:(m-n) do
        . . new qe,qx,q
        . . set qe=$$newSt(h),qx=$$newSt(h)
        . . do bld(h,childAst,.q)
        . . do addEps(h,qe,q("entry"))
        . . do addEps(h,qe,qx)
        . . do addEps(h,q("exit"),qx)
        . . do addEps(h,frag("exit"),qe)
        . . set frag("exit")=qx
        quit
        ;
bldGroup(h,id,frag)     ; (A) capturing or (?:A) non-capturing.
        new childAst,capturing,gnum,e,x,sub
        set childAst=^STDLIB($job,"stdregex",h,"ast",id,"child")
        set capturing=^STDLIB($job,"stdregex",h,"ast",id,"capturing")
        do bld(h,childAst,.sub)
        if 'capturing set frag("entry")=sub("entry"),frag("exit")=sub("exit") quit
        set gnum=^STDLIB($job,"stdregex",h,"ast",id,"groupNum")
        set e=$$newSt(h),x=$$newSt(h)
        do addCapStart(h,e,gnum,sub("entry"))
        do addCapEnd(h,sub("exit"),gnum,x)
        set frag("entry")=e,frag("exit")=x
        if gnum>$get(^STDLIB($job,"stdregex",h,"nfa","groups")) set ^STDLIB($job,"stdregex",h,"nfa","groups")=gnum
        quit
        ;
