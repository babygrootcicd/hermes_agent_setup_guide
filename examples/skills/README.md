# Hermes Agent Skill Templates

This directory contains reusable Hermes skill examples in the `agentskills.io/v1` style. A distributable skill should live in its own directory and expose a `SKILL.md` file:

```text
examples/skills/<skill-name>/SKILL.md
```

To install a skill locally, copy the whole skill directory to:

```bash
~/.hermes/skills/<skill-name>/SKILL.md
```

## Compatible Skill Card Structure

Each `SKILL.md` should include:

1. `Metadata` with version, Hermes compatibility, and standard identifier.
2. `Triggers` describing when Hermes should invoke the skill.
3. `Tools Required` listing toolsets such as `web`, `file`, `github`, `terminal`, `memory`, or `messaging`.
4. `Customization Variables` for values that should come from `MEMORY.md`, profile config, cron prompts, or inline overrides.
5. `Step-by-Step Procedure` with the operational runbook.
6. `Example Invocation Prompts` for interactive and scheduled usage.
7. `Known Edge Cases` and explicit handling rules.
8. `Success Criteria` so the agent can validate the run before delivery.
9. `Memory Integration` for preferences, patterns, or run history that should persist.

## Practical Examples

| Skill | Coverage |
|-------|----------|
| `daily-briefing/SKILL.md` | Morning news and research briefing with source links and delivery fallback |
| `github-pr-review/SKILL.md` | GitHub PR review, CI status, security checks, and test coverage assessment |
| `devops-monitor/SKILL.md` | Uptime checks, disk monitoring, webhook alert triage, and incident reports |
| `ccsp-study-review/SKILL.md` | CCSP and security certification weekly review, misconception analysis, and drill planning |
| `arxiv-digest/SKILL.md` | Daily or weekly arXiv digest for AI, security, ML, and software engineering papers |

The legacy flat files `code-review.md` and `data-formatter.md` are simple prompt examples. Prefer the directory-based `SKILL.md` format for Hermes/agentskills-compatible skills.

## Loading Examples

Interactive:

```bash
hermes chat --skill examples/skills/daily-briefing/SKILL.md
```

Installed:

```bash
cp -R examples/skills/daily-briefing ~/.hermes/skills/daily-briefing
hermes chat --toolsets web,memory,messaging,skills
```

Scheduled:

```bash
hermes cron create "0 8 * * *" \
  --prompt "Run daily-briefing skill." \
  --deliver telegram
```
