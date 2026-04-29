#!/usr/bin/env bash
# scripts/common/scaffold-hermes-dir.sh
# Creates the full ~/.hermes/ directory structure with starter template files.
# Safe to run on an existing installation — never overwrites existing files.

set -euo pipefail

# --- UI Helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
success() { echo -e "${GREEN}[CREATED]${NC} $1"; }
skip()    { echo -e "${YELLOW}[EXISTS]${NC}  $1 (skipped)"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
error()   { echo -e "${RED}[ERROR]${NC}   $1"; exit 1; }
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

# --- Resolve repo root (location of this script's repo) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HERMES_DIR="$HOME/.hermes"

echo -e "${GREEN}${BOLD}"
echo "=============================================="
echo "   Hermes Agent — Directory Scaffold"
echo "=============================================="
echo -e "${NC}"
info "Repo root : $REPO_ROOT"
info "Target    : $HERMES_DIR"

# --- Warn if already exists ---
if [[ -d "$HERMES_DIR" ]]; then
    warn "~/.hermes/ already exists."
    warn "Existing files will NOT be overwritten. Only missing items will be created."
    echo ""
fi

# --- Helper: create dir ---
make_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        success "$dir/"
    else
        skip "$dir/"
    fi
}

# --- Helper: create file from heredoc if missing ---
create_file_if_missing() {
    local path="$1"
    local content="$2"
    if [[ ! -f "$path" ]]; then
        mkdir -p "$(dirname "$path")"
        (umask 077 && printf '%s\n' "$content" > "$path")
        success "$path"
    else
        skip "$path"
    fi
}

# --- Helper: copy template if source exists and dest missing ---
copy_template() {
    local src="$1"
    local dest="$2"
    if [[ -f "$src" && ! -f "$dest" ]]; then
        (umask 077 && cp "$src" "$dest")
        success "$dest (copied from template)"
    elif [[ ! -f "$src" ]]; then
        : # source template doesn't exist yet — handled by create_file_if_missing
    else
        skip "$dest"
    fi
}

append_line_once() {
    local file="$1"
    local line="$2"
    if [[ -f "$file" ]] && grep -Fqx "$line" "$file"; then
        skip "$file already contains: $line"
        return
    fi
    (umask 077 && printf '%s\n' "$line" >> "$file")
    success "Added to $file: $line"
}

# ============================================================
section "Core Directories"
# ============================================================
make_dir "$HERMES_DIR"
make_dir "$HERMES_DIR/memories"
make_dir "$HERMES_DIR/skills"
make_dir "$HERMES_DIR/sessions"
make_dir "$HERMES_DIR/cron"
make_dir "$HERMES_DIR/cron/outputs"
make_dir "$HERMES_DIR/logs"
make_dir "$HERMES_DIR/profiles"

# ============================================================
section "config.yaml"
# ============================================================
CONFIG_TEMPLATE_SRC="$REPO_ROOT/examples/config/config.yaml.template"
copy_template "$CONFIG_TEMPLATE_SRC" "$HERMES_DIR/config.yaml"

CONFIG_CONTENT='# Hermes Agent Configuration
# Run "hermes model" to configure your provider interactively.
# Full reference: https://hermes-agent.nousresearch.com/docs/user-guide/configuration

model:
  provider: ""        # e.g. auto | gemini | copilot | anthropic | openrouter
  default: ""         # e.g. gemini-2.5-flash | gpt-4o | claude-sonnet-4-5
  context_length: 32768
  # base_url: http://localhost:11434/v1
  # api_key: ollama

terminal:
  backend: local      # local | docker | modal
  timeout: 180

memory:
  memory_enabled: true
  user_profile_enabled: true

agent:
  max_turns: 20

toolsets:
  enabled:
    - terminal
    - skills
    - memory
  disabled:
    - browser_automation
    - code_execution

storage:
  type: local
  path: ~/.hermes

delegation:
  max_concurrent_children: 2
  max_spawn_depth: 2'

create_file_if_missing "$HERMES_DIR/config.yaml" "$CONFIG_CONTENT"

# ============================================================
section ".env (API Keys)"
# ============================================================
ENV_TEMPLATE_SRC="$REPO_ROOT/examples/config/.env.template"
copy_template "$ENV_TEMPLATE_SRC" "$HERMES_DIR/.env"

ENV_CONTENT='# Hermes Agent — API Keys & Tokens
# This file is NEVER injected into prompts.
# Keep it out of all version control and shared backups.

# LLM Providers
# GOOGLE_API_KEY=your_key_here
# ANTHROPIC_API_KEY=your_key_here
# OPENAI_API_KEY=your_key_here
# OPENROUTER_API_KEY=your_key_here

# Messaging Gateways
# TELEGRAM_BOT_TOKEN=your_token_here
# DISCORD_BOT_TOKEN=your_token_here
# SLACK_BOT_TOKEN=your_token_here

