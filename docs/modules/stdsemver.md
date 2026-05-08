---
module: STDSEMVER
tag: v0.3.0
phase: P4 wave
stable: stable
since: v0.3.0
synopsis: 'SemVer 2.0.0 parse / compare / range matching'
labels: ['build', 'compare', 'major', 'matches', 'minor', 'parse', 'patch', 'prerelease', 'valid']
errors: []
conformance: []
see_also: []
---

# `STDSEMVER` — SemVer 2.0.0

Parse, compare, and range-match Semantic Versioning 2.0.0 strings.
The architectural pretext for an eventual M package manager —
`m install foo@^1.2.3` needs SemVer arithmetic somewhere; this is
where it lives.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `valid` | `$$valid^STDSEMVER(s)` | `1` iff `s` is a valid SemVer 2.0.0 string. |
| `parse` | `$$parse^STDSEMVER(s, .v)` | Populates `v(1..5)` (major, minor, patch, prerelease, build); returns 1/0. |
| `major` | `$$major^STDSEMVER(s)` | Major component (integer); `""` if `s` is invalid. |
| `minor` | `$$minor^STDSEMVER(s)` | Minor component. |
| `patch` | `$$patch^STDSEMVER(s)` | Patch component. |
| `prerelease` | `$$prerelease^STDSEMVER(s)` | Prerelease tail (no leading `-`); `""` if absent. |
| `build` | `$$build^STDSEMVER(s)` | Build tail (no leading `+`); `""` if absent. |
| `compare` | `$$compare^STDSEMVER(a, b)` | `-1` / `0` / `1` per SemVer §11 precedence; `""` if either operand invalid. |
| `matches` | `$$matches^STDSEMVER(v, range)` | `1` iff `v` satisfies `range`. |

## Examples

```m
; predicate
WRITE $$valid^STDSEMVER("1.2.3"),!          ; 1
WRITE $$valid^STDSEMVER("01.2.3"),!         ; 0  (leading zero)
WRITE $$valid^STDSEMVER("1.2.3-rc.1+meta"),! ; 1

; parse into structured array
DO  SET rc=$$parse^STDSEMVER("1.2.3-rc.1+meta",.v)
WRITE v(1),"/",v(2),"/",v(3)," pre=",v(4)," build=",v(5),!
; -> 1/2/3 pre=rc.1 build=meta

; accessors
WRITE $$major^STDSEMVER("1.2.3"),!          ; 1
WRITE $$prerelease^STDSEMVER("1.0.0-rc.1+m"),! ; "rc.1"
WRITE $$build^STDSEMVER("1.0.0-rc.1+m"),!   ; "m"

; ordering
WRITE $$compare^STDSEMVER("1.0.0-rc.1","1.0.0"),! ; -1  (prerelease < release)
WRITE $$compare^STDSEMVER("2.0.0","1.99.99"),!    ; 1
WRITE $$compare^STDSEMVER("1.2.3+a","1.2.3+b"),!  ; 0   (build ignored)

; range matching
WRITE $$matches^STDSEMVER("1.5.0","^1.2.3"),!     ; 1   (>=1.2.3 <2.0.0)
WRITE $$matches^STDSEMVER("1.5.0","~1.2.3"),!     ; 0   (~ caps to <1.3.0)
WRITE $$matches^STDSEMVER("1.5.0",">=1.2.3 <2.0.0"),! ; 1
```

## Grammar

```
<version>     ::= <triple> ("-" <prerelease>)? ("+" <build>)?
<triple>      ::= <num> "." <num> "." <num>
<num>         ::= "0" | [1-9][0-9]*       ; no leading zeros except "0" itself
<prerelease>  ::= <pre-id> ("." <pre-id>)*
<pre-id>      ::= <num>                   ; numeric ID — no leading zeros
                | [0-9A-Za-z-]+           ; alphanumeric ID — at least one non-digit
<build>       ::= <build-id> ("." <build-id>)*
<build-id>    ::= [0-9A-Za-z-]+           ; numeric leading zeros OK in build
```

