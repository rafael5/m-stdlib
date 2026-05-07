STDPROF ; m-stdlib — Wall-clock profiler with per-tag aggregates + percentiles.
        ; m-lint: disable-file=M-MOD-022
        ; M-MOD-022: STDPROF uses $ZHOROLOG for microsecond-resolution timing
        ; ($HOROLOG is only second-resolution — too coarse for profiling).
        ; $ZHOROLOG is YDB extension, also supported by IRIS — listed in
        ; STDDATE's precedent. v0.2.x ships YDB-first; IRIS arm tracks the
        ; $ZTIMESTAMP equivalent under STDDATE's IRIS pass.
        ;
        ; Public extrinsics:
        ;   new^STDPROF(.prof)                — initialise empty profiler
        ;   start^STDPROF(.prof, tag)         — open a timer for tag
        ;   stop^STDPROF(.prof, tag)          — close the timer; record sample
        ;   $$count^STDPROF(.prof, tag)       — completed cycles
        ;   $$total^STDPROF(.prof, tag)       — sum of elapsed (microseconds)
        ;   $$mean^STDPROF(.prof, tag)        — total / count (integer floor)
        ;   $$min^STDPROF(.prof, tag)         — fastest sample
        ;   $$max^STDPROF(.prof, tag)         — slowest sample
        ;   $$percentile^STDPROF(.prof, tag, p) — p-th percentile (0..100)
        ;   $$tags^STDPROF(.prof, .out)       — populate out(1..N) with tag names
        ;   clear^STDPROF(.prof)              — drop every tag's data
        ;
        ; Tree shape (caller-owned; pass by reference):
        ;   prof("active",tag)               — start time of an in-progress cycle
        ;   prof("count",tag)                — completed cycles
        ;   prof("total",tag)                — sum of elapsed microseconds
        ;   prof("min",tag)                  — fastest sample
        ;   prof("max",tag)                  — slowest sample
        ;   prof("samples",tag,value,seq)=""  — per-sample, sorted by value
        ;
        ; Time source: $ZHOROLOG = "DDDDD,SSSSS,US,TZ" (days, seconds, microseconds,
        ; timezone). nowMicros() collapses to a single integer microsecond count
        ; since the M epoch (1840-12-31). Sample resolution is microseconds; the
        ; underlying system clock typically delivers ~1ms granularity on
        ; container hosts and ~10us on bare metal.
        ;
        quit
        ;
        ; ---------- public API ----------
        ;
new(prof)       ; Initialise / wipe the profiler.
        ; doc: Idempotent — calling new() on a populated profiler clears it.
        ; doc: Example: do new^STDPROF(.p)
        kill prof
        quit
        ;
start(prof,tag) ; Open a timer for tag. Stamps prof("active",tag) with $ZHOROLOG.
        ; doc: Calling start() while a timer is already active is a no-op
        ; doc: (the existing start time is preserved).
        ; doc: Example: do start^STDPROF(.p,"db.query")
        if $data(prof("active",tag)) quit
        set prof("active",tag)=$$nowMicros()
        quit
        ;
stop(prof,tag)  ; Close the timer; record one sample. No-op if no matching start.
        ; doc: Example: do stop^STDPROF(.p,"db.query")
        new now,startedAt,elapsed,seq
        if '$data(prof("active",tag)) quit
        set now=$$nowMicros()
        set startedAt=prof("active",tag)
        set elapsed=now-startedAt
        if elapsed<0 set elapsed=0
        kill prof("active",tag)
        ; Update aggregates.
        set prof("count",tag)=$get(prof("count",tag),0)+1
        set prof("total",tag)=$get(prof("total",tag),0)+elapsed
        if '$data(prof("min",tag))!(elapsed<prof("min",tag)) set prof("min",tag)=elapsed
        if '$data(prof("max",tag))!(elapsed>prof("max",tag)) set prof("max",tag)=elapsed
        ; Append sample for percentile lookup; seq disambiguates duplicates.
        set seq=$get(prof("seq",tag),0)+1
        set prof("seq",tag)=seq
        set prof("samples",tag,elapsed,seq)=""
        quit
        ;
count(prof,tag) ; Return number of completed cycles for tag; 0 if untracked.
        ; doc: Example: write $$count^STDPROF(.p,"db.query")
        quit $get(prof("count",tag),0)
        ;
total(prof,tag) ; Return sum of elapsed microseconds across all cycles; 0 if untracked.
        ; doc: Example: write $$total^STDPROF(.p,"db.query")
        quit $get(prof("total",tag),0)
        ;
mean(prof,tag)  ; Return total\count (integer floor); 0 if no cycles.
        ; doc: Example: write $$mean^STDPROF(.p,"db.query")
        new c
        set c=$$count(.prof,tag)
        if c=0 quit 0
        quit $$total(.prof,tag)\c
        ;
min(prof,tag)   ; Return fastest sample; 0 if no cycles.
        ; doc: Example: write $$min^STDPROF(.p,"db.query")
        quit $get(prof("min",tag),0)
        ;
max(prof,tag)   ; Return slowest sample; 0 if no cycles.
        ; doc: Example: write $$max^STDPROF(.p,"db.query")
        quit $get(prof("max",tag),0)
        ;
percentile(prof,tag,p)  ; Return the p-th percentile sample (0..100).
        ; doc: p=0 returns min; p=100 returns max; intermediate values use
        ; doc: nearest-rank: ceil(p*N/100) into the sorted samples (1-based).
        ; doc: Example: write $$percentile^STDPROF(.p,"db.query",95)
        new n,target,seen,value,seq,foundValue
        set n=$$count(.prof,tag)
        if n=0 quit 0
        if p'>0 quit $$min(.prof,tag)
        if p'<100 quit $$max(.prof,tag)
        set target=p*n\100
        if (p*n)#100>0 set target=target+1
        if target<1 set target=1
        if target>n set target=n
        set foundValue="",seen=0,value=""
        for  set value=$order(prof("samples",tag,value)) quit:value=""  do  quit:seen'<target
        . set seq=""
        . for  set seq=$order(prof("samples",tag,value,seq)) quit:seq=""  do  quit:seen'<target
        . . set seen=seen+1
        . . if seen=target set foundValue=value
        quit foundValue
        ;
tags(prof,out)  ; Populate out(1..N) with tag names that have at least one cycle.
        ; doc: Walk order is M's $ORDER (alphabetical for plain string tags).
        ; doc: Returns N as the implicit value.
        ; doc: Example: do  set n=$$tags^STDPROF(.p,.list)
        kill out
        new tag,n
        set tag="",n=0
        for  set tag=$order(prof("count",tag)) quit:tag=""  do
        . set n=n+1
        . set out(n)=tag
        quit n
        ;
clear(prof)     ; Drop every tag's data; preserves nothing.
        ; doc: Equivalent to new() — kept as a separate name so call sites
        ; doc: that read "clear" register the intent.
        ; doc: Example: do clear^STDPROF(.p)
        kill prof
        quit
        ;
        ; ---------- internal helpers ----------
        ;
nowMicros()     ; Return microseconds since the M epoch (1840-12-31).
        ; doc: Internal — drives start/stop. $ZHOROLOG = "DDDDD,SSSSS,US,TZ".
        new h,d,s,u
        set h=$zhorolog
        set d=$piece(h,",",1)
        set s=$piece(h,",",2)
        set u=$piece(h,",",3)
        if u="" set u=0
        quit (d*86400000000)+(s*1000000)+u
