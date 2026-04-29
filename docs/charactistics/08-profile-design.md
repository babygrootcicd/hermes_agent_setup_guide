# Profile Design (多 Profile 設計)

Hermes supports multiple isolated profiles. Each profile has its own configuration, credentials, memory, skills, session database, and cron jobs. This enables clean separation between different working contexts — for example, keeping personal email access completely isolated from a security-lab environment.

---

## Why Use Profiles

Without profiles, a single Hermes instance accumulates memory and sessions from all contexts — personal, professional, client work, security research. This creates several problems:

```text
- Personal email context leaks into coding sessions
- Security lab API keys are accessible from personal assistant sessions
- Memory becomes cluttered with irrelevant cross-context facts
- Skills developed for one context may be incorrectly applied in another
- Session search returns results from all contexts indiscriminately
```

Profiles solve this by giving each context its own isolated state.

---

## Profile Isolation Guarantees

Each profile has its own:

| Component | Profile-isolated |
|-----------|-----------------|
| `config.yaml` | Yes — separate model, tools, gateway config |
| `.env` | Yes — separate API keys and tokens |
| `SOUL.md` | Yes — separate agent personality/instructions |
| `memories/MEMORY.md` | Yes — separate project/environment notes |
| `memories/USER.md` | Yes — same user, but context-specific preferences |
| `skills/` | Yes — separate skill libraries |
| `state.db` | Yes — separate session database |
| `sessions/` | Yes — separate JSONL transcripts |
| `cron/` | Yes — separate scheduled jobs |

---

## Recommended 4-Profile Setup

### Create Profiles

```bash
hermes profile create personal
hermes profile create coder
hermes profile create security-lab
hermes profile create study
```

### Profile Overview

| Profile | Primary purpose | Recommended tools | Notes |
|---------|----------------|------------------|-------|
| `personal` | Gmail, Calendar, daily reminders | google_workspace, cron, messaging | Keep personal data isolated here |
| `coder` | GitHub, Cursor, repo automation | terminal, file, github, mcp | Coding-focused; no personal data |
| `security-lab` | GitLab, SIEM, monitoring, DevSecOps | SSH, terminal, webhook, cron | Highest privilege; most restricted gateway |
| `study` | CCSP, certifications, scholarship research | web, notes, file | No terminal execution needed |

---

## Profile: `personal`

**Purpose:** Personal assistant. Gmail triage, calendar briefing, reminders, daily briefing.

```yaml
# ~/.hermes/profiles/personal/config.yaml
model:
  provider: google-gemini-cli
  default: gemini-2.5-flash
  context_length: 32768

toolsets:
  enabled:
    - google_workspace
    - cron
    - messaging
    - web
    - memory
  disabled:
    - terminal
    - file
    - browser_automation
    - code_execution
    - github

terminal:
  backend: none

memory:
  memory_enabled: true
  user_profile_enabled: true

agent:
  max_turns: 15
```

**MEMORY.md contents for personal profile:**

```markdown
- Primary email: pcleegood@gmail.com
- Calendar: Google Calendar
- Priority senders: HR, legal, HMRC, university admissions offices
- Summary format: grouped by urgency (action required / FYI / newsletters)
- Delivery platform: Telegram
- Preferred reply tone: professional but direct
```

---

## Profile: `coder`

**Purpose:** Coding assistant. GitHub integration, repo automation, PR review, CI analysis, MCP server connections.

```yaml
# ~/.hermes/profiles/coder/config.yaml
model:
  provider: copilot
  default: gpt-4o
  context_length: 64000

toolsets:
  enabled:
    - terminal
    - file
    - web
    - github
    - mcp
    - skills
    - memory
  disabled:
    - google_workspace
    - messaging_send
    - home_assistant
    - browser_automation

terminal:
  backend: docker
  timeout: 180
  mounts:
    - source: ~/projects
      target: /workspace
      readonly: false

security:
  dangerous_command_approval: true
  context_scan_enabled: true

agent:
  max_turns: 30

delegation:
  max_concurrent_children: 2
  max_spawn_depth: 2
```

**MEMORY.md contents for coder profile:**

