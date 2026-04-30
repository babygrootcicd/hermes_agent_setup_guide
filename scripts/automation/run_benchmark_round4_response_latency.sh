#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MATRIX_FILE="${1:-$SCRIPT_DIR/round4_matrix.csv}"
BENCH_ROOT="$ROOT_DIR/docs/enhancements/benchmarks"
TS="$(date +%Y%m%d_%H%M%S)"
RUN_TAG="${TS}_round4_response_latency"
OUT_DIR="$BENCH_ROOT/$RUN_TAG"
RUNS_DIR="$OUT_DIR/runs"
CONFIGS_DIR="$OUT_DIR/configs"
METRICS_CSV="$OUT_DIR/10_metrics.csv"
INVALID_CSV="$OUT_DIR/11_invalid_runs.csv"
ROUND4_MD="$OUT_DIR/ROUND4.md"
SUMMARY_LOG="$OUT_DIR/99_summary.log"
OLLAMA_URL="http://127.0.0.1:11434"
OLLAMA_V1_URL="$OLLAMA_URL/v1"

mkdir -p "$OUT_DIR" "$RUNS_DIR" "$CONFIGS_DIR"

if [ ! -f "$MATRIX_FILE" ]; then
  echo "matrix file not found: $MATRIX_FILE" >&2
  exit 1
fi

clean_csv_field() {
  printf '%s' "$1" | tr '\n' ' ' | sed 's/,/;/g; s/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

elapsed_from_line() {
  printf '%s\n' "$1" | sed -n 's/^\[t+\([0-9][0-9]*\)s\].*/\1/p'
}

extract_first_elapsed_match() {
  local file="$1"
  local regex="$2"
  local line
  line="$(grep -E -m1 "$regex" "$file" || true)"
  if [ -z "$line" ]; then
    return 1
  fi
  elapsed_from_line "$line"
}

extract_first_output_elapsed() {
  local file="$1"
  local line
  line="$(grep -m1 -E '^\[t\+[0-9][0-9]*s\] .+' "$file" || true)"
  if [ -z "$line" ]; then
    return 1
  fi
  elapsed_from_line "$line"
}

extract_first_token_elapsed() {
  local file="$1"
  local assistant_line
  local sec

  assistant_line="$(extract_first_assistant_line "$file" || true)"
  if [ -z "$assistant_line" ]; then
    return 1
  fi

  sec="$(elapsed_from_line "$assistant_line")"
  if [ -z "$sec" ]; then
    return 1
  fi

  printf '%s\n' "$sec"
}

extract_first_assistant_line() {
  local file="$1"
  local seen_init=0
  local seen_init_error=0
  local line payload

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *"Initializing agent"*)
        seen_init=1
        continue
        ;;
    esac

    if [ "$seen_init" -eq 0 ]; then
      continue
    fi

    payload="${line#*] }"
    if [ -z "${payload// }" ]; then
      continue
    fi

    case "$payload" in
      "Failed to initialize agent:"*|*"Operation not permitted"*|*"No such file or directory"*)
        seen_init_error=1
        continue
        ;;
    esac

    if [ "$seen_init_error" -eq 1 ]; then
      continue
    fi

    case "$payload" in
      "Initializing agent"*|"Query:"*|"Welcome to Hermes Agent"*|"Goodbye!"*|"Session:"*|"Profile:"*)
        continue
        ;;
    esac

    if ! printf '%s\n' "$payload" | grep -Eq '[A-Za-z0-9]'; then
      continue
    fi

    printf '%s\n' "$line"
    return 0
  done <"$file"

  return 1
}

contains_profile_or_config_error() {
  local file="$1"
  grep -Eqi 'PermissionError|Traceback|Failed to initialize agent|Operation not permitted|No such file or directory|profile[[:space:]].*not found|config[[:space:]].*failed|Error:' "$file"
}

