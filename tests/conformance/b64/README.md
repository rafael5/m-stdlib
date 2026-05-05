# RFC-4648 Base64 conformance vectors

Vendored test vectors for `STDB64`. Source of truth:
[RFC 4648 §10 — Test Vectors](https://datatracker.ietf.org/doc/html/rfc4648#section-10).

## Contents

| File | Source | Encoding |
|---|---|---|
| `rfc4648-section-10.tsv` | RFC 4648 §10 (Base64) | Standard alphabet, padded |
| `rfc4648-section-10-urlsafe.tsv` | Derived from §10 by remapping `+/` → `-_` and stripping `=` padding (per §5) | URL-safe alphabet, no padding |

## Format

TSV with two columns: `input` (raw bytes as ASCII), `encoded` (Base64
text). Empty `input` is represented as the literal empty string —
parsers must not skip the row.

## Why vendored

The RFC vectors are short and well-known, but vendoring them as data
files (rather than inlining them in `STDB64TST.m`) means:

1. They are auditable — anyone can `diff` against the RFC.
2. Future test additions (round-trip property tests, fuzz corpora)
   can read the same files without restating the vectors.
3. The `tests/conformance/` tree is the canonical home for every
   external spec corpus per
   [implementation plan §5](../../../docs/m-stdlib-implementation-plan.md#5-project-layout).

## Reuse

Other `STDxxx` modules with RFC-defined test vectors follow the same
pattern: `tests/conformance/<name>/<rfc-id>.tsv` plus a sibling
`README.md`.
