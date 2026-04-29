# Hermes Agent Use Case Guide

This guide is for individual developers and small teams using Hermes Agent in this repository.
It is practical-first: each use case includes exactly what to prepare, what to ask, and how to know it worked.

## Quick Start (5 minutes)

1. Initialize Hermes + local model.

```bash
./scripts/macos/setup_hermes_ollama.sh
hermes model
```

2. Verify runtime health.

```bash
./scripts/common/verify.sh
```

3. Prepare a context bundle (recommended before most tasks).

```bash
./scripts/common/gather_context.sh README.md docs examples/skills > /tmp/hermes_context.txt
```

4. Start a focused session.

```bash
hermes chat --model qwen32b-64k:latest --toolsets terminal,skills --max-turns 12
```

5. Paste your task prompt + key context paths.

Minimal prompt skeleton:

```text
Goal: <one clear outcome>
Constraints: <what not to change>
Context files: <exact paths>
Definition of done: <testable checks>
```

Chinese hint: 任務越小、上下文越精準，回覆速度和品質通常越好。

---

## Use Case 1: Daily Coding Assistant (Individual Developer)

### When to use
- You need fast support for routine tasks: scaffolding files, refactoring a module, writing tests, or updating config.
- You want to reduce context-switching while staying in terminal-first workflow.

### Sample prompt
```text
Act as my pair programmer for this repo.
Task: add a new troubleshooting subsection for slow response in docs/dev_progress/60-troubleshooting.md.
Constraints: keep existing structure; do not edit unrelated files.
Context bundle: README.md, installation_start_guide.md, docs/dev_progress/60-troubleshooting.md.
Definition of done: new subsection includes symptoms, root causes, diagnostic commands, and rollback notes.
```

### Expected inputs / context bundle
- Current task target files.
- One style reference file (for tone/format consistency).
- Optional command outputs (`verify.sh`, logs).
- Optional team conventions (naming, commit style).

### Success criteria
- Only intended files changed.
- Output format matches surrounding docs/code style.
- Task-specific checks pass (lint/test/manual verification).
- The next step is obvious without additional clarification.

### Common pitfalls
- Prompt is too broad (“improve docs” with no scope).
- Missing constraints, leading to over-editing.
- No explicit definition of done.
- Context bundle includes too many irrelevant files, causing slower and noisier output.

---

## Use Case 2: Debugging Loops (Individual or Pair)

### When to use
- A command repeatedly fails, or startup is unstable/intermittent.
- You need a structured diagnosis loop instead of ad-hoc trial and error.

### Sample prompt
```text
Run a debugging loop for slow Hermes responses in my local setup.
Collect: environment info, model config, startup logs, toolset list, and one reproducible slow prompt.
Then produce: hypothesis list ranked by likelihood, test plan, and minimal fix order.
Constraints: no destructive commands; ask before any network-heavy action.
```

### Expected inputs / context bundle
- `installation_start_guide.md`
- `docs/dev_progress/60-troubleshooting.md`
- `scripts/common/verify.sh` output
- Relevant log snippets (`~/.hermes/logs/...`)
- Repro details: exact prompt, model, toolsets, and elapsed time

### Success criteria
- Repro case is captured with concrete steps.
- At least 2-3 root-cause hypotheses with verification method.
- A prioritized fix sequence is proposed and tested.
- You can confirm improvement via measurable delta (latency before/after).

### Common pitfalls
- Skipping baseline measurement (no before/after numbers).
- Mixing multiple changes at once, making attribution impossible.
- Ignoring model/toolset size impact on latency.
- Failing to persist findings into troubleshooting docs.

Chinese hint: 先固定「可重現案例」再優化，不然很難判斷是否真的變快。

---

## Use Case 3: Code Review Preparation (Small Team)

### When to use
- Before opening a PR, you want Hermes to produce a reviewer-ready package.
- Team wants consistent risk summaries and test evidence.

### Sample prompt
```text
Prepare this branch for PR review.
Output sections:
1) change summary by file,
2) behavior impact,
3) risk matrix,
4) test evidence,
5) reviewer checklist.
Focus on bugs, regressions, and missing tests first.
```

### Expected inputs / context bundle
- Changed files list and diffs (`git diff`, `git status`).
- Relevant requirements docs or issue statement.
- Test outputs (unit/integration/manual).
- Existing review template if team uses one.

### Success criteria
- Review brief is concise and actionable.
- High-risk changes are clearly called out.
- Test gaps are explicitly listed, not implied.
- Reviewer can understand intent without reading full commit history first.

### Common pitfalls
- Asking for only “summary” without risk analysis.
- No mapping from change -> behavior impact.
- Missing rollback notes for risky operational changes.
- Treating AI-generated review text as final without human verification.

---

## Use Case 4: Documentation Generation and Maintenance

