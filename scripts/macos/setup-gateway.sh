#!/usr/bin/env bash
# setup-gateway.sh — Interactive gateway setup for Hermes Agent (macOS)
#
# Usage:
#   chmod +x scripts/macos/setup-gateway.sh
#   ./scripts/macos/setup-gateway.sh [telegram|discord|slack]
#
# What this script does:
#   1. Guides you through bot creation (instructions + links)
#   2. Prompts for required tokens and IDs
#   3. Writes credentials to ~/.hermes/.env
#   4. Appends gateway config block to ~/.hermes/config.yaml
#   5. Optionally installs the gateway as a macOS launchd service

set -euo pipefail

# ─── Colours ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERR]${RESET}  $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}═══ $* ═══${RESET}\n"; }

# ─── Preflight Checks ─────────────────────────────────────────────────────
check_hermes() {
    if ! command -v hermes &>/dev/null; then
        error "hermes not found in PATH. Install Hermes Agent first."
        echo "  pip install hermes-agent   OR   pipx install hermes-agent"
        exit 1
    fi
    success "Hermes Agent found: $(hermes --version 2>/dev/null || echo 'version unknown')"
}

check_hermes_dir() {
    local hermes_dir="$HOME/.hermes"
    if [[ ! -d "$hermes_dir" ]]; then
        warn "~/.hermes/ not found. Run 'hermes model' first to initialise Hermes."
        exit 1
    fi
    success "~/.hermes/ directory exists"
}

# ─── Env File Helper ──────────────────────────────────────────────────────
write_env_var() {
    local key="$1"
    local value="$2"
    local env_file="$HOME/.hermes/.env"
    local escaped_value

    escaped_value="$(printf '%s' "$value" | sed 's/[&|\\]/\\&/g')"

    touch "$env_file"
    chmod 600 "$env_file"

    if grep -q "^${key}=" "$env_file" 2>/dev/null; then
        # Update existing entry
        sed -i '' "s|^${key}=.*|${key}=${escaped_value}|" "$env_file"
        info "Updated ${key} in ~/.hermes/.env"
    else
        echo "${key}=${value}" >> "$env_file"
        info "Wrote ${key} to ~/.hermes/.env"
    fi
}

# ─── Config File Helper ───────────────────────────────────────────────────
append_config_block() {
    local platform="$1"
    local config_file="$HOME/.hermes/config.yaml"
    local template_file="$(dirname "$0")/../../examples/gateway/${platform}.config.yaml"

    if [[ ! -f "$config_file" ]]; then
        warn "~/.hermes/config.yaml not found. Hermes may not be initialised."
        warn "Printing config block to stdout instead:"
        echo "---"
        cat "$template_file" 2>/dev/null || echo "(template file not found at $template_file)"
        return
    fi

    if grep -q "^${platform}:" "$config_file"; then
        warn "A '${platform}:' block already exists in config.yaml. Skipping to avoid duplication."
        warn "Edit ~/.hermes/config.yaml manually to update the ${platform} section."
        return
    fi

    echo "" >> "$config_file"
    if [[ -f "$template_file" ]]; then
        # Append the full example block once. The template already contains the
        # top-level key and practical comments, so do not synthesize another key.
        cat "$template_file" >> "$config_file"
        success "Appended ${platform} gateway block to ~/.hermes/config.yaml"
    else
        warn "Template file not found at $template_file"
        warn "Manually add the ${platform}: block to ~/.hermes/config.yaml"
    fi
}

# ─── launchd Service Installer ────────────────────────────────────────────
install_launchd_service() {
    local platform="$1"
    local plist_label="com.hermes.gateway.${platform}"
    local plist_path="$HOME/Library/LaunchAgents/${plist_label}.plist"
    local log_dir="$HOME/.hermes/logs"

    mkdir -p "$log_dir"

    cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plist_label}</string>

    <key>ProgramArguments</key>
    <array>
        <string>$(command -v hermes)</string>
        <string>gateway</string>
        <string>start</string>
        <string>${platform}</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${log_dir}/gateway-${platform}.log</string>

    <key>StandardErrorPath</key>
    <string>${log_dir}/gateway-${platform}-error.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    </dict>
