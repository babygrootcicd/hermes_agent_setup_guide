# Hermes Agent Installation + Start Guide (EN + 繁體中文)

This document provides exact, executable steps to initialize, configure, and start Hermes Agent on macOS and Windows (via WSL2).

本文件提供可直接執行的步驟，讓你在 macOS 與 Windows（透過 WSL2）完成 Hermes Agent 的初始化、設定與啟動。

---

## 0) Scope / 範圍

- Repo root / 專案根目錄:
  - `/Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide`
- Supported:
  - macOS native
  - Windows with WSL2 (Hermes on native Windows is not supported)
- Local model profiles:
  - **fast-local** (active default): model `qwen2.5-coder:7b`, Hermes context override `65536`, Ollama actual ctx `32768`
  - **default** (quality): model `qwen32b-64k:latest`, context `65536`
  - Ollama URL: `http://127.0.0.1:11434/v1`
- Default first-start launch profile in this guide:
  - `--toolsets terminal,skills`
  - `--max-turns 8` (speed-first smoke test)

---

## 0.5) First-Start Decision Flow / 首次啟動決策流程

### English

Run these checks in order before deep troubleshooting:

1. Hermes binary available?
```bash
export PATH="$HOME/.hermes/bin:$PATH"
hermes --version
```
2. Ollama API reachable?
```bash
curl -fsS http://127.0.0.1:11434/api/tags
```
3. Old OpenClaw workspace present and causing config confusion?
```bash
hermes claw cleanup
```
4. Profile and model appropriate for task?
   - `fast-local` profile (default): `qwen2.5-coder:7b` — fast, good for routine work.
   - `default` profile: `qwen32b-64k:latest` — slower, better for complex reasoning.
   - Check active profile: `cat ~/.hermes/active_profile`
   - Switch: `hermes profile use fast-local` or `hermes profile use default`
   - Avoid `hermes3` for agentic tool workflows.
   - Never pass `--model` on CLI — use profiles instead.
5. Still slow (3+ minute responses)?
   - Confirm fast-local model: `grep default ~/.hermes/profiles/fast-local/config.yaml` → should show `qwen2.5-coder:7b`
   - Warm up Ollama first: `ollama run qwen2.5-coder:7b "" >/dev/null 2>&1 &`
   - Reduce toolsets: start with only `terminal,skills` and low `--max-turns`.

### 繁體中文

在進入深度排錯前，請依序做以下檢查：

1. Hermes 指令可用嗎？
```bash
export PATH="$HOME/.hermes/bin:$PATH"
hermes --version
```
2. Ollama API 可連線嗎？
```bash
curl -fsS http://127.0.0.1:11434/api/tags
```
3. 是否有舊的 OpenClaw 工作目錄造成設定混淆？
```bash
hermes claw cleanup
```
4. Profile 與模型是否符合當前任務？
   - `fast-local` profile（預設）：`qwen2.5-coder:7b`，快速，適合日常任務。
   - `default` profile：`qwen32b-64k:latest`，較慢但推理更強。
   - 確認目前 profile：`cat ~/.hermes/active_profile`
   - 切換：`hermes profile use fast-local` 或 `hermes profile use default`
   - 避免 `hermes3` 用於 agent 工具流程。
   - 不要在 CLI 傳 `--model`，改用 profile 管理模型。
5. 還是很慢（回應超過 3 分鐘）？
   - 確認 fast-local 模型：`grep default ~/.hermes/profiles/fast-local/config.yaml` → 應顯示 `qwen2.5-coder:7b`
   - 預熱 Ollama：`ollama run qwen2.5-coder:7b "" >/dev/null 2>&1 &`
   - 縮小 toolsets：先用 `terminal,skills` 與較低 `--max-turns`。

---

## 1) Prerequisites / 先決條件

### English

1. `git`, `curl`, `python3`, and `pip3` must be installed.
2. For local/offline inference, install Ollama and ensure port `11434` is reachable.
3. For Windows users, install and enable WSL2 with Ubuntu.

Quick checks:

