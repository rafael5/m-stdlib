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
        ; doc: @param s       array   by-ref local; the set
        ; doc: @param value   string  member to add (empty string is silently ignored)
        ; doc: @example       do setAdd^STDCOLL(.s,"alpha")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           $$setHas^STDCOLL, do setRemove^STDCOLL
        if value="" quit
        if $data(s("v",value)) quit
        set s("v",value)=""
        set s("n")=$get(s("n"),0)+1
        quit
        ;
setHas(s,value) ; Return 1 iff value is a member of set s.
        ; doc: @param s       array   by-ref local; the set
        ; doc: @param value   string  candidate member
        ; doc: @returns       bool    1 iff value is a member; 0 otherwise
        ; doc: @example       write $$setHas^STDCOLL(.s,"alpha")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: @see           do setAdd^STDCOLL
        if value="" quit 0
        quit ''$data(s("v",value))
        ;
setRemove(s,value)      ; Remove value from set s; absent values are no-ops.
        ; doc: @param s       array   by-ref local; the set
        ; doc: @param value   string  member to remove
        ; doc: @example       do setRemove^STDCOLL(.s,"alpha")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        if '$data(s("v",value)) quit
        kill s("v",value)
        set s("n")=$get(s("n"),0)-1
        quit
        ;
setSize(s)      ; Return cardinality.
        ; doc: @param s       array   by-ref local
        ; doc: @returns       int     cardinality
        ; doc: @example       write $$setSize^STDCOLL(.s)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $get(s("n"),0)
        ;
setClear(s)     ; Drop every member.
        ; doc: @param s       array   by-ref local
        ; doc: @example       do setClear^STDCOLL(.s)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        kill s
        quit
        ;
setNext(s,prev) ; Return the next member after prev in $order; "" at end.
        ; doc: @param s       array   by-ref local
        ; doc: @param prev    string  previous member ("" for first call)
        ; doc: @returns       string  next member; "" at end
        ; doc: @example       set k=$$setNext^STDCOLL(.s,"") for  quit:k=""  ...
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $order(s("v",prev))
        ;
        ; ---------- Map ----------
        ;
mapPut(m,key,value)     ; Store value at key (overwrites).
        ; doc: @param m       array   by-ref local; the map
        ; doc: @param key     string  map key (empty silently ignored)
        ; doc: @param value   string  value to store
        ; doc: @example       do mapPut^STDCOLL(.m,"name","Alice")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        if key="" quit
        if '$data(m("v",key)) set m("n")=$get(m("n"),0)+1
        set m("v",key)=value
        quit
        ;
mapGet(m,key,default)   ; Return value at key; default if absent.
        ; doc: @param m       array   by-ref local
        ; doc: @param key     string  map key
        ; doc: @param default string  fallback if key absent
        ; doc: @returns       string  stored value or default
        ; doc: @example       set v=$$mapGet^STDCOLL(.m,"name","")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $select($data(m("v",key)):m("v",key),1:default)
        ;
mapHas(m,key)   ; Return 1 iff key is set.
        ; doc: @param m       array   by-ref local
        ; doc: @param key     string  candidate key
        ; doc: @returns       bool    1 iff present; 0 otherwise
        ; doc: @example       write $$mapHas^STDCOLL(.m,"name")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        if key="" quit 0
        quit ''$data(m("v",key))
        ;
mapRemove(m,key)        ; Drop key (no-op when absent).
        ; doc: @param m       array   by-ref local
        ; doc: @param key     string  key to remove
        ; doc: @example       do mapRemove^STDCOLL(.m,"name")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        if '$data(m("v",key)) quit
        kill m("v",key)
        set m("n")=$get(m("n"),0)-1
        quit
        ;
mapSize(m)      ; Return number of keys.
        ; doc: @param m       array   by-ref local
        ; doc: @returns       int     number of keys
        ; doc: @example       write $$mapSize^STDCOLL(.m)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $get(m("n"),0)
        ;
mapClear(m)     ; Drop every entry.
        ; doc: @param m       array   by-ref local
        ; doc: @example       do mapClear^STDCOLL(.m)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        kill m
        quit
        ;
