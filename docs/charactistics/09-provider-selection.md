# Provider & Model Selection Guide

Choosing the right LLM provider for Hermes has a large impact on response latency, cost, tool-calling reliability, and data privacy. This guide covers every provider option, their trade-offs, setup steps, and speed optimization strategies.

---

## Why `--model hermes3` Is Not Suitable for Agentic Use

The Hermes 3 and Hermes 4 base models are conversational language models, **not** agentic models. Hermes itself displays this warning:

```
Nous Hermes 3 / 4 models are NOT agentic and are not designed for Hermes Agent.
```

Running `hermes chat --model hermes3` causes multiple compounding problems:

| Problem | Impact |
|---------|--------|
| Model not designed for tool calling | Unreliable tool invocations, malformed JSON |
| 131K context on local model | Extreme prefill latency; KV cache pressure |
| 29 tools + 74 skills all loaded | Tool schema inflates system prompt dramatically |
| Browser / cron / discord toolsets all active | First-token time is very slow even before model inference |
| Low-VRAM or Intel Mac hardware | 32B+ models with long context are not viable for real-time agent use |

**Fix:** Exit the session and run `hermes model` to configure a proper provider.

```bash
/quit
hermes model
```

---

## Provider Ranking by Practical Value

Ordered for users who want to avoid additional token billing while maximizing capability:

| Priority | Provider | Free / subscription cost | Speed | Notes |
|----------|----------|-------------------------|-------|-------|
| 1 | **Google Gemini API free tier** | Free (rate-limited) | Fast | Cleanest free option; use API key via `gemini` provider |
| 2 | **Google Gemini OAuth (CLI)** | Free (policy risk) | Fast | Uses Google Cloud Code Assist; personal account free tier; policy violation risk if used in third-party software |
| 3 | **GitHub Copilot provider** | Copilot subscription | Fast | Access GPT, Claude, Gemini via Copilot API; stable tool calling |
| 4 | **OpenAI Codex provider** | Codex / ChatGPT account | Fast | Device code OAuth; not a general ChatGPT API replacement |
| 5 | **Local Ollama (small model)** | Free | Medium–slow | No billing but requires capable hardware; choose tool-calling-capable models |
| 6 | **Anthropic (Claude)** | Claude Max + extra credits | Fast | Claude Pro insufficient; requires Max + overage credits or direct API key billing |

---

## Provider Setup

### Setup Command

Always run from the shell — not inside a Hermes chat session:

```bash
hermes model
```

This launches an interactive wizard with options to:
- Add or switch provider
- Run OAuth device code flow
- Enter API key manually
- Configure a custom endpoint URL and model

Inside an active session, `/model` only switches between already-configured providers.

---

## Option 1: Google Gemini (Recommended Default)

### Two Sub-Options

**A. Gemini API Key (cleaner, recommended for long-term use)**

```bash
hermes model
# Select: Google Gemini API key
# Enter: your GOOGLE_API_KEY or GEMINI_API_KEY
```

Or manually in `config.yaml`:

```yaml
model:
  provider: gemini
  default: gemini-2.5-flash
  api_key: "${GOOGLE_API_KEY}"
  context_length: 32768
```

