STDCACHE        ; m-stdlib — LRU + TTL cache over a caller-owned local array.
        ;
        ; Public extrinsics:
        ;   new^STDCACHE(.cache, capacity?, ttl?)  — initialise; cap=0 unlimited, ttl=0 no expiry
        ;   put^STDCACHE(.cache, key, value)       — insert/update; touches recency
        ;   $$get^STDCACHE(.cache, key)            — fetch; "" if absent or expired; touches recency
        ;   $$has^STDCACHE(.cache, key)            — predicate; expired keys are lazily reaped
        ;   remove^STDCACHE(.cache, key)           — delete one entry; idempotent
        ;   clear^STDCACHE(.cache)                 — drop all entries; capacity/ttl preserved
        ;   $$size^STDCACHE(.cache)                — current entry count
        ;   $$capacity^STDCACHE(.cache)            — declared capacity (0 = unlimited)
        ;
        ; Tree shape (caller-owned; pass by reference):
        ;   cache("cap")        — capacity (0 = unlimited)
        ;   cache("ttl")        — TTL seconds (0 = no expiry)
        ;   cache("size")       — current entry count
        ;   cache("seq")        — monotonic counter for recency tracking
        ;   cache("v",key)      — stored value
        ;   cache("ts",key)     — recency: this key's seq number
        ;   cache("o",seq)      — reverse map: seq → key (for LRU eviction lookup)
        ;   cache("ex",key)     — expiry seconds-since-1840-epoch (only when ttl>0)
        ;
        ; LRU eviction: the smallest seq in cache("o",...) is the least-recently-
        ; touched key. On capacity overflow, $ORDER picks it off in O(1) per evict.
        ; Recency touch: on get/put, kill the old (seq → key) entry, bump seq, write
        ; the new (seq → key) entry, update cache("ts",key).
        ;
        ; TTL eviction: lazy. has() and get() check cache("ex",key) before returning;
        ; if expired, remove() is invoked inline. size() is decremented at that point.
        ; A get() of an expired key returns "" exactly like an absent key.
        ;
        ; Time source: M's $H = "DDDDD,SSSSS" (ANSI standard). nowSec() collapses
        ; this to seconds since 1840-12-31. No `$Z*` extensions; runs unchanged on
        ; YDB and IRIS.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
new(cache,capacity,ttl) ; Initialise cache with optional capacity / TTL.
        ; doc: @param cache       array  by-ref local; killed then populated
        ; doc: @param capacity    int    max entries; 0 = unlimited (default 0)
        ; doc: @param ttl         int    TTL in seconds; 0 = no expiry (default 0)
        ; doc: @example           do new^STDCACHE(.cfg,128,300)  ; 128 entries, 5-minute TTL
        ; doc: @since             v0.3.0
        ; doc: @stable            stable
        ; doc: @see               do put^STDCACHE, do clear^STDCACHE
        ; doc: Idempotent — calling new() on an existing cache wipes it.
        kill cache
        set cache("cap")=$get(capacity,0)
        set cache("ttl")=$get(ttl,0)
        set cache("size")=0
        set cache("seq")=0
        quit
        ;
put(cache,key,value)    ; Insert / update. Promotes the key to most-recent. May evict.
        ; doc: @param cache   array   by-ref local from new^STDCACHE
        ; doc: @param key     string  cache key
        ; doc: @param value   string  value to store
        ; doc: @example       do put^STDCACHE(.cfg,"hostname","example.org")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$get^STDCACHE, do remove^STDCACHE
        new now,seq,oldSeq
        ; If the key already exists, this is an update — drop its old recency entry.
        if $data(cache("v",key)) do
        . set oldSeq=cache("ts",key)
        . kill cache("o",oldSeq)
        else  set cache("size")=cache("size")+1
        ; Bump the global seq and record the new (seq → key) entry.
        set seq=cache("seq")+1
        set cache("seq")=seq
        set cache("v",key)=value
        set cache("ts",key)=seq
        set cache("o",seq)=key
        ; Stamp expiry if TTL is enabled.
        if cache("ttl")>0 do
        . set now=$$nowSec()
        . set cache("ex",key)=now+cache("ttl")
        ; Evict the oldest entry while over capacity.
        if cache("cap")>0 do evictWhileOver(.cache)
        quit
        ;
