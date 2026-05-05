# RFC-4180 CSV conformance vectors

Vendored test vectors for `STDCSV`. Source of truth:
[RFC 4180 §2 — Definition of the CSV Format](https://datatracker.ietf.org/doc/html/rfc4180#section-2)
plus a small set of real-world Excel quirks.

## Contents

| File | RFC-4180 § | What it covers |
|---|---|---|
| `rfc4180-2.1-crlf-records.csv` | §2.1, §2.2 | Records separated by CRLF; trailing CRLF on last line |
| `rfc4180-2.3-header.csv` | §2.3 | Optional header line; same shape as data rows |
| `rfc4180-2.4-spaces.csv` | §2.4 | Spaces inside fields are part of the field |
| `rfc4180-2.5-quoted-fields.csv` | §2.5 | Optional double-quote enclosure on each field |
| `rfc4180-2.6-embedded-comma.csv` | §2.6 | Quoted fields containing `,` |
| `rfc4180-2.6-embedded-crlf.csv` | §2.6 | Quoted fields containing line breaks |
| `rfc4180-2.7-escaped-quote.csv` | §2.7 | `""` as the literal-quote escape inside a quoted field |
| `lf-line-endings.csv` | (extension) | Records terminated by LF only — the Unix-world default |
| `bom-utf8.csv` | (extension) | UTF-8 BOM (`EF BB BF`) prefixing the first field |
| `excel-quirks.csv` | (extension) | Real-world Excel oddity: empty trailing field, lone CR |

## Format

Each `.csv` file is a literal CSV byte stream with the line endings
implied by its name (CRLF for the RFC-4180 files unless `lf-` in the
name; mixed for `excel-quirks.csv`). Files are intentionally small
(≤ 6 rows) so the entire corpus is auditable by eye.

## Why vendored

Storing the corpus as data files (rather than inlining everything in
`STDCSVTST.m`) means:

1. The corpus is auditable — anyone can `xxd` it and check the bytes
   against the RFC clause it claims to cover.
2. `parseFile^STDCSV` round-trip tests have a real on-disk fixture
   to read, exercising the file I/O path end-to-end.
3. Future modules with structurally similar inputs (e.g. TSV, PSV)
   can borrow the same files via `$translate`.

The `*TST.m` suite covers most clauses with inline byte strings so
the tests remain runnable without disk access; the on-disk corpus is
the audit trail.

## See also

- [implementation plan §5](../../../docs/m-stdlib-implementation-plan.md#5-project-layout)
  for the canonical `tests/conformance/` layout.
- [implementation plan §8.8](../../../docs/m-stdlib-implementation-plan.md#88-stdcsv--rfc-4180-csv)
  for the STDCSV public API and acceptance criteria.
