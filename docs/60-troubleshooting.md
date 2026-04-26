# Troubleshooting Guide

This guide covers common issues encountered while setting up or running Hermes Agent with Ollama.

## 1. Connection Refused (Ollama)

**Symptoms**: `Error: Connect ENETUNREACH` or `Connection refused`.

- **Cause**: Ollama is not running or is not listening on the expected port.
- **Fix**: 
    - Ensure Ollama is running (check system tray on Windows/macOS).
    - Try running `curl http://127.0.0.1:11434/api/tags` in your terminal.
    - If you are on **Windows/WSL**, ensure you have set `OLLAMA_HOST=0.0.0.0` in your Windows environment variables and restarted Ollama.

## 2. WSL Networking Issues

**Symptoms**: Hermes inside WSL cannot reach Ollama on Windows.

- **Cause**: WSL uses a virtual network, and `127.0.0.1` inside WSL refers to WSL itself, not the Windows host.
- **Fix**:
    - Use the host IP address in `HERMES_BASE_URL`. Find it by running `cat /etc/resolv.conf` inside WSL.
    - Ensure Windows Firewall allows inbound connections on port 11434.
    - Set `OLLAMA_HOST=0.0.0.0` on Windows.

## 3. Model Not Found

**Symptoms**: `Error: model "hermes3" not found`.

- **Cause**: The model has not been pulled yet.
- **Fix**:
    - Run `ollama pull hermes3`.
    - Check the list of available models with `ollama list`.
    - Ensure the model name in your config matches exactly what is shown in `ollama list`.

## 4. Performance is Very Slow

**Symptoms**: Agent takes a long time to respond; high CPU usage.

- **Cause**: The model is too large for your VRAM and is being offloaded to system RAM (CPU).
- **Fix**:
    - Try a smaller model (e.g., use an 8B model instead of a 70B model).
    - If using a laptop, ensure it is plugged into power.
    - Check VRAM usage with `nvidia-smi` (on Windows/Linux with NVIDIA GPUs).

## 5. "hermes" Command Not Found

**Symptoms**: `-bash: hermes: command not found`.

- **Cause**: The Hermes binary directory is not in your shell's PATH.
- **Fix**:
    - Add `export PATH="$HOME/.hermes/bin:$PATH"` to your `.bashrc` or `.zshrc`.
    - Run `source ~/.bashrc` or `source ~/.zshrc`.

## 6. Playwright / Browser Tool Errors

**Symptoms**: Errors related to "missing dependencies" when using web browsing tools.

- **Cause**: Hermes uses Playwright for web tools, which requires specific system libraries.
- **Fix**:
    - Run the Playwright install command (usually handled by Hermes, but might need manual intervention in some environments):
    ```bash
    npx playwright install --with-deps
    ```

## 7. Log File Analysis

If you are still stuck, check the logs:
- **Hermes Logs**: Usually found in `~/.hermes/logs/` or printed to stdout if `DEBUG=true`.
- **Ollama Logs**: 
    - **macOS**: `tail -f ~/Library/Logs/Ollama/app.log`
    - **Windows**: Right-click the Ollama icon in the system tray and select "View Logs".
