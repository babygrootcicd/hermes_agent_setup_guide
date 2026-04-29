#!/usr/bin/env bash

# scripts/macos/debug.sh
# macOS debugging helper focused on session persistence/log inspection.

set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HERMES_DIR="${HOME}/.hermes"
LOG_DIR="${HERMES_DIR}/logs"
STATE_DB="${HERMES_DIR}/state.db"
OPEN_DESKTOP=false
LOG_OVERRIDE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [--desktop] [--log <path>]

Options:
  --desktop      Build and open the macOS desktop app DMG first.
  --log <path>   Tail a specific log file (default: auto-detect from ~/.hermes/logs).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --desktop) OPEN_DESKTOP=true; shift ;;
        --log) LOG_OVERRIDE="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "[WARN] Unknown argument: $1"; usage; exit 1 ;;
    esac
done

echo "==============================================="
echo "   Hermes macOS Debug"
echo "==============================================="

if [[ "$OPEN_DESKTOP" == true ]]; then
    echo "[INFO] Building desktop app..."
    "$REPO_ROOT/scripts/macos/build_app.sh"
    DMG_PATH="$REPO_ROOT/app/dist/Hermes Agent-0.1.0-arm64.dmg"
    if [[ -f "$DMG_PATH" ]]; then
        echo "[INFO] Opening DMG: $DMG_PATH"
        open "$DMG_PATH"
    else
        echo "[WARN] DMG not found at $DMG_PATH"
    fi
fi

echo ""
echo "[INFO] Hermes home : $HERMES_DIR"
echo "[INFO] Logs dir    : $LOG_DIR"
echo "[INFO] Session DB  : $STATE_DB"

if [[ -f "$STATE_DB" ]]; then
    if command -v sqlite3 >/dev/null 2>&1; then
        echo ""
        echo "[INFO] Recent sessions (latest 5):"
        sqlite3 -header -column "$STATE_DB" \
            "SELECT session_id, source, created_at FROM sessions ORDER BY created_at DESC LIMIT 5;" \
            2>/dev/null || echo "[WARN] Could not query sessions table from state.db."
    else
        echo "[WARN] sqlite3 is not installed; skipping session table preview."
    fi
else
    echo "[WARN] state.db not found. Start Hermes once to initialize session storage."
fi

echo ""
echo "[INFO] Resume hints:"
echo "  hermes chat --continue"
echo "  hermes chat --resume <session_id>"
echo "  hermes session search \"<keyword>\""

LOG_CANDIDATES=(
    "$LOG_OVERRIDE"
    "$LOG_DIR/gui.log"
    "$LOG_DIR/agent.log"
    "$LOG_DIR/error.log"
    "$LOG_DIR/gateway.log"
)

SELECTED_LOG=""
for candidate in "${LOG_CANDIDATES[@]}"; do
    [[ -n "$candidate" ]] || continue
    if [[ -f "$candidate" ]]; then
        SELECTED_LOG="$candidate"
        break
    fi
done

if [[ -z "$SELECTED_LOG" ]]; then
    echo "[WARN] No log file found to tail."
    echo "[INFO] Start Hermes, then rerun this script or pass --log <path>."
    exit 1
fi

echo ""
echo "[INFO] Tailing log: $SELECTED_LOG"
tail -n 120 -f "$SELECTED_LOG"
