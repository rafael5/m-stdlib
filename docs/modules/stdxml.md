# `STDXML` — XML parser (well-formed XML 1.0 subset)

A recursive-descent parser for the well-formed-XML core. v0
covers the practical 70% of the format — elements with
attributes, nested children, text content, the five standard
entity references — and queues every other XML 1.0 feature as a
focused T-ticket. The architectural pretext is VistA HL7v3 / CDA /
FHIR ingestion: an XML you can actually parse without shelling out
to libxml2.

**Status:** v0 lands on `main` 2026-05-07 with a deliberately
narrow surface. Roughly 70% of the full XML 1.0 + Namespaces 1.0
+ XPath 1.0 envelope is queued under T23–T27 — see "Out of scope"
below for the explicit deferral list.

## Public API

| Extrinsic | Signature | Action / Returns |
|---|---|---|
| `parse` | `$$parse^STDXML(text, .root)` | Parse; `1` on success, `0` on failure. |
| `valid` | `$$valid^STDXML(text)` | Predicate. |
| `rootName` | `$$rootName^STDXML(.node)` | Element tag name. |
| `attr` | `$$attr^STDXML(.node, name)` | Attribute value, decoded; `""` if absent. |
| `text` | `$$text^STDXML(.node)` | Direct text content, decoded. |
| `childCount` | `$$childCount^STDXML(.node)` | Number of element children. |
| `childByName` | `$$childByName^STDXML(.node, name, .out)` | Find first child with `name`; merge into `.out`; `1`/`0`. |
| `lastError` | `$$lastError^STDXML()` | Diagnostic from the last failed parse. |

## Examples

```m
NEW xml,doc
SET xml="<bookstore><book id=""1""><title>Modern M</title></book></bookstore>"
DO  SET rc=$$parse^STDXML(xml,.doc)
WRITE $$rootName^STDXML(.doc),!         ; "bookstore"
WRITE $$childCount^STDXML(.doc),!       ; 1

NEW book
DO  IF $$childByName^STDXML(.doc,"book",.book) DO
. WRITE $$attr^STDXML(.book,"id"),!     ; "1"
. NEW title
. DO  IF $$childByName^STDXML(.book,"title",.title) DO
. . WRITE $$text^STDXML(.title),!       ; "Modern M"
```

## Tree shape

| Path | Holds |
|---|---|
| `node("name")` | Element tag (string). |
| `node("attr", attrName)` | Attribute value, decoded (the 5 standard entities). |
| `node("text")` | Direct text content, decoded. |
| `node("childCount")` | Number of element children. |
| `node("child", n)` | Subtree of n-th child element (recursive structure). |

The tree is caller-owned; each `parse` call kills the root before
populating. **Direct passing of `.node("child", n)` is invalid
YDB syntax** (`%YDB-E-COMMAORRPAREXP` at compile time) — pass-by-
reference of a subscripted local is not permitted. The
`childByName` helper does the canonical `merge` internally so
callers receive the child subtree as a non-subscripted local
they can then pass by reference.

## Grammar (v0 subset of XML 1.0)

```
<document>   ::= <ws>? <element> <ws>?
<element>    ::= <empty-tag> | <stag> <content> <etag>
<empty-tag>  ::= "<" <name> <attrs>? <ws>? "/>"
<stag>       ::= "<" <name> <attrs>? <ws>? ">"
<etag>       ::= "</" <name> <ws>? ">"
<attrs>      ::= ( <ws> <attr> )+
<attr>       ::= <name> <ws>? "=" <ws>? <attval>
<attval>     ::= '"' <chardata> '"' | "'" <chardata> "'"
<content>    ::= <chardata>? ( <element> <chardata>? )*
<name>       ::= [A-Za-z_:] [A-Za-z0-9_:.-]*
<chardata>   ::= text with the 5 standard entities decoded
```

## Standard entity references

The five XML predefined entities are decoded everywhere
character data is allowed (text content and attribute values):

| Entity | Decodes to |
|---|---|
| `&amp;` | `&` |
| `&lt;` | `<` |
| `&gt;` | `>` |
| `&quot;` | `"` |
| `&apos;` | `'` |

Numeric character references (`&#10;`, `&#x0A;`) and custom
DTD-declared entities are out of scope — see T24 / T26.

## Out of scope (queued)

| Track | Feature |
|---|---|
| **T23** | `<![CDATA[ ... ]]>` sections, `<?processing-instructions?>`, `<!-- comments -->`, `<?xml ... ?>` declaration |
| **T24** | Numeric character references `&#nnnn;` / `&#xHH;` |
| **T25** | Namespaces — `xmlns="..."` / `xmlns:prefix="..."` / `<prefix:tag>` |
| **T26** | DTDs / DOCTYPE / custom entity declarations |
| **T27** | XPath 1.0 query subset (axes, predicates, basic functions) |

These features land as v0.x.y patches when concrete consumers
drive them. v0's `parse()` returns `0` on any of these
constructs (fails closed); the diagnostic in `lastError()`
identifies the offending token.

The end goal — full XML 1.0 + Namespaces 1.0 + an XPath subset
for VistA HL7v3 / CDA / FHIR — was estimated at 12-16 days in the
Table 2 entry. v0 ships ~30% of that scope; T23–T27 cover the
remaining ~70%, scheduled when real consumers exercise them.

## Edge cases

- **Empty input is invalid.** `$$parse^STDXML("", .root)` returns
  `0` with `lastError() = "empty input"`.
- **Surrounding whitespace is tolerated.** Leading and trailing
  whitespace before / after the document element is fine; the
  parser skips it.
- **Mismatched close tag is rejected.** `<foo></bar>` returns `0`
  with a clear diagnostic.
- **Unclosed tag is rejected.** `<foo>` without `</foo>` returns
  `0`.
- **Quote characters in attribute values.** `'"'` is allowed in a
  single-quoted attribute and vice versa; otherwise use `&quot;`
  / `&apos;`.
- **Tag name characters.** v0 accepts `[A-Za-z_:][A-Za-z0-9_:.-]*`.
  This is a slight superset of strict XML 1.0 §2.3 (which excludes
  digits in the first character of a name) and covers practical
  XML in the wild including namespace-prefixed tags. **Note:
  namespaces are not recognised semantically** in v0 — `<x:foo>`
  is parsed as a single tag named `x:foo`. T25 lifts this.

## Engine portability

Pure-M throughout: `$extract` / `$length` / `$piece` / `$find` /
`$translate`. ANSI-standard, no `$Z*` extensions. Runs unchanged
on YDB and IRIS. The test suite (22 labels, 47 assertions) is
the v0 conformance gate.

## See also

- [`STDJSON`](stdjson.md) — sibling structured-data parser; same
  caller-owned-tree convention; same merge-then-pass idiom for
  recursive descent.
- [`STDREGEX`](stdregex.md) — soft dep listed in the Table 2 entry
  but not used in v0; XPath 1.0's text-pattern operators (T27)
  could lean on STDREGEX once that lands.
- [W3C XML 1.0 spec](https://www.w3.org/TR/xml/) — the production
  rules in v0's grammar trace directly.
- [W3C XML Test Suite](https://www.w3.org/XML/Test/) — conformance
  corpus for T23–T27 acceptance gating.
