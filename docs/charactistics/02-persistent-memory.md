# Persistent Memory (跨會話持久記憶)

Hermes replaces the "re-explain everything every session" model with a layered persistent memory system. Memory is stored locally, loaded at session start, and updated in real time as the agent learns new facts.

---

## Memory Architecture Overview

```text
Memory Layer          Storage Location                  Loaded When
─────────────────────────────────────────────────────────────────────
Hot memory (facts)    ~/.hermes/memories/MEMORY.md      Session start
User profile (prefs)  ~/.hermes/memories/USER.md        Session start
Episode history       ~/.hermes/state.db (SQLite FTS5)  On-demand search
Procedures            ~/.hermes/skills/                 Task matching
```

---

## MEMORY.md — Agent Personal Notes

**Path:** `~/.hermes/memories/MEMORY.md`
**Capacity:** ~2,200 characters
**Loaded:** Injected into system prompt at every session start as a frozen snapshot

### What to store in MEMORY.md

| Category | Examples |
|----------|---------|
| Project environment | `Project pandora-box-console uses Next.js + Go API + Prometheus + Loki` |
| Infrastructure facts | `Server is Ubuntu 24.04 + GitLab + MinIO + Grafana` |
| Tool quirks / workarounds | `Do not use sudo docker — user is already in docker group` |
| Completed work records | `Migrated Loki from BoltDB to TSDB on 2025-03-10` |
| Project conventions | `All PRs require squash merge; commit messages use conventional commits` |
| Corrections | `Alert threshold is 85%, not 80% — confirmed by ops team` |
| Known pitfalls | `GitLab runner cache invalidates on branch rename` |

### What NOT to store in MEMORY.md

```text
- Raw data dumps (logs, full stack traces)
- Temporary file paths or ephemeral state
- Large code blocks
- Information that changes frequently without clear update discipline
```

### Capacity management

When `MEMORY.md` approaches 2,200 characters, the agent will prompt to:
- Consolidate related items
- Replace outdated entries
- Remove resolved corrections

---

## USER.md — User Profile & Preferences

**Path:** `~/.hermes/memories/USER.md`
**Capacity:** ~1,375 characters
**Loaded:** Injected into system prompt at every session start

### What to store in USER.md

| Category | Examples |
|----------|---------|
| Name / role / timezone | `Dennis, DevSecOps engineer, UTC+8` |
| Language preference | `Respond in Traditional Chinese` |
| Technical level | `Expert in Go / Linux; learning React` |
| Communication style | `No filler text; repo-style deliverables` |
| Preferred formats | `docker-compose.yml + GitHub Actions + runbook.md` |
| Domain conventions | `Security topics: threat model / control / detection / response structure` |
| Report style | `2 sentences per summary item max; always include source links` |
| Work habits | `Prefers Markdown + tables + checklists` |

### Example USER.md entry

```text
- Language: Traditional Chinese responses
- Stack preference for DevOps: docker compose / GitHub Actions / Terraform
- Security responses: threat model / control / detection / response structure
- No preamble; deliver repo-style artifacts
- Code format: 2-space indent, no trailing comments
- Summary length: ≤ 2 sentences per item
```

---

## How Memory Is Loaded

Memory files are read at **session start** and injected as a **frozen snapshot** into the system prompt. This means:

- Memory written during a session is immediately saved to disk
- But it typically does not appear in the active session's context
- It becomes active in the **next session**

```text
Session A:  agent writes new memory entry → saved to disk immediately
Session B:  new memory entry is injected into system prompt → now active
```

This is by design: it prevents memory from cascading into an already-running context in unexpected ways.

---

## How Hermes Learns Preferences

### A. Preferences → USER.md

Suppose you consistently prefer:

```text
- Responses in Traditional Chinese
- DevOps topics: docker compose / GitHub Actions / Terraform
- Security topics: threat model / control / detection / response structure
- No filler text; repo-style deliverables
```

These get written to `USER.md`. The next time you ask:

```text
"Design a GitLab monitoring workflow"
```

Hermes will automatically produce:

```text
- docker-compose.yml
- Prometheus / Grafana / Loki
- Alertmanager
- runbook.md
- GitHub Actions / GitLab CI
- Discord webhook alert
```

Rather than a generic prose explanation.

### B. Project Environment → MEMORY.md

```text
Project pandora-box-console: Next.js + Go API + Prometheus + Loki
Local machine: macOS + zsh + Docker Desktop
Server: Ubuntu 24.04 + GitLab + MinIO + Grafana
Note: do not use sudo docker — user is already in docker group
```

This context is injected at session start, so you never have to re-explain your environment.

### C. Procedures → Skills (not memory)

When Hermes solves a novel complex problem — for example:

```text
"Set up Cursor + local LLM + MCP + GitHub Actions CI auto-debug pipeline"
```

The **procedure** (the how) is extracted into a skill file, not into memory. Memory stores facts; skills store procedures. See `01-self-evolution-and-skills.md` for details.

---

## Session Search via SQLite FTS5

In addition to the short hot-memory files, Hermes maintains a full-text-searchable session database:

**Path:** `~/.hermes/state.db`
**Engine:** SQLite with FTS5 full-text search index

The `session_search` tool can retrieve content from weeks-old sessions even if that content never made it into active memory.

### Example use cases

```text
"What was the root cause of the GitLab 502 we debugged last month?"
"What was the main thesis of my Glasgow scholarship essay draft?"
"Which CCSP Domain 6 question types did I repeatedly get wrong?"
```

All CLI and messaging sessions (Telegram, Discord, Slack, WhatsApp, Signal, Matrix, email, webhook, cron) are stored in `state.db` with complete message history.

---

## Memory Target: `memory` vs `user`

The official memory system distinguishes two write targets:

| Target | Contents |
|--------|----------|
| `memory` | Environment facts, workflows, project conventions, tool workarounds, completed work records |
| `user` | Name, role, timezone, communication preferences, work habits, technical level |

These map to `MEMORY.md` and `USER.md` respectively.

---

## Triggering Memory Writes

Hermes writes to memory automatically when it identifies a fact worth preserving. You can also trigger explicitly:

```bash
/memory add "Project pandora-box-console uses Prometheus on port 9090"
/memory add --target user "Prefer concise bullet lists over paragraphs"
```

To view current memory:

```bash
/memory show
```

To remove an entry:

```bash
/memory remove "outdated entry text"
```

---

## Privacy Considerations

- `MEMORY.md` and `USER.md` are plain text files — human-readable and easily auditable
- They are injected into every LLM API call as part of the system prompt
- If you use a cloud LLM provider (OpenAI, Anthropic, Gemini), the contents of these files are sent to that provider
- For sensitive projects, either use a local model (Ollama) or carefully curate what goes into memory

---

## References

- [Persistent Memory — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory)
- [Sessions — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/sessions)
- [FAQ — Memory vs Skills](https://hermes-agent.nousresearch.com/docs/reference/faq)
