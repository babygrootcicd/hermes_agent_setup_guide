# Configuration Examples

This directory contains templates and examples to help you configure your Hermes Agent environment.

## Files

- `config/config.yaml.template`: A base configuration file for Hermes. Copy this to `~/.hermes/config.yaml` and modify as needed.
- `config/.env.template`: A template for environment variables (API keys, base URLs). Copy this to `~/.hermes/.env`.

## Setup
1.  Create the directory: `mkdir -p ~/.hermes`
2.  Copy templates:
    ```bash
    cp config.yaml.template ~/.hermes/config.yaml
    cp .env.template ~/.hermes/.env
    ```
3.  Edit the files with your specific settings (e.g., custom Ollama endpoints or Gateway tokens).
