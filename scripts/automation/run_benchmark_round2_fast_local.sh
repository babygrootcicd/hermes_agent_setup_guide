#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH_ROOT="$ROOT_DIR/docs/enhancements/benchmarks"
TS="$(date +%Y%m%d_%H%M%S)"
RUN_TAG="${TS}_round2_fast_local"
OUT_DIR="$BENCH_ROOT/$RUN_TAG"
PROFILE="fast-local"
FAST_MODEL="qwen2.5-coder:7b"
BASELINE_MODEL="qwen32b-64k:latest"
OLLAMA_URL="http://127.0.0.1:11434"
OLLAMA_V1_URL="$OLLAMA_URL/v1"

mkdir -p "$OUT_DIR"

run_log() {
  local file="$1"
  shift
  {
    "$@"
  } >"$OUT_DIR/$file" 2>&1
}

run_timed_shell() {
  local file="$1"
  local title="$2"
  local cmd="$3"
  {
    echo "== $title =="
    /usr/bin/time -p bash -lc "$cmd"
  } >"$OUT_DIR/$file" 2>&1
}

extract_real() {
  local file="$1"
  awk '/^real /{print $2; exit}' "$OUT_DIR/$file"
}

{
  echo "timestamp=$RUN_TAG"
  echo "cwd=$ROOT_DIR"
  echo "date=$(date -Iseconds)"
  echo "profile=$PROFILE"
  echo "fast_model=$FAST_MODEL"
  echo "baseline_model=$BASELINE_MODEL"
} >"$OUT_DIR/00_meta.log"

run_log "01_hermes_version.log" bash -lc 'echo "== hermes --version =="; hermes --version'
run_log "02_ollama_version.log" bash -lc 'echo "== ollama version =="; ollama --version'
run_log "03_verify.log" bash -lc "echo '== verify.sh =='; cd '$ROOT_DIR' && ./scripts/common/verify.sh" || true
run_timed_shell "04_ollama_tags.log" "ollama tags check" "curl -fsS $OLLAMA_URL/api/tags"

run_log "05_profile_apply.log" bash -lc "
set -e
echo '== fast-local profile apply =='
if hermes profile show $PROFILE >/dev/null 2>&1; then
  echo 'profile exists: $PROFILE'
else
  hermes profile create $PROFILE --clone
  echo 'profile created: $PROFILE'
fi
hermes --profile $PROFILE config set model.provider custom
hermes --profile $PROFILE config set model.default $FAST_MODEL
hermes --profile $PROFILE config set model.base_url $OLLAMA_V1_URL
hermes --profile $PROFILE config set model.api_key no-key-required
hermes --profile $PROFILE config set model.context_length 16384
hermes --profile $PROFILE config set agent.max_turns 12
hermes --profile $PROFILE config set display.personality technical
echo 'profile config path:'
hermes --profile $PROFILE config path
echo 'profile config snapshot:'
hermes --profile $PROFILE config show
"

run_timed_shell \
  "06_chat_fast_terminal_skills.log" \
  "fast-local chat: terminal,skills max-turns=1" \
  "printf '/quit\n' | hermes --profile $PROFILE chat --toolsets terminal,skills --max-turns 1"

run_timed_shell \
  "07_chat_fast_web_terminal_skills.log" \
  "fast-local chat: web,terminal,skills max-turns=1" \
  "printf '/quit\n' | hermes --profile $PROFILE chat --toolsets web,terminal,skills --max-turns 1"

run_timed_shell \
  "08_chat_baseline_terminal_skills.log" \
  "baseline compare chat: qwen32b-64k terminal,skills max-turns=1" \
  "printf '/quit\n' | hermes chat --model $BASELINE_MODEL --toolsets terminal,skills --max-turns 1"

run_log "09_process_snapshot.log" bash -lc 'echo "== process snapshot =="; ps aux | rg "hermes|ollama"' || true

FAST_TERM_REAL="$(extract_real 06_chat_fast_terminal_skills.log)"
FAST_WEB_REAL="$(extract_real 07_chat_fast_web_terminal_skills.log)"
BASE_TERM_REAL="$(extract_real 08_chat_baseline_terminal_skills.log)"

{
  echo "== quick summary =="
  for f in 00_meta.log 01_hermes_version.log 02_ollama_version.log 03_verify.log 04_ollama_tags.log 05_profile_apply.log 06_chat_fast_terminal_skills.log 07_chat_fast_web_terminal_skills.log 08_chat_baseline_terminal_skills.log 09_process_snapshot.log; do
    echo "--- $f ---"
    tail -n 25 "$OUT_DIR/$f"
    echo
  done
} >"$OUT_DIR/99_summary.log"

{
  echo "# Round 2 Benchmark Report (fast-local)"
  echo
  echo "- Timestamp: $(date -Iseconds)"
  echo "- Folder: \`docs/enhancements/benchmarks/$RUN_TAG\`"
  echo "- Profile: \`$PROFILE\`"
  echo "- Fast model: \`$FAST_MODEL\`"
  echo "- Baseline compare model: \`$BASELINE_MODEL\`"
  echo
  echo "## Measured Results"
  echo
  echo "- \`fast-local terminal,skills\`: \`real ${FAST_TERM_REAL:-n/a}s\`"
  echo "- \`fast-local web,terminal,skills\`: \`real ${FAST_WEB_REAL:-n/a}s\`"
  echo "- \`baseline qwen32b terminal,skills\`: \`real ${BASE_TERM_REAL:-n/a}s\`"
  echo
  echo "## Artifacts"
  echo
  echo "- \`00_meta.log\`"
  echo "- \`01_hermes_version.log\`"
  echo "- \`02_ollama_version.log\`"
  echo "- \`03_verify.log\`"
  echo "- \`04_ollama_tags.log\`"
  echo "- \`05_profile_apply.log\`"
  echo "- \`06_chat_fast_terminal_skills.log\`"
  echo "- \`07_chat_fast_web_terminal_skills.log\`"
  echo "- \`08_chat_baseline_terminal_skills.log\`"
  echo "- \`09_process_snapshot.log\`"
  echo "- \`99_summary.log\`"
} >"$OUT_DIR/ROUND2.md"

echo "Round 2 benchmark completed: $OUT_DIR"