Get a free API key at [Google AI Studio](https://aistudio.google.com). The Gemini API free tier includes multiple models.

**B. Google Gemini CLI OAuth (quicker setup, policy risk)**

```bash
hermes model
# Select: Google Gemini OAuth / google-gemini-cli
# Follow OAuth device code flow
```

Hermes uses the Google Cloud Code Assist backend. Personal accounts get a free tier automatically provisioned. **However**, Google may treat use of the Gemini CLI OAuth client in third-party software as a policy violation. Use for short-term testing; switch to an API key for production use.

### Starting a Session with Gemini

```bash
# General assistant
hermes chat \
  --provider google-gemini-cli \
  --model gemini-2.5-flash \
  --toolsets terminal,skills,web \
  --max-turns 20

# Minimal (no browser, no cron, fastest)
hermes chat \
  --provider google-gemini-cli \
  --model gemini-2.5-flash \
  --toolsets terminal,skills \
  --max-turns 12
```

### Gemini Model Options

| Model | Best for | Context |
|-------|----------|---------|
| `gemini-2.5-flash` | Fast everyday tasks; best latency | 1M tokens |
| `gemini-2.5-pro` | Complex reasoning, long documents | 1M tokens |
| `gemini-2.0-flash` | Very low latency; slightly lower capability | 1M tokens |

---

## Option 2: GitHub Copilot (Best for Copilot Subscribers)

If you already pay for GitHub Copilot, this is the most cost-effective option with the best tool-calling reliability.

**What it provides:**
- Access to GPT-4o, Claude Sonnet, Gemini via Copilot API
- Uses your existing Copilot subscription (no extra billing)
- Stable, production-quality tool calling
- Low latency (cloud inference)

### Setup

```bash
hermes model
# Select: GitHub Copilot
# Follow OAuth device code login
```

### Starting a Session with Copilot

```bash
hermes chat \
  --provider copilot \
  --model gpt-4o \
  --toolsets terminal,web,skills \
  --max-turns 20
```

Or select Claude via Copilot:

```bash
hermes chat \
  --provider copilot \
  --model claude-sonnet-4-5 \
  --toolsets terminal,web,skills \
  --max-turns 20
```

**Advantages over local models:**
- No GPU/VRAM pressure on local machine
- Tool calling is more reliable than most local models
- Latency is dramatically lower than large local models
- Utilizes already-paid Copilot subscription

---

## Option 3: OpenAI Codex Provider

**Important distinction:** ChatGPT Plus / Pro subscriptions **do not** grant free access to the OpenAI API. API billing is separate.

However, Hermes includes an **OpenAI Codex provider** that authenticates via device code OAuth and can import `~/.codex/auth.json`. This is separate from the general OpenAI API.

```bash
hermes model
# Select: OpenAI Codex
# Follow OAuth device code flow
```

**Limitations:**
- Not a general-purpose OpenAI API replacement
- Treat it as a Codex/ChatGPT OAuth-backed provider with limited scope
- Do not attempt to use browser automation to control ChatGPT web UI as a backend — this is unstable, slow, cannot do tool calling reliably, and violates platform policies

---

## Option 4: Anthropic (Claude)

### Important Constraint

Hermes requires **Claude Max subscription + extra usage credits** for the OAuth path. Claude Pro is insufficient.

| Subscription | Hermes compatible? |
|-------------|-------------------|
| Claude Pro | No — cannot use Hermes OAuth path |
| Claude Max (no extra credits) | No — base Max allowance is not consumed by Hermes |
| Claude Max + extra usage credits | Yes — Hermes consumes extra credits |
| Standard `ANTHROPIC_API_KEY` | Yes — standard API token billing |

**Recommended split:**
```text
Claude Code CLI → use for coding (covered by Max subscription)
Hermes          → use Gemini or Copilot as backend (avoid extra Claude billing)
```

If you do want to use Claude as the Hermes backend via API key:

```yaml
model:
  provider: anthropic
  default: claude-sonnet-4-5
  api_key: "${ANTHROPIC_API_KEY}"
  context_length: 64000
```

---

## Option 5: Local Ollama

Best for: privacy-sensitive tasks, air-gapped environments, zero API costs.

### Setup

```bash
# Pull a tool-calling capable model
ollama pull qwen2.5-coder:7b

# Set context length at server level (important — not just in config)
OLLAMA_CONTEXT_LENGTH=32768 ollama serve
```

### Configure Hermes

**Via wizard:**

```bash
hermes model
# Select: Custom endpoint
# URL: http://localhost:11434/v1
# API key: ollama (or leave empty)
# Model: qwen2.5-coder:7b
# Context length: 32768
```

**Via config.yaml:**

```yaml
model:
  provider: custom
  default: qwen2.5-coder:7b
  base_url: http://localhost:11434/v1
  api_key: ollama
  context_length: 32768

agent:
  max_turns: 20
```

### Model Size Guidance

| Model size | Appropriate for | Hardware requirement |
|-----------|----------------|---------------------|
| 7B coder | Tool calling tests, simple agentic tasks | 8GB+ RAM, any modern Mac |
| 14B coder | More capable agentic tasks; good accuracy | 16GB+ RAM / M1+ |
| 32B+ | High accuracy; long reasoning | Apple Silicon with 32GB+ RAM |
| 70B+ | Not viable for real-time local agent | Requires GPU server |

**Start small. Validate tool calling with 7B before upgrading.**

### Recommended Local Models for Agentic Use

| Model | Ollama pull command | Notes |
|-------|--------------------|----|
| Qwen2.5-Coder 7B | `ollama pull qwen2.5-coder:7b` | Best small model for tool calling |
| Qwen2.5-Coder 14B | `ollama pull qwen2.5-coder:14b` | Better accuracy, still manageable |
| Qwen2.5 7B | `ollama pull qwen2.5:7b` | Good general assistant |
| Mistral 7B Instruct | `ollama pull mistral:7b-instruct` | Fast; moderate tool calling |

Avoid: `hermes3`, `llama3`, `phi`, `gemma` for agentic tool use — these models have weak or unreliable tool-calling behavior.

---

## Speed Optimization

### 1. Reduce Tool Loading

Each enabled toolset adds tool schemas to the system prompt. Start minimal:

```bash
# Minimal — everyday Q&A and simple tasks
hermes chat --toolsets terminal,skills --max-turns 12

# Medium — add web search
hermes chat --toolsets web,terminal,skills --max-turns 20

# Full — only when you need browser automation
hermes chat --toolsets web,browser,terminal,file,skills --max-turns 30
```

### 2. Reduce Context Length

For local models, 131K context is extremely slow for prefill. Use 32K:

```yaml
model:
  context_length: 32768
```

Never use `context_length: 131072` for local models unless on a high-end GPU server.

### 3. Limit Delegation Depth

Subagent delegation multiplies costs. Depth 3, 3 children each = 27 concurrent leaf agents.

```yaml
delegation:
  max_concurrent_children: 1
  max_spawn_depth: 1
```

Increase only when you explicitly need multi-agent parallelism.

### 4. Set `max_turns`

Prevents runaway agent loops that burn tokens:

```yaml
agent:
  max_turns: 20
```

For complex multi-step tasks, increase to 30–50. For simple Q&A, 10–12 is sufficient.

---

## Recommended Final Architecture

### Everyday Assistant

```yaml
primary:
  provider: google-gemini-cli
  model: gemini-2.5-flash
  toolsets: [terminal, skills, web]

fallback:
  provider: custom (Ollama)
  model: qwen2.5-coder:7b
  context_length: 32768
```

### Coding & DevSecOps

```yaml
primary:
  provider: copilot          # if Copilot subscriber
  model: gpt-4o
  toolsets: [terminal, file, github, skills, web]

fallback:
  provider: custom (Ollama)
  model: qwen2.5-coder:14b
  context_length: 32768
```

### Security-Sensitive / Air-Gapped

```yaml
only:
  provider: custom (Ollama)
  model: qwen2.5-coder:14b
  context_length: 32768
  toolsets: [terminal, skills, web]
```

### Shortest Setup Path

```bash
# 1. Exit any current session
/quit

# 2. Configure provider
hermes model
# Recommended: Google Gemini OAuth or Gemini API key

# 3. Start with minimal toolset
hermes chat \
  --toolsets terminal,skills \
  --max-turns 12
```

---

## References

- [AI Providers — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/integrations/providers)
- [CLI Commands Reference](https://github.com/nousresearch/hermes-agent/blob/main/website/docs/reference/cli-commands.md)
- [Configuration — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- [Gemini API Free Tier Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [OpenAI API vs ChatGPT Subscription](https://help.openai.com/en/articles/8156019-how-can-i-move-my-chatgpt-subscription-to-the-api)
