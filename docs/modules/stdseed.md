# `STDSEED` — declarative test data

Loads a TSV manifest of FileMan records into the runtime environment
so a test can run against a known fixture set. Each row is dispatched
to a *filer* — by default `FILE^DIE` (FileMan's filing API), but any
`tag^routine` reference will do, which keeps the parser testable
outside a VistA host.

## Public API

| Label | Signature | Returns |
|---|---|---|
| `load` | `do load^STDSEED(path,filer)` | — (mutates the database via `filer`). |
| `loaded` | `$$loaded^STDSEED(path)` | `1` iff `path` is currently tracked. |
| `clear` | `do clear^STDSEED(path)` | — (drops `STDSEED`'s bookkeeping for `path`; idempotent). |
| `validate` | `$$validate^STDSEED(path)` | `1` if every row parses cleanly; raises `$ECODE` on syntax error. |
| `loadJson` | `do loadJson^STDSEED(jsonText)` | — (stub; raises `,U-STDSEED-NOT-IMPLEMENTED,` until STDJSON ships). |

The `filer` argument is optional. When empty, the default
`fileViaDie^STDSEED` is used; that label calls `FILE^DIE` and
reports any `^TMP("DIERR",$J)` error back through `$ECODE`. Any
custom filer is invoked once per row as

```m
do @filer@(file,.fda,.iens)
```

with `fda(file,"+1,",field)=value` and `iens` an output IEN. STDSEED
records the returned IEN under `^STDLIB($job,"stdseed",path,...)` so
`clear()` can drop it later.

## Manifest format

```tsv
# file 9.4 — package
9.4	.01=DEMO PACKAGE	1=DEMO	8=DEMO PACKAGE
# file 200 — user
200	.01=USER,TEST ONE	2=THING
```

- One row per record. Columns are tab-separated.
- The first column is the FileMan file number.
- Subsequent columns are `field=value` pairs. The first `=` is the
  separator; embedded `=` characters are preserved in the value.
- Lines starting with `#` and pure-whitespace lines are ignored.
- Trailing CR (Windows-style line endings) is stripped automatically.

## Examples

```m
; happy path — load against real FileMan
do load^STDSEED("/data/seed/widgets.tsv")
write $$loaded^STDSEED("/data/seed/widgets.tsv"),!  ; 1
do clear^STDSEED("/data/seed/widgets.tsv")          ; drops bookkeeping

; testing without FileMan — stub filer
do load^STDSEED("/tmp/widgets.tsv","capture^MYTEST")

; pre-flight validate
if '$$validate^STDSEED("/tmp/widgets.tsv") write "manifest broken",!
```

A custom filer has the shape:

```m
capture(file,fda,iens)
        ; record fda(file,"+1,",field)=value somewhere observable
        set ^TMP("seed-capture",file,$increment(^TMP("seed-capture",file,"n")))=fda(file,"+1,",".01")
        set iens=42
        quit
```

The default filer (`fileViaDie^STDSEED`) wraps `FILE^DIE`. The
suite uses stub filers exclusively, so `fileViaDie` ships with the
real-FileMan path uncovered (10/11 = 90.9% per-module coverage).
Real-environment validation requires a FileMan-bearing YDB endpoint
(e.g. vista-meta with the dataset loaded) and an STDFIX-wrapped
test that exercises FILE^DIE inside a rollback boundary; the
integration test is queued behind the v0.1.4 cycle. The label
itself compiles and is observably correct against any FileMan
host (manual smoke runs against vista-meta succeed); the gap is
test-coverage, not implementation. (Tracker T8.)

## Transactions

STDSEED does not open a transaction. The intended use is to wrap a
load → test → clear cycle inside an `STDFIX` (v0.1.1+) TSTART /
TROLLBACK pair so that filing side-effects roll back automatically.
`clear()` only removes STDSEED's bookkeeping; it does not delete the
records that the filer wrote. Until STDFIX ships, callers either
(a) point the load at a stub filer for unit testing, or (b) rely on
manual rollback.

## Error codes

| `$ECODE` | When |
|---|---|
| `,U-STDSEED-FILE-NOT-FOUND,` | `path` cannot be opened readonly |
| `,U-STDSEED-MISSING-FILE,` | A row's first column is empty |
| `,U-STDSEED-MISSING-FIELD,` | A `field=value` pair has no `=` |
| `,U-STDSEED-FILER-ERROR,` | The filer set `$ECODE`; STDSEED relays the failure |
| `,U-STDSEED-FILER-DIE-ERROR,` | The default filer saw `^TMP("DIERR",$J)` populated |
| `,U-STDSEED-NOT-IMPLEMENTED,` | `loadJson()` is called before STDJSON ships |

## See also

- [`STDARGS`](stdargs.md) — pairs with the m-cli `m test --seed PATH`
  flag (track Y) once the runner protocol lands at M1.
- The TDD orchestration plan, §6.3 ([`tdd-orchestration-plan.md`](../tdd-orchestration-plan.md))
  — narrative around STDFIX / STDMOCK / STDSEED.