capture_chat_with_timestamps() {
  local profile="$1"
  local model="$2"
  local toolsets="$3"
  local max_turns="$4"
  local prompt="$5"
  local run_log="$6"
  local time_log="$7"

  local start_epoch
  local chat_rc

  start_epoch="$(date +%s)"

  set +e
  /usr/bin/time -p -o "$time_log" \
    hermes --profile "$profile" chat --toolsets "$toolsets" --max-turns "$max_turns" --query "$prompt" 2>&1 \
    | while IFS= read -r line || [ -n "$line" ]; do
        printf '[t+%06ds] %s\n' "$(( $(date +%s) - start_epoch ))" "$line"
      done >"$run_log"
  chat_rc="${PIPESTATUS[0]}"
  set -e

  printf '%s\n' "$chat_rc"
}

apply_profile_config() {
  local profile="$1"
  local model="$2"
  local context_length="$3"
  local apply_log="$4"

  local rc=0
  {
    echo "== profile apply $(date -Iseconds) =="
    echo "profile=$profile"
    echo "model=$model"
    echo "context_length=$context_length"

    if hermes profile show "$profile" >/dev/null 2>&1; then
      echo "profile exists: $profile"
    else
      hermes profile create "$profile" --clone
      echo "profile created: $profile"
    fi

    hermes --profile "$profile" config set model.provider custom
    hermes --profile "$profile" config set model.default "$model"
    hermes --profile "$profile" config set model.base_url "$OLLAMA_V1_URL"
    hermes --profile "$profile" config set model.api_key no-key-required
    hermes --profile "$profile" config set model.context_length "$context_length"
    hermes --profile "$profile" config set agent.max_turns 12
    hermes --profile "$profile" config set display.personality technical

    echo "profile config path:"
    hermes --profile "$profile" config path

    echo "profile config snapshot:"
    hermes --profile "$profile" config show
  } >"$apply_log" 2>&1 || rc=$?

  return "$rc"
}

{
  echo "timestamp=$RUN_TAG"
  echo "date=$(date -Iseconds)"
  echo "root_dir=$ROOT_DIR"
  echo "matrix_file=$MATRIX_FILE"
  echo "ollama_url=$OLLAMA_URL"
  echo "metric_prompt_ready=approx_seconds_to_query_or_first_output"
  echo "metric_first_token=approx_seconds_to_first_assistant_output_after_init"
  echo "metric_completion_done=process_elapsed_real_seconds_from_usr_bin_time"
} >"$OUT_DIR/00_meta.log"

{
  echo "== hermes --version =="
  hermes --version
} >"$OUT_DIR/01_hermes_version.log" 2>&1 || true

{
  echo "== ollama preflight =="
  if command -v ollama >/dev/null 2>&1; then
    ollama --version
  else
    echo "ollama command not found"
  fi
} >"$OUT_DIR/02_ollama_preflight.log" 2>&1 || true

cp "$MATRIX_FILE" "$OUT_DIR/03_round4_matrix_snapshot.csv"

cat >"$METRICS_CSV" <<'CSV'
config_id,run_id,status,invalid_reason,profile,model,context_length,toolsets,max_turns,prompt_ready_s_approx,first_token_s_approx,completion_done_s,assistant_chars,metric_prompt_ready_label,metric_first_token_label,metric_completion_done_label,chat_exit_code,run_log
CSV

cat >"$INVALID_CSV" <<'CSV'
config_id,run_id,reason,detail,run_log
CSV

