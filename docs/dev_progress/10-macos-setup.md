# macOS Setup Guide

This guide provides detailed instructions for setting up Hermes Agent with a local Ollama instance on macOS.

## Prerequisites

Before starting, ensure you have the following:
- A Mac with macOS 12 (Monterey) or later.
- At least 8GB of RAM (16GB+ recommended for larger models).
- Basic familiarity with the Terminal.

## Step 1: Install and Run Ollama

Ollama is the engine that runs the Large Language Models (LLMs) locally.

1.  **Download**: Visit [ollama.com/download/mac](https://ollama.com/download/mac) and download the application.
2.  **Install**: Unzip the downloaded file and move `Ollama.app` to your `/Applications` folder.
3.  **Launch**: Open `Ollama.app`. You should see an Ollama icon in your menu bar.
4.  **Verify**: Open your terminal and run:
    ```bash
    curl http://127.0.0.1:11434/api/tags
    ```
    **Expected Output**: A JSON object (likely empty `{"models":[]}` if no models are installed yet) or a list of models.

## Step 2: Install Hermes Agent

Use the official installation script provided by Nous Research.

1.  **Run Installation Script**:
    ```bash
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    ```
2.  **Update PATH**: The script installs Hermes to `~/.hermes/bin`. Add it to your shell profile (e.g., `~/.zshrc` or `~/.bash_profile`):
    ```bash
    echo 'export PATH="$HOME/.hermes/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
    ```
3.  **Verify Installation**:
    ```bash
    hermes --version
    ```
    **Expected Output**: The version number of Hermes Agent.

## Step 3: Configure Hermes for Ollama

Hermes Agent needs to be pointed to your local Ollama API endpoint.

1.  **Set Environment Variable**: Add the following to your shell profile:
    ```bash
    echo 'export HERMES_BASE_URL="http://127.0.0.1:11434/v1"' >> ~/.zshrc
    source ~/.zshrc
    ```
2.  **Run Setup**:
    ```bash
    hermes setup
    ```
    Follow the interactive prompts to configure your preferences.

## Step 4: Pull a Model and Start Chatting

1.  **Pull Hermes 3**:
    ```bash
    ollama pull hermes3
    ```
2.  **Start Chat**:
    ```bash
    hermes chat --model hermes3
    ```

## Automated Setup

Alternatively, you can use the provided setup script in this repository:

```bash
bash scripts/macos/setup_hermes_ollama.sh
```

This script will check for Ollama, start it if needed, install Hermes Agent, and provide configuration guidance.

## Verification Checklist

- [ ] `ollama` command is available.
- [ ] Ollama service is running at `http://127.0.0.1:11434`.
- [ ] `hermes` command is available.
- [ ] `HERMES_BASE_URL` is set to `http://127.0.0.1:11434/v1`.
- [ ] At least one model (e.g., `hermes3`) is pulled via Ollama.
