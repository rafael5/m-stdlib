STDMATH ; m-stdlib — Numeric helpers (clamp / min / max / sum / count / mean over arrays).
        ;
        ; Public extrinsics:
        ;   $$clamp^STDMATH(x,lo,hi)     — clamp scalar x into [lo, hi]
        ;   $$min^STDMATH(.arr)          — smallest value in arr (1st-level $ORDER walk)
        ;   $$max^STDMATH(.arr)          — largest value in arr
        ;   $$sum^STDMATH(.arr)          — sum of arr's values (unary-+ coercion)
        ;   $$count^STDMATH(.arr)        — number of $ORDER-visible values at depth 1
        ;   $$mean^STDMATH(.arr)         — sum / count; "" on empty (no /0)
        ;
        ; All array-walking entry points operate on the FIRST subscript level
        ; only (the canonical "1-D vector" shape). Subscripts are walked via
        ; $ORDER so any subscript shape works (1-indexed, string-keyed, sparse
        ; integer keys, etc.). Multi-dim arrays read only their first level
        ; — descend yourself if you want a deeper walk.
        ;
        ; Empty-array convention:
        ;   sum, count    → 0   (additive identity)
        ;   min, max, mean → "" (no value to report; mean avoids /0)
        ;
        ; Non-numeric values are coerced via M's standard unary-`+` rule:
        ;   +"abc"=0, +"3.14"=3.14, +""=0, +"42-extra"=42. This matches
        ;   how every other M arithmetic primitive treats string operands.
        ;
        ; Pure-M throughout — no $Z* extensions, no STDREGEX dep. Runs
        ; unchanged on YDB and IRIS.
        ;
        quit
        ;
        ; ---------- public API: scalar ----------
        ;
clamp(x,lo,hi)  ; Clamp x into [lo, hi]. Returns lo if x<lo, hi if x>hi, else x.
        ; doc: Caller is responsible for lo ≤ hi; the function does not validate.
        ; doc: Example: write $$clamp^STDMATH(99,0,10)  ; 10
        if x<lo quit lo
        if x>hi quit hi
        quit x
        ;
        ; ---------- public API: array reductions ----------
        ;
min(arr)        ; Smallest value in arr (1st-level $ORDER walk). "" if empty.
        ; doc: Example: new a  set a(1)=3,a(2)=1,a(3)=4  write $$min^STDMATH(.a)  ; 1
        new k,result,first,v
        set k="",first=1,result=""
        for  set k=$order(arr(k)) quit:k=""  do
        . set v=+arr(k)
        . if first set result=v,first=0 quit
        . if v<result set result=v
        quit result
        ;
max(arr)        ; Largest value in arr. "" if empty.
        ; doc: Example: new a  set a(1)=3,a(2)=9,a(3)=4  write $$max^STDMATH(.a)  ; 9
        new k,result,first,v
        set k="",first=1,result=""
        for  set k=$order(arr(k)) quit:k=""  do
        . set v=+arr(k)
        . if first set result=v,first=0 quit
        . if v>result set result=v
        quit result
        ;
sum(arr)        ; Sum of arr's values (unary-+ coercion). 0 if empty.
        ; doc: Example: new a  set a(1)=10,a(2)=-3,a(3)=5  write $$sum^STDMATH(.a)  ; 12
        new k,total
        set total=0,k=""
        for  set k=$order(arr(k)) quit:k=""  set total=total+arr(k)
        quit total
        ;
count(arr)      ; Number of $ORDER-visible values at depth 1. 0 if empty.
        ; doc: Example: new a  set a(1)=10,a("k")=20  write $$count^STDMATH(.a)  ; 2
        new k,n
        set n=0,k=""
        for  set k=$order(arr(k)) quit:k=""  set n=n+1
        quit n
        ;
mean(arr)       ; Arithmetic mean = sum / count. "" if arr is empty (no /0).
        ; doc: Example: new a  set a(1)=2,a(2)=4,a(3)=6  write $$mean^STDMATH(.a)  ; 4
        new n
        set n=$$count(.arr)
        if n=0 quit ""
        quit $$sum(.arr)/n
