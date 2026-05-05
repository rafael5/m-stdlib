STDCOLLTST      ; Test suite for STDCOLL (v0.2.0).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; ---------- Set ----------
        do tSetAddAndHas(.pass,.fail)
        do tSetAddIdempotent(.pass,.fail)
        do tSetRemove(.pass,.fail)
        do tSetSize(.pass,.fail)
        do tSetClear(.pass,.fail)
        do tSetNextIteration(.pass,.fail)
        do tSetEmptyKeyNoOp(.pass,.fail)
        ;
        ; ---------- Map ----------
        do tMapPutGet(.pass,.fail)
        do tMapPutOverwrites(.pass,.fail)
        do tMapGetDefault(.pass,.fail)
        do tMapHas(.pass,.fail)
        do tMapRemove(.pass,.fail)
        do tMapSize(.pass,.fail)
        do tMapClear(.pass,.fail)
        do tMapNextIteration(.pass,.fail)
        ;
        ; ---------- Stack ----------
        do tStackPushPop(.pass,.fail)
        do tStackPeek(.pass,.fail)
        do tStackSize(.pass,.fail)
        do tStackClear(.pass,.fail)
        do tStackPopEmptyIsBlank(.pass,.fail)
        ;
        ; ---------- Queue ----------
        do tQueueFifo(.pass,.fail)
        do tQueuePeek(.pass,.fail)
        do tQueueSize(.pass,.fail)
        do tQueueClear(.pass,.fail)
        do tQueuePopEmptyIsBlank(.pass,.fail)
        ;
        ; ---------- Deque ----------
        do tDequePushFrontBack(.pass,.fail)
        do tDequePopFrontBack(.pass,.fail)
        do tDequePeekFront(.pass,.fail)
        do tDequePeekBack(.pass,.fail)
        do tDequeSize(.pass,.fail)
        do tDequeClear(.pass,.fail)
        do tDequePopFrontEmpty(.pass,.fail)
        do tDequePopBackEmpty(.pass,.fail)
        ;
        ; ---------- Heap ----------
        do tHeapMinOrder(.pass,.fail)
        do tHeapWithValues(.pass,.fail)
        do tHeapDefaultValueIsKey(.pass,.fail)
        do tHeapPopKey(.pass,.fail)
        do tHeapPeek(.pass,.fail)
        do tHeapPeekKey(.pass,.fail)
        do tHeapSize(.pass,.fail)
        do tHeapClear(.pass,.fail)
        do tHeapPopEmptyIsBlank(.pass,.fail)
        ;
        ; ---------- OrderedDict ----------
        do tOdictInsertionOrder(.pass,.fail)
        do tOdictUpdateKeepsPosition(.pass,.fail)
        do tOdictGet(.pass,.fail)
        do tOdictGetDefault(.pass,.fail)
        do tOdictHas(.pass,.fail)
        do tOdictRemove(.pass,.fail)
        do tOdictRemoveSkipsInIteration(.pass,.fail)
        do tOdictSize(.pass,.fail)
        do tOdictClear(.pass,.fail)
        do tOdictFirstLast(.pass,.fail)
        do tOdictNextPrev(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---------- Set ----------
        ;
tSetAddAndHas(pass,fail)        ;@TEST "setAdd registers a value; setHas returns 1"
        new s
        do setAdd^STDCOLL(.s,"alpha")
        do setAdd^STDCOLL(.s,"beta")
        do eq^STDASSERT(.pass,.fail,$$setHas^STDCOLL(.s,"alpha"),1,"alpha present")
        do eq^STDASSERT(.pass,.fail,$$setHas^STDCOLL(.s,"beta"),1,"beta present")
        do eq^STDASSERT(.pass,.fail,$$setHas^STDCOLL(.s,"gamma"),0,"gamma absent")
        quit
        ;
tSetAddIdempotent(pass,fail)    ;@TEST "setAdd of an existing member leaves size unchanged"
        new s
        do setAdd^STDCOLL(.s,"x")
        do setAdd^STDCOLL(.s,"x")
        do setAdd^STDCOLL(.s,"x")
        do eq^STDASSERT(.pass,.fail,$$setSize^STDCOLL(.s),1,"size after triple add")
        quit
        ;
tSetRemove(pass,fail)   ;@TEST "setRemove drops a member; setHas returns 0; absent remove is a no-op"
        new s
        do setAdd^STDCOLL(.s,"a")
        do setAdd^STDCOLL(.s,"b")
        do setRemove^STDCOLL(.s,"a")
        do eq^STDASSERT(.pass,.fail,$$setHas^STDCOLL(.s,"a"),0,"a removed")
        do eq^STDASSERT(.pass,.fail,$$setHas^STDCOLL(.s,"b"),1,"b retained")
        do setRemove^STDCOLL(.s,"never-present")
        do eq^STDASSERT(.pass,.fail,$$setSize^STDCOLL(.s),1,"absent-remove no-op")
        quit
        ;
tSetSize(pass,fail)     ;@TEST "setSize tracks add/remove cardinality"
        new s
        do eq^STDASSERT(.pass,.fail,$$setSize^STDCOLL(.s),0,"empty size")
        do setAdd^STDCOLL(.s,"a")
        do setAdd^STDCOLL(.s,"b")
        do setAdd^STDCOLL(.s,"c")
        do eq^STDASSERT(.pass,.fail,$$setSize^STDCOLL(.s),3,"after 3 adds")
        do setRemove^STDCOLL(.s,"b")
        do eq^STDASSERT(.pass,.fail,$$setSize^STDCOLL(.s),2,"after 1 remove")
        quit
        ;
tSetClear(pass,fail)    ;@TEST "setClear empties the set"
        new s
        do setAdd^STDCOLL(.s,"a")
        do setAdd^STDCOLL(.s,"b")
        do setClear^STDCOLL(.s)
        do eq^STDASSERT(.pass,.fail,$$setSize^STDCOLL(.s),0,"size 0 after clear")
        do eq^STDASSERT(.pass,.fail,$$setHas^STDCOLL(.s,"a"),0,"members gone")
        quit
        ;
tSetNextIteration(pass,fail)    ;@TEST "setNext walks members in M $order sequence"
        new s,k,seen
        do setAdd^STDCOLL(.s,"banana")
        do setAdd^STDCOLL(.s,"apple")
        do setAdd^STDCOLL(.s,"cherry")
        set seen=""
        set k=$$setNext^STDCOLL(.s,"")
        for  quit:k=""  set seen=seen_k_"|" set k=$$setNext^STDCOLL(.s,k)
        do eq^STDASSERT(.pass,.fail,seen,"apple|banana|cherry|","ascending walk")
        quit
        ;
tSetEmptyKeyNoOp(pass,fail)     ;@TEST "setAdd of empty string is a documented no-op"
        new s
        do setAdd^STDCOLL(.s,"")
        do eq^STDASSERT(.pass,.fail,$$setSize^STDCOLL(.s),0,"empty member ignored")
        do eq^STDASSERT(.pass,.fail,$$setHas^STDCOLL(.s,""),0,"empty member never present")
        quit
        ;
        ; ---------- Map ----------
        ;
tMapPutGet(pass,fail)   ;@TEST "mapPut stores; mapGet retrieves"
        new m
        do mapPut^STDCOLL(.m,"name","Alice")
        do mapPut^STDCOLL(.m,"city","NYC")
        do eq^STDASSERT(.pass,.fail,$$mapGet^STDCOLL(.m,"name",""),"Alice","name")
        do eq^STDASSERT(.pass,.fail,$$mapGet^STDCOLL(.m,"city",""),"NYC","city")
        quit
        ;
tMapPutOverwrites(pass,fail)    ;@TEST "mapPut overwrites existing key without changing size"
        new m
        do mapPut^STDCOLL(.m,"k","first")
        do mapPut^STDCOLL(.m,"k","second")
        do eq^STDASSERT(.pass,.fail,$$mapGet^STDCOLL(.m,"k",""),"second","overwrite wins")
        do eq^STDASSERT(.pass,.fail,$$mapSize^STDCOLL(.m),1,"size unchanged")
        quit
        ;
tMapGetDefault(pass,fail)       ;@TEST "mapGet returns default for missing key"
        new m
        do mapPut^STDCOLL(.m,"present","yes")
        do eq^STDASSERT(.pass,.fail,$$mapGet^STDCOLL(.m,"absent","fallback"),"fallback","default returned")
        do eq^STDASSERT(.pass,.fail,$$mapGet^STDCOLL(.m,"present","fallback"),"yes","present wins over default")
        quit
        ;
tMapHas(pass,fail)      ;@TEST "mapHas distinguishes set keys from absent keys"
        new m
        do mapPut^STDCOLL(.m,"k","")
        do eq^STDASSERT(.pass,.fail,$$mapHas^STDCOLL(.m,"k"),1,"key with empty value still present")
        do eq^STDASSERT(.pass,.fail,$$mapHas^STDCOLL(.m,"missing"),0,"missing absent")
        quit
        ;
tMapRemove(pass,fail)   ;@TEST "mapRemove drops the key; size decrements; absent-remove is a no-op"
        new m
        do mapPut^STDCOLL(.m,"a","1")
        do mapPut^STDCOLL(.m,"b","2")
        do mapRemove^STDCOLL(.m,"a")
        do eq^STDASSERT(.pass,.fail,$$mapHas^STDCOLL(.m,"a"),0,"a removed")
        do eq^STDASSERT(.pass,.fail,$$mapSize^STDCOLL(.m),1,"size decremented")
        do mapRemove^STDCOLL(.m,"never-present")
        do eq^STDASSERT(.pass,.fail,$$mapSize^STDCOLL(.m),1,"absent-remove no-op")
        quit
        ;
tMapSize(pass,fail)     ;@TEST "mapSize counts distinct keys"
        new m
        do eq^STDASSERT(.pass,.fail,$$mapSize^STDCOLL(.m),0,"empty")
        do mapPut^STDCOLL(.m,"a","1")
        do mapPut^STDCOLL(.m,"b","2")
        do mapPut^STDCOLL(.m,"c","3")
        do eq^STDASSERT(.pass,.fail,$$mapSize^STDCOLL(.m),3,"three keys")
        quit
        ;
tMapClear(pass,fail)    ;@TEST "mapClear empties the map"
        new m
        do mapPut^STDCOLL(.m,"a","1")
        do mapPut^STDCOLL(.m,"b","2")
        do mapClear^STDCOLL(.m)
        do eq^STDASSERT(.pass,.fail,$$mapSize^STDCOLL(.m),0,"size 0")
        do eq^STDASSERT(.pass,.fail,$$mapHas^STDCOLL(.m,"a"),0,"keys gone")
        quit
        ;
tMapNextIteration(pass,fail)    ;@TEST "mapNext walks keys in M $order sequence"
        new m,k,seen
        do mapPut^STDCOLL(.m,"third","3")
        do mapPut^STDCOLL(.m,"first","1")
        do mapPut^STDCOLL(.m,"second","2")
        set seen=""
        set k=$$mapNext^STDCOLL(.m,"")
        for  quit:k=""  set seen=seen_k_"|" set k=$$mapNext^STDCOLL(.m,k)
        do eq^STDASSERT(.pass,.fail,seen,"first|second|third|","ascending key walk")
        quit
        ;
        ; ---------- Stack ----------
        ;
tStackPushPop(pass,fail)        ;@TEST "stackPush / stackPop are LIFO"
        new s
        do stackPush^STDCOLL(.s,"a")
        do stackPush^STDCOLL(.s,"b")
        do stackPush^STDCOLL(.s,"c")
        do eq^STDASSERT(.pass,.fail,$$stackPop^STDCOLL(.s),"c","top first")
        do eq^STDASSERT(.pass,.fail,$$stackPop^STDCOLL(.s),"b","middle next")
        do eq^STDASSERT(.pass,.fail,$$stackPop^STDCOLL(.s),"a","bottom last")
        do eq^STDASSERT(.pass,.fail,$$stackSize^STDCOLL(.s),0,"empty after drain")
        quit
        ;
tStackPeek(pass,fail)   ;@TEST "stackPeek returns top without popping"
        new s
        do stackPush^STDCOLL(.s,"x")
        do stackPush^STDCOLL(.s,"y")
        do eq^STDASSERT(.pass,.fail,$$stackPeek^STDCOLL(.s),"y","peek y")
        do eq^STDASSERT(.pass,.fail,$$stackSize^STDCOLL(.s),2,"size unchanged")
        quit
        ;
tStackSize(pass,fail)   ;@TEST "stackSize tracks push/pop"
        new s
        do eq^STDASSERT(.pass,.fail,$$stackSize^STDCOLL(.s),0,"empty")
        do stackPush^STDCOLL(.s,"a")
        do stackPush^STDCOLL(.s,"b")
        do eq^STDASSERT(.pass,.fail,$$stackSize^STDCOLL(.s),2,"after 2 pushes")
        new dropped
        set dropped=$$stackPop^STDCOLL(.s)
        do eq^STDASSERT(.pass,.fail,$$stackSize^STDCOLL(.s),1,"after 1 pop")
        quit
        ;
tStackClear(pass,fail)  ;@TEST "stackClear empties the stack"
        new s
        do stackPush^STDCOLL(.s,"a")
        do stackPush^STDCOLL(.s,"b")
        do stackClear^STDCOLL(.s)
        do eq^STDASSERT(.pass,.fail,$$stackSize^STDCOLL(.s),0,"empty after clear")
        do eq^STDASSERT(.pass,.fail,$$stackPeek^STDCOLL(.s),"","peek empty is blank")
        quit
        ;
tStackPopEmptyIsBlank(pass,fail)        ;@TEST "stackPop on empty silently returns the empty string"
        new s
        do eq^STDASSERT(.pass,.fail,$$stackPop^STDCOLL(.s),"","empty stackPop")
        do eq^STDASSERT(.pass,.fail,$$stackPeek^STDCOLL(.s),"","empty stackPeek")
        quit
        ;
        ; ---------- Queue ----------
        ;
tQueueFifo(pass,fail)   ;@TEST "queuePush / queuePop are FIFO"
        new q
        do queuePush^STDCOLL(.q,"a")
        do queuePush^STDCOLL(.q,"b")
        do queuePush^STDCOLL(.q,"c")
        do eq^STDASSERT(.pass,.fail,$$queuePop^STDCOLL(.q),"a","first in first out")
        do eq^STDASSERT(.pass,.fail,$$queuePop^STDCOLL(.q),"b","second")
        do eq^STDASSERT(.pass,.fail,$$queuePop^STDCOLL(.q),"c","third")
        do eq^STDASSERT(.pass,.fail,$$queueSize^STDCOLL(.q),0,"drained")
        quit
        ;
tQueuePeek(pass,fail)   ;@TEST "queuePeek returns front without popping"
        new q
        do queuePush^STDCOLL(.q,"first")
        do queuePush^STDCOLL(.q,"second")
        do eq^STDASSERT(.pass,.fail,$$queuePeek^STDCOLL(.q),"first","front is first")
        do eq^STDASSERT(.pass,.fail,$$queueSize^STDCOLL(.q),2,"size unchanged")
        quit
        ;
tQueueSize(pass,fail)   ;@TEST "queueSize tracks push/pop"
        new q,dropped
        do eq^STDASSERT(.pass,.fail,$$queueSize^STDCOLL(.q),0,"empty")
        do queuePush^STDCOLL(.q,"a")
        do queuePush^STDCOLL(.q,"b")
        do eq^STDASSERT(.pass,.fail,$$queueSize^STDCOLL(.q),2,"after 2 pushes")
        set dropped=$$queuePop^STDCOLL(.q)
        do eq^STDASSERT(.pass,.fail,$$queueSize^STDCOLL(.q),1,"after 1 pop")
        quit
        ;
tQueueClear(pass,fail)  ;@TEST "queueClear empties the queue"
        new q
        do queuePush^STDCOLL(.q,"a")
        do queuePush^STDCOLL(.q,"b")
        do queueClear^STDCOLL(.q)
        do eq^STDASSERT(.pass,.fail,$$queueSize^STDCOLL(.q),0,"size 0")
        do eq^STDASSERT(.pass,.fail,$$queuePeek^STDCOLL(.q),"","peek empty is blank")
        quit
        ;
tQueuePopEmptyIsBlank(pass,fail)        ;@TEST "queuePop on empty silently returns the empty string"
        new q
        do eq^STDASSERT(.pass,.fail,$$queuePop^STDCOLL(.q),"","empty queuePop")
        do eq^STDASSERT(.pass,.fail,$$queuePeek^STDCOLL(.q),"","empty queuePeek")
        quit
        ;
        ; ---------- Deque ----------
        ;
tDequePushFrontBack(pass,fail)  ;@TEST "dequePushFront / dequePushBack distribute around the centre"
        new d
        do dequePushBack^STDCOLL(.d,"b")
        do dequePushBack^STDCOLL(.d,"c")
        do dequePushFront^STDCOLL(.d,"a")
        do dequePushFront^STDCOLL(.d,"start")
        do eq^STDASSERT(.pass,.fail,$$dequePeekFront^STDCOLL(.d),"start","front is most-recently-front-pushed")
        do eq^STDASSERT(.pass,.fail,$$dequePeekBack^STDCOLL(.d),"c","back is most-recently-back-pushed")
        do eq^STDASSERT(.pass,.fail,$$dequeSize^STDCOLL(.d),4,"all 4 retained")
        quit
        ;
tDequePopFrontBack(pass,fail)   ;@TEST "dequePopFront / dequePopBack drain from each end"
        new d
        do dequePushBack^STDCOLL(.d,"a")
        do dequePushBack^STDCOLL(.d,"b")
        do dequePushBack^STDCOLL(.d,"c")
        do eq^STDASSERT(.pass,.fail,$$dequePopFront^STDCOLL(.d),"a","front pop")
        do eq^STDASSERT(.pass,.fail,$$dequePopBack^STDCOLL(.d),"c","back pop")
        do eq^STDASSERT(.pass,.fail,$$dequePopFront^STDCOLL(.d),"b","middle from front")
        do eq^STDASSERT(.pass,.fail,$$dequeSize^STDCOLL(.d),0,"drained")
        quit
        ;
tDequePeekFront(pass,fail)      ;@TEST "dequePeekFront does not modify the deque"
        new d
        do dequePushBack^STDCOLL(.d,"x")
        do dequePushBack^STDCOLL(.d,"y")
        do eq^STDASSERT(.pass,.fail,$$dequePeekFront^STDCOLL(.d),"x","x at front")
        do eq^STDASSERT(.pass,.fail,$$dequeSize^STDCOLL(.d),2,"size unchanged")
        quit
        ;
tDequePeekBack(pass,fail)       ;@TEST "dequePeekBack does not modify the deque"
        new d
        do dequePushBack^STDCOLL(.d,"x")
        do dequePushBack^STDCOLL(.d,"y")
        do eq^STDASSERT(.pass,.fail,$$dequePeekBack^STDCOLL(.d),"y","y at back")
        do eq^STDASSERT(.pass,.fail,$$dequeSize^STDCOLL(.d),2,"size unchanged")
        quit
        ;
tDequeSize(pass,fail)   ;@TEST "dequeSize tracks pushes and pops"
        new d
        do eq^STDASSERT(.pass,.fail,$$dequeSize^STDCOLL(.d),0,"empty")
        do dequePushFront^STDCOLL(.d,"a")
        do dequePushBack^STDCOLL(.d,"b")
        do dequePushFront^STDCOLL(.d,"z")
        do eq^STDASSERT(.pass,.fail,$$dequeSize^STDCOLL(.d),3,"after 3 pushes")
        quit
        ;
tDequeClear(pass,fail)  ;@TEST "dequeClear empties the deque"
        new d
        do dequePushBack^STDCOLL(.d,"a")
        do dequePushFront^STDCOLL(.d,"b")
        do dequeClear^STDCOLL(.d)
        do eq^STDASSERT(.pass,.fail,$$dequeSize^STDCOLL(.d),0,"size 0")
        do eq^STDASSERT(.pass,.fail,$$dequePeekFront^STDCOLL(.d),"","peek-front empty is blank")
        do eq^STDASSERT(.pass,.fail,$$dequePeekBack^STDCOLL(.d),"","peek-back empty is blank")
        quit
        ;
tDequePopFrontEmpty(pass,fail)  ;@TEST "dequePopFront on empty silently returns blank"
        new d
        do eq^STDASSERT(.pass,.fail,$$dequePopFront^STDCOLL(.d),"","empty front pop")
        quit
        ;
tDequePopBackEmpty(pass,fail)   ;@TEST "dequePopBack on empty silently returns blank"
        new d
        do eq^STDASSERT(.pass,.fail,$$dequePopBack^STDCOLL(.d),"","empty back pop")
        quit
        ;
        ; ---------- Heap ----------
        ;
tHeapMinOrder(pass,fail)        ;@TEST "heapPop returns numeric keys in ascending order"
        new h,seen,v
        do heapPush^STDCOLL(.h,5)
        do heapPush^STDCOLL(.h,2)
        do heapPush^STDCOLL(.h,8)
        do heapPush^STDCOLL(.h,1)
        do heapPush^STDCOLL(.h,4)
        set seen=""
        for  quit:$$heapSize^STDCOLL(.h)=0  set v=$$heapPop^STDCOLL(.h) set seen=seen_v_","
        do eq^STDASSERT(.pass,.fail,seen,"1,2,4,5,8,","ascending pop order")
        quit
        ;
tHeapWithValues(pass,fail)      ;@TEST "heapPush(key,value) returns the value bound to the min key"
        new h
        do heapPush^STDCOLL(.h,3,"task A")
        do heapPush^STDCOLL(.h,1,"task B")
        do heapPush^STDCOLL(.h,2,"task C")
        do eq^STDASSERT(.pass,.fail,$$heapPop^STDCOLL(.h),"task B","min by key 1")
        do eq^STDASSERT(.pass,.fail,$$heapPop^STDCOLL(.h),"task C","next by key 2")
        do eq^STDASSERT(.pass,.fail,$$heapPop^STDCOLL(.h),"task A","last by key 3")
        quit
        ;
tHeapDefaultValueIsKey(pass,fail)       ;@TEST "heapPush with no value defaults the value to the key"
        new h
        do heapPush^STDCOLL(.h,7)
        do heapPush^STDCOLL(.h,3)
        do eq^STDASSERT(.pass,.fail,$$heapPop^STDCOLL(.h),3,"default value is the key")
        quit
        ;
tHeapPopKey(pass,fail)  ;@TEST "heapPopKey returns the min key while removing the entry"
        new h
        do heapPush^STDCOLL(.h,9,"X")
        do heapPush^STDCOLL(.h,4,"Y")
        do eq^STDASSERT(.pass,.fail,$$heapPopKey^STDCOLL(.h),4,"min key returned")
        do eq^STDASSERT(.pass,.fail,$$heapSize^STDCOLL(.h),1,"size decremented")
        quit
        ;
tHeapPeek(pass,fail)    ;@TEST "heapPeek returns the value at the min key without removal"
        new h
        do heapPush^STDCOLL(.h,5,"E")
        do heapPush^STDCOLL(.h,2,"B")
        do heapPush^STDCOLL(.h,7,"G")
        do eq^STDASSERT(.pass,.fail,$$heapPeek^STDCOLL(.h),"B","min value")
        do eq^STDASSERT(.pass,.fail,$$heapSize^STDCOLL(.h),3,"size unchanged")
        quit
        ;
tHeapPeekKey(pass,fail) ;@TEST "heapPeekKey returns the min key without removal"
        new h
        do heapPush^STDCOLL(.h,5)
        do heapPush^STDCOLL(.h,2)
        do heapPush^STDCOLL(.h,7)
        do eq^STDASSERT(.pass,.fail,$$heapPeekKey^STDCOLL(.h),2,"min key")
        do eq^STDASSERT(.pass,.fail,$$heapSize^STDCOLL(.h),3,"size unchanged")
        quit
        ;
tHeapSize(pass,fail)    ;@TEST "heapSize tracks pushes and pops"
        new h,dropped
        do eq^STDASSERT(.pass,.fail,$$heapSize^STDCOLL(.h),0,"empty")
        do heapPush^STDCOLL(.h,1)
        do heapPush^STDCOLL(.h,2)
        do heapPush^STDCOLL(.h,3)
        do eq^STDASSERT(.pass,.fail,$$heapSize^STDCOLL(.h),3,"after 3 pushes")
        set dropped=$$heapPop^STDCOLL(.h)
        do eq^STDASSERT(.pass,.fail,$$heapSize^STDCOLL(.h),2,"after 1 pop")
        quit
        ;
tHeapClear(pass,fail)   ;@TEST "heapClear empties the heap"
        new h
        do heapPush^STDCOLL(.h,1)
        do heapPush^STDCOLL(.h,2)
        do heapClear^STDCOLL(.h)
        do eq^STDASSERT(.pass,.fail,$$heapSize^STDCOLL(.h),0,"size 0")
        do eq^STDASSERT(.pass,.fail,$$heapPeek^STDCOLL(.h),"","peek empty is blank")
        do eq^STDASSERT(.pass,.fail,$$heapPeekKey^STDCOLL(.h),"","peekKey empty is blank")
        quit
        ;
tHeapPopEmptyIsBlank(pass,fail) ;@TEST "heapPop / heapPopKey on empty silently return blank"
        new h
        do eq^STDASSERT(.pass,.fail,$$heapPop^STDCOLL(.h),"","empty heapPop")
        do eq^STDASSERT(.pass,.fail,$$heapPopKey^STDCOLL(.h),"","empty heapPopKey")
        quit
        ;
        ; ---------- OrderedDict ----------
        ;
tOdictInsertionOrder(pass,fail) ;@TEST "odictNext walks keys in insertion order, regardless of M $order"
        new o,k,seen
        do odictPut^STDCOLL(.o,"zulu","z")
        do odictPut^STDCOLL(.o,"alpha","a")
        do odictPut^STDCOLL(.o,"mike","m")
        set seen=""
        set k=$$odictFirst^STDCOLL(.o)
        for  quit:k=""  set seen=seen_k_"|" set k=$$odictNext^STDCOLL(.o,k)
        do eq^STDASSERT(.pass,.fail,seen,"zulu|alpha|mike|","walk follows insertion")
        quit
        ;
tOdictUpdateKeepsPosition(pass,fail)    ;@TEST "odictPut on an existing key updates value but keeps position"
        new o,k,seen
        do odictPut^STDCOLL(.o,"a","1")
        do odictPut^STDCOLL(.o,"b","2")
        do odictPut^STDCOLL(.o,"c","3")
        do odictPut^STDCOLL(.o,"a","UPDATED")
        do eq^STDASSERT(.pass,.fail,$$odictGet^STDCOLL(.o,"a",""),"UPDATED","value updated")
        set seen=""
        set k=$$odictFirst^STDCOLL(.o)
        for  quit:k=""  set seen=seen_k_"|" set k=$$odictNext^STDCOLL(.o,k)
        do eq^STDASSERT(.pass,.fail,seen,"a|b|c|","position retained")
        do eq^STDASSERT(.pass,.fail,$$odictSize^STDCOLL(.o),3,"size unchanged")
        quit
        ;
tOdictGet(pass,fail)    ;@TEST "odictGet retrieves stored value"
        new o
        do odictPut^STDCOLL(.o,"k","v")
        do eq^STDASSERT(.pass,.fail,$$odictGet^STDCOLL(.o,"k",""),"v","retrieved")
        quit
        ;
tOdictGetDefault(pass,fail)     ;@TEST "odictGet returns default for missing key"
        new o
        do eq^STDASSERT(.pass,.fail,$$odictGet^STDCOLL(.o,"x","fallback"),"fallback","fallback returned")
        quit
        ;
tOdictHas(pass,fail)    ;@TEST "odictHas distinguishes set from absent keys"
        new o
        do odictPut^STDCOLL(.o,"k","")
        do eq^STDASSERT(.pass,.fail,$$odictHas^STDCOLL(.o,"k"),1,"empty value present")
        do eq^STDASSERT(.pass,.fail,$$odictHas^STDCOLL(.o,"missing"),0,"absent")
        quit
        ;
tOdictRemove(pass,fail) ;@TEST "odictRemove drops the key and decrements size"
        new o
        do odictPut^STDCOLL(.o,"a","1")
        do odictPut^STDCOLL(.o,"b","2")
        do odictRemove^STDCOLL(.o,"a")
        do eq^STDASSERT(.pass,.fail,$$odictHas^STDCOLL(.o,"a"),0,"a removed")
        do eq^STDASSERT(.pass,.fail,$$odictSize^STDCOLL(.o),1,"size 1")
        do odictRemove^STDCOLL(.o,"never-present")
        do eq^STDASSERT(.pass,.fail,$$odictSize^STDCOLL(.o),1,"absent-remove no-op")
        quit
        ;
tOdictRemoveSkipsInIteration(pass,fail) ;@TEST "odictNext skips a removed middle key"
        new o,k,seen
        do odictPut^STDCOLL(.o,"a","1")
        do odictPut^STDCOLL(.o,"b","2")
        do odictPut^STDCOLL(.o,"c","3")
        do odictRemove^STDCOLL(.o,"b")
        set seen=""
        set k=$$odictFirst^STDCOLL(.o)
        for  quit:k=""  set seen=seen_k_"|" set k=$$odictNext^STDCOLL(.o,k)
        do eq^STDASSERT(.pass,.fail,seen,"a|c|","b skipped")
        quit
        ;
tOdictSize(pass,fail)   ;@TEST "odictSize tracks distinct keys"
        new o
        do eq^STDASSERT(.pass,.fail,$$odictSize^STDCOLL(.o),0,"empty")
        do odictPut^STDCOLL(.o,"a","1")
        do odictPut^STDCOLL(.o,"b","2")
        do eq^STDASSERT(.pass,.fail,$$odictSize^STDCOLL(.o),2,"two")
        quit
        ;
tOdictClear(pass,fail)  ;@TEST "odictClear empties the dict"
        new o
        do odictPut^STDCOLL(.o,"a","1")
        do odictPut^STDCOLL(.o,"b","2")
        do odictClear^STDCOLL(.o)
        do eq^STDASSERT(.pass,.fail,$$odictSize^STDCOLL(.o),0,"size 0")
        do eq^STDASSERT(.pass,.fail,$$odictFirst^STDCOLL(.o),"","first empty is blank")
        do eq^STDASSERT(.pass,.fail,$$odictLast^STDCOLL(.o),"","last empty is blank")
        quit
        ;
tOdictFirstLast(pass,fail)      ;@TEST "odictFirst / odictLast return ends in insertion order"
        new o
        do odictPut^STDCOLL(.o,"first","1")
        do odictPut^STDCOLL(.o,"middle","2")
        do odictPut^STDCOLL(.o,"last","3")
        do eq^STDASSERT(.pass,.fail,$$odictFirst^STDCOLL(.o),"first","first")
        do eq^STDASSERT(.pass,.fail,$$odictLast^STDCOLL(.o),"last","last")
        quit
        ;
tOdictNextPrev(pass,fail)       ;@TEST "odictPrev walks insertion order in reverse"
        new o,k,seen
        do odictPut^STDCOLL(.o,"a","1")
        do odictPut^STDCOLL(.o,"b","2")
        do odictPut^STDCOLL(.o,"c","3")
        set seen=""
        set k=$$odictLast^STDCOLL(.o)
        for  quit:k=""  set seen=seen_k_"|" set k=$$odictPrev^STDCOLL(.o,k)
        do eq^STDASSERT(.pass,.fail,seen,"c|b|a|","reverse insertion walk")
        do eq^STDASSERT(.pass,.fail,$$odictNext^STDCOLL(.o,"a"),"b","forward step")
        do eq^STDASSERT(.pass,.fail,$$odictPrev^STDCOLL(.o,"b"),"a","backward step")
        quit
        ;
