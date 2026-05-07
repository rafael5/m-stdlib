STDSEMVER       ; m-stdlib — SemVer 2.0.0 parse / compare / range matching.
        ;
        ; Public extrinsics:
        ;   $$valid^STDSEMVER(s)         — 1 iff s is a valid SemVer string
        ;   $$parse^STDSEMVER(s,.v)      — populate v(1..5); return 1/0
        ;   $$major^STDSEMVER(s)         — major component, or "" if invalid
        ;   $$minor^STDSEMVER(s)         — minor component, or "" if invalid
        ;   $$patch^STDSEMVER(s)         — patch component, or "" if invalid
        ;   $$prerelease^STDSEMVER(s)    — prerelease tail, or "" if absent
        ;   $$build^STDSEMVER(s)         — build tail, or "" if absent
        ;   $$compare^STDSEMVER(a,b)     — -1/0/1 per SemVer §11 precedence
        ;   $$matches^STDSEMVER(v,range) — 1 iff v satisfies range
        ;
        ; Grammar (SemVer 2.0.0 §2):
        ;   <major>.<minor>.<patch>('-'<prerelease>)?('+'<build>)?
        ;   each numeric part: non-negative integer, no leading zeros (except 0)
        ;   <prerelease>: dot-separated IDs; each is [0-9A-Za-z-]+; numeric IDs
        ;     have no leading zeros; alphanumeric IDs may include hyphens.
        ;   <build>: dot-separated IDs; same charset; numeric leading zeros OK.
        ;
        ; Range syntax (npm subset):
        ;   exact:       "1.2.3"
        ;   comparator:  ">"|"<"|">="|"<="|"=" prefixing a SemVer
        ;   caret:       "^1.2.3"  ≡  ">=1.2.3 <2.0.0"
        ;   tilde:       "~1.2.3"  ≡  ">=1.2.3 <1.3.0"
        ;   AND:         space-separated comparators must all hold
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
valid(s)        ; Return 1 iff s is a valid SemVer 2.0.0 string; else 0.
        ; doc: Empty input is invalid. Leading 'v' is NOT accepted (callers
        ; doc: must strip it). A '+' or '-' delimiter present but followed by
        ; doc: an empty tail is invalid.
        ; doc: Example: write $$valid^STDSEMVER("1.0.0-rc.1+exp")  ; 1
        new core,pre,build,plusPos,dashPos,hasPre,hasBuild
        if s="" quit 0
        ; Split off build at first '+'.
        set plusPos=$find(s,"+"),hasBuild=0
        if plusPos>0 do
        . set core=$extract(s,1,plusPos-2)
        . set build=$extract(s,plusPos,$length(s))
        . set hasBuild=1
        else  set core=s,build=""
        if core="" quit 0
        if hasBuild,build="" quit 0
        ; Split off prerelease at first '-' inside core.
        set dashPos=$find(core,"-"),hasPre=0
        if dashPos>0 do
        . set pre=$extract(core,dashPos,$length(core))
        . set core=$extract(core,1,dashPos-2)
        . set hasPre=1
        else  set pre=""
        if core="" quit 0
        if hasPre,pre="" quit 0
        if '$$validTriple(core) quit 0
        if pre'="",'$$validPrerelease(pre) quit 0
        if build'="",'$$validBuild(build) quit 0
        quit 1
        ;
parse(s,v)      ; Populate v(1..5)=major,minor,patch,prerelease,build; return 1/0.
        ; doc: Returns 0 (and leaves v unset) if s is invalid. Numeric parts
        ; doc: are stored as integers (no leading zeros surface in v).
        ; doc: Example: do  set rc=$$parse^STDSEMVER("1.2.3-rc.1+meta",.v)
        kill v
        if '$$valid(s) quit 0
        new core,pre,build,plusPos,dashPos
        set plusPos=$find(s,"+")
        if plusPos>0 set core=$extract(s,1,plusPos-2),build=$extract(s,plusPos,$length(s))
        else  set core=s,build=""
        set dashPos=$find(core,"-")
        if dashPos>0 set pre=$extract(core,dashPos,$length(core)),core=$extract(core,1,dashPos-2)
        else  set pre=""
        set v(1)=+$piece(core,".",1)
        set v(2)=+$piece(core,".",2)
        set v(3)=+$piece(core,".",3)
        set v(4)=pre
        set v(5)=build
        quit 1
        ;
major(s)        ; Return the major component; "" if s is invalid.
        ; doc: Example: write $$major^STDSEMVER("1.2.3")  ; 1
        new v
        set v(1)="",v(2)="",v(3)="",v(4)="",v(5)=""
        if '$$parse(s,.v) quit ""
        quit v(1)
        ;
minor(s)        ; Return the minor component; "" if s is invalid.
        new v
        set v(1)="",v(2)="",v(3)="",v(4)="",v(5)=""
        if '$$parse(s,.v) quit ""
        quit v(2)
        ;