```bash
git --version
curl --version
python3 --version
pip3 --version
```

### 繁體中文

1. 需先安裝 `git`、`curl`、`python3`、`pip3`。
2. 若要本地/離線推理，需安裝 Ollama，並可連線到 `11434` port。
3. Windows 使用者必須先安裝並啟用 WSL2（建議 Ubuntu）。

快速檢查指令：

```bash
git --version
curl --version
python3 --version
pip3 --version
```

---

## 2) macOS: Init → Config → Start

### 2.1 Init (Initialization)

#### English

From repo root:

```bash
cd /Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide
./scripts/macos/setup_hermes_ollama.sh
```

What this script does:
1. Checks Ollama installation and running state.
2. Installs Hermes via official install script if missing.
3. Optionally pulls `qwen32b-64k:latest`.
4. Prints exact provider values for `hermes model`.

Optional safe scaffold for `~/.hermes` structure:

```bash
chmod +x ./scripts/common/scaffold-hermes-dir.sh
./scripts/common/scaffold-hermes-dir.sh
```

#### 繁體中文

在專案根目錄執行：

```bash
cd /Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide
./scripts/macos/setup_hermes_ollama.sh
```

這個腳本會做：
1. 檢查 Ollama 是否安裝且服務可用。
2. 若未安裝 Hermes，透過官方安裝腳本安裝。
3. 可選擇是否下載 `qwen32b-64k:latest`。
4. 輸出 `hermes model` 需要填的完整參數。

可選：安全建立 `~/.hermes` 目錄骨架（不覆寫既有檔案）：

```bash
./scripts/common/scaffold-hermes-dir.sh
```

### 2.2 Config (Provider + Model)

#### English

The `fast-local` profile is pre-configured to use `qwen2.5-coder:7b`. The `hermes model` wizard configures the **default (quality) profile** — run it if you need to set up `qwen32b-64k:latest` or a cloud provider.

Run model wizard (for default/quality profile):

```bash
hermes model
```

Choose `Custom endpoint` and fill:
- URL: `http://127.0.0.1:11434/v1`
- API key: `ollama`
- Model: `qwen32b-64k:latest`
- Context length: `65536`

Important:
- Do not pass `--model` on the CLI — use `hermes profile use <name>` to switch models.
- Avoid `hermes3` for agentic tool use.
- If you use cloud providers instead, still run `hermes model` first and complete auth/API-key setup.

#### 繁體中文

`fast-local` profile 已預先設定使用 `qwen2.5-coder:7b`，不需另外配置。`hermes model` 精靈是用來設定 **default（品質）profile** 的，例如 `qwen32b-64k:latest` 或雲端供應商。

執行模型設定精靈（針對 default/品質 profile）：

```bash
hermes model
```

選擇 `Custom endpoint`，並填入：
- URL: `http://127.0.0.1:11434/v1`
- API key: `ollama`
- Model: `qwen32b-64k:latest`
- Context length: `65536`

重點：
- 不要在 CLI 傳 `--model`，改用 `hermes profile use <name>` 切換模型。
- 不建議使用 `hermes3` 做 agent 工具流程。
- 若改用雲端供應商，也必須先完成 `hermes model` 的授權/API key 設定。

### 2.3 Start (First Session)

#### English

Use separate launch commands per mode (model/toolsets are fixed at session start).

1. `fast-local` with `terminal,skills`:
```bash
fast-local chat --toolsets terminal,skills --max-turns 12
```
2. `fast-local` with `web,terminal,skills`:
```bash
fast-local chat --toolsets web,terminal,skills --max-turns 12
```
3. Quality mode `qwen32b-64k` with `terminal,skills` (switch profile first):
```bash
hermes profile use default
hermes chat --toolsets terminal,skills --max-turns 1
# Return to fast: hermes profile use fast-local
```

Switching between modes:

1. Exit current session with `/quit`.
2. Start the other command.

Set `fast-local` as default profile (optional):

```bash
hermes profile use fast-local
```

Then you can use:

```bash
hermes chat --toolsets terminal,skills
```

Or change toolsets per launch.

