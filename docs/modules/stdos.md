---
module: STDOS
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'Process / env / cmdline helpers (YDB-only v1)'
labels: ['arg', 'argc', 'argv', 'cmdline', 'cwd', 'env', 'exit', 'hostname', 'pid', 'splitArgs', 'user']
errors: []
conformance: []
see_also: []
---

# `STDOS` — Process / env / cmdline helpers

Thin wrappers over YDB's `$ZTRNLNM` / `$JOB` / `$ZCMDLINE` /
`ZHALT` intrinsics, plus a whitespace-only `splitArgs` tokeniser.
Fills the gap between [`STDARGS`](stdargs.md) (which parses CLI
flags from `$ZCMDLINE` for one routine's invocation) and the
ad-hoc `$zsystem` /  `$horolog` / direct-`$ZGETENV` patterns
sprinkled across consumer projects.

## Public API

| Extrinsic | Signature | Returns / Action |
|---|---|---|
| `env` | `$$env^STDOS(name)` | Value of env var `name`; `""` if unset. |
| `pid` | `$$pid^STDOS()` | Current process ID (integer). |
| `cmdline` | `$$cmdline^STDOS()` | Raw `$ZCMDLINE` string. |
| `argc` | `$$argc^STDOS()` | Count of `$ZCMDLINE` arguments. |
| `arg` | `$$arg^STDOS(i)` | i-th `$ZCMDLINE` arg (1-indexed); `""` out of bounds. |
| `argv` | `do argv^STDOS(.args)` | Populates `args(1..N)` from `$ZCMDLINE`. |
| `splitArgs` | `$$splitArgs^STDOS(s, .args)` | Tokenise `s` on whitespace; populate `args(1..N)`; return N. |
| `cwd` | `$$cwd^STDOS()` | Current working directory (from `$PWD`). |
| `user` | `$$user^STDOS()` | Current username (from `$USER`, falling back to `$LOGNAME`). |
| `hostname` | `$$hostname^STDOS()` | Host name (from `$HOSTNAME`; may be `""`). |
| `exit` | `do exit^STDOS(rc)` | Terminate the YDB process with exit code `rc` (default `0`). |

## Examples

```m
; environment variable lookup
SET home=$$env^STDOS("HOME")             ; "/home/alice"
SET notSet=$$env^STDOS("NO_SUCH_VAR")    ; ""

; process ID — same as $J
SET p=$$pid^STDOS()                      ; e.g. 12345

; command-line introspection
IF $$argc^STDOS()<2 DO usage^MYAPP HALT
SET inputPath=$$arg^STDOS(1)
DO argv^STDOS(.args)                     ; args(1..N)

; quoteless split of an arbitrary string
SET n=$$splitArgs^STDOS("alpha beta gamma",.tokens)  ; n=3, tokens(1..3)

; identity helpers
SET who=$$user^STDOS()                   ; "alice"
SET where=$$cwd^STDOS()                  ; "/home/alice/projects/foo"
SET host=$$hostname^STDOS()              ; "alice-dev" or "" in stripped containers

; clean exit
DO exit^STDOS(0)                         ; rc=0 to the calling shell
DO exit^STDOS(2)                         ; rc=2 — caller can inspect $?
```

## Argument splitting

`splitArgs` in v1 is **whitespace-only**:

- Input is split on runs of one or more spaces (single space `0x20`).
- Leading and trailing whitespace is dropped.
- **No quote handling.** A string `'one "two three"'` tokenises as
  four args: `one`, `"two`, `three"`, not three. STDARGS has a
  quote-aware tokeniser; if you need it here, either pre-tokenise
  via the shell (which already removes quotes) or use STDARGS'
  parser directly. Quote-aware `splitArgs` is queued at T15.

Behaviour summary:

| Input | Split |
|---|---|
| `""` | 0 args |
| `"solo"` | 1 arg: `solo` |
| `"a b c"` | 3 args: `a`, `b`, `c` |
| `"a   b"` | 2 args: `a`, `b` (run collapsed) |
| `"  alpha beta  "` | 2 args (boundary whitespace dropped) |

`argc`, `arg`, and `argv` all delegate to `splitArgs($ZCMDLINE, ...)`,
so they share these semantics.

## YDB intrinsic boundary

| STDOS surface | YDB intrinsic |
|---|---|
| `env(name)` | `$ZTRNLNM(name)` |
| `pid()` | `$JOB` (which is the integer PID) |
| `cmdline()` | `$ZCMDLINE` |
| `cwd()` / `user()` / `hostname()` | `$ZTRNLNM("PWD" / "USER" / "HOSTNAME")` |
| `exit(rc)` | `ZHALT rc` |

**Why `$ZTRNLNM` and not `$ZGETENV`?** Both are valid YDB
intrinsics for environment-variable lookup. `$ZGETENV` is the
GT.M / IRIS-style name; `$ZTRNLNM` is the VAX/VMS legacy name —
YDB supports both for backward compatibility. The default `m fmt`
profile in this project mis-handles abbreviation expansion of
`$zgetenv` (rewrites it as `$zgbldiretenv`, splicing
`$zgbldir` + `etenv`); `$ztrnlnm` does not trigger the
mangling. Filed as a [`discoveries.md`](../tracking/discoveries.md) row; the equivalence at
the YDB level means consumers see no observable difference.

## Edge cases

- **`env("")` returns `""`.** No call into `$ZTRNLNM` is made; an
  empty name is always "unset" by definition.
- **`hostname()` may be `""`.** `$HOSTNAME` is exported by some
  shells (`bash`) but not always — minimal containers strip it.
  The contract is "never raises", not "always non-empty". Callers
  that always need a hostname should wait on the
  `$ZF → gethostname(2)` callout backend (T15).
- **`cwd()` may be `""`.** Same caveat as `hostname()`; `$PWD` is
  shell-set, not kernel-tracked. The future
  `$ZF → getcwd(2)` backend will use the kernel-tracked CWD.
- **`arg(i)` is 1-indexed.** `arg(0)`, negative `i`, and
  out-of-range `i` all return `""` rather than raising — matches
  the lenient lookup convention of `$GET()`.
- **`splitArgs` runs are linear in input length.** The collapse-
  doubles loop runs `O(log W)` iterations where `W` is the longest
  run of spaces; total work is `O(N log W)` with N the input length.
  For typical CLI inputs (tens to hundreds of chars, no long runs),
  this is well below the parser's other costs.
- **`exit(rc)` is unreachable from automated tests.** Calling it
  ends the test process. The label is shipped intact and
  inspectable; coverage on STDOS sits at 91.7% (11/12 labels) for
  this reason. Callers should drive integration tests through a
  shell wrapper that captures the rc via `$?`.

## Engine portability

YDB on Linux is the supported configuration. The IRIS arm —
`$CLASSMETHOD %SYSTEM.Util.GetEnviron()` for env, `%SYS.System` for
pid / cwd / hostname, `do $SYSTEM.Process.Terminate(.,.)` for exit —
is queued at T15 alongside the `$ZF → libc` callout backend. The
public API surface does not change for the IRIS arm.

## See also

- [`STDARGS`](stdargs.md) — full CLI parser (long/short/grouped
  flags, positionals, sub-commands). Use STDOS for raw access to
  `$ZCMDLINE` / env / pid / cwd; use STDARGS for parsed CLI option
  surfaces.
- [`STDLOG`](stdlog.md) — emits `$$pid^STDOS()` as part of its
  default field set when `FORMAT(json)` is selected (queued).
- [`STDFS`](stdfs.md) — uses `$JOB` for sandbox-path namespacing
  in its tests; STDOS provides `$$pid^STDOS()` as the supported
  way to get the same value from app code.
