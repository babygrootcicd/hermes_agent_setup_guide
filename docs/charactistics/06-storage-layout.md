# Local Storage Layout & Data Export

All Hermes data lives under `~/.hermes/` by default. This document describes every component of that directory, what it contains, how it behaves, and how to export or back it up safely.

---

## Full Directory Structure

```text
~/.hermes/
├── config.yaml              # Model, toolsets, terminal backend, gateway settings
├── .env                     # API keys and bot tokens (never injected into prompts)
├── auth.json                # OAuth credentials (never injected into prompts)
├── memories/
│   ├── MEMORY.md            # Agent personal notes (~2,200 char hot memory)
│   └── USER.md              # User profile and preferences (~1,375 char hot memory)
├── skills/                  # All skills: bundled, hub-installed, agent-created
│   └── <skill-name>/
│       └── SKILL.md
├── state.db                 # SQLite database: all sessions, FTS5 search index
├── sessions/                # JSONL session transcripts (one file per session)
│   └── <session-id>.jsonl
├── cron/                    # Cron job definitions and output logs
│   ├── jobs.yaml
│   └── outputs/
├── logs/                    # Agent, gateway, and error logs
│   ├── agent.log
│   ├── gateway.log
│   ├── error.log
│   └── cron.log
└── profiles/                # Per-profile data directories (if using profiles)
    └── <profile-name>/
        ├── config.yaml
        ├── .env
        ├── memories/
        ├── skills/
        ├── state.db
        └── sessions/
```

---

## Component Reference

### `config.yaml`

The primary configuration file. Controls:
- Model provider, model name, context length
- Toolsets enabled/disabled
- Terminal backend (local, Docker, Modal)
- Gateway configurations (Telegram, Discord, Slack)
- Memory settings
- Agent behavior (max_turns, delegation limits)
- Delegation settings

Example:

```yaml
model:
  provider: google-gemini-cli
  default: gemini-2.5-flash
  context_length: 32768

terminal:
  backend: docker
  timeout: 180

memory:
  memory_enabled: true
  user_profile_enabled: true

agent:
  max_turns: 20

toolsets:
  enabled:
    - terminal
    - web
    - skills

delegation:
  max_concurrent_children: 2
  max_spawn_depth: 2
```

---

### `.env`

Stores all sensitive credentials:

```bash
GOOGLE_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
TELEGRAM_BOT_TOKEN=your_token_here
DISCORD_BOT_TOKEN=your_token_here
GITHUB_TOKEN=your_token_here
```

**Security:** Never injected into prompts. Never included in default backup exports. Do not commit to version control.

---

### `auth.json`

OAuth credential store. Written automatically after OAuth device code flows (Gemini CLI, GitHub Copilot, OpenAI Codex). Structure is provider-specific.

**Security:** Same rules as `.env`. Keep private, do not share.

---

### `memories/MEMORY.md`

Hot memory: agent personal notes. Injected as part of the system prompt at every session start. Changes made during a session are written to disk immediately but take effect in the next session.

**Capacity:** ~2,200 characters  
**Format:** Plain Markdown  
**Editable:** Yes — you can edit this file directly in any text editor

---

### `memories/USER.md`

Hot memory: user profile and preferences. Same loading behavior as `MEMORY.md`.

**Capacity:** ~1,375 characters  
**Format:** Plain Markdown  
**Editable:** Yes — directly editable

---

### `skills/`

All skill documents, organized by skill name. Each skill directory contains at minimum a `SKILL.md` file. May also contain supporting files (templates, scripts, config examples).

```text
~/.hermes/skills/
├── daily-briefing-bot/
│   └── SKILL.md
├── github-pr-review/
│   └── SKILL.md
├── cursor-local-agentic-coding/
│   ├── SKILL.md
│   └── example-config.yaml
└── ccsp-study-review/
    └── SKILL.md
```

