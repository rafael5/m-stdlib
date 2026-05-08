---
module: STDDATE
tag: v0.0.5
phase: Phase 1
stable: stable
since: v0.0.5
synopsis: 'ISO-8601 datetime + arithmetic (v0.0.5)'
labels: ['add', 'civilFromDays', 'civilToDays', 'dayOfYear', 'daysInMonth', 'diff', 'fmtDate', 'fmtTime', 'fmtTzColon', 'fmtTzCompact', 'fromh', 'isLeap', 'now', 'padL', 'parseFrac', 'parseTz', 'strftime', 'strptime', 'toh', 'validDate']
errors: []
conformance: []
see_also: ['STDLOG']
---

# `STDDATE` — ISO-8601 datetime + duration arithmetic

ISO-8601 date/time formatting and parsing, plus calendar
arithmetic over the proleptic Gregorian calendar. M's `$HOROLOG`
is the canonical internal form; ISO-8601 strings are the wire form.

## Public API

| Extrinsic | Signature | Returns |
|---|---|---|
| `now` | `$$now^STDDATE()` | Current UTC as `YYYY-MM-DDTHH:MM:SS.sssZ` (ms precision). |
| `fromh` | `$$fromh^STDDATE(h)` | ISO-8601 string for a 2/3/4-piece horolog. |
| `toh` | `$$toh^STDDATE(iso)` | Horolog form (2/3/4-piece) parsed from ISO-8601. |
| `strftime` | `$$strftime^STDDATE(h,fmt)` | Format `h` per `fmt` directives. |
| `strptime` | `$$strptime^STDDATE(text,fmt)` | Parse `text` per `fmt` into a horolog. |
| `add` | `$$add^STDDATE(h,dur)` | `h` plus an ISO-8601 duration. |
| `diff` | `$$diff^STDDATE(h1,h2)` | `h2 − h1` as an ISO-8601 duration. |

## Horolog forms

| Pieces | Meaning | Example |
|---|---|---|
| 2 | `D,S` — `$HOROLOG` proper. | `47117,3661` |
| 3 | `D,S,U` — adds microseconds. | `47117,0,123456` |
| 4 | `D,S,U,T` — adds tz offset in seconds. | `47117,0,0,18000` |

`D` is days since `1840-12-31` (M's `$HOROLOG` epoch — Unix epoch is
day **47117**). `S` is seconds-into-day (0 − 86399). `U` is
microseconds. `T` is tz offset east of UTC, in seconds.

## ISO-8601 forms accepted by `toh`

- `YYYY-MM-DD` → 2-piece `D,0`.
- `YYYY-MM-DDTHH:MM:SS` → 2-piece `D,S` (wall-clock; no offset).
- `YYYY-MM-DDTHH:MM:SS.SSS` / `.SSSSSS` → 3-piece `D,S,U`.
- `YYYY-MM-DDTHH:MM:SSZ` → 4-piece `D,S,0,0`.
- `YYYY-MM-DDTHH:MM:SS+HH:MM` / `-HH:MM` → 4-piece `D,S,0,T`.
- Sub-second + tz combine into 4-piece `D,S,U,T`.

`fromh` is the exact inverse: 2-piece in → no fraction, no tz; 3-piece
in (with `U > 0`) → `.uuuuuu`; 4-piece in → tz suffix (`Z` if `T = 0`,
otherwise `±HH:MM`).

## strftime / strptime directives

| Directive | Meaning |
|---|---|
| `%Y` | 4-digit year. |
| `%m` | 2-digit month (01 − 12). |
| `%d` | 2-digit day-of-month (01 − 31). |
| `%H` | 2-digit hour-of-day (00 − 23). |
| `%M` | 2-digit minute (00 − 59). |
| `%S` | 2-digit second (00 − 59). |
| `%j` | 3-digit day-of-year (001 − 366). `strftime` only. |
| `%z` | `+HHMM` / `-HHMM` (no colon). Empty string when the horolog has < 4 pieces. `strftime` only. |
| `%%` | Literal `%`. |

Unknown directives in `strftime` pass through as `%X` literally.

## Examples

