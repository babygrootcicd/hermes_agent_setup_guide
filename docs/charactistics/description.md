1. 閉環自學與技能進化 (Self-Evolution & Skill Creation)
這是 Hermes Agent 區別於其他開源 AI 框架（如 OpenClaw）的最大差異。

自動萃取技能：當系統成功執行一項複雜任務（例如：解決特定 Bug 或處理跨應用資料提取）後，它會自動將推理邏輯與解決方法封裝為可複用的「技能卡（Skill）」。系統「永遠不會忘記解決方法」，下次遇到類似任務時可直接調用。

自我進化機制：借助專屬的 hermes-agent-self-evolution 模組，系統會利用 DSPy 與 GEPA（Genetic-Pareto Prompt Evolution）算法，根據過去的執行軌跡，自動優化其擁有的技能、系統提示詞與代碼。這使 Agent 能在不依賴 GPU 重新訓練模型的狀況下，隨著使用次數增加而自動提升效能與準確率。

2. 跨會話持久記憶 (Persistent Memory)
Hermes Agent 捨棄了每次對話都需要重新交代背景脈絡的模式，建立了一套具備層次的持久化記憶系統：

核心記憶分離：系統會將資訊獨立儲存於兩個核心檔案中。MEMORY.md 負責記錄專案環境資訊、過往任務經驗與協議；USER.md 則專門記錄使用者的偏好設定、決策習慣與對話風格（例如使用者習慣的代碼格式或報告排版）。

降低運算成本：新任務進入時，系統會優先檢索現有的記憶與技能庫並套用最佳解法，大幅降低 API 的 Token 消耗與無效的運算時間。

3. 多平台無縫接入與自動化排程 (Multi-Platform Gateway & Automation)
Hermes Agent 旨在成為無所不在的協作助理，而非受限於單一視窗：

統一訊息閘道：原生支援串接 Telegram、Discord、Slack、WhatsApp、Signal 等平台以及 CLI 介面。使用者可以在手機的 Telegram 留言下達指令，讓位於雲端 VM 或本地伺服器上的 Agent 繼續執行終端機任務，實現跨平台無縫切換。

內建 Cron 自動化排程：支援透過自然語言設定定時任務。Agent 可以無人值守地在背景執行夜間系統備份、每週資料庫審計、每日早報生成等工作，並將結果主動推送到指定的通訊軟體頻道中。

4. 深度防禦的安全架構 (Defense-in-Depth Security Model)
由於此類 Agent 往往擁有操作系統或讀取本地檔案的權限，Hermes Agent 內建了七層安全防護機制：

危險指令攔截 (Dangerous Command Approval)：在執行任何具潛在破壞性的指令前，系統會比對危險特徵庫，並強制要求使用者顯式授權後才能放行。

容器化隔離 (Container Isolation)：支援在嚴格強化的 Docker 或 Modal 沙箱環境中執行工具與指令。系統會自動掛載唯讀權限的 Bind Mounts，以避免 Agent 失控破壞宿主機（Host）環境。

上下文檔案掃描 (Context File Scanning)：自動偵測並防禦提示詞注入攻擊（Prompt Injection），攔截隱藏的惡意指令，防堵 Agent 嘗試讀取環境變數（如 .env）或透過 curl 進行憑證外洩的行為。

5. 跨模型支援與資料隱私 (Model Agnosticism & Data Privacy)
不綁定單一供應商：Hermes Agent 支援透過 OpenRouter 切換超過 200 種大語言模型（包含 Claude、OpenAI、DeepSeek 等），也支援透過 Ollama 在本地端進行完全斷網的離線推理。

企業級資料安全：基於 MIT 授權完全開源，企業可直接透過 OAuth 授權連接 LLM API，無需將敏感資料繞經第三方的中介伺服器，確保企業內部數據的傳輸安全性。
---
## 0. 先講結論

Hermes Agent 的「跟使用者一起成長」不是指它會直接 fine-tune 自己的 base model，而是靠 **4 層持久化能力**：

1. **短而精的長期記憶**：`MEMORY.md` / `USER.md`
2. **完整會話歷史搜尋**：`~/.hermes/state.db` + FTS5
3. **可重用技能文件**：`~/.hermes/skills/`
4. **排程 / webhook / messaging gateway**：把學到的工作流變成固定自動化

官方描述 Hermes 是 Nous Research 開源的 self-improving agent，重點包含跨會話記憶、從經驗建立 skills、跨平台 gateway、排程任務與 subagent。它可在 Linux、macOS、WSL2、Android Termux 上跑；Windows 原生不支援，建議用 WSL2。([GitHub][1])

---

# 1. 「能跟我一起成長」到底是什麼意思？

## 1.1 不是單純 chatbot，而是「有狀態的 agent」

一般 chatbot 的問題是：

```text
每次對話 = 重新開始
專案背景 = 要重講
偏好格式 = 要重講
常用工具 = 要重講
踩過的坑 = 可能再踩一次
```

Hermes 的設計是把這些資訊拆成不同層級儲存：