## Comparison rules (SemVer §11)

1. Compare major → minor → patch numerically. First mismatch decides.
2. If triples are equal, **build metadata is ignored.**
3. A version *with* a prerelease has lower precedence than the same
   version *without* (`1.0.0-rc.1 < 1.0.0`).
4. Two prereleases are compared identifier-by-identifier (split on `.`):
   - Numeric IDs compare **numerically** (`beta.2 < beta.11`).
   - Alphanumeric IDs compare **lexically** (string-collation via M's
     `]` operator).
   - **Numeric IDs are always lower than alphanumeric IDs**
     (`1.0.0-1 < 1.0.0-alpha`).
   - When the shared prefix is equal, the **longer** prerelease wins
     (`alpha < alpha.1`).

The full SemVer §11 ordering example is exercised end-to-end in
`tests/STDSEMVERTST.m:tCompareSpecExampleChain`:

```
1.0.0-alpha
  < 1.0.0-alpha.1
  < 1.0.0-alpha.beta
  < 1.0.0-beta
  < 1.0.0-beta.2
  < 1.0.0-beta.11
  < 1.0.0-rc.1
  < 1.0.0
```

## Range syntax

A subset of npm range expressions, intentionally narrow:

| Form | Meaning |
|---|---|
| `1.2.3` | Exact match (same as `=1.2.3`). |
| `=1.2.3` | Exact match. |
| `>1.2.3`, `>=1.2.3` | Strict / non-strict greater. |
| `<1.2.3`, `<=1.2.3` | Strict / non-strict less. |
| `^1.2.3` | Caret — `>=1.2.3 <2.0.0` (compatible major). |
| `~1.2.3` | Tilde — `>=1.2.3 <1.3.0` (compatible minor). |
| `>=1.2.3 <2.0.0` | Space-separated AND of comparators. |

Range forms **not** supported in v1 (queued for the next iteration):

- `||` (OR).
- Hyphen ranges (`1.2.3 - 2.3.4`).
- `*` / `x` / `X` placeholders.
- `^0.x.y` / `^0.0.x` zero-major narrowing (npm treats these specially;
  STDSEMVER v1 uses the simple rule `^0.x.y → >=0.x.y <1.0.0`).
- Prerelease-aware semantics (`>1.2.3-alpha` matching `1.2.3-beta`).

## Edge cases

- **Empty string is invalid.** `$$valid^STDSEMVER("")` returns `0`.
- **Empty `-` or `+` tail is invalid.** `1.0.0-` and `1.0.0+` both fail
  validation; the delimiter without an identifier list is malformed.
- **Leading `v` is rejected.** Strip it at the call site
  (`$EXTRACT(s,2,$LENGTH(s))`) — common shell-style wrappers like
  `git describe` emit `v1.2.3`.
- **`compare(a, b)` with invalid `a` or `b`** returns `""`, not `0`.
  Always pre-flight with `$$valid` if either side is user-supplied.
- **`matches` returns `0` for invalid `v`.** Same lenient-truthy
  contract as the rest of the predicates: an invalid version cannot
  match anything.

## No regex dependency

v1 is implemented purely via `$piece` / `$translate` / `$length` so it
ships without a runtime dep on STDREGEX. STDREGEX is listed as a
**soft** dependency in the tracker because a future regex-driven
implementation could shorten the validator, but the current code is
already concise enough that the dep wouldn't pay for itself.

## Engine portability

Pure-M, no `$Z*` extensions. Runs unchanged on YDB and IRIS. The
test suite (99 assertions across 33 labels) is the conformance gate.

## See also

- [`STDREGEX`](stdregex.md) — soft dep; not used in v1.
- The SemVer 2.0.0 spec: <https://semver.org/spec/v2.0.0.html>.
- Full §11 ordering example: `tests/STDSEMVERTST.m:tCompareSpecExampleChain`.
