#!/usr/bin/env bash
# Build + deploy m-stdlib's $ZF callouts (STDCRYPTO / STDCOMPRESS / STDHTTP)
# into the shared vista-meta container.
#
# Phase 1 — push src/callouts/*.c into the container and run gcc against
#           libyottadb.h there, so output ABI matches the YDB runtime.
# Phase 2 — stage so/$PLATFORM/*.so + tools/std_*.xc under
#           ~/export/seed/m-stdlib/{lib,xc}/.
# Phase 3 — idempotently append STDLIB_LIB + ydb_xc_* exports to
#           /etc/profile.d/ydb_env.sh inside a marker block (sudo -n),
#           so every `m test` SSH session inherits them.
#
# Closes T28 (STDCRYPTO/STDCOMPRESS deploy) + T29 (STDHTTP iter 2 deploy)
# in docs/module-tracker.md.
set -euo pipefail

PROJECT="m-stdlib"
PLATFORM="${PLATFORM:-linux-x86_64}"

CONN="${VISTA_CONN_FILE:-$HOME/data/vista-meta/conn.env}"
[ -f "$CONN" ] || { echo "[$PROJECT/callouts] no conn file: $CONN — is vista-meta running?"; exit 1; }
# shellcheck disable=SC1090
source "$CONN"

ssh_v() {
  ssh -p "$VISTA_SSH_PORT" -o StrictHostKeyChecking=no -o BatchMode=yes \
      "$VISTA_SSH_USER@$VISTA_HOST" "$@"
}
scp_v() {
  scp -O -P "$VISTA_SSH_PORT" -o StrictHostKeyChecking=no -o BatchMode=yes "$@"
}

ssh_v 'true' >/dev/null 2>&1 || {
  echo "[$PROJECT/callouts] cannot reach $VISTA_SSH_USER@$VISTA_HOST:$VISTA_SSH_PORT"
  exit 1
}

