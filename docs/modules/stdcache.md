---
module: STDCACHE
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'LRU + TTL cache over a caller-owned local array'
labels: ['capacity', 'clear', 'get', 'has', 'new', 'put', 'remove', 'size']
errors: []
conformance: []
see_also: []
---

# `STDCACHE` — LRU + TTL cache

A small, caller-owned cache: bounded by capacity (LRU eviction)
and / or wall-clock TTL (lazy reap on access). The cache lives in
a local-array tree the caller owns; you pass it by reference into
every operation. No globals, no per-process singletons — perfect
for memoisation, RPC-result caching, and rate-limit windows.

## Public API

| Extrinsic | Signature | Action / Returns |
|---|---|---|
| `new` | `do new^STDCACHE(.cache, capacity?, ttl?)` | Initialise / wipe; defaults `capacity=0` (unlimited), `ttl=0` (no expiry). |
| `put` | `do put^STDCACHE(.cache, key, value)` | Insert / update; promotes the key to most-recent; may evict. |
| `get` | `$$get^STDCACHE(.cache, key)` | Fetch the value; `""` if absent or expired; touches recency. |
| `has` | `$$has^STDCACHE(.cache, key)` | `1` iff present and not expired; reaps expired entries inline. |
| `remove` | `do remove^STDCACHE(.cache, key)` | Delete one entry; idempotent. |
| `clear` | `do clear^STDCACHE(.cache)` | Drop all entries; preserves `capacity` / `ttl`. |
| `size` | `$$size^STDCACHE(.cache)` | Current entry count. |
| `capacity` | `$$capacity^STDCACHE(.cache)` | Declared capacity (`0` = unlimited). |

## Examples

```m
; bounded LRU cache for memoisation
NEW lookup
DO new^STDCACHE(.lookup,128)
DO put^STDCACHE(.lookup,"foo","resolved-foo")
DO put^STDCACHE(.lookup,"bar","resolved-bar")
WRITE $$get^STDCACHE(.lookup,"foo"),!     ; "resolved-foo"

; TTL-only cache (no capacity bound, 5-minute expiry)
NEW sessions
DO new^STDCACHE(.sessions,0,300)
DO put^STDCACHE(.sessions,token,userId)
; ...300 seconds pass...
WRITE $$has^STDCACHE(.sessions,token),!   ; 0  (auto-expired on access)

; combined LRU + TTL — bounded *and* time-limited
NEW rpcCache
DO new^STDCACHE(.rpcCache,256,60)
DO put^STDCACHE(.rpcCache,callId,response)
```

## Semantics

### LRU

When `capacity > 0` and `size > capacity`, `put` evicts the
**least-recently-touched** entry. "Touched" means accessed by
`get` or rewritten by `put`. A `has` probe does **not** touch
recency — it's a true predicate.

### TTL

When `ttl > 0`, every `put` stamps an expiry of `now + ttl`
seconds. `get` and `has` check the expiry before returning;
expired entries are reaped **lazily, inline** — no background
sweeper. The cache's `size` decrements when an expired entry is
touched.

The reaper does not walk the whole cache on every access: only
the specific key being looked up is checked. This keeps the
cost of the cache predictable (O(log N) per access via M's
`$ORDER` over the recency map). If you need an explicit "drop
all expired entries now" operation, a future `prune^STDCACHE`
extrinsic will land alongside the STDCOLL rebase (T19).

### Time source

`$HOROLOG` (M's standard `"DDDDD,SSSSS"` format), collapsed to
seconds since 1840-12-31. ANSI-standard, no `$Z*` extensions —
runs unchanged on YDB and IRIS.

## Tree shape

The cache lives entirely in the caller's array. A typical post-
populate snapshot:

```
cache("cap")     = 128             ; declared capacity
cache("ttl")     = 60              ; TTL seconds (0 = none)
cache("size")    = 3               ; current entry count
cache("seq")    = 42               ; monotonic counter (recency)

cache("v","foo")     = "..."       ; value
cache("ts","foo")    = 40          ; recency: this key's seq
cache("o",40)        = "foo"       ; reverse map for LRU eviction

cache("v","bar")     = "..."
cache("ts","bar")    = 41
cache("o",41)        = "bar"

cache("v","baz")     = "..."
cache("ts","baz")    = 42
cache("o",42)        = "baz"

cache("ex","foo")    = 5781234567  ; expiry epoch (only when ttl>0)
cache("ex","bar")    = 5781234567
cache("ex","baz")    = 5781234567
```

The caller owns this tree. Multiple caches in one process are
independent caller-array variables — no globals, no shared state.

## Edge cases

- **`new()` is idempotent.** Calling it on a populated cache
  wipes everything (including the previously-stored values).
- **`capacity = 0`** means unlimited. `put` never evicts.
- **`ttl = 0`** means no expiry. Entries persist until they're
  evicted by LRU or explicitly `remove`d.
- **`get` of an expired key returns `""`,** indistinguishable
  from an absent key. Use `has` first if you need to disambiguate
  before the inline reap.
- **`put` of an existing key is an update, not an insert.** It
  refreshes the value, the recency, and the expiry; `size` does
  not change.
- **`remove` of an absent key is a no-op.** Matches the
  unlink-with-`ENOENT-suppression` semantics throughout the rest
  of the stdlib.
- **`has` does not touch recency.** It's a clean predicate. Use
  `get` if you want both fetch and recency promotion.
- **Coercion of stored values.** Whatever you put in is what you
  get out — `put(.cache,"k",1)` returns `1` from `get`, not
  `"1"`. Numeric-vs-string distinction is preserved.

## Performance

| Operation | Cost |
|---|---|
| `put` (no eviction) | O(log N) for the `$ORDER` lookup of the prior recency entry |
| `put` triggering eviction | O(K log N), where K is the number of entries to evict |
| `get` | O(log N) |
| `has` | O(log N) (one `$DATA` + optional `$HOROLOG`) |
| `remove` | O(log N) |
| `clear` | O(N) (kills the whole subtree) |
| `size` / `capacity` | O(1) |

For the typical "memoise the last 1000 results" use case, this is
indistinguishable from in-process struct-based caches in
faster-clock languages — M's tree operations are cheap.

## Engine portability

Pure-M throughout. `$HOROLOG`, `$ORDER`, `$DATA`, `$GET` —
ANSI-standard. Runs unchanged on YDB and IRIS. The test suite
(48 assertions across 18 labels) is the conformance gate.

## See also

- [`STDCOLL`](stdcoll.md) — provides Map and OrderedDict over
  caller-owned arrays. STDCACHE could rebase onto STDCOLL's
  OrderedDict in a future cleanup pass (T19); v1 inlines the
  bookkeeping for self-containment and to avoid the runtime dep.
- [`STDDATE`](stddate.md) — STDCACHE's TTL clock could use
  STDDATE's `now`/`add` if datetime arithmetic became more
  involved; v1 stays on `$HOROLOG` directly because seconds
  arithmetic is trivial.

## History

LRU + TTL cache over caller-owned local-array tree; no globals,
multiple caches per process are independent. LRU uses two-way
`seq ↔ key` maps for O(log N) eviction; TTL reaping is **lazy on
access** (no background sweeper). Time source `$HOROLOG` collapsed
to seconds. Pure-M, no `$Z*`. STDCOLL listed as soft dep but inlined
in v1 for self-containment.

**Optional add-on (T19, deferred):** rebase onto STDCOLL OrderedDict
+ explicit `prune()` for batch expired-entry sweeps. Activates if a
real consumer needs the streaming-percentile or batch-prune surface.
