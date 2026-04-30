# Setup & Utility Scripts

This directory contains the automation scripts for installing and verifying the Hermes Agent + Ollama environment.

## Directory Structure

- `macos/`:
  - `setup_hermes_ollama.sh`: The primary installer for macOS users.
  - `build_app.sh`: Automates the packaging of the Electron Desktop App.
- `windows/`:
  - `setup_hermes_ollama.ps1`: The primary installer for Windows users (utilizes WSL2).
- `common/`:
  - `verify.sh`: Cross-platform Bash script to verify installation status.
  - `verify.ps1`: PowerShell version of the verification script.
- `automation/`:
  - `run_benchmark_round2_fast_local.sh`: Round 2 benchmark harness (historical artifact).
  - `run_benchmark_round4_response_latency.sh`: Round 4 response-latency harness (real prompt + assistant output).
  - `round4_matrix.csv`: Matrix input consumed by the Round 4 harness.
  - `update_models.sh`: Ollama model list/pull/update/remove helper.
  - `check_fast_local_contract.sh`: Guardrail for fast-local model/context/toolset consistency across docs/scripts.

## Usage
Always run scripts from the root of the repository to ensure paths are resolved correctly.

### Fast-Local Contract Guardrail

Run:

```bash
./scripts/automation/check_fast_local_contract.sh
```

Behavior:

- Exit `0`: no fast-local contract violations detected.
- Exit non-zero: one or more drift/mismatch violations found.
- Each violation prints an `ERROR:` line with a path, line number (when available), and suggested fix.

Minimum check scope:

- `README.md`
- `installation_start_guide.md`
- `docs/enhancements/round3_speed_fix_plan.md`
- `scripts/automation/*`

### Round 4 Response-Latency Benchmark

Run:

```bash
./scripts/automation/run_benchmark_round4_response_latency.sh
```

Optional custom matrix file:

```bash
./scripts/automation/run_benchmark_round4_response_latency.sh ./scripts/automation/round4_matrix.csv
```
