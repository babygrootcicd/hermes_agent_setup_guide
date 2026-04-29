#!/usr/bin/env bash
# scripts/common/export-sessions.sh
# Exports Hermes session history to JSONL format with optional credential redaction.
#
# Usage:
#   ./export-sessions.sh                              # Export all sessions
#   ./export-sessions.sh --source telegram            # Filter by platform
#   ./export-sessions.sh --since 2026-01-01           # Filter start date
#   ./export-sessions.sh --until 2026-01-31           # Filter end date
#   ./export-sessions.sh --session-id 20260426_abc123 # Single session
#   ./export-sessions.sh --output ~/my-sessions.jsonl # Custom output path
#   ./export-sessions.sh --redact                     # Auto-redact credentials

set -euo pipefail

# --- UI Helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${CYAN}${BOLD}── $1 ──${NC}"; }

expand_home_path() {
    local path="$1"
    if [[ "$path" == "~" ]]; then
        printf '%s\n' "$HOME"
    elif [[ "$path" == "~/"* ]]; then
        printf '%s\n' "$HOME/${path#"~/"}"
    else
        printf '%s\n' "$path"
    fi
}

usage() {
    cat <<EOF
Usage: $0 [--source cli|telegram|discord|slack|all] [--since YYYY-MM-DD] [--until YYYY-MM-DD]
          [--session-id ID] [--profile NAME] [--output PATH] [--redact]
EOF
}

