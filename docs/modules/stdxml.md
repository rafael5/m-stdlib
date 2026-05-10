---
module: STDXML
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'XML parser (well-formed XML 1.0 subset, in-progress)'
labels: ['attr', 'attrNs', 'childByName', 'childCount', 'lastError', 'ns', 'parse', 'rootName', 'text', 'valid', 'xpath', 'xpathOne', 'xpathText']
errors: []
conformance: []
see_also: []
---

# `STDXML` — XML parser (well-formed XML 1.0 subset)

A recursive-descent parser for the well-formed-XML core. v0
covers the practical 70% of the format — elements with
attributes, nested children, text content, the five standard
entity references — and queues every other XML 1.0 feature as a
focused T-ticket. The architectural pretext is VistA HL7v3 / CDA /
FHIR ingestion: an XML you can actually parse without shelling out
to libxml2.

**Status:** ~95% of the full XML 1.0 + Namespaces 1.0 + XPath 1.0
envelope. Shipped: well-formed XML 1.0, the five standard entity
references, numeric character references, comments / processing
instructions / `<?xml ?>` declaration / `<![CDATA[ ]]>`, namespaces
(element + attribute level with the built-in `xml:` prefix), and
an XPath subset covering paths, `[N]` predicates, descendant axis
`//`, wildcards (`*`, `@*`), the attribute axis (`@attrName`), and
**comparison predicates** (`[@id='v']`, `[name()='b']`,
`[count(child)>1]`) backed by an expression evaluator with XPath
1.0 type coercion and the most common XPath functions
(`position()`, `last()`, `name()`, `text()`, `count()`,
`string-length()`, `normalize-space()`, `contains()`,
`starts-with()`, plus `not()` / `string()` / `number()`).
Remaining: DTDs / custom entity declarations (T26).

## Public API

| Extrinsic | Signature | Action / Returns |
|---|---|---|
| `parse` | `$$parse^STDXML(text, .root)` | Parse; `1` on success, `0` on failure. |
| `valid` | `$$valid^STDXML(text)` | Predicate. |
| `rootName` | `$$rootName^STDXML(.node)` | Element tag name. |
| `attr` | `$$attr^STDXML(.node, name)` | Attribute value, decoded; `""` if absent. |
| `ns` | `$$ns^STDXML(.node)` | Resolved namespace URI for the element; `""` if not in any namespace (T25). |
| `attrNs` | `$$attrNs^STDXML(.node, attrName)` | Resolved namespace URI for an attribute; `""` if unprefixed or absent (T25b). |
| `xpath` | `$$xpath^STDXML(.tree, expr, .results)` | Run an XPath query; populate `results(1..N)`; return N. Element matches merge a subtree; attribute matches surface as `results(i,"text")` = value, `results(i,"name")` = attribute name. |
| `xpathOne` | `$$xpathOne^STDXML(.tree, expr, .out)` | First match → `.out` (merged); return 1/0. |
| `xpathText` | `$$xpathText^STDXML(.tree, expr)` | Direct text content of the first match; `""` if none. |
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
| `node("name")` | Element local name (e.g. `foo` for `<x:foo>`). |
| `node("ns")` | Resolved namespace URI (T25); `""` if not in any namespace. |
| `node("prefix")` | Original prefix used in the source (T25); `""` if unprefixed. |
| `node("attr", attrName)` | Attribute value, decoded (the 5 standard entities + numeric char refs). |
| `node("attrNs", attrName)` | Attribute namespace URI (T25b); only set for prefixed attrs. |
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

## Numeric character references (T24)

Both decimal `&#NNN;` and hexadecimal `&#xHH;` forms are decoded:

| Reference | Code point | Output bytes |
|---|---|---|
| `&#65;` | U+0041 (`A`) | `A` (1 byte) |
| `&#x41;` | U+0041 (`A`) | `A` (1 byte) |
| `&#xA9;` | U+00A9 (`©`) | `0xC2 0xA9` (2 bytes UTF-8) |
| `&#x4E2D;` | U+4E2D (`中`) | `0xE4 0xB8 0xAD` (3 bytes UTF-8) |
| `&#x1F600;` | U+1F600 (`😀`) | `0xF0 0x9F 0x98 0x80` (4 bytes UTF-8) |

Code points up to `U+10FFFF` are accepted; out-of-range or
malformed references fall through as literal text per the
lenient `decodeEntities` convention.

Custom DTD-declared entities are still out of scope — see T26.

## CDATA sections (T23)