Then test session persistence:

```bash
hermes chat --continue
hermes sessions list
```

#### 繁體中文

每個模式請分開啟動（模型與 toolsets 在 session 開始時就固定）。

1. `fast-local` 搭配 `terminal,skills`：
```bash
fast-local chat --toolsets terminal,skills --max-turns 12
```
2. `fast-local` 搭配 `web,terminal,skills`：
```bash
fast-local chat --toolsets web,terminal,skills --max-turns 12
```
3. 品質模式 `qwen32b-64k` 搭配 `terminal,skills`（先切換 profile）：
```bash
hermes profile use default
hermes chat --toolsets terminal,skills --max-turns 1
# 切回快速：hermes profile use fast-local
```

模式切換方式：

1. 先在目前 session 輸入 `/quit`。
2. 再啟動另一條指令。

可選：把 `fast-local` 設為預設 profile：

```bash
hermes profile use fast-local
```

之後可直接使用：

```bash
hermes chat --toolsets terminal,skills
```

也可以每次啟動時切換不同 toolsets。

接著測試 session 延續：

```bash
hermes chat --continue
hermes sessions list
```

### 2.4 Verify + Debug

#### English

```bash
./scripts/common/verify.sh
./scripts/macos/debug.sh --help
```

If needed, tail a specific log:

```bash
./scripts/macos/debug.sh --log ~/.hermes/logs/agent.log
```

#### 繁體中文

```bash
./scripts/common/verify.sh
./scripts/macos/debug.sh --help
```

若要直接追蹤特定 log：

```bash
./scripts/macos/debug.sh --log ~/.hermes/logs/agent.log
```

---

## 3) Windows (WSL2): Init → Config → Start

### 3.1 Init in PowerShell

#### English

Open **PowerShell as Administrator**:

```powershell
cd C:\Users\dennis_leedennis_lee\Documents\GitHub\hermes_agent_setup_guide
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows\setup_hermes_ollama.ps1
```

What this script does:
1. Validates WSL2 availability and distro presence.
2. Installs Hermes inside WSL if missing.
3. Checks Ollama on Windows.
4. Prints WSL-to-Windows networking guidance for `HERMES_BASE_URL`.

If WSL is missing:

```powershell
wsl --install -d Ubuntu
```

Reboot, then rerun setup script.

#### 繁體中文

以**系統管理員**開啟 PowerShell：

```powershell
cd C:\Users\dennis_leedennis_lee\Documents\GitHub\hermes_agent_setup_guide
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows\setup_hermes_ollama.ps1
```

這個腳本會做：
1. 驗證 WSL2 是否可用、是否有 Linux 發行版。
2. 若 WSL 內沒有 Hermes，會自動安裝。
3. 檢查 Windows 上 Ollama 狀態。
4. 輸出 WSL 連到 Windows Ollama 的 `HERMES_BASE_URL` 設定方式。

若 WSL 尚未安裝：

```powershell
wsl --install -d Ubuntu
```

重開機後再執行 setup 腳本。

### 3.2 Config inside WSL

#### English

Enter Ubuntu (WSL terminal), then set base URL if needed:

```bash
# Example: detect Windows host IP from WSL
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
echo "export HERMES_BASE_URL=http://${HOST_IP}:11434/v1" >> ~/.bashrc
source ~/.bashrc
```

Run model wizard in WSL:

```bash
hermes model
```

Choose `Custom endpoint` and set:
- URL: `http://<windows-host-ip>:11434/v1` (preferred)
- API key: `ollama`
- Model: `qwen32b-64k:latest`
- Context length: `65536`

#### 繁體中文

進入 Ubuntu（WSL 終端機）後，必要時設定 Base URL：

```bash
# 範例：在 WSL 取得 Windows 主機 IP
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
echo "export HERMES_BASE_URL=http://${HOST_IP}:11434/v1" >> ~/.bashrc
source ~/.bashrc
```

在 WSL 內執行模型設定：

```bash
hermes model
```