Skills are compatible with the [agentskills.io](https://agentskills.io) open standard and can be shared.

---

### `state.db`

SQLite database. The authoritative store for all session history.

**Schema includes:**

| Table | Contents |
|-------|---------|
| `sessions` | Session metadata: ID, source platform, timestamps, model config, token counts |
| `messages` | Full message history per session (role, content, tool calls, tool results) |
| `messages_fts` | FTS5 full-text search index over all message content |
| `session_lineage` | Parent-child relationships for delegated/subagent sessions |

**FTS5 search enables:**

```bash
hermes session search "GitLab 502 root cause"
hermes session search "Glasgow scholarship thesis"
```

Hermes uses WAL (Write-Ahead Logging) mode, meaning `state.db` can be safely read while Hermes is running without corruption risk.

---

### `sessions/`

JSONL (JSON Lines) transcript files, one per session. Each line is a JSON object representing a single event (message, tool call, tool result, metadata).

These are the human-readable / machine-parseable equivalent of `state.db` sessions. Useful for:
- External processing or analysis
- Archival and compliance
- Redaction before long-term storage

---

### `cron/`

Contains cron job definitions (`jobs.yaml`) and a per-job output directory. Cron state persists independently of any active session or gateway.

---

### `logs/`

Rotating log files for agent, gateway, error, and cron events. Useful for debugging, auditing, and post-incident review.

---

## Export Options

### Option A: Full Hermes Backup

Creates a zip archive of all Hermes data (excluding the agent codebase itself):

```bash
# Full backup
hermes backup

# Specify output path
hermes backup -o ~/Desktop/hermes-backup.zip

# Quick backup: config, state.db, .env, auth, cron jobs only
hermes backup --quick --label "pre-upgrade"
```

Restore from backup:

```bash
hermes import ~/Desktop/hermes-backup.zip
```

**Note:** Uses SQLite's `backup()` API — safe to run while Hermes is active (WAL mode).

---

### Option B: Session Export (JSONL)

```bash
# Export all sessions
hermes sessions export backup.jsonl

# Export only Telegram sessions
hermes sessions export telegram-history.jsonl --source telegram

# Export a single session by ID
hermes sessions export session.jsonl --session-id 20250305_091523_a1b2c3d4
```

Each exported line contains:
```json
{
  "session_id": "20250305_091523_a1b2c3d4",
  "source": "cli",
  "timestamp": "2025-03-05T09:15:23Z",
  "model": "gemini-2.5-flash",
  "messages": [...],
  "token_counts": {"input": 4821, "output": 1203}
}
```

---

### Option C: Memory & Skills Only (Human-Readable)

```bash
mkdir -p ~/hermes-export

cp ~/.hermes/memories/MEMORY.md ~/hermes-export/
cp ~/.hermes/memories/USER.md ~/hermes-export/
rsync -a ~/.hermes/skills/ ~/hermes-export/skills/

tar -czf ~/hermes-memory-skills-export.tar.gz -C ~/hermes-export .
```

---

### Option D: Secure Audit Export

```bash
# Weekly full backup
hermes backup -o ~/secure-backups/hermes-$(date +%F).zip

# Session JSONL for grep/audit/redaction
hermes sessions export ~/secure-backups/hermes-sessions-$(date +%F).jsonl

# Memory + skills only (human-readable, portable)
tar -czf ~/secure-backups/hermes-memory-skills-$(date +%F).tar.gz \
  ~/.hermes/memories \
  ~/.hermes/skills
```

---

## What to Exclude from All Backups

```text
~/.hermes/.env            # API keys and bot tokens
~/.hermes/auth.json       # OAuth credentials
~/.hermes/state.db        # Contains full session history with potentially sensitive context
~/.hermes/sessions/       # Raw JSONL transcripts (ditto)
```

Also review skills and memory files for:
- API keys or tokens accidentally captured in tool call traces
- Internal IP addresses or hostnames
- Customer names, PII, or confidential project details
- SSH key paths or contents

---

## References

- [CLI Commands Reference — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/reference/cli-commands)
- [Sessions — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/sessions)
- [CONTRIBUTING.md — NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent/blob/main/CONTRIBUTING.md)
- [Configuration — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
