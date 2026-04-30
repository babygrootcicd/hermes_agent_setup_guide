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

**Symptoms**: Agent takes a long time to respond (for example 3+ minute first reply), even when startup succeeds.

- **Likely causes**:
    - Model/runtime mismatch for current hardware (large model CPU-offload, memory pressure).
    - High first-turn context footprint (large initial prompt payload before useful work).
    - Config drift across profile/model/context/toolsets between runs.
    - Benchmark method measured startup/quit path instead of real interaction latency.
- **Fix checklist**:
    1. Confirm active profile and fast-local config values:
       ```bash
       cat ~/.hermes/active_profile
       grep -E "default|context_length" ~/.hermes/profiles/fast-local/config.yaml
       ```
    2. Ensure fast-local model/context match current expected values (for example `qwen2.5-coder:7b` or `qwen2.5-coder-fast:latest`, with `context_length: 65536` in Hermes profile config).
    3. Keep toolsets fixed while testing (`terminal,skills` first), and warm up Ollama before test runs.
    4. During the first slow reply, note the context meter in the session output; unusually high initial footprint can dominate first-token latency.
    5. Measure real interaction latency (not startup-only timing) with:
       ```bash
       ./scripts/automation/run_benchmark_round4_response_latency.sh
       ```
    6. Apply benchmark quality gates before claiming improvements:
       - Exclude runs with profile/config errors, model-load failures, or missing assistant output.
       - Require `t_prompt_ready`, `t_first_token`, and `t_completion_done` for every summarized run.

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

## 7. Context Window Below Minimum (Model Initialization Fails)

**Symptoms**: `Failed to initialize agent: Model qwen32b-64k:latest has a context window of 16,384 tokens, which is below the minimum 64,000 required by Hermes Agent.`

- **Cause**: Passing `--model <name>` on the command line triggers a fresh context window query from Ollama's API. Ollama may return the model's native architecture context length (e.g. 16,384 or 32,768) rather than the `num_ctx` you configured, bypassing the `model.context_length` override in `config.yaml`.
- **Fix**:
    1. If `qwen32b-64k:latest` is already your default model in `~/.hermes/config.yaml`, drop the `--model` flag entirely:
       ```bash
       hermes chat --toolsets terminal,skills --max-turns 1
       ```
    2. If you need to set it as the default, run `hermes model` and select `qwen32b-64k:latest`. Then use the command above.
    3. Verify the context_length override is set in `~/.hermes/config.yaml`:
       ```yaml
       model:
         default: qwen32b-64k:latest
         context_length: 65536
       ```
    4. If the issue persists, check `~/.hermes/context_length_cache.yaml`. If the entry for `qwen32b-64k:latest` is missing or wrong, delete the file and restart Hermes so it re-queries Ollama.

## 8. Log File Analysis

If you are still stuck, check the logs:
- **Hermes Logs**: Usually found in `~/.hermes/logs/` or printed to stdout if `DEBUG=true`.
- **Ollama Logs**: 
    - **macOS**: `tail -f ~/Library/Logs/Ollama/app.log`
    - **Windows**: Right-click the Ollama icon in the system tray and select "View Logs".

## 9. Benchmark Looks Fast, But Chat Still Feels Slow

**Symptoms**: Benchmark reports single-digit seconds, but real chat still has long delays.

- **Cause**: Startup-only measurements (for example sending `/quit` immediately) do not measure model response latency.
- **Fix**:
    - Do not use startup/quit timing as evidence that response latency is fixed.
    - Use `./scripts/automation/run_benchmark_round4_response_latency.sh` so each run includes a real prompt and assistant response.
    - Compare runs only when profile/model/context/toolsets are consistent (avoid config drift).