| 成長層            | 儲存什麼                       | 作用                             |
| -------------- | -------------------------- | ------------------------------ |
| User Profile   | 使用者偏好、溝通風格、角色、技術程度         | 下次回覆更貼合習慣                      |
| Agent Memory   | 專案環境、工具 quirks、完成過的工作、修正事項 | 不用每次重交代環境                      |
| Session Search | 過去完整對話與工具呼叫                | 需要時回查「之前討論過什麼」                 |
| Skills         | 成功解決問題後沉澱成 SOP             | 類似 reusable runbook / playbook |

官方 memory 文件明確區分 `memory` 與 `user` 兩個 target：`memory` 存環境、工作流、專案慣例、工具 workaround、完成紀錄；`user` 存姓名、角色、時區、溝通偏好、工作習慣與技術程度。([Hermes Agent][2])

---

## 1.2 它怎麼「越用越懂使用者」

### A. 記住偏好

例如你長期偏好：

```text
- 回答要用繁體中文
- DevOps 題目希望給 docker compose / GitHub Actions / Terraform
- 安全題目希望用 threat model / control / detection / response 架構
- 不要廢話，要有 repo-style deliverables
```

這些會進 `USER.md`。

下次問：

```text
幫我設計一個 GitLab monitoring workflow
```

理想情況下，它會自動傾向產出：

```text
- docker-compose.yml
- Prometheus / Grafana / Loki
- Alertmanager
- runbook.md
- GitHub Actions / GitLab CI
- Discord webhook alert
```

而不是一般泛泛的說明。

---

### B. 記住專案與環境

例如：

```text
Project pandora-box-console 使用 Next.js + Go API + Prometheus + Loki
本機是 macOS + zsh + Docker Desktop
伺服器是 Ubuntu 24.04 + GitLab + MinIO + Grafana
不應該直接 sudo docker，因為 user 已在 docker group
```

這類資訊會進 `MEMORY.md`。官方建議保存的內容包含 user preferences、environment facts、corrections、project conventions、completed work 等；不建議保存 raw data dumps、暫時性路徑、過大的 log/code。([Hermes Agent][2])

---

### C. 記住「做法」而不是只記住「事實」

這是 Hermes 比一般 memory 更有價值的地方。

例如它幫你成功做過一次：

```text
用 Cursor + local LLM + MCP + GitHub Actions 做 CI auto-debug
```

之後可以沉澱成 skill：

```text
~/.hermes/skills/cursor-local-agentic-coding/SKILL.md
```

下次遇到類似任務，不必重新推理整套流程。Hermes 官方說明指出，當 Hermes 解決困難問題時，會寫入 reusable skill document；skills 可搜尋、分享，並相容 agentskills.io open standard。([Hermes Agent][3])

---

### D. 可搜尋過去所有會話

Hermes 不只靠短 memory。所有 CLI 與 messaging sessions 會存進 SQLite `~/.hermes/state.db`，並用 FTS5 做全文搜尋；`session_search` 可以找幾週前討論過的內容，即使該內容沒有進 active memory。([Hermes Agent][2])

這很適合：

```text
「上次我們 debug GitLab 502 的原因是什麼？」
「之前我那個 Glasgow scholarship essay 的主軸是什麼？」
「我之前 CCSP D6 常錯哪些題型？」
```

---

# 2. Persistent Memory 怎麼存在 local device？能不能匯出？

## 2.1 本地儲存位置

預設資料都在：

```bash
~/.hermes/
```

常見結構如下：

```text
~/.hermes/
├── config.yaml              # model、toolsets、terminal backend 等設定
├── .env                     # API keys / tokens
├── auth.json                # OAuth credentials
├── memories/
│   ├── MEMORY.md            # agent personal notes
│   └── USER.md              # user profile
├── skills/                  # bundled / installed / agent-created skills
├── state.db                 # SQLite session database
├── sessions/                # JSONL session transcripts
├── cron/                    # scheduled jobs and outputs
└── logs/                    # agent / gateway / error logs
```

官方 contributing 文件列出 `~/.hermes/config.yaml`、`.env`、`auth.json`、`skills/`、`memories/`、`state.db`、`sessions/`、`cron/` 等用途。([GitHub][4])

---

## 2.2 `MEMORY.md` / `USER.md` 是小型熱記憶

官方文件說明：

```text
~/.hermes/memories/MEMORY.md
~/.hermes/memories/USER.md
```

會在每次 session 開始時被讀入 system prompt，成為 frozen snapshot。也就是：同一個 session 中新增的 memory 會立刻寫入磁碟，但通常要到下一個 session 才會出現在 prompt 中。([Hermes Agent][2])

容量限制大約是：

| 檔案          | 用途                    | 官方限制          |
| ----------- | --------------------- | ------------- |
| `MEMORY.md` | agent 對環境、專案、工作流的個人筆記 | 約 2,200 chars |
| `USER.md`   | 使用者 profile、偏好、工作習慣   | 約 1,375 chars |

官方文件也說，memory 滿了之後需要 consolidate / replace / remove 舊項目。([Hermes Agent][2])

---

## 2.3 `state.db` 是完整 session 記憶

`state.db` 是 SQLite database，存：

```text
- sessions metadata
- full message history
- model config
- messages_fts FTS5 table
- token counts
- timestamps
- source platform
```

