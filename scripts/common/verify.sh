#!/usr/bin/env bash

# scripts/common/verify.sh
# Verification script for Hermes Agent session persistence + security baseline + Ollama

set -u

# --- UI Helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()    { echo -e "${RED}[FAIL]${NC}  $1"; }
section() { echo -e "\n${CYAN}── $1 ──${NC}"; }

CHECKS_TOTAL=0
CHECKS_OK=0
CHECKS_WARN=0
CHECKS_FAIL=0

mark_ok()   { ((CHECKS_TOTAL++)); ((CHECKS_OK++)); success "$1"; }
mark_warn() { ((CHECKS_TOTAL++)); ((CHECKS_WARN++)); warn "$1"; }
mark_fail() { ((CHECKS_TOTAL++)); ((CHECKS_FAIL++)); fail "$1"; }

echo -e "${GREEN}"
echo "==============================================="
echo "   Hermes Agent Verification"
echo "==============================================="
echo -e "${NC}"

HERMES_DIR="$HOME/.hermes"
CONFIG_FILE="$HERMES_DIR/config.yaml"
STATE_DB="$HERMES_DIR/state.db"
HERMES_BIN=""

find_hermes_bin() {
    if command -v hermes >/dev/null 2>&1; then
        HERMES_BIN="$(command -v hermes)"
        return 0
    fi
    if [[ -x "$HERMES_DIR/bin/hermes" ]]; then
        HERMES_BIN="$HERMES_DIR/bin/hermes"
        return 0
    fi
    return 1
}

config_key_true() {
    local key="$1"
    [[ -f "$CONFIG_FILE" ]] || return 1
    grep -Eq "^[[:space:]]*${key}[[:space:]]*:[[:space:]]*true([[:space:]]*#.*)?$" "$CONFIG_FILE"
}

section "Hermes Installation"
if find_hermes_bin; then
    VERSION="$("$HERMES_BIN" --version 2>&1 || true)"
    if [[ -n "$VERSION" ]]; then
        mark_ok "Hermes found: $VERSION"
    else
        mark_warn "Hermes binary found at $HERMES_BIN, but version output is empty."
    fi
    if [[ "$HERMES_BIN" == "$HERMES_DIR/bin/hermes" ]]; then
        mark_warn "Hermes is not in PATH. Consider: export PATH=\"\$HOME/.hermes/bin:\$PATH\""
    fi
else
    mark_fail "Hermes binary not found in PATH or $HERMES_DIR/bin/hermes."
fi

section "Session Persistence Files"
[[ -d "$HERMES_DIR" ]] && mark_ok "Hermes data directory exists: $HERMES_DIR" || mark_warn "Hermes data directory missing: $HERMES_DIR"
[[ -f "$CONFIG_FILE" ]] && mark_ok "Configuration file exists: $CONFIG_FILE" || mark_warn "Configuration file missing: $CONFIG_FILE"
[[ -f "$STATE_DB" ]] && mark_ok "Session database exists: $STATE_DB" || mark_warn "Session database missing: $STATE_DB"
[[ -d "$HERMES_DIR/sessions" ]] && mark_ok "Raw sessions directory exists: $HERMES_DIR/sessions" || mark_warn "Raw sessions directory missing: $HERMES_DIR/sessions"
[[ -d "$HERMES_DIR/logs" ]] && mark_ok "Logs directory exists: $HERMES_DIR/logs" || mark_warn "Logs directory missing: $HERMES_DIR/logs"
[[ -d "$HERMES_DIR/cron" ]] && mark_ok "Cron directory exists: $HERMES_DIR/cron" || mark_warn "Cron directory missing: $HERMES_DIR/cron"

section "Session CLI Commands"
if [[ -n "$HERMES_BIN" ]]; then
    CHAT_HELP="$("$HERMES_BIN" chat --help 2>&1 || true)"
    [[ "$CHAT_HELP" == *"--continue"* ]] && mark_ok "`hermes chat --continue` is available." || mark_warn "Could not verify `--continue` flag in `hermes chat --help`."
    [[ "$CHAT_HELP" == *"--resume"* ]] && mark_ok "`hermes chat --resume` is available." || mark_warn "Could not verify `--resume` flag in `hermes chat --help`."

    if "$HERMES_BIN" sessions list --help >/dev/null 2>&1; then
        mark_ok "`hermes sessions list` command is available."
    else
        mark_warn "`hermes sessions list --help` failed."
    fi

    if "$HERMES_BIN" session search --help >/dev/null 2>&1 || "$HERMES_BIN" sessions search --help >/dev/null 2>&1; then
        mark_ok "Session search command is available."
    else
        mark_warn "Could not verify a session search command."
    fi
