# Hermes Agent + Ollama Setup Guide

A local-first setup and orientation repository for running **Hermes Agent** with local Ollama, cloud providers, gateway automation, an Electron desktop app, and Docker-based isolation.

## Quick Start

### macOS / Linux
```bash
./scripts/macos/setup_hermes_ollama.sh
hermes model
hermes chat
```

### Windows (WSL2)
PowerShell (Run as Administrator):
```powershell
.\scripts\windows\setup_hermes_ollama.ps1
```

---

## Repository Map

| Path | Purpose |
|------|---------|
| [docs/charactistics](docs/charactistics) | Hermes Agent characteristics, architecture, setup guide, provider selection, storage layout, security, profiles, and session management |
| [docs/dev_progress](docs/dev_progress) | Implementation-phase setup docs for macOS, WSL2, Ollama, gateways, config, troubleshooting, Docker, security, task management, tooling, and metrics |
| [examples](examples) | Copyable config, provider, gateway, cron, memory, profile, security, skill, and task-template examples |
| [scripts](scripts) | Install, verification, backup, context-gathering, gateway, provider, app-build, and model-update scripts |
| [app](app) | Electron desktop wrapper around the Hermes CLI |
| [.agent-progress](.agent-progress) | Worker phase completion markers |
| [Dockerfile](Dockerfile), [docker-compose.yml](docker-compose.yml) | Containerized Hermes runtime support |

## Setup Guide

Start with the end-user setup path, then use the dev-progress docs for platform-specific implementation details:

- [Hermes Agent Quick-Start Setup Guide](docs/charactistics/setup-guide.md)
- [Characteristics Overview](docs/charactistics/00-overview.md)
- [Characteristics Documentation Index](docs/charactistics/README.md)
- [Dev Progress Overview](docs/dev_progress/00-overview.md)
- [macOS Setup](docs/dev_progress/10-macos-setup.md)
- [Windows/WSL2 Setup](docs/dev_progress/20-windows-wsl2-setup.md)
- [Ollama Model Guide](docs/dev_progress/30-ollama-models.md)
- [Gateway Setup](docs/dev_progress/40-gateway-setup.md)
- [Config Reference](docs/dev_progress/50-config-reference.md)
- [Troubleshooting](docs/dev_progress/60-troubleshooting.md)
- [Security](docs/dev_progress/70-security.md)
- [Docker Deployment Guide](docs/dev_progress/80-docker-deployment.md)

## Examples

- [Configuration templates](examples/config): base `config.yaml`, `.env`, and provider snippets for Anthropic, Copilot, Gemini, Ollama, and OpenRouter.
- [Gateway configs](examples/gateway): Telegram, Discord, and Slack examples.
- [Cron jobs](examples/cron): daily briefing, disk monitor, GitHub triage, and study-review schedules with prompt files.
- [Memory and profiles](examples/memory): starter `MEMORY.md` and `USER.md` files, including a DevSecOps profile.
- [Security examples](examples/security): Docker sandbox, security baseline, and threat checklist.
- [Skill Library](examples/skills/README.md)
- [Task template](examples/task-templates/feature-implementation.md)

## Scripts

- [scripts/macos/setup_hermes_ollama.sh](scripts/macos/setup_hermes_ollama.sh): primary macOS setup script.
- [scripts/windows/setup_hermes_ollama.ps1](scripts/windows/setup_hermes_ollama.ps1): Windows/WSL2 setup script.
- [scripts/common/verify.sh](scripts/common/verify.sh) and [scripts/common/verify.ps1](scripts/common/verify.ps1): installation checks.
- [scripts/common/gather_context.sh](scripts/common/gather_context.sh): bundle relevant project context for an agent task.
- [scripts/common/backup.sh](scripts/common/backup.sh) and [scripts/common/export-sessions.sh](scripts/common/export-sessions.sh): backup and session export helpers.
- [scripts/macos/setup-gateway.sh](scripts/macos/setup-gateway.sh): gateway setup helper.
- [scripts/macos/setup-provider-gemini.sh](scripts/macos/setup-provider-gemini.sh): Gemini provider setup helper.
- [scripts/automation/update_models.sh](scripts/automation/update_models.sh): model update automation.

## Desktop App

The Electron app in [app](app) wraps the Hermes CLI with a desktop chat interface.

- Build: `./scripts/macos/build_app.sh`
- Output: `app/dist/Hermes Agent-xxx.dmg`

## Docker Support

Containerized Hermes support is available for isolated deployments.

```bash
docker-compose up --build
```

See [Docker Deployment Guide](docs/dev_progress/80-docker-deployment.md).

## Phase Artifacts

Implementation phases are complete (11/11) and tracked in [docs/charactistics/progress.md](docs/charactistics/progress.md).

Development phase docs and markers are split between:

- [docs/dev_progress](docs/dev_progress): authored setup and operational documentation.
- [docs/dev_progress/progress.md](docs/dev_progress/progress.md): dev-progress tracking.
- [docs/charactistics/progress.md](docs/charactistics/progress.md): characteristics documentation tracking.
- [.agent-progress](.agent-progress): worker completion markers, including this overview/orientation phase.

## Advanced Operations

- [Task Management](docs/dev_progress/90-task-management.md)
- [Advanced Tooling](docs/dev_progress/100-advanced-tooling.md)
- [Metrics & ROI Tracking](docs/dev_progress/110-metrics-tracking.md)
- [Project Retrospective](docs/dev_progress/retrospective_template.md)

---

## The Hermes Workflow

To get the most out of Hermes Agent, we recommend a three-step workflow:

1.  **Decompose**: Break your complex goal into smaller, actionable sub-tasks. Use our [Task Templates](examples/task-templates/feature-implementation.md) to structure your requests.
2.  **Context**: Gather the necessary files and information for the agent. Use the [`gather_context.sh`](scripts/common/gather_context.sh) script to quickly bundle relevant project context.
3.  **Execute**: Pass the gathered context and the specific sub-task to Hermes for high-precision execution.

For a deep dive into effective agent orchestration, read the [Task Management & Context Provision Guide](docs/dev_progress/90-task-management.md).

---

## Configuration
See [examples/config](examples/config) for templates to set up your `~/.hermes/config.yaml` and `.env` files.

---

## Troubleshooting

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
