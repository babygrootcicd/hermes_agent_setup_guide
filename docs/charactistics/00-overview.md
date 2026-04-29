# Hermes Agent — Overview

Hermes Agent is an open-source, **local-first personal agent runtime** developed by Nous Research. It is not a chatbot. It is a stateful agent that persists knowledge, learns procedures, schedules routines, and integrates with messaging platforms — all running from your local machine.

**Repository:** [NousResearch/hermes-agent](https://github.com/nousresearch/hermes-agent)

---

## Core Distinction: Agent vs Chatbot

A standard chatbot resets on every conversation:

```text
Every session  = start from scratch
Project context = must re-explain
Preferences    = must re-explain
Tools used     = must re-explain
Past mistakes  = may be repeated
```

Hermes is designed to accumulate state across sessions:

```text
Every session  = loads persistent memory + skills
Project context = stored in MEMORY.md
Preferences    = stored in USER.md
Procedures     = stored as reusable SKILL.md files
Past sessions  = searchable via SQLite FTS5
```

---

## The 4-Layer Persistence Architecture

Hermes's "grows with you" capability is built on four distinct persistence layers:

| Layer | What it stores | Location |
|-------|---------------|----------|
| **Short-term hot memory** | User preferences, project environment, conventions, corrections | `~/.hermes/memories/MEMORY.md` + `USER.md` |
| **Full session search** | Complete conversation and tool-call history | `~/.hermes/state.db` (SQLite + FTS5) |
| **Reusable skill documents** | Solved procedures, SOPs, runbooks extracted from successful tasks | `~/.hermes/skills/` |
| **Scheduled routines** | Recurring automations, cron jobs, webhook integrations | `~/.hermes/cron/` + messaging gateways |

---

## Five Core Feature Pillars

### 1. Self-Evolution & Skill Creation (閉環自學與技能進化)
After solving a complex task, Hermes automatically extracts the reasoning logic and packages it as a reusable **Skill Card**. The system never forgets a solution — next time a similar problem appears, the skill is invoked directly. The `hermes-agent-self-evolution` module uses DSPy and GEPA (Genetic-Pareto Prompt Evolution) to auto-optimize skills, system prompts, and code based on past execution traces. No GPU retraining required.

### 2. Persistent Memory (跨會話持久記憶)
Two core files separate concerns cleanly: `MEMORY.md` stores project environment, past task experience, and agent conventions; `USER.md` stores user preferences, decision habits, and communication style. New tasks first retrieve existing memory and skills before making any API calls, reducing token consumption.

### 3. Multi-Platform Gateway & Automation (多平台無縫接入與自動化排程)
Native support for Telegram, Discord, Slack, WhatsApp, Signal, and CLI. A user can send a command from a mobile Telegram client and have the agent execute terminal tasks on a cloud VM or local server. Built-in cron scheduling supports natural language task definitions.

### 4. Defense-in-Depth Security (深度防禦的安全架構)
Seven-layer security model including: dangerous command approval, container isolation (Docker/Modal sandboxes), context file scanning for prompt injection, read-only bind mounts, and credential exfiltration detection (blocks `.env` reads and unauthorized `curl` calls).

### 5. Model Agnosticism & Data Privacy (跨模型支援與資料隱私)
Supports 200+ LLMs via OpenRouter (Claude, OpenAI, DeepSeek, etc.) and fully offline local inference via Ollama. MIT-licensed and fully open-source. Enterprises connect directly via OAuth to LLM APIs — no sensitive data passes through third-party intermediary servers.

---

## Platform Support

| Platform | Support |
|----------|---------|
| Linux | Full |
| macOS | Full |
| WSL2 | Full |
| Android Termux | Full |
| Windows (native) | Not supported — use WSL2 |

---

## Conceptual Architecture Summary

```text
Hermes Agent =
  local-first personal agent runtime
  + persistent memory (MEMORY.md / USER.md)
  + session database (state.db, SQLite + FTS5)
  + procedural skills (~/.hermes/skills/)
  + cron scheduler (~/.hermes/cron/)
  + messaging gateway (Telegram, Discord, Slack, WhatsApp, Signal)
  + tool execution layer (terminal, browser, file, web, MCP, Home Assistant)
```

It is not:

```text
AI chatbot
Fine-tuned model
Cloud-dependent SaaS agent
```

---

## References

- [GitHub — NousResearch/hermes-agent](https://github.com/nousresearch/hermes-agent)
- [Hermes Agent Official Site](https://hermes-agent.org/)
- [Persistent Memory Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory)
- [FAQ & Troubleshooting](https://hermes-agent.nousresearch.com/docs/reference/faq)