mapNext(m,prev) ; Return next key after prev in $order; "" at end.
        ; doc: @param m       array   by-ref local
        ; doc: @param prev    string  previous key ("" for first call)
        ; doc: @returns       string  next key; "" at end
        ; doc: @example       set k=$$mapNext^STDCOLL(.m,"") for  quit:k=""  ...
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $order(m("v",prev))
        ;
        ; ---------- Stack ----------
        ;
stackPush(s,value)      ; Push value on top of the stack.
        ; doc: @param s       array   by-ref local; the stack
        ; doc: @param value   string  value to push
        ; doc: @example       do stackPush^STDCOLL(.s,"alpha")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new n
        set n=$get(s("n"),0)+1
        set s("v",n)=value
        set s("n")=n
        quit
        ;
stackPop(s)     ; Remove and return the top; "" when empty.
        ; doc: @param s       array   by-ref local
        ; doc: @returns       string  top value; "" when empty
        ; doc: @example       set top=$$stackPop^STDCOLL(.s)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
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
        ; doc: @param s       array   by-ref local
        ; doc: @returns       string  top value; "" when empty
        ; doc: @example       set top=$$stackPeek^STDCOLL(.s)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new n
        set n=$get(s("n"),0)
        if n<1 quit ""
        quit s("v",n)
        ;
stackSize(s)    ; Return depth.
        ; doc: @param s       array   by-ref local
        ; doc: @returns       int     stack depth
        ; doc: @example       write $$stackSize^STDCOLL(.s)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $get(s("n"),0)
        ;
stackClear(s)   ; Drop every entry.
        ; doc: @param s       array   by-ref local
        ; doc: @example       do stackClear^STDCOLL(.s)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        kill s
        quit
        ;
        ; ---------- Queue ----------
        ;
queuePush(q,value)      ; Enqueue at back.
        ; doc: @param q       array   by-ref local; the queue
        ; doc: @param value   string  value to enqueue
        ; doc: @example       do queuePush^STDCOLL(.q,"alpha")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new t
        ; head/tail initialise to (1, 0): empty when t<h.
        if '$data(q("h")) set q("h")=1,q("t")=0
        set t=q("t")+1
        set q("v",t)=value
        set q("t")=t
        quit
        ;
queuePop(q)     ; Dequeue at front; "" when empty.
        ; doc: @param q       array   by-ref local
        ; doc: @returns       string  front value; "" when empty
        ; doc: @example       set front=$$queuePop^STDCOLL(.q)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
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
        ; doc: @param q       array   by-ref local
        ; doc: @returns       string  front value; "" when empty
        ; doc: @example       set front=$$queuePeek^STDCOLL(.q)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new h,t
        set h=$get(q("h"),1),t=$get(q("t"),0)
        if t<h quit ""
        quit q("v",h)
        ;
queueSize(q)    ; Return queue length.
        ; doc: @param q       array   by-ref local
        ; doc: @returns       int     queue length
        ; doc: @example       write $$queueSize^STDCOLL(.q)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new h,t
        set h=$get(q("h"),1),t=$get(q("t"),0)
        if t<h quit 0
        quit t-h+1
        ;
queueClear(q)   ; Drop every entry.
        ; doc: @param q       array   by-ref local
        ; doc: @example       do queueClear^STDCOLL(.q)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        kill q
        quit
        ;
        ; ---------- Deque ----------
        ;
dequePushFront(d,value) ; Push value at the front.
        ; doc: @param d       array   by-ref local; the deque
        ; doc: @param value   string  value to push
        ; doc: @example       do dequePushFront^STDCOLL(.d,"alpha")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new h
        if '$data(d("h")) set d("h")=1,d("t")=0
        set h=d("h")-1
        set d("v",h)=value
        set d("h")=h
        quit
        ;
dequePushBack(d,value)  ; Push value at the back.
        ; doc: @param d       array   by-ref local
        ; doc: @param value   string  value to push
        ; doc: @example       do dequePushBack^STDCOLL(.d,"omega")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new t
        if '$data(d("h")) set d("h")=1,d("t")=0
        set t=d("t")+1
        set d("v",t)=value
        set d("t")=t
        quit
        ;