get(cache,key)  ; Return the cached value, or "" if absent / expired. Touches recency.
        ; doc: @param cache   array   by-ref local from new^STDCACHE
        ; doc: @param key     string  cache key
        ; doc: @returns       string  the stored value; "" if absent or expired
        ; doc: @example       write $$get^STDCACHE(.cfg,"hostname")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$has^STDCACHE, do put^STDCACHE
        ; doc: Expired entries are reaped inline before the lookup returns.
        if '$$has(.cache,key) quit ""
        new seq,oldSeq
        ; Bump recency.
        set oldSeq=cache("ts",key)
        kill cache("o",oldSeq)
        set seq=cache("seq")+1
        set cache("seq")=seq
        set cache("ts",key)=seq
        set cache("o",seq)=key
        quit cache("v",key)
        ;
has(cache,key)  ; Return 1 iff key is present and not expired; reap if expired.
        ; doc: @param cache   array   by-ref local from new^STDCACHE
        ; doc: @param key     string  cache key
        ; doc: @returns       bool    1 iff present and not expired; 0 otherwise
        ; doc: @example       if $$has^STDCACHE(.cfg,"hostname") ...
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$get^STDCACHE
        if '$data(cache("v",key)) quit 0
        if cache("ttl")>0,$$nowSec()'<cache("ex",key) do remove(.cache,key) quit 0
        quit 1
        ;
remove(cache,key)       ; Delete one entry. Idempotent — no-op if key is absent.
        ; doc: @param cache   array   by-ref local from new^STDCACHE
        ; doc: @param key     string  cache key
        ; doc: @example       do remove^STDCACHE(.cfg,"stale-token")
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           do clear^STDCACHE
        new oldSeq
        if '$data(cache("v",key)) quit
        set oldSeq=cache("ts",key)
        kill cache("o",oldSeq)
        kill cache("v",key)
        kill cache("ts",key)
        if $data(cache("ex",key)) kill cache("ex",key)
        set cache("size")=cache("size")-1
        quit
        ;
clear(cache)    ; Drop every entry; preserve capacity / TTL settings.
        ; doc: @param cache   array   by-ref local from new^STDCACHE
        ; doc: @example       do clear^STDCACHE(.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           do new^STDCACHE, do remove^STDCACHE
        kill cache("v"),cache("ts"),cache("o"),cache("ex")
        set cache("size")=0
        set cache("seq")=0
        quit
        ;
size(cache)     ; Return the current entry count.
        ; doc: @param cache   array   by-ref local from new^STDCACHE
        ; doc: @returns       int     current entry count
        ; doc: @example       write $$size^STDCACHE(.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$capacity^STDCACHE
        ; doc: Reflects entries actually in the cache; expired entries that have
        ; doc: not yet been touched are still counted until lazily reaped.
        quit $get(cache("size"),0)
        ;
capacity(cache) ; Return the declared capacity (0 = unlimited).
        ; doc: @param cache   array   by-ref local from new^STDCACHE
        ; doc: @returns       int     declared capacity (0 = unlimited)
        ; doc: @example       write $$capacity^STDCACHE(.cfg)
        ; doc: @since         v0.3.0
        ; doc: @stable        stable
        ; doc: @see           $$size^STDCACHE
        quit $get(cache("cap"),0)
        ;
        ; ---------- internal helpers ----------
        ;
nowSec()        ; Return seconds since the M epoch (1840-12-31).
        ; doc: @internal
        ; doc: Drives TTL stamping and expiry checks. M $H is "DDDDD,SSSSS";
        ; doc: we collapse to a single integer.
        new h
        set h=$horolog
        quit $piece(h,",",1)*86400+$piece(h,",",2)
        ;
evictWhileOver(cache)   ; Pop oldest entries until size <= capacity.
        ; doc: @internal
        ; doc: Driven by put() when capacity is finite. Picks the smallest
        ; doc: seq in cache("o",...), maps to a key, removes it.
        new oldestSeq,oldestKey
        set oldestKey=""
        for  quit:cache("size")'>cache("cap")  do  quit:oldestKey=""
        . set oldestSeq=$order(cache("o",""))
        . if oldestSeq="" set oldestKey="" quit
        . set oldestKey=cache("o",oldestSeq)
        . do remove(.cache,oldestKey)
        quit
