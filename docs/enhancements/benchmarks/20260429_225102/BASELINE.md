# Baseline Benchmark Report

- Timestamp: 2026-04-29T22:51:02+08:00
- Folder: `docs/enhancements/benchmarks/20260429_225102`
- Host CWD: `/Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide`

## Environment Snapshot

- Hermes: `v0.11.0 (2026.4.23)`
- Ollama client: `0.20.7` (warning: no running Ollama instance detected)

## Measured Results

- `verify.sh` runtime: `real 16.31s`
- `curl /api/tags` runtime: `real 0.02s` (failed to connect)
- `hermes chat --toolsets terminal,skills --max-turns 1`: `real 9.01s`
- `hermes chat --toolsets web,terminal,skills --max-turns 1`: `real 9.45s`
- Toolset overhead delta (`web` added): `+0.44s`

## Observations

- Hermes CLI starts and exits correctly in non-interactive benchmark mode (`/quit` piped).
- Ollama endpoint `127.0.0.1:11434` was not reachable during this run.
- `verify.sh` completed with warnings but no hard fail (`ok=11, warn=8, fail=0`).
- Process snapshot command (`ps aux`) returned `operation not permitted` in this execution environment.

## Blocking Warnings To Clear For Next Baseline

1. Start Ollama service and confirm:

```bash
curl -fsS http://127.0.0.1:11434/api/tags
```

2. Re-run these two startup timings after Ollama is healthy:

```bash
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 1
/usr/bin/time -p hermes chat --model qwen32b-64k:latest --toolsets web,terminal,skills --max-turns 1
```

3. Re-run verifier:

```bash
./scripts/common/verify.sh
```

## Raw Logs

- `00_meta.log`
- `01_hermes_version.log`
- `02_ollama_version.log`
- `03_verify.log`
- `04_ollama_tags.log`
- `05_chat_terminal_skills.log`
- `06_chat_web_terminal_skills.log`
- `07_process_snapshot.log`
- `99_summary.log`
