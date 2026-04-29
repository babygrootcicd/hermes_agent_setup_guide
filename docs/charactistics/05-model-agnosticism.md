# Model Agnosticism & Data Privacy (跨模型支援與資料隱私)

Hermes is not locked to any single LLM provider. It supports over 200 models via OpenRouter, all major cloud APIs directly, and fully offline local inference via Ollama. This flexibility enables both cost optimization and data sovereignty.

---

## Supported Provider Categories

### 1. Cloud Providers (Direct API)

| Provider | Notes |
|----------|-------|
| **Anthropic (Claude)** | Requires Claude Max + extra usage credits for OAuth; standard `ANTHROPIC_API_KEY` for API billing |
| **OpenAI** | Standard API key; ChatGPT subscription does NOT grant free API access |
| **Google Gemini** | Via API key (`GOOGLE_API_KEY` / `GEMINI_API_KEY`) or Google Cloud Code Assist OAuth |
| **DeepSeek** | Via API key |
| **Mistral** | Via API key |

### 2. Aggregator / Routing

| Provider | Notes |
|----------|-------|
| **OpenRouter** | Access to 200+ models from a single API key; good for model diversity |
| **GitHub Copilot** | Uses Copilot subscription; can access GPT, Claude, Gemini via Copilot API |
| **OpenAI Codex** | Separate from ChatGPT; device-code OAuth; imports `~/.codex/auth.json` |

### 3. Local / Self-Hosted

| Provider | Notes |
|----------|-------|
| **Ollama** | Fully offline; OpenAI-compatible endpoint at `http://localhost:11434/v1` |
| **LM Studio** | Desktop GUI for local models; same OpenAI-compatible API |
| **vLLM** | High-throughput local inference server |
| **llama.cpp server** | Lightweight local server |
| **SGLang** | Structured generation local server |
| **LocalAI** | Drop-in OpenAI-compatible local backend |
| **Custom endpoint** | Any endpoint that supports OpenAI-compatible `/v1/chat/completions` |

---

## Switching Providers

### Interactive Setup Wizard

```bash
hermes model
```

This launches the full provider setup wizard. Options include:
- Adding a new provider
- Running OAuth device code flow
- Entering an API key
- Configuring a custom endpoint URL and model name

**Note:** Run `hermes model` from the shell, not from inside a Hermes chat session. Inside a session, `/model` only switches between already-configured providers.

### Manual Configuration

Edit `~/.hermes/config.yaml`:

```yaml
model:
  provider: gemini
  default: gemini-2.5-flash
  api_key: "${GOOGLE_API_KEY}"
  context_length: 32768
```

For Ollama:

```yaml
model:
  provider: custom
  default: qwen2.5-coder:7b
  base_url: http://localhost:11434/v1
  api_key: ollama
  context_length: 32768
```

---

## Local-First ≠ Fully Air-Gapped

This is an important distinction:

- **Hermes itself** collects no telemetry or analytics
- **Conversations, memory, and skills** are stored locally at `~/.hermes/`
- **LLM API calls** are sent to whichever provider you configure

If you use OpenRouter, OpenAI, Anthropic, or Google, the content of `MEMORY.md` and `USER.md` (injected into the system prompt) is transmitted to that provider's servers.

**To achieve true local inference:**

```bash
# Pull a capable tool-use model
ollama pull qwen2.5-coder:7b

# Set context length at the server level
OLLAMA_CONTEXT_LENGTH=32768 ollama serve
```

Then configure Hermes to use it:

```yaml
model:
  provider: custom
  default: qwen2.5-coder:7b
  base_url: http://localhost:11434/v1
  api_key: ollama
  context_length: 32768
```

With this setup, no data leaves your machine during inference.

---

## Data Privacy Architecture

| Data type | Where it lives | Who can see it |
|-----------|---------------|---------------|
| `MEMORY.md` / `USER.md` | `~/.hermes/memories/` | You + LLM provider (injected in prompts) |
| `state.db` (session history) | `~/.hermes/state.db` | You only (local SQLite) |
| `skills/` | `~/.hermes/skills/` | You only (local files) |
| `.env` (API keys) | `~/.hermes/.env` | You only (never injected into prompts) |
| `auth.json` (OAuth tokens) | `~/.hermes/auth.json` | You only (never injected into prompts) |
| Cron outputs | `~/.hermes/cron/` | You only (local) |
| LLM API calls | In-flight to provider | You + LLM provider |

---

## Enterprise Data Security

Hermes is MIT-licensed and fully open-source. Enterprises can:

1. **Self-host the agent** on internal infrastructure
2. **Connect directly via OAuth** to their LLM provider (no intermediary server)
3. **Use an internal LLM gateway** (e.g., Azure OpenAI, private Bedrock endpoint) as a custom endpoint
4. **Audit all traffic** because the agent codebase is fully readable and modifiable

```yaml
# Example: enterprise internal LLM gateway
model:
  provider: custom
  default: gpt-4o
  base_url: https://internal-llm-gateway.corp.example.com/v1
  api_key: "${INTERNAL_LLM_API_KEY}"
  context_length: 128000
```

This eliminates the need to route sensitive data through any third-party intermediary.

---

## Model Selection Guidance by Use Case

| Use case | Recommended model type | Notes |
|----------|----------------------|-------|
| General everyday assistant | Gemini 2.5 Flash / GPT-4o mini | Fast, cheap, good tool calling |
| Coding & DevOps | Claude Sonnet / GPT-4o / Qwen2.5-Coder | Strong code understanding |
| Security-sensitive tasks | Local Ollama model | No data leaves machine |
| Long context analysis | Gemini 2.5 Pro / Claude Opus | 1M+ token context |
| Offline / air-gapped | Ollama (Qwen Coder 7B–14B) | Requires capable hardware |
| Cost-free daily use | Gemini API free tier / Copilot subscription | See provider selection guide |

---

## Context Length Considerations

Running very large context windows on local models is expensive:

| Context length | Appropriate for |
|---------------|----------------|
| 8K–16K | Simple task completion, Q&A |
| 32K | Most agentic tasks; recommended for local models |
| 64K–128K | Long document analysis; cloud models only |
| 131K+ | Avoid on local models; degrades prefill speed dramatically |

For local inference, 32K context is the practical sweet spot:

```yaml
model:
  context_length: 32768
```

---

## References

- [AI Providers — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/integrations/providers)
- [Configuration — Hermes Agent Docs](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)
- [FAQ & Troubleshooting](https://hermes-agent.nousresearch.com/docs/reference/faq)
- [Gemini API Pricing (free tier)](https://ai.google.dev/gemini-api/docs/pricing)
