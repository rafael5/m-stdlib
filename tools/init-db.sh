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

"$YDB_DIST/mumps" -run GDE <<EOF
change -segment DEFAULT -file_name="$DAT"
change -region DEFAULT -dynamic_segment=DEFAULT
exit
EOF

"$YDB_DIST/mupip" create
