STDCOLL ; m-stdlib — collections (Set, Map, Stack, Queue, Deque, Heap, OrderedDict).
        ;
        ; All collections are by-reference local arrays owned by the caller.
        ; The caller's variable is the collection; killing it disposes of
        ; everything. No process-globals are touched.
        ;
        ; Reserved subscripts inside each collection:
        ;   ("v",...)    values / members / payload
        ;   ("n")        cardinality counter
        ;   ("h")        head index   (queue, deque)
        ;   ("t")        tail index   (queue, deque)
        ;   ("k",i)      heap-array of keys   (heap)
        ;   ("seq",key)  insertion sequence number   (odict)
        ;   ("ord",seq)  reverse map sequence -> key   (odict)
        ;   ("nseq")     monotonic sequence allocator   (odict)
        ;
        ; Public API — each entry point is a procedure call (`do …`) or an
        ; extrinsic ($$ …) per the prefix below.
        ;
        ; Set (unordered, no duplicates; subscript-as-value)
        ;   do setAdd^STDCOLL(.s,value)
        ;   $$setHas^STDCOLL(.s,value)              -> 0|1
        ;   do setRemove^STDCOLL(.s,value)
        ;   $$setSize^STDCOLL(.s)                   -> count
        ;   do setClear^STDCOLL(.s)
        ;   $$setNext^STDCOLL(.s,prev)              -> next member, "" at end
        ;
        ; Map (string-keyed dictionary)
        ;   do mapPut^STDCOLL(.m,key,value)
        ;   $$mapGet^STDCOLL(.m,key,default)        -> value or default
        ;   $$mapHas^STDCOLL(.m,key)                -> 0|1
        ;   do mapRemove^STDCOLL(.m,key)
        ;   $$mapSize^STDCOLL(.m)
        ;   do mapClear^STDCOLL(.m)
        ;   $$mapNext^STDCOLL(.m,prev)              -> next key in $order
        ;
        ; Stack (LIFO)
        ;   do stackPush^STDCOLL(.s,value)
        ;   $$stackPop^STDCOLL(.s)                  -> top; "" if empty
        ;   $$stackPeek^STDCOLL(.s)                 -> top without removal
        ;   $$stackSize^STDCOLL(.s)
        ;   do stackClear^STDCOLL(.s)
        ;
        ; Queue (FIFO; head/tail indices)
        ;   do queuePush^STDCOLL(.q,value)          enqueue at back
        ;   $$queuePop^STDCOLL(.q)                  dequeue front; "" if empty
        ;   $$queuePeek^STDCOLL(.q)                 front without removal
        ;   $$queueSize^STDCOLL(.q)
        ;   do queueClear^STDCOLL(.q)
        ;
        ; Deque (double-ended)
        ;   do dequePushFront^STDCOLL(.d,value)
        ;   do dequePushBack^STDCOLL(.d,value)
        ;   $$dequePopFront^STDCOLL(.d)
        ;   $$dequePopBack^STDCOLL(.d)
        ;   $$dequePeekFront^STDCOLL(.d)
        ;   $$dequePeekBack^STDCOLL(.d)
        ;   $$dequeSize^STDCOLL(.d)
        ;   do dequeClear^STDCOLL(.d)
        ;
        ; Heap (min-heap; numeric key, optional payload)
        ;   do heapPush^STDCOLL(.h,key[,value])     value defaults to key
        ;   $$heapPop^STDCOLL(.h)                   value at min key; ""
        ;   $$heapPopKey^STDCOLL(.h)                min key; ""
        ;   $$heapPeek^STDCOLL(.h)                  value at min key
        ;   $$heapPeekKey^STDCOLL(.h)               min key
        ;   $$heapSize^STDCOLL(.h)
        ;   do heapClear^STDCOLL(.h)
        ;
        ; OrderedDict (insertion-ordered map; update keeps original position)
        ;   do odictPut^STDCOLL(.o,key,value)
        ;   $$odictGet^STDCOLL(.o,key,default)
        ;   $$odictHas^STDCOLL(.o,key)
        ;   do odictRemove^STDCOLL(.o,key)
        ;   $$odictSize^STDCOLL(.o)
        ;   do odictClear^STDCOLL(.o)
        ;   $$odictFirst^STDCOLL(.o)                first key in insertion order
        ;   $$odictLast^STDCOLL(.o)                 last key in insertion order
        ;   $$odictNext^STDCOLL(.o,prev)            forward step
        ;   $$odictPrev^STDCOLL(.o,next)            reverse step
        ;
        ; Edge cases:
        ;   - Empty-string set members and map / odict keys are silently
        ;     ignored on add / put: M's $order cannot enumerate the empty
        ;     subscript, and the API would not be able to round-trip them.
        ;   - Pop / peek on empty silently returns "". Callers gate on
        ;     `*Size` when they need to distinguish empty from a stored "".
        ;   - Heap keys must be numeric (compared with M's `<`).
        ;   - All collections may be reset by `kill <var>`; every entry
        ;     point reads counters via `$get(...,0)` so a fresh / killed
        ;     variable is indistinguishable from an explicitly cleared one.
        ;
        quit
        ;
        ; ---------- Set ----------
        ;
setAdd(s,value) ; Add value to set s (idempotent).
        ; doc: Empty-string members are silently ignored — the iteration
        ; doc: API uses $order, which cannot reach an empty subscript.
        ; doc: Example: do setAdd^STDCOLL(.s,"alpha")
        if value="" quit
        if $data(s("v",value)) quit
        set s("v",value)=""
        set s("n")=$get(s("n"),0)+1
        quit
        ;
setHas(s,value) ; Return 1 iff value is a member of set s.
        ; doc: Example: write $$setHas^STDCOLL(.s,"alpha")
        if value="" quit 0
        quit ''$data(s("v",value))
        ;
setRemove(s,value)      ; Remove value from set s; absent values are no-ops.
        ; doc: Example: do setRemove^STDCOLL(.s,"alpha")
        if '$data(s("v",value)) quit
        kill s("v",value)
        set s("n")=$get(s("n"),0)-1
        quit
        ;
setSize(s)      ; Return cardinality.
        ; doc: Example: write $$setSize^STDCOLL(.s)
        quit $get(s("n"),0)
        ;
setClear(s)     ; Drop every member.
        ; doc: Example: do setClear^STDCOLL(.s)
        kill s
        quit
        ;
setNext(s,prev) ; Return the next member after prev in $order; "" at end.
        ; doc: Pass "" for the first call; loop until "" is returned.
        ; doc: Example: set k=$$setNext^STDCOLL(.s,"") for  quit:k=""  ...
        quit $order(s("v",prev))
        ;
        ; ---------- Map ----------
        ;
mapPut(m,key,value)     ; Store value at key (overwrites).
        ; doc: Empty-string keys are silently ignored — see preamble.
        ; doc: Example: do mapPut^STDCOLL(.m,"name","Alice")
        if key="" quit
        if '$data(m("v",key)) set m("n")=$get(m("n"),0)+1
        set m("v",key)=value
        quit
        ;
mapGet(m,key,default)   ; Return value at key; default if absent.
        ; doc: Example: set v=$$mapGet^STDCOLL(.m,"name","")
        quit $select($data(m("v",key)):m("v",key),1:default)
        ;
mapHas(m,key)   ; Return 1 iff key is set.
        ; doc: Example: write $$mapHas^STDCOLL(.m,"name")
        if key="" quit 0
        quit ''$data(m("v",key))
        ;
mapRemove(m,key)        ; Drop key (no-op when absent).
        ; doc: Example: do mapRemove^STDCOLL(.m,"name")
        if '$data(m("v",key)) quit
        kill m("v",key)
        set m("n")=$get(m("n"),0)-1
        quit
        ;
mapSize(m)      ; Return number of keys.
        ; doc: Example: write $$mapSize^STDCOLL(.m)
        quit $get(m("n"),0)
        ;
mapClear(m)     ; Drop every entry.
        ; doc: Example: do mapClear^STDCOLL(.m)
        kill m
        quit
        ;
mapNext(m,prev) ; Return next key after prev in $order; "" at end.
        ; doc: Example: set k=$$mapNext^STDCOLL(.m,"") for  quit:k=""  ...
        quit $order(m("v",prev))
        ;
        ; ---------- Stack ----------
        ;
stackPush(s,value)      ; Push value on top of the stack.
        ; doc: Example: do stackPush^STDCOLL(.s,"alpha")
        new n
        set n=$get(s("n"),0)+1
        set s("v",n)=value
        set s("n")=n
        quit
        ;
stackPop(s)     ; Remove and return the top; "" when empty.
        ; doc: Example: set top=$$stackPop^STDCOLL(.s)
        new n,v
        set n=$get(s("n"),0)
        if n<1 quit ""
        set v=s("v",n)
        kill s("v",n)
        if n=1 kill s quit v
        set s("n")=n-1
        quit v
        ;
stackPeek(s)    ; Return the top without removal; "" when empty.
        ; doc: Example: set top=$$stackPeek^STDCOLL(.s)
        new n
        set n=$get(s("n"),0)
        if n<1 quit ""
        quit s("v",n)
        ;
stackSize(s)    ; Return depth.
        ; doc: Example: write $$stackSize^STDCOLL(.s)
        quit $get(s("n"),0)
        ;
stackClear(s)   ; Drop every entry.
        ; doc: Example: do stackClear^STDCOLL(.s)
        kill s
        quit
        ;
        ; ---------- Queue ----------
        ;
queuePush(q,value)      ; Enqueue at back.
        ; doc: Example: do queuePush^STDCOLL(.q,"alpha")
        new t
        ; head/tail initialise to (1, 0): empty when t<h.
        if '$data(q("h")) set q("h")=1,q("t")=0
        set t=q("t")+1
        set q("v",t)=value
        set q("t")=t
        quit
        ;
queuePop(q)     ; Dequeue at front; "" when empty.
        ; doc: Example: set front=$$queuePop^STDCOLL(.q)
        new h,t,v
        set h=$get(q("h"),1),t=$get(q("t"),0)
        if t<h quit ""
        set v=q("v",h)
        kill q("v",h)
        if h=t kill q quit v
        set q("h")=h+1
        quit v
        ;
queuePeek(q)    ; Return front without removal; "" when empty.
        ; doc: Example: set front=$$queuePeek^STDCOLL(.q)
        new h,t
        set h=$get(q("h"),1),t=$get(q("t"),0)
        if t<h quit ""
        quit q("v",h)
        ;
queueSize(q)    ; Return queue length.
        ; doc: Example: write $$queueSize^STDCOLL(.q)
        new h,t
        set h=$get(q("h"),1),t=$get(q("t"),0)
        if t<h quit 0
        quit t-h+1
        ;
queueClear(q)   ; Drop every entry.
        ; doc: Example: do queueClear^STDCOLL(.q)
        kill q
        quit
        ;
        ; ---------- Deque ----------
        ;
dequePushFront(d,value) ; Push value at the front.
        ; doc: Front is q("h")-1 after the push.
        ; doc: Example: do dequePushFront^STDCOLL(.d,"alpha")
        new h
        if '$data(d("h")) set d("h")=1,d("t")=0
        set h=d("h")-1
        set d("v",h)=value
        set d("h")=h
        quit
        ;
dequePushBack(d,value)  ; Push value at the back.
        ; doc: Example: do dequePushBack^STDCOLL(.d,"omega")
        new t
        if '$data(d("h")) set d("h")=1,d("t")=0
        set t=d("t")+1
        set d("v",t)=value
        set d("t")=t
        quit
        ;
dequePopFront(d)        ; Pop and return the front; "" when empty.
        ; doc: Example: set v=$$dequePopFront^STDCOLL(.d)
        new h,t,v
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit ""
        set v=d("v",h)
        kill d("v",h)
        if h=t kill d quit v
        set d("h")=h+1
        quit v
        ;
dequePopBack(d) ; Pop and return the back; "" when empty.
        ; doc: Example: set v=$$dequePopBack^STDCOLL(.d)
        new h,t,v
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit ""
        set v=d("v",t)
        kill d("v",t)
        if h=t kill d quit v
        set d("t")=t-1
        quit v
        ;
dequePeekFront(d)       ; Return front without removal; "" when empty.
        ; doc: Example: set v=$$dequePeekFront^STDCOLL(.d)
        new h,t
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit ""
        quit d("v",h)
        ;
dequePeekBack(d)        ; Return back without removal; "" when empty.
        ; doc: Example: set v=$$dequePeekBack^STDCOLL(.d)
        new h,t
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit ""
        quit d("v",t)
        ;
dequeSize(d)    ; Return deque length.
        ; doc: Example: write $$dequeSize^STDCOLL(.d)
        new h,t
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit 0
        quit t-h+1
        ;
dequeClear(d)   ; Drop every entry.
        ; doc: Example: do dequeClear^STDCOLL(.d)
        kill d
        quit
        ;
        ; ---------- Heap (min-heap, numeric keys) ----------
        ;
heapPush(h,key,value)   ; Push (key, value) onto the heap.
        ; doc: Sort uses M's numeric `<` over keys. value defaults to key
        ; doc: when omitted so a heap-of-numbers form just works.
        ; doc: Example: do heapPush^STDCOLL(.h,3,"task A")
        new n,val
        set val=$select($data(value):value,1:key)
        set n=$get(h("n"),0)+1
        set h("k",n)=key
        set h("v",n)=val
        set h("n")=n
        do siftup(.h,n)
        quit
        ;
heapPop(h)      ; Pop value at the min key; "" when empty.
        ; doc: Example: set v=$$heapPop^STDCOLL(.h)
        new n,v
        set n=$get(h("n"),0)
        if n<1 quit ""
        set v=h("v",1)
        do heapRemoveTop(.h,n)
        quit v
        ;
heapPopKey(h)   ; Pop and return the min key; "" when empty.
        ; doc: Example: set k=$$heapPopKey^STDCOLL(.h)
        new n,k
        set n=$get(h("n"),0)
        if n<1 quit ""
        set k=h("k",1)
        do heapRemoveTop(.h,n)
        quit k
        ;
heapPeek(h)     ; Return value at min key without removal; "" when empty.
        ; doc: Example: set v=$$heapPeek^STDCOLL(.h)
        if $get(h("n"),0)<1 quit ""
        quit h("v",1)
        ;
heapPeekKey(h)  ; Return min key without removal; "" when empty.
        ; doc: Example: set k=$$heapPeekKey^STDCOLL(.h)
        if $get(h("n"),0)<1 quit ""
        quit h("k",1)
        ;
heapSize(h)     ; Return heap size.
        ; doc: Example: write $$heapSize^STDCOLL(.h)
        quit $get(h("n"),0)
        ;
heapClear(h)    ; Drop every entry.
        ; doc: Example: do heapClear^STDCOLL(.h)
        kill h
        quit
        ;
        ; ---------- heap helpers ----------
        ;
heapRemoveTop(h,n)      ; Remove the root, restoring the heap property.
        ; doc: Internal — called by heapPop / heapPopKey after the root
        ; doc: value has been captured. Replaces the root with the last
        ; doc: leaf and sifts it down; clears the array entirely on n=1.
        if n=1 kill h quit
        set h("k",1)=h("k",n)
        set h("v",1)=h("v",n)
        kill h("k",n),h("v",n)
        set h("n")=n-1
        do siftdown(.h,1)
        quit
        ;
siftup(h,i)     ; Restore heap order by walking i toward the root.
        ; doc: Internal — used by heapPush. Compares h("k",i) against its
        ; doc: parent at i\2 and swaps until the parent is <= the child.
        new p,tk,tv
        for  quit:i'>1  do
        . set p=i\2
        . if h("k",p)'>h("k",i) set i=1 quit
        . set tk=h("k",p),tv=h("v",p)
        . set h("k",p)=h("k",i),h("v",p)=h("v",i)
        . set h("k",i)=tk,h("v",i)=tv
        . set i=p
        quit
        ;
siftdown(h,i)   ; Restore heap order by walking i toward the leaves.
        ; doc: Internal — used after heapRemoveTop replaces the root with
        ; doc: the last leaf. Compares against the smaller of two children
        ; doc: and swaps while a child is strictly less.
        new n,c,r,smallest,tk,tv
        set n=$get(h("n"),0),smallest=-1
        for  do  quit:smallest=i
        . set c=2*i,r=c+1,smallest=i
        . if c'>n,h("k",c)<h("k",smallest) set smallest=c
        . if r'>n,h("k",r)<h("k",smallest) set smallest=r
        . if smallest=i quit
        . set tk=h("k",i),tv=h("v",i)
        . set h("k",i)=h("k",smallest),h("v",i)=h("v",smallest)
        . set h("k",smallest)=tk,h("v",smallest)=tv
        . set i=smallest,smallest=-1
        quit
        ;
        ; ---------- OrderedDict ----------
        ;
odictPut(o,key,value)   ; Store value at key; create-or-update preserving position.
        ; doc: Sequence numbers are monotonic — an update reuses the
        ; doc: existing position; a new key is appended to the back.
        ; doc: Empty-string keys are silently ignored (see preamble).
        ; doc: Example: do odictPut^STDCOLL(.o,"name","Alice")
        new seq
        if key="" quit
        if $data(o("v",key)) set o("v",key)=value quit
        set seq=$get(o("nseq"),0)+1
        set o("nseq")=seq
        set o("v",key)=value
        set o("seq",key)=seq
        set o("ord",seq)=key
        set o("n")=$get(o("n"),0)+1
        quit
        ;
odictGet(o,key,default) ; Return value at key; default if absent.
        ; doc: Example: set v=$$odictGet^STDCOLL(.o,"name","")
        quit $select($data(o("v",key)):o("v",key),1:default)
        ;
odictHas(o,key) ; Return 1 iff key is set.
        ; doc: Example: write $$odictHas^STDCOLL(.o,"name")
        if key="" quit 0
        quit ''$data(o("v",key))
        ;
odictRemove(o,key)      ; Drop key (no-op when absent).
        ; doc: Example: do odictRemove^STDCOLL(.o,"name")
        new seq
        if '$data(o("v",key)) quit
        set seq=o("seq",key)
        kill o("v",key),o("seq",key),o("ord",seq)
        set o("n")=$get(o("n"),0)-1
        quit
        ;
odictSize(o)    ; Return number of keys.
        ; doc: Example: write $$odictSize^STDCOLL(.o)
        quit $get(o("n"),0)
        ;
odictClear(o)   ; Drop every entry.
        ; doc: Example: do odictClear^STDCOLL(.o)
        kill o
        quit
        ;
odictFirst(o)   ; Return first key in insertion order; "" when empty.
        ; doc: Example: set k=$$odictFirst^STDCOLL(.o)
        new s
        set s=$order(o("ord",""))
        if s="" quit ""
        quit o("ord",s)
        ;
odictLast(o)    ; Return last key in insertion order; "" when empty.
        ; doc: Example: set k=$$odictLast^STDCOLL(.o)
        new s
        set s=$order(o("ord",""),-1)
        if s="" quit ""
        quit o("ord",s)
        ;
odictNext(o,prev)       ; Return next key (insertion order) after prev; "" at end.
        ; doc: Pair with odictFirst to walk forward; pass "" to get the
        ; doc: first key. Skips entries removed via odictRemove.
        ; doc: Example: set k=$$odictNext^STDCOLL(.o,k)
        new s,n
        if prev="" set s=$order(o("ord",""))
        else  set s=$get(o("seq",prev),0)
        if 's quit ""
        if prev'="" set s=$order(o("ord",s))
        if s="" quit ""
        quit o("ord",s)
        ;
odictPrev(o,next)       ; Return previous key (insertion order) before next; "" at start.
        ; doc: Pair with odictLast to walk backward; pass "" to get the
        ; doc: last key. Skips entries removed via odictRemove.
        ; doc: Example: set k=$$odictPrev^STDCOLL(.o,k)
        new s
        if next="" set s=$order(o("ord",""),-1)
        else  set s=$get(o("seq",next),0)
        if 's quit ""
        if next'="" set s=$order(o("ord",s),-1)
        if s="" quit ""
        quit o("ord",s)
        ;