# --- Defaults ---
SOURCE_FILTER=""
SINCE_DATE=""
UNTIL_DATE=""
SESSION_ID=""
OUTPUT_PATH="$HOME/hermes-sessions-$(date +%F).jsonl"
PROFILE_NAME=""
REDACT=false

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            [[ $# -ge 2 ]] || error "Missing value for --source"
            SOURCE_FILTER="$2"
            shift 2
            ;;
        --since)
            [[ $# -ge 2 ]] || error "Missing value for --since"
            SINCE_DATE="$2"
            shift 2
            ;;
        --until)
            [[ $# -ge 2 ]] || error "Missing value for --until"
            UNTIL_DATE="$2"
            shift 2
            ;;
        --session-id)
            [[ $# -ge 2 ]] || error "Missing value for --session-id"
            SESSION_ID="$2"
            shift 2
            ;;
        --profile)
            [[ $# -ge 2 ]] || error "Missing value for --profile"
            PROFILE_NAME="$2"
            shift 2
            ;;
        --output|-o)
            [[ $# -ge 2 ]] || error "Missing value for $1"
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --redact)     REDACT=true;        shift ;;
        -h|--help)
            usage
            exit 0 ;;
        *) error "Unknown argument: $1" ;;
    esac
done

OUTPUT_PATH="$(expand_home_path "$OUTPUT_PATH")"

echo -e "${GREEN}${BOLD}"
echo "=============================================="
echo "   Hermes Agent — Session Export"
echo "=============================================="
echo -e "${NC}"
info "Output  : $OUTPUT_PATH"
[[ -n "$SOURCE_FILTER" ]] && info "Source  : $SOURCE_FILTER"
[[ -n "$SINCE_DATE"    ]] && info "Since   : $SINCE_DATE"
[[ -n "$UNTIL_DATE"    ]] && info "Until   : $UNTIL_DATE"
[[ -n "$SESSION_ID"    ]] && info "Session : $SESSION_ID"
[[ -n "$PROFILE_NAME"  ]] && info "Profile : $PROFILE_NAME"
[[ "$REDACT" == true   ]] && info "Redact  : enabled"
echo ""

# --- Check hermes is available ---
if ! command -v hermes &>/dev/null; then
    warn "hermes command not found in PATH."
    warn "Attempting fallback: direct SQLite export."
    HERMES_AVAILABLE=false
else
    HERMES_AVAILABLE=true
fi

# --- Build hermes export command ---
section "Exporting"
mkdir -p "$(dirname "$OUTPUT_PATH")"

if [[ "$HERMES_AVAILABLE" == true ]]; then
    CMD_ARGS=()
    [[ -n "$PROFILE_NAME" ]] && CMD_ARGS+=("--profile" "$PROFILE_NAME")
    CMD_ARGS+=("sessions" "export" "$OUTPUT_PATH")

    [[ -n "$SOURCE_FILTER" && "$SOURCE_FILTER" != "all" ]] && CMD_ARGS+=("--source" "$SOURCE_FILTER")
    [[ -n "$SINCE_DATE"    ]] && CMD_ARGS+=("--since" "$SINCE_DATE")
    [[ -n "$UNTIL_DATE"    ]] && CMD_ARGS+=("--until" "$UNTIL_DATE")
    [[ -n "$SESSION_ID"    ]] && CMD_ARGS+=("--session-id" "$SESSION_ID")

    info "Running: hermes ${CMD_ARGS[*]}"
    hermes "${CMD_ARGS[@]}"

else
    # --- Fallback: raw SQLite export ---
    if [[ -n "$PROFILE_NAME" ]]; then
        HERMES_DB="$HOME/.hermes/profiles/$PROFILE_NAME/state.db"
    else
        HERMES_DB="$HOME/.hermes/state.db"
    fi
    [[ -f "$HERMES_DB" ]] || error "state.db not found at $HERMES_DB"

    warn "Fallback: exporting directly from SQLite (basic format)."
    python3 - <<PYEOF
import sqlite3, json, sys
from datetime import datetime

db_path = "$HERMES_DB"
output_path = "$OUTPUT_PATH"
source_filter = "$SOURCE_FILTER"
since_date = "$SINCE_DATE"
until_date = "$UNTIL_DATE"
session_id = "$SESSION_ID"

con = sqlite3.connect(db_path)
con.row_factory = sqlite3.Row
cur = con.cursor()

query = "SELECT * FROM sessions WHERE 1=1"
params = []

if source_filter and source_filter != "all":
    query += " AND source = ?"
    params.append(source_filter)
if since_date:
    query += " AND created_at >= ?"
    params.append(since_date)
if until_date:
    query += " AND created_at <= ?"
    params.append(until_date + "T23:59:59")
if session_id:
    query += " AND session_id = ?"
    params.append(session_id)

query += " ORDER BY created_at DESC"
cur.execute(query, params)
sessions = cur.fetchall()

with open(output_path, "w") as f:
    for session in sessions:
        row = dict(session)
        msg_cur = con.cursor()
        msg_cur.execute(
            "SELECT role, content FROM messages WHERE session_id = ? ORDER BY id",
            (row["session_id"],)
        )
        row["messages"] = [dict(m) for m in msg_cur.fetchall()]
        f.write(json.dumps(row, default=str) + "\n")

con.close()
print(f"  Exported {len(sessions)} sessions.")
PYEOF
fi

# --- Redaction ---
if [[ "$REDACT" == true && -f "$OUTPUT_PATH" ]]; then
    section "Credential Redaction"
    warn "Redacting common credential patterns..."

    REDACT_SRC="$(mktemp)"
    REDACT_OUT="$(mktemp)"
    cp "$OUTPUT_PATH" "$REDACT_SRC"

    # Redact API keys, tokens, passwords, secrets (value after key=, ": ", etc.)
    sed -E \
        -e 's/(api[_-]?key["'"'"':[[:space:]]*=]+)[A-Za-z0-9_\-]{16,}/\1[REDACTED]/gI' \
        -e 's/(token["'"'"':[[:space:]]*=]+)[A-Za-z0-9_\-\.]{16,}/\1[REDACTED]/gI' \
        -e 's/(password["'"'"':[[:space:]]*=]+)[^[:space:]"'"'"',}{]{6,}/\1[REDACTED]/gI' \
        -e 's/(secret["'"'"':[[:space:]]*=]+)[A-Za-z0-9_\-\.]{8,}/\1[REDACTED]/gI' \
        -e 's/(Authorization: Bearer )[^[:space:]"]{8,}/\1[REDACTED]/gI' \
        -e 's/sk-[A-Za-z0-9]{20,}/sk-[REDACTED]/g' \
        -e 's/AIza[A-Za-z0-9_\-]{35}/[GOOGLE_KEY_REDACTED]/g' \
        "$REDACT_SRC" > "$REDACT_OUT"

    mv "$REDACT_OUT" "$OUTPUT_PATH"
    rm -f "$REDACT_SRC"
    success "Redaction complete"
fi

# --- Stats ---
section "Export Summary"
if [[ -f "$OUTPUT_PATH" ]]; then
    LINE_COUNT="$(wc -l < "$OUTPUT_PATH" | tr -d ' ')"
    FILE_SIZE="$(du -sh "$OUTPUT_PATH" | cut -f1)"
    success "Exported to : $OUTPUT_PATH"
    success "Sessions    : $LINE_COUNT"
    success "File size   : $FILE_SIZE"
    echo ""
    echo -e "  ${CYAN}Preview first session:${NC}"
    echo -e "  ${CYAN}head -1 $OUTPUT_PATH | python3 -m json.tool | head -30${NC}"
else
    warn "Output file not created. Check hermes output above for errors."
fi
echo ""
