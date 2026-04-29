# Skill: DevOps Monitoring & Alert Triage

## Metadata
- **Version:** 1.0.0
- **Compatible with:** Hermes Agent 0.x+
- **Standard:** agentskills.io/v1

## Triggers
Invoke this skill when the user says any of:
- "check server"
- "alert triage"
- "uptime check"
- "disk usage"
- "infrastructure status"
- "check {service name}"
- "what's wrong with {service}"

Also triggered by inbound webhook alerts from Grafana, PagerDuty, Datadog, Prometheus Alertmanager.

---

## Tools Required
| Tool | Purpose |
|------|---------|
| `terminal` | SSH into servers, run disk/process checks, query logs |
| `web` | Fetch HTTP endpoints for uptime checks; receive webhook payloads |
| `memory` | Read service inventory, runbooks, alert thresholds from MEMORY.md |
| `messaging` | Deliver alerts and triage reports |
| `file` | Write incident reports to local path |

---

## Customization Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONITOR_SERVICES` | From MEMORY.md | List of service name → URL pairs to check |
| `MONITOR_DISK_THRESHOLD` | `85` | % usage that triggers cleanup plan |
| `MONITOR_DISK_PATHS` | `/var/opt/gitlab/backups,/var/log/journal,/var/lib/docker` | Paths to check |
| `MONITOR_ALERT_DELIVERY` | `telegram` | Alert delivery target |
| `MONITOR_INCIDENT_PATH` | `~/incidents/` | Local path for incident reports |
| `MONITOR_KNOWN_FP` | See MEMORY.md | Known false-positive alert patterns to suppress |
| `MONITOR_SSH_HOST` | From MEMORY.md | SSH target for server-side checks |

---

## Step-by-Step Procedure

### Step 1: Load context
```
Read MEMORY.md for:
- Service inventory (name, URL, expected status)
- Known false-positive patterns
- Disk paths and thresholds
- Past incident patterns (root causes seen before)
- Runbook references per service
```

### Step 2: Uptime / Endpoint Check

For each service in MONITOR_SERVICES:
```
HTTP GET {url} with timeout=10s
Expected: HTTP 200 (or configured expected code)

If response code != expected OR timeout:
  → Mark service as DOWN
  → Record: url, response code, response time, timestamp

If response time > 2000ms:
  → Mark as DEGRADED (not DOWN)
```

Health check endpoints by service type:
```
GitLab:    /-/health
MinIO:     /minio/health/live
Grafana:   /api/health
Prometheus:/api/v1/query?query=up
Generic:   / or /health or /status
```

### Step 3: Disk Usage Check

Via terminal (SSH or local):
```bash
df -h {MONITOR_DISK_PATHS}
du -sh {path}/* | sort -rh | head -20
```

For each path:
- If usage >= MONITOR_DISK_THRESHOLD: trigger cleanup plan (Step 5)
- If usage >= (MONITOR_DISK_THRESHOLD - 5): warn (approaching threshold)

Additional container disk check:
```bash
docker system df
docker system df -v | grep -E "^[A-Z]|SIZE"
```

### Step 4: Alert Payload Triage (Webhook Mode)

When receiving an inbound alert payload (Grafana/Alertmanager/PagerDuty format):

```
Parse payload:
  - alert_name
  - severity (critical / warning / info)
  - affected_service
  - labels (env, region, pod, host)
  - annotations (description, runbook_url, dashboard_url)
  - starts_at timestamp
```

**Suppress if:** alert matches MONITOR_KNOWN_FP pattern (name + labels combination)

**Triage sequence:**
1. Search session history: `session_search("{alert_name} {affected_service}")`
   → Find past occurrences, root causes, resolutions
2. Check recent deployments: `git log --since="2 hours ago"` on affected service repo (if --workdir set)
3. Check recent config changes: look for config file modifications in the past hour
4. Cross-reference with current uptime check results

### Step 5: Disk Cleanup Plan

When disk usage exceeds threshold, generate:

```markdown
## Disk Cleanup Plan — {path} at {usage}%

### Immediate actions (safe to run)
1. Clear Docker build cache:
   docker builder prune -f
   docker image prune -f

2. Remove stopped containers:
   docker container prune -f

3. Truncate old journal logs (keep 7 days):
   journalctl --vacuum-time=7d

4. Clear old GitLab backups (keep last 3):
   ls -t /var/opt/gitlab/backups/*.tar | tail -n +4 | xargs rm -f

### Requires review before running
- Old Docker volumes: docker volume prune (check for data volumes first)
- Loki/Prometheus old chunks: confirm retention config before deleting
- Large log files in /var/log: identify owner before truncation

### Estimated recovery
{estimate based on du output}
```

### Step 6: Compose Triage Report

**Alert triage output format:**
```markdown
## Alert Triage — {alert_name}
**Time:** {timestamp}
**Service:** {affected_service}
**Severity:** {severity}

### Root Cause Hypothesis
{ranked list of likely causes based on past incidents and current state}
1. {most likely cause} — confidence: {high/medium/low}
2. {alternate cause}

### Evidence
- Endpoint check: {result}
- Disk usage: {result}
- Recent deploys: {list or "none in past 2 hours"}
- Past incidents: {found N similar incidents; last on {date}, resolved by {action}}

### First Response Steps
1. {immediate action — safe, non-destructive}
2. {second step}
3. {verification step}

### Escalation
{Escalate to: on-call engineer / team lead / vendor support}
{Escalate if: first response does not resolve within 15 minutes}

### Links
- Dashboard: {dashboard_url if available}
- Runbook: {runbook_url if available}
```

### Step 7: Deliver

- Send to MONITOR_ALERT_DELIVERY target
- Write to `MONITOR_INCIDENT_PATH/{date}-{alert_name}.md`

---

## Example Cron Commands

**Every 30 minutes uptime check:**
```bash
hermes cron create "*/30 * * * *" \
  --prompt "Run devops-monitor skill: uptime check only. Alert if any service is DOWN or DEGRADED." \
  --deliver telegram \
  --profile security-lab
```

**Daily disk usage report:**
```bash
hermes cron create "0 9 * * *" \
  --prompt "Run devops-monitor skill: disk usage check on all monitored paths. If any path >85%, generate cleanup plan." \
  --deliver telegram \
  --profile security-lab
```

**Every 2 hours full check:**
```bash
hermes cron create "0 */2 * * *" \
  --prompt "Run devops-monitor skill: full check — uptime, disk, Loki/Prometheus retention anomalies." \
  --deliver telegram \
  --profile security-lab
```

---

## Service Inventory Template (for MEMORY.md)

```markdown
## Service Inventory
| Service | URL | Expected Status | Runbook |
|---------|-----|----------------|---------|
| GitLab | https://gitlab.internal/-/health | 200 | ~/runbooks/gitlab.md |
| MinIO | http://minio.internal:9000/minio/health/live | 200 | ~/runbooks/minio.md |
| Grafana | http://grafana.internal:3000/api/health | 200 | ~/runbooks/grafana.md |
| Prometheus | http://prometheus.internal:9090/api/v1/query?query=up | 200 | ~/runbooks/prometheus.md |
| Loki | http://loki.internal:3100/ready | 200 | ~/runbooks/loki.md |

## Disk Thresholds
- Alert at: 85%
- Warning at: 80%
- Paths: /var/opt/gitlab/backups, /var/log/journal, /var/lib/docker

## Known False Positives
- Alert: "HighMemoryUsage" on gitlab-runner — normal during large CI jobs; suppress if < 30 min
- Alert: "MinIOStorageWarning" on Sunday 02:00–04:00 — weekly backup window
```

---

## Known Edge Cases

| Situation | Handling |
|-----------|---------|
| Cascading alerts (5+ alerts in < 2 min) | Group by root service; suppress derivatives; triage root cause only |
| Known false positive | Suppress and log; do not deliver alert; update FP list if new |
| SSH connection refused | Note connectivity failure as a potential symptom; do not retry infinitely |
| All services DOWN simultaneously | Likely network or DNS issue; check DNS resolution before per-service triage |
| Disk check shows 0% (mount not found) | Flag as `MOUNT_MISSING`; do not report as 0% used |
| Cleanup plan would delete > 10GB | Require explicit user confirmation before executing |

---

## Memory Integration

After each alert triage, update MEMORY.md with:
```
Incident pattern: {alert_name} on {service} — root cause: {cause}. Resolved by: {action}. Duration: {N} min.
```

This builds a local incident database that improves future triage accuracy.
