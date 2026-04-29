#!/usr/bin/env bash
# scripts/common/backup.sh
# Creates a backup archive of Hermes Agent data.
# Safe to run while Hermes is active (uses SQLite WAL-safe backup for state.db).
#
# Usage:
#   ./backup.sh                        # Full backup, output to ~/Desktop
#   ./backup.sh --quick                # Config + memories + state.db + cron only
#   ./backup.sh --secure               # Includes .env and auth.json (with warning)
#   ./backup.sh --output ~/my.zip      # Custom output path
#   ./backup.sh --profile coder        # Backup a specific profile

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

# --- Defaults ---
HERMES_DIR="$HOME/.hermes"
BACKUP_MODE="full"           # full | quick | secure
OUTPUT_PATH=""
PROFILE_NAME=""
DATE_STR="$(date +%F)"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --quick)   BACKUP_MODE="quick";  shift ;;
        --full)    BACKUP_MODE="full";   shift ;;
        --secure)  BACKUP_MODE="secure"; shift ;;
        --output)  OUTPUT_PATH="$2";     shift 2 ;;
        --profile) PROFILE_NAME="$2";   shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--quick|--full|--secure] [--output <path>] [--profile <name>]"
            exit 0 ;;
        *) error "Unknown argument: $1" ;;
    esac
done

# --- Resolve source dir ---
if [[ -n "$PROFILE_NAME" ]]; then
    SOURCE_DIR="$HERMES_DIR/profiles/$PROFILE_NAME"
    [[ -d "$SOURCE_DIR" ]] || error "Profile not found: $SOURCE_DIR"
    LABEL="hermes-profile-${PROFILE_NAME}-${DATE_STR}"
else
    SOURCE_DIR="$HERMES_DIR"
    LABEL="hermes-backup-${DATE_STR}"
fi

# --- Resolve output path ---
if [[ -z "$OUTPUT_PATH" ]]; then
    OUTPUT_PATH="$HOME/Desktop/${LABEL}.tar.gz"
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo -e "${GREEN}${BOLD}"
echo "=============================================="
echo "   Hermes Agent — Backup"
echo "=============================================="
echo -e "${NC}"
info "Source  : $SOURCE_DIR"
info "Mode    : $BACKUP_MODE"
info "Output  : $OUTPUT_PATH"
echo ""

# --- Define what to include ---
section "Backup Contents"

declare -a INCLUDE_ITEMS=()
declare -a EXCLUDE_ITEMS=()

case "$BACKUP_MODE" in
    quick)
        INCLUDE_ITEMS=(
            "config.yaml"
            "memories/"
            "cron/"
            "skills/"
        )
        EXCLUDE_ITEMS=(".env" "auth.json" "state.db" "sessions/" "logs/")
        echo "  Mode: QUICK — config, memories, cron, skills"
        ;;
    full)
        INCLUDE_ITEMS=(
            "config.yaml"
            "memories/"
            "skills/"
            "sessions/"
            "cron/"
            "logs/"
            "profiles/"
        )
        EXCLUDE_ITEMS=(".env" "auth.json")
        echo "  Mode: FULL — everything except .env and auth.json"
        ;;
    secure)
        warn "SECURE mode includes .env and auth.json (credentials)."
        warn "Ensure the output archive is encrypted or stored securely."
        echo ""
        read -r -p "  Continue with SECURE backup? [y/N] " CONFIRM
        [[ "${CONFIRM,,}" == "y" ]] || { info "Aborted."; exit 0; }
        INCLUDE_ITEMS=(
            "config.yaml"
            ".env"
            "auth.json"
            "memories/"
            "skills/"
            "sessions/"
            "cron/"
            "logs/"
            "profiles/"
        )
        EXCLUDE_ITEMS=()
        echo "  Mode: SECURE — everything including credentials"
        ;;
esac

echo ""
for item in "${INCLUDE_ITEMS[@]}"; do
    path="$SOURCE_DIR/$item"
    if [[ -e "$path" ]]; then
        echo -e "  ${GREEN}✓${NC} $item"
    else
        echo -e "  ${YELLOW}–${NC} $item (not found, skipping)"
    fi
done

# --- SQLite WAL-safe state.db backup ---
section "state.db (WAL-safe copy)"
STATE_DB="$SOURCE_DIR/state.db"
STATE_DB_BACKUP="$WORK_DIR/state.db"

if [[ -f "$STATE_DB" ]]; then
    if command -v python3 &>/dev/null; then
        python3 - <<PYEOF
import sqlite3, sys
src_path = "$STATE_DB"
dst_path = "$STATE_DB_BACKUP"
try:
    src = sqlite3.connect(src_path)
    bak = sqlite3.connect(dst_path)
    src.backup(bak)
    bak.close()
    src.close()
    print("  SQLite backup complete (WAL-safe).")
except Exception as e:
    print(f"  SQLite backup failed: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
        success "state.db backed up via SQLite API"
    else
        warn "python3 not found — falling back to cp for state.db (may be unsafe if Hermes is running)"
        cp "$STATE_DB" "$STATE_DB_BACKUP"
    fi
fi

# --- Stage files into work dir ---
section "Staging Files"
STAGE_DIR="$WORK_DIR/hermes-backup"
mkdir -p "$STAGE_DIR"

# Copy state.db backup if it was created
if [[ -f "$STATE_DB_BACKUP" ]]; then
    cp "$STATE_DB_BACKUP" "$STAGE_DIR/state.db"
fi

for item in "${INCLUDE_ITEMS[@]}"; do
    src_path="$SOURCE_DIR/$item"
    if [[ -e "$src_path" ]]; then
        dest_path="$STAGE_DIR/$item"
        mkdir -p "$(dirname "$dest_path")"
        if [[ -d "$src_path" ]]; then
            cp -r "$src_path" "$dest_path"
        elif [[ "$item" != "state.db" ]]; then  # already handled above
            cp "$src_path" "$dest_path"
        fi
    fi
done

success "Files staged in $STAGE_DIR"

# --- Create archive ---
section "Creating Archive"
mkdir -p "$(dirname "$OUTPUT_PATH")"

if [[ "$OUTPUT_PATH" == *.zip ]]; then
    if command -v zip &>/dev/null; then
        (cd "$WORK_DIR" && zip -rq "$(realpath "$OUTPUT_PATH")" hermes-backup/)
    else
        warn "zip not found — using tar.gz instead"
        OUTPUT_PATH="${OUTPUT_PATH%.zip}.tar.gz"
        (cd "$WORK_DIR" && tar -czf "$(realpath "$OUTPUT_PATH")" hermes-backup/)
    fi
else
    (cd "$WORK_DIR" && tar -czf "$(realpath "$OUTPUT_PATH")" hermes-backup/)
fi

# --- Report ---
section "Done"
ARCHIVE_SIZE="$(du -sh "$OUTPUT_PATH" | cut -f1)"
success "Archive created: $OUTPUT_PATH ($ARCHIVE_SIZE)"
echo ""
echo -e "  Restore command:"
echo -e "  ${CYAN}hermes import $OUTPUT_PATH${NC}"
echo ""
echo -e "  Or manual restore:"
echo -e "  ${CYAN}tar -xzf $OUTPUT_PATH -C ~/.hermes/ --strip-components=1${NC}"
echo ""
