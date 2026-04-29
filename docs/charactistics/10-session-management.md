# Session Management & Persistence

Understanding what Hermes persists, where it lives, and how to resume or export sessions is essential for using it reliably. This document clarifies the distinction between persistent memory, session history, and running processes.

---

## What Is a "Session"?

A session is a single continuous conversation between you and Hermes, from start to exit. Sessions are tracked across all platforms:

- CLI (`hermes chat`)
- Telegram gateway
- Discord gateway
- Slack gateway
- WhatsApp gateway
- Signal gateway
- Matrix gateway
- Email
- Webhook
- Cron-triggered tasks

Each session gets a unique ID in the format:

```text
20260426_103523_086f4d
```

(date `_` time `_` random hex)

---

## What Persists and What Doesn't

### When You Close the Terminal

If you run Hermes as a foreground CLI process and close the terminal:

| Component | Persists? | Notes |
|-----------|-----------|-------|
| `MEMORY.md` / `USER.md` | Yes | Already written to disk; loaded into next session |
| Completed session messages | Usually yes | Written to `state.db` incrementally |
| Response mid-generation | No | Current response may be cut off |
| Active tool execution | No | Process is killed; tool state is lost |
| Cron job definitions | Yes | Stored in `~/.hermes/cron/`; persist independently |
| Background gateway | Only if daemonized | If started as a foreground process, it dies with the terminal |

### Session vs Memory — The Key Distinction

| Concept | What it is | Scope |
|---------|-----------|-------|
| **Memory** (`MEMORY.md`/`USER.md`) | Curated facts and preferences | Injected into every new session |
| **Session** (state.db entry) | Complete conversation and tool call history | Available on explicit resume or search |

Memory is always active. Sessions must be explicitly resumed to restore full conversation context.

---

## Resuming a Session

### Continue the Most Recent Session

```bash
hermes chat --continue
# or short form:
hermes chat -c
```

This loads the most recent CLI session from `~/.hermes/state.db` and restores the complete conversation history.

### Resume a Specific Session by ID

```bash
hermes chat --resume 20260426_103523_086f4d
# or short form:
hermes chat -r 20260426_103523_086f4d
```

### Find Your Session ID

When Hermes exits normally (via `/quit` or `Ctrl+C`), it prints:

```text
Resume this session with:
  hermes --resume 20260426_103523_086f4d
```

The session ID is also displayed in the UI status bar:

```text
Session: 20260426_103523_086f4d
```

---

## Session Search

Even without resuming a session, you can search all past sessions by content:

```bash
hermes session search "GitLab 502 root cause"
hermes session search "Glasgow scholarship essay thesis"
hermes session search "CCSP Domain 6 wrong answers"
```

The underlying SQLite FTS5 index covers all sessions from all platforms. Results include the session ID, timestamp, source platform, and matching message excerpts.

---

## Session Listing

```bash
# List recent sessions
hermes sessions list

# List with platform filter
hermes sessions list --source telegram
hermes sessions list --source cli

# List with date range
hermes sessions list --since 2026-04-01 --until 2026-04-30
```

---

## Closing Hermes Properly

Do not simply close the terminal window. The preferred exit methods are:

**Inside Hermes chat:**

```bash
/quit
```

**From the keyboard:**

```bash
Ctrl+C
```

Both trigger a clean shutdown: in-progress responses are flushed, the session is written to `state.db`, and the resume command is printed.

---

## Memory Is Not the Same as Session Context

Starting a new `hermes chat` (without `--continue` or `--resume`) gives you:

```text
New session with:
  - Persistent memory loaded (MEMORY.md + USER.md)
  - Skills available
  - But NO previous conversation context from prior sessions
```

Resuming with `--continue` or `--resume` gives you:

```text
Resumed session with:
  - Persistent memory loaded
  - Skills available
  - FULL prior conversation history restored
```

**Rule of thumb:**
- For a fresh task on the same project: `hermes chat` (new session, memory carries context)
- To continue an interrupted conversation: `hermes chat -c` or `hermes chat -r <id>`

---

## Running Hermes After Terminal Close

### Option A: tmux (Simplest — Recommended)

