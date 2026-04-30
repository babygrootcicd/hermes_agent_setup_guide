# Round 4 Fast-Local Configuration Contract

**Date**: 2026-04-30  
**Status**: Canonical contract for fast-local docs/automation consistency checks.

## Purpose

Define one fast-local baseline so benchmark results and setup guidance are comparable across this repository.

## Contract Baseline

### 1) Preferred default model and allowed variants

- Preferred fast-local default model: `qwen2.5-coder:7b`
- Allowed fast-local variant: `qwen2.5-coder-fast:latest` (7B variant created with `num_ctx 65536`)
- Not valid as fast-local default:
  - `qwen32b-64k:latest` (quality baseline only)
  - `hermes3` (not recommended for tool-calling workflows)

### 2) Context length expectations

- Fast-local profile (`~/.hermes/profiles/fast-local/config.yaml`) must use:
  - `model.context_length: 65536`
- If default is `qwen2.5-coder:7b`, effective Ollama native context can still be `32768` (known limitation).
- For full `65536` effective context, use `qwen2.5-coder-fast:latest` (created via `scripts/macos/setup_fast_local_model.sh`).
- Any automation that sets fast-local `model.context_length` below `65536` is a contract violation.

### 3) Benchmark command/toolset consistency rules

- Canonical fast-local latency benchmark toolset: `terminal,skills`
- Fast-local benchmark command should resolve model from profile, not CLI override:
  - Use `hermes --profile fast-local chat ...`
  - Do not use `--model` for fast-local benchmark rows.
- Startup-only `/quit` timing is invalid for response-latency claims.
- Non-canonical toolset runs (for example `web,terminal,skills`) can be collected, but must be reported separately from canonical fast-local latency numbers.

## Guardrail Scope

`scripts/automation/check_fast_local_contract.sh` validates drift/mismatch at minimum across:

- `README.md`
- `installation_start_guide.md`
- `docs/enhancements/round3_speed_fix_plan.md`
- `scripts/automation/*`

Note: `run_benchmark_round2_fast_local.sh` is treated as a historical artifact and excluded from pass/fail guardrail enforcement.

The checker exits non-zero on violations and prints actionable fixes.