</dict>
</plist>
EOF

    launchctl load "$plist_path" 2>/dev/null || true
    success "launchd service installed: $plist_label"
    info "  Start:   launchctl start $plist_label"
    info "  Stop:    launchctl stop $plist_label"
    info "  Remove:  launchctl unload $plist_path && rm $plist_path"
    info "  Logs:    tail -f $log_dir/gateway-${platform}.log"
}

# ─── Platform Setup: Telegram ─────────────────────────────────────────────
setup_telegram() {
    header "Telegram Gateway Setup"

    echo "Step 1: Create a Telegram bot"
    echo "  • Open Telegram and message @BotFather"
    echo "  • Send: /newbot"
    echo "  • Follow prompts (name + username ending in 'bot')"
    echo "  • Copy the bot token (format: 123456:ABC-DEF...)"
    echo ""

    read -rsp "Paste your Telegram bot token: " bot_token
    echo ""
    if [[ -z "$bot_token" ]]; then
        error "Bot token cannot be empty."
        exit 1
    fi
    write_env_var "TELEGRAM_BOT_TOKEN" "$bot_token"

    echo ""
    echo "Step 2: Find your Telegram user ID"
    echo "  • Message @userinfobot on Telegram"
    echo "  • It will reply with your numeric user ID"
    echo ""

    read -rp "Enter your Telegram user ID (numeric): " user_id
    if [[ -z "$user_id" ]] || ! [[ "$user_id" =~ ^[0-9]+$ ]]; then
        error "User ID must be a number."
        exit 1
    fi

    echo ""
    info "Writing gateway config to ~/.hermes/config.yaml ..."
    append_config_block "telegram"

    # Patch the user ID placeholder in config
    if grep -q "123456789" "$HOME/.hermes/config.yaml"; then
        sed -i '' "s/123456789/${user_id}/g" "$HOME/.hermes/config.yaml"
        success "Set allowed_users and default_delivery_chat_id to $user_id"
    fi

    echo ""
    read -rp "Install Telegram gateway as a launchd service (auto-start on login)? [y/N] " install_service
    if [[ "$install_service" =~ ^[Yy]$ ]]; then
        install_launchd_service "telegram"
    else
        info "To start the gateway manually: hermes gateway start telegram"
        info "To run in background:          tmux new -s hermes-telegram 'hermes gateway start telegram'"
    fi

    echo ""
    success "Telegram gateway setup complete!"
    info "Test it: open Telegram, message your bot, and type 'hello'"
}

# ─── Platform Setup: Discord ──────────────────────────────────────────────
setup_discord() {
    header "Discord Gateway Setup"

    echo "Step 1: Create a Discord application and bot"
    echo "  • Go to: https://discord.com/developers/applications"
    echo "  • New Application → name it"
    echo "  • Bot tab → Add Bot → copy token"
    echo "  • Enable: Message Content Intent (under Privileged Gateway Intents)"
    echo ""

    read -rsp "Paste your Discord bot token: " bot_token
    echo ""
    if [[ -z "$bot_token" ]]; then
        error "Bot token cannot be empty."
        exit 1
    fi
    write_env_var "DISCORD_BOT_TOKEN" "$bot_token"

    echo ""
    echo "Step 2: Invite the bot to your server"
    echo "  • OAuth2 → URL Generator"
    echo "  • Scopes: bot, applications.commands"
    echo "  • Bot Permissions: Send Messages, Read Message History, Use Slash Commands,"
    echo "                     Embed Links, Attach Files, Add Reactions"
    echo "  • Copy the generated URL and open in browser to invite the bot"
    echo ""

    echo "Step 3: Find your Guild (server) ID and Channel ID"
    echo "  • Enable Developer Mode: User Settings → Advanced → Developer Mode"
    echo "  • Right-click server name → Copy Server ID"
    echo "  • Right-click channel → Copy Channel ID"
    echo ""

    read -rp "Enter your Discord guild (server) ID: " guild_id
    read -rp "Enter your Discord channel ID for Hermes: " channel_id

    info "Writing gateway config to ~/.hermes/config.yaml ..."
    append_config_block "discord"

    if [[ -n "$guild_id" ]]; then
        sed -i '' "s/1234567890123456789/${guild_id}/g" "$HOME/.hermes/config.yaml"
    fi
    if [[ -n "$channel_id" ]]; then
        sed -i '' "s/9876543210987654321/${channel_id}/g" "$HOME/.hermes/config.yaml"
    fi

    echo ""
    read -rp "Install Discord gateway as a launchd service? [y/N] " install_service
    if [[ "$install_service" =~ ^[Yy]$ ]]; then
        install_launchd_service "discord"
    else
        info "To start manually: hermes gateway start discord"
    fi

    echo ""
    success "Discord gateway setup complete!"
}

