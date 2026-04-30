# Round 4 Root-Cause Investigation Report: Hermes Latency

**Date**: 2026-04-30  
**Scope**: Investigation grounded in `.ignore.txt`, `docs/enhancements/*`, and `scripts/*` artifacts in this repository.

## 1) Symptom statement and exact evidence with metrics

Primary user-facing symptom is severe first-response latency in an interactive session, even after switching to the fast-local model path.

### Evidence

| Evidence | Metric | Source |
|---|---:|---|
| Interactive `hey` turn took **4m36s** elapsed | 276s first response latency | `.ignore.txt:95` |
| Same slow response occurred on `qwen2.5-coder-fast:latest` | Model shown at response time: `qwen2.5-coder-fast:latest` | `.ignore.txt:51`, `.ignore.txt:95` |
| Context meter at slow response was **6.16K/65.5K** (9%) | Large initial prompt/context payload before normal usage | `.ignore.txt:95` |
| Existing benchmark headline numbers (5.79s to 9.45s) measure startup/quit path, not response generation | `real 8.62s` / `5.79s` / `9.01s` / `9.45s` | `docs/enhancements/benchmarks/20260429_230136_round2_fast_local/ROUND2.md:11-13`, `docs/enhancements/benchmarks/20260429_225102/BASELINE.md:16-18` |
| Benchmark harness sends `/quit` immediately | No user prompt or model answer measured | `scripts/automation/run_benchmark_round2_fast_local.sh:80`, `:85`, `:90` |
| One Round 2 run reported `0.07s` for fast-local because profile creation failed (`PermissionError`) | Invalid benchmark run was still summarized as measured result | `docs/enhancements/benchmarks/20260429_230044_round2_fast_local/05_profile_apply.log:15`, `.../06_chat_fast_terminal_skills.log:2-3`, `.../ROUND2.md:11-13` |

### Quantified gap vs repo targets

- Target `simple_chat_first_token <= 3.5s` (`docs/enhancements/hermes_speed_improvement_plan.md:11`).
- Observed interactive response: **276s**, i.e. **~79x slower** than target.

## 2) Ranked root causes with confidence levels and rationale

## RC1. Benchmark methodology masked true latency (Confidence: High)
- Rationale:
  - Round 2 timing path is scripted as `printf '/quit\n' | hermes ...` and exits without a real generation turn (`scripts/automation/run_benchmark_round2_fast_local.sh:80`, `:85`, `:90`).
  - Invalid runs (profile creation failure) still produced attractive but meaningless `0.07s` and were recorded in report markdown (`docs/enhancements/benchmarks/20260429_230044_round2_fast_local/ROUND2.md:11-13`).
  - This caused false confidence that latency was fixed while interactive latency remained minutes.

## RC2. Effective context configuration is too heavy for fast-local on this hardware (Confidence: Medium-High)
- Rationale:
  - Fast-local variant is explicitly configured for 64k context (`scripts/macos/setup_fast_local_model.sh:27`, `:34`).
  - Slow response snapshot shows `6.16K/65.5K` at a trivial `hey` turn (`.ignore.txt:95`), indicating a large fixed context payload before meaningful work begins.
  - Large context budgets can increase KV/cache pressure and prefill time, especially on laptop-class unified memory.

## RC3. Configuration drift across scripts/plans created unstable behavior (Confidence: Medium)
- Rationale:
  - Round 2 benchmark automation sets `model.context_length 16384` (`scripts/automation/run_benchmark_round2_fast_local.sh:68`), while Round 3 plan standardizes on 65536 for Hermes minimum checks (`docs/enhancements/round3_speed_fix_plan.md:46-47`).
  - Model defaults also vary across artifacts (`qwen2.5-coder:7b` vs `qwen2.5-coder-fast:latest`), making comparisons non-isomorphic.

## RC4. Earlier model selection regression (`qwen32b-64k`) is a confirmed historical amplifier, but not sufficient for current slow case (Confidence: Medium)
- Rationale:
  - Round 3 document records prior 3+ minute behavior tied to 32.8B model usage on MacBook (`docs/enhancements/round3_speed_fix_plan.md:5`, `:18`, `:26`).
  - Current slow transcript is already on `qwen2.5-coder-fast:latest`, so this is a historical cause and recurrence risk, not the sole present cause.

## 3) What is already fixed vs unresolved gaps

### Already fixed
- A fast-local 7B model variant with 64k context exists and creation flow works:
  - `scripts/macos/setup_fast_local_model.sh` defines and creates `qwen2.5-coder-fast:latest` with `num_ctx 65536`.
  - Transcript confirms successful creation (`.ignore.txt:14-24`).
