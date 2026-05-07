STDCACHETST     ; Test suite for STDCACHE (v0.2.x — Phase 4).
        ; m-lint: disable-file=M-MOD-020
        ; Test labels delegate counters by-ref to STDASSERT helpers; m-cli's
        ; by-ref analyzer can't see writes-via-callee.
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tNewEmptyCache(.pass,.fail)
        do tNewWithCapacity(.pass,.fail)
        do tPutThenGet(.pass,.fail)
        do tGetOfMissingReturnsEmpty(.pass,.fail)
        do tHasPredicate(.pass,.fail)
        do tSizeTracksPuts(.pass,.fail)
        do tPutOverwriteKeepsSize(.pass,.fail)
        do tRemoveDeletesEntry(.pass,.fail)
        do tRemoveOfMissingIsNoOp(.pass,.fail)
        do tClearEmptiesCache(.pass,.fail)
        do tCapacityZeroIsUnlimited(.pass,.fail)
        do tLruEvictsOldestAtCapacity(.pass,.fail)
        do tLruAccessTouchesRecency(.pass,.fail)
        do tLruWriteUpdatesRecency(.pass,.fail)
        do tTtlZeroNeverExpires(.pass,.fail)
        do tTtlExpiredEntryAbsent(.pass,.fail)
        do tTtlSizeReflectsExpiry(.pass,.fail)
        do tTtlAndLruInteract(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
        ; ---- new / size / capacity ----
tNewEmptyCache(pass,fail)       ;@TEST "new() with default args yields an empty unbounded cache"
        new cache
        do new^STDCACHE(.cache)
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),0,"size=0")
        do eq^STDASSERT(.pass,.fail,$$capacity^STDCACHE(.cache),0,"capacity=0 (unlimited)")
        quit
        ;
tNewWithCapacity(pass,fail)     ;@TEST "new(.cache, 16) sets capacity=16"
        new cache
        do new^STDCACHE(.cache,16)
        do eq^STDASSERT(.pass,.fail,$$capacity^STDCACHE(.cache),16,"capacity=16")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),0,"size still 0")
        quit
        ;
        ; ---- put / get / has ----
tPutThenGet(pass,fail)  ;@TEST "put followed by get round-trips the value"
        new cache
        do new^STDCACHE(.cache)
        do put^STDCACHE(.cache,"k","v")
        do eq^STDASSERT(.pass,.fail,$$get^STDCACHE(.cache,"k"),"v","get(k)=v")
        do put^STDCACHE(.cache,"n",42)
        do eq^STDASSERT(.pass,.fail,$$get^STDCACHE(.cache,"n"),42,"get(n)=42")
        quit
        ;
tGetOfMissingReturnsEmpty(pass,fail)    ;@TEST "get() of an absent key returns ''"
        new cache
        do new^STDCACHE(.cache)
        do eq^STDASSERT(.pass,.fail,$$get^STDCACHE(.cache,"missing"),"","missing returns ''")
        quit
        ;
tHasPredicate(pass,fail)        ;@TEST "has() distinguishes present from absent"
        new cache
        do new^STDCACHE(.cache)
        do put^STDCACHE(.cache,"k","v")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"k"),"has(k)=1")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"missing"),"has(missing)=0")
        quit
        ;
        ; ---- size tracking ----
tSizeTracksPuts(pass,fail)      ;@TEST "size() increments with each new key"
        new cache
        do new^STDCACHE(.cache)
        do put^STDCACHE(.cache,"a","1")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),1,"size=1")
        do put^STDCACHE(.cache,"b","2")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),2,"size=2")
        do put^STDCACHE(.cache,"c","3")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),3,"size=3")
        quit
        ;
tPutOverwriteKeepsSize(pass,fail)       ;@TEST "put on existing key updates value, leaves size"
        new cache
        do new^STDCACHE(.cache)
        do put^STDCACHE(.cache,"k","old")
        do put^STDCACHE(.cache,"k","new")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),1,"size still 1")
        do eq^STDASSERT(.pass,.fail,$$get^STDCACHE(.cache,"k"),"new","value updated")
        quit
        ;
        ; ---- remove / clear ----
tRemoveDeletesEntry(pass,fail)  ;@TEST "remove() deletes the entry; size drops"
        new cache
        do new^STDCACHE(.cache)
        do put^STDCACHE(.cache,"k","v")
        do remove^STDCACHE(.cache,"k")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"k"),"absent after remove")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),0,"size=0")
        quit
        ;
tRemoveOfMissingIsNoOp(pass,fail)       ;@TEST "remove() of an absent key is a no-op"
        new cache
        do new^STDCACHE(.cache)
        do put^STDCACHE(.cache,"k","v")
        do remove^STDCACHE(.cache,"never-set")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),1,"size unchanged")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"k"),"k still present")
        quit
        ;
