# Self-Evolution & Skills System (閉環自學與技能進化)

This is the defining characteristic that separates Hermes Agent from other open-source AI frameworks such as OpenClaw. The system is designed to permanently retain solutions and automatically improve its own capabilities over time — without retraining the underlying model.

---

## How Skill Extraction Works

When Hermes successfully completes a complex task — for example, resolving a specific bug, automating a cross-application data extraction pipeline, or building a CI/CD debug loop — it automatically:

1. Identifies that a reusable solution was found
2. Extracts the reasoning logic and resolution steps
3. Packages them into a **Skill Card** (`SKILL.md`)
4. Writes the skill to `~/.hermes/skills/<skill-name>/SKILL.md`

The system "never forgets a solution." On subsequent encounters with a similar task, Hermes retrieves and applies the skill directly rather than re-deriving the solution from scratch.

---

## Skill Storage Location

All skills are stored under:

```bash
~/.hermes/skills/
```

This directory is the canonical source of truth for all skills, regardless of origin:

| Skill origin | Description |
|-------------|-------------|
| **Bundled skills** | Shipped with Hermes installation |
| **Hub-installed skills** | Downloaded from [agentskills.io](https://agentskills.io) or Skills Hub |
| **Agent-created skills** | Auto-generated when Hermes solves a novel complex problem |

Example skill path:

```bash
~/.hermes/skills/cursor-local-agentic-coding/SKILL.md
```

---

## What a Skill Contains

A skill document captures:

```text
- Task description / trigger condition
- Step-by-step reasoning / procedure
- Tool calls used
- Known edge cases or gotchas
- Success criteria
```

This is conceptually equivalent to a **reusable runbook** or **SOP (Standard Operating Procedure)** — but auto-generated from real execution history rather than manually written.

---

## Example: From Task to Skill

Suppose Hermes successfully completes:

```text
"Set up Cursor + local LLM + MCP + GitHub Actions for CI auto-debug"
```

After task completion, it produces:

```bash
~/.hermes/skills/cursor-local-agentic-coding/SKILL.md
```

Next time a user asks:

```text
"Help me set up local LLM-powered CI debugging for my repo"
```

Hermes retrieves the skill and applies the procedure directly — no re-derivation needed.

---

## Skills vs Memory

These two persistence layers serve different purposes:

| Concept | What it stores | Analogy |
|---------|---------------|---------|
| `MEMORY.md` / `USER.md` | Facts, preferences, project environment | Declarative knowledge |
| `~/.hermes/skills/` | Procedures, SOPs, step-by-step workflows | Procedural knowledge |
| `state.db` (sessions) | Full historical episodes, tool calls | Episodic memory |
| `cron/` | Fixed routines that run on a schedule | Habits / automation |

Skills and memory are both cross-session persistent, but they answer different questions:
- Memory answers: "What do I know?"
- Skills answer: "How do I do this?"

---

## Self-Evolution Module

The `hermes-agent-self-evolution` module goes beyond passive skill storage. It actively improves existing skills, system prompts, and agent code using:

### DSPy
A framework for programming — not prompting — language models. Allows Hermes to optimize prompt pipelines using labeled data from past executions.

### GEPA (Genetic-Pareto Prompt Evolution)
An evolutionary algorithm that:
1. Generates candidate prompt/skill variants
2. Evaluates them against past execution traces
3. Selects Pareto-optimal variants (balancing accuracy, token cost, speed)
4. Replaces weaker variants with evolved versions

**Key advantage:** This entire optimization loop runs without GPU retraining. The base model weights never change. Only the prompts, skill documents, and agent configuration evolve.

---

## Skill Interoperability

Skills produced by Hermes are compatible with the **agentskills.io open standard**, meaning:

- Skills can be shared with other Hermes users
- Skills can be imported from the community hub
- Skills created in one profile can be copied to another

---

## Practical Skill-Building Workflow

To deliberately build skills from your own workflows:

1. Use Hermes to solve a complex, repeatable task
2. After success, trigger skill extraction:
   ```bash
   /skill save "name-of-skill"
   ```
3. Review and edit the generated `SKILL.md` if needed
4. On future similar tasks, Hermes will match and apply the skill automatically

To list all available skills:

```bash
hermes skills list
```

To search skills:

```bash
hermes skills search "keyword"
```

---

## Security Note on Agent-Created Skills

Agent-created skills are auto-written to `~/.hermes/skills/`. Before sharing or backing up:

- Review for embedded API keys, tokens, or internal IPs
- Redact any credentials that may have been captured in tool call traces
- Do not push raw skill files to public repositories without review

---

## References

- [Skills System — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills)
- [Skills Hub — agentskills.io](https://hermes-agent.nousresearch.com/docs/skills)
- [FAQ — Memory vs Skills](https://hermes-agent.nousresearch.com/docs/reference/faq)