### When to use
- Features/scripts changed and docs are stale.
- You need onboarding docs, runbooks, or migration notes aligned with current repo state.

### Sample prompt
```text
Update documentation for the current setup flow.
Files in scope: README.md and installation_start_guide.md.
Goals: remove ambiguity, keep commands executable, add failure recovery notes.
Constraints: preserve bilingual style where already present.
```

### Expected inputs / context bundle
- Target doc files.
- Source-of-truth scripts (`scripts/...`).
- Example templates under `examples/`.
- Recent troubleshooting learnings.

### Success criteria
- Commands in docs are copy-paste runnable.
- Terminology and file paths are consistent.
- Known failure patterns have explicit fixes.
- New users can complete setup using docs only.

### Common pitfalls
- Writing conceptual text without executable commands.
- Drifting from actual script behavior.
- Duplicate guidance across files without cross-linking.
- Overusing bilingual content where it harms readability.

---

## Use Case 5: Local Model / Offline Workflow

### When to use
- You need privacy-first, low-dependency workflows.
- Network is limited or cloud API spend must be minimized.

### Sample prompt
```text
Design an offline-first Hermes workflow for this repo using Ollama.
Include: model selection, context-size policy, prompt-size limits, and fallback when quality drops.
Output a practical checklist for daily use.
```

### Expected inputs / context bundle
- Local provider config examples:
  - `examples/config/providers/ollama.yaml`
  - `installation_start_guide.md`
- Hardware constraints (RAM/CPU/GPU).
- Typical task types (coding/docs/review/ops).

### Success criteria
- Workflow runs with no cloud dependency in normal path.
- Latency and quality tradeoffs are documented.
- Team has clear escalation rule to cloud model when needed.
- Sensitive data remains local by default.

### Common pitfalls
- Using a model too large for local hardware.
- Sending oversized context every turn.
- No fallback path for hard reasoning tasks.
- Exposing local model endpoint beyond localhost without controls.

---

## Use Case 6: Gateway Automation (Small Team Notifications and Ops)

### When to use
- Team needs Hermes in chat channels (Telegram/Discord/Slack/Email).
- You want scheduled summaries or alert-driven responses.

### Sample prompt
```text
Set up gateway automation plan for a 4-person dev team.
Channels: Slack for daily standup summary, Telegram for incident notifications.
Use existing examples in this repo.
Output: setup steps, required scopes/tokens, and runbook for token rotation.
```

### Expected inputs / context bundle
- `docs/dev_progress/40-gateway-setup.md`
- `examples/gateway/*.config.yaml`
- `examples/cron/*.yaml`
- Security baseline docs under `examples/security/`

### Success criteria
- Gateway boots reliably with documented startup command.
- Permissions follow least-privilege principle.
- Rotation/revocation process exists for all tokens.
- Message format is stable and useful to recipients.

### Common pitfalls
- Over-privileged bot scopes.
- Tokens committed or shared in plaintext.
- No health check/monitoring for gateway process.
- Automation spam due to missing guardrails or rate control.

Chinese hint: 先用測試群組驗證，再推到正式頻道。

---

## Use Case 7: Safe Operations (Guardrails, Security, Recovery)

### When to use
- You allow command/tool execution and need safety boundaries.
- Team requires repeatable incident response and rollback behavior.

### Sample prompt
```text
Create a safe-operations checklist for Hermes usage in this repository.
Include: credential handling, command allow/deny policy, backup/restore routine, and log sanitization before sharing.
Reference existing security examples.
```

### Expected inputs / context bundle
- `docs/dev_progress/70-security.md`
- `examples/security/threat-checklist.md`
- `scripts/common/backup.sh`
- `scripts/common/export-sessions.sh`
- `.gitignore` and config templates

### Success criteria
- Secrets are not stored in tracked files.
- Backup and restore procedure is tested.
- High-risk commands require explicit human confirmation.
- Shared logs are sanitized for sensitive data.

### Common pitfalls
- Assuming local execution is automatically safe.
- No separation between dev and production-like credentials.
- Skipping restore drills (backup exists but recovery untested).
- Over-trusting autonomous actions in high-impact operations.

---

## Recommended Context Bundle Patterns

Use these lightweight bundles to keep Hermes fast and relevant:

- `Task-only`: target files + 1 reference style file.
- `Debug`: target files + repro logs + verify output.
- `Review`: changed files + diff summary + test results.
- `Ops`: gateway/security docs + active config snippets.

Command pattern:

```bash
./scripts/common/gather_context.sh <path1> <path2> <path3> > /tmp/context.txt
```

Then feed `/tmp/context.txt` into your Hermes prompt session.

---

## Team Operating Model (Small Team, Practical)

- One person owns prompt scope and done-criteria.
- One person validates output against real environment.
- One person updates persistent docs/runbooks.

This keeps AI output actionable and auditable, not just fast.
