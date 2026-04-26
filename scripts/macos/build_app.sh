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

# Install dependencies
echo "📦 Installing dependencies (including node-pty)..."
npm install

# Rebuild native modules for Electron
echo "🏗️  Rebuilding native modules for Electron..."
if ./node_modules/.bin/electron-rebuild --version &> /dev/null; then
    ./node_modules/.bin/electron-rebuild
elif npx @electron/rebuild --version &> /dev/null; then
    npx @electron/rebuild
else
    echo "⚠️  Standard rebuild tools failed, attempting build anyway (electron-builder may handle it)..."
fi

# Run build
echo "🔨 Building DMG package..."
npm run build

echo "✅ Build complete! You can find the DMG in $APP_DIR/dist/"