```bash
# Create a new named tmux session
tmux new -s hermes

# Start Hermes inside it
hermes chat \
  --provider google-gemini-cli \
  --model gemini-2.5-flash \
  --toolsets terminal,skills

# Detach (Hermes keeps running)
Ctrl+B then D

# Reattach later
tmux attach -t hermes
```

This keeps the Hermes process alive even after the terminal window is closed or SSH connection drops.

### Option B: screen

```bash
screen -S hermes
hermes chat --provider google-gemini-cli --model gemini-2.5-flash
# Detach: Ctrl+A then D
# Reattach: screen -r hermes
```

### Option C: nohup (Fire and Forget)

```bash
nohup hermes chat \
  --provider google-gemini-cli \
  --model gemini-2.5-flash \
  --toolsets terminal,skills \
  > ~/.hermes/logs/nohup.log 2>&1 &
```

Not ideal for interactive use, but suitable for a non-interactive task you want to run in the background.

### Option D: Gateway as a Service

For persistent messaging gateway (Telegram, Discord) that should survive reboots:

**macOS (launchd):**

```bash
hermes gateway install --platform telegram --service launchd
```

This creates a `~/Library/LaunchAgents/com.hermes.telegram.plist` and loads it automatically on login.

**Linux (systemd):**

```bash
hermes gateway install --platform telegram --service systemd
```

Creates a systemd user service that starts on login.

---

## Session Storage Details

`~/.hermes/state.db` uses SQLite in WAL (Write-Ahead Logging) mode. This means:
- The database can be safely read while Hermes is running
- `hermes backup` can copy the database without corruption
- No need to stop Hermes to back up session history

---

## Exporting Sessions

### Export All Sessions

```bash
hermes sessions export backup.jsonl
```

### Export by Platform

```bash
hermes sessions export telegram-history.jsonl --source telegram
hermes sessions export discord-history.jsonl --source discord
hermes sessions export cli-history.jsonl --source cli
```

### Export a Single Session

```bash
hermes sessions export session.jsonl --session-id 20260426_103523_086f4d
```

### JSONL Format

Each line is a JSON object:

```json
{
  "session_id": "20260426_103523_086f4d",
  "source": "cli",
  "timestamp": "2026-04-26T10:35:23Z",
  "model": "gemini-2.5-flash",
  "profile": "coder",
  "messages": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "...", "tool_calls": [...]},
    {"role": "tool", "content": "..."}
  ],
  "token_counts": {"input": 4821, "output": 1203},
  "lineage": {"parent_session": null}
}
```

---

## Recommended Session Hygiene

### Daily Usage Flow

```bash
# Start work
hermes chat --profile coder -c   # continue from yesterday if relevant

# Or start fresh
hermes chat --profile coder

# End of session
/quit
```

### Weekly Archival

```bash
# Export sessions for the week as JSONL
hermes sessions export \
  ~/secure-backups/sessions-$(date +%F).jsonl \
  --since $(date -d '7 days ago' +%F)

# Full backup
hermes backup -o ~/secure-backups/hermes-$(date +%F).zip
```

### Redact Before Long-Term Storage

Before archiving JSONL session files:
- Remove messages containing API keys, tokens, or credentials
- Redact internal IP addresses and hostnames if archiving off-machine
- Strip any customer names or PII

---

## Troubleshooting

### "Session not found"

Session IDs are stored in `~/.hermes/state.db`. If you are using multiple profiles, the session ID must match the active profile's database.

```bash
# Verify with correct profile
hermes --profile coder sessions list
hermes --profile coder chat --resume <session-id>
```

### Session Seems to Lose Context Mid-Conversation

Context window limits apply. If a session grows beyond the configured `context_length`, older messages are truncated. To mitigate:
- Increase `context_length` (use a cloud model if needed)
- Use `session_search` to retrieve specific past content instead of keeping everything in context

### Gateway Stopped Responding After Restart

If the gateway was started as a foreground process, it dies when the terminal closes. Install it as a service:

```bash
hermes gateway install --platform telegram --service launchd   # macOS
hermes gateway install --platform telegram --service systemd   # Linux
```

---

## References

- [Sessions — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/sessions)
- [CLI Commands Reference — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/reference/cli-commands)
- [Persistent Memory — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory)
- [Configuration — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
