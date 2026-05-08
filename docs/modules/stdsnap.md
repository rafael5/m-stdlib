---
module: STDSNAP
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'Snapshot testing: serialize an M tree, diff against a baseline'
labels: ['asserts', 'dq', 'isNumeric', 'matches', 'qval', 'save', 'serialize']
errors: []
conformance: []
see_also: ['STDASSERT', 'STDFS']
---

# `STDSNAP` — Snapshot testing

Capture a deterministic dump of an M tree on the first run; on
subsequent runs, compare the live tree against the saved baseline.
A mismatch is reported as a STDASSERT failure with the snapshot
path so a human can inspect the diff. Cuts the wrist-deep
hand-written `eq^STDASSERT` chains for tests that verify large
parsed JSON trees, FileMan record exports, etc.

## Public API

| Extrinsic | Signature | Action / Returns |
|---|---|---|
| `serialize` | `$$serialize^STDSNAP(.data)` | Canonical line-per-leaf text dump (no trailing LF). |
| `save` | `do save^STDSNAP(path, .data)` | Write `serialize(data)` to `path` via STDFS. |
| `matches` | `$$matches^STDSNAP(path, .data)` | `1` iff `serialize(data)` byte-equals `path`'s content. |
| `asserts` | `do asserts^STDSNAP(.pass, .fail, path, .data, desc)` | STDASSERT-style integration: pass on match, fail on mismatch. |

## Examples

```m
; First run: capture the baseline
NEW report
DO buildReport^MYAPP(.report)
DO save^STDSNAP("snapshots/report.snap",.report)

; Subsequent runs: compare against the baseline
NEW report
DO buildReport^MYAPP(.report)
IF '$$matches^STDSNAP("snapshots/report.snap",.report) DO  ...

; Inside a test suite, drop straight into STDASSERT integration:
tReportShape(pass,fail) ;@TEST "report tree matches the snapshot"
        NEW report
        DO buildReport^MYAPP(.report)
        DO asserts^STDSNAP(.pass,.fail,"snapshots/report.snap",.report,"report tree")
        QUIT

; Update workflow: when the report shape legitimately changes,
; re-save the snapshot. (No CLI flag for this in v1 — caller
; toggles between save and matches by hand.)
DO save^STDSNAP("snapshots/report.snap",.report)
```

## Canonical format

Each leaf in the tree emits exactly one line. Lines are emitted in
M's `$ORDER` walk order — natural M-collation, which sorts numeric
subscripts numerically and string subscripts as strings.

```
(subscripts)=value
```

| Component | Format |
|---|---|
| `subscripts` | M-syntax comma-separated list. Numeric subscripts unquoted; string subscripts wrapped in `"..."` with embedded `"` doubled. |
| `=` | Literal separator. |
| `value` | Numeric leaves: unquoted (canonical numeric form). Everything else: wrapped in `"..."` with embedded `"` doubled. |

Example dumps:

| Input tree | Serialised |
|---|---|
| `data("a")="hello"` | `("a")="hello"` |
| `data(1)="first"` | `(1)="first"` |
| `data("k")="say ""hi"""` | `("k")="say ""hi"""` |
| Two leaves: `data("a")="x", data("b")="y"` | `("a")="x"\n("b")="y"` |
| Nested: `data("user","name")="alice", data("user","age")=42, data("system")="ok"` | `("system")="ok"\n("user","age")=42\n("user","name")="alice"` |

The format is **deterministic by construction**: $QUERY walks
descendants in M-collation order; each leaf produces exactly one
line; quoting rules are positional and reversible. Two
`serialize()` calls on the same tree return byte-identical output —
which is exactly what makes file-based diffing reliable.

The format is also **diff-friendly**: a value change touches one
line, an added key adds one line, a removed key removes one line.
`diff -u baseline.snap current.snap` produces a tight unified diff
that a human can scan in seconds.

## Workflow

**First run** — caller doesn't have a snapshot yet:

1. Build the data tree.
2. Call `save^STDSNAP(path, .data)` to write the baseline.
3. Commit the snapshot file alongside the test source.

**Subsequent runs** — caller has a baseline:

1. Build the data tree (same producer, presumably the same shape).
2. Call `matches^STDSNAP(path, .data)` (or `asserts^STDSNAP` inside a
   test) to compare.
3. On mismatch: a human runs `diff -u baseline.snap current.snap`
   to see what changed. If the change is intentional (the report
   shape legitimately moved), re-`save` to update the baseline. If
   not, fix the producer.

There is **no auto-update mode** in v1 — callers must explicitly
re-`save` to refresh the baseline. This is a feature: forces a
human review before snapshot drift becomes invisible.

## Edge cases

- **Empty tree** serialises to `""`. `save` writes a zero-byte
  file (well, almost: STDFS appends a trailing LF per its POSIX
  convention; readFile strips it; round-trip is clean).
- **Missing baseline file** → `matches()` returns `0`. The first
  run on a fresh checkout fails until you call `save()` to seed
  the snapshot. This is intentional — silently passing the first
  run would leave snapshots accidentally absent.
- **Single root scalar** (`set data="value"` with no subscripts) is
  not currently serialised — `$QUERY` walks only descendants.
  Callers that need root-scalar snapshots should pre-wrap in a
  one-key tree (`data("value")=originalValue`). Documented as a
  v0.x.y enhancement under T21.
- **Numeric vs string distinction.** A value of `0` and a value
  of `"0"` both serialise to `0` — M's canonical numeric form
  doesn't distinguish them in the dump. If you need byte-faithful
  type round-trip, prefer JSON encoding via STDJSON (which has
  `s:` / `n:` / `t` / `f` / `z` type tags).
- **Numeric subscripts with leading zeros.** M canonicalises
  `data("01")` to `data(1)` if "01" parses as a canonical number?
  No — strings with leading zeros are not canonical numeric.
  `$$isNumeric("01")` returns 0 (since `+"01"` = `1`, not equal
  to `"01"`). So `data("01","x")` emits `("01","x")="..."` with
  the subscript quoted as a string — preserves the input.

## Engine portability

Pure-M throughout: `$QUERY`, `$ORDER`, `$DATA`, `$EXTRACT`,
`$LENGTH`, `$PIECE`, `$SELECT`. ANSI-standard, no `$Z*`
extensions. Runs unchanged on YDB and IRIS. The test suite
(14 labels, 23 assertions) is the conformance gate.

## See also

- [`STDASSERT`](stdassert.md) — STDSNAP's `asserts` integrates with
  STDASSERT's pass/fail counters and recordPass/recordFail
  output protocol. Pair them inside any `*TST.m` suite.
- [`STDFS`](stdfs.md) — STDSNAP's `save` and `matches` use
  `writeFile` and `readFile` for the I/O. STDSNAP files are plain
  text — a dropped LF on `writeFile` and stripped LF on `readFile`
  give clean round-trip behaviour.
- [`STDJSON`](stdjson.md) — alternative encoding for cases where
  byte-faithful type distinction matters (numeric `0` vs string
  `"0"`). STDSNAP's text format trades a small amount of fidelity
  for human-readable dumps.
