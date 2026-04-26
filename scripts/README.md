# Setup & Utility Scripts

This directory contains the automation scripts for installing and verifying the Hermes Agent + Ollama environment.

## Directory Structure

- `macos/`:
  - `setup_hermes_ollama.sh`: The primary installer for macOS users.
  - `build_app.sh`: Automates the packaging of the Electron Desktop App.
- `windows/`:
  - `setup_hermes_ollama.ps1`: The primary installer for Windows users (utilizes WSL2).
- `common/`:
  - `verify.sh`: Cross-platform Bash script to verify installation status.
  - `verify.ps1`: PowerShell version of the verification script.

## Usage
Always run scripts from the root of the repository to ensure paths are resolved correctly.