dequePopFront(d)        ; Pop and return the front; "" when empty.
        ; doc: @param d       array   by-ref local
        ; doc: @returns       string  front value; "" when empty
        ; doc: @example       set v=$$dequePopFront^STDCOLL(.d)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
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
        ; doc: @param d       array   by-ref local
        ; doc: @returns       string  back value; "" when empty
        ; doc: @example       set v=$$dequePopBack^STDCOLL(.d)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
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
        ; doc: @param d       array   by-ref local
        ; doc: @returns       string  front value; "" when empty
        ; doc: @example       set v=$$dequePeekFront^STDCOLL(.d)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new h,t
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit ""
        quit d("v",h)
        ;
dequePeekBack(d)        ; Return back without removal; "" when empty.
        ; doc: @param d       array   by-ref local
        ; doc: @returns       string  back value; "" when empty
        ; doc: @example       set v=$$dequePeekBack^STDCOLL(.d)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new h,t
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit ""
        quit d("v",t)
        ;
dequeSize(d)    ; Return deque length.
        ; doc: @param d       array   by-ref local
        ; doc: @returns       int     deque length
        ; doc: @example       write $$dequeSize^STDCOLL(.d)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new h,t
        set h=$get(d("h"),1),t=$get(d("t"),0)
        if t<h quit 0
        quit t-h+1
        ;
dequeClear(d)   ; Drop every entry.
        ; doc: @param d       array   by-ref local
        ; doc: @example       do dequeClear^STDCOLL(.d)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        kill d
        quit
        ;
        ; ---------- Heap (min-heap, numeric keys) ----------
        ;
heapPush(h,key,value)   ; Push (key, value) onto the heap.
        ; doc: @param h       array   by-ref local; the heap
        ; doc: @param key     num     numeric priority (smaller = higher priority in min-heap)
        ; doc: @param value   string  payload; defaults to key if omitted
        ; doc: @example       do heapPush^STDCOLL(.h,3,"task A")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
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
        ; doc: @param h       array   by-ref local
        ; doc: @returns       string  payload at the min key; "" when empty
        ; doc: @example       set v=$$heapPop^STDCOLL(.h)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new n,v
        set n=$get(h("n"),0)
        if n<1 quit ""
        set v=h("v",1)
        do heapRemoveTop(.h,n)
        quit v
        ;
heapPopKey(h)   ; Pop and return the min key; "" when empty.
        ; doc: @param h       array   by-ref local
        ; doc: @returns       num     min key; "" when empty
        ; doc: @example       set k=$$heapPopKey^STDCOLL(.h)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new n,k
        set n=$get(h("n"),0)
        if n<1 quit ""
        set k=h("k",1)
        do heapRemoveTop(.h,n)
        quit k
        ;
heapPeek(h)     ; Return value at min key without removal; "" when empty.
        ; doc: @param h       array   by-ref local
        ; doc: @returns       string  payload at min key; "" when empty
        ; doc: @example       set v=$$heapPeek^STDCOLL(.h)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        if $get(h("n"),0)<1 quit ""
        quit h("v",1)
        ;
heapPeekKey(h)  ; Return min key without removal; "" when empty.
        ; doc: @param h       array   by-ref local
        ; doc: @returns       num     min key; "" when empty
        ; doc: @example       set k=$$heapPeekKey^STDCOLL(.h)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        if $get(h("n"),0)<1 quit ""
        quit h("k",1)
        ;
heapSize(h)     ; Return heap size.
        ; doc: @param h       array   by-ref local
        ; doc: @returns       int     heap size
        ; doc: @example       write $$heapSize^STDCOLL(.h)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $get(h("n"),0)
        ;
heapClear(h)    ; Drop every entry.
        ; doc: @param h       array   by-ref local
        ; doc: @example       do heapClear^STDCOLL(.h)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        kill h
        quit
        ;
        ; ---------- heap helpers ----------
        ;
heapRemoveTop(h,n)      ; Remove the root, restoring the heap property.
        ; doc: @internal
        ; doc: Called by heapPop / heapPopKey after the root value has
        ; doc: been captured. Replaces the root with the last leaf and
        ; doc: sifts it down; clears the array entirely on n=1.
        if n=1 kill h quit
        set h("k",1)=h("k",n)
        set h("v",1)=h("v",n)
        kill h("k",n),h("v",n)
        set h("n")=n-1
        do siftdown(.h,1)
        quit
        ;
