# `STDCSV` — RFC-4180 CSV

CSV parsing and serialisation per
[RFC 4180](https://datatracker.ietf.org/doc/html/rfc4180).
Pure-M; no host-call. In-memory and file-backed entry points.

## Public API

| Entry point | Signature | Returns / effect |
|---|---|---|
| `parse` | `$$parse^STDCSV(text,.rows)` | Populates `rows(i,j)`; returns the row count. |
| `write` | `$$write^STDCSV(.rows)` | Returns the RFC-4180 CSV text for `rows`. |
| `parseFile` | `parseFile^STDCSV(path,callback)` | Reads `path`; calls `callback(rownum,.fields)` per record. |
| `writeFile` | `writeFile^STDCSV(path,.rows)` | Writes `rows` to `path` as RFC-4180 CSV. |

`parse` returns 0 and leaves `rows` undefined for empty input. `write`
returns the empty string for an empty `rows` array.

## Examples

```m
; in-memory parse
NEW rows,n
SET n=$$parse^STDCSV("a,b,c"_$CHAR(13,10)_"d,e,f"_$CHAR(13,10),.rows)
WRITE n,!                     ; 2
WRITE rows(1,2),!             ; "b"
WRITE rows(2,3),!             ; "f"

; quoted fields with embedded comma, CRLF, and "" escape
SET t="aaa,""b,b,b"",""hello """"world"""""_$CHAR(13,10)
SET n=$$parse^STDCSV(t,.r)
WRITE r(1,2),!                ; "b,b,b"
WRITE r(1,3),!                ; hello "world"

; round-trip
KILL src
SET src(1,1)="name",src(1,2)="city"
SET src(2,1)="Alice",src(2,2)="has,comma"
SET out=$$write^STDCSV(.src)
; out = "name,city<CRLF>Alice,""has,comma""<CRLF>"

; file-backed: streaming parse
DO parseFile^STDCSV("/tmp/in.csv","onrow^MYAPP")
;   onrow(rownum,.fields) is called once per record;
;   fields(j) holds the j'th field (1-based).
```

## Behaviour

| RFC-4180 | Behaviour |
|---|---|
| §2.1 | Records separated by CRLF. `parse` also accepts LF and lone CR; `write` emits CRLF. |
| §2.2 | A trailing terminator on the last record is optional on input; `write` always emits one. |
| §2.3 | Header rows are not distinguished — the parser treats them as data. |
| §2.4 | Spaces inside fields (leading, trailing, internal) are preserved verbatim. |
| §2.5 | Fields may optionally be wrapped in `"..."`; the wrapping quotes are not part of the value. |
| §2.6 | Quoted fields may contain `,`, CR, or LF as literals. `write` quotes any field containing those characters. |
| §2.7 | `""` inside a quoted field decodes to one `"`. `write` doubles every embedded `"` and wraps the field. |
| ext. | A leading UTF-8 BOM (`EF BB BF`) is stripped from the input by `parse`. `write` never emits a BOM. |

## Edge cases

- **Empty input.** `parse("",.rows)` returns 0 and leaves `rows`
  undefined. The caller's `rows` array is killed before population on
  every other call, so stale subscripts from a previous parse do not
  leak into the next.
- **Trailing terminator optional.** `parse` accepts files with or
  without a final CRLF; the row count is the same either way.
- **Mixed line endings.** `parse` accepts CRLF, LF, and lone CR as
  record terminators on input. `write` always emits CRLF.
- **Empty fields.** Consecutive commas yield empty-string fields:
  `"a,,c"_$CHAR(10)` → `rows(1,1)="a"`, `rows(1,2)=""`, `rows(1,3)="c"`.
- **Ragged rows.** `write` walks `rows(i,j)` via `$ORDER`, so rows with
  different column counts emit only as many fields as are populated.
- **Embedded NUL.** `$CHAR(0)` inside fields is not supported — M
  strings cannot represent null bytes portably.

## File I/O semantics

- **Engine.** YottaDB-only at v0.0.6 (uses YDB SEQ-device deviceparams
  `readonly` / `newversion` / `stream` / `nowrap`). IRIS portability
  is fail-soft per project policy.
- **`parseFile` line buffering.** Reads with the default SEQ
  `READ`, which strips the LF terminator. `parseFile` strips a
  trailing CR if present, then re-injects canonical CRLF between
  accumulated lines. Records spanning multiple lines (RFC-4180 §2.6)
  are detected by tracking the running quote count and accumulating
  until even.
- **`writeFile` STREAM mode.** Opens with `(newversion:stream:nowrap)`
  so embedded CRLFs in quoted fields are written byte-faithfully and
  no record-mode transformation is applied.
- **Errors.** Both file-backed entry points set `$ECODE` to
  `,U-STDCSV-OPEN-FAIL,` if the OPEN fails (5-second timeout).

## Conformance

The module is tested against an inline RFC-4180 §2 vector set covering
every clause (§2.1–§2.7) plus the BOM, LF-only, and Excel-quirk
extensions. The audit-trail corpus is vendored at
[`tests/conformance/csv/`](../../tests/conformance/csv/) — see its
[README](../../tests/conformance/csv/README.md) for the file layout.
File-I/O smoke tests (`parseFile`, `writeFile`) write a fixture to
`/tmp` inside the test, round-trip it through both entry points, and
clean up on close.

## See also

- `STDFMT` for printf-style formatting of strings before they hit a
  CSV field.
- `STDJSON` (Phase 2) for a richer structured-data alternative when
  CSV's flat-table model is too constrained.