選 `Custom endpoint`，設定：
- URL: `http://<windows-host-ip>:11434/v1`（建議）
- API key: `ollama`
- Model: `qwen32b-64k:latest`
- Context length: `65536`

### 3.3 Start in WSL

#### English

```bash
hermes chat --toolsets terminal,skills --max-turns 8
```

For quality/reasoning work, switch profile first:
```bash
hermes profile use default && hermes chat --toolsets terminal,skills --max-turns 8
```

#### 繁體中文

```bash
hermes chat --toolsets terminal,skills --max-turns 8
```

需要品質模式時，先切換 profile：
```bash
hermes profile use default && hermes chat --toolsets terminal,skills --max-turns 8
```

### 3.4 Verify on Windows + WSL

#### English

From WSL:

```bash
cd /mnt/c/Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide
./scripts/common/verify.sh
```

From PowerShell (optional host-side checks):

```powershell
cd C:\Users\dennis_leedennis_lee\Documents\GitHub\hermes_agent_setup_guide
.\scripts\common\verify.ps1
```

#### 繁體中文

在 WSL 內：

```bash
cd /mnt/c/Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide
./scripts/common/verify.sh
```

在 PowerShell（可選，做主機端檢查）：

```powershell
cd C:\Users\dennis_leedennis_lee\Documents\GitHub\hermes_agent_setup_guide
.\scripts\common\verify.ps1
```

---

## 4) Required File/Path Details / 重要路徑細節

### English

Hermes runtime files (default):
- Config: `~/.hermes/config.yaml`
- Secrets/env: `~/.hermes/.env`
- Session DB: `~/.hermes/state.db`
- Logs: `~/.hermes/logs/`
- Sessions: `~/.hermes/sessions/`

### 繁體中文

Hermes 預設資料路徑：
- 設定檔：`~/.hermes/config.yaml`
- 金鑰環境：`~/.hermes/.env`
- Session 資料庫：`~/.hermes/state.db`
- 日誌：`~/.hermes/logs/`
- 對話紀錄：`~/.hermes/sessions/`

---

## 5) Backup / Export / Maintenance

### English

Create backup archive:

```bash
./scripts/common/backup.sh --full --output ~/hermes_backups/hermes-backup-$(date +%F).zip
```

Export sessions (example: last 7 days):

```bash
./scripts/common/export-sessions.sh --since "7 days ago" --output ~/hermes_exports/sessions-$(date +%F).jsonl
```

Model lifecycle helper:

```bash
./scripts/automation/update_models.sh recommended
./scripts/automation/update_models.sh pull qwen32b-64k:latest
./scripts/automation/update_models.sh update
```

### 繁體中文

建立備份封存：

```bash
./scripts/common/backup.sh --full --output ~/hermes_backups/hermes-backup-$(date +%F).zip
```

匯出 sessions（範例：最近 7 天）：

```bash
./scripts/common/export-sessions.sh --since "7 days ago" --output ~/hermes_exports/sessions-$(date +%F).jsonl
```

模型維護工具：

```bash
./scripts/automation/update_models.sh recommended
./scripts/automation/update_models.sh pull qwen32b-64k:latest
./scripts/automation/update_models.sh update
```

---

## 6) Common Failures and Exact Fixes / 常見錯誤與精準修復

### A. `connection refused` to Ollama

- English: Ensure Ollama app/service is running and port `11434` is open.
- 繁中：確認 Ollama 已啟動，且 `11434` 可連線。

Check:

```bash
curl -fsS http://127.0.0.1:11434/api/tags
```

### B. `hermes: command not found`

- English: Reload shell profile and ensure Hermes path exists.
- 繁中：重新載入 shell 設定，並確認 Hermes 路徑存在。

```bash
export PATH="$HOME/.hermes/bin:$PATH"
hermes --version
```

### C. WSL can’t reach Windows Ollama

- English: Set `HERMES_BASE_URL` to Windows host IP from WSL and allow firewall rule for 11434.
- 繁中：在 WSL 用 Windows host IP 設定 `HERMES_BASE_URL`，並開放防火牆 11434。