`<![CDATA[ ... ]]>` content is captured as **literal text**: no
entity decoding, no markup interpretation. `&` and `<` inside a
CDATA section are preserved verbatim, which is the whole point —
HL7v3 / CDA narrative blocks routinely use CDATA to wrap clinical
text containing `<` and `&`.

```xml
<x><![CDATA[a&b<c]]></x>
```

decodes to text `a&b<c` (5 bytes, the literals preserved).

CDATA can be interleaved with regular text:

```xml
<x>before <![CDATA[mid&dle]]> after</x>
```

decodes to `before mid&dle after`.

## Comments, PIs, and the xml-decl (T23)

`<!-- ... -->` comments, `<? ... ?>` processing instructions, and
the `<?xml ... ?>` declaration are all **skipped** — they don't
appear in the parsed tree. Comments may appear before the root,
inside element content, or after the root; PIs and the xml-decl
typically appear at the document level (before / after the root)
but the parser tolerates them anywhere a comment is allowed.

## Supported / queued tracks

| Track | Feature | Status |
|---|---|---|
| (v0) | Elements, attributes, nested children, text, 5 standard entities | ✅ shipped |
| **T23** | `<![CDATA[ ... ]]>` / `<?processing-instructions?>` / `<!-- comments -->` / `<?xml ... ?>` declaration | ✅ **shipped 2026-05-07** |
| **T24** | Numeric character references `&#nnnn;` / `&#xHH;` (UTF-8 encoded) | ✅ **shipped 2026-05-07** |
| **T25** | Namespaces — `xmlns="..."` / `xmlns:prefix="..."` / `<prefix:tag>` resolution at the **element** level | ✅ **shipped 2026-05-07** |
| **T25b** | Attribute-namespace resolution + built-in `xml:` prefix | ✅ **shipped 2026-05-07** |
| **T27 v0** | Minimal XPath: paths, `[N]` predicates, `//` descendant axis | ✅ **shipped 2026-05-07** |
| **T27a** | XPath wildcards (`*`, `@*`) + attribute axis (`@attrName`) | ✅ **shipped 2026-05-07** |
| **T27b** | XPath functions (`position()`, `text()`, etc.) + comparison predicates | ✅ **shipped 2026-05-07** |
| **T26** | DTDs / DOCTYPE / custom entity declarations | queued |

Queued features land as v0.x.y patches when concrete consumers
drive them. The diagnostic in `lastError()` identifies the
offending token when the parser fails closed.

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

## Namespaces (T25)

XML Namespaces 1.0 element-level support:

```m
NEW doc
SET xml="<x:bookstore xmlns:x=""urn:books""><x:book/></x:bookstore>"
DO  SET rc=$$parse^STDXML(xml,.doc)
WRITE $$rootName^STDXML(.doc),!         ; "bookstore" (prefix stripped)
WRITE $$ns^STDXML(.doc),!               ; "urn:books"

NEW book
DO  IF $$childByName^STDXML(.doc,"book",.book) DO
. WRITE $$ns^STDXML(.book),!            ; "urn:books"  (inherited)
```

Behaviour:

- `xmlns="URI"` — declares a default namespace for this element and
  its descendants (until shadowed by a child's own xmlns).
- `xmlns:prefix="URI"` — declares a prefix binding for this element
  and its descendants (until shadowed).
- `<prefix:foo>` — element in the namespace bound to `prefix`.
  Resolution uses the namespace map in scope at the element's
  position. **An undeclared prefix is a parse error.**
- `xmlns` / `xmlns:*` declarations are **filtered out** of the
  regular attribute list — `$$attr^STDXML(.node,"xmlns")` returns
  `""` even when the source had an xmlns.
- `node("name")` always stores the **local** name (without prefix);
  `node("prefix")` preserves the original prefix for round-tripping;
  `node("ns")` holds the resolved URI.

### Attribute namespaces (T25b)

Per Namespaces 1.0 §6.2, the **default xmlns does NOT apply to
unprefixed attributes** — they always have no namespace,
regardless of any default declaration in scope. Only attributes
with an explicit prefix carry a namespace URI:

```m
NEW doc
SET xml="<foo xmlns=""urn:default"" xmlns:x=""urn:X"" id=""1"" x:role=""r""/>"
DO  SET rc=$$parse^STDXML(xml,.doc)
WRITE $$ns^STDXML(.doc),!                ; "urn:default"
WRITE $$attrNs^STDXML(.doc,"id"),!       ; ""  (unprefixed → no ns even though default xmlns is set)
WRITE $$attrNs^STDXML(.doc,"x:role"),!   ; "urn:X"  (prefixed → resolved)
```

The `xml:` prefix is bound to
`http://www.w3.org/XML/1998/namespace` as a **built-in** —
declared by definition, so `xml:lang`, `xml:space`, `xml:base`,
etc. work without any `xmlns:xml="..."` declaration:

```m
SET rc=$$parse^STDXML("<foo xml:lang=""en""/>",.doc)
WRITE $$attrNs^STDXML(.doc,"xml:lang"),! ; "http://www.w3.org/XML/1998/namespace"
```

Undeclared prefixes on attribute names are a parse error, just
like undeclared prefixes on element names.

## XPath subset

A deliberately narrow XPath 1.0 subset for the most common
ingestion patterns. Three public entry points:

```m
NEW doc,results,n
SET xml="<r><a id=""1""/><a id=""2""/><a id=""3""/></r>"
DO  SET rc=$$parse^STDXML(xml,.doc)

; Get all 'a' children
SET n=$$xpath^STDXML(.doc,"a",.results)
WRITE n,!                                ; 3

; Get the 2nd 'a' (1-based position predicate)
NEW out
DO  IF $$xpathOne^STDXML(.doc,"a[2]",.out) DO
. WRITE $$attr^STDXML(.out,"id"),!       ; "2"

; Wildcard — match any direct child regardless of name
SET n=$$xpath^STDXML(.doc,"*",.results)

; Find all descendants named 'x' anywhere in the tree
SET n=$$xpath^STDXML(.doc,"//x",.results)

; Attribute axis — return id values for every a child
SET n=$$xpath^STDXML(.doc,"a/@id",.results)
WRITE $get(results(1,"text")),!          ; "1"

; Quick text accessor: get the text of the first match
WRITE $$xpathText^STDXML(.doc,"/cfg/server/host"),!
```

Supported syntax:

| Construct | Example | Meaning |
|---|---|---|
| Bare name | `foo` | Direct children of the context node named `foo`. |
| Wildcard | `*` | Direct children regardless of name. |
| Chained path | `a/b/c` | Walk: c-children of b-children of a-children. |
| Absolute path | `/foo` | Match the root only if its name is `foo`. |
| Descendant axis | `//x` | All descendants named `x`, anywhere in the tree. |
| Position predicate | `name[N]` | Filter to the N-th match (1-based). |
| Attribute axis | `@attrName`, `*/@id`, `//@id` | Return attribute values from the candidate elements. Terminal — nothing may follow `@attr`. |
| Attribute wildcard | `@*` | All attributes on the candidate element(s). |
| Comparison predicate | `a[@id='2']`, `*[name()='b']`, `book[count(author)>1]` | Filter candidates by an expression. Operators: `=`, `!=`, `<`, `>`, `<=`, `>=`. |
| Function predicate | `a[contains(@class,'foo')]`, `a[starts-with(@id,'pre')]`, `a[normalize-space()='hi']`, `a[string-length(@id)>2]` | Filter via XPath 1.0 functions on the context. |
| Truthy attribute test | `a[@id]` | Keep candidates where `@id` is present and non-empty. |

Attribute matches surface in the result array as scalar-like
entries: `results(i,"text")` holds the attribute value and
`results(i,"name")` holds the attribute name. `xpathText` therefore
returns the attribute value transparently for `xpathText(.doc,"@id")`.

### Predicate expressions (T27b)

Predicates beyond `[N]` are parsed into a small AST (`parsePredExpr`)
and evaluated per candidate (`applyExprPredicate` →
`evalPredExpr`). The evaluator carries XPath-1.0-style type
coercion (`toBool` / `toStr` / `toNum`); ordering operators
(`<`, `>`, `<=`, `>=`) always coerce both sides to number, while
equality (`=`, `!=`) compares numerically when both sides are
numeric and otherwise as strings.

| Function | Form | Returns |
|---|---|---|
| `position()` | zero-arg | 1-based index of the candidate within the post-step set |
| `last()` | zero-arg | Size of the post-step set |
| `name()` | zero-arg | Local name of the candidate element |
| `text()` | zero-arg | Direct text content of the candidate element |
| `count(...)` | one arg: `name` / `*` / `@name` / `@*` | Count of children / attributes matching the relative-path arg |
| `string-length()` / `string-length(s)` | zero or one arg | Length of the context text or of the argument |
| `normalize-space()` / `normalize-space(s)` | zero or one arg | Whitespace-collapsed string (single internal spaces, trimmed) |
| `contains(haystack, needle)` | two args | Boolean substring test |
| `starts-with(haystack, prefix)` | two args | Boolean prefix test |
| `not(expr)` | one arg | Boolean negation |
| `string(expr)` / `number(expr)` | zero or one arg | Type coercion helpers |

`count()`'s argument is restricted to a single-step relative
path in v0 (`name` / `*` / `@name` / `@*`); full XPath sub-paths
inside `count(...)` are queued for a future ticket if a real
consumer drives the requirement.

Out of scope: **chained boolean operators (`and` / `or`)** and
**multiple predicates on the same step (`a[1][@id]`)**. Both can
be added incrementally if a consumer drives them.

### How it works

The expression is compiled into a step list (axis + name +
optional predicate). The evaluator carries the candidate set as
a list of "paths" — comma-separated child indices into the tree
(e.g., `"1,3,2"` for `tree("child",1,"child",3,"child",2)`).
Each step:

1. For each candidate path, walk the children matching the step's
   name (or recursively walk all descendants for `//`).
2. Append the new paths to the next-step set.
3. After all base-paths are processed, optionally apply the
   position predicate to the flat list.

When all steps have applied, each remaining path is
`merge`-ed into `results(idx)` to produce the final node-set.

The path-walk uses M's `@` indirection (`merge results(idx)=@ref`)
to dereference paths at runtime. Path strings are entirely
composed of internal loop counters from `for i=1:1:childCount`,
never from user-supplied data, so M-MOD-036 (tainted-local
indirection) is suppressed file-wide with a documented rationale.

## Engine portability

Pure-M throughout: `$extract` / `$length` / `$piece` / `$find` /
`$translate` / `$char` / `$query` / `$order` / `$data` / `@`
indirection. ANSI-standard, no `$Z*` extensions. Runs unchanged
on YDB and IRIS. The test suite is the conformance gate.

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

## History

Shipped incrementally across eight landings, each preserving 100%
backward compatibility.

- **v0** (`3d5df3a`, 2026-05-07): well-formed XML 1.0 elements,
  attributes, nested children, text content, the 5 standard entity
  references. Recursive-descent parser; tree shape mirrors STDJSON's
  caller-owned-tree convention. `childByName` does the internal
  `merge` to sidestep the YDB `.x(SUBS)` syntax limit.
- **T23 + T24** (`25a04d8`, 2026-05-07): comments / PI /
  `<?xml ?>` / CDATA + numeric character references (`&#NNN;`
  decimal, `&#xHH;` hex with UTF-8 encoding for any code point up to
  U+10FFFF). CDATA preserves `&` and `<` verbatim — exactly what
  HL7v3 / CDA narrative blocks need.
- **T25** (`bb169c1`, 2026-05-07): element-level namespaces.
  Per-element nsMap threaded through `parseElement` / `parseContent`;
  `xmlns` / `xmlns:prefix` filtered out of regular attrs; element
  prefix resolved to URI; `$$ns^STDXML(.node)` accessor; undeclared
  prefix is a parse error.
- **T25b** (`1f2c38f`, 2026-05-07): attribute-level namespaces.
  `resolveAttrNs` walks `node("attr",...)`; default xmlns does NOT
  apply to unprefixed attrs (per spec); `xml:` prefix bound to
  `http://www.w3.org/XML/1998/namespace` as a built-in;
  `$$attrNs^STDXML(.node, attrName)` accessor.
- **T27 v0**: XPath 1.0 v0 — bare `name`, chained `a/b/c`, absolute
  `/foo`, descendant `//x`, position predicate `[N]`. Public:
  `$$xpath` / `$$xpathOne` / `$$xpathText`.
- **T27a** (2026-05-07): wildcards (`*`) + attribute axis (`@attrName`).
  `*[N]`, `//*`, `*/x`, `@id`, `@*`, `a/@id`, `//@id`.
- **T27b** (2026-05-07): comparison predicates + functions.
  `[@id='v']` / `[name()='b']` / `[count(x)>1]`. Functions:
  `position()`, `last()`, `name()`, `text()`, `count()`,
  `string-length()`, `normalize-space()`, `contains()`,
  `starts-with()`, `not()`, `string()`, `number()`. Full XPath 1.0
  type coercion (`toBool` / `toStr` / `toNum`); ordering operators
  numeric-promote, equality is string-or-number.
- **T26** (2026-05-08): DOCTYPE + internal subset + `<!ENTITY>`
  custom entity declarations. Closes the 12-16d envelope.
  STDXMLTST 209/209 on engine. External `SYSTEM "url"` and `PUBLIC`
  declarations are tolerated but ignored — internal subsets only.
  Out of scope (queued behind real consumer): parameter entities
  (`%name;`), recursive expansion inside entity values, external
  DTD fetch.

Full envelope covered.
