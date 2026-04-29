# Everyday Tasks & Use Cases

Hermes's built-in tool layer covers web search, browser automation, terminal execution, file editing, memory, subagent delegation, messaging delivery, Home Assistant, MCP, and more. Toolsets can be selectively enabled or disabled per profile and per session.

This document covers the most practical everyday use cases and how Hermes learns your preferences for each.

---

## Task Categories Overview

| Task category | What Hermes can do | What it learns |
|--------------|-------------------|---------------|
| **Daily briefing** | Search news, summarize, deliver to Telegram/Discord | Source preferences, summary length, topic priorities |
| **Gmail / Calendar / Docs** | Manage Gmail, Calendar, Drive, Docs, Sheets via Google Workspace skill | Reply tone, meeting summary format, priority senders |
| **GitHub / Coding** | Issue triage, PR review, CI failure analysis, docs drift detection | Repo structure, branch conventions, CI failure patterns |
| **DevOps / Monitoring** | Uptime checks, alert triage, deployment verification | Service names, runbooks, alert severity mapping |
| **Research** | arXiv digest, repo scouting, competitor tracking | Research topics, preferred sources, format preferences |
| **Notes / Study** | Apple Notes, Obsidian workflows, exam prep | Note templates, tag conventions, study formats |
| **Reminders / Routines** | Cron reminders, weekly review, monthly audits | Recurrence schedules, delivery channels |
| **Smart home / Devices** | Home Assistant, Apple Reminders, FindMy, iMessage | Common devices, automation triggers |

---

## Daily Briefing & Research Radar

### How It Works

Hermes cron triggers at a set time, spins up a fresh agent session, runs web searches, summarizes results, and delivers to your preferred platform.

### Setup Command

```bash
hermes cron create "0 8 * * *" \
  --prompt "
    Every morning, search for the following topics and produce a structured briefing:
    1. AI agent frameworks (new releases, GitHub stars, papers)
    2. Open-source LLM releases (models, benchmarks, finetunes)
    3. Cloud security and zero trust news
    4. UK scholarship deadlines and announcements
    Summarize each item in Traditional Chinese.
    Prioritize engineering impact over business/funding news.
    Maximum 2 sentences per item.
    Include source links for each item.
  " \
  --deliver telegram
```

### What Hermes Learns Over Time

```text
- Preferred summary language (Traditional Chinese)
- Preferred sources (GitHub, arXiv, vendor engineering blogs)
- Topics to exclude (funding news unless open-source related)
- Summary density (≤ 2 sentences per item)
- Required elements (source links)
```

These preferences are written to `MEMORY.md` and applied automatically in future briefings.

---

## Coding, GitHub & DevSecOps

This is where Hermes provides the most leverage for engineering workflows.

### Supported Tasks

```text
- Nightly issue triage (label, prioritize, summarize open issues)
- Automated PR review (code quality, security, convention checks)
- CI failure analysis (identify root cause, suggest fix)
- Dependency vulnerability scan (SBOM analysis, CVE matching)
- Docs drift detection (check if docs are out of sync with code)
- Repo activity scouting (new stars, forks, related projects)
- Release note generation (from commit history and merged PRs)
- Security audit pipeline (static analysis, secret scanning)
```

### Nightly DevSecOps Digest

```bash
hermes cron create "0 2 * * *" \
  --workdir /home/me/projects/pandora-box-console \
  --prompt "
    Audit all open PRs and GitHub issues.
    Summarize CI status for all branches.
    Identify security-relevant changes (dependency updates, auth changes, config changes).
    Check for dependency CVEs in package.json and go.mod.
    Produce a concise DevSecOps digest with action items.
  " \
  --deliver telegram
```

### What Hermes Learns Over Time

```text
- Repo structure and file organization
- Commit message style (conventional commits, custom prefixes)
- PR review rubric (what constitutes a passing review)
- Common CI failure patterns and standard fixes
- Typical fix sequence for recurring issues
- Security audit checklist for this codebase
```

### Interactive Coding Session

```bash
hermes chat \
  --workdir ~/projects/my-repo \
  --toolsets terminal,file,web,skills \
  --max-turns 30
```

With `--workdir` set:
- Project files are accessible for reading and editing
- `AGENTS.md`, `CLAUDE.md`, `.cursorrules` are injected as context
- Terminal commands run relative to the project directory

---

## DevOps, Monitoring & On-Call Assistant

### Supported Tasks

```text
- Endpoint uptime monitoring (API, web, docs endpoints)
- Alert triage (PagerDuty, Grafana, Datadog webhook ingest)
- Deployment verification (smoke tests after deploy)
- Weekly dependency audit
- Weekly secret scanning (pattern match for exposed secrets)
- Log analysis (Loki, journald, Docker logs)
- Disk usage monitoring and cleanup planning
- Database retention check (Prometheus, Loki TSDB)
```

### Alert Triage Workflow

When an alert comes in via webhook:

1. Hermes receives the alert payload
2. Searches session history for similar past incidents
3. Compares against recent deployments or config changes
4. Produces:
   - Root cause hypothesis
   - First response steps
   - Escalation recommendation

### Lab-Specific Monitoring Examples