```m
; current UTC
WRITE $$now^STDDATE(),!                        ; 2026-05-05T17:42:31.123Z

; horolog round-trip
SET h="47117,3661"
WRITE $$fromh^STDDATE(h),!                     ; 1970-01-01T01:01:01
WRITE $$toh^STDDATE($$fromh^STDDATE(h)),!      ; 47117,3661

; format the current date
SET nowH=$ZHOROLOG
WRITE $$strftime^STDDATE(nowH,"%Y-%m-%d"),!    ; e.g. "2026-05-05"

; +1 day, +2h30m
WRITE $$add^STDDATE("47117,0","P1DT2H30M"),!   ; 47118,9000

; difference between two horologs
WRITE $$diff^STDDATE("47117,0","47117,3661"),! ; PT1H1M1S

; Feb-29 → Feb-28 clamp on +P1Y
WRITE $$add^STDDATE($$toh^STDDATE("2024-02-29"),"P1Y"),!
                                               ; same as $$toh^STDDATE("2025-02-28")
```

## Calendar

Proleptic Gregorian. The civil-↔-day-count conversion uses
[Howard Hinnant's `days_from_civil` algorithm][hinnant], which is
well-defined for any year (negative years → BCE).

[hinnant]: https://howardhinnant.github.io/date_algorithms.html

Verified against the leap-year rule for years 1900 (not leap),
2000 (leap), 2024 (leap), 2400 (leap).

## ISO-8601 durations (`add` / `diff`)

`add` accepts `[-]P[nY][nM][nW][nD][T[nH][nM][nS]]`:

- `Y M W D` apply before `T`; `H M S` apply after.
- `M` before `T` is months, `M` after `T` is minutes (per ISO-8601).
- The leading `-` flips all components — `-P1D` subtracts a day.
- Calendar arithmetic for `Y` and `M` clamps the day-of-month if the
  target month is shorter (`2024-02-29 + P1Y → 2025-02-28`,
  matching Python's `dateutil.relativedelta`).
- `W` and `D` are raw day arithmetic.
- `H M S` are raw second arithmetic, with day-carry into `D`.

`diff` always emits the `PnDTnHnMnS` form (no `Y` / `M` since those
are variable-length); `PT0S` for zero; `-P...` prefix for negative.

## Errors

`STDDATE` sets `$ECODE` for malformed input:

| Code | When |
|---|---|
| `,U-STDDATE-BAD-HOROLOG,` | `fromh` / `strftime` / `add` got a horolog with `< 2` or `> 4` pieces. |
| `,U-STDDATE-BAD-ISO,` | `toh` / `strptime` got a string that does not match the documented form, or parses to an invalid civil date (e.g. `2026-02-30`, `1900-02-29`, `2026-13-01`). |
| `,U-STDDATE-BAD-DUR,` | `add` got a duration that does not match `[-]P[nY][nM][nW][nD][T[nH][nM][nS]]`. |

Production code that calls `STDDATE` and wants to recover from
malformed input must wrap the call under `$ETRAP` and inspect
`$ECODE`. The `t*Rejects*` / `t*Raises*` test labels in
[`tests/STDDATETST.m`](../../tests/STDDATETST.m) document the
expected error codes per input shape; they are present in the file
but are **not currently dispatched** because `STDASSERT.raises`
cannot handle `$ECODE` raised inside an extrinsic chain. Re-enable
once that is fixed (see [`TOOLCHAIN-FINDINGS.md`](../tracking/TOOLCHAIN-FINDINGS.md)).

## Engine portability

`now` reads `$ZHOROLOG` (YDB-specific); the `unixMs`-style
microsecond + tzoff pieces come from there. An IRIS arm using
`$ZTIMESTAMP` is a follow-on; the lint suppression directive
`; m-lint: disable-next-line=M-MOD-022` documents the YDB-only
dependency at the call site.

The civil-↔-day-count helpers, format/parse, and duration
arithmetic are pure-M and run unchanged on IRIS.

## Replaces

`STDLOG`'s inline ISO-8601 timestamp helper from `v0.0.4`. Track
**L4b** (per [`docs/parallel-tracks.md`](../tracking/parallel-tracks.md))
bumps `STDLOG` to use `$$now^STDDATE()` once both modules merge.

## See also

- [`STDLOG`](stdlog.md) — consumer of `now()` from L4b onward.
- ISO 8601 — date/time format spec.
- [Howard Hinnant — `chrono`-Compatible Low-Level Date Algorithms][hinnant]
  — the civil-↔-day algorithm used internally.
- Implementation plan §8.7 — the API spec.