官方 session 文件指出，每個 CLI、Telegram、Discord、Slack、WhatsApp、Signal、Matrix、email、webhook、cron 等來源的對話都會被存成 session，並包含完整 message history。([Hermes Agent][5])

---

## 2.4 Skills 也是一種「程序記憶」

Skills 放在：

```bash
~/.hermes/skills/
```

官方 skills 文件說明，所有 skills 都以 `~/.hermes/skills/` 作為主要 source of truth；bundled、hub-installed、agent-created skills 都會在這裡。([Hermes Agent][6])

概念上：

```text
Memory = facts
Skills = procedures
Sessions = episodes / history
Cron = routines
```

官方 FAQ 也明確區分：memory 存 facts；skills 存 procedures，兩者都跨 session 持久化。([Hermes Agent][7])

---

## 2.5 能不能匯出？可以，而且有三種層級

### A. 匯出完整 Hermes 狀態

官方提供：

```bash
hermes backup
```

會建立 zip archive，包含 Hermes configuration、skills、sessions、data，但排除 hermes-agent codebase 本身。官方也提供 `--quick` 快照，並說備份使用 SQLite `backup()` API，因此 Hermes 正在運行時也能安全複製 WAL-mode SQLite。([Hermes Agent][8])

常用命令：

```bash
# 完整備份
hermes backup

# 指定輸出路徑
hermes backup -o ~/Desktop/hermes-backup.zip

# 快速備份：config.yaml, state.db, .env, auth, cron jobs
hermes backup --quick --label "pre-upgrade"
```

還原：

```bash
hermes import ~/Desktop/hermes-backup.zip
```

---

### B. 匯出 sessions 為 JSONL

官方支援：

```bash
hermes sessions export backup.jsonl
```

也可以依平台或單一 session 匯出：

```bash
# 匯出 Telegram session history
hermes sessions export telegram-history.jsonl --source telegram

# 匯出單一 session
hermes sessions export session.jsonl --session-id 20250305_091523_a1b2c3d4
```

官方說明 exported files 會是 JSONL，每行一個 JSON object，包含完整 session metadata 與所有 messages。([Hermes Agent][5])

---

### C. 只匯出記憶與 skills

如果只要「人可讀」的記憶與技能：

```bash
mkdir -p ~/hermes-export

cp ~/.hermes/memories/MEMORY.md ~/hermes-export/
cp ~/.hermes/memories/USER.md ~/hermes-export/
rsync -a ~/.hermes/skills/ ~/hermes-export/skills/

tar -czf ~/hermes-memory-skills-export.tar.gz -C ~/hermes-export .
```

若要避免外洩 secrets，匯出前不要包含：

```text
~/.hermes/.env
~/.hermes/auth.json
任何含 API key / bot token / SSH key 的 skill 或 session
```

---

## 2.6 Local-first 不等於完全不出網

這點要注意。

官方 FAQ 說 Hermes 不收集 telemetry / analytics，conversations、memory、skills 存在 `~/.hermes/`；但 API calls 會送到使用者設定的 LLM provider。也就是說，如果使用 OpenRouter、OpenAI、Anthropic、Nous Portal，prompt 內被注入的 memory 可能會送到該 provider。若要更接近完全本地，需要設定 Ollama、vLLM、llama.cpp server、SGLang、LocalAI 等 local/custom endpoint。([Hermes Agent][7])

對資安工程使用建議：

```text
高敏感專案：
- local model / internal LLM gateway
- Docker backend or SSH sandbox
- disable unnecessary tools
- .env / auth.json 不納入一般分享備份
- 定期 hermes sessions export + redaction
- 專案與個人 profile 分離
```

---

# 3. Everyday tasks 能做哪些？怎麼學習習慣？

## 3.1 任務類型總覽

Hermes 內建工具涵蓋 web search、browser automation、terminal、file editing、memory、delegation、messaging delivery、Home Assistant、MCP、RL 等；toolsets 可依平台啟用/停用。([Hermes Agent][9])

| Everyday task      | Hermes 能做什麼                                                     | 如何學習習慣                               |
| ------------------ | --------------------------------------------------------------- | ------------------------------------ |
| 每日 briefing        | 每天搜尋 AI / 資安 / crypto / scholarship news，送 Telegram/Discord     | 記住偏好來源、摘要長度、技術深度                     |
| 行事曆 / Gmail / Docs | 透過 Google Workspace skill 管理 Gmail、Calendar、Drive、Docs、Sheets   | 記住常用回覆格式、會議摘要格式                      |
| GitHub / coding    | issue triage、PR review、CI failure analysis、docs drift detection | 記住 repo 結構、branch convention、CI 常見錯誤 |
| DevOps monitoring  | uptime check、alert triage、deployment verification               | 記住服務名稱、runbook、告警分級                  |
| 研究整理               | arXiv paper digest、repo scout、競品追蹤                              | 記住研究主題、排除低價值新聞                       |
| 筆記管理               | Apple Notes、Obsidian 類 notes workflow                           | 記住 note template、tag convention      |
| 提醒 / routine       | cron reminders、weekly review、monthly audit                      | 記住固定週期與輸出渠道                          |
| 個人裝置 / 智慧家庭        | Home Assistant / FindMy / Apple Reminders 等                     | 記住常用設備與 automations                  |

