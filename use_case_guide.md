# Hermes Agent Use Case Guide

This guide is for individual developers and small teams using Hermes Agent in this repository.
It is practical-first: each use case includes exactly what to prepare, what to ask, and how to know it worked.

## 繁體中文（簡介）

這份指南提供給在本 repo 使用 Hermes Agent 的**個人開發者**與**小型團隊**。
內容偏「實作導向」：每個 Use Case 都會清楚列出**要準備什麼**、**要怎麼問**、以及**如何驗證成功**。

## Quick Start (5 minutes)

1. Initialize Hermes + local model.

```bash
./scripts/macos/setup_hermes_ollama.sh
hermes model
```

2. Verify runtime health.

```bash
./scripts/common/verify.sh
```

3. Prepare a context bundle (recommended before most tasks).

```bash
./scripts/common/gather_context.sh README.md docs examples/skills > /tmp/hermes_context.txt
```

4. Start a focused session.

```bash
hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 12
```

5. Paste your task prompt + key context paths.

Minimal prompt skeleton:

```text
Goal: <one clear outcome>
Constraints: <what not to change>
Context files: <exact paths>
Definition of done: <testable checks>
```

Chinese hint: 任務越小、上下文越精準，回覆速度和品質通常越好。

### 繁體中文（5 分鐘快速開始）

1. 初始化 Hermes + 本地模型。

```bash
./scripts/macos/setup_hermes_ollama.sh
hermes model
```

2. 驗證執行環境是否健康。

```bash
./scripts/common/verify.sh
```

3. 先打包上下文（大多數任務都建議先做）。

```bash
./scripts/common/gather_context.sh README.md docs examples/skills > /tmp/hermes_context.txt
```

4. 開啟一個聚焦的對話 session。

```bash
hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 12
```

5. 貼上你的任務描述與關鍵檔案路徑。

最小提示詞骨架：

```text
目標（Goal）: <一個明確可交付的結果>
限制（Constraints）: <哪些不能改 / 不能做>
上下文檔案（Context files）: <精準的路徑清單>
完成定義（Definition of done）: <可測試/可驗收的檢查點>
```

---

## Use Case 1: Daily Coding Assistant (Individual Developer)

### When to use
- You need fast support for routine tasks: scaffolding files, refactoring a module, writing tests, or updating config.
- You want to reduce context-switching while staying in terminal-first workflow.

### Sample prompt
```text
Act as my pair programmer for this repo.
Task: add a new troubleshooting subsection for slow response in docs/dev_progress/60-troubleshooting.md.
Constraints: keep existing structure; do not edit unrelated files.
Context bundle: README.md, installation_start_guide.md, docs/dev_progress/60-troubleshooting.md.
Definition of done: new subsection includes symptoms, root causes, diagnostic commands, and rollback notes.
```

### Expected inputs / context bundle
- Current task target files.
- One style reference file (for tone/format consistency).
- Optional command outputs (`verify.sh`, logs).
- Optional team conventions (naming, commit style).

### Success criteria
- Only intended files changed.
- Output format matches surrounding docs/code style.
- Task-specific checks pass (lint/test/manual verification).
- The next step is obvious without additional clarification.

### Common pitfalls
- Prompt is too broad (“improve docs” with no scope).
- Missing constraints, leading to over-editing.
- No explicit definition of done.
- Context bundle includes too many irrelevant files, causing slower and noisier output.

### 繁體中文

#### 何時使用
- 你需要快速完成日常任務：建立檔案骨架、重構模組、補單元測試、更新設定等。
- 你想維持 terminal-first 工作流，降低來回切換成本。

#### 範例提示詞
```text
請在這個 repo 內扮演我的 pair programmer。
任務：在 docs/dev_progress/60-troubleshooting.md 新增一個「回應很慢」的疑難排解小節。
限制：保留既有章節結構；不要修改不相關檔案。
上下文：README.md、installation_start_guide.md、docs/dev_progress/60-troubleshooting.md。
完成定義：新增的小節需包含症狀、可能根因、診斷指令、以及回滾/復原注意事項。
```

