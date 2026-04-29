# Hermes Speed Improvement Plan (Worker 1)

## Scope
This plan targets the current Hermes setup workflow in this repo with local Ollama model `qwen32b-64k`, active toolsets/skills, profile/config loading, memory/session growth, startup checks, WSL networking paths, and day-to-day CLI usage.

## Performance Objectives (Measurable)

### Baseline latency targets
- `cold_start_to_prompt_ready`: <= 12s (from command enter to interactive prompt)
- `warm_start_to_prompt_ready`: <= 4s
- `simple_chat_first_token` (no tools): <= 3.5s
- `simple_chat_completion_120_tokens`: <= 12s
- `tool_call_roundtrip_local` (single lightweight tool): <= 4s
- `interactive_p95_turn_time` (normal usage): <= 8s
- `error_recovery_time` (interrupt/retry): <= 3s

### Resource targets
- Idle RSS for Hermes process: <= 900MB
- Peak RSS during normal chat (no heavy tools): <= 2.5GB
- CPU sustained during idle: < 10%

## Likely Bottlenecks
1. Oversized local model (`qwen32b-64k`) causing high token prefill and decode latency.
2. Large context windows and unbounded memory/session history growth.
3. Overloaded startup path (too many tools/skills scanned and checked each launch).
4. Slow tool discovery or unavailable endpoints causing retries/timeouts.
5. WSL/host networking overhead (DNS, localhost bridging, firewall scanning).
6. Disk-heavy startup checks (directory scans, stale caches, migration probes).
7. CLI usage patterns that keep carrying large context into each turn.

## Phase 0: Baseline and Guardrails (0-1 day)

### A. Establish repeatable benchmark workflow
Run from repo root:

```bash
mkdir -p docs/enhancements/benchmarks

# 1) preflight health check
./scripts/common/verify.sh

# 2) cold/warm startup timing (measure with shell time)
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 1

# 3) toolset impact comparison
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 1
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets web,terminal,skills --max-turns 1

# 4) resource snapshot while Hermes is active
ps aux | rg "hermes|ollama"
```

When running timing commands, enter `/quit` as soon as the prompt is ready so the measured duration reflects startup and first-response readiness.

Save outputs to timestamped files:

```bash
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p docs/enhancements/benchmarks/$TS
# append each benchmark output into docs/enhancements/benchmarks/$TS/*.log
```

### B. Immediate operational quick wins
- Start with minimal toolsets when not needed:

```bash
hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 8
```

- Reset long conversation drift frequently for heavy sessions:

```bash
/clear
/new
```

- Limit carried memory/session where possible by config (history caps, summary mode).
- Keep Ollama warm before Hermes launches:

```bash
ollama ps
ollama run qwen32b-64k:latest "ok" >/dev/null
```

## Phase 1: Quick Wins (0-1 day)

### 1) Create a `fast-local` profile
- Keep only required toolsets for common work (disable rarely used integrations).
- Reduce startup checks to essential checks only.
- Reduce verbose logging at runtime unless debugging.

Expected gain: 20-40% faster startup and lower p95 turn time.

### 2) Constrain context + memory growth
- Cap max conversation turns retained in active context.
- Enable memory summarization/compaction at fixed intervals.
- Prune stale session artifacts older than N days (start with 14).

Expected gain: lower prefill delay and more stable latency over long sessions.

### 3) Tighten network/tool timeouts
- Lower timeout and retry counts for optional toolsets.
- Fail fast on unreachable endpoints (especially WSL bridge services).

Expected gain: prevents long stalls from single bad tool route.

## Phase 2: Short-Term (1 week)

### 1) Model strategy for speed-sensitive flows
- Keep `qwen32b-64k` as quality profile.
- Add a faster profile for routine tasks (smaller local model) and switch by task type.
- Route tool-heavy or iterative commands to fast profile first, escalate to 32B only when needed.

Expected gain: 2-4x perceived responsiveness in common operations.