Google Workspace skill 官方描述包含 Gmail、Calendar、Drive、Docs、Sheets；Apple Notes、Apple Reminders、FindMy、iMessage 也列在 built-in skills catalog。([Hermes Agent][10])

---

## 3.2 每日 briefing / research radar

典型指令：

```text
Every morning at 8am, search for:
1. AI agent frameworks
2. open-source LLM releases
3. cloud security / zero trust news
4. UK scholarship deadlines
Summarize in Traditional Chinese, prioritize engineering impact, and send to Telegram.
```

Hermes cron 官方支援自然語言或 cron expressions，可建立 one-shot / recurring tasks，並把結果送回原 chat、local files 或 configured platform targets。([Hermes Agent][11])

官方 daily briefing 教學流程是：8:00 AM 觸發 cron、啟動 fresh agent session、web search 拉最新資訊、摘要、送到 Telegram 或 Discord。([Hermes Agent][12])

它能學習的習慣包括：

```text
- 偏好繁中摘要
- 偏好 source links
- 不要 funding news，除非與 open source 有關
- 每篇摘要 2 句以內
- 優先看 GitHub / arXiv / vendor blog
```

---

## 3.3 Coding / GitHub / DevSecOps 任務

Hermes 對你的日常最有價值的部分大概是這塊。

### 可做任務

```text
- 每晚 issue triage
- PR 自動 review
- CI failure analysis
- dependency vulnerability scan
- docs drift detection
- repo activity scout
- release note summary
- security audit pipeline
```

官方 automation templates 包含 nightly backlog triage、自動 PR review、docs drift detection、dependency security audit、CI failure analysis、security audit pipeline 等範例。([Hermes Agent][13])

### 對你的實用例子

```bash
hermes cron create "0 2 * * *" \
  --workdir /home/me/projects/pandora-box-console \
  --prompt "Audit open PRs, summarize CI status, identify security-relevant changes, and produce a concise DevSecOps digest." \
  --deliver telegram
```

Cron job 可以指定 `--workdir`，讓 `AGENTS.md`、`CLAUDE.md`、`.cursorrules` 等專案上下文被注入，並讓 terminal/file/code tools 使用該工作目錄。([Hermes Agent][11])

它能學習：

```text
- 你的 repo 慣例
- commit message style
- PR review rubric
- 常見 CI failure pattern
- 常用修復順序
- 安全審查 checklist
```

---

## 3.4 DevOps / monitoring / on-call assistant

可做：

```text
- 每 30 分鐘檢查 API / web / docs endpoint
- Grafana / PagerDuty / Datadog webhook alert triage
- 部署後 smoke test
- 每週 dependency audit
- 每週 secret scanning / SQLi pattern / unsafe deserialization 掃描
```

官方 templates 有 alert triage、uptime monitor、deploy verification 等模式；alert triage 可以接收 monitoring alert，搜尋已知問題、比對近期部署或 config change，產出 root cause、first response steps、escalation recommendation。([Hermes Agent][13])

對你的 GitLab / MinIO / Prometheus / Grafana lab，可以變成：

```text
- 每天 09:00 摘要 GitLab disk usage
- 每 2 小時檢查 /var/opt/gitlab/backups, /var/log/journal, /var/lib/docker
- 超過 85% 時產生 cleanup plan
- 每週檢查 Loki / Prometheus retention 是否異常
```

---

## 3.5 Gmail / Calendar / Docs everyday assistant

Hermes 可以透過 Google Workspace skill 做：

```text
- Gmail digest
- Calendar briefing
- Meeting notes 整理
- Drive / Docs / Sheets 查找與摘要
- 回信草稿
- 每週工作摘要
```

官方 skill catalog 寫明 Google Workspace skill 涵蓋 Gmail、Calendar、Drive、Docs、Sheets。([Hermes Agent][10])

它能學習：

```text
- 常用回信語氣
- 會議摘要格式
- 哪些寄件人重要
- 哪些 project label 要優先
- 每週 summary 的欄位
```

但建議把 Gmail / Calendar 權限和 coding 權限分 profile，避免個人資料與工作 repo 混在一起。

---

## 3.6 筆記、研究、Obsidian / Apple Notes

可做：

```text
- 每天 arXiv paper digest
- YouTube transcript → summary
- research note template
- scholarship essay material collection
- CCSP / CPSA / CRT 錯題講義整理
```

官方 automation templates 有 paper digest with notes，示範每天搜尋 arXiv 並存到 note-taking system。([Hermes Agent][13])

對你的場景，可以設定：

```text
Every Sunday 20:00, summarize this week's CCSP wrong-answer patterns into:
1. domain coverage
2. repeated misconception
3. exam trap pattern
4. next week's drill list
Save as Markdown.
```

它能學習：

```text
- 你偏好專業講義
- 不要「你我他」這種代名詞
- 喜歡 domain / control / common trap 分類
- Markdown + table + checklist 格式
```

---

# 4. 建議你的 Hermes profile 設計

基於你的使用模式，建議至少拆 4 個 profiles：

