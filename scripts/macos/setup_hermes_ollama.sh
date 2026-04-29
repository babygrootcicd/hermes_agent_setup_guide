#!/bin/bash

# scripts/macos/setup_hermes_ollama.sh
# macOS setup script for Hermes Agent + Ollama

set -euo pipefail

# --- Configuration ---
DEFAULT_OLLAMA_URL="http://127.0.0.1:11434/v1"
DEFAULT_MODEL="qwen2.5-coder:7b"
DEFAULT_CONTEXT_LENGTH="32768"

# --- UI Helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

echo -e "${GREEN}"
echo "==============================================="
echo "   Hermes Agent + Ollama Setup for macOS"
echo "==============================================="
echo -e "${NC}"

# 1. Check for Ollama installation
info "Checking for Ollama installation..."
if command -v ollama &> /dev/null; then
    success "Ollama is installed."
else
    warn "Ollama command not found in your PATH."
    if [ -d "/Applications/Ollama.app" ]; then
        info "Ollama.app found in /Applications, but 'ollama' command is not in PATH."
    else
        info "Please download and install Ollama from: https://ollama.com/download/mac"
    fi
fi

# Check if Ollama is running
info "Checking if Ollama service is running..."
if curl -fsS http://127.0.0.1:11434/api/tags > /dev/null; then
    success "Ollama service is running and accessible."
else
    warn "Ollama service does not appear to be running."
    info "Attempting to start Ollama application..."
    if [ -d "/Applications/Ollama.app" ]; then
        open -a Ollama
        info "Waiting for Ollama to initialize (10 seconds)..."
        sleep 10
        if curl -fsS http://127.0.0.1:11434/api/tags > /dev/null; then
            success "Ollama service is now running."
        else
            error "Still couldn't verify Ollama service. Please start Ollama manually and re-run."
        fi
    else
        error "Ollama.app not found in /Applications. Please install it and start it manually."
    fi
fi

# 2. Check for Hermes installation
info "Checking for Hermes Agent installation..."
if command -v hermes &> /dev/null; then
    success "Hermes Agent is already installed."
else
    info "Hermes Agent not found. Installing via official script..."
    # Official install.sh: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    if curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash; then
        success "Hermes Agent installation script executed."
        
        # Try to find the binary to add to current session PATH
        if [ -f "$HOME/.hermes/bin/hermes" ]; then
            export PATH="$HOME/.hermes/bin:$PATH"
            success "Hermes binary found and added to current session PATH."
        fi
    else
        error "Hermes Agent installation failed."
        exit 1
    fi
fi

# 3. Check for recommended model and offer to pull
echo ""
info "Checking for recommended Ollama model: ${DEFAULT_MODEL}"
if curl -fsS http://127.0.0.1:11434/api/tags | grep -q "\"${DEFAULT_MODEL}\""; then
    success "'${DEFAULT_MODEL}' is already available."
else
    warn "'${DEFAULT_MODEL}' not found in your local Ollama."
    read -p "Would you like to pull '${DEFAULT_MODEL}' now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Pulling '${DEFAULT_MODEL}'... this may take a few minutes."
        ollama pull "${DEFAULT_MODEL}"
        success "'${DEFAULT_MODEL}' pulled successfully."
    else
        info "Skipping model pull. Run 'ollama pull ${DEFAULT_MODEL}' later."
    fi
fi

# 4. Guide user to configure Hermes model provider
echo ""
info "--- Configuration Guide ---"
echo -e "Run ${GREEN}hermes model${NC} and choose ${YELLOW}Custom endpoint${NC}."
echo -e "Use these values:"
echo -e "  URL:            ${GREEN}${DEFAULT_OLLAMA_URL}${NC}"
echo -e "  API key:        ${GREEN}ollama${NC}"
echo -e "  Model:          ${GREEN}${DEFAULT_MODEL}${NC}"
echo -e "  Context length: ${GREEN}${DEFAULT_CONTEXT_LENGTH}${NC}"
echo ""
warn "Avoid 'hermes3' for agentic tool use; use qwen2.5-coder models instead."

# 5. Verification instructions
echo ""
info "--- Verification & Usage ---"
echo -e "1. Confirm model is present:"
echo -e "   ${GREEN}ollama list${NC}"
echo ""
echo -e "2. Configure provider with wizard:"
echo -e "   ${GREEN}hermes model${NC}"
echo ""
echo -e "3. Start a fast session:"
echo -e "   ${GREEN}hermes chat --model ${DEFAULT_MODEL} --toolsets terminal,skills --max-turns 12${NC}"
echo ""
echo -e "Note: If you encounter issues, ensure Docker is installed and running,"
echo -e "as some Hermes Agent features may require it."
echo ""
success "Setup script completed!"
