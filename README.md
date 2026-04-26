# Hermes Agent + Ollama Setup Guide

This repository provides a comprehensive guide and automation scripts for setting up [Hermes Agent](https://github.com/mhermes-agent/hermes) with a local [Ollama](https://ollama.com/) instance on macOS and Windows (WSL2).

## Overview

The goal of this project is to simplify the deployment of Hermes Agent by providing:
- One-click installation and configuration scripts for macOS and Windows.
- Detailed documentation for integrating local Ollama models.
- Step-by-step guides for setting up various Gateways (Telegram, Discord, Slack, Email, etc.).
- Validation and troubleshooting procedures.

## Key Features

- **Automated Setup**: Leverages the official Hermes `install.sh` with added automation for environment-specific needs.
- **Local AI Integration**: Optimized configurations for running LLMs locally via Ollama.
- **Multi-Platform Support**: Tailored scripts for macOS and Windows (WSL2).
- **Comprehensive Docs**: Clear explanations of architecture, data flow, and troubleshooting.

## Repository Structure

- `docs/`: Detailed documentation, starting with [00-overview.md](docs/00-overview.md).
- `scripts/`: Platform-specific installation and setup scripts.
  - `macos/`: Scripts for macOS users.
  - `windows/`: Scripts for Windows (WSL2) users.
  - `common/`: Shared utility scripts.
- `examples/config/`: Template files for configuration.

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/hermes_agent_setup_guide.git
   cd hermes_agent_setup_guide
   ```
2. **Consult the Overview:** Read [docs/00-overview.md](docs/00-overview.md) to understand the system architecture.
3. **Follow Platform Guides:**
   - [macOS Setup Guide](docs/macos-setup.md) (Coming soon)
   - [Windows Setup Guide](docs/windows-setup.md) (Coming soon)

## Prerequisites

- [Docker](https://www.docker.com/) (Required for Hermes Agent)
- [Ollama](https://ollama.com/) (For local LLM support)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
