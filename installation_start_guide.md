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
- Default local model settings used across this guide:
  - Ollama URL: `http://127.0.0.1:11434/v1`
  - Model: `qwen2.5-coder:7b`
  - Context length: `32768`

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
3. Optionally pulls `qwen2.5-coder:7b`.
4. Prints exact provider values for `hermes model`.

Optional safe scaffold for `~/.hermes` structure:

```bash
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
3. 可選擇是否下載 `qwen2.5-coder:7b`。
4. 輸出 `hermes model` 需要填的完整參數。

可選：安全建立 `~/.hermes` 目錄骨架（不覆寫既有檔案）：

```bash
./scripts/common/scaffold-hermes-dir.sh
```

### 2.2 Config (Provider + Model)

#### English

Run model wizard:

```bash
hermes model
```

Choose `Custom endpoint` and fill:
- URL: `http://127.0.0.1:11434/v1`
- API key: `ollama`
- Model: `qwen2.5-coder:7b`
- Context length: `32768`

Important:
- Avoid `hermes3` for agentic tool use.
- If you use cloud providers instead, still run `hermes model` first and complete auth/API-key setup.

#### 繁體中文

執行模型設定精靈：

```bash
hermes model
```

選擇 `Custom endpoint`，並填入：
- URL: `http://127.0.0.1:11434/v1`
- API key: `ollama`
- Model: `qwen2.5-coder:7b`
- Context length: `32768`

重點：
- 不建議使用 `hermes3` 做 agent 工具流程。
- 若改用雲端供應商，也必須先完成 `hermes model` 的授權/API key 設定。

### 2.3 Start (First Session)

#### English

```bash
hermes chat --provider custom --model qwen2.5-coder:7b --toolsets terminal,skills --max-turns 12
```

Then test session persistence:

```bash
hermes chat --continue
hermes sessions list
```

#### 繁體中文

```bash
hermes chat --provider custom --model qwen2.5-coder:7b --toolsets terminal,skills --max-turns 12
```

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
- Model: `qwen2.5-coder:7b`
- Context length: `32768`

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
- Model: `qwen2.5-coder:7b`
- Context length: `32768`

### 3.3 Start in WSL

#### English

```bash
hermes chat --provider custom --model qwen2.5-coder:7b --toolsets terminal,skills --max-turns 12
```

#### 繁體中文

```bash
hermes chat --provider custom --model qwen2.5-coder:7b --toolsets terminal,skills --max-turns 12
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
./scripts/automation/update_models.sh pull qwen2.5-coder:7b
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
./scripts/automation/update_models.sh pull qwen2.5-coder:7b
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

### D. Session not resumable

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
