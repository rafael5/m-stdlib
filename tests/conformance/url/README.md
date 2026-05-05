# RFC 3986 URI conformance vectors

Vendored test vectors for `STDURL`. Source of truth:
[RFC 3986 — Uniform Resource Identifier (URI): Generic Syntax](https://datatracker.ietf.org/doc/html/rfc3986).

## Contents

| File | Source | Coverage |
|---|---|---|
| `rfc3986-section-5.4.1-normal.tsv` | RFC 3986 §5.4.1 | Normal reference-resolution examples — base `http://a/b/c/d;p?q` against 23 references |
| `rfc3986-section-5.4.2-abnormal.tsv` | RFC 3986 §5.4.2 | Abnormal reference-resolution examples (extra `..`, `.` segments, dotted names, query/fragment with embedded `/`) — base `http://a/b/c/d;p?q` against 19 references |

## Format

Tab-separated. Three columns: `base`, `ref`, `resolved`. The header
row is included. The empty `ref` row exercises §5.4.1 row 15 (empty
reference resolves to the base).

## Why vendored

Per [implementation plan §5](../../../docs/m-stdlib-implementation-plan.md#5-project-layout),
`tests/conformance/` is the canonical home for external-spec corpora.
Inlining the §5.4 tables in `STDURLTST.m` would obscure their RFC
provenance and discourage adding fuzz / round-trip drivers that share
the same fixtures.

## Strict-mode caveat

RFC 3986 §5.4.2 also lists `http:g` resolving to `http:g` (strict) /
`http://a/b/c/g` (loose). `STDURL.resolve` is strict — the abnormal
table omits this row to keep it engine-agnostic; a dedicated
`tStrictMode` test in `STDURLTST.m` covers it directly.