### D. OpenClaw migration confusion (`~/.openclaw` still active)

- English: Hermes may read stale OpenClaw memory/config if migration leftovers remain.
- 繁中：若遷移殘留未清理，Hermes 可能讀到舊 OpenClaw 設定/記憶。

```bash
hermes claw cleanup
```

### E. Wrong model for tool use (slow, weak tool orchestration)

- English: Re-run `hermes model` and use `qwen32b-64k:latest`; avoid `hermes3` for tool-heavy sessions.
- 繁中：重新執行 `hermes model`，改用 `qwen32b-64k:latest`；工具密集任務避免 `hermes3`。

### F. Desktop app startup error (`posix_spawnp failed`)

- English: This usually means `node-pty` was built for wrong Electron ABI.
- 繁中：通常是 `node-pty` 與目前 Electron ABI 不相容。

```bash
cd app
npm install
npx @electron/rebuild -f -w node-pty
npm run build
```

### G. Very slow responses even when startup succeeds

- English: First check that the fast-local profile uses the 7B model (not the 32B):
  ```bash
  grep default ~/.hermes/profiles/fast-local/config.yaml
  # Should show: qwen2.5-coder:7b
  ```
  If it shows `qwen32b-64k`, edit the file and set `model.default: qwen2.5-coder:7b`.
- English: Warm up Ollama before starting Hermes:
  `ollama run qwen2.5-coder:7b "" >/dev/null 2>&1 &`
- English: Reduce toolsets and turn budget:
  `hermes chat --toolsets terminal,skills --max-turns 8`
- English: Only add more toolsets after baseline responsiveness is confirmed.
- 繁中：先確認 fast-local profile 使用的是 7B 模型（不是 32B）：
  ```bash
  grep default ~/.hermes/profiles/fast-local/config.yaml
  # 應顯示：qwen2.5-coder:7b
  ```
  若顯示 `qwen32b-64k`，請編輯檔案並設為 `model.default: qwen2.5-coder:7b`。
- 繁中：啟動 Hermes 前先預熱 Ollama：
  `ollama run qwen2.5-coder:7b "" >/dev/null 2>&1 &`
- 繁中：縮小 toolsets 與回合數：
  `hermes chat --toolsets terminal,skills --max-turns 8`
- 繁中：確認基礎反應速度後，再逐步增加 toolsets。

### H. Session not resumable

- English: Verify DB/session dirs and run verifier.
- 繁中：確認資料庫與 sessions 目錄，並執行驗證腳本。

```bash
./scripts/common/verify.sh
```

---

## 7) Security Baseline (Must-Do) / 安全基線（必做）

### English

1. Never commit `~/.hermes/.env`, tokens, or `auth.json`.
2. Enable conservative config defaults (`dangerous_command_approval`, prompt-injection controls).
3. Use separate profiles for personal/professional contexts.
4. Export/redact session artifacts before sharing.

### 繁體中文

1. 絕對不要提交 `~/.hermes/.env`、token、`auth.json`。
2. 啟用保守安全設定（例如 `dangerous_command_approval`、prompt injection 防護）。
3. 個人與工作請使用分離 profile。
4. 分享 session 前先匯出並去識別化。

---

## 8) Minimal Daily Start Commands / 每日最小啟動指令

### macOS

```bash
cd /Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide
hermes chat --continue
```

### Windows (WSL)

```bash
cd /mnt/c/Users/dennis_leedennis_lee/Documents/GitHub/hermes_agent_setup_guide
hermes chat --continue
```

If continuing fails, list and resume explicitly:

```bash
hermes sessions list
hermes chat --resume <session_id>
```

若 `--continue` 失敗，先列出 session 再指定 `--resume <session_id>`。

If responsiveness is poor, confirm fast-local profile is active and start a fresh session:

```bash
hermes profile use fast-local
hermes chat --toolsets terminal,skills --max-turns 8
```

若反應速度仍慢，確認 fast-local profile 已啟用再開新 session：

```bash
hermes profile use fast-local
hermes chat --toolsets terminal,skills --max-turns 8
```
