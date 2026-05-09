#!/usr/bin/env bash
# Idempotent m-cli + tree-sitter-m install into vehu's home venv.
# Runs once per container creation. Survives container restart;
# re-runs (and is idempotent) on container recreate.
set -euo pipefail

VENV=/home/vehu/.venv
M_BIN="$VENV/bin/m"

if [ -x "$M_BIN" ] && "$M_BIN" --version >/dev/null 2>&1; then
    echo "[install-m-cli] already installed: $($M_BIN --version)"
    exit 0
fi

# python3.12-dev is needed to compile tree-sitter-m's C extension
# (Python.h). vista-meta:latest ships build-essential but not -dev.
if ! dpkg -s python3.12-dev >/dev/null 2>&1; then
    echo "[install-m-cli] installing python3.12-dev"
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends python3.12-dev
fi

cd /home/vehu

if [ ! -d tree-sitter-m ]; then
    git clone https://github.com/m-dev-tools/tree-sitter-m
fi
if [ ! -d m-cli ]; then
    git clone https://github.com/m-dev-tools/m-cli
fi

python3.12 -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install ./tree-sitter-m
"$VENV/bin/pip" install -e "./m-cli[lsp]"

echo "[install-m-cli] installed: $($M_BIN --version)"
