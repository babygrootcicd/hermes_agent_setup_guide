#!/bin/bash

# Ollama model management utility
# Supports listing, pulling, updating, removing, and pruning local models.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

RECOMMENDED_MODELS=(
  "qwen32b-64k:latest"
  "qwen2.5-coder:32b"
)

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

show_help() {
  echo "Usage: $0 <command> [args]"
  echo ""
  echo "Commands:"
  echo "  list                      List installed models"
  echo "  pull [model]              Pull/update a model (prompt if missing)"
  echo "  recommended               Pull recommended agentic models"
  echo "  update                    Update all currently installed models"
  echo "  remove [model]            Remove a model (prompt if missing)"
  echo "  prune                     Interactively remove models"
  echo "  help                      Show this help message"
}

check_ollama() {
  if ! command -v ollama >/dev/null 2>&1; then
    fail "Ollama is not installed or not in PATH."
  fi
}

installed_models() {
  ollama list | awk 'NR>1 && NF>0 {print $1}'
}

list_models() {
  info "Installed Ollama models:"
  ollama list
}

pull_model() {
  local model_name="${1:-}"
  if [[ -z "${model_name}" ]]; then
    read -rp "Enter model name to pull: " model_name
  fi

  [[ -n "${model_name}" ]] || fail "No model name provided."

  if [[ "${model_name}" == "hermes3" ]]; then
    warn "'hermes3' is not recommended for agentic tool-calling workflows."
    warn "Consider: qwen32b-64k:latest or qwen2.5-coder:32b"
  fi

  info "Pulling model: ${model_name}"
  ollama pull "${model_name}"
  ok "Pulled ${model_name}"
}

pull_recommended_models() {
  info "Pulling recommended local models for Hermes Agent..."
  local model
  for model in "${RECOMMENDED_MODELS[@]}"; do
    info "Pulling ${model}"
    ollama pull "${model}"
  done
  ok "Recommended models pulled."
}

update_all_models() {
  local models
  models="$(installed_models)"

  if [[ -z "${models}" ]]; then
    warn "No installed models found to update."
    return 0
  fi

  info "Updating all installed models..."
  local model
  while IFS= read -r model; do
    [[ -n "${model}" ]] || continue
    info "Updating ${model}"
    ollama pull "${model}"
  done <<< "${models}"
  ok "All installed models updated."
}

remove_model() {
  local model_name="${1:-}"
  if [[ -z "${model_name}" ]]; then
    read -rp "Enter model name to remove: " model_name
  fi

  [[ -n "${model_name}" ]] || fail "No model name provided."
  warn "Removing model: ${model_name}"
  ollama rm "${model_name}"
  ok "Removed ${model_name}"
}

prune_models() {
  local models
  models="$(installed_models)"

  if [[ -z "${models}" ]]; then
    warn "No installed models found to prune."
    return 0
  fi

  info "Pruning models (interactive)..."
  local model choice
  while IFS= read -r model; do
    [[ -n "${model}" ]] || continue
    read -rp "Keep ${model}? [Y/n]: " choice
    case "${choice}" in
      n|N)
        warn "Removing ${model}"
        ollama rm "${model}"
        ;;
      *)
        ok "Keeping ${model}"
        ;;
    esac
  done <<< "${models}"
}

main() {
  local cmd="${1:-help}"

  case "${cmd}" in
    list)
      check_ollama
      list_models
      ;;
    pull)
      check_ollama
      pull_model "${2:-}"
      ;;
    recommended)
      check_ollama
      pull_recommended_models
      ;;
    update)
      check_ollama
      update_all_models
      ;;
    remove)
      check_ollama
      remove_model "${2:-}"
      ;;
    prune)
      check_ollama
      prune_models
      ;;
    help)
      show_help
      ;;
    *)
      fail "Unknown command: ${cmd}. Run '$0 help' for usage."
      ;;
  esac
}

main "$@"