```bash
hermes profile create personal
hermes profile create coder
hermes profile create security-lab
hermes profile create study
```

官方 profiles 功能是每個 profile 有自己的 `config.yaml`、`.env`、`SOUL.md`、memories、sessions、skills、cron jobs、state database；可用來分離 coding assistant、personal bot、research agent。([Hermes Agent][14])

建議配置：

| Profile        | 用途                                     | 允許工具                            |
| -------------- | -------------------------------------- | ------------------------------- |
| `personal`     | Gmail、Calendar、日常提醒                    | Google Workspace、cron、messaging |
| `coder`        | Cursor / GitHub / repo automation      | terminal、file、GitHub、MCP        |
| `security-lab` | GitLab / SIEM / monitoring / DevSecOps | SSH、terminal、webhook、cron       |
| `study`        | CCSP / CPSA / Glasgow / scholarship    | web、notes、PDF、Markdown          |

---

# 5. 安全建議：尤其適合你的資安背景

Hermes 的威力來自 filesystem、terminal、browser、messaging、cron；風險也在這裡。

官方 configuration 文件提醒：local backend 會以你的 user account 權限直接跑命令；若不想讓 agent 有同等 filesystem access，應停用不需要的 tools 或改用 Docker backend。([Hermes Agent][15])

建議 baseline：

```yaml
terminal:
  backend: docker
  timeout: 180

memory:
  memory_enabled: true
  user_profile_enabled: true
```

備份策略：

```bash
# 每週完整備份
hermes backup -o ~/secure-backups/hermes-$(date +%F).zip

# 匯出 session JSONL，便於審計 / grep / redaction
hermes sessions export ~/secure-backups/hermes-sessions-$(date +%F).jsonl

# 只匯出人可讀記憶
tar -czf ~/secure-backups/hermes-memory-skills-$(date +%F).tar.gz \
  ~/.hermes/memories \
  ~/.hermes/skills
```

不要把這些直接丟到公開 GitHub：

```text
~/.hermes/.env
~/.hermes/auth.json
~/.hermes/state.db
~/.hermes/sessions/
任何含 API key、bot token、客戶名稱、內網 IP、SSH path 的 memory/skill
```

---

# 6. 最精準的理解方式

Hermes Agent 比較像：

```text
local-first personal agent runtime
+ persistent memory
+ session database
+ procedural skills
+ cron scheduler
+ messaging gateway
+ tool execution layer
```

而不是單純：

```text
AI chatbot
```

對你的價值會集中在：

```text
1. DevSecOps routine automation
2. GitHub / CI / PR / issue workflow
3. CCSP / security study memory
4. scholarship / UK prep research tracker
5. local MCP / LLM gateway integration
6. personal briefing + reminder + notes system
```

真正要讓它「跟你一起成長」，關鍵不是一直聊天，而是固定讓它沉澱：

```text
- facts → MEMORY.md / USER.md
- procedures → SKILL.md
- history → state.db / sessions export
- routines → cron jobs
- integrations → MCP / Google Workspace / GitHub / messaging gateway
```

[1]: https://github.com/nousresearch/hermes-agent "GitHub - NousResearch/hermes-agent: The agent that grows with you · GitHub"
[2]: https://hermes-agent.nousresearch.com/docs/user-guide/features/memory "Persistent Memory | Hermes Agent"
[3]: https://hermes-agent.org/ "Hermes Agent — Open-Source AI Agent with Persistent Memory"
[4]: https://github.com/NousResearch/hermes-agent/blob/main/CONTRIBUTING.md "hermes-agent/CONTRIBUTING.md at main · NousResearch/hermes-agent · GitHub"
[5]: https://hermes-agent.nousresearch.com/docs/user-guide/sessions "Sessions | Hermes Agent"
[6]: https://hermes-agent.nousresearch.com/docs/user-guide/features/skills?utm_source=chatgpt.com "Skills System | Hermes Agent - nous research"
[7]: https://hermes-agent.nousresearch.com/docs/reference/faq "FAQ & Troubleshooting | Hermes Agent"
[8]: https://hermes-agent.nousresearch.com/docs/reference/cli-commands "CLI Commands Reference | Hermes Agent"
[9]: https://hermes-agent.nousresearch.com/docs/user-guide/features/tools "Tools & Toolsets | Hermes Agent"
[10]: https://hermes-agent.nousresearch.com/docs/skills "Skills Hub | Hermes Agent"
[11]: https://hermes-agent.nousresearch.com/docs/user-guide/features/cron "Scheduled Tasks (Cron) | Hermes Agent"
[12]: https://hermes-agent.nousresearch.com/docs/guides/daily-briefing-bot "Tutorial: Daily Briefing Bot | Hermes Agent"
[13]: https://hermes-agent.nousresearch.com/docs/guides/automation-templates "Automation Templates | Hermes Agent"
[14]: https://hermes-agent.nousresearch.com/docs/user-guide/profiles "Profiles: Running Multiple Agents | Hermes Agent"
[15]: https://hermes-agent.nousresearch.com/docs/user-guide/configuration?utm_source=chatgpt.com "Configuration | Hermes Agent - nous research"
---
## 先判斷：你現在慢的主因