```bash
# Daily disk usage check
hermes cron create "0 9 * * *" \
  --prompt "
    Check disk usage on the GitLab server.
    Report usage for:
    - /var/opt/gitlab/backups
    - /var/log/journal
    - /var/lib/docker
    If any partition exceeds 85%, produce a cleanup plan and send alert.
    Also check Loki and Prometheus TSDB retention for anomalies.
  " \
  --deliver telegram

# Every 2 hours uptime check
hermes cron create "0 */2 * * *" \
  --prompt "
    Check uptime for:
    - GitLab web (https://gitlab.internal)
    - MinIO API (http://minio.internal:9000/minio/health/live)
    - Grafana (http://grafana.internal:3000/api/health)
    Report any failures immediately.
  " \
  --deliver telegram
```

### What Hermes Learns Over Time

```text
- Service names and internal URLs
- Standard runbook steps per alert type
- Alert severity classification for this environment
- Known false positives to suppress
- Escalation paths and contacts
```

---

## Gmail, Calendar & Google Workspace

### Supported Tasks (via Google Workspace skill)

```text
- Gmail: inbox digest, label-based triage, draft replies, thread summary
- Calendar: daily briefing, meeting preparation, schedule conflicts
- Drive: file search and summary
- Docs: document digest and editing
- Sheets: data summary and updates
```

### Daily Gmail Digest

```bash
hermes cron create "0 7 * * 1-5" \
  --prompt "
    Summarize unread Gmail from the last 24 hours.
    Group by: urgent action required / FYI only / newsletters.
    For urgent items, draft a suggested reply.
    Flag emails from: HR, legal, HMRC, university admissions.
  " \
  --deliver telegram
```

### Calendar Briefing

```bash
hermes cron create "30 7 * * 1-5" \
  --prompt "
    Summarize today's calendar events.
    For each meeting: time, attendees, agenda (if available), prep notes.
    Flag any conflicts.
  " \
  --deliver telegram
```

### What Hermes Learns Over Time

```text
- Reply tone and style per sender type
- Meeting summary format preference
- Priority senders and labels
- Weekly summary fields and format
- Which threads to auto-archive vs flag
```

**Security recommendation:** Keep Gmail/Calendar access in a separate `personal` profile, isolated from coding and security-lab profiles. This prevents personal email context from leaking into work sessions and vice versa.

---

## Notes, Research & Study (Obsidian / Apple Notes)

### Supported Tasks

```text
- arXiv paper digest (daily or weekly)
- YouTube transcript → structured summary
- Research note creation with template
- Scholarship essay material collection
- Exam wrong-answer pattern analysis
- Reading list curation
- Concept explanation and deep-dive
```

### Weekly Study Review (CCSP / Security Certs)

```bash
hermes cron create "0 20 * * 0" \
  --prompt "
    Summarize this week's CCSP study session patterns.
    Structure the output as:
    1. Domain coverage (which domains were studied)
    2. Repeated misconceptions (concepts answered incorrectly multiple times)
    3. Exam trap patterns (specific question structures that caused errors)
    4. Next week's drill list (3-5 specific topics to prioritize)
    Format as Markdown with tables.
    Do not use first/second/third person pronouns.
  " \
  --deliver file:~/study/weekly-review-$(date +%F).md
```

### Daily arXiv Digest

```bash
hermes cron create "0 9 * * *" \
  --prompt "
    Search arXiv for papers published today in:
    - cs.AI (AI agents, reasoning, tool use)
    - cs.CR (cryptography, security)
    - cs.LG (LLM training, alignment)
    Summarize the top 3 most relevant papers.
    Include: title, authors, key contribution, why it matters.
    Save as Markdown.
  " \
  --deliver file:~/research/arxiv-$(date +%F).md
```

### What Hermes Learns Over Time

```text
- Preferred note format (Markdown + tables + checklists)
- Topic taxonomy and tagging system
- Preferred level of technical depth
- Citation and reference style
- Which paper categories are high priority
- Study schedule and review cadence
```

---

## Smart Home & Personal Devices

### Supported Integrations (via Built-in Skills)

```text
- Home Assistant (device control, automation, state queries)
- Apple Reminders (create and manage reminders)
- Apple Notes (read and write notes)
- FindMy (device location queries)
- iMessage (send messages, read threads)
```

### Examples

```bash
# Check if door is locked before going to sleep
hermes chat --toolsets home_assistant
> "Is the front door locked and are all lights off?"

# Create a reminder
> "Remind me tomorrow at 9am to submit the HMRC self-assessment"

# Find device
> "Where is my MacBook according to FindMy?"
```

---

## Toolset Reference

Toolsets can be enabled or disabled globally (in `config.yaml`) or per-session (via `--toolsets` flag):

| Toolset | What it includes |
|---------|-----------------|
| `terminal` | Shell command execution |
| `file` | File read, write, edit |
| `web` | Web search, URL fetching |
| `browser` | Full browser automation (Playwright) |
| `skills` | Skill retrieval and application |
| `memory` | Memory read/write |
| `github` | GitHub API integration |
| `google_workspace` | Gmail, Calendar, Drive, Docs, Sheets |
| `messaging` | Send messages to configured platforms |
| `home_assistant` | Home Assistant API |
| `mcp` | Model Context Protocol server tools |
| `code_execution` | Sandboxed code execution |
| `cron` | Cron job management |
| `delegation` | Spawn and manage subagents |

---

## References

- [Tools & Toolsets — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/tools)
- [Skills Hub — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/skills)
- [Automation Templates](https://hermes-agent.nousresearch.com/docs/guides/automation-templates)
- [Daily Briefing Bot Tutorial](https://hermes-agent.nousresearch.com/docs/guides/daily-briefing-bot)
- [Scheduled Tasks (Cron)](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron)
