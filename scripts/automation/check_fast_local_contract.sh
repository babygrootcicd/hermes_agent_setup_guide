#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTOMATION_DIR="$ROOT_DIR/scripts/automation"

PREFERRED_MODEL="qwen2.5-coder:7b"
ALLOWED_VARIANT_MODEL="qwen2.5-coder-fast:latest"
REQUIRED_CONTEXT_LENGTH="65536"
CANONICAL_TOOLSETS="terminal,skills"
LEGACY_BENCHMARK_SCRIPT="run_benchmark_round2_fast_local.sh"
ROUND4_MATRIX_FILE="$AUTOMATION_DIR/round4_matrix.csv"

VIOLATION_COUNT=0

error() {
  printf 'ERROR: %s\n' "$1" >&2
  VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
}

require_file() {
  local rel_path="$1"
  if [[ ! -f "$ROOT_DIR/$rel_path" ]]; then
    error "Missing required file: $rel_path"
  fi
}

check_contains() {
  local rel_path="$1"
  local regex="$2"
  local fix_hint="$3"
  if [[ ! -f "$ROOT_DIR/$rel_path" ]]; then
    return
  fi
  if ! grep -Eq "$regex" "$ROOT_DIR/$rel_path"; then
    error "$rel_path is missing expected contract content. Fix: $fix_hint"
  fi
}

check_required_sources() {
  local files=(
    "README.md"
    "installation_start_guide.md"
    "docs/enhancements/round3_speed_fix_plan.md"
  )

  local rel
  for rel in "${files[@]}"; do
    require_file "$rel"
  done
}

check_docs_contract_baseline() {
  check_contains \
    "README.md" \
    "qwen2\\.5-coder:7b" \
    "document fast-local default as qwen2.5-coder:7b."

  check_contains \
    "README.md" \
    "terminal,skills" \
    "keep canonical fast-local toolset examples on terminal,skills."

  check_contains \
    "installation_start_guide.md" \
    "qwen2\\.5-coder:7b" \
    "document fast-local default as qwen2.5-coder:7b."

  check_contains \
    "installation_start_guide.md" \
    "65536" \
    "document fast-local context expectation as 65536."

  check_contains \
    "docs/enhancements/round3_speed_fix_plan.md" \
    "context_length:[[:space:]]*65536" \
    "keep fast-local context_length at 65536 in the speed-fix plan."

  check_contains \
    "docs/enhancements/round3_speed_fix_plan.md" \
    "qwen2\\.5-coder-fast:latest" \
    "retain allowed fast-local variant qwen2.5-coder-fast:latest."
}

check_fast_model_assignment() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"
  local line_no line_text model

  while IFS=: read -r line_no line_text; do
    model="$(printf '%s\n' "$line_text" | sed -E 's/.*FAST_MODEL="([^"]+)".*/\1/')"
    if [[ "$model" != "$PREFERRED_MODEL" && "$model" != "$ALLOWED_VARIANT_MODEL" ]]; then
      error "$rel:$line_no sets FAST_MODEL=$model. Use $PREFERRED_MODEL or $ALLOWED_VARIANT_MODEL."
    fi
  done < <(grep -nE 'FAST_MODEL="[^"]+"' "$file" || true)
}

check_context_length_assignment() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"
  local line_no line_text value

  while IFS=: read -r line_no line_text; do
    value="$(printf '%s\n' "$line_text" | awk '{print $NF}')"
    if [[ "$value" != "$REQUIRED_CONTEXT_LENGTH" ]]; then
      error "$rel:$line_no sets model.context_length=$value. Fast-local contract requires $REQUIRED_CONTEXT_LENGTH. Update to $REQUIRED_CONTEXT_LENGTH."
    fi
  done < <(grep -nE 'config set model\.context_length[[:space:]]+[0-9]+' "$file" || true)
}

check_quit_only_benchmarks() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"
  local line_no line_text

  while IFS=: read -r line_no line_text; do
    error "$rel:$line_no uses startup-only '/quit' timing. Replace with a real prompt and wait for assistant output before collecting latency metrics."
  done < <(grep -nF "printf '/quit\\n'" "$file" || true)
}