```markdown
- Repos: pandora-box-console (Next.js + Go API), hermes-agent-setup-guide (docs)
- Commit style: conventional commits (feat/fix/chore/docs)
- PR merge strategy: squash merge only
- CI: GitHub Actions; common failures: npm cache miss, Go module timeout
- Do not use sudo docker — user is in docker group
- Prometheus on port 9090; Grafana on port 3000
```

---

## Profile: `security-lab`

**Purpose:** Security operations. GitLab management, SIEM integration, monitoring, DevSecOps automation, penetration test support.

```yaml
# ~/.hermes/profiles/security-lab/config.yaml
model:
  provider: custom
  default: qwen2.5-coder:14b
  base_url: http://localhost:11434/v1
  api_key: ollama
  context_length: 32768

toolsets:
  enabled:
    - terminal
    - web
    - skills
    - cron
    - memory
  disabled:
    - google_workspace
    - home_assistant
    - browser_automation
    - messaging_send

terminal:
  backend: docker
  timeout: 300
  network: restricted
  allowed_hosts:
    - gitlab.internal
    - grafana.internal
    - prometheus.internal

security:
  dangerous_command_approval: true
  context_scan_enabled: true
  prompt_injection_detection: true

agent:
  max_turns: 20

delegation:
  max_concurrent_children: 1
  max_spawn_depth: 1
```

**Why local model for security-lab:** No LLM API calls leave the machine. Internal infrastructure details (IPs, hostnames, credentials) never reach external providers.

**MEMORY.md contents for security-lab profile:**

```markdown
- Server: Ubuntu 24.04, GitLab on gitlab.internal
- MinIO on minio.internal:9000
- Prometheus on prometheus.internal:9090
- Grafana on grafana.internal:3000
- Loki on loki.internal:3100
- Alert threshold: 85% disk usage triggers cleanup plan
- Do not use sudo docker — user is in docker group
- Backup path: /var/opt/gitlab/backups
```

---

## Profile: `study`

**Purpose:** Certification study (CCSP, CPSA, CRT), scholarship research, paper digests, learning notes.

```yaml
# ~/.hermes/profiles/study/config.yaml
model:
  provider: google-gemini-cli
  default: gemini-2.5-flash
  context_length: 32768

toolsets:
  enabled:
    - web
    - file
    - skills
    - memory
  disabled:
    - terminal
    - github
    - google_workspace
    - browser_automation
    - code_execution
    - messaging_send

terminal:
  backend: none

agent:
  max_turns: 15
```

**MEMORY.md contents for study profile:**

```markdown
- Active certifications: CCSP (exam target: Q3 2026), CPSA
- Study format: Markdown tables + checklists; no pronoun-heavy writing
- CCSP weak domains: Domain 4 (Cloud Application Security), Domain 6 (Legal)
- Paper digest format: title / key contribution / why it matters
- Scholarship target: University of Glasgow MSc Cybersecurity (2026 intake)
- Note output path: ~/study/
```

---

## Switching Between Profiles

```bash
# Start session with a specific profile
hermes chat --profile coder
hermes chat --profile security-lab
hermes chat --profile study

# Set default profile
hermes profile use coder

# List all profiles
hermes profile list

# Show current active profile
hermes profile current
```

---

## Profile-Specific Cron Jobs

Cron jobs are scoped to their profile. A cron job created in `security-lab` uses that profile's config, model, toolsets, and credentials.

```bash
# Create a cron job for the security-lab profile
hermes --profile security-lab cron create "0 9 * * *" \
  --prompt "Check disk usage on GitLab server. Alert if >85%." \
  --deliver telegram

# List cron jobs for a specific profile
hermes --profile personal cron list
```

---

## Memory Separation Across Profiles

While `USER.md` captures personal preferences (name, language, communication style) and can be shared conceptually across profiles, each profile maintains its own physical copy. This means:

- The `coder` profile `USER.md` can include coding-specific preferences without polluting the `personal` profile
- The `security-lab` profile `MEMORY.md` can contain internal server IPs without those appearing in `personal` or `study` sessions
- Skills developed in one profile don't automatically appear in another (though you can copy them manually)

---

## References

- [Profiles: Running Multiple Agents — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/profiles)
- [Configuration — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- [Tools & Toolsets — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/tools)