siftup(h,i)     ; Restore heap order by walking i toward the root.
        ; doc: @internal
        ; doc: Used by heapPush. Compares h("k",i) against its parent at
        ; doc: i\2 and swaps until the parent is <= the child.
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
        ; doc: @internal
        ; doc: Used after heapRemoveTop replaces the root with the last
        ; doc: leaf. Compares against the smaller of two children and
        ; doc: swaps while a child is strictly less.
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
        ; doc: @param o       array   by-ref local; the ordered dict
        ; doc: @param key     string  dict key (empty silently ignored)
        ; doc: @param value   string  value to store
        ; doc: @example       do odictPut^STDCOLL(.o,"name","Alice")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        ; doc: Sequence numbers are monotonic — an update reuses the
        ; doc: existing position; a new key is appended to the back.
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
        ; doc: @param o       array   by-ref local
        ; doc: @param key     string  dict key
        ; doc: @param default string  fallback if key absent
        ; doc: @returns       string  stored value or default
        ; doc: @example       set v=$$odictGet^STDCOLL(.o,"name","")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $select($data(o("v",key)):o("v",key),1:default)
        ;
odictHas(o,key) ; Return 1 iff key is set.
        ; doc: @param o       array   by-ref local
        ; doc: @param key     string  candidate key
        ; doc: @returns       bool    1 iff present
        ; doc: @example       write $$odictHas^STDCOLL(.o,"name")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        if key="" quit 0
        quit ''$data(o("v",key))
        ;
odictRemove(o,key)      ; Drop key (no-op when absent).
        ; doc: @param o       array   by-ref local
        ; doc: @param key     string  key to remove
        ; doc: @example       do odictRemove^STDCOLL(.o,"name")
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new seq
        if '$data(o("v",key)) quit
        set seq=o("seq",key)
        kill o("v",key),o("seq",key),o("ord",seq)
        set o("n")=$get(o("n"),0)-1
        quit
        ;
odictSize(o)    ; Return number of keys.
        ; doc: @param o       array   by-ref local
        ; doc: @returns       int     number of keys
        ; doc: @example       write $$odictSize^STDCOLL(.o)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        quit $get(o("n"),0)
        ;
odictClear(o)   ; Drop every entry.
        ; doc: @param o       array   by-ref local
        ; doc: @example       do odictClear^STDCOLL(.o)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        kill o
        quit
        ;
odictFirst(o)   ; Return first key in insertion order; "" when empty.
        ; doc: @param o       array   by-ref local
        ; doc: @returns       string  first key; "" when empty
        ; doc: @example       set k=$$odictFirst^STDCOLL(.o)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new s
        set s=$order(o("ord",""))
        if s="" quit ""
        quit o("ord",s)
        ;
odictLast(o)    ; Return last key in insertion order; "" when empty.
        ; doc: @param o       array   by-ref local
        ; doc: @returns       string  last key; "" when empty
        ; doc: @example       set k=$$odictLast^STDCOLL(.o)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new s
        set s=$order(o("ord",""),-1)
        if s="" quit ""
        quit o("ord",s)
        ;
odictNext(o,prev)       ; Return next key (insertion order) after prev; "" at end.
        ; doc: @param o       array   by-ref local
        ; doc: @param prev    string  previous key ("" for first call)
        ; doc: @returns       string  next key; "" at end
        ; doc: @example       set k=$$odictNext^STDCOLL(.o,k)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new s,n
        if prev="" set s=$order(o("ord",""))
        else  set s=$get(o("seq",prev),0)
        if 's quit ""
        if prev'="" set s=$order(o("ord",s))
        if s="" quit ""
        quit o("ord",s)
        ;
odictPrev(o,next)       ; Return previous key (insertion order) before next; "" at start.
        ; doc: @param o       array   by-ref local
        ; doc: @param next    string  next key ("" for last call)
        ; doc: @returns       string  previous key; "" at start
        ; doc: @example       set k=$$odictPrev^STDCOLL(.o,k)
        ; doc: @since         v0.2.0
        ; doc: @stable        stable
        new s
        if next="" set s=$order(o("ord",""),-1)
        else  set s=$get(o("seq",next),0)
        if 's quit ""
        if next'="" set s=$order(o("ord",s),-1)
        if s="" quit ""
        quit o("ord",s)
        ;