patch(s)        ; Return the patch component; "" if s is invalid.
        new v
        set v(1)="",v(2)="",v(3)="",v(4)="",v(5)=""
        if '$$parse(s,.v) quit ""
        quit v(3)
        ;
prerelease(s)   ; Return the prerelease tail (no leading '-'); "" if absent or invalid.
        ; doc: Example: write $$prerelease^STDSEMVER("1.0.0-rc.1+meta")  ; "rc.1"
        new v
        set v(1)="",v(2)="",v(3)="",v(4)="",v(5)=""
        if '$$parse(s,.v) quit ""
        quit v(4)
        ;
build(s)        ; Return the build tail (no leading '+'); "" if absent or invalid.
        ; doc: Example: write $$build^STDSEMVER("1.0.0-rc.1+meta")  ; "meta"
        new v
        set v(1)="",v(2)="",v(3)="",v(4)="",v(5)=""
        if '$$parse(s,.v) quit ""
        quit v(5)
        ;
compare(a,b)    ; Return -1/0/1 per SemVer §11 precedence (build ignored).
        ; doc: Returns "" if either operand is invalid.
        ; doc: Example: write $$compare^STDSEMVER("1.0.0-rc.1","1.0.0")  ; -1
        new va,vb,c
        set va(1)="",va(2)="",va(3)="",va(4)="",va(5)=""
        set vb(1)="",vb(2)="",vb(3)="",vb(4)="",vb(5)=""
        if '$$parse(a,.va) quit ""
        if '$$parse(b,.vb) quit ""
        ; Compare major, minor, patch numerically.
        if va(1)<vb(1) quit -1
        if va(1)>vb(1) quit 1
        if va(2)<vb(2) quit -1
        if va(2)>vb(2) quit 1
        if va(3)<vb(3) quit -1
        if va(3)>vb(3) quit 1
        ; Triples equal — apply prerelease precedence (§11.3 / §11.4).
        if va(4)="",vb(4)="" quit 0
        if va(4)="" quit 1   ; release > prerelease
        if vb(4)="" quit -1  ; prerelease < release
        set c=$$comparePrerelease(va(4),vb(4))
        quit c
        ;
matches(v,range)        ; Return 1 iff v satisfies the range expression.
        ; doc: range may be a bare SemVer (exact match), a single comparator
        ; doc: ('>'/'<'/'>='/'<='/'='-prefixed), a caret/tilde expansion, or
        ; doc: a space-separated AND of comparators.
        ; doc: Example: write $$matches^STDSEMVER("1.5.0","^1.2.3")  ; 1
        if '$$valid(v) quit 0
        if range="" quit 0
        ; Caret expands to >=X.Y.Z <(X+1).0.0
        if $extract(range,1)="^" quit $$matchesCaret(v,$extract(range,2,$length(range)))
        ; Tilde expands to >=X.Y.Z <X.(Y+1).0
        if $extract(range,1)="~" quit $$matchesTilde(v,$extract(range,2,$length(range)))
        ; AND-combination: split on space, all must hold.
        new n,i,piece,rc
        set n=$length(range," "),rc=1
        for i=1:1:n quit:'rc  do
        . set piece=$piece(range," ",i)
        . if piece="" quit
        . if '$$matchesOne(v,piece) set rc=0
        quit rc
        ;
        ; ---------- internal: SemVer validation ----------
        ;
validTriple(s)  ; True iff s = N.N.N with each N a non-leading-zero non-negative integer.
        ; doc: Internal — driven by valid().
        new n
        set n=$length(s,".")
        if n'=3 quit 0
        if '$$validNumericId($piece(s,".",1)) quit 0
        if '$$validNumericId($piece(s,".",2)) quit 0
        if '$$validNumericId($piece(s,".",3)) quit 0
        quit 1
        ;
validPrerelease(s)      ; True iff s is a valid dot-separated prerelease ID list.
        ; doc: Internal — each ID non-empty; numeric IDs no leading zeros;
        ; doc: alphanumeric IDs match [0-9A-Za-z-]+.
        new n,i,id,ok
        if s="" quit 0
        set n=$length(s,"."),ok=1
        for i=1:1:n quit:'ok  do
        . set id=$piece(s,".",i)
        . if id="" set ok=0 quit
        . if '$$validPreId(id) set ok=0
        quit ok
        ;
validBuild(s)   ; True iff s is a valid dot-separated build ID list.
        ; doc: Internal — same charset as prerelease; numeric leading zeros OK.
        new n,i,id,ok
        if s="" quit 0
        set n=$length(s,".")
        set ok=1
        for i=1:1:n quit:'ok  do
        . set id=$piece(s,".",i)
        . if id="" set ok=0 quit
        . if '$$validBuildId(id) set ok=0
        quit ok
        ;
validNumericId(s)       ; True iff s is "0" or a digit string with no leading zero.
        ; doc: Internal — covers triple components and numeric prerelease IDs.
        if s="" quit 0
        if '$$isAllDigits(s) quit 0
        if $length(s)>1,$extract(s,1)="0" quit 0
        quit 1
        ;
