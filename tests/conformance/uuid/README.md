# UUID conformance vectors

Vendored test vectors for `STDUUID`. Sources of truth:

- [RFC 4122 — A Universally Unique IDentifier (UUID) URN Namespace](https://datatracker.ietf.org/doc/html/rfc4122)
  (versions 1, 3, 4, 5; the four namespace UUIDs in Appendix C; the
  Nil UUID in §4.1.7).
- [RFC 9562 — Universally Unique IDentifiers (UUIDs)](https://datatracker.ietf.org/doc/html/rfc9562)
  (versions 6, 7, 8; Max UUID; updated variant table).

## Contents

| File | What it covers |
|---|---|
| `rfc4122-vectors.tsv` | One UUID per row, with the version, variant, and validity STDUUID is expected to report. Includes well-formed examples (every version 1–8, every variant, mixed/uppercase hex), plus a battery of malformed-input rejections. |

## Format

Tab-separated, with a header line. Columns:

| Column | Type | Meaning |
|---|---|---|
| `uuid` | string | The literal text that goes into `$$valid^STDUUID(uuid)`. May be empty (last row). |
| `version` | int 0–15, or empty | Expected `$$version^STDUUID(uuid)` output. Empty when the UUID is invalid (matches STDUUID's "" return). |
| `variant` | one of `ncs` / `rfc4122` / `microsoft` / `future`, or empty | Expected `$$variant^STDUUID(uuid)` output. Empty when invalid. |
| `valid` | `1` or `0` | Expected `$$valid^STDUUID(uuid)` output. |
| `notes` | string | Why this row is in the corpus. Free-form. |

## Coverage map

### Well-formed UUIDs

- Nil UUID (`00...00`) and Max UUID (`ff...ff`) — the two extreme
  bookends from RFC 4122 §4.1.7 and RFC 9562 §5.10.
- One example for each defined version (1, 2, 3, 4, 5, 6, 7, 8).
- The four namespace UUIDs from RFC 4122 Appendix C (DNS, URL, OID,
  X.500). All four share variant `rfc4122` and version `1`.
- Variant cases: position-20 = `3` → `ncs`; position-20 = `9` →
  `rfc4122`; position-20 = `c` → `microsoft`; position-20 = `f` →
  `future`. STDUUID's variant decoder is exercised by a single hex
  digit, so one example per variant suffices.
- Case sensitivity: an all-uppercase row and a mixed-case row prove
  the validator is case-insensitive (per RFC 4122 §3 — text
  representation is lowercase, but parsers MUST accept any case).

### Malformed inputs

- Length off by ±1 (35 chars, 37 chars).
- 36-char input with hyphens at the wrong positions.
- Hyphen replaced by a different separator (`_`).
- Non-hex character at a body position.
- All-hex but no hyphens (32 chars).
- Empty string.
- 36-char string of mostly non-hex letters in correct hyphen shape.

## Why vendored

The well-formed examples are short and well-known, but vendoring
them as a TSV (rather than inlining everything in `STDUUIDTST.m`)
means:

1. The corpus is auditable — anyone can `diff` against RFC 4122 §C
   or RFC 9562 §5.
2. Future TDD additions (round-trip property tests, fuzz harnesses)
   can ingest the same TSV.
3. Adjacent projects building on STDUUID get a known-good fixture
   set without restating the vectors.

## Reuse

Other STD modules with structured input use the same pattern:
`tests/conformance/<name>/<rfc-id>.tsv` plus a sibling `README.md`.
See `tests/conformance/b64/`, `tests/conformance/csv/`, and
`tests/conformance/json/`.

## See also

- [implementation plan §5](../../../docs/m-stdlib-implementation-plan.md#5-project-layout)
  for the canonical `tests/conformance/` layout.
- [implementation plan §8.2](../../../docs/m-stdlib-implementation-plan.md#82-stduuid--rfc-4122-uuids)
  for STDUUID's public API and acceptance criteria.
