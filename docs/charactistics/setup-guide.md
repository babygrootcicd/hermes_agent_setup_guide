# Hermes Agent — Quick-Start Setup Guide

This guide takes you from zero to a working Hermes Agent session. Follow the sections in order on your first install.

---

## 1. Prerequisites

Verify each dependency before installing.

### Python 3.10 or higher

```bash
python3 --version
# Expected: Python 3.10.x or higher
```

If missing (macOS):

```bash
brew install python@3.12
```

If missing (Ubuntu/Debian):

```bash
sudo apt update && sudo apt install python3.12 python3.12-pip -y
```

### pip

```bash
pip3 --version
# Expected: pip 23.x or higher
```

Upgrade if outdated:

```bash
pip3 install --upgrade pip
```

### git

```bash
git --version
# Expected: git version 2.x
```

Install if missing:

```bash
# macOS
brew install git

# Ubuntu
sudo apt install git -y
```

### Ollama (optional — for local/offline inference)

Only required if you plan to run a local model without cloud API access.

```bash
# macOS / Linux installer
curl -fsSL https://ollama.com/install.sh | sh

# Verify
ollama --version
```

### Node.js (optional — for the Electron desktop app only)

```bash
node --version
# Expected: v18.x or higher

npm --version
```

Install via [https://nodejs.org](https://nodejs.org) or:

```bash
brew install node
```

---

## 2. Installation

Choose either the pip install (recommended for most users) or the GitHub source install (for development or the latest unreleased features).

### Method A: pip (Recommended)

```bash
pip3 install hermes-agent
```

Verify the install:

```bash
hermes --version
```

You should see output like:

```
Hermes Agent v0.x.x
```

### Method B: Clone from GitHub

```bash
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
pip3 install -e .
```

Verify:

```bash
hermes --version
```

### Method C: pipx (Isolated environment — avoids dependency conflicts)

```bash
pip3 install pipx
pipx install hermes-agent
```

---

## 3. First Run — Provider Setup Wizard

Never run `hermes chat` before configuring a provider. The first command to run is always:

```bash
hermes model
```

### What the wizard does

1. Detects any existing provider config
2. Presents a list of supported providers (Gemini, Copilot, Anthropic, OpenAI Codex, Ollama/custom)
3. Prompts for API key entry or runs an OAuth device-code flow
4. Writes credentials to `~/.hermes/.env` and `~/.hermes/auth.json`
5. Sets the default model and context length in `~/.hermes/config.yaml`

### What you will see on first launch

When you run `hermes model` for the first time, Hermes will:

```
Initializing Hermes Agent...
Creating ~/.hermes/ directory structure...
Loading bundled skills (74 found)...
Scanning toolsets (29 tools available)...
Initializing memory store...
  Created ~/.hermes/memories/MEMORY.md
  Created ~/.hermes/memories/USER.md
  Created ~/.hermes/state.db

No provider configured. Running setup wizard...
```

> **Warning you may see:**
> ```
> Nous Hermes 3 / 4 models are NOT agentic and are not designed for Hermes Agent.
> ```
> This appears if you pass `--model hermes3`. Do not use `hermes3`. Use the wizard to pick a proper agentic provider.

---

## 4. Choosing Your First Provider

Use this decision table to pick the right provider on your first run:

| Situation | Recommended provider | Setup path |
|-----------|---------------------|-----------|
| You have GitHub Copilot | `copilot` | OAuth device code via `hermes model` |
| You want free cloud quota | `gemini` (Google AI Studio free tier) | API key from [aistudio.google.com](https://aistudio.google.com) |
| You want fully private / offline | `custom` (Ollama local) | Run Ollama first, then enter endpoint in wizard |
| You have Anthropic API key | `anthropic` | API key entry in wizard |
| You want to test quickly (policy risk) | `google-gemini-cli` (OAuth) | OAuth device code via `hermes model` |

For full provider comparison, see [09-provider-selection.md](09-provider-selection.md).

### Gemini Free Tier (most common first choice)

1. Go to [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Create a free API key
3. Run `hermes model` → select **Google Gemini API key** → paste key
4. Select model: `gemini-2.5-flash`
5. Set context length: `32768`

### GitHub Copilot

1. Run `hermes model` → select **GitHub Copilot**
2. A device code URL will be printed — open it in your browser and authorize
3. Select model: `gpt-4o` (or `claude-sonnet-4-5` via Copilot)

### Ollama (local)

```bash
# Pull a tool-calling capable model first
ollama pull qwen2.5-coder:7b

# Start Ollama server with the right context size
OLLAMA_CONTEXT_LENGTH=32768 ollama serve
```

Then run `hermes model` → select **Custom endpoint** → enter:

```
URL:            http://localhost:11434/v1
API key:        ollama
Model:          qwen2.5-coder:7b
Context length: 32768
```

---

## 5. First Chat Session

After provider setup, start a minimal session:

```bash
hermes chat --toolsets terminal,skills --max-turns 12
```

### Flags explained

| Flag | What it does |
|------|-------------|
| `--toolsets terminal,skills` | Load only terminal execution + skill retrieval (fastest startup) |
| `--max-turns 12` | Prevent runaway loops; increase to 20–30 for complex tasks |

### What you will see in the UI

```
╔══════════════════════════════════════════════════════════════╗
║  Hermes Agent                              Session: 20260429_...  ║
║  Provider: gemini / gemini-2.5-flash       Memory: loaded    ║
║  Tools: terminal (1), skills (74)          Turns: 0/12       ║
╚══════════════════════════════════════════════════════════════╝

hermes> _
```

Key elements:
- **Session ID** — shown top-right; copy this for `--resume` later
- **Memory: loaded** — confirms `MEMORY.md` and `USER.md` were injected
- **Tools** — number of tools active
- **Turns** — current/max turn counter

### Your first test prompt

```text
hermes> What tools do you have available right now?
```

Hermes should list the active toolsets and describe what each can do. This confirms tool loading is working correctly.

---

## 6. Verifying Memory Works

This five-step test confirms the persistence system is functioning.

### Step 1 — Write a test memory entry

Inside the Hermes session:

```bash
/memory add "Test: setup guide verification entry — written on first install"
```

Expected response:

```
Memory written to ~/.hermes/memories/MEMORY.md
Note: new memory takes effect in next session.
```

### Step 2 — Exit cleanly

```bash
/quit
```

Hermes prints:

```
Session saved. Resume with:
  hermes chat --resume 20260429_...
```

### Step 3 — Start a new session

```bash
hermes chat --toolsets terminal,skills --max-turns 6
```

### Step 4 — Verify the memory was loaded

```bash
/memory show
```

You should see your test entry in the output. If it appears, memory persistence is working correctly.

### Step 5 — Clean up the test entry

```bash
/memory remove "Test: setup guide verification entry — written on first install"
```

---

## 7. Setting Up Your First Cron Job

A daily briefing is the most useful first automation.

### Exit the current session first

```bash
/quit
```

### Create the cron job

```bash
hermes cron create "0 8 * * *" \
  --prompt "
    Search for today's top news in:
    1. AI agent tools and frameworks
    2. Open-source LLM releases
    3. Cloud security news
    Summarize each section in 2–3 bullet points.
    Include source links.
    Keep total length under 400 words.
  " \
  --deliver telegram
```

Replace `--deliver telegram` with `--deliver discord` or remove it entirely to save output to cron logs only.

### Verify the job was created

```bash
hermes cron list
```

### Test it immediately without waiting for 8am

```bash
hermes cron run <job-id>
```

### View output

```bash
hermes cron logs <job-id>
```

For full cron documentation, see [03-multi-platform-and-automation.md](03-multi-platform-and-automation.md).

---

## 8. Next Steps

Now that Hermes is running, explore these topics in depth:

| Topic | File | Read when... |
|-------|------|-------------|
| How skills are created and reused | [01-self-evolution-and-skills.md](01-self-evolution-and-skills.md) | You want Hermes to remember how to do things |
| How memory works in detail | [02-persistent-memory.md](02-persistent-memory.md) | You want to tune what Hermes knows about you |
| Telegram/Discord gateway + cron | [03-multi-platform-and-automation.md](03-multi-platform-and-automation.md) | You want to command Hermes from your phone |
| Security hardening | [04-security-architecture.md](04-security-architecture.md) | You're handling sensitive data |
| Switching between 200+ models | [05-model-agnosticism.md](05-model-agnosticism.md) | You want to compare providers |
| Where all data is stored | [06-storage-layout.md](06-storage-layout.md) | You want to back up or export your data |
| Everyday task automation recipes | [07-everyday-tasks.md](07-everyday-tasks.md) | You want daily briefing, GitHub triage, Gmail digest |
| Running 4 isolated profiles | [08-profile-design.md](08-profile-design.md) | You want separate personal/coder/security/study contexts |
| Full provider comparison + speed tips | [09-provider-selection.md](09-provider-selection.md) | Your sessions are slow or expensive |
| Resuming sessions, tmux, services | [10-session-management.md](10-session-management.md) | You want to keep Hermes running after terminal close |

---

## 9. Troubleshooting Quick Reference

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| **Very slow first token (30s+)** | Using `--model hermes3` — not an agentic model; 131K context on local hardware | Exit with `/quit`, run `hermes model`, select Gemini or Copilot; set `context_length: 32768` |
| **Memory not loading in new session** | Memory written mid-session; not yet injected | Normal behavior — memory takes effect on the *next* session start. Run `/memory show` after restarting |
| **Tool calls fail / JSON parse errors** | Model not designed for tool use | Switch to a tool-calling model: `gemini-2.5-flash`, `gpt-4o`, or `qwen2.5-coder:7b` via Ollama |
| **Context window error / truncation** | `context_length` set too high for available VRAM | In `~/.hermes/config.yaml`, set `context_length: 32768`. Never use 131072 on local models |
| **Telegram/Discord gateway not responding after restart** | Gateway started as foreground process; died with terminal | Install as a service: `hermes gateway install --platform telegram --service launchd` (macOS) or `--service systemd` (Linux) |
| **`hermes: command not found`** | pip install target not on PATH | Add `~/.local/bin` to PATH: `export PATH="$HOME/.local/bin:$PATH"` in `~/.zshrc` or `~/.bashrc` |
| **`hermes model` not available inside chat** | `/model` (slash) is different from `hermes model` (shell) | Exit the chat first with `/quit`, then run `hermes model` from your shell |
| **Skills not matching / not applying** | Skills stored in different profile | Check active profile: `hermes profile current`. Switch with `hermes profile use <name>` |

---

## References

- [GitHub — NousResearch/hermes-agent](https://github.com/nousresearch/hermes-agent)
- [Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs)
- [Provider Setup](09-provider-selection.md)
- [Session Management](10-session-management.md)
- [Security Architecture](04-security-architecture.md)
