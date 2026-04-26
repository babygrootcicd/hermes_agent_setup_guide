# Hermes Agent + Ollama Setup Guide

A comprehensive, one-click setup repository for running **Hermes Agent** locally with **Ollama** on macOS and Windows (WSL2). This project now includes a modern Desktop GUI and Docker support.

## 🚀 Quick Start

### macOS
```bash
./scripts/macos/setup_hermes_ollama.sh
 hermes chat --model hermes3
```

### Windows (WSL2)
PowerShell (Run as Administrator):
```powershell
.\scripts\windows\setup_hermes_ollama.ps1
```

---

## 📦 Project Components

### 🖥️ Desktop Application (Electron)
Located in `/app`. A modern chat interface that wraps the Hermes CLI.
- **Build**: `./scripts/macos/build_app.sh`
- **Output**: `app/dist/Hermes Agent-xxx.dmg`

### 🛠️ Setup Scripts
Located in `/scripts`. Automated scripts to check dependencies (Ollama, Hermes) and configure your environment.
- `macos/`: Bash scripts for macOS.
- `windows/`: PowerShell scripts for Windows/WSL2.
- `common/`: Cross-platform verification scripts.

### 🐳 Docker Support
Containerized Hermes environment for isolated deployments.
- **Run**: `docker-compose up --build`
- **Docs**: [Docker Deployment Guide](docs/80-docker-deployment.md)

### 📚 Documentation
- [Overview](docs/00-overview.md)
- [macOS Setup](docs/10-macos-setup.md)
- [Windows/WSL2 Setup](docs/20-windows-wsl2-setup.md)
- [Ollama Model Guide](docs/30-ollama-models.md)
- [Gateway Setup](docs/40-gateway-setup.md)
- [Troubleshooting](docs/60-troubleshooting.md)

---

## ⚙️ Configuration
See [examples/config](examples/config) for templates to set up your `~/.hermes/config.yaml` and `.env` files.
