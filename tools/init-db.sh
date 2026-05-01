#!/usr/bin/env bash
# init-db.sh — Bootstrap a YottaDB workspace for m-stdlib.
#
# Idempotent: skips if .ydb/m-stdlib.gld already exists.
# Creates .ydb/m-stdlib.gld + .ydb/m-stdlib.dat under $PROJECT_ROOT.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YDB_DIR="$PROJECT_ROOT/.ydb"
GLD="$YDB_DIR/m-stdlib.gld"
DAT="$YDB_DIR/m-stdlib.dat"

if [[ -f "$GLD" && -f "$DAT" ]]; then
    exit 0
fi

YDB_DIST="${ydb_dist:-$(ls -d /usr/local/lib/yottadb/r* 2>/dev/null | sort -V | tail -1)}"
if [[ -z "$YDB_DIST" ]]; then
    echo "init-db.sh: YottaDB not found under /usr/local/lib/yottadb/" >&2
    exit 1
fi

mkdir -p "$YDB_DIR"

# GDE doesn't want a routines path — unset it to avoid validation noise.
export ydb_dist="$YDB_DIST"
export ydb_gbldir="$GLD"
unset ydb_routines

# KEY_SIZE=1019 + BLOCK_SIZE=4096: required so YDB's `view "TRACE"` can
# capture deeply-nested FOR_LOOP/*CHILDREN subscripts without raising
# %YDB-E-GVSUBOFLOW. Default KEY_SIZE=64 trips on test labels longer
# than ~30 chars combined with FOR-loop call depth. See
# TOOLCHAIN-FINDINGS.md for the full investigation.
"$YDB_DIST/mumps" -run GDE <<EOF
change -segment DEFAULT -file_name="$DAT"
change -region DEFAULT -dynamic_segment=DEFAULT -KEY_SIZE=1019
change -segment DEFAULT -BLOCK_SIZE=4096
exit
EOF

"$YDB_DIST/mupip" create
