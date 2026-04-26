#!/bin/bash

# scripts/macos/debug.sh
# macOS debug script for Hermes Agent + Ollama

set -e

# Build the application
./scripts/macos/build_app.sh

# Tail the log file
echo "Tailing the log file..."
tail -f ~/.hermes/logs/gui.log

# Wait for the application to start
echo "Waiting for the application to start..."
sleep 10

# Open the application
echo "Opening the application..."
open -a dist/Hermes Agent-xxx.dmg

# Wait for the application to open
echo "Waiting for the application to open..."
sleep 10