#### 需要的輸入／上下文
- 本次要改的目標檔案。
- 1 份風格參考檔（統一語氣與格式）。
- 可選：指令輸出（`verify.sh`、logs）。
- 可選：團隊慣例（命名、commit style）。

#### 成功標準
- 只改到預期檔案。
- 輸出格式與周邊文件/程式風格一致。
- 任務相關檢查通過（lint/test/人工驗證）。
- 不需要再追問就能知道下一步怎麼做。

#### 常見踩雷
- 提示詞太大（例如「把文件變好」但沒有範圍）。
- 沒寫限制，導致亂改或過度重寫。
- 沒有完成定義，最後難以驗收。
- 上下文塞太多無關檔案，回覆更慢且更不精準。

---

## Use Case 2: Debugging Loops (Individual or Pair)

### When to use
- A command repeatedly fails, or startup is unstable/intermittent.
- You need a structured diagnosis loop instead of ad-hoc trial and error.

### Sample prompt
```text
Run a debugging loop for slow Hermes responses in my local setup.
Collect: environment info, model config, startup logs, toolset list, and one reproducible slow prompt.
Then produce: hypothesis list ranked by likelihood, test plan, and minimal fix order.
Constraints: no destructive commands; ask before any network-heavy action.
```

### Expected inputs / context bundle
- `installation_start_guide.md`
- `docs/dev_progress/60-troubleshooting.md`
- `scripts/common/verify.sh` output
- Relevant log snippets (`~/.hermes/logs/...`)
- Repro details: exact prompt, model, toolsets, and elapsed time

### Success criteria
- Repro case is captured with concrete steps.
- At least 2-3 root-cause hypotheses with verification method.
- A prioritized fix sequence is proposed and tested.
- You can confirm improvement via measurable delta (latency before/after).

### Common pitfalls
- Skipping baseline measurement (no before/after numbers).
- Mixing multiple changes at once, making attribution impossible.
- Ignoring model/toolset size impact on latency.
- Failing to persist findings into troubleshooting docs.

Chinese hint: 先固定「可重現案例」再優化，不然很難判斷是否真的變快。

### 繁體中文

#### 何時使用
- 指令反覆失敗、啟動不穩定或偶發性問題。
- 你需要一個「可重複」的診斷迴圈，而不是憑感覺試來試去。

#### 範例提示詞
```text
請針對我本機的 Hermes 回應偏慢問題，跑一個 debugging loop。
先收集：環境資訊、模型設定、啟動 logs、toolset 清單、以及一個可重現的慢提示詞。
再輸出：依可能性排序的假設清單、驗證測試計畫、最小修復順序。
限制：禁止破壞性指令；任何網路流量較大的動作先詢問我再做。
```

#### 需要的輸入／上下文
- `installation_start_guide.md`
- `docs/dev_progress/60-troubleshooting.md`
- `scripts/common/verify.sh` 的輸出
- 相關 log 片段（`~/.hermes/logs/...`）
- 可重現資訊：完整 prompt、模型、toolsets、耗時

#### 成功標準
- 明確記錄可重現流程（具體步驟）。
- 至少提出 2–3 個根因假設，且每個都有驗證方式。
- 有優先序的修復順序，並實際測過。
- 能用量化結果確認改善（延遲 before/after）。

#### 常見踩雷
- 沒先量 baseline（缺 before/after 數字）。
- 一次改太多，最後無法歸因是哪個改動有效。
- 忽略模型大小/toolset 對延遲的影響。
- 沒把結論寫回 troubleshooting 文件，下一次又重來。

---

## Use Case 3: Code Review Preparation (Small Team)

### When to use
- Before opening a PR, you want Hermes to produce a reviewer-ready package.
- Team wants consistent risk summaries and test evidence.

### Sample prompt
```text
Prepare this branch for PR review.
Output sections:
1) change summary by file,
2) behavior impact,
3) risk matrix,
4) test evidence,
5) reviewer checklist.
Focus on bugs, regressions, and missing tests first.
```

### Expected inputs / context bundle
- Changed files list and diffs (`git diff`, `git status`).
- Relevant requirements docs or issue statement.
- Test outputs (unit/integration/manual).
- Existing review template if team uses one.

