#!/usr/bin/env bash
# Build YottaDB $ZF / $ZROUTINES shared objects for m-stdlib Phase 3 modules
# (STDHTTP, STDCRYPTO, STDCOMPRESS).
#
# Usage:
#   tools/build-callouts.sh                # build for the host platform
#   tools/build-callouts.sh --check        # report what would be built; do nothing
#   tools/build-callouts.sh --clean        # remove ./so/<platform>/ before building
#   tools/build-callouts.sh --target=PLAT  # cross-name only (no cross-compile yet)
#
# Layout:
#   src/callouts/*.c                       # one C file per callout family
#   so/<platform>/*.so                     # compiled output (or *.dylib on macOS)
#
# Supported platforms (auto-detected from `uname -s -m`):
#   linux-x86_64, linux-aarch64, darwin-x86_64, darwin-arm64
#
# YottaDB host-call ABI: -fPIC + -shared, header from $ydb_dist (resolved
# from environment, falling back to /opt/yottadb/current). The script does
# not depend on YDB being installed when no .c files exist — running it on
# an empty src/callouts/ is a no-op success, which is the v0.0.4 state.

set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/src/callouts"
SO_ROOT="${PROJECT_ROOT}/so"

CHECK_ONLY=0
DO_CLEAN=0
TARGET_OVERRIDE=""

for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    --clean) DO_CLEAN=1 ;;
    --target=*) TARGET_OVERRIDE="${arg#--target=}" ;;
    -h|--help)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# ── platform detection ────────────────────────────────────────────────
detect_platform() {
  local os arch
  os="$(uname -s)"; arch="$(uname -m)"
  case "${os}-${arch}" in
    Linux-x86_64)   echo "linux-x86_64" ;;
    Linux-aarch64)  echo "linux-aarch64" ;;
    Linux-arm64)    echo "linux-aarch64" ;;
    Darwin-x86_64)  echo "darwin-x86_64" ;;
    Darwin-arm64)   echo "darwin-arm64" ;;
    *) echo "unsupported host: ${os}-${arch}" >&2; exit 3 ;;
  esac
}

PLATFORM="${TARGET_OVERRIDE:-$(detect_platform)}"
SO_DIR="${SO_ROOT}/${PLATFORM}"

case "${PLATFORM}" in
  linux-*)  CC_DEFAULT=gcc;   SO_EXT=so;    LD_FLAGS="-shared -fPIC" ;;
  darwin-*) CC_DEFAULT=clang; SO_EXT=dylib; LD_FLAGS="-dynamiclib -fPIC -undefined dynamic_lookup" ;;
  *) echo "unsupported target: ${PLATFORM}" >&2; exit 3 ;;
esac

CC="${CC:-${CC_DEFAULT}}"
YDB_DIST="${ydb_dist:-/opt/yottadb/current}"

# ── ydb header resolution (only required when actually compiling) ─────
ydb_include_flag() {
  if [ -d "${YDB_DIST}" ] && [ -f "${YDB_DIST}/libyottadb.h" ]; then
    echo "-I${YDB_DIST}"
  elif [ -f "/opt/yottadb/libyottadb.h" ]; then
    echo "-I/opt/yottadb"
  else
    echo ""
  fi
}

# ── input enumeration ─────────────────────────────────────────────────
shopt -s nullglob
SOURCES=("${SRC_DIR}"/*.c)
# Sort for deterministic ordering across systems.
if [ "${#SOURCES[@]}" -gt 1 ]; then
  IFS=$'\n' SOURCES=($(printf '%s\n' "${SOURCES[@]}" | sort))
  unset IFS
fi

if [ "${#SOURCES[@]}" -eq 0 ]; then
  rel="${SRC_DIR#${PROJECT_ROOT}/}"
  echo "[build-callouts] no callouts in ${rel} — Phase 3 modules will populate it"
  exit 0
fi

# ── plan ──────────────────────────────────────────────────────────────
echo "[build-callouts] platform=${PLATFORM}  cc=${CC}  ydb_dist=${YDB_DIST}"
for src in "${SOURCES[@]}"; do
  base="$(basename -- "${src}" .c)"
  out="${SO_DIR}/${base}.${SO_EXT}"
  printf '  %s -> %s\n' "${src#${PROJECT_ROOT}/}" "${out#${PROJECT_ROOT}/}"
done

if [ "${CHECK_ONLY}" -eq 1 ]; then
  echo "[build-callouts] --check: nothing built"
  exit 0
fi

# ── execute ───────────────────────────────────────────────────────────
if [ "${DO_CLEAN}" -eq 1 ] && [ -d "${SO_DIR}" ]; then
  echo "[build-callouts] cleaning ${SO_DIR#${PROJECT_ROOT}/}"
  rm -rf -- "${SO_DIR}"
fi

mkdir -p -- "${SO_DIR}"
INC_FLAG="$(ydb_include_flag)"

for src in "${SOURCES[@]}"; do
  base="$(basename -- "${src}" .c)"
  out="${SO_DIR}/${base}.${SO_EXT}"
  echo "[build-callouts] cc ${src#${PROJECT_ROOT}/} -> ${out#${PROJECT_ROOT}/}"
  # shellcheck disable=SC2086
  "${CC}" ${LD_FLAGS} ${INC_FLAG} -O2 -Wall -Wextra -o "${out}" "${src}"
  file "${out}" | sed 's/^/  /'
done

echo "[build-callouts] ok — ${#SOURCES[@]} object(s) in ${SO_DIR#${PROJECT_ROOT}/}"
