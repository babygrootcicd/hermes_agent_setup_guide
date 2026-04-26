#!/bin/bash

# scripts/macos/debug.sh
# macOS debug script for Hermes Agent + Ollama

set -e

# Build the application
./scripts/macos/build_app.sh

# Open the application
echo "Opening the application..."
open "dist/Hermes Agent-0.1.0-arm64.dmg"

# Wait for the application to open
echo "Waiting for the application to open..."
sleep 10

# Tail the log file
echo "Tailing the log file..."
tail -f ~/.hermes/logs/gui.log