#!/usr/bin/env bash
# Creates qwen2.5-coder-fast:latest — a qwen2.5-coder:7b variant with num_ctx 65536.
# This satisfies Hermes Agent's 64k context minimum while keeping 7B inference speed.
#
# After running this script, update ~/.hermes/profiles/fast-local/config.yaml:
#   model.default: qwen2.5-coder-fast:latest
#
# Usage: ./scripts/macos/setup_fast_local_model.sh

set -euo pipefail

MODEL_NAME="qwen2.5-coder-fast:latest"
BASE_MODEL="qwen2.5-coder:7b"

echo "==> Checking Ollama is reachable..."
if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
  echo "ERROR: Ollama is not running. Start Ollama and retry."
  exit 1
fi

echo "==> Checking base model ${BASE_MODEL} is available..."
if ! ollama list 2>/dev/null | grep -q "qwen2.5-coder:7b"; then
  echo "==> Pulling ${BASE_MODEL}..."
  ollama pull "${BASE_MODEL}"
fi

echo "==> Creating ${MODEL_NAME} with num_ctx 65536..."
ollama create "${MODEL_NAME}" -f - << 'MODELFILE'
FROM qwen2.5-coder:7b
PARAMETER num_ctx 65536
MODELFILE

echo ""
echo "==> Done. ${MODEL_NAME} is ready."
echo ""
echo "To use it in the fast-local profile, update ~/.hermes/profiles/fast-local/config.yaml:"
echo "  model:"
echo "    default: qwen2.5-coder-fast:latest"
echo ""
echo "Then restart hermes chat."
