#!/bin/bash

# Exit on error
set -e

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
APP_DIR="$PROJECT_ROOT/app"

echo "🚀 Starting Hermes Agent macOS Build..."

# Change to app directory
cd "$APP_DIR"

# Ensure Hermes is installed
echo "🔍 Checking for Hermes Agent..."
if ! command -v hermes &> /dev/null && [ ! -f "$HOME/.hermes/bin/hermes" ] && [ ! -f "$HOME/.local/bin/hermes" ]; then
    echo "⚠️  Hermes Agent not found. Running setup script..."
    bash "$SCRIPT_DIR/setup_hermes_ollama.sh"
fi

# Ensure a compatible Node.js version (18 or 20 LTS) for @electron/rebuild
# Node v21+ breaks yargs (used by @electron/rebuild) via ESM/CJS incompatibility
NODE_MAJOR=$(node -e "process.stdout.write(process.version.slice(1).split('.')[0])")
if [ "$NODE_MAJOR" -gt 20 ]; then
    echo "⚠️  Node.js v$NODE_MAJOR detected. @electron/rebuild requires Node 18 or 20 LTS."
    # Try to switch via nvm
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh"
        if nvm list 20 &>/dev/null; then
            echo "🔄 Switching to Node 20 via nvm..."
            nvm use 20
        elif nvm list 18 &>/dev/null; then
            echo "🔄 Switching to Node 18 via nvm..."
            nvm use 18
        else
            echo "📥 Installing Node 20 LTS via nvm..."
            nvm install 20
            nvm use 20
        fi
    else
        echo "❌ nvm not found. Please install Node 18 or 20 LTS and retry."
        echo "   Install nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
        exit 1
    fi
fi

# Install dependencies
echo "📦 Installing dependencies (including node-pty)..."
npm install

# Rebuild native modules for Electron
echo "🏗️  Rebuilding native modules for Electron..."
npx @electron/rebuild -f -w node-pty

# Run build
echo "🔨 Building DMG package..."
npm run build

echo "✅ Build complete! You can find the DMG in $APP_DIR/dist/"