從截圖看，你現在用的是：

```bash
python3 ~/.local/bin/hermes chat --model hermes3
```

Hermes 畫面自己也警告：**Nous Hermes 3 / 4 models are NOT agentic and are not designed for Hermes Agent**。所以現在的問題不只是「慢」，而是：

1. **`hermes3` 不是適合 agent loop / tool calling 的模型**
2. **上下文顯示 131.1K，對 local model 會非常吃 prefill / KV cache**
3. **啟動時載入 29 tools + 74 skills，tool schema 會把 prompt 撐大**
4. **browser automation / cron / discord / code execution 等 toolset 全開時，首 token 很慢是正常現象**
5. 如果是 Intel Mac 或低 VRAM 環境，local 32B / 長 context 幾乎不適合當即時 agent backend

Hermes 官方也提到，local agent 場景至少需要 16K–32K context；如果 context 太小會忘記或失常，但 context 設太大又會顯著拖慢本地推理。Ollama 預設 context 也可能很低，需要 server-side 設定，而不是只在 API 端改。([Hermes Agent][1])

---

# 1. 你的 constraint 下，最實際的 provider 排序

你的限制是：

```text
不要另外付 token
可以用：
- 免費 local model
- 免費 cloud quota
- 已付費 ChatGPT / Gemini / Claude 訂閱
```

我會這樣排：

| 優先級 |                                             方案 | 是否符合「不另付 token」 |  速度 | 風險 / 限制                                        |
| --- | ---------------------------------------------: | --------------: | --: | ---------------------------------------------- |
| 1   | **Google Gemini OAuth / Gemini API free tier** |               高 |   快 | OAuth 方式有 policy risk；API key free tier 比較乾淨   |
| 2   |        **GitHub Copilot provider**，若已有 Copilot |               高 |   快 | 需要 Copilot subscription                        |
| 3   | **OpenAI Codex provider**，若 ChatGPT/Codex 帳號可用 |               中 |   快 | 不是通用 ChatGPT API；可用性看帳號                        |
| 4   |               **Local Ollama / LM Studio 小模型** |               高 | 中到慢 | 免費但吃硬體；需選工具能力好的模型                              |
| 5   |             **Claude subscription 直接接 Hermes** |               低 |   快 | 通常不符合你的限制；Hermes 端需要 Max extra usage 或 API key |

---

# 2. 不建議繼續用 `--model hermes3`

你應該先退出目前 session：

```bash
/quit
```

然後跑正式 provider setup：

```bash
hermes model
```

注意：`hermes model` 要在 shell 裡跑，不是在 Hermes chat 裡跑。官方文件也區分：`hermes model` 是完整 provider setup wizard，可以新增 provider、跑 OAuth、輸入 API key、設定 custom endpoint；`/model` 只能在現有 session 裡切換已設定好的 provider/model。([GitHub][2])

---

# 3. 最推薦：Gemini 作為主要 agent backend

## 3.1 低成本 / 免費路線

Hermes 支援兩種 Gemini 路線：

```text
A. google-gemini-cli provider：OAuth / Code Assist backend
B. gemini provider：GOOGLE_API_KEY / GEMINI_API_KEY
```

Hermes 官方文件說 `google-gemini-cli` provider 使用 Google Cloud Code Assist backend，支援 personal account free tier；登入後 Hermes 可自動 provision free tier。([Hermes Agent][1])

但官方也明確警告：Google 可能把用 Gemini CLI OAuth client 於第三方軟體視為 policy violation；低風險做法是用自己的 API key via `gemini` provider。([Hermes Agent][1])

所以建議：

```text
短期測試：Gemini OAuth
長期穩定：Google AI Studio API key + free tier
```

Gemini API pricing 頁面也列出多個模型有 Free Tier。([Google AI for Developers][3])

### 建議操作

```bash
hermes model
# 選 Google Gemini OAuth 或 Gemini API key provider
# 優先選 flash / fast 類模型
```

啟動時先不要全開工具：

```bash
hermes chat \
  --provider google-gemini-cli \
  --model gemini-2.5-flash \
  --toolsets web,terminal,skills \
  --max-turns 20
```

如果只要日常 assistant，不要 browser automation：

```bash
hermes chat \
  --provider google-gemini-cli \
  --model gemini-2.5-flash \
  --toolsets terminal,skills \
  --max-turns 12
```

---

# 4. 如果你有 GitHub Copilot：這可能是最穩的「已付費訂閱」解法

Hermes 官方文件寫得很清楚：`copilot` provider 會使用 GitHub Copilot subscription，並可透過 Copilot API 存取 GPT、Claude、Gemini 等模型；如果沒有 token，`hermes model` 會提供 OAuth device code login。([Hermes Agent][1])

### 操作

```bash
hermes model
# 選 GitHub Copilot
# Login with GitHub / OAuth device code
```

然後：

```bash
hermes chat \
  --provider copilot \
  --model gpt-5.4 \
  --toolsets web,terminal,skills \
  --max-turns 20
```

這比 local model 更適合 agentic workflow，因為：

```text
- latency 通常低很多
- tool calling 穩定
- 不吃本機 VRAM / CPU
- 可用已付 Copilot 額度
```