### 2) Startup pipeline optimization
- Parallelize non-dependent startup checks.
- Cache tool/skill discovery results with short TTL.
- Skip migration checks after first confirmed success unless `--doctor`/`--repair` mode.

Expected gain: lower cold start variability and fewer startup spikes.

### 3) WSL networking hardening
- Pin stable host endpoints for WSL<->host services.
- Verify DNS and localhost mapping once per boot; avoid per-request probes.
- Exclude Hermes/Ollama process dirs from aggressive antivirus real-time scanning where policy allows.

Validation commands:

```bash
# in WSL
time curl -sS http://127.0.0.1:11434/api/tags >/dev/null
time curl -sS http://<windows-host-ip>:11434/api/tags >/dev/null

# compare latency and packet loss
ping -c 20 127.0.0.1
ping -c 20 <windows-host-ip>
```

## Phase 3: Medium-Term (2-4 weeks)

### 1) Performance regression suite in repo docs workflow
- Add a documented benchmark matrix (cold/warm/tool/model) with thresholds.
- Track weekly p50/p95 values in `docs/enhancements/benchmarks/`.
- Add pass/fail gate for major config/profile changes.

### 2) Adaptive context controller
- Dynamic truncation based on token budget and latency budget.
- Prioritize recent turns + pinned facts; summarize older context automatically.

### 3) Observability and incident playbook
- Standardize logs for: startup stage timing, model prefill time, tool call timing.
- Add "slow-session triage" checklist for operators.

## Measurement Commands (Operational)

### Hermes timing wrappers
```bash
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 1
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets web,terminal,skills --max-turns 1
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets web,browser,terminal,file,skills --max-turns 1
```

### Ollama model health
```bash
ollama ps
ollama list
curl -sS http://127.0.0.1:11434/api/tags | head
```

### System pressure snapshot
```bash
# macOS
vm_stat
top -l 1 | head -n 30

# Linux/WSL
free -h
uptime
top -b -n1 | head -n 30
```

## Rollback Criteria
Rollback any optimization if one or more occur for 2 consecutive benchmark runs:
- Response quality regression blocks normal usage.
- `simple_chat_first_token` worsens by >20% from pre-change baseline.
- Tool success rate drops below 98% for required toolsets.
- Startup failure rate exceeds 1 in 20 launches.

Rollback procedure:
1. Revert to prior profile/config snapshot.
2. Restart Ollama and Hermes cleanly.
3. Re-run baseline benchmark set and compare.

## Risk Table

| Risk | Impact | Probability | Mitigation | Owner |
|---|---|---:|---|---|
| Aggressive context trimming loses important details | Medium | Medium | Pin critical facts + summary checkpoints | Operator |
| Disabling toolsets breaks specific workflows | High | Medium | Keep `default` profile unchanged; optimize `fast-local` first | Operator |
| Smaller model profile degrades output quality | Medium | High | Route only speed-first tasks to fast profile | Operator |
| WSL network tuning inconsistent across reboots | Medium | Medium | Add boot-time validation command checklist | Operator |
| Timeout reductions cause false negatives | Medium | Medium | Tune retry/timeout incrementally and monitor failures | Operator |

## Acceptance Checklist
- [ ] Baseline benchmark logs captured under `docs/enhancements/benchmarks/<timestamp>/`.
- [ ] `fast-local` workflow documented and tested for startup + simple chat.
- [ ] p95 turn time <= 8s in normal usage over at least 30 turns.
- [ ] Warm start <= 4s median over 10 runs.
- [ ] Tool roundtrip <= 4s median for lightweight local tool.
- [ ] No startup crash across 20 consecutive launches.
- [ ] Rollback snapshot exists and has been dry-run once.

## Suggested Execution Order (Practical)
1. Capture baseline metrics first.
2. Implement profile minimization + context controls.
3. Tune timeout/retry and validate tool reliability.
4. Introduce fast model profile routing.
5. Add weekly benchmark tracking and regression checks.
