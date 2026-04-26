#!/bin/bash

# scripts/macos/setup_hermes_ollama.sh
# macOS setup script for Hermes Agent + Ollama

set -e

# --- Configuration ---
DEFAULT_OLLAMA_URL="http://127.0.0.1:11434/v1"

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
if curl -s http://127.0.0.1:11434/api/tags > /dev/null; then
    success "Ollama service is running and accessible."
else
    warn "Ollama service does not appear to be running."
    info "Attempting to start Ollama application..."
    if [ -d "/Applications/Ollama.app" ]; then
        open -a Ollama
        info "Waiting for Ollama to initialize (10 seconds)..."
        sleep 10
        if curl -s http://127.0.0.1:11434/api/tags > /dev/null; then
            success "Ollama service is now running."
        else
            warn "Still couldn't verify Ollama service. Please ensure it's running manually."
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

# 3. Guide user to set base URL
echo ""
info "--- Configuration Guide ---"
echo -e "Hermes Agent needs to know where your Ollama instance is running."
echo -e "Default Ollama API Base URL: ${GREEN}${DEFAULT_OLLAMA_URL}${NC}"
echo ""
echo -e "To configure this, you can set the ${YELLOW}HERMES_BASE_URL${NC} environment variable."
echo -e "Add the following line to your shell profile (${YELLOW}~/.zshrc${NC} or ${YELLOW}~/.bash_profile${NC}):"
echo ""
echo -e "    ${BLUE}export HERMES_BASE_URL=\"${DEFAULT_OLLAMA_URL}\"${NC}"
echo ""
echo -e "After adding it, restart your terminal or run ${YELLOW}source ~/.zshrc${NC}."

# 4. Verification instructions
echo ""
info "--- Verification & Usage ---"
echo -e "1. Pull a model with Ollama (e.g., Hermes 3):"
echo -e "   ${GREEN}ollama pull hermes3${NC}"
echo ""
echo -e "2. Start a chat with Hermes Agent:"
echo -e "   ${GREEN}hermes chat --model hermes3${NC}"
echo ""
echo -e "Note: If you encounter issues, ensure Docker is installed and running,"
echo -e "as some Hermes Agent features may require it."
echo ""
success "Setup script completed!"
