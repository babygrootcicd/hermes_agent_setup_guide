# Defense-in-Depth Security Architecture (深度防禦的安全架構)

Because Hermes Agent can operate the terminal, read local files, execute code, and interact with external services, it is designed with a multi-layered security model. This is not optional hardening — it is a core architectural decision.

---

## Why Security Is a First-Class Concern

Hermes agents typically have access to:

```text
- Local filesystem (read/write)
- Terminal execution (arbitrary commands)
- Browser automation (web interaction)
- Messaging platforms (sending/receiving)
- Cron scheduler (unattended execution)
- External APIs (LLM providers, GitHub, cloud services)
```

Without security controls, a single prompt injection or misconfigured agent can result in data exfiltration, system modification, or credential theft.

---

## The Seven-Layer Defense Model

### Layer 1: Dangerous Command Approval (危險指令攔截)

Before executing any potentially destructive command, Hermes:

1. Compares the command against a **dangerous pattern library**
2. Suspends execution
3. Shows the user the exact command to be run and why it was flagged
4. **Requires explicit user authorization** before proceeding

Examples of flagged patterns:

```bash
rm -rf /
dd if=/dev/zero of=/dev/sda
chmod -R 777 /
curl ... | bash
wget ... | sh
sudo visudo
```

This layer cannot be bypassed by prompt injection — the approval gate is enforced at the execution layer, not the prompt layer.

---

### Layer 2: Container Isolation (容器化隔離)

Hermes supports executing tools and commands inside hardened sandboxes:

**Docker backend:**

```yaml
terminal:
  backend: docker
  image: hermes-sandbox:latest
  timeout: 180
```

**Modal sandbox:**

```yaml
terminal:
  backend: modal
  timeout: 300
```

When using container isolation:
- The agent cannot directly access the host filesystem
- Bind mounts default to **read-only** for the project directory
- Network access can be restricted per sandbox policy
- Container is destroyed after each task or session

This prevents a rogue agent from permanently modifying or destroying the host environment even if it is instructed to.

**Read-only bind mount example:**

```yaml
terminal:
  backend: docker
  mounts:
    - source: /home/user/project
      target: /workspace
      readonly: true
```

---

### Layer 3: Context File Scanning (上下文檔案掃描)

Before any user-provided file, URL content, or tool output is injected into the agent's context, Hermes scans for:

**Prompt injection patterns:**
```text
- "Ignore all previous instructions"
- "Your new instructions are..."
- "Act as a different AI"
- "Disregard your safety guidelines"
```

**Credential exfiltration attempts:**
```text
- Instructions to read ~/.env, ~/.ssh/id_rsa, /etc/shadow
- curl / wget calls to external IPs with local file content
- base64 encoding of sensitive paths
- Data piped to external webhooks
```

**Malicious instruction hiding:**
```text
- Zero-width characters used to hide text
- Unicode bidirectional control characters
- HTML comment injection
- Whitespace-encoded payloads
```

When a suspicious pattern is detected, Hermes halts processing and alerts the user.

---

### Layer 4: Tool Permission Scoping

Tools can be enabled or disabled globally or per-profile. The principle of least privilege applies: only enable what a given profile actually needs.

```yaml
# Minimal tool configuration example
toolsets:
  enabled:
    - terminal
    - skills
    - web
  disabled:
    - browser_automation
    - code_execution
    - discord
    - home_assistant
```

Per-profile tool restriction:

```bash
# security-lab profile: no browser, no messaging write
hermes profile edit security-lab \
  --enable terminal,web,skills \
  --disable browser_automation,messaging_send
```

---

### Layer 5: Credential Isolation

Sensitive credentials are stored in:

```bash
~/.hermes/.env        # API keys, bot tokens
~/.hermes/auth.json   # OAuth credentials
```

These files are:
- Never injected into system prompts
- Never included in session exports by default
- Listed in `.gitignore` equivalents for backup commands

The `hermes backup` command explicitly excludes `.env` and `auth.json` from default exports.

---

### Layer 6: Sandbox Network Policy

When using Docker or Modal backends, network access for agent-executed code can be restricted:

```yaml
terminal:
  backend: docker
  network: none          # fully air-gapped sandbox
  # or
  network: restricted    # allowlist-based outbound only
  allowed_hosts:
    - api.github.com
    - registry.npmjs.org
```

This prevents agent-executed scripts from beaconing or exfiltrating data to external hosts.

---

### Layer 7: Audit Logging

All agent actions are logged to:

```bash
~/.hermes/logs/
```

Log types:

| Log file | Contents |
|----------|---------|
| `agent.log` | Tool calls, reasoning steps, model responses |
| `gateway.log` | Incoming/outgoing messages per platform |
| `error.log` | Failures, approval denials, scan alerts |
| `cron.log` | Scheduled task execution records |

Logs can be exported for security auditing:

```bash
hermes logs export --since 2025-01-01 --output ~/audit/hermes-logs.tar.gz
```

---

## Configuration Baseline (Recommended)

```yaml
terminal:
  backend: docker
  timeout: 180

memory:
  memory_enabled: true
  user_profile_enabled: true

security:
  dangerous_command_approval: true
  context_scan_enabled: true
  prompt_injection_detection: true

toolsets:
  enabled:
    - terminal
    - skills
    - web
  disabled:
    - browser_automation
    - code_execution
```

---

## What NOT to Back Up or Share

The following files must never be committed to public repositories, shared in team drives, or included in unencrypted backups:

```text
~/.hermes/.env                    # API keys / bot tokens
~/.hermes/auth.json               # OAuth credentials
~/.hermes/state.db                # Full session history (may contain sensitive context)
~/.hermes/sessions/               # Raw session JSONL (ditto)
Any skill or memory file containing:
  - API keys
  - Bot tokens
  - Internal IP addresses
  - SSH key paths or contents
  - Customer names or PII
  - Internal network topology
```

---

## Threat Model Summary

| Threat | Mitigation |
|--------|-----------|
| Prompt injection via external content | Context file scanning (Layer 3) |
| Rogue agent destroying host filesystem | Container isolation + read-only mounts (Layer 2) |
| Credential theft via agent-executed curl | Dangerous command approval + network policy (Layers 1, 6) |
| Unintended destructive commands | Dangerous command approval gate (Layer 1) |
| Overprivileged agent | Tool permission scoping (Layer 4) |
| Credential leakage via memory injection | Credential isolation (Layer 5) |
| Unaudited agent actions | Audit logging (Layer 7) |

---

## Security Recommendations for DevSecOps Use

For high-sensitivity projects (internal infrastructure, client data, security tooling):

```text
1. Use local model (Ollama) or internal LLM gateway — avoid cloud providers
2. Enable Docker backend for all terminal execution
3. Disable browser automation unless explicitly needed
4. Keep .env and auth.json out of all shared backups
5. Regularly export sessions as JSONL and redact before archiving
6. Use separate profiles for coding vs personal vs client work
7. Set max_turns low (12–20) to prevent runaway agent loops
8. Review ~/.hermes/logs/agent.log after any automated cron run
```

---

## References

- [Configuration — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- [FAQ & Troubleshooting](https://hermes-agent.nousresearch.com/docs/reference/faq)
- [CLI Commands Reference](https://hermes-agent.nousresearch.com/docs/reference/cli-commands)
