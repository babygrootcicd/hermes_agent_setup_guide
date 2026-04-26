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

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Run build
echo "🔨 Building DMG package..."
npm run build

echo "✅ Build complete! You can find the DMG in $APP_DIR/dist/"
