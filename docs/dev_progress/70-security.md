# Security Best Practices

When running an autonomous agent like Hermes, security should be a top priority. This guide outlines how to protect your credentials and maintain a safe environment.

## 1. Protect Your API Tokens

Tokens for Telegram, Discord, Slack, and other platforms are sensitive. Anyone with access to these tokens can control your bot or access your data.

- **Never Commit Tokens**: Ensure your `config.yaml` and `.env` files are added to your `.gitignore`.
- **Use Environment Variables**: Instead of hardcoding tokens in `config.yaml`, use the `${VAR_NAME}` syntax and store the actual values in a `.env` file.
- **Rotate Tokens**: If you suspect a token has been compromised, revoke it immediately through the platform's developer portal and generate a new one.

## 2. Secure Your `.env` File

The `.env` file is a common target for attackers.

- **File Permissions**: On macOS/Linux/WSL, set strict permissions on your `.env` file:
    ```bash
    chmod 600 ~/.hermes/.env
    ```
    This ensures only your user can read or write to the file.
- **Avoid Global Environment Variables**: While setting `HERMES_MODEL` in your `~/.bashrc` is convenient, be careful with sensitive tokens. Keeping them in a local `.env` file is generally safer.

## 3. Local-First Privacy (Ollama)

By using Ollama, you are already significantly improving your privacy because your data does not leave your machine.

- **Firewall**: Ensure port 11434 (Ollama) is not exposed to the public internet unless you have explicitly configured authentication (Ollama does not provide built-in auth for the API).
- **Binding**: By default, Ollama on Windows/macOS binds to `127.0.0.1`. Only change this to `0.0.0.0` if necessary for WSL access, and ensure your local network is secure.

## 4. Minimize Privileges

- **Gateway Scopes**: When creating bots for Discord or Slack, only grant the minimum necessary permissions (e.g., `Send Messages`, `Read Messages`). Avoid giving them Administrative or "Manage Server" permissions.
- **Sandbox Tools**: If you are using Hermes' tool-calling capabilities (like code execution), be aware that the agent is running in your local shell environment. Use caution when allowing it to run arbitrary commands.

## 5. Logging and Data Privacy

Hermes Agent logs its interactions to help with debugging.

- **Sensitive Data in Logs**: Be aware that if you share your logs for troubleshooting, they may contain fragments of your conversations or private data.
- **Clean Logs**: Periodically clear your logs or use a script to anonymize sensitive information before sharing.

## 6. Update Regularly

Keep both Hermes Agent and Ollama up to date to benefit from the latest security patches and performance improvements.

```bash
# Update Hermes
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Update Ollama
# Check for updates in the Ollama menu bar app or download the latest version.
```