line_no=0
while IFS=',' read -r config_id enabled profile model context_length toolsets_raw max_turns runs prompt note; do
  line_no=$((line_no + 1))

  if [ "$line_no" -eq 1 ]; then
    continue
  fi

  if [ -z "${config_id// }" ]; then
    continue
  fi

  config_id="$(trim "$config_id")"
  enabled="$(trim "$enabled")"
  profile="$(trim "$profile")"
  model="$(trim "$model")"
  context_length="$(trim "$context_length")"
  toolsets_raw="$(trim "$toolsets_raw")"
  max_turns="$(trim "$max_turns")"
  runs="$(trim "$runs")"
  prompt="$(trim "$prompt")"
  note="$(trim "$note")"

  if [ "${config_id#\#}" != "$config_id" ]; then
    continue
  fi

  if [ "$enabled" != "1" ]; then
    continue
  fi

  if [ -z "$runs" ] || ! printf '%s\n' "$runs" | grep -Eq '^[0-9][0-9]*$'; then
    runs=1
  fi

  if [ -z "$max_turns" ] || ! printf '%s\n' "$max_turns" | grep -Eq '^[0-9][0-9]*$'; then
    max_turns=1
  fi

  toolsets="${toolsets_raw//+/,}"

  apply_log="$CONFIGS_DIR/${config_id}_profile_apply.log"
  profile_ok=1
  if ! apply_profile_config "$profile" "$model" "$context_length" "$apply_log"; then
    profile_ok=0
  fi
  if contains_profile_or_config_error "$apply_log"; then
    profile_ok=0
  fi

  run_index=1
  while [ "$run_index" -le "$runs" ]; do
    run_id="${config_id}_run$(printf '%02d' "$run_index")"
    run_log="$RUNS_DIR/${run_id}.chat.log"
    time_log="$RUNS_DIR/${run_id}.time.log"

    status="valid"
    invalid_reason=""
    prompt_ready=""
    first_token=""
    completion_done=""
    assistant_chars=0
    chat_exit_code=""
    assistant_line=""
    assistant_payload=""

    if [ "$profile_ok" -ne 1 ]; then
      status="invalid"
      invalid_reason="profile_config_error"
      printf '[t+000000s] skipped due to profile/config error\n' >"$run_log"
      printf 'real 0.00\nuser 0.00\nsys 0.00\n' >"$time_log"
    else
      chat_exit_code="$(capture_chat_with_timestamps "$profile" "$model" "$toolsets" "$max_turns" "$prompt" "$run_log" "$time_log")"

      if [ -z "$chat_exit_code" ] || [ "$chat_exit_code" != "0" ]; then
        status="invalid"
        invalid_reason="chat_exit_nonzero_${chat_exit_code:-unknown}"
      fi

      if contains_profile_or_config_error "$run_log"; then
        status="invalid"
        invalid_reason="profile_or_runtime_error"
      fi

      prompt_ready="$(extract_first_elapsed_match "$run_log" '\\] Query:' || true)"
      if [ -z "$prompt_ready" ]; then
        prompt_ready="$(extract_first_elapsed_match "$run_log" 'Initializing agent' || true)"
      fi
      if [ -z "$prompt_ready" ]; then
        prompt_ready="$(extract_first_output_elapsed "$run_log" || true)"
      fi

      assistant_line="$(extract_first_assistant_line "$run_log" || true)"
      if [ -n "$assistant_line" ]; then
        first_token="$(elapsed_from_line "$assistant_line")"
      fi

      if [ -z "$first_token" ]; then
        status="invalid"
        if [ -z "$invalid_reason" ]; then
          invalid_reason="no_assistant_output"
        else
          invalid_reason="${invalid_reason}+no_assistant_output"
        fi
      else
        assistant_payload="${assistant_line#*] }"
        assistant_chars="${#assistant_payload}"
      fi

      completion_done="$(awk '/^real /{print $2; exit}' "$time_log")"
    fi

    if [ -z "$prompt_ready" ]; then
      prompt_ready="n/a"
    fi

    if [ -z "$first_token" ]; then
      first_token="n/a"
    fi

    if [ -z "$completion_done" ]; then
      completion_done="n/a"
    fi

    if [ -z "$chat_exit_code" ]; then
      chat_exit_code="n/a"
    fi

    echo "${config_id},${run_id},${status},$(clean_csv_field "$invalid_reason"),${profile},${model},${context_length},${toolsets},${max_turns},${prompt_ready},${first_token},${completion_done},${assistant_chars},approx_query_or_first_output_seconds,approx_first_assistant_output_seconds,usr_bin_time_real_seconds,${chat_exit_code},${run_log}" >>"$METRICS_CSV"

    if [ "$status" != "valid" ]; then
      echo "${config_id},${run_id},$(clean_csv_field "$invalid_reason"),$(clean_csv_field "$note"),${run_log}" >>"$INVALID_CSV"
    fi

    run_index=$((run_index + 1))
  done
done <"$MATRIX_FILE"