# ── enumerate callout sources ─────────────────────────────────────────
shopt -s nullglob
C_SOURCES=(src/callouts/*.c)
XC_FILES=(tools/std_*.xc)
shopt -u nullglob

if [ "${#C_SOURCES[@]}" -eq 0 ]; then
  echo "[$PROJECT/callouts] no .c sources to build — skipping"
  exit 0
fi

echo "[$PROJECT/callouts] deploying ${#C_SOURCES[@]} callout(s) + ${#XC_FILES[@]} descriptor(s) to $VISTA_HOST:$VISTA_SSH_PORT"

# ── stage layout ──────────────────────────────────────────────────────
STAGE="\$HOME/export/seed/$PROJECT"
BUILD="$STAGE/build"
LIB="$STAGE/lib/$PLATFORM"
XC="$STAGE/xc"

ssh_v "
  set -euo pipefail
  mkdir -p $BUILD/callouts $LIB $XC
  find $BUILD/callouts -maxdepth 1 -name '*.c' -delete 2>/dev/null || true
  find $LIB -maxdepth 1 -name '*.so' -delete 2>/dev/null || true
  find $XC  -maxdepth 1 -name '*.xc' -delete 2>/dev/null || true
"

# ── push .c sources + .xc descriptors ─────────────────────────────────
scp_v "${C_SOURCES[@]}" "$VISTA_SSH_USER@$VISTA_HOST:\$HOME/export/seed/$PROJECT/build/callouts/"
if [ "${#XC_FILES[@]}" -gt 0 ]; then
  scp_v "${XC_FILES[@]}" "$VISTA_SSH_USER@$VISTA_HOST:\$HOME/export/seed/$PROJECT/xc/"
fi

# ── build inside container against the runtime YDB headers ────────────
# Reads the per-source `// link: -lfoo` directive from the first 30 lines
# of each .c file (same convention as tools/build-callouts.sh on the host).
ssh_v "
  set -euo pipefail
  YDB_INC=\"\${ydb_dist:-/usr/local/lib/yottadb/r2.02}\"
  if [ ! -f \"\$YDB_INC/libyottadb.h\" ]; then
    echo '[seed-callouts] libyottadb.h not found at '\"\$YDB_INC\"'/libyottadb.h' >&2
    exit 1
  fi
  cd $BUILD/callouts
  for src in *.c; do
    base=\$(basename \"\$src\" .c)
    out=$LIB/\$base.so
    link_flags=\$(sed -n '1,30s|^// link:[[:space:]]*||p' \"\$src\" | head -1)
    echo \"[seed-callouts] cc \$src -> \$out\${link_flags:+ (link: \$link_flags)}\"
    # shellcheck disable=SC2086
    gcc -shared -fPIC -I\"\$YDB_INC\" -O2 -Wall -Wextra -o \"\$out\" \"\$src\" \$link_flags
  done
  echo \"[seed-callouts] built \$(ls $LIB/*.so | wc -l) .so file(s) under $LIB\"
  ls -la $LIB
"

# ── idempotently inject env-var exports into ydb_env.sh ───────────────
# Uses a labelled marker block so re-runs replace the prior block in
# place. The block exports STDLIB_LIB + every ydb_xc_<name> derived from
# the .xc descriptors we just deployed.
MARKER_START="# >>> m-stdlib callouts (managed by scripts/seed-callouts.sh) >>>"
MARKER_END="# <<< m-stdlib callouts <<<"

XC_EXPORTS=""
for xc in "${XC_FILES[@]}"; do
  base="$(basename "$xc" .xc)"             # e.g. std_crypto
  pkg="${base//[^A-Za-z0-9]/}"             # YDB package name — must be alphanumeric
  XC_EXPORTS+="  export ydb_xc_${pkg}=\"\$_M_STDLIB_XC/${base}.xc\""$'\n'
done

# Build the block content. We reference $HOME explicitly because ydb_env.sh
# is sourced as root via `sudo bash -c` during the inject step but reflects
# the calling user's HOME via the SSH session that runs `m test`.
BLOCK="$MARKER_START
# Auto-generated $(date -u +%Y-%m-%dT%H:%M:%SZ). Do not hand-edit.
# Removed cleanly by deleting the block between the markers.
_M_STDLIB_LIB=\"\$HOME/export/seed/$PROJECT/lib/$PLATFORM\"
_M_STDLIB_XC=\"\$HOME/export/seed/$PROJECT/xc\"
if [ -d \"\$_M_STDLIB_LIB\" ]; then
  export STDLIB_LIB=\"\$_M_STDLIB_LIB\"
fi
if [ -d \"\$_M_STDLIB_XC\" ]; then
${XC_EXPORTS}fi
unset _M_STDLIB_LIB _M_STDLIB_XC
$MARKER_END"

# Push the block content and the inject script to the container, run as root.
echo "[$PROJECT/callouts] injecting env-var exports into /etc/profile.d/ydb_env.sh"
ssh_v "cat > $STAGE/build/env-block.sh" <<<"$BLOCK"
ssh_v "
  set -euo pipefail
  TARGET=/etc/profile.d/ydb_env.sh
  BLOCK_FILE=$STAGE/build/env-block.sh
  TMP=\$(mktemp)
  # Strip any existing managed block, append the fresh one.
  sudo -n awk '
    /^# >>> m-stdlib callouts/ {skip=1; next}
    /^# <<< m-stdlib callouts/ {skip=0; next}
    !skip {print}
  ' \"\$TARGET\" > \"\$TMP\"
  cat \"\$BLOCK_FILE\" >> \"\$TMP\"
  sudo -n install -m 0775 -o root -g root \"\$TMP\" \"\$TARGET\"
  rm -f \"\$TMP\"
  echo '[seed-callouts] ydb_env.sh marker block:'
  sudo -n awk '/^# >>> m-stdlib callouts/,/^# <<< m-stdlib callouts/' \"\$TARGET\"
"

echo "[$PROJECT/callouts] done — STDLIB_LIB + ydb_xc_* will be exported on next SSH session"