tClearEmptiesCache(pass,fail)   ;@TEST "clear() drops all entries; capacity preserved"
        new cache
        do new^STDCACHE(.cache,8)
        do put^STDCACHE(.cache,"a","1")
        do put^STDCACHE(.cache,"b","2")
        do clear^STDCACHE(.cache)
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),0,"size=0 after clear")
        do eq^STDASSERT(.pass,.fail,$$capacity^STDCACHE(.cache),8,"capacity preserved")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"a"),"a gone")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"b"),"b gone")
        quit
        ;
        ; ---- LRU eviction ----
tCapacityZeroIsUnlimited(pass,fail)     ;@TEST "capacity=0 means unlimited; no eviction"
        new cache,i
        do new^STDCACHE(.cache,0)
        for i=1:1:50  do put^STDCACHE(.cache,"k"_i,i)
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),50,"size=50, no eviction")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"k1"),"oldest still present")
        quit
        ;
tLruEvictsOldestAtCapacity(pass,fail)   ;@TEST "at capacity, the oldest entry is evicted"
        new cache
        do new^STDCACHE(.cache,3)
        do put^STDCACHE(.cache,"a","1")
        do put^STDCACHE(.cache,"b","2")
        do put^STDCACHE(.cache,"c","3")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),3,"size=3")
        do put^STDCACHE(.cache,"d","4")  ; should evict "a"
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),3,"size still 3")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"a"),"a evicted")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"b"),"b still present")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"c"),"c still present")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"d"),"d present")
        quit
        ;
tLruAccessTouchesRecency(pass,fail)     ;@TEST "get() promotes the key to most-recent"
        new cache,unused
        do new^STDCACHE(.cache,3)
        do put^STDCACHE(.cache,"a","1")
        do put^STDCACHE(.cache,"b","2")
        do put^STDCACHE(.cache,"c","3")
        ; touch "a" so it's most-recent
        set unused=$$get^STDCACHE(.cache,"a")
        ; insert "d" — least-recent is now "b", not "a"
        do put^STDCACHE(.cache,"d","4")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"a"),"a saved by touch")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"b"),"b evicted")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"c"),"c still present")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"d"),"d present")
        quit
        ;
tLruWriteUpdatesRecency(pass,fail)      ;@TEST "put() on existing key promotes it to most-recent"
        new cache
        do new^STDCACHE(.cache,3)
        do put^STDCACHE(.cache,"a","1")
        do put^STDCACHE(.cache,"b","2")
        do put^STDCACHE(.cache,"c","3")
        ; rewrite "a"
        do put^STDCACHE(.cache,"a","1+")
        ; insert "d" — least-recent is now "b"
        do put^STDCACHE(.cache,"d","4")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"a"),"a saved by rewrite")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"b"),"b evicted")
        do eq^STDASSERT(.pass,.fail,$$get^STDCACHE(.cache,"a"),"1+","a has new value")
        quit
        ;
        ; ---- TTL ----
tTtlZeroNeverExpires(pass,fail) ;@TEST "ttl=0 entries do not expire"
        new cache
        do new^STDCACHE(.cache,0,0)
        do put^STDCACHE(.cache,"k","v")
        hang 1
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"k"),"still present after 1s")
        do eq^STDASSERT(.pass,.fail,$$get^STDCACHE(.cache,"k"),"v","value preserved")
        quit
        ;
tTtlExpiredEntryAbsent(pass,fail)       ;@TEST "ttl=1 entry is absent after the TTL elapses"
        new cache
        do new^STDCACHE(.cache,0,1)  ; capacity=unlimited, TTL=1s
        do put^STDCACHE(.cache,"k","v")
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"k"),"present immediately")
        hang 2
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"k"),"absent after 2s")
        do eq^STDASSERT(.pass,.fail,$$get^STDCACHE(.cache,"k"),"","get returns '' after TTL")
        quit
        ;
tTtlSizeReflectsExpiry(pass,fail)       ;@TEST "size() decrements as expired entries are accessed"
        new cache,unused
        do new^STDCACHE(.cache,0,1)
        do put^STDCACHE(.cache,"a","1")
        do put^STDCACHE(.cache,"b","2")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),2,"size=2 immediately")
        hang 2
        ; Expired entries are reaped lazily on access; touch them to force.
        set unused=$$has^STDCACHE(.cache,"a")
        set unused=$$has^STDCACHE(.cache,"b")
        do eq^STDASSERT(.pass,.fail,$$size^STDCACHE(.cache),0,"size=0 after lazy reap")
        quit
        ;
tTtlAndLruInteract(pass,fail)   ;@TEST "expired entries no longer count against capacity"
        new cache
        do new^STDCACHE(.cache,3,1)  ; capacity=3, TTL=1s
        do put^STDCACHE(.cache,"a","1")
        do put^STDCACHE(.cache,"b","2")
        do put^STDCACHE(.cache,"c","3")
        hang 2  ; everything expires
        do put^STDCACHE(.cache,"d","4")
        ; "d" is fresh; "a"/"b"/"c" are expired and lazily reaped on next access
        do true^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"d"),"d present")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"a"),"a expired")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"b"),"b expired")
        do false^STDASSERT(.pass,.fail,$$has^STDCACHE(.cache,"c"),"c expired")
        quit
