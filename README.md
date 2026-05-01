# m-stdlib

Pure-M (and selectively `$ZF`-bound) runtime library that fills the
highest-impact gaps in the M standard library. Sibling project to
[m-cli](https://github.com/rafael5/m-cli),
[m-standard](https://github.com/rafael5/m-standard), and
[tree-sitter-m](https://github.com/rafael5/tree-sitter-m).

YottaDB-first; IRIS portable where reasonable.

## What's planned

- **Phase 1 — pure-M quick wins.** STDASSERT, STDUUID, STDB64, STDHEX,
  STDFMT, STDLOG, STDDATE, STDCSV, STDARGS. Ships as `v0.1.0`.
- **Phase 2 — pure-M heavy lifting.** STDJSON, STDREGEX, STDCOLL,
  STDURL. Ships as `v0.2.0`.
- **Phase 3 — host-call integrations.** STDHTTP, STDCRYPTO,
  STDCOMPRESS (via `$ZF`). Ships as `v0.3.0`.
- **`v1.0.0`** once the API has been stable for 3 months.

See [`docs/m-stdlib-implementation-plan.md`](docs/m-stdlib-implementation-plan.md)
for the live, continuously updated work plan.

## Install (development checkout)

```bash
git clone https://github.com/rafael5/m-stdlib ~/projects/m-stdlib
cd ~/projects/m-stdlib
make setup-ydb     # one-time YDB workspace bootstrap
make check         # fmt-check + lint + test + coverage
```

Requires:

- YottaDB (`/usr/local/lib/yottadb/r*` on Linux Mint / Debian-based
  systems — install per <https://yottadb.com/product/get-started/>).
- [m-cli](https://github.com/rafael5/m-cli) installed in a venv at
  `~/projects/m-cli/.venv` (or override `M=` on the make command line).

## Install (devcontainer)

Open the project in VS Code with the **Dev Containers** extension and
choose *Reopen in Container*. Everything (YottaDB r2.07, m-cli, the
M LSP) is wired up automatically.

## Install (downstream M project)

Until an M package manager exists, downstream projects vendor m-stdlib
as a git submodule and add `src/` to their `ydb_routines`:

```bash
git submodule add https://github.com/rafael5/m-stdlib third_party/m-stdlib
export ydb_routines="$PWD/routines $PWD/third_party/m-stdlib/src $ydb_dist"
```

## License

[AGPL-3.0](LICENSE). Family-wide consistency with m-cli, m-standard,
and tree-sitter-m.

## Conventions

- All public routines use the `STD` prefix (reserved family-wide).
- Test suites use the `*TST.m` suffix and the
  `t<UpperCase>(pass,fail)` label convention recognised by `m test`.
- Per-process state lives under `^STDLIB($J,...)`; shared config under
  `^STDLIBC(...)`.

## Status

See [`docs/m-stdlib-implementation-plan.md`](docs/m-stdlib-implementation-plan.md)
§1 — Current state.
