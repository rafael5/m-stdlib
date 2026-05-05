#!/usr/bin/env bash
# Load m-stdlib's STD* routines and conformance tests into the shared
# vista-meta container.
set -euo pipefail

PROJECT="m-stdlib"
XTMP_KEY="M-STDLIB"

ROUTINE_GLOBS=(
  "src/*.m"
  "tests/*.m"
  "tests/conformance/*.m"
)

CONN="${VISTA_CONN_FILE:-$HOME/data/vista-meta/conn.env}"
[ -f "$CONN" ] || { echo "[$PROJECT] no conn file: $CONN — is vista-meta running?"; exit 1; }
# shellcheck disable=SC1090
source "$CONN"

ssh_v() {
  ssh -p "$VISTA_SSH_PORT" -o StrictHostKeyChecking=no -o BatchMode=yes \
      "$VISTA_SSH_USER@$VISTA_HOST" "$@"
}
scp_v() {
  # -O forces legacy SCP protocol (vista-meta's sshd ships without sftp).
  scp -O -P "$VISTA_SSH_PORT" -o StrictHostKeyChecking=no -o BatchMode=yes "$@"
}

ssh_v 'true' >/dev/null 2>&1 || {
  echo "[$PROJECT] cannot reach $VISTA_SSH_USER@$VISTA_HOST:$VISTA_SSH_PORT"
  exit 1
}

shopt -s nullglob
declare -A by_name=()
for g in "${ROUTINE_GLOBS[@]}"; do
  for f in $g; do
    by_name[$(basename "$f" .m)]="$f"
  done
done
shopt -u nullglob

if [ "${#by_name[@]}" -eq 0 ]; then
  echo "[$PROJECT] no routines to seed"
  exit 0
fi

echo "[$PROJECT] seeding $VISTA_HOST:$VISTA_SSH_PORT (${#by_name[@]} routines)"

STAGE="export/seed/$PROJECT"
ssh_v "mkdir -p $STAGE && find $STAGE -maxdepth 1 -name '*.m' -delete"

files=()
for n in "${!by_name[@]}"; do files+=("${by_name[$n]}"); done
scp_v "${files[@]}" "$VISTA_SSH_USER@$VISTA_HOST:$STAGE/"

manifest_lines=$(printf '%s\n' "${!by_name[@]}")
ssh_v "cat > $STAGE/MANIFEST.txt" <<< "$manifest_lines"

echo "[$PROJECT] seed done — routines staged under \$HOME/$STAGE"
