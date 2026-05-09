# Pinned to yottadb/yottadb-base:latest-master per Phase 0 §6.0 verification
# (2026-04-30). At pin time: YottaDB r2.07, Linux x86_64. The image installs
# YottaDB at /opt/yottadb/current with /opt/yottadb/current/ydb_env_set as
# the env-bootstrap script (sets PATH, ydb_dist, etc).
#
# Alternatives considered:
#  - yottadb/yottadb        (untagged, drift risk)
#  - yottadb/yottadb:r2.02  (older release line)
# Picked latest-master because it tracks active development and is what
# upstream points new users at.
FROM yottadb/yottadb-base:latest-master

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.12 python3.12-venv python3.12-dev python3-pip git build-essential \
        libssl-dev libcurl4-openssl-dev libsodium-dev zlib1g-dev libpcre2-dev \
        bash make ca-certificates curl gnupg \
    && rm -rf /var/lib/apt/lists/*

# m-cli installed from git checkout. Distribution model is git-clone-and-install
# (no package registry).
#
# tree-sitter-m must be installed first: m-cli declares it as a dep, and the
# `[tool.uv.sources]` redirect in m-cli/pyproject.toml is uv-only — pip needs
# the local checkout already satisfied in the env before resolving m-cli.
RUN git clone https://github.com/m-dev-tools/tree-sitter-m /opt/tree-sitter-m && \
    git clone https://github.com/m-dev-tools/m-cli /opt/m-cli && \
    python3.12 -m venv /opt/m-cli/.venv && \
    /opt/m-cli/.venv/bin/pip install --upgrade pip && \
    /opt/m-cli/.venv/bin/pip install /opt/tree-sitter-m && \
    /opt/m-cli/.venv/bin/pip install -e "/opt/m-cli[lsp]"

# Node 20 + Claude Code CLI. NodeSource ships a current Node that's
# compatible with @anthropic-ai/claude-code's engine requirement (>=18).
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g @anthropic-ai/claude-code

# Non-root user already exists in the base image (ubuntu, uid 1000).
USER ubuntu
WORKDIR /workspaces/m-stdlib

# Defensive YDB env bootstrap.
#
# `ydb_env_set` falls back to creating /data/r when ydb_dir is unset
# (or points to a non-existent path), which fails as the unprivileged
# `ubuntu` user. devcontainer.json's containerEnv supplies ydb_dir for
# the VS Code-spawned shell, but `docker exec` and SSH sessions don't
# inherit it — so we set a sensible default here, mkdir it, and only
# then source the env script.
RUN cat >> /home/ubuntu/.bashrc <<'EOF'

# --- YottaDB env (added by devcontainer Dockerfile) ---
if [ -z "${ydb_dir:-}" ]; then
    if [ -d /workspaces/m-stdlib ]; then
        export ydb_dir=/workspaces/m-stdlib/.ydb
    elif [ -d /workspace ]; then
        export ydb_dir=/workspace/.ydb
    else
        export ydb_dir="$HOME/.ydb"
    fi
fi
mkdir -p "$ydb_dir"
. /opt/yottadb/current/ydb_env_set >/dev/null 2>&1 || true
export PATH="/opt/m-cli/.venv/bin:$PATH"
EOF
