# `STDPROF` — Wall-clock profiler

A small, caller-owned profiler: per-tag start/stop timers,
aggregate count / total / mean / min / max, and percentiles
computed from a sorted-by-value sample tree. Drop into any code
path you want to instrument; pass the profiler array by reference;
inspect on demand.

## Public API

| Extrinsic | Signature | Action / Returns |
|---|---|---|
| `new` | `do new^STDPROF(.prof)` | Initialise / wipe. |
| `start` | `do start^STDPROF(.prof, tag)` | Open a timer for tag. No-op if already active. |
| `stop` | `do stop^STDPROF(.prof, tag)` | Close the timer; record one sample. No-op if no matching start. |
| `count` | `$$count^STDPROF(.prof, tag)` | Completed cycles for tag; `0` if untracked. |
| `total` | `$$total^STDPROF(.prof, tag)` | Sum of elapsed microseconds. |
| `mean` | `$$mean^STDPROF(.prof, tag)` | `total \ count` (integer floor). |
| `min` | `$$min^STDPROF(.prof, tag)` | Fastest sample. |
| `max` | `$$max^STDPROF(.prof, tag)` | Slowest sample. |
| `percentile` | `$$percentile^STDPROF(.prof, tag, p)` | p-th percentile sample (`0..100`). |
| `tags` | `$$tags^STDPROF(.prof, .out)` | Populates `out(1..N)` with tag names; returns N. |
| `clear` | `do clear^STDPROF(.prof)` | Drop everything (alias for `new`). |

## Examples

```m
NEW prof
DO new^STDPROF(.prof)

; Time a database call
DO start^STDPROF(.prof,"db.query")
DO ^DBCALL
DO stop^STDPROF(.prof,"db.query")

; Aggregate after many calls
WRITE "count: ",$$count^STDPROF(.prof,"db.query"),!
WRITE "mean:  ",$$mean^STDPROF(.prof,"db.query")," us",!
WRITE "p50:   ",$$percentile^STDPROF(.prof,"db.query",50)," us",!
WRITE "p95:   ",$$percentile^STDPROF(.prof,"db.query",95)," us",!
WRITE "p99:   ",$$percentile^STDPROF(.prof,"db.query",99)," us",!
WRITE "max:   ",$$max^STDPROF(.prof,"db.query")," us",!

; Enumerate tracked tags
DO  SET n=$$tags^STDPROF(.prof,.tags)
FOR i=1:1:n  WRITE tags(i)," ",$$count^STDPROF(.prof,tags(i)),!
```

## Time source

`$ZHOROLOG = "DDDDD,SSSSS,US,TZ"` — days since 1840-12-31, seconds
into day, **microseconds into second**, and timezone offset.
`nowMicros()` collapses this into a single integer microsecond
count; `stop` subtracts the start-time stamp to get elapsed.

The underlying clock resolution depends on the host:

| Environment | Typical resolution |
|---|---|
| Bare-metal Linux | ~1–10 µs |
| Container hosts | ~100–1000 µs |
| Virtualised guests | ~1 ms |

Samples below the host's resolution are recorded as `0` µs.
Aggregates are unaffected; percentiles still rank correctly.

## Tree shape

The profiler lives entirely in the caller's array. A typical
post-population snapshot for one tag:

```
prof("count","db.query")               = 4203
prof("total","db.query")               = 8412345
prof("min","db.query")                 = 412
prof("max","db.query")                 = 18234
prof("seq","db.query")                 = 4203
prof("samples","db.query",412,1)       = ""
prof("samples","db.query",412,2)       = ""
prof("samples","db.query",413,3)       = ""
...
prof("samples","db.query",18234,4203)  = ""
```

Multiple tags share the top-level subscripts; samples are
interleaved by tag at the second subscript. `prof("active",tag)`
holds the start-time stamp while a cycle is in progress and is
killed on `stop`.

## Percentile semantics

**Nearest-rank** computation. For N samples and percentile p:

```
target = ceil(p * N / 100)        (1-based index into sorted samples)
```

- `p=0` returns `min` (fast path; no walk).
- `p=100` returns `max` (fast path; no walk).
- Intermediate values walk `prof("samples", tag, value, seq)` in
  natural numeric `$ORDER` until the cumulative count reaches
  `target`, returning the value at that position.

Ties (multiple samples with the same elapsed) are resolved by the
seq subscript — the order doesn't matter for percentile lookup,
since they all share the same value.

The walk is `O(N)` worst case but typically much less because
percentile lookups are clustered near the tail. For one-shot
reports (call `percentile` once per tag at the end of a run), the
cost is negligible. A streaming-percentile variant (CKMS sketch
backed by `STDCOLL` Heap) was reserved under T20 and closed 2026-
05-07 as won't-fix-without-consumer-driver — the only caller
today, m-cli `--timings`, is a one-shot end-of-run report, exactly
the case the v1 walk is sized for. If a continuous-monitoring
caller emerges that calls `percentile` inside a hot path, T20 can
be reopened and implemented behind a `newStreaming^STDPROF(.prof,
epsilon)` constructor without disturbing the v1 surface.

## Edge cases

- **`stop()` without a matching `start()` is a no-op.** `count`
  stays at zero; no sample is recorded.
- **`start()` on an already-active tag is a no-op.** The original
  start time is preserved. This matches the convention that you
  can't "double-start" a single timer; if you need nested timing,
  use distinct tags.
- **Negative elapsed (clock skew).** If `$ZHOROLOG` reports an
  earlier time on `stop` than on `start` — typically only possible
  during a clock adjustment — the elapsed is clamped to `0` rather
  than recorded as a negative sample.
- **`count` / `total` / `min` / `max` of an untracked tag** all
  return `0`.
- **`percentile` of an untracked tag** returns `0`.
- **`tags()` walks `prof("count", ...)`** in `$ORDER` — alphabetical
  for plain string tags, numeric for numeric tags. The walk does
  not include in-progress timers (those have a `prof("active", tag)`
  entry but no `prof("count", tag)` until the first `stop`).

## Engine portability

`$ZHOROLOG` is a YDB extension (also IRIS-supported); listed in
the file-wide `M-MOD-022` directive at the top of the source. The
ANSI-standard `$HOROLOG` is too coarse (1-second resolution) to be
useful for profiling. An IRIS-compatible time source via
`$ZTIMESTAMP` is queued alongside STDDATE's IRIS pass. The rest
of the module — `$ORDER`, `$DATA`, `$GET`, integer arithmetic — is
ANSI-standard.

## See also

- [`STDDATE`](stddate.md) — same `$ZHOROLOG` precedent; STDDATE
  has the canonical wall-clock helpers but at second / millisecond
  resolution.
- [`STDCOLL`](stdcoll.md) — provides Heap; was reserved as the
  backing for a T20 streaming-percentile variant. T20 closed 2026-
  05-07 as won't-fix-without-consumer-driver; the soft dep is no
  longer load-bearing for STDPROF v1.
- [`STDCACHE`](stdcache.md) — same caller-owned array convention;
  multiple profilers in one process are independent variables.
