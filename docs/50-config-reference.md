# Configuration Reference

Hermes Agent uses two main files for configuration: `config.yaml` and `.env`. These files are typically located in the `~/.hermes/` directory.

---

## 1. `config.yaml`

The `config.yaml` file defines the structural configuration of your agent, including providers, gateways, and storage.

### Example Structure
```yaml
# General Settings
agent:
  name: "MyHermesAgent"
  description: "A local assistant powered by Ollama"

# LLM Provider Settings (Ollama)
provider:
  type: "ollama"
  baseUrl: "http://127.0.0.1:11434/v1"
  model: "hermes3"

# Gateway Settings
gateways:
  telegram:
    enabled: true
    token: "${TELEGRAM_BOT_TOKEN}"
  discord:
    enabled: false
    token: "${DISCORD_BOT_TOKEN}"

# Storage Settings
storage:
  type: "local"
  path: "./data"
```

### Key Sections
- **`agent`**: Basic identification for your agent.
- **`provider`**: Configuration for the LLM backend.
  - `type`: Set to `ollama` for local models.
  - `baseUrl`: The API endpoint (e.g., `http://127.0.0.1:11434/v1`).
  - `model`: The model name you pulled via Ollama (e.g., `hermes3`).
- **`gateways`**: Configuration for external platforms. You can use `${VAR_NAME}` syntax to reference environment variables from `.env`.
- **`storage`**: Where Hermes saves its memory and state.

---

## 2. `.env`

The `.env` file is used to store sensitive information like API tokens and secrets, as well as environment-specific overrides.

### Example Content
```env
# Gateway Tokens
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrSTUvwxYZ
DISCORD_BOT_TOKEN=your_discord_bot_token_here
SLACK_BOT_TOKEN=your_slack_bot_token_here

# Ollama Overrides
HERMES_BASE_URL=http://127.0.0.1:11434/v1
HERMES_MODEL=hermes3

# System Settings
DEBUG=true
LOG_LEVEL=info
```

### Variable Precedence
Hermes Agent typically follows this precedence order (highest to lowest):
1.  Command-line arguments (e.g., `--model`).
2.  Environment variables (e.g., `HERMES_MODEL`).
3.  Values in `config.yaml`.
4.  Default values.

---

## 3. Recommended Locations

- **macOS/Linux**: `~/.hermes/config.yaml` and `~/.hermes/.env`
- **Windows (WSL)**: `~/.hermes/config.yaml` and `~/.hermes/.env` inside your WSL distribution.

---

## 4. Best Practices

1.  **Never Commit Secrets**: Do not commit your `.env` or `config.yaml` files (if they contain tokens) to public repositories. Use `.gitignore` to protect them.
2.  **Use Environment Variables**: Prefer using `${VARIABLE}` syntax in `config.yaml` and defining the actual values in `.env`.
3.  **Validate Config**: After making changes, run `hermes chat --version` or a similar command to ensure the agent still starts correctly.
