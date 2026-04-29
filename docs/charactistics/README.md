# Hermes Agent - Characteristics Documentation

This directory contains detailed documentation reconstructed from research notes on Hermes Agent by Nous Research. It is the conceptual and setup-oriented companion to the repository's scripts, examples, and dev-progress artifacts.

---

## Start Here

| Need | File |
|------|------|
| Install Hermes Agent and configure the first provider | [setup-guide.md](setup-guide.md) |
| Understand what Hermes Agent is | [00-overview.md](00-overview.md) |
| Choose Gemini, Copilot, Anthropic, OpenRouter, or Ollama | [09-provider-selection.md](09-provider-selection.md) |
| Find storage, backup, and export locations | [06-storage-layout.md](06-storage-layout.md) |
| Keep sessions running or resume work | [10-session-management.md](10-session-management.md) |

## Characteristics Index

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

## Repository Orientation

Use these root-level resources when you move from reading the characteristics docs to configuring or validating the local setup.

| Area | Location | Notes |
|------|----------|-------|
| Root orientation | [../../README.md](../../README.md) | Top-level map for docs, examples, scripts, Docker, app, and phase artifacts |
| Platform setup docs | [../dev_progress](../dev_progress) | macOS, WSL2, Ollama models, gateways, config, troubleshooting, security, Docker, task management, tooling, metrics |
| Dev-progress index | [../dev_progress/00-overview.md](../dev_progress/00-overview.md) | Implementation-focused overview |
| Examples index | [../../examples/README.md](../../examples/README.md) | Starter examples for local Hermes configuration |
| Scripts index | [../../scripts/README.md](../../scripts/README.md) | Install and utility script overview |
| Desktop app | [../../app/README.md](../../app/README.md) | Electron wrapper documentation |
| Phase markers | [../../.agent-progress](../../.agent-progress) | Worker completion artifacts |

## Examples Map

| Directory | Contents |
|-----------|----------|
| [../../examples/config](../../examples/config) | Base `config.yaml`, `.env`, and provider snippets for Anthropic, Copilot, Gemini, Ollama, and OpenRouter |
| [../../examples/gateway](../../examples/gateway) | Telegram, Discord, and Slack gateway config examples |
| [../../examples/cron](../../examples/cron) | Daily briefing, disk monitor, GitHub triage, and study-review jobs with prompt files |
| [../../examples/memory](../../examples/memory) | Starter `MEMORY.md` and `USER.md` files |
| [../../examples/profiles](../../examples/profiles) | Profile-specific configuration and memory examples |
| [../../examples/security](../../examples/security) | Docker sandbox, security baseline, and threat checklist |
| [../../examples/skills](../../examples/skills) | Reusable skill examples and skill index |
| [../../examples/task-templates](../../examples/task-templates) | Feature implementation prompt template |

## Scripts Map

| Directory | Scripts |
|-----------|---------|
| [../../scripts/macos](../../scripts/macos) | macOS setup, desktop app build, debug, gateway setup, Gemini provider setup |
| [../../scripts/windows](../../scripts/windows) | Windows/WSL2 setup script |
| [../../scripts/common](../../scripts/common) | Verify, backup, export sessions, gather context, scaffold Hermes directory |
| [../../scripts/automation](../../scripts/automation) | Model update automation |

## Phase Artifacts

| Location | Purpose |
|----------|---------|
| [../dev_progress/progress.md](../dev_progress/progress.md) | Dev-progress status tracking |
| [progress.md](progress.md) | Characteristics documentation progress tracking |
| [../../.agent-progress](../../.agent-progress) | Worker phase done markers |

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