- Round 2 second pass fixed profile creation path and produced usable startup logs (`docs/enhancements/benchmarks/20260429_230136_round2_fast_local/05_profile_apply.log:3-23`).

### Unresolved gaps
- No valid post-fix benchmark currently measures first token or completion latency on real prompts.
- Existing benchmark reports mix valid and invalid runs without gating criteria.
- No repo-captured resource telemetry (RSS, memory pressure, swap, tokenizer/prefill/decode timings) during the 4m36s incident.
- Configuration inconsistency remains across automation and plans (context length/model default mismatch).
- Interaction-level symptom (minutes) and benchmark-level symptom (seconds) are not reconciled by current data pipeline.

## 4) Concrete remediation actions with measurable targets

## Action A: Replace startup-only benchmark with response benchmark (Priority P0)
- Change benchmark harness to send a real prompt (for example `hey`) and wait for assistant text before timing success.
- Add run invalidation rules:
  - Fail run if profile creation errors, model not loaded, or no assistant response.
- Targets:
  - `first_token_latency` captured for every run.
  - 0% invalid runs included in summary tables.
  - At least 10 valid runs per profile/config permutation.

## Action B: Run controlled context/model matrix (Priority P0)
- Matrix:
  - `qwen2.5-coder:7b` (`context_length` 16384, 32768)
  - `qwen2.5-coder-fast:latest` (`num_ctx` 65536)
  - `qwen32b-64k:latest` as quality baseline only
- Keep toolsets constant (`terminal,skills`) for comparability.
- Targets:
  - Fast-local `p50 first_token <= 8s`
  - Fast-local `p95 first_token <= 15s`
  - Fast-local `p50 completion(<=120 tokens) <= 20s`

## Action C: Reduce initial prompt footprint for fast-local (Priority P1)
- Audit what contributes to initial `6.16K` context footprint and minimize non-essential default prompt content for fast profile.
- Targets:
  - Initial context meter at first turn reduced from `6.16K` to `<=2.5K`.
  - `first_token_latency` improves by `>=40%` vs current slow-path baseline.

## Action D: Enforce config consistency guardrails (Priority P1)
- Define one canonical fast-local configuration contract in docs and automation (model name + context length).
- CI/static check should flag script/doc mismatch for fast-local defaults.
- Targets:
  - Zero conflicting fast-local defaults across `scripts/automation` and `docs/enhancements`.

## Action E: Re-baseline on current Hermes build and updated build (Priority P2)
- Transcript shows local install is `159 commits behind` (`.ignore.txt:69`).
- Run same matrix on current and updated Hermes versions to isolate product-level performance deltas.
- Targets:
  - Quantified version delta with same hardware/config.
  - If update yields `>=20%` first-token improvement, prioritize upgrade path.

## 5) Risks/tradeoffs

- Lowering context length improves speed but can truncate long-session reasoning.
- Reducing prompt/skill payload for fast-local can hurt tool selection quality for specialized tasks.
- Using 7B fast model improves latency but may regress complex reasoning quality compared with 32B.
- Tight benchmark gating may initially reduce “pass” counts; this is expected and improves data integrity.
- Updating Hermes may change behavior and require profile re-validation.

## 6) Verification/benchmark plan

## Phase 1: Harness validation
1. Build a round4 benchmark runner that records:
   - `t_prompt_ready`
   - `t_first_token`
   - `t_completion_done`
2. Require a real user prompt and assistant response; reject runs that only execute `/quit` or error out.
3. Store all artifacts under `docs/enhancements/benchmarks/<timestamp>_round4_root_cause/`.

## Phase 2: Controlled experiment execution
1. Preflight each run:
   - `curl -fsS http://127.0.0.1:11434/api/tags`
   - `hermes --version`
   - Active profile/model dump
2. Execute matrix from Action B with:
   - Cold start: 5 runs per config
   - Warm start: 5 runs per config
3. Capture system pressure snapshots (RSS, CPU, memory pressure) during slow turns.

## Phase 3: Acceptance criteria
1. Data quality:
   - 100% runs include first-token timestamp and model identity.
   - 0 invalid runs included in aggregate metrics.
2. Performance:
   - Fast-local meets `p50 <= 8s`, `p95 <= 15s` first-token target.
3. Stability:
   - No profile-creation/configuration errors across 20 consecutive automated runs.

## Phase 4: Decision gate
1. If targets are met, publish updated speed-fix closure note and lock benchmark method.
2. If not met, prioritize either:
   - prompt/context footprint reduction, or
   - fast-local context cap reduction, before broader tuning work.