# ─── Platform Setup: Slack ────────────────────────────────────────────────
setup_slack() {
    header "Slack Gateway Setup"

    echo "Step 1: Create a Slack app"
    echo "  • Go to: https://api.slack.com/apps → Create New App → From Scratch"
    echo "  • Socket Mode → Enable Socket Mode"
    echo "  • Basic Information → App-Level Tokens → Generate Token"
    echo "    Scope: connections:write → copy as SLACK_APP_TOKEN (xapp-...)"
    echo ""

    read -rsp "Paste your Slack App-Level Token (xapp-...): " app_token
    echo ""
    if [[ -z "$app_token" ]]; then
        error "App token cannot be empty."
        exit 1
    fi
    write_env_var "SLACK_APP_TOKEN" "$app_token"

    echo ""
    echo "Step 2: Get Bot Token"
    echo "  • OAuth & Permissions → Bot Token Scopes:"
    echo "    channels:history, channels:read, chat:write, groups:history,"
    echo "    groups:read, im:history, im:read, im:write, users:read"
    echo "  • Install to Workspace → copy Bot User OAuth Token (xoxb-...)"
    echo ""

    read -rsp "Paste your Slack Bot Token (xoxb-...): " bot_token
    echo ""
    if [[ -z "$bot_token" ]]; then
        error "Bot token cannot be empty."
        exit 1
    fi
    write_env_var "SLACK_BOT_TOKEN" "$bot_token"

    echo ""
    echo "Step 3: Enable Event Subscriptions"
    echo "  • Event Subscriptions → Enable Events"
    echo "  • Subscribe to bot events: message.channels, message.groups, message.im"
    echo "  • Save Changes"
    echo ""

    read -rp "Enter your Slack workspace ID (T...): " workspace_id
    read -rp "Enter the channel name for Hermes (without #): " channel_name

    info "Writing gateway config to ~/.hermes/config.yaml ..."
    append_config_block "slack"

    if [[ -n "$workspace_id" ]]; then
        sed -i '' "s/T01234ABCDE/${workspace_id}/g" "$HOME/.hermes/config.yaml"
    fi
    if [[ -n "$channel_name" ]]; then
        sed -i '' "s/hermes-agent/${channel_name}/g" "$HOME/.hermes/config.yaml"
    fi

    echo ""
    read -rp "Install Slack gateway as a launchd service? [y/N] " install_service
    if [[ "$install_service" =~ ^[Yy]$ ]]; then
        install_launchd_service "slack"
    else
        info "To start manually: hermes gateway start slack"
    fi

    echo ""
    success "Slack gateway setup complete!"
}

# ─── Main ─────────────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}Hermes Agent — Gateway Setup (macOS)${RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    check_hermes
    check_hermes_dir

    local platform="${1:-}"

    if [[ -z "$platform" ]]; then
        echo ""
        echo "Which messaging platform do you want to set up?"
        echo "  1) telegram"
        echo "  2) discord"
        echo "  3) slack"
        echo ""
        read -rp "Enter choice [1/2/3] or platform name: " choice
        case "$choice" in
            1|telegram) platform="telegram" ;;
            2|discord)  platform="discord"  ;;
            3|slack)    platform="slack"    ;;
            *) error "Unknown platform: $choice"; exit 1 ;;
        esac
    fi

    case "$platform" in
        telegram) setup_telegram ;;
        discord)  setup_discord  ;;
        slack)    setup_slack    ;;
        *)
            error "Unknown platform: $platform"
            echo "Usage: $0 [telegram|discord|slack]"
            exit 1
            ;;
    esac
}

main "$@"
