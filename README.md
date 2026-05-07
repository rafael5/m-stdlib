# m-stdlib

Pure-M (and selectively `$ZF`-bound) runtime library that fills the
highest-impact gaps in M's standard library — assertions, UUIDs,
base64/hex, formatting, structured logging, datetime, CSV, argparse,
fixtures, mocks, seed loaders, JSON, regex, collections, URLs.

Sibling project to [m-cli](https://github.com/rafael5/m-cli) (the
toolchain), [m-standard](https://github.com/rafael5/m-standard) (the
modern-M style guide), and
[tree-sitter-m](https://github.com/rafael5/tree-sitter-m) (the parser).

YottaDB-first; IRIS-portable where reasonable.

## Status

- **`v0.1.0` shipped** (2026-05-05): Phase 1 — 9 modules covering the
  pure-M quick wins (STDASSERT, STDUUID, STDB64, STDHEX, STDFMT,
  STDLOG, STDDATE, STDCSV, STDARGS).
- **Phase 1b on `main`, awaiting batch tag** (`v0.1.1`–`v0.1.3`):
  STDFIX, STDMOCK, STDSEED — the TDD primitives that power per-test
  isolation, call interception, and FileMan fixture loading.
- **Phase 2 substance on `main`, awaiting `v0.2.0` tag**: STDJSON,
  STDREGEX, STDCOLL, STDURL — pure-M heavy lifting.
- 16 modules total. 800+ assertions across the suites; per-module
  label coverage ≥ 95 % (most at 100 %); 0 lint errors; `m fmt` clean.
- Phase 3 (`STDHTTP`, `STDCRYPTO`, `STDCOMPRESS` via `$ZF`) is
  designed but not yet implemented.

Live dispatch board: [`docs/parallel-tracks.md`](docs/parallel-tracks.md).
Genesis and evolution: see [§ Further reading](#further-reading).

## What it's for

- A **canonical, RFC-anchored answer** to the recurring small-library
  questions in M — so each shop stops re-implementing base64, JSON,
  UUIDs, and date arithmetic in a private `^XB*` / `^%Z*` routine.
- A **TDD-first runtime substrate** — every module ships with a
  conformance-grade test suite (RFC-4648 / RFC-4180 / RFC-8259 /
  RFC-3986 / RFC-4122 / RFC-9562 vectors vendored where they exist).
- A **CI/CD-friendly substrate** — `make ci` runs `m fmt --check`,
  `m lint --error-on=error`, `m test --format=tap`, and
  `m coverage --min-percent=85` against a shared YottaDB container
  with no host install required.
- **A non-framework**. No global registries, no init hooks, no DI.
  Each module is a flat M routine; you `do`-call or `$$`-call its
  public labels.

## Module inventory

| # | Module | Tag | Purpose |
|---|---|---|---|
| 1 | [`STDASSERT`](docs/modules/stdassert.md) | `v0.0.1` | Assertion library — `eq` / `ne` / `true` / `false` / `near` / `raises` / `contains` / `len` + `start` / `report`. Wire-protocol-compatible with m-cli's runner. |
| 2 | [`STDUUID`](docs/modules/stduuid.md)   | `v0.0.1` | RFC-4122 v4 + RFC-9562 v7 UUIDs. v7 sorts in generation order under M collation. |
| 3 | [`STDB64`](docs/modules/stdb64.md)     | `v0.0.2` | RFC-4648 Base64 — standard `+ /` and URL-safe `- _` alphabets. |
| 4 | [`STDHEX`](docs/modules/stdhex.md)     | `v0.0.2` | RFC-4648 §8 hex — lowercase default + uppercase variant. |
| 5 | [`STDFMT`](docs/modules/stdfmt.md)     | `v0.0.3` | Printf-style formatter — subset of Python `str.format`. |
| 6 | [`STDLOG`](docs/modules/stdlog.md)     | `v0.0.4` | Structured `key=value` logger — five levels, four sinks. |
| 7 | [`STDDATE`](docs/modules/stddate.md)   | `v0.0.5` | ISO-8601 datetime + duration arithmetic over proleptic Gregorian. |
| 8 | [`STDCSV`](docs/modules/stdcsv.md)     | `v0.0.6` | RFC-4180 CSV parser/writer with optional file I/O. |
| 9 | [`STDARGS`](docs/modules/stdargs.md)   | `v0.0.7` | argparse — long/short/grouped flags, positionals, sub-commands. |
| 10 | [`STDFIX`](docs/modules/stdfix.md)    | `v0.1.1` (pending tag) | Fixture lifecycle — `with` / `invoke` transactional scope. |
| 11 | [`STDMOCK`](docs/modules/stdmock.md)  | `v0.1.2` (pending tag) | Opt-in test-time call interception. |
| 12 | [`STDSEED`](docs/modules/stdseed.md)  | `v0.1.3` (pending tag) | Declarative TSV manifest loader for FileMan record fixtures. |
| 13 | [`STDJSON`](docs/modules/stdjson.md)  | `v0.2.0` (pending tag) | RFC-8259 JSON parser + serialiser. |
| 14 | [`STDREGEX`](docs/modules/stdregex.md)| `v0.2.0` (pending tag) | Thompson-NFA regex engine — full subset (literals, classes, groups, alternation, greedy quantifiers, capture, replace, split). |
| 15 | [`STDCOLL`](docs/modules/stdcoll.md)  | `v0.2.0` (pending tag) | Collections — Set / Map / Stack / Queue / Deque / Heap / OrderedDict over caller-owned arrays. |
| 16 | [`STDURL`](docs/modules/stdurl.md)    | `v0.2.0` (pending tag) | RFC-3986 URI parse / build / encode / decode / normalize / resolve. |

Canonical module index: [`docs/modules/index.md`](docs/modules/index.md).
Per-module API surface: each row's linked page.

## Where it fits in the M development lifecycle

```
   write tests          implement        format/lint        run + cover
       │                   │                  │                │
       ▼                   ▼                  ▼                ▼
   STDASSERT           STDFMT etc.         m fmt              m test
   STDFIX              (your code)         m lint             m coverage
   STDMOCK                                                    │
   STDSEED                                                    │
                                                              ▼
                                                      vista-meta YDB
                                                      (shared engine)
```

| Stage | What you reach for in m-stdlib |
|---|---|
| **TDD red** | `STDASSERT` — `start` / `eq` / `ne` / `true` / `near` / `raises` / `contains` / `len` / `report`. The `*TST.m` convention `m test` discovers expects this API. |
| **TDD green** | The runtime utility you'd otherwise have to write — `STDFMT` for formatting, `STDDATE` for time, `STDLOG` for diagnostics, `STDCSV` for ingest, `STDARGS` for CLI front-ends, `STDJSON` for serialisation, `STDREGEX` for parsing, `STDCOLL` for data structures, `STDURL` for routing, `STDB64`/`STDHEX`/`STDUUID` for IDs and encodings. |
| **Test infrastructure** | `STDFIX` (per-test transactional rollback — wired by default into `m test`'s isolation), `STDMOCK` (test-time call interception), `STDSEED` (FileMan fixture loader). |
| **CI gate** | `make check` / `make ci` enforces fmt + lint + test + coverage minimums against your m-stdlib-using code. |

The library is what makes a TDD discipline mechanically enforceable in
M. Without `STDASSERT` there is no `m test` runner protocol; without
`STDFIX` per-test isolation costs ~5 lines of `tstart` / `trollback`
boilerplate per test; without `STDMOCK` there is no way to assert
"this routine was called with these arguments" without intrusive
production-side scaffolding.

## Where it could fit in VistA package development

A new VistA package built TDD-first — see
[`~/projects/py-kids-install/docs/new-vista-package-lifecycle.md`](../py-kids-install/docs/new-vista-package-lifecycle.md)
— uses m-stdlib in two distinct ways:

1. **At test time, always.** `tests/<RTN>TST.m` calls
   `do start^STDASSERT(.pass,.fail)` … `do report^STDASSERT(...)`.
   Tests are not shipped in the `.KID`, so STDASSERT et al. only need
   to exist on the developer's vista-meta engine. This is the supported
   path today; nothing more is needed.
2. **At runtime, when wanted** — currently a manual choice. Two
   options:
   - **Vendor only what you need**: copy `STDDATE.m` (or whichever
     module) into your package's namespace and rename it (e.g.
     `MYPKGDATE.m`), shipping it inside your `.KID`. This keeps your
     namespace clean and avoids a runtime dependency on a separate
     m-stdlib KIDS build.
   - **Ship m-stdlib as its own VistA package** (`STD` namespace, file
     `#9.4` PACKAGE record, KIDS build). This is gap **G7** in the
     lifecycle proposal — once shipped, downstream VistA packages can
     declare `M-STDLIB 1.0` as a required build under `BUILD/4/` and
     call STDDATE/STDFMT/STDREGEX/etc. at runtime without copying.

Until G7 lands, treat m-stdlib as a **dev-time / test-time** dependency
for VistA packages, not a runtime one. Production VistA code stays in
its own namespace and uses VA Kernel utilities (`^XLF*`, `^DI*`) for
cross-cutting needs the same way the rest of VistA does.

## Install (development checkout)

```bash
git clone https://github.com/rafael5/m-stdlib ~/projects/m-stdlib
cd ~/projects/m-stdlib
make seed                  # one-time YDB workspace bootstrap (vista-meta engine)
make check                 # fmt-check + lint + test
make coverage              # line + label coverage; LCOV at coverage.lcov
make ci                    # release-readiness gate (check + JUnit XML + min-percent)
```

Requires:

- [m-cli](https://github.com/rafael5/m-cli) installed at
  `~/projects/m-cli/.venv` (or override `M=` on the make command line).
- The shared **vista-meta** YottaDB container reachable per
  `~/data/vista-meta/conn.env`. Tests run remotely over SSH — there is
  no host YDB install to manage.
- For Phase 3 host-callout work only:
  [YottaDB](https://yottadb.com/product/get-started/) header files +
  a C toolchain. `tools/build-callouts.sh` produces per-platform
  shared objects in `so/`.

## Install (devcontainer)

Open the project in VS Code with the **Dev Containers** extension and
choose *Reopen in Container*. YottaDB r2.07, m-cli, and the M LSP are
all wired automatically.

## Install (downstream M project)

Until an M package manager exists, downstream projects vendor m-stdlib
as a git submodule and add `src/` to `ydb_routines`:

```bash
git submodule add https://github.com/rafael5/m-stdlib third_party/m-stdlib
export ydb_routines="$PWD/routines $PWD/third_party/m-stdlib/src $ydb_dist"
```

For a project using m-cli's seed/unseed scripts, point the seed at the
submodule's `src/` so STDASSERT loads alongside your routines.

## Conventions

- All public routines use the `STD` prefix (reserved family-wide).
- Test suites use the `*TST.m` suffix and the `t<UpperCase>(pass,fail)`
  label convention recognised by `m test`.
- Per-process state lives under `^STDLIB($job,...)`; shared config
  under `^STDLIBC(...)`. No module writes outside these globals at
  runtime.
- Modern (pythonic-lower) style — lowercase keywords, full canonical
  spellings, one command per line. Enforced by
  [`m-cli`](https://github.com/rafael5/m-cli) under the `pythonic`
  lint profile.
- Per-module §9 acceptance gate before any `vN.N.N` tag: fmt clean,
  0 lint errors, 100 % test pass, ≥ 85 % label coverage.

## License

[AGPL-3.0](LICENSE). Family-wide consistency with m-cli, m-standard,
and tree-sitter-m.

## Further reading

The README is the *current state*. For genesis, evolution, and the
deeper why, walk the docs in this order:

| Doc | Read it for |
|---|---|
| [`docs/users-guide.md`](docs/users-guide.md) | The 562-line orientation — TDD philosophy, CI/CD chain, every module in five-minute slices, roadmap. |
| [`docs/m-stdlib-implementation-plan.md`](docs/m-stdlib-implementation-plan.md) | The live, continuously updated work plan — per-module specs (§§ 8.1–8.16), §10 release sequencing, §11 locked decisions. |
| [`docs/parallel-tracks.md`](docs/parallel-tracks.md) | Dispatch board — every track L1–L14, m-cli companion tracks C1–C6 + W/X/Y, conformance corpora A1–A7, status snapshot, sync points. |
| [`docs/tdd-orchestration-plan.md`](docs/tdd-orchestration-plan.md) | Milestone narrative for the m-stdlib ↔ m-cli joint cadence (M0–M5). |
| [`docs/m-libraries-remediation.md`](docs/m-libraries-remediation.md) | The original survey of which gaps exist in M's stdlib and why. |
| [`docs/modules/index.md`](docs/modules/index.md) | Canonical per-module index with conformance-corpus pointers. |
| [`docs/realcode-validation.md`](docs/realcode-validation.md) | Findings from running the toolchain against `m-modern-corpus` — what shipped corpora bend toward needing. |
| [`docs/modern-m-corpus-test-results.md`](docs/modern-m-corpus-test-results.md) | Library-fit findings — concrete LOC reductions in real projects (e.g. `_zewdJSON.m`'s 833 LOC → STDJSON ~50). |
| [`docs/vista-corpus-lint-results.md`](docs/vista-corpus-lint-results.md) | Lint results against the VistA M corpus, calibrating the `pythonic` profile against legacy code. |
| [`TOOLCHAIN-FINDINGS.md`](TOOLCHAIN-FINDINGS.md) | Open and resolved m-cli / YDB regressions discovered while building m-stdlib. |
| [`CHANGELOG.md`](CHANGELOG.md) | Per-tag release notes. |

For where m-stdlib fits a new VistA package end-to-end:
[`~/projects/py-kids-install/docs/new-vista-package-lifecycle.md`](../py-kids-install/docs/new-vista-package-lifecycle.md).
