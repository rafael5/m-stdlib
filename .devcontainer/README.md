# m-stdlib devcontainer — attaches to vista-vehu

This devcontainer **does not build its own image**. It attaches to the
shared `vista-vehu` container — the YottaDB + VistA dev engine owned
by `~/projects/vista-meta/` — so m-stdlib develops against the real
VistA + YottaDB engine: full `/opt/VistA-M`, `vehu` user,
`/home/vehu/g` globals volume, all of it.

## How it works

- `docker-compose.yml` `extends:` the master compose file at
  `~/projects/vista-meta/docker/compose.yml` (single source of truth)
  and adds only the m-stdlib bind mount. All ports, volumes, hostname,
  and lifecycle policy come from the master.
- `devcontainer.json` uses `dockerComposeFile` mode and tells VS Code
  to land in the `vista-vehu` service container as user `vehu`, with
  the m-stdlib repo mounted at `/home/vehu/work/m-stdlib`.
- `install-m-cli.sh` runs as `postCreateCommand` and installs `m-cli`
  + `tree-sitter-m` into `/home/vehu/.venv` inside the container.
  Idempotent; safe to re-run.
- `shutdownAction: none` keeps the container alive when VS Code closes,
  matching the long-lived shared-engine model.

## Workflow

The `vista-vehu` container is **shared** between vista-meta's Makefile
and any client devcontainer (m-stdlib, m-cli, m-tools, …). Both routes
target the same container name and the same `vehu-globals` volume —
but they cannot run simultaneously. Pick one:

- **Editing M code in m-stdlib via VS Code devcontainer:** open this
  folder, run "Reopen in Container". VS Code now owns the lifecycle.
  If `make run` had created the container previously, run
  `cd ~/projects/vista-meta && make rm` first to release the name.
- **Vista-meta-side work (bake, snapshots, pkg/context CLI):** close
  VS Code's devcontainer (or `Dev Containers: Stop Container`), then
  `cd ~/projects/vista-meta && make run`.

`make rm` and "Reopen in Container" are interchangeable — only one at
a time.

## Prerequisites

- `vista-meta:latest` image built (`cd ~/projects/vista-meta && make build`).
- `~/projects/vista-meta/` checked out at the same parent directory as
  `~/projects/m-stdlib/` (the master compose's bind paths are relative
  to `vista-meta/docker/`).
- `vehu-globals` volume — auto-created by compose on first up.

## Files

| File | Purpose |
|---|---|
| `devcontainer.json` | VS Code dev-container config, points at the `vista-vehu` service |
| `docker-compose.yml` | Thin overlay that `extends:` `vista-meta/docker/compose.yml` and adds the m-stdlib bind mount |
| `install-m-cli.sh` | `postCreateCommand` — installs m-cli inside container |
| `Dockerfile` | **Orphaned.** Pre-attach standalone-yottadb path. Kept for reference; unreferenced by `devcontainer.json`. Safe to delete. |
