# Hermes Agent — Characteristics Documentation

This directory contains detailed documentation reconstructed from research notes on Hermes Agent (by Nous Research). Each file covers one aspect of the system in depth.

---

## Index

| File | Topic | Summary |
|------|-------|---------|
| [00-overview.md](00-overview.md) | Overview | What Hermes is, the 4-layer persistence model, 5 core pillars, platform support |
| [01-self-evolution-and-skills.md](01-self-evolution-and-skills.md) | Self-Evolution & Skills | Skill extraction, DSPy/GEPA optimization, skills vs memory, agentskills.io compatibility |
| [02-persistent-memory.md](02-persistent-memory.md) | Persistent Memory | MEMORY.md, USER.md, how preferences are learned, memory capacity, session search |
| [03-multi-platform-and-automation.md](03-multi-platform-and-automation.md) | Gateways & Cron | Telegram/Discord/Slack/CLI setup, cron scheduling, automation recipes |
| [04-security-architecture.md](04-security-architecture.md) | Security | 7-layer defense model, container isolation, prompt injection detection, threat model |
| [05-model-agnosticism.md](05-model-agnosticism.md) | Model Agnosticism | Provider categories, local-first vs cloud, data privacy, model selection by use case |
| [06-storage-layout.md](06-storage-layout.md) | Storage Layout | Full `~/.hermes/` directory tree, every component explained, export options |
| [07-everyday-tasks.md](07-everyday-tasks.md) | Everyday Tasks | Daily briefing, coding/GitHub, DevOps monitoring, Gmail/Calendar, study workflows |
| [08-profile-design.md](08-profile-design.md) | Profile Design | 4-profile setup (personal/coder/security-lab/study), isolation guarantees, config examples |
| [09-provider-selection.md](09-provider-selection.md) | Provider Selection | Provider ranking, Gemini/Copilot/Codex/Claude/Ollama setup, speed optimization |
| [10-session-management.md](10-session-management.md) | Session Management | What persists, resume/continue, tmux, gateway as service, session export |

---

## Quick Decision Guide

**"Which provider should I use?"**
→ See [09-provider-selection.md](09-provider-selection.md)

**"Why is Hermes so slow?"**
→ See [09-provider-selection.md — Why `hermes3` Is Not Suitable](09-provider-selection.md#why---model-hermes3-is-not-suitable-for-agentic-use)

**"What happens to my data when I close the terminal?"**
→ See [10-session-management.md](10-session-management.md)

**"How do I keep Hermes running in the background?"**
→ See [10-session-management.md — Running Hermes After Terminal Close](10-session-management.md#running-hermes-after-terminal-close)

**"Where is everything stored?"**
→ See [06-storage-layout.md](06-storage-layout.md)

**"How do I separate personal vs work vs security contexts?"**
→ See [08-profile-design.md](08-profile-design.md)

**"How does memory work?"**
→ See [02-persistent-memory.md](02-persistent-memory.md)

**"What are skills and how do they work?"**
→ See [01-self-evolution-and-skills.md](01-self-evolution-and-skills.md)

**"Is my data private?"**
→ See [05-model-agnosticism.md — Data Privacy Architecture](05-model-agnosticism.md#data-privacy-architecture)

**"What security risks does Hermes have?"**
→ See [04-security-architecture.md](04-security-architecture.md)

---

## Source

All content reconstructed from `description.md` — a consolidated research document covering Hermes Agent features, architecture, and operational guidance.

**Official resources:**
- [GitHub — NousResearch/hermes-agent](https://github.com/nousresearch/hermes-agent)
- [Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs)
- [Hermes Agent Official Site](https://hermes-agent.org/)
