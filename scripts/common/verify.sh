#!/bin/bash

# scripts/common/verify.sh
# Verification script for Hermes Agent + Ollama

# --- UI Helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}"
echo "==============================================="
echo "   Hermes Agent + Ollama Verification"
echo "==============================================="
echo -e "${NC}"

# 1. Check Hermes Agent version
info "Checking Hermes Agent installation..."
if command -v hermes &> /dev/null; then
    HERMES_VERSION=$(hermes --version 2>&1)
    success "Hermes Agent found: $HERMES_VERSION"
else
    # Check common installation path if not in PATH
    if [ -f "$HOME/.hermes/bin/hermes" ]; then
        HERMES_VERSION=$($HOME/.hermes/bin/hermes --version 2>&1)
        success "Hermes Agent found at $HOME/.hermes/bin/hermes: $HERMES_VERSION"
        warn "Hermes is not in your PATH. Consider adding it: export PATH=\"\$HOME/.hermes/bin:\$PATH\""
    else
        error "Hermes Agent command not found."
    fi
fi

# 2. Verify config file existence
info "Checking configuration file..."
CONFIG_FILE="$HOME/.hermes/config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    success "Configuration file found at $CONFIG_FILE"
else
    warn "Configuration file not found at $CONFIG_FILE"
    info "Note: This is normal if you haven't run 'hermes' yet or configured it manually."
fi

# 3. Test Ollama endpoint
info "Testing Ollama API endpoint..."
OLLAMA_URL=${HERMES_BASE_URL:-"http://127.0.0.1:11434/v1"}
info "Using Ollama URL: $OLLAMA_URL"

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$OLLAMA_URL/models" 2>/dev/null)

if [ "$RESPONSE" == "200" ]; then
    success "Ollama API is responding correctly (HTTP 200)."
else
    error "Ollama API is not responding correctly (HTTP $RESPONSE)."
    info "Ensure Ollama is running and OLLAMA_HOST/HERMES_BASE_URL is correctly set."
fi

# 4. Check for pulled models
info "Checking for pulled models in Ollama..."
if command -v ollama &> /dev/null; then
    MODELS=$(ollama list | tail -n +2)
    if [ -n "$MODELS" ]; then
        success "Models found in Ollama:"
        echo "$MODELS" | awk '{print "  - " $1}'
    else
        warn "No models found in Ollama. You may need to run 'ollama pull hermes3'."
    fi
else
    # Fallback to API if ollama command is not available (e.g. remote or just API)
    MODELS_JSON=$(curl -s "$OLLAMA_URL/models" 2>/dev/null)
    if [ -n "$MODELS_JSON" ] && [[ "$MODELS_JSON" == *"data"* ]]; then
        success "Models found via API."
        # Simple extraction if possible, or just a generic success
    else
        warn "Could not list models via 'ollama' command or API."
    fi
fi

echo ""
info "Verification complete."