check_benchmark_toolsets() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"
  local line_no line_text toolsets

  while IFS=: read -r line_no line_text; do
    if printf '%s\n' "$line_text" | grep -Eq '\$[{]?(toolsets|TOOLSETS)[}]?'; then
      continue
    fi
    toolsets="$(printf '%s\n' "$line_text" | awk '{for (i = 1; i <= NF; i++) if ($i == "--toolsets") {print $(i+1); exit}}')"
    if [[ -n "$toolsets" && "$toolsets" != "$CANONICAL_TOOLSETS" ]]; then
      error "$rel:$line_no uses --toolsets $toolsets. Canonical fast-local benchmark toolset is $CANONICAL_TOOLSETS. Keep non-canonical toolsets in separate reports."
    fi
  done < <(grep -n -- '--toolsets' "$file" || true)
}

check_fast_local_model_override() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"
  local line_no line_text

  while IFS=: read -r line_no line_text; do
    error "$rel:$line_no mixes --profile and --model in one command. Fast-local benchmark rows must resolve model via profile only."
  done < <(grep -nE -- '--profile[[:space:]]+[^ ]+.*--model|--model.*--profile[[:space:]]+[^ ]+' "$file" || true)
}

check_update_models_alignment() {
  local file="$AUTOMATION_DIR/update_models.sh"
  if [[ ! -f "$file" ]]; then
    return
  fi

  if ! grep -Eq "qwen2\\.5-coder:7b|qwen2\\.5-coder-fast:latest" "$file"; then
    error "scripts/automation/update_models.sh does not list a fast-local model in RECOMMENDED_MODELS. Add $PREFERRED_MODEL or $ALLOWED_VARIANT_MODEL."
  fi
}

check_round4_matrix_contract() {
  local file="$ROUND4_MATRIX_FILE"
  local line_no=0
  local config_id enabled profile model context_length toolsets max_turns runs prompt note

  if [[ ! -f "$file" ]]; then
    error "Missing required file: scripts/automation/round4_matrix.csv"
    return
  fi

  while IFS=',' read -r config_id enabled profile model context_length toolsets max_turns runs prompt note; do
    line_no=$((line_no + 1))
    if [[ "$line_no" -eq 1 ]]; then
      continue
    fi

    config_id="$(printf '%s' "$config_id" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    enabled="$(printf '%s' "$enabled" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    toolsets="$(printf '%s' "$toolsets" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

    [[ -n "$config_id" ]] || continue
    [[ "$enabled" == "1" ]] || continue

    if [[ "$toolsets" != "terminal+skills" ]]; then
      error "scripts/automation/round4_matrix.csv:$line_no config '$config_id' uses toolsets '$toolsets'. Expected terminal+skills."
    fi
  done <"$file"
}

check_automation_contract() {
  if [[ ! -d "$AUTOMATION_DIR" ]]; then
    error "Missing required directory: scripts/automation"
    return
  fi

  local found_any=0
  local file base

  while IFS= read -r file; do
    found_any=1
    base="$(basename "$file")"
    if [[ "$base" == "check_fast_local_contract.sh" ]]; then
      continue
    fi
    if [[ "$base" == "$LEGACY_BENCHMARK_SCRIPT" ]]; then
      continue
    fi

    check_fast_model_assignment "$file"
    check_context_length_assignment "$file"
    check_quit_only_benchmarks "$file"

    if [[ "$base" == run_benchmark_* ]]; then
      check_benchmark_toolsets "$file"
      check_fast_local_model_override "$file"
    fi
  done < <(find "$AUTOMATION_DIR" -maxdepth 1 -type f -name '*.sh' | sort)

  if [[ "$found_any" -eq 0 ]]; then
    error "No automation scripts found in scripts/automation/*.sh."
  fi

  check_update_models_alignment
  check_round4_matrix_contract
}

main() {
  check_required_sources
  check_docs_contract_baseline
  check_automation_contract

  if [[ "$VIOLATION_COUNT" -gt 0 ]]; then
    printf 'fast-local contract check failed: %s violation(s).\n' "$VIOLATION_COUNT" >&2
    exit 1
  fi

  printf 'fast-local contract check passed.\n'
}

main "$@"
