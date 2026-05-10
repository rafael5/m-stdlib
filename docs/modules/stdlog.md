---
module: STDLOG
tag: v0.0.4
phase: Phase 1
stable: stable
since: v0.0.4
synopsis: 'structured key=value logger (v0.0.4)'
labels: ['DEBUG', 'ERROR', 'FATAL', 'FORMAT', 'INFO', 'LEVEL', 'SINK', 'WARN']
errors: ['U-STDLOG-INVALID-FORMAT', 'U-STDLOG-INVALID-LEVEL', 'U-STDLOG-INVALID-SINK']
conformance: []
see_also: ['STDDATE', 'STDJSON']
---

# `STDLOG` — structured key=value logger

A small, dependency-free structured logger. Emits one line per record in
the form

```
<ISO-8601 UTC ts> level=<NAME> event=<event> k=v k=v ...
```

Pure-M; timestamp source is `$$now^STDDATE()` (track L4b folded into
the v0.0.4 commit since L5 STDDATE landed first).

## Public API

| Entry | Signature | Purpose |
|---|---|---|
| `DEBUG` | `do DEBUG^STDLOG(event,k1,v1,...,k5,v5)` | Emit at level DEBUG (priority 10). Up to 5 kv pairs. |
| `INFO` | `do INFO^STDLOG(event,...)` | Emit at level INFO (priority 20). Default threshold. |
| `WARN` | `do WARN^STDLOG(event,...)` | Emit at level WARN (priority 30). |
| `ERROR` | `do ERROR^STDLOG(event,...)` | Emit at level ERROR (priority 40). |
| `FATAL` | `do FATAL^STDLOG(event,...)` | Emit at level FATAL (priority 50). |
| `LEVEL` | `do LEVEL^STDLOG(threshold)` | Set threshold. Accepts any level name above. |
| `SINK` | `do SINK^STDLOG(target)` | Set sink: `stderr` / `stdout` / `global` / `global:^GREF`. |

All five level entry points accept a leading `event` string and up to
5 key/value formal pairs (`k1,v1,...,k5,v5`). Caller-supplied pairs
appear in the rendered line in the order they were passed; missing
trailing pairs are simply omitted.

## Examples

```m
; defaults — INFO threshold, stderr sink
do INFO^STDLOG("login","user","alice","ip","10.0.0.1")
; → 2026-05-05T17:42:31.123Z level=INFO event=login user=alice ip=10.0.0.1

; quiet down — only WARN and above
do LEVEL^STDLOG("WARN")
do INFO^STDLOG("ignored")          ; suppressed
do WARN^STDLOG("retry","attempt","3")
; → 2026-05-05T17:42:31.456Z level=WARN event=retry attempt=3

; capture into a global for tests / log inspection
do SINK^STDLOG("global")
do INFO^STDLOG("captured")
; ^STDLIB($job,"stdlog","buf",1) holds the rendered line

; redirect to a caller-named global
do SINK^STDLOG("global:^MYAPPLOG")
do INFO^STDLOG("hello")
; ^MYAPPLOG(1) holds the rendered line
```

## Levels

| Name | Priority |
|---|---|
| `DEBUG` | 10 |
| `INFO` | 20 (default threshold) |
| `WARN` | 30 |
| `ERROR` | 40 |
| `FATAL` | 50 |

A line is emitted when its level priority is **at or above** the
configured threshold. The default threshold is `INFO`, so `DEBUG`
calls are silent unless the caller explicitly opts in via
`do LEVEL^STDLOG("DEBUG")`.

## Sinks

| Target | Behaviour |
|---|---|
| `stderr` | Open `/dev/stderr` and write the line. Default when no `SINK` call has been made. |
| `stdout` | Write to the current device (typically standard output). |
| `global` | Write to `^STDLIB($job,"stdlog","buf",N)` where `N` is allocated via `$INCREMENT`. |
| `global:^FOO` | Write to `^FOO(N)` where `N` is allocated via `$INCREMENT` on a per-target counter under `^STDLIB($job,"stdlog","cnt","g","^FOO")`. |