# Other Integrations
# GITHUB_TOKEN=your_token_here'

create_file_if_missing "$HERMES_DIR/.env" "$ENV_CONTENT"

# ============================================================
section "Storage Files"
# ============================================================
create_file_if_missing "$HERMES_DIR/auth.json" "{}"
create_file_if_missing "$HERMES_DIR/cron/jobs.yaml" "jobs: []"
create_file_if_missing "$HERMES_DIR/logs/agent.log" ""
create_file_if_missing "$HERMES_DIR/logs/gateway.log" ""
create_file_if_missing "$HERMES_DIR/logs/error.log" ""
create_file_if_missing "$HERMES_DIR/logs/cron.log" ""

STATE_DB="$HERMES_DIR/state.db"
if [[ -f "$STATE_DB" ]]; then
    skip "$STATE_DB"
else
    if command -v python3 >/dev/null 2>&1; then
        python3 - <<PYEOF
import sqlite3
db_path = r"$STATE_DB"
con = sqlite3.connect(db_path)
con.execute("PRAGMA journal_mode=WAL;")
con.execute("PRAGMA foreign_keys=ON;")
con.commit()
con.close()
PYEOF
        success "$STATE_DB (initialized with SQLite WAL)"
    else
        create_file_if_missing "$STATE_DB" ""
        warn "python3 not found; state.db created as empty file (WAL not initialized)"
    fi
fi

# ============================================================
section "Memory Templates"
# ============================================================
# Try copying from repo templates first, then create starters
copy_template "$REPO_ROOT/examples/memory/MEMORY.md" "$HERMES_DIR/memories/MEMORY.md"
copy_template "$REPO_ROOT/examples/memory/USER.md"   "$HERMES_DIR/memories/USER.md"

MEMORY_STARTER='# Hermes Agent — MEMORY.md
# Agent personal notes: project environment, conventions, completed work.
# Capacity: ~2,200 characters. Loaded at every session start.
# Do NOT store: raw logs, temporary paths, large code blocks, secrets.

## Environment
# - OS: macOS / Linux / WSL2
# - Shell: zsh / bash
# - Docker: available

## Projects
# - Add your active projects here

## Conventions
# - Add repo/commit/PR conventions here

## Corrections
# - Add known quirks and workarounds here'

USER_STARTER='# Hermes Agent — USER.md
# User profile and preferences. Capacity: ~1,375 characters.
# Loaded at every session start. Edit to reflect your actual preferences.

## Identity
# Name:
# Role:
# Timezone:

## Language & Style
# - Respond in: English / Traditional Chinese
# - Format: concise, no filler text, repo-style deliverables

## Technical Level
# - Strong in: (e.g. Go, Linux, Docker)
# - Learning: (e.g. React, Kubernetes)

## Format Preferences
# - DevOps topics: docker-compose + GitHub Actions + runbook.md
# - Security topics: threat model / control / detection / response
# - Summary length: ≤ 2 sentences per item, always include source links'

create_file_if_missing "$HERMES_DIR/memories/MEMORY.md" "$MEMORY_STARTER"
create_file_if_missing "$HERMES_DIR/memories/USER.md"   "$USER_STARTER"

# ============================================================
section "Permissions"
# ============================================================
chmod 700 "$HERMES_DIR"
chmod 600 "$HERMES_DIR/.env"
chmod 600 "$HERMES_DIR/auth.json"
chmod 600 "$HERMES_DIR/state.db" "$HERMES_DIR/cron/jobs.yaml"
chmod 600 "$HERMES_DIR"/logs/*.log
info "Permissions set: ~/.hermes/ (700), secrets/state/logs (600)"

# ============================================================
section "~/.gitignore Safety Net"
# ============================================================
GITIGNORE="$HOME/.gitignore"
touch "$GITIGNORE"
append_line_once "$GITIGNORE" ".hermes/.env"
append_line_once "$GITIGNORE" ".hermes/auth.json"
append_line_once "$GITIGNORE" ".hermes/state.db"
append_line_once "$GITIGNORE" ".hermes/sessions/"
append_line_once "$GITIGNORE" ".hermes/logs/"
append_line_once "$GITIGNORE" ".hermes/cron/outputs/"

# ============================================================
section "Summary"
# ============================================================
echo ""
echo -e "${GREEN}${BOLD}Scaffold complete.${NC}"
echo ""
echo "  Next steps:"
echo "    1. Run: hermes model            — configure your LLM provider"
echo "    2. Edit: ~/.hermes/memories/USER.md   — add your preferences"
echo "    3. Edit: ~/.hermes/memories/MEMORY.md — add your project context"
echo "    4. Run: hermes chat             — start your first session"
echo ""
echo "  Structure created at: $HERMES_DIR"
echo ""