---

# 5. ChatGPT Plus / Pro：不能直接當 OpenAI API 用

這點要分清楚。

OpenAI 官方說 API billing 與 ChatGPT subscription 是分開管理；API usage 依 token 計費，不包含在 ChatGPT 訂閱內。([OpenAI Help Center][4])

所以：

```text
ChatGPT Plus / Pro ≠ 免費 OpenAI API key
```

但 Hermes 目前文件有一條 **OpenAI Codex provider**，透過 device code OAuth 驗證，並可 import `~/.codex/auth.json`，不需要安裝 Codex CLI。([Hermes Agent][1])

### 實務建議

可以試：

```bash
hermes model
# 選 OpenAI Codex
```

但要把它視為：

```text
Codex / ChatGPT OAuth-backed provider
不是通用 OpenAI API 替代品
```

也不要用 browser automation 去「操控 ChatGPT 網頁」當 backend。這種做法通常慢、脆弱、無法穩定做 tool calling，而且容易碰到平台政策問題。

---

# 6. Claude：目前不符合你的 constraint

Hermes 官方文件寫明：Anthropic OAuth 路線需要 **Claude Max + extra usage credits**；Hermes 不會消耗 Claude Code base Max allowance，而是消耗額外加購的 overage credits。Claude Pro 不能用這條路。沒有 Max + extra credits 時，就要用 `ANTHROPIC_API_KEY`，也就是標準 API token 計費。([Hermes Agent][1])

所以對你的限制：

```text
已付 Claude Pro / Max 基本訂閱
→ 不等於 Hermes 可免費直接使用 Claude backend
```

比較合理的 Claude 用法是：

```text
- Claude Code 官方 CLI：做 coding
- Hermes：用 Gemini / Copilot / local model 做 everyday assistant
```

---

# 7. Local model：可用，但要降規格

你現在 `131.1K context` 對 local agent 來說太重。先改成 32K，比較合理。

## 7.1 Ollama 建議

```bash
ollama pull qwen2.5-coder:7b
OLLAMA_CONTEXT_LENGTH=32768 ollama serve
```

然後：

```bash
hermes model
# Custom endpoint
# URL: http://localhost:11434/v1
# API key: ollama 或留空
# model: qwen2.5-coder:7b
# context length: 32768
```

手動 config：

```yaml
model:
  provider: custom
  default: qwen2.5-coder:7b
  base_url: http://localhost:11434/v1
  api_key: ollama
  context_length: 32768

agent:
  max_turns: 20
```

Hermes 官方也說 local/self-hosted endpoint 只要支援 OpenAI-compatible `/v1/chat/completions` 就能接；Ollama 走 custom endpoint，URL 是 `http://localhost:11434/v1`。 ([Hermes Agent][1])

## 7.2 不要一開始就用大模型

建議順序：

```text
7B coder model → 測 tool calling
14B coder model → 若速度可接受再升級
32B+ → 只適合 Apple Silicon 高 RAM / GPU server
70B+ → 不適合一般 Mac local realtime agent
```

---

# 8. 速度優化設定

## 8.1 減少工具載入

先不要全開 browser / discord / cron / code_execution。日常問答與 repo task 先用：

```bash
hermes chat \
  --toolsets terminal,skills \
  --max-turns 12
```

需要查網頁時才加 web/browser：

```bash
hermes chat \
  --toolsets web,terminal,skills \
  --max-turns 20
```

## 8.2 降低 context

```yaml
model:
  context_length: 32768
```

不要一開始用：

```yaml
context_length: 131072
```

除非是 cloud model 或高階 GPU server。

## 8.3 限制 delegation

如果有 subagent delegation，先關小：

```yaml
delegation:
  max_concurrent_children: 1
  max_spawn_depth: 1
```

Hermes 文件也提醒 delegation 成本會乘法擴張，例如深度 3、每層 3 個 children 會變成 27 個 concurrent leaf agents。([Hermes Agent][5])

---

# 9. 我建議你的最終架構

## 日常 everyday assistant

```text
Primary:
  Gemini Flash / Gemini OAuth or API free tier

Fallback:
  Local Ollama qwen coder 7B / 14B

Tools:
  terminal, skills, web
  browser automation only on demand
```

## Coding / DevSecOps

```text
如果已有 GitHub Copilot:
  Hermes Copilot provider

如果有 ChatGPT/Codex access:
  Hermes OpenAI Codex provider

Local backup:
  qwen coder local model
```

## Claude

```text
不要把 Claude subscription 當 Hermes backend 主線。
Claude Code 獨立用於 coding；Hermes 不要硬接 Claude，除非接受 extra usage / API billing。
```

---

# 10. 你現在可以直接照做的最短路徑

```bash
# 1. 停掉現在 hermes3 session
/quit

# 2. 設定 provider
hermes model

# 3A. 優先選 Google Gemini OAuth
# 或 3B. 如果你有 Copilot，選 GitHub Copilot
# 或 3C. 如果你要本地，選 Custom endpoint -> Ollama

# 4. 用小 toolset 起跑
hermes chat \
  --toolsets terminal,skills \
  --max-turns 12
```

