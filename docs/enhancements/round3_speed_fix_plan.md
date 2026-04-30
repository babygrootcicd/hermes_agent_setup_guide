# Round 3: Speed Fix Plan

**Date**: 2026-04-30  
**Status**: Implemented (configuration changes); real-prompt latency validation pending Round 4 benchmark harness  
**Problem**: `hermes chat` (fast-local profile) takes 3+ minutes to respond.

---

## Root Cause Analysis

| Step | What happened |
|---|---|
| Round 1 (baseline) | `qwen32b-64k:latest` used, context_length missing → slow but working |
| Round 2 (context fix attempt) | `fast-local` profile had `context_length: 16384` + wrong model → init failed with "below 64k minimum" |
| Previous session fix | Set fast-local profile to `qwen32b-64k:latest` / 65536 → fixed init error but introduced 3+ min responses |
| Round 3 (this plan) | Revert fast-local to a small fast model with proper context config |

**Core issue**: A 32.8B parameter model (`qwen32b-64k:latest`) on a MacBook causes extremely slow token generation. For a simple "hey" response, inference takes 3+ minutes because the model barely fits in unified memory and is partially CPU-offloaded.

**Round 4 update**: This explains a major historical slowdown, but it is not a complete closure for current latency. Later investigation found startup-only timing and configuration/context drift can mask true interaction latency.

---

## Model Comparison

| Model | Params | Typical tok/s (Apple M-series) | Hermes ctx check | Ollama native ctx |
|---|---|---|---|---|
| `qwen32b-64k:latest` | 32.8B | 2–5 | Pass (65536) | 65536 |
| `qwen2.5-coder:7b` | 7.6B | 25–60 | Fail (32768 < 64000) | 32768 |
| `qwen2.5-coder-fast:latest` (custom) | 7.6B | 25–60 | Pass (65536) | 65536 |

**Solution**: Use `qwen2.5-coder:7b` for fast-local, with `context_length: 65536` override in the profile config to satisfy Hermes' minimum check. Optionally create a proper Ollama model with `num_ctx 65536` for full 64k support.

---

## Changes Made

### 1. fast-local profile (`~/.hermes/profiles/fast-local/config.yaml`)

```yaml
# Before (broken by previous fix)
model:
  default: qwen32b-64k:latest
  context_length: 65536

# After
model:
  default: qwen2.5-coder:7b
  context_length: 65536   # satisfies Hermes 64k check; Ollama truncates at 32k for very long sessions
```

Expected improvement (hypothesis): ~10–20x faster token generation for typical conversations. This is not acceptance evidence until validated with real prompts and assistant responses.

### 2. Setup script (`scripts/macos/setup_fast_local_model.sh`)

Creates a proper Ollama model variant `qwen2.5-coder-fast:latest` with `num_ctx 65536` so that both Hermes and Ollama agree on the 64k context window. Run this for full 64k context support:

```bash
./scripts/macos/setup_fast_local_model.sh
```

After running, update the fast-local profile to `qwen2.5-coder-fast:latest`.

---

## Estimated Performance After Fix (Pre-Round4 Validation)

The table below is an estimate based on model size/runtime expectations. Treat these as planning values, not verified interaction-latency results.

| Metric | Before (qwen32b) | After (qwen2.5-coder:7b) | Target |
|---|---|---|---|
| First token (simple chat) | 180–210s | 3–8s | ≤3.5s |
| Startup to prompt ready | 7–9s | 7–9s | ≤12s |
| Token generation speed | 2–5 tok/s | 25–60 tok/s | — |
| Max context (Ollama) | 65536 | 32768 (65536 w/ fast model) | — |

---

## Two-Track Deployment

**Track A (immediate)**: Profile updated to `qwen2.5-coder:7b` + `context_length: 65536`.
- Applies immediately, no extra setup steps.
- Conversations under 32k tokens work perfectly.
- Very long sessions (>32k tokens) truncated by Ollama.
- Response-latency fix is not considered confirmed until real-prompt benchmark gates pass.

**Track B (proper, run when ready)**:
```bash
./scripts/macos/setup_fast_local_model.sh
# Then edit ~/.hermes/profiles/fast-local/config.yaml:
# model.default: qwen2.5-coder-fast:latest
```
- Full 64k context support in both Hermes and Ollama.
- Expected to have similar generation speed to Track A, pending real-prompt benchmark confirmation.

---

## Quality/Speed Mode Switching

| Use case | Command | Model |
|---|---|---|
| Fast responses, coding, routine tasks | `hermes chat --toolsets terminal,skills` | qwen2.5-coder:7b (fast-local) |
| Complex reasoning, large context needed | `hermes profile use default && hermes chat` | qwen32b-64k:latest |
| Back to fast-local | `hermes profile use fast-local` | qwen2.5-coder:7b |

---

## Rollback

If qwen2.5-coder:7b produces poor tool-use quality:
```bash
# Switch to quality model for current session
hermes profile use default
hermes chat --toolsets terminal,skills
```

---

## Benchmark Schedule

Use the Round 4 response-latency harness for acceptance benchmarking:
```bash
./scripts/automation/run_benchmark_round4_response_latency.sh
```

Notes:
- Startup-only paths (for example immediate `/quit`) do not measure real response latency.
- Only summarize runs that include assistant output plus `t_prompt_ready`, `t_first_token`, and `t_completion_done`.