validPreId(s)   ; True iff s is a valid prerelease identifier.
        ; doc: Internal — numeric IDs use validNumericId; otherwise must be
        ; doc: [0-9A-Za-z-]+ with at least one non-digit character.
        if s="" quit 0
        if $$isAllDigits(s) quit $$validNumericId(s)
        quit $$isAlphaNumDash(s)
        ;
validBuildId(s) ; True iff s is a valid build identifier (same charset; leading zeros OK).
        ; doc: Internal.
        if s="" quit 0
        quit $$isAlphaNumDash(s)
        ;
isAllDigits(s)  ; True iff s is non-empty and every char is 0-9.
        if s="" quit 0
        quit $select($translate(s,"0123456789")="":1,1:0)
        ;
isAlphaNumDash(s)       ; True iff s is non-empty and every char is [0-9A-Za-z-].
        new alpha
        if s="" quit 0
        set alpha="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-"
        quit $select($translate(s,alpha)="":1,1:0)
        ;
        ; ---------- internal: prerelease comparison (§11.4) ----------
        ;
comparePrerelease(a,b)  ; Compare two prerelease tails per SemVer §11.4.
        ; doc: Internal — driven by compare(). a,b non-empty by precondition.
        new na,nb,minN,i,ia,ib,c
        set na=$length(a,"."),nb=$length(b,".")
        set minN=$select(na<nb:na,1:nb)
        set c=0
        for i=1:1:minN quit:c'=0  do
        . set ia=$piece(a,".",i)
        . set ib=$piece(b,".",i)
        . set c=$$comparePreId(ia,ib)
        if c'=0 quit c
        ; Shared prefix; longer wins (§11.4.4).
        if na<nb quit -1
        if na>nb quit 1
        quit 0
        ;
comparePreId(a,b)       ; Compare two prerelease identifiers per §11.4.{1,2,3}.
        ; doc: Internal — numeric < alphanumeric; numeric IDs compare
        ; doc: numerically; alphanumeric IDs compare lexically.
        new aNum,bNum
        set aNum=$$isAllDigits(a),bNum=$$isAllDigits(b)
        if aNum,bNum,(+a<+b) quit -1
        if aNum,bNum,(+a>+b) quit 1
        if aNum,bNum quit 0
        if aNum quit -1     ; §11.4.3 — numeric < alphanumeric
        if bNum quit 1
        ; Both alphanumeric — string-collation compare via "]".
        if a]b quit 1
        if b]a quit -1
        quit 0
        ;
        ; ---------- internal: range matching ----------
        ;
matchesOne(v,piece)     ; Apply one comparator piece to v; return 0/1.
        ; doc: Internal — piece may be a bare SemVer (exact) or comparator-prefixed.
        new prefix,operand,c,result
        if piece="" quit 1
        ; Detect comparator prefix.
        if $extract(piece,1,2)=">=" set prefix=">=",operand=$extract(piece,3,$length(piece))
        else  if $extract(piece,1,2)="<=" set prefix="<=",operand=$extract(piece,3,$length(piece))
        else  if $extract(piece,1)=">" set prefix=">",operand=$extract(piece,2,$length(piece))
        else  if $extract(piece,1)="<" set prefix="<",operand=$extract(piece,2,$length(piece))
        else  if $extract(piece,1)="=" set prefix="=",operand=$extract(piece,2,$length(piece))
        else  set prefix="=",operand=piece
        if '$$valid(operand) quit 0
        set c=$$compare(v,operand)
        if c="" quit 0
        if prefix="=" quit $select(c=0:1,1:0)
        if prefix=">" quit $select(c>0:1,1:0)
        if prefix="<" quit $select(c<0:1,1:0)
        if prefix=">=" quit $select(c'<0:1,1:0)
        if prefix="<=" quit $select(c'>0:1,1:0)
        quit 0
        ;
matchesCaret(v,base)    ; Apply ^X.Y.Z := >=X.Y.Z <(X+1).0.0 to v.
        ; doc: Internal. SemVer 0.x.y is treated specially in npm; v1 keeps it
        ; doc: simple — ^0.2.3 expands to >=0.2.3 <1.0.0.
        new vb
        set vb(1)="",vb(2)="",vb(3)="",vb(4)="",vb(5)=""
        if '$$parse(base,.vb) quit 0
        if '$$matchesOne(v,">="_base) quit 0
        if '$$matchesOne(v,"<"_(vb(1)+1)_".0.0") quit 0
        quit 1
        ;
matchesTilde(v,base)    ; Apply ~X.Y.Z := >=X.Y.Z <X.(Y+1).0 to v.
        new vb
        set vb(1)="",vb(2)="",vb(3)="",vb(4)="",vb(5)=""
        if '$$parse(base,.vb) quit 0
        if '$$matchesOne(v,">="_base) quit 0
        if '$$matchesOne(v,"<"_vb(1)_"."_(vb(2)+1)_".0") quit 0
        quit 1
