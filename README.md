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
- **Docs**: [Docker Deployment Guide](docs/dev_progress/80-docker-deployment.md)

### 📚 Documentation
- [Overview](docs/dev_progress/00-overview.md)
- [macOS Setup](docs/dev_progress/10-macos-setup.md)
- [Windows/WSL2 Setup](docs/dev_progress/20-windows-wsl2-setup.md)
- [Ollama Model Guide](docs/dev_progress/30-ollama-models.md)
- [Gateway Setup](docs/dev_progress/40-gateway-setup.md)
- [Troubleshooting](docs/dev_progress/60-troubleshooting.md)
- [Docker Deployment Guide](docs/dev_progress/80-docker-deployment.md)

### 🚀 Advanced Operations (Phase 3)
- [Task Management](docs/90-task-management.md)
- [Advanced Tooling](docs/100-advanced-tooling.md)
- [Metrics & ROI Tracking](docs/110-metrics-tracking.md)
- [Automation Scripts](scripts/automation/update_models.sh)
- [Skill Library](examples/skills/README.md)
- [Project Retrospective](docs/dev_progress/retrospective_template.md)

---

## 🧠 The Hermes Workflow

To get the most out of Hermes Agent, we recommend a three-step workflow:

1.  **Decompose**: Break your complex goal into smaller, actionable sub-tasks. Use our [Task Templates](examples/task-templates/feature-implementation.md) to structure your requests.
2.  **Context**: Gather the necessary files and information for the agent. Use the [`gather_context.sh`](scripts/common/gather_context.sh) script to quickly bundle relevant project context.
3.  **Execute**: Pass the gathered context and the specific sub-task to Hermes for high-precision execution.

For a deep dive into effective agent orchestration, read the [Task Management & Context Provision Guide](docs/90-task-management.md).

---

## ⚙️ Configuration
See [examples/config](examples/config) for templates to set up your `~/.hermes/config.yaml` and `.env` files.

---

## 🔧 Troubleshooting

### `Error: Failed to start Hermes: posix_spawnp failed`

**Cause**: `node-pty`'s native binary was not compiled for Electron's ABI (or was never compiled at all). This happens when the app is built without running `@electron/rebuild` first.

**Fix**: Rebuild `node-pty` for Electron from inside the `app/` directory:

```bash
cd app
npm install
npx @electron/rebuild -f -w node-pty
npm run build
```

This compiles `pty.node` and `spawn-helper` against the correct Electron runtime. Re-open the DMG after building.

For full details on what was changed and why, see [002-fix-progress.md](docs/dev_progress/002-fix-progress.md).