Sink configuration is per-process and persists in
`^STDLIB($job,"stdlog","sink")`. The `global` sinks are convenient for
testing and for buffered analysis pipelines: each emit gets a unique
sequential subscript, and concurrent emitters never collide because
`$INCREMENT` is atomic.

## Value escaping

Values are emitted **raw** when they contain none of: space, `=`, `"`,
`\`. Otherwise the value is wrapped in double quotes, with embedded
`\` doubled to `\\` and embedded `"` escaped to `\"`. The empty
string renders as `""`.

```m
do INFO^STDLOG("e","msg","hello world")  ; msg="hello world"
do INFO^STDLOG("e","kv","a=b")           ; kv="a=b"
do INFO^STDLOG("e","q","a""b")           ; q="a\"b"
do INFO^STDLOG("e","p","a\b c")          ; p="a\\b c"
do INFO^STDLOG("e","empty","")           ; empty=""
```

Keys are emitted verbatim — callers should keep keys to
identifier-safe characters (alphanumerics + `_`).

## Edge cases

- **No kv pairs.** Calling `do INFO^STDLOG("startup")` is legal; the
  line ends after `event=startup`.
- **Missing trailing values.** Passing `k1` without `v1` (e.g. an odd
  number of kv arguments) treats the missing value as the empty string
  and emits `k1=""`.
- **Threshold reset.** Killing `^STDLIB($job,"stdlog","level")`
  restores the default `INFO` threshold; the same applies to the sink
  config.
- **Test isolation.** Tests that exercise STDLOG should reset state
  between cases: `kill ^STDLIB($job,"stdlog")` then `do
  SINK^STDLOG("global")` and `do LEVEL^STDLOG("DEBUG")`.

## Errors

| `$ECODE` | Trigger |
|---|---|
| `,U-STDLOG-INVALID-LEVEL,` | `LEVEL` called with anything other than the five named priorities. |
| `,U-STDLOG-INVALID-SINK,` | `SINK` called with a target that is not `stderr`, `stdout`, `global`, or `global:^...` (the post-colon part must start with `^`). |

## Timestamp source

`$$now^STDDATE()` — millisecond-precision ISO-8601 UTC ending in `Z`.
v0.0.4 was originally planned to ship an inline helper (replaced at
v0.0.5 by track L4b), but since L5 STDDATE merged first, L4b is
folded into the v0.0.4 commit and STDLOG ships using STDDATE from
day one.

## See also

- `STDDATE` (v0.0.5) — provides the timestamp via `$$now`.
- `STDJSON` (v0.2.0) — adds a JSON-line output mode in Phase 2.
- `STDFIX` (v0.1.1) — log records can be safely emitted from inside
  TSTART/TROLLBACK isolation blocks; STDLOG performs no transactional
  state of its own.

## History

The original `v0.0.4` release was the kv logger only. The L4
`FORMAT(kv|json)` add-on landed at `v0.2.0` (depends on STDJSON, which
itself only became available at `v0.2.0`). Total effort spans both
landings.

The seven JSON-emission tests (`tFormatJsonEmitsValidJson` …
`tFormatKvAfterJsonReverts`) were withheld at the kv-only v0.0.4
release because the first call after a clean kv-path test crashed the
YDB harness. Diagnosis (corrected after one wrong turn) traced to the
documented YDB syntax limit `.x(SUBS)` (`%YDB-E-COMMAORRPAREXP` at
compile time on subscripted-by-reference args). STDJSON's recursive
descent was refactored to the **merge-then-pass** idiom in commit
`c3a0880`; the four parked STDLOG-JSON probe-the-tree tests followed
in commit `fb48f39` once `raises^STDASSERT` itself was hardened (ZGOTO
unwind for arg-less-quit-in-extrinsic in `9ee9724`).