如果要我給一個最符合你限制的結論：

```text
首選：Gemini free/OAuth or Gemini API free tier
次選：GitHub Copilot provider，如果已有 Copilot
第三：OpenAI Codex provider，如果你的 ChatGPT/Codex 帳號支援
本地備援：Ollama + qwen coder 7B/14B + 32K context
不建議：Hermes + Claude subscription，除非接受 extra usage/API billing
```

[1]: https://hermes-agent.nousresearch.com/docs/integrations/providers "AI Providers | Hermes Agent"
[2]: https://github.com/nousresearch/hermes-agent/blob/main/website/docs/reference/cli-commands.md "hermes-agent/website/docs/reference/cli-commands.md at main · NousResearch/hermes-agent · GitHub"
[3]: https://ai.google.dev/gemini-api/docs/pricing?utm_source=chatgpt.com "Gemini Developer API pricing"
[4]: https://help.openai.com/en/articles/8156019-how-can-i-move-my-chatgpt-subscription-to-the-api "How can I move my ChatGPT subscription to the API? | OpenAI Help Center"
[5]: https://hermes-agent.nousresearch.com/docs/user-guide/configuration "Configuration | Hermes Agent"
---
關掉 Terminal 後，Hermes 不會自動重啟。
你現在是用前景 CLI process 跑：

python3 ~/.local/bin/hermes chat --model hermes3

Terminal 關掉後，這個 process 通常會一起結束；除非你是用 tmux、screen、nohup、launchd、systemd、cron gateway、messaging gateway 之類方式讓它常駐。

1. 關掉 Terminal 後會不會帶記憶？

會，但要分清楚 memory 跟 session。

A. Persistent Memory 會保留

Hermes 的 persistent memory 主要存在本機：

~/.hermes/memories/MEMORY.md
~/.hermes/memories/USER.md

這些會在新 session 開始時注入 system prompt；官方文件也說 memory 是 session start 時的 frozen snapshot，session 中途新增的 memory 會寫入磁碟，但通常要下一個 session 才會進 prompt。

所以：

關掉 Terminal → 再開新的 hermes chat

仍會帶：

- 你的偏好
- 專案背景
- agent 學到的長期資訊
- USER.md / MEMORY.md 裡的內容
B. 但「完整對話上下文」不會自動接上，除非 resume

如果你直接重新跑：

hermes chat

這通常是新 session。它會帶 persistent memory，但不會自動把剛剛整段對話完整塞回上下文。

要接續剛剛的對話，要用：

hermes chat --continue

或短版：

hermes chat -c

官方文件寫明，--continue / -c 會從 SQLite database 載入最近的 CLI session，恢復完整 conversation history。

也可以指定某個 session：

hermes chat --resume 20260426_103523_086f4d

或：

hermes chat -r 20260426_103523_086f4d
2. Session 存在哪裡？

CLI sessions 會存在：

~/.hermes/state.db

這是 SQLite database，保存：

- session metadata
- message history
- token counters
- lineage
- full-text search index

官方 CLI 文件也說，Hermes CLI resume 是從 ~/.hermes/state.db 還原完整 conversation history。

3. 最安全的關閉方式

不要直接按 Terminal 關閉。建議在 Hermes 裡輸入：

/quit

或用：

Ctrl+C

官方 CLI command 文件也建議如果要離開 Hermes session 再跑 hermes model，可以用 Ctrl+C 或 /quit。

正常退出時，它通常會印出 resume command，例如：

Resume this session with:
  hermes --resume 20260426_103523_086f4d

你的畫面左側已經有 session id：

Session: 20260426_103523_086f4d

所以之後可以試：

hermes chat --resume 20260426_103523_086f4d
4. 關掉 Terminal 時，哪一些東西可能不會保存？
類型	是否保留	說明
MEMORY.md / USER.md	會	已寫入磁碟的 long-term memory 會保留
已完成的 session messages	通常會	存在 ~/.hermes/state.db
正在生成中的回覆	不保證	Terminal 被關掉時，當下 response 可能中斷
正在跑的 tool / browser / terminal task	不保證	process 可能被殺掉
cron job 設定	會	存在 Hermes config / cron state
background gateway	看啟動方式	若沒有 daemon/service，就不會自動活著
5. 如果你希望它關掉 Terminal 也繼續跑

用 tmux 最簡單：

tmux new -s hermes
hermes chat --provider google-gemini-cli --model gemini-2.5-flash

離開但不中斷：

Ctrl+B
D

回來：

tmux attach -t hermes

如果只是要避免 session 消失，則不需要 tmux；用 resume 就好：

hermes chat -c

如果是要讓 agent 長期接 webhook、Telegram、Discord、cron，那就應該改成 service / daemon / tmux / launchd，而不是普通 Terminal 前景執行。

建議你的用法

目前先養成這個流程：

# 正常離開
/quit

# 下次接續
hermes chat -c

如果你要保留現在這個 session：

hermes chat --resume 20260426_103523_086f4d

簡化理解：

重新開 hermes chat
= 有長期記憶，但不是同一段對話

hermes chat -c / --resume
= 有長期記憶 + 接回完整 session