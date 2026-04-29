#!/usr/bin/env bash
# scripts/macos/setup-provider-gemini.sh
# Configure Hermes Agent to use Google Gemini as the LLM backend.

set -euo pipefail

# --- UI helpers (matches project style) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()    { echo -e "\n${CYAN}==> $*${NC}"; }

HERMES_DIR="${HOME}/.hermes"
HERMES_ENV="${HERMES_DIR}/.env"
HERMES_CONFIG="${HERMES_DIR}/config.yaml"

# ── Header ────────────────────────────────────────────────────────────────────
echo -e "${GREEN}"
echo "======================================================"
echo "   Hermes Agent — Google Gemini Provider Setup"
echo "======================================================"
echo -e "${NC}"

# ── 1. Check Hermes installation ──────────────────────────────────────────────
step "Checking Hermes Agent installation"
if ! command -v hermes &> /dev/null; then
  warn "hermes command not found."
  echo ""
  echo "Install Hermes Agent with:"
  echo -e "  ${GREEN}curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash${NC}"
  echo ""
  echo "Then re-run this script."
  exit 1
fi
HERMES_VER=$(hermes --version 2>/dev/null || echo "unknown")
success "Hermes Agent found: ${HERMES_VER}"

# ── 2. Ensure ~/.hermes exists ────────────────────────────────────────────────
mkdir -p "${HERMES_DIR}"

# ── 3. Choose setup path ──────────────────────────────────────────────────────
step "Choose Gemini connection method"
echo ""
echo "  A) Gemini API Key  [RECOMMENDED]"
echo "     • Uses your own key from Google AI Studio"
echo "     • No Google policy risk"
echo "     • Free tier available"
echo ""
echo "  B) Gemini OAuth (google-gemini-cli)  [TESTING ONLY]"
echo "     • Uses Google Cloud Code Assist backend"
echo "     • WARNING: Google may treat third-party use as a policy violation"
echo "     • Free personal account tier"
echo ""
read -rp "Choose option [A/B, default A]: " CHOICE
CHOICE="${CHOICE:-A}"

case "${CHOICE^^}" in

  A)
    # ── Option A: API Key ────────────────────────────────────────────────────
    step "Gemini API Key setup"
    echo ""
    echo "Get your free API key at:"
    echo -e "  ${CYAN}https://aistudio.google.com/apikey${NC}"
    echo ""
    read -rp "Paste your Gemini API key here: " API_KEY
    if [[ -z "${API_KEY}" ]]; then
      error "No API key entered. Aborting."
    fi

    # Append to .env (do not overwrite other keys)
    if grep -q "^GOOGLE_API_KEY=" "${HERMES_ENV}" 2>/dev/null; then
      warn "GOOGLE_API_KEY already present in ${HERMES_ENV} — updating."
      sed -i '' "s|^GOOGLE_API_KEY=.*|GOOGLE_API_KEY=${API_KEY}|" "${HERMES_ENV}"
    else
      echo "GOOGLE_API_KEY=${API_KEY}" >> "${HERMES_ENV}"
    fi
    success "API key written to ${HERMES_ENV}"

    PROVIDER="gemini"
    MODEL="gemini-2.5-flash"

    # Write config block
    if [[ -f "${HERMES_CONFIG}" ]] && grep -q "^model:" "${HERMES_CONFIG}"; then
      warn "${HERMES_CONFIG} already has a model section — please merge manually:"
      echo ""
      echo "model:"
      echo "  provider: gemini"
      echo "  default: gemini-2.5-flash"
      echo "  api_key: \"\${GOOGLE_API_KEY}\""
      echo "  context_length: 32768"
    else
      cat >> "${HERMES_CONFIG}" <<'YAML'

model:
  provider: gemini
  default: gemini-2.5-flash
  api_key: "${GOOGLE_API_KEY}"
  context_length: 32768

agent:
  max_turns: 20

toolsets:
  enabled:
    - terminal
    - web
    - skills
    - memory
YAML
      success "Config written to ${HERMES_CONFIG}"
    fi
    ;;

  B)
    # ── Option B: OAuth ──────────────────────────────────────────────────────
    step "Gemini OAuth setup"
    echo ""
    warn "POLICY RISK: Google may treat use of the Gemini CLI OAuth client"
    warn "in third-party software as a violation of their Terms of Service."
    warn "Use this path for short-term testing only."
    echo ""
    read -rp "Proceed anyway? [y/N]: " CONFIRM
    if [[ "${CONFIRM^^}" != "Y" ]]; then
      info "Aborted. Re-run and choose option A for the API key path."
      exit 0
    fi

    PROVIDER="google-gemini-cli"
    MODEL="gemini-2.5-flash"

    info "Launching hermes model wizard — follow the prompts to complete OAuth..."
    hermes model
    success "OAuth flow completed."
    ;;

  *)
    error "Invalid choice '${CHOICE}'. Re-run and enter A or B."
    ;;
esac

# ── 4. Smoke test ─────────────────────────────────────────────────────────────
step "Running smoke test"
echo ""
info "Sending test message to ${PROVIDER} / ${MODEL} ..."
echo ""
if hermes chat \
    --provider "${PROVIDER}" \
    --model    "${MODEL}" \
    --max-turns 1 \
    --toolsets skills \
    --prompt   "Reply with exactly: Gemini is working"; then
  echo ""
  success "Smoke test passed."
else
  echo ""
  warn "Smoke test exited non-zero — check the output above for errors."
fi

# ── 5. Next steps ─────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}======================================================"
echo "   Setup complete!"
echo "======================================================${NC}"
echo ""
echo "Start a session:"
echo -e "  ${GREEN}hermes chat --provider ${PROVIDER} --model ${MODEL} --toolsets terminal,skills${NC}"
echo ""
echo "Or set this provider as default and just run:"
echo -e "  ${GREEN}hermes chat${NC}"
echo ""
echo "See docs/charactistics/09-provider-selection.md for tuning tips."
