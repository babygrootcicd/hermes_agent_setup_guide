# Multi-Platform Gateway & Automation (多平台無縫接入與自動化排程)

Hermes is designed to be a ubiquitous collaborative assistant — not confined to a single terminal window. It connects natively to major messaging platforms, executes tasks on remote infrastructure, and runs unattended automations on a schedule.

---

## Unified Messaging Gateway

Hermes supports native integration with the following platforms out of the box:

| Platform | Type | Notes |
|----------|------|-------|
| **Telegram** | Messaging | Most commonly used; mobile-friendly |
| **Discord** | Messaging | Good for team/server workflows |
| **Slack** | Messaging | Enterprise workspace integration |
| **WhatsApp** | Messaging | Personal messaging |
| **Signal** | Messaging | Privacy-focused |
| **Matrix** | Messaging | Open federated protocol |
| **Email** | Messaging | Inbox-triggered agent tasks |
| **Webhook** | HTTP | Inbound HTTP trigger from any service |
| **CLI** | Terminal | Local interactive session |

### Cross-Platform Use Case

A typical workflow enabled by the gateway:

```text
1. User sends command from mobile Telegram client
2. Hermes agent running on a cloud VM or local server receives it
3. Agent executes terminal commands, file edits, or web searches
4. Results are sent back to the Telegram chat
```

This enables:
- Commanding your home server from anywhere
- Triggering DevOps tasks from your phone
- Receiving monitoring alerts directly in your preferred chat app
- Seamless switching between devices without losing context

---

## Starting the Messaging Gateway

### Telegram

```bash
hermes gateway start telegram
```

Configuration in `~/.hermes/config.yaml`:

```yaml
telegram:
  bot_token: "${TELEGRAM_BOT_TOKEN}"
  allowed_users:
    - your_telegram_user_id
  toolsets:
    - terminal
    - web
    - skills
```

### Discord

```bash
hermes gateway start discord
```

```yaml
discord:
  bot_token: "${DISCORD_BOT_TOKEN}"
  allowed_channels:
    - "1234567890"
  toolsets:
    - terminal
    - skills
```

### Running as a Persistent Service

To keep the gateway alive after terminal close, use a process manager:

```bash
# tmux (simplest)
tmux new -s hermes-gateway
hermes gateway start telegram
# Ctrl+B then D to detach

# launchd (macOS, persistent across reboots)
hermes gateway install --platform telegram --service launchd

# systemd (Linux)
hermes gateway install --platform telegram --service systemd
```

---

## Built-in Cron Scheduler (自動化排程)

Hermes includes a native cron engine that supports both standard cron expressions and natural language task definitions.

### Creating a Scheduled Task

**Natural language:**

```bash
hermes cron create "every day at 8am" \
  --prompt "Search for AI agent news, summarize in Traditional Chinese, send to Telegram" \
  --deliver telegram
```

**Standard cron expression:**

```bash
hermes cron create "0 8 * * *" \
  --prompt "Daily briefing: AI / security / LLM releases" \
  --deliver telegram
```

**With project working directory:**

```bash
hermes cron create "0 2 * * *" \
  --workdir /home/me/projects/pandora-box-console \
  --prompt "Audit open PRs, summarize CI status, identify security-relevant changes, produce a DevSecOps digest." \
  --deliver telegram
```

When `--workdir` is specified:
- `AGENTS.md`, `CLAUDE.md`, `.cursorrules` in that directory are injected as project context
- Terminal and file tools operate relative to that working directory

### Task Delivery Targets

| Flag | Delivery destination |
|------|---------------------|
| `--deliver telegram` | Active Telegram bot channel |
| `--deliver discord` | Configured Discord channel |
| `--deliver slack` | Configured Slack workspace |
| `--deliver file:/path/to/output.md` | Local file |
| (none) | Stored in cron output log |

### Managing Cron Jobs

```bash
# List all scheduled jobs
hermes cron list

# View output of last run
hermes cron logs <job-id>

# Run a job immediately (without waiting for schedule)
hermes cron run <job-id>

# Pause a job
hermes cron pause <job-id>

# Delete a job
hermes cron delete <job-id>
```

### Cron Job Storage

All cron job definitions and their outputs are stored at:

```bash
~/.hermes/cron/
```

Cron state persists across terminal restarts and agent sessions.

---

## Example Automation Recipes

### Daily Briefing Bot

```bash
hermes cron create "0 8 * * *" \
  --prompt "
    Search for today's top news in:
    1. AI agent frameworks
    2. Open-source LLM releases
    3. Cloud security / zero trust
    4. UK scholarship deadlines
    Summarize in Traditional Chinese.
    Prioritize engineering impact over business news.
    Max 2 sentences per item. Include source links.
  " \
  --deliver telegram
```

### Nightly GitHub Triage

```bash
hermes cron create "0 22 * * *" \
  --workdir ~/projects/my-repo \
  --prompt "
    Review all open GitHub issues and PRs.
    Summarize CI status.
    Flag any security-relevant changes.
    Produce a concise DevSecOps digest.
  " \
  --deliver telegram
```

### Disk Usage Monitor

```bash
hermes cron create "0 9 * * *" \
  --prompt "
    Check disk usage on server.
    Alert if /var/opt/gitlab/backups or /var/lib/docker exceeds 85%.
    If exceeded, produce a cleanup plan.
  " \
  --deliver telegram
```

### Weekly CCSP Study Review

```bash
hermes cron create "0 20 * * 0" \
  --prompt "
    Summarize this week's CCSP wrong-answer patterns:
    1. Domain coverage gaps
    2. Repeated misconceptions
    3. Exam trap patterns
    4. Next week's drill list
    Format as Markdown with tables.
  " \
  --deliver file:~/study/weekly-review.md
```

---

## Session Routing

Every message received by any gateway (Telegram, Discord, Slack, webhook, CLI, email) is stored as a separate **session** in `~/.hermes/state.db`. Sessions are tagged by source platform and include full message history, tool calls, and timestamps.

This means you can:
- Search across Telegram and CLI sessions simultaneously with `session_search`
- Export only Telegram sessions: `hermes sessions export --source telegram`
- Resume a specific gateway session by ID

---

## References

- [Scheduled Tasks (Cron) — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron)
- [Tutorial: Daily Briefing Bot](https://hermes-agent.nousresearch.com/docs/guides/daily-briefing-bot)
- [Automation Templates](https://hermes-agent.nousresearch.com/docs/guides/automation-templates)
- [Sessions — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/sessions)
