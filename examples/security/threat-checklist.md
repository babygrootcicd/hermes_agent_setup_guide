# Hermes Agent — Pre-Deployment Security Checklist

Run through this checklist before exposing Hermes to production data, messaging gateways, or automated cron jobs. Each item links to the relevant config or documentation.

---

## Credentials & Secrets

- [ ] **`.env` is not committed to git**
  Verify: `git ls-files ~/.hermes/.env` returns nothing.
  Add to `.gitignore`: `echo '.env' >> ~/.hermes/.gitignore`

- [ ] **`auth.json` is not committed to git**
  Verify: `git ls-files ~/.hermes/auth.json` returns nothing.

- [ ] **`.env` and `auth.json` are excluded from shared backups**
  Use `hermes backup --quick` (excludes credentials) or manually exclude them from tar archives.
  Never send these files to cloud storage without encryption.

- [ ] **API keys in `.env` use the principle of least privilege**
  GitHub token: read-only scopes unless write is required.
  Google API key: restricted to specific APIs (not "All Google APIs").
  Telegram bot token: only granted to bots you control.

- [ ] **Credentials are not embedded in `MEMORY.md`, `USER.md`, or any `SKILL.md`**
  Search: `grep -r "api[_-]key\|token\|password\|secret" ~/.hermes/memories ~/.hermes/skills`
  If found, remove and rotate the exposed credential.

---

## Access Control

- [ ] **`allowed_users` is set on every messaging gateway**
  Telegram, Discord, Slack: verify only your user IDs are whitelisted.
  An open gateway accepts commands from anyone who finds the bot.
  ```yaml
  telegram:
    allowed_users:
      - 123456789   # your Telegram user ID
  ```

- [ ] **Gateway bots are not added to public channels or servers**
  Discord bots added to public servers can be messaged by any member.
  Keep bots in private servers or DMs only.

- [ ] **Webhook endpoints require a shared secret**
  If using `hermes gateway start webhook`, configure a `webhook_secret` so only
  trusted callers can trigger agent tasks.

---

## Tool & Permission Scope

- [ ] **Only necessary toolsets are enabled per profile**
  Disable unused toolsets in each profile's `config.yaml`:
  ```yaml
  toolsets:
    enabled: [terminal, skills, web]
    disabled: [browser_automation, code_execution, home_assistant, messaging_send]
  ```
  See `examples/config/profiles/` for per-profile examples.

- [ ] **`terminal.backend: docker` is configured for any profile that runs shell commands**
  Local backend executes with your user account's full permissions.
  Docker backend isolates execution. See `examples/security/docker-sandbox.yaml`.

- [ ] **`dangerous_command_approval: true` is set**
  Verify in your active profile's `config.yaml` or in `security-baseline.yaml`.

- [ ] **`max_turns` is set to a reasonable limit**
  Prevents runaway agent loops from burning tokens or taking unintended actions:
  ```yaml
  agent:
    max_turns: 20
  ```

- [ ] **`delegation.max_spawn_depth` is constrained**
  Depth 3 × 3 children = 27 concurrent agents. Start at depth 1:
  ```yaml
  delegation:
    max_concurrent_children: 2
    max_spawn_depth: 1
  ```

---

## Memory & Data Privacy

- [ ] **`MEMORY.md` and `USER.md` reviewed before first cloud provider session**
  These files are injected into every system prompt and sent to your LLM provider.
  Check for: internal IPs, hostnames, customer names, PII, file paths to sensitive data.

- [ ] **Sensitive projects use a local model (Ollama) as the backend**
  If project context contains confidential information, use `provider: custom` + Ollama.
  No data leaves the machine during inference.

- [ ] **Separate profiles for personal and professional contexts**
  Run `hermes profile list` and verify that personal email, coding, and security-lab
  contexts are in separate profiles with separate `state.db` databases.

---

## Session Audit

- [ ] **Periodic session export and review is scheduled**
  ```bash
  hermes cron create "0 3 * * 0" \
    --prompt "Export this week's sessions to ~/secure-backups/ and summarize any anomalous tool calls." \
    --deliver telegram
  ```
  Or manually: `hermes sessions export ~/secure-backups/sessions-$(date +%F).jsonl`

- [ ] **Session JSONL files are redacted before long-term archival**
  Strip messages containing API keys, tokens, internal IPs, or PII before archiving off-machine.

- [ ] **`audit_logging: true` is enabled**
  Verifiable in `security-baseline.yaml`. Logs all tool inputs/outputs to `~/.hermes/logs/agent.log`.

---

## Skill Review

- [ ] **Agent-created skills reviewed before sharing or backing up**
  Agent-created skills are auto-written from tool call traces and may capture:
  - API keys passed as CLI arguments
  - Internal hostnames
  - Credentials from environment inspection
  Search: `grep -r "key\|token\|password" ~/.hermes/skills/`

- [ ] **Skills from the Hub reviewed before installation**
  Hub skills run with the same permissions as any other skill.
  Review the `SKILL.md` and any referenced scripts before installing.

---

## Backup & Recovery

- [ ] **Weekly backup is scheduled and tested**
  Schedule: `hermes cron create "0 1 * * 0" --prompt "Run hermes backup and verify the archive." --deliver telegram`
  Test restore: `hermes import ~/backups/hermes-test.zip` to a separate `--profile test`

- [ ] **Backup archive is stored encrypted**
  Hermes backup zip is not encrypted. Use:
  ```bash
  openssl enc -aes-256-cbc -pbkdf2 -in hermes-backup.zip -out hermes-backup.zip.enc
  ```
  Or store on an encrypted volume (FileVault / LUKS).

- [ ] **Restore procedure is documented and tested**
  A backup that has never been restored is not a backup.

---

## Model & Provider

- [ ] **Cloud provider's Data Processing Agreement (DPA) reviewed**
  If using OpenAI, Anthropic, or Google: confirm their DPA covers your data classification.
  Enterprise users: prefer Azure OpenAI, Vertex AI, or Amazon Bedrock with BAA/DPA in place.

- [ ] **Local model used for any data classified as confidential or above**
  Configure Ollama: see `examples/config/providers/ollama.config.yaml`.

- [ ] **`context_length` is set appropriately for the model**
  Oversize context on local models causes severe latency. Use 32K for local inference.

---

## Network

- [ ] **Docker sandbox network policy is set to `restricted` or `none`**
  Verify `terminal.network: restricted` and `allowed_hosts` list in `docker-sandbox.yaml`.

- [ ] **Private IP ranges are blocked in the sandbox**
  `block_private_ranges: true` in `security-baseline.yaml` prevents SSRF to 10.x, 172.16.x, 192.168.x.

- [ ] **No gateway is listening on `0.0.0.0` without authentication**
  The webhook gateway should bind to `127.0.0.1` unless intentionally external.

---

## Final Sign-Off

| Check | Owner | Date | Status |
|-------|-------|------|--------|
| Credentials review | | | |
| Access control | | | |
| Tool scope | | | |
| Memory review | | | |
| Session audit setup | | | |
| Backup tested | | | |
| Provider DPA | | | |
| Network policy | | | |

All items checked? Hermes is ready for production use.
