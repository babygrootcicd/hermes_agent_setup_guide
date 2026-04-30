# Round 4 Enhancement Implementation Plan

**Date**: 2026-04-30  
**Input**: `docs/enhancements/round4_root_cause_investigation_report.md`  
**Goal**: Convert Round 4 findings into executable, multi-agent implementation work with objective gates.

## Scope
- Implement Round 4 actions A-E from the root-cause report.
- Focus on measurable latency improvement for first-token and short completion on fast-local workflows.
- Prevent recurrence by adding benchmark validity gates and config consistency checks.

## Explicit Assumptions
1. This repository does not contain Hermes core source; only setup/automation/docs are in scope.
2. Some runtime configuration changes require local profile edits outside the repo (`~/.hermes/profiles/fast-local/config.yaml`); those steps are automated/documented via repo scripts where possible.
3. Ollama is available at `http://127.0.0.1:11434` during benchmark execution.
4. All benchmark comparisons are run on the same machine, same thermal/power conditions, and same toolset (`terminal,skills`) unless the matrix row explicitly differs.
5. CI is optional because `.github/` is not currently present; static guardrails must run locally first.

## Ownership Model (Multi-Agent)
- **Agent A (Benchmark Harness)**: Build/maintain round4 response-latency harness and invalidation logic.
- **Agent B (Experiment Ops)**: Execute matrix runs, collect artifacts, publish benchmark summaries.
- **Agent C (Context/Prompt Tuning)**: Reduce first-turn prompt footprint for fast-local and validate quality risk.
- **Agent D (Config Guardrails)**: Define canonical fast-local contract and enforce consistency checks.
- **Agent E (Version Delta + Release Decision)**: Compare current vs updated Hermes build, issue go/no-go recommendation.
- **Coordinator**: Dependency tracking, acceptance gate decisions, rollback activation.

## Phase Plan

### Phase 1 (P0) - Replace startup-only benchmark with response benchmark (Action A)

| Task ID | Owner | Dependencies | Exact files likely changed | Expected deliverables |
|---|---|---|---|---|
| R4-A1 | Agent A | None | `scripts/automation/run_benchmark_round4_response_latency.sh` (new), `scripts/README.md` | New harness that sends a real prompt and records `t_prompt_ready`, `t_first_token`, `t_completion_done`. |
| R4-A2 | Agent A | R4-A1 | `scripts/automation/run_benchmark_round4_response_latency.sh`, `docs/enhancements/benchmarks/<timestamp>_round4_root_cause/ROUND4.md` (generated) | Invalidation rules (`profile/config error`, `no model`, `no assistant text`) and summary with valid/invalid counts. |
| R4-A3 | Agent B | R4-A2 | `docs/enhancements/benchmarks/<timestamp>_round4_root_cause/00_meta.log` (generated), `.../10_metrics.csv` (generated), `.../99_summary.log` (generated) | First valid benchmark set using real prompt path and new metric schema. |

**Success criteria**
- 100% benchmark runs output all three timestamps.
- 0 invalid runs included in aggregate stats.
- At least 10 valid runs captured for the initial fast-local baseline.

**Rollback criteria**
- If >10% runs are falsely invalidated (manual inspection), revert to prior script revision and re-run baseline.
- If harness cannot detect first token reliably, freeze summary publication and keep raw logs only.

### Phase 2 (P0) - Controlled context/model matrix (Action B)

| Task ID | Owner | Dependencies | Exact files likely changed | Expected deliverables |
|---|---|---|---|---|
| R4-B1 | Agent B | R4-A3 | `scripts/automation/round4_matrix.csv` (new), `scripts/automation/run_benchmark_round4_response_latency.sh` | Matrix definition for: `qwen2.5-coder:7b` (`16384`, `32768`), `qwen2.5-coder-fast:latest` (`65536`), `qwen32b-64k:latest` (quality baseline). |
| R4-B2 | Agent B | R4-B1 | `docs/enhancements/benchmarks/<timestamp>_round4_root_cause/*` (generated) | 5 cold + 5 warm runs per config, with per-run model identity and context config. |
| R4-B3 | Agent B | R4-B2 | `docs/enhancements/benchmarks/<timestamp>_round4_root_cause/ROUND4.md` (generated) | Aggregate p50/p95 first-token and completion metrics for each matrix row. |

**Success criteria**
- Fast-local (`qwen2.5-coder-fast:latest`) meets: `p50 first_token <= 8s`, `p95 first_token <= 15s`, `p50 completion<=120 tokens <= 20s`.
- 10/10 runs per row are valid or invalid reasons are explicitly recorded.

**Rollback criteria**
- If any matrix row has <8 valid runs after retries, mark row inconclusive and do not use it for decision gates.
- If baseline model results are accidentally mixed into fast-local aggregates, discard aggregate and recompute.

### Phase 3 (P1) - Reduce initial prompt footprint for fast-local (Action C)

| Task ID | Owner | Dependencies | Exact files likely changed | Expected deliverables |
|---|---|---|---|---|
| R4-C1 | Agent C | R4-B3 | `docs/enhancements/benchmarks/<timestamp>_round4_root_cause/context_footprint_audit.md` (new), `scripts/automation/run_benchmark_round4_response_latency.sh` | Audit of first-turn context contributors and before/after context-meter values. |
| R4-C2 | Agent C | R4-C1 | `README.md`, `docs/dev_progress/50-config-reference.md`, `scripts/automation/run_benchmark_round4_response_latency.sh`, `~/.hermes/profiles/fast-local/config.yaml` (runtime, outside repo) | Fast-local prompt/context reduction changes with clear operator instructions and benchmarked impact. |

**Success criteria**
- Initial context meter reduced from `6.16K` to `<=2.5K` at first turn.
- Fast-local first-token latency improves by `>=40%` versus Round 4 pre-tuning baseline.

**Rollback criteria**
- If tool-use quality regression is observed in 3 consecutive manual smoke tasks, revert prompt-footprint changes.
- If context drops but latency does not improve by at least 20%, pause further trimming and escalate to model/runtime path.

### Phase 4 (P1) - Enforce config consistency guardrails (Action D)

| Task ID | Owner | Dependencies | Exact files likely changed | Expected deliverables |
|---|---|---|---|---|
| R4-D1 | Agent D | R4-B3 | `docs/enhancements/round4_fast_local_config_contract.md` (new), `README.md`, `docs/enhancements/round3_speed_fix_plan.md` | Canonical fast-local contract: model default, context length, benchmark toolsets, and allowed variants. |
| R4-D2 | Agent D | R4-D1 | `scripts/automation/check_fast_local_contract.sh` (new), `scripts/README.md`, optional `.github/workflows/fast_local_contract.yml` (new; only if CI adoption approved) | Static check that fails on model/context mismatch across docs/scripts for fast-local defaults. |

**Success criteria**
- Zero conflicting fast-local defaults across `scripts/automation` and `docs/enhancements`.
- Contract check fails intentionally on seeded mismatch and passes on clean repo.

**Rollback criteria**
- If guardrail causes false positives on clean state, disable required gate status and keep as non-blocking warning until parser fix.

### Phase 5 (P2) - Re-baseline current vs updated Hermes build (Action E)

| Task ID | Owner | Dependencies | Exact files likely changed | Expected deliverables |
|---|---|---|---|---|
| R4-E1 | Agent E | R4-A2, R4-B3 | `scripts/automation/run_benchmark_round4_response_latency.sh`, `docs/enhancements/benchmarks/<timestamp>_round4_current/ROUND4.md` (generated), `docs/enhancements/benchmarks/<timestamp>_round4_updated/ROUND4.md` (generated) | Like-for-like benchmark runs on current and updated Hermes builds. |
| R4-E2 | Agent E | R4-E1, R4-C2, R4-D2 | `docs/enhancements/round4_version_delta_report.md` (new), `docs/enhancements/round4_closure_note.md` (new) | Version delta analysis and final upgrade recommendation with risk notes. |

**Success criteria**
- Version delta report includes exact Hermes versions, identical matrix config, and normalized p50/p95 deltas.
- If updated Hermes improves first-token by `>=20%`, upgrade path is prioritized and documented.

**Rollback criteria**
- If updated Hermes regresses fast-local p50 by `>10%` or introduces >1 failure in 20 runs, hold upgrade and retain current build path.

## Dependency Graph (Execution Order)
1. `R4-A1 -> R4-A2 -> R4-A3`
2. `R4-A3 -> R4-B1 -> R4-B2 -> R4-B3`
3. `R4-B3 -> (R4-C1 -> R4-C2)` and `R4-B3 -> (R4-D1 -> R4-D2)` in parallel
4. `R4-A2 + R4-B3 + R4-C2 + R4-D2 -> R4-E1 -> R4-E2`

## Verification Strategy
- **Preflight per run**:
  - `curl -fsS http://127.0.0.1:11434/api/tags`
  - `hermes --version`
  - active profile + model/context snapshot in artifact metadata
- **Run integrity checks**:
  - Reject runs with profile apply errors, model load failure, no assistant output, or missing timestamps.
  - Persist full raw logs for accepted and rejected runs.
- **Comparability controls**:
  - Fixed prompt template (`hey` for first-token tests, capped follow-up for <=120 token completion tests).
  - Fixed toolset (`terminal,skills`) for matrix comparability.
  - Split cold/warm cohorts and report separately before combined aggregate.
- **Reproducibility**:
  - Store all artifacts under `docs/enhancements/benchmarks/<timestamp>_round4_*`.
  - Include run manifest with command line, profile, model, context length, and host timestamp.

## Benchmark Acceptance Gates

### Gate G1: Data Quality (must pass before performance evaluation)
- 100% runs have `t_prompt_ready`, `t_first_token`, `t_completion_done`.
- 0 invalid runs in aggregate tables.
- At least 10 valid runs per matrix row (5 cold + 5 warm minimum).

### Gate G2: Fast-Local Performance
- `p50 first_token <= 8s`
- `p95 first_token <= 15s`
- `p50 completion(<=120 tokens) <= 20s`

### Gate G3: Stability
- No profile creation/configuration errors across 20 consecutive automated runs.
- No model identity mismatch in any accepted run.

### Gate G4: Decision Gate
- If G1-G3 pass: publish closure note and lock round4 benchmark method.
- If G2 fails: prioritize prompt/context footprint reduction first, then context-cap/model tuning.

## Global Rollback Policy
- Trigger rollback if any of these persist for 2 consecutive benchmark cycles:
  - `first_token` worsens by >20% against last accepted baseline.
  - Required tool task success rate drops below 98%.
  - Benchmark invalid-run ratio exceeds 10% after retry budget.
- Rollback steps:
  1. Revert changed automation/doc files to last accepted round4 baseline commit.
  2. Restore prior fast-local runtime config (`~/.hermes/profiles/fast-local/config.yaml`).
  3. Re-run Gate G1 only; unblock G2-G4 after data quality is restored.

## Final Deliverables Checklist
- [ ] Round4 response benchmark harness committed.
- [ ] Round4 matrix artifacts captured under `docs/enhancements/benchmarks/...`.
- [ ] Context footprint audit + tuning results documented.
- [ ] Fast-local contract + static guardrail implemented.
- [ ] Current vs updated Hermes delta report published.
- [ ] Closure note with pass/fail gate outcomes published.