awk -F',' '
  NR==1 {next}
  {
    cfg=$1
    total[cfg]++
    if ($3=="valid") {
      valid[cfg]++
      if ($10 != "n/a") {
        pr_sum[cfg]+=$10
        pr_n[cfg]++
      }
      if ($11 != "n/a") {
        ft_sum[cfg]+=$11
        ft_n[cfg]++
      }
      if ($12 != "n/a") {
        cd_sum[cfg]+=$12
        cd_n[cfg]++
      }
    } else {
      invalid[cfg]++
    }
    total_all++
    if ($3=="valid") valid_all++
    if ($3!="valid") invalid_all++
  }
  END {
    printf("TOTAL_RUNS=%d\n", total_all)
    printf("VALID_RUNS=%d\n", valid_all)
    printf("INVALID_RUNS=%d\n", invalid_all)
    for (cfg in total) {
      pr=(pr_n[cfg]>0 ? pr_sum[cfg]/pr_n[cfg] : -1)
      ft=(ft_n[cfg]>0 ? ft_sum[cfg]/ft_n[cfg] : -1)
      cd=(cd_n[cfg]>0 ? cd_sum[cfg]/cd_n[cfg] : -1)
      printf("CFG,%s,%d,%d,%d,", cfg, total[cfg], (valid[cfg]+0), (invalid[cfg]+0))
      if (pr>=0) printf("%.2f,", pr); else printf("n/a,")
      if (ft>=0) printf("%.2f,", ft); else printf("n/a,")
      if (cd>=0) printf("%.2f\n", cd); else printf("n/a\n")
    }
  }
' "$METRICS_CSV" >"$OUT_DIR/20_aggregates.txt"

{
  echo "# Round 4 Response Latency Benchmark"
  echo
  echo "- Timestamp: $(date -Iseconds)"
  echo "- Run tag: $RUN_TAG"
  echo "- Output folder: docs/enhancements/benchmarks/$RUN_TAG"
  echo "- Matrix source: $MATRIX_FILE"
  echo
  total_runs="$(awk -F= '/^TOTAL_RUNS=/{print $2}' "$OUT_DIR/20_aggregates.txt")"
  valid_runs="$(awk -F= '/^VALID_RUNS=/{print $2}' "$OUT_DIR/20_aggregates.txt")"
  invalid_runs="$(awk -F= '/^INVALID_RUNS=/{print $2}' "$OUT_DIR/20_aggregates.txt")"
  echo "## Validity"
  echo
  echo "- Total runs: ${total_runs:-0}"
  echo "- Valid runs: ${valid_runs:-0}"
  echo "- Invalid runs: ${invalid_runs:-0}"
  echo
  echo "## Metric Definitions"
  echo
  echo "- prompt_ready_s_approx: seconds to first 'Query:' line (fallback: first output line)."
  echo "- first_token_s_approx: seconds to first assistant-content line after 'Initializing agent...' (fallback unavailable => invalid run)."
  echo "- completion_done_s: 'real' elapsed seconds from '/usr/bin/time -p'."
  echo
  echo "## Per-Config Aggregates (valid runs only)"
  echo
  echo "| config_id | total | valid | invalid | avg_prompt_ready_s_approx | avg_first_token_s_approx | avg_completion_done_s |"
  echo "|---|---:|---:|---:|---:|---:|---:|"
  awk -F',' '/^CFG,/{printf("| %s | %s | %s | %s | %s | %s | %s |\n", $2,$3,$4,$5,$6,$7,$8)}' "$OUT_DIR/20_aggregates.txt"
  echo
  echo "## Artifacts"
  echo
  echo "- 00_meta.log"
  echo "- 01_hermes_version.log"
  echo "- 02_ollama_preflight.log"
  echo "- 03_round4_matrix_snapshot.csv"
  echo "- 10_metrics.csv"
  echo "- 11_invalid_runs.csv"
  echo "- 20_aggregates.txt"
  echo "- runs/*.chat.log"
  echo "- runs/*.time.log"
  echo "- configs/*_profile_apply.log"
  echo "- 99_summary.log"
} >"$ROUND4_MD"

{
  echo "== round4 summary =="
  echo "output_dir=$OUT_DIR"
  echo "matrix_file=$MATRIX_FILE"
  echo
  tail -n +1 "$OUT_DIR/20_aggregates.txt"
  echo
  echo "invalid sample:"
  sed -n '1,40p' "$INVALID_CSV"
} >"$SUMMARY_LOG"

echo "Round 4 benchmark completed: $OUT_DIR"
