#!/usr/bin/env bash
# scripts/safe-test.sh — Wrap `m test` with auto-recovery for the
# vista-meta YDB container's known failure modes.
#
# Two failure modes this wrapper handles:
#
# 1. **Stuck `mumps` processes** in the container after a crashed test
#    leak the YDB lock + journal state, blocking subsequent `m test`
#    invocations. Documented as TOOLCHAIN-FINDINGS P2 (2026-05-06).
#
# 2. **SSH multiplex MaxSessions exhaustion** when the master
#    accumulates dead sessions after process leaks. Symptom:
#    `Session open refused by peer` from `m test`'s SSH transport.
#
# On any non-zero exit from `m test`, the wrapper:
#   1. Logs the failure to ~/data/m-stdlib/test-runs.log
#   2. Stops the SSH multiplex master (clears stuck sessions)
#   3. Issues `mupip rundown -region "*"` over a fresh non-multiplexed
#      SSH connection (best-effort — non-fatal on failure)
#   4. Kills any leaked `mumps` processes in the container
#   5. Retries `m test` once
#
# Final exit status mirrors the (last) `m test` invocation.
#
# Usage: same as `m test`, e.g.
#   scripts/safe-test.sh tests/STDSEEDTST.m
#   scripts/safe-test.sh --no-isolation --format=tap tests/

set -u

LOG_DIR="$HOME/data/m-stdlib"
LOG_FILE="$LOG_DIR/test-runs.log"
mkdir -p "$LOG_DIR"

CONN="${VISTA_CONN_FILE:-$HOME/data/vista-meta/conn.env}"
[ -f "$CONN" ] || {
    echo "[safe-test] no conn file: $CONN — is vista-meta running?" >&2
    exit 2
}
# shellcheck disable=SC1090
source "$CONN"

CTRL_PATH="$HOME/.ssh/cm-vista-${VISTA_SSH_USER}@${VISTA_HOST}:${VISTA_SSH_PORT}"
M_BIN="${M:-$HOME/projects/m-cli/.venv/bin/m}"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { printf '%s | safe-test | %s\n' "$(ts)" "$*" >> "$LOG_FILE"; }

run_attempt() {
    local label="$1"; shift
    log "$label START args=[$*]"
    "$M_BIN" test "$@"
    local rc=$?
    log "$label END rc=$rc"
    return $rc
}

ssh_one_shot() {
    # Bypass the multiplex master entirely — fresh sshd session each call.
    ssh -o ControlMaster=no -o ControlPath=none \
        -o ConnectTimeout=10 -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -p "$VISTA_SSH_PORT" "${VISTA_SSH_USER}@${VISTA_HOST}" "$@"
}

recover() {
    log "RECOVER START"

    # Step 1 — stop multiplex master if it has a control socket
    if [ -e "$CTRL_PATH" ]; then
        ssh -O stop -S "$CTRL_PATH" -p "$VISTA_SSH_PORT" \
            "${VISTA_SSH_USER}@${VISTA_HOST}" >/dev/null 2>&1 \
            && log "ssh-master stopped" \
            || log "ssh-master stop failed (non-fatal)"
        sleep 1
    fi

    # Step 2 — kill any stale mumps processes in the container.
    # YDB's mumps lives at /usr/local/lib/yottadb/r2.02/mumps; pgrep
    # matches the binary path on the cmdline.
    local kill_out
    kill_out="$(ssh_one_shot 'pkill -9 -f "/usr/local/lib/yottadb/.*/mumps" 2>&1; pgrep -af "/usr/local/lib/yottadb/.*/mumps" 2>&1 | head -5' 2>&1 || true)"
    log "pkill mumps: ${kill_out//$'\n'/ | }"

    # Step 3 — mupip rundown to release any stuck region locks. Non-interactive
    # SSH does not source the YDB env, so we explicitly source ydb_env_set
    # (which sets ydb_dist + PATH for mupip).
    local rundown_out
    rundown_out="$(ssh_one_shot 'source /usr/local/lib/yottadb/r2.02/ydb_env_set 2>/dev/null && mupip rundown -region "*" 2>&1' 2>&1 || true)"
    log "mupip rundown: ${rundown_out//$'\n'/ | }"

    log "RECOVER END"
    sleep 1
}

# Default Bash exit if vista-meta is unreachable on the very first connect
ssh_one_shot 'true' >/dev/null 2>&1 || {
    log "CONNECT FAIL: cannot reach $VISTA_SSH_USER@$VISTA_HOST:$VISTA_SSH_PORT"
    echo "[safe-test] cannot reach vista-meta; check container is up" >&2
    exit 3
}

# First attempt
run_attempt "first" "$@"
rc=$?

# Recover-and-retry on any non-zero exit
if [ "$rc" -ne 0 ]; then
    log "first-attempt failed rc=$rc; running recovery"
    recover
    run_attempt "retry" "$@"
    rc=$?
fi

log "FINAL rc=$rc"
exit "$rc"