### Success criteria
- Review brief is concise and actionable.
- High-risk changes are clearly called out.
- Test gaps are explicitly listed, not implied.
- Reviewer can understand intent without reading full commit history first.

### Common pitfalls
- Asking for only “summary” without risk analysis.
- No mapping from change -> behavior impact.
- Missing rollback notes for risky operational changes.
- Treating AI-generated review text as final without human verification.

### 繁體中文

#### 何時使用
- 開 PR 前，想讓 Hermes 先產出一份 reviewer 友善的說明包。
- 團隊希望每次 review 都有一致的風險摘要與測試證據。

#### 範例提示詞
```text
請協助我把這個分支整理成 PR review 用的素材。
輸出需要包含：
1) 逐檔案變更摘要
2) 行為影響（對使用者/系統）
3) 風險矩陣
4) 測試證據
5) Reviewer checklist
優先找出 bug/regression 風險與缺少的測試。
```

#### 需要的輸入／上下文
- 變更檔案清單與 diff（`git status`、`git diff`）。
- 需求文件或 issue 描述（若有）。
- 測試輸出（unit/integration/manual）。
- 團隊既有 review 模板（若有）。

#### 成功標準
- Review 簡報短而可行動。
- 高風險變更明確標示。
- 缺少的測試被「明講」列出，而不是含糊帶過。
- Reviewer 不用先看完整 commit history 也能理解意圖。

#### 常見踩雷
- 只要 summary，不做風險分析。
- 變更沒有對應到行為影響，review 變成猜謎。
- 風險操作缺乏回滾/復原說明。
- 把 AI 產出文字當成終稿，未經人工核對。

---

## Use Case 4: Documentation Generation and Maintenance

### When to use
- Features/scripts changed and docs are stale.
- You need onboarding docs, runbooks, or migration notes aligned with current repo state.

### Sample prompt
```text
Update documentation for the current setup flow.
Files in scope: README.md and installation_start_guide.md.
Goals: remove ambiguity, keep commands executable, add failure recovery notes.
Constraints: preserve bilingual style where already present.
```

### Expected inputs / context bundle
- Target doc files.
- Source-of-truth scripts (`scripts/...`).
- Example templates under `examples/`.
- Recent troubleshooting learnings.

### Success criteria
- Commands in docs are copy-paste runnable.
- Terminology and file paths are consistent.
- Known failure patterns have explicit fixes.
- New users can complete setup using docs only.

### Common pitfalls
- Writing conceptual text without executable commands.
- Drifting from actual script behavior.
- Duplicate guidance across files without cross-linking.
- Overusing bilingual content where it harms readability.

### 繁體中文

#### 何時使用
- 功能/腳本更新後，文件跟不上現況。
- 你需要 onboarding 文件、runbook、或 migration notes，且必須與 repo 現況一致。

#### 範例提示詞
```text
請更新目前的 setup 流程文件。
範圍：README.md 與 installation_start_guide.md。
目標：移除模糊敘述、確保指令可直接執行、補上失敗復原步驟。
限制：如果某些段落已採中英雙語，請維持該風格。
```

#### 需要的輸入／上下文
- 目標文件。
- 真實行為來源（`scripts/...`）。
- `examples/` 底下的範例模板。
- 最近的 troubleshooting 經驗/結論。

#### 成功標準
- 文件中的指令可以直接複製貼上執行。
- 名詞與路徑一致，不互相打架。
- 已知失敗情境有對應的修復步驟。
- 新手只看文件就能完成 setup。

#### 常見踩雷
- 只寫概念，沒有可執行指令。
- 文件描述偏離腳本實際行為。
- 多份文件重複但沒有互相連結，造成資訊分裂。
- 為了雙語而雙語，反而降低可讀性。

---

## Use Case 5: Local Model / Offline Workflow

### When to use
- You need privacy-first, low-dependency workflows.
- Network is limited or cloud API spend must be minimized.

### Sample prompt
```text
Design an offline-first Hermes workflow for this repo using Ollama.
Include: model selection, context-size policy, prompt-size limits, and fallback when quality drops.
Output a practical checklist for daily use.
```

### Expected inputs / context bundle
- Local provider config examples:
  - `examples/config/providers/ollama.yaml`
  - `installation_start_guide.md`
- Hardware constraints (RAM/CPU/GPU).
- Typical task types (coding/docs/review/ops).

### Success criteria
- Workflow runs with no cloud dependency in normal path.
- Latency and quality tradeoffs are documented.
- Team has clear escalation rule to cloud model when needed.
- Sensitive data remains local by default.

### Common pitfalls
- Using a model too large for local hardware.
- Sending oversized context every turn.
- No fallback path for hard reasoning tasks.
- Exposing local model endpoint beyond localhost without controls.

### 繁體中文

#### 何時使用
- 你需要隱私優先、低依賴的工作流。
- 網路受限，或雲端 API 成本必須控管。

#### 範例提示詞
```text
請用 Ollama 為本 repo 設計一個 offline-first 的 Hermes 工作流。
需包含：模型選擇、context 大小策略、prompt 長度限制、品質下降時的 fallback。
請輸出成一份「每日可照做」的檢查清單。
```

#### 需要的輸入／上下文
- 本地 provider 設定範例：
  - `examples/config/providers/ollama.yaml`
  - `installation_start_guide.md`
- 硬體限制（RAM/CPU/GPU）。
- 常見任務類型（coding/docs/review/ops）。

#### 成功標準
- 正常流程不依賴雲端。
- 清楚記錄延遲與品質取捨。
- 需要時有明確升級規則（何時改用雲端模型）。
- 預設敏感資料留在本機。

#### 常見踩雷
- 模型過大，導致本機跑不動/卡死。
- 每一輪都丟超大上下文，速度變慢且不穩定。
- 缺少「難題」的 fallback（品質掉時無路可走）。
- 在未設防的情況下把本地模型 endpoint 暴露到 localhost 之外。

---

## Use Case 6: Gateway Automation (Small Team Notifications and Ops)

### When to use
- Team needs Hermes in chat channels (Telegram/Discord/Slack/Email).
- You want scheduled summaries or alert-driven responses.

### Sample prompt
```text
Set up gateway automation plan for a 4-person dev team.
Channels: Slack for daily standup summary, Telegram for incident notifications.
Use existing examples in this repo.
Output: setup steps, required scopes/tokens, and runbook for token rotation.
```

### Expected inputs / context bundle
- `docs/dev_progress/40-gateway-setup.md`
- `examples/gateway/*.config.yaml`
- `examples/cron/*.yaml`
- Security baseline docs under `examples/security/`

### Success criteria
- Gateway boots reliably with documented startup command.
- Permissions follow least-privilege principle.
- Rotation/revocation process exists for all tokens.
- Message format is stable and useful to recipients.

### Common pitfalls
- Over-privileged bot scopes.
- Tokens committed or shared in plaintext.
- No health check/monitoring for gateway process.
- Automation spam due to missing guardrails or rate control.

Chinese hint: 先用測試群組驗證，再推到正式頻道。

### 繁體中文

#### 何時使用
- 團隊希望 Hermes 進入聊天通訊（Telegram/Discord/Slack/Email）。
- 你想做排程摘要或事件/告警驅動的自動回應。

#### 範例提示詞
```text
請為 4 人開發團隊規劃 gateway automation。
通路：Slack 用於每日 standup 摘要、Telegram 用於 incident 通知。
請優先沿用本 repo 既有範例。
輸出：安裝設定步驟、所需 scopes/tokens、以及 token 輪替（rotation）runbook。
```

#### 需要的輸入／上下文
- `docs/dev_progress/40-gateway-setup.md`
- `examples/gateway/*.config.yaml`
- `examples/cron/*.yaml`
- `examples/security/` 底下的安全基線文件

#### 成功標準
- Gateway 能穩定啟動，且文件有明確啟動指令。
- 權限遵守最小權限原則（least privilege）。
- 每種 token 都有輪替/撤銷流程。
- 訊息格式穩定且對接收者有用。

#### 常見踩雷
- Bot scopes 開太大。
- Token 被提交到 git 或用明碼分享。
- 缺少健康檢查/監控，壞了不知道。
- 沒有防呆（guardrails）或速率限制，造成自動化洗版。

---

## Use Case 7: Safe Operations (Guardrails, Security, Recovery)

### When to use
- You allow command/tool execution and need safety boundaries.
- Team requires repeatable incident response and rollback behavior.

### Sample prompt
```text
Create a safe-operations checklist for Hermes usage in this repository.
Include: credential handling, command allow/deny policy, backup/restore routine, and log sanitization before sharing.
Reference existing security examples.
```

### Expected inputs / context bundle
- `docs/dev_progress/70-security.md`
- `examples/security/threat-checklist.md`
- `scripts/common/backup.sh`
- `scripts/common/export-sessions.sh`
- `.gitignore` and config templates

### Success criteria
- Secrets are not stored in tracked files.
- Backup and restore procedure is tested.
- High-risk commands require explicit human confirmation.
- Shared logs are sanitized for sensitive data.

### Common pitfalls
- Assuming local execution is automatically safe.
- No separation between dev and production-like credentials.
- Skipping restore drills (backup exists but recovery untested).
- Over-trusting autonomous actions in high-impact operations.

### 繁體中文

#### 何時使用
- 你允許執行命令/工具，需要明確的安全邊界。
- 團隊需要可重複的 incident response 與回滾行為。

#### 範例提示詞
```text
請為本 repo 的 Hermes 使用方式建立一份 safe-operations checklist。
需包含：憑證處理、指令 allow/deny 政策、備份/還原流程、分享 logs 前的去敏（sanitization）。
請參考 repo 既有 security 範例。
```

#### 需要的輸入／上下文
- `docs/dev_progress/70-security.md`
- `examples/security/threat-checklist.md`
- `scripts/common/backup.sh`
- `scripts/common/export-sessions.sh`
- `.gitignore` 與設定檔模板

#### 成功標準
- Secrets 不會被存進 tracked files。
- 備份與還原流程有實際演練過。
- 高風險指令需要人工明確確認。
- 對外分享的 logs 已去除敏感資訊。

#### 常見踩雷
- 以為「在本機跑」就一定安全。
- dev 與 production 類憑證沒有隔離。
- 只有備份，沒有還原演練（等於沒備份）。
- 在高影響操作上過度信任自動化行為。

---

## Recommended Context Bundle Patterns

Use these lightweight bundles to keep Hermes fast and relevant:

- `Task-only`: target files + 1 reference style file.
- `Debug`: target files + repro logs + verify output.
- `Review`: changed files + diff summary + test results.
- `Ops`: gateway/security docs + active config snippets.

Command pattern:

```bash
./scripts/common/gather_context.sh <path1> <path2> <path3> > /tmp/context.txt
```

Then feed `/tmp/context.txt` into your Hermes prompt session.

### 繁體中文（建議的上下文打包模式）

用這些輕量組合，讓 Hermes 又快又準：

- `Task-only`：目標檔案 + 1 份風格參考檔
- `Debug`：目標檔案 + 可重現 logs + `verify` 輸出
- `Review`：變更檔案 + diff 摘要 + 測試結果
- `Ops`：gateway/security 文件 + 目前正在用的設定片段

指令範本：

```bash
./scripts/common/gather_context.sh <path1> <path2> <path3> > /tmp/context.txt
```

然後把 `/tmp/context.txt` 貼進 Hermes 對話 session 當作上下文。

---

## Team Operating Model (Small Team, Practical)

- One person owns prompt scope and done-criteria.
- One person validates output against real environment.
- One person updates persistent docs/runbooks.

This keeps AI output actionable and auditable, not just fast.

### 繁體中文（小團隊運作建議）

- 一人負責 prompt 範圍與完成定義（避免任務發散）。
- 一人負責在真實環境驗證輸出（避免紙上談兵）。
- 一人負責把可重用結論寫回文件/runbook（避免知識流失）。

這樣 AI 產出會更可落地、可稽核，而不只是「很快」。