else
    mark_warn "Skipping CLI command checks because Hermes binary is unavailable."
fi

section "Security Baseline (config.yaml)"
if [[ -f "$CONFIG_FILE" ]]; then
    config_key_true "dangerous_command_approval" \
        && mark_ok "dangerous_command_approval: true" \
        || mark_warn "dangerous_command_approval is missing or not true."

    config_key_true "context_scan_enabled" \
        && mark_ok "context_scan_enabled: true" \
        || mark_warn "context_scan_enabled is missing or not true."

    config_key_true "prompt_injection_detection" \
        && mark_ok "prompt_injection_detection: true" \
        || mark_warn "prompt_injection_detection is missing or not true."

    if grep -Eq "^[[:space:]]*backend[[:space:]]*:[[:space:]]*docker([[:space:]]*#.*)?$" "$CONFIG_FILE"; then
        mark_ok "terminal backend is set to docker."
    else
        mark_warn "terminal backend is not explicitly set to docker."
    fi
else
    mark_warn "Skipping security baseline checks because config.yaml is missing."
fi

section "Session Database Shape"
if [[ -f "$STATE_DB" ]]; then
    if command -v sqlite3 >/dev/null 2>&1; then
        TABLE_COUNT="$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('sessions','messages');" 2>/dev/null || echo "0")"
        if [[ "$TABLE_COUNT" == "2" ]]; then
            mark_ok "state.db includes required tables: sessions, messages."
        else
            mark_warn "state.db does not expose both sessions/messages tables (count=$TABLE_COUNT)."
        fi

        LAST_SESSION_ID="$(sqlite3 "$STATE_DB" "SELECT session_id FROM sessions ORDER BY created_at DESC LIMIT 1;" 2>/dev/null || true)"
        if [[ -z "$LAST_SESSION_ID" ]]; then
            mark_warn "No sessions found yet in state.db."
        elif [[ "$LAST_SESSION_ID" =~ ^[0-9]{8}_[0-9]{6}_[0-9a-fA-F]+$ ]]; then
            mark_ok "Latest session_id format looks valid: $LAST_SESSION_ID"
        else
            mark_warn "Latest session_id format differs from expected pattern: $LAST_SESSION_ID"
        fi
    else
        mark_warn "sqlite3 is not installed; skipping state.db schema/session-id checks."
    fi
else
    mark_warn "Skipping state.db checks because the database file is missing."
fi

section "Ollama Connectivity"
OLLAMA_URL="${HERMES_BASE_URL:-http://127.0.0.1:11434/v1}"
MODELS_ENDPOINT="${OLLAMA_URL%/}/models"
info "Using Ollama URL: $OLLAMA_URL"

HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "$MODELS_ENDPOINT" 2>/dev/null || true)"
if [[ "$HTTP_CODE" == "200" ]]; then
    mark_ok "Ollama models endpoint responded HTTP 200."
else
    mark_warn "Ollama models endpoint did not return HTTP 200 (got: ${HTTP_CODE:-n/a})."
fi

if command -v ollama >/dev/null 2>&1; then
    MODEL_LINES="$(ollama list 2>/dev/null | tail -n +2 || true)"
    if [[ -n "$MODEL_LINES" ]]; then
        mark_ok "Ollama CLI reports pulled model(s)."
        echo "$MODEL_LINES" | awk '{print "  - " $1}'
    else
        mark_warn "No pulled models detected via `ollama list`."
    fi
else
    mark_warn "ollama CLI not found; skipped local model inventory."
fi

echo ""
echo -e "${CYAN}Summary${NC}: total=$CHECKS_TOTAL ok=$CHECKS_OK warn=$CHECKS_WARN fail=$CHECKS_FAIL"
if (( CHECKS_FAIL > 0 )); then
    fail "Verification completed with failure(s)."
    exit 1
fi
info "Verification completed."
