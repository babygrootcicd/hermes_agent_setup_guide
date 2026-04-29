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
DEFAULT_PROVIDER="gemini"
DEFAULT_MODEL="gemini-2.5-flash"
DEFAULT_CONTEXT_LENGTH="32768"

upsert_env_var() {
  local key="$1"
  local value="$2"
  local file="$3"
  local escaped_value

  mkdir -p "$(dirname "${file}")"
  touch "${file}"
  chmod 600 "${file}" 2>/dev/null || true

  escaped_value=$(printf '%s' "${value}" | sed -e 's/[&|\\]/\\&/g')
  if grep -q "^${key}=" "${file}" 2>/dev/null; then
    sed -i '' "s|^${key}=.*|${key}=${escaped_value}|" "${file}"
  else
    printf '%s=%s\n' "${key}" "${value}" >> "${file}"
  fi
}

write_model_config() {
  local provider="$1"
  local model="$2"
  local context_length="$3"
  local tmp_file

  mkdir -p "${HERMES_DIR}"
  touch "${HERMES_CONFIG}"

  tmp_file="$(mktemp "${TMPDIR:-/tmp}/hermes-config.XXXXXX")"
  awk -v provider="${provider}" -v model="${model}" -v context="${context_length}" '
    function emit_model_block() {
      print "model:"
      print "  provider: " provider
      print "  default: " model
      print "  api_key: \"${GOOGLE_API_KEY}\""
      print "  context_length: " context
    }
    BEGIN {
      in_model_block = 0
      replaced = 0
    }
    {
      if ($0 ~ /^model:[[:space:]]*$/) {
        if (!replaced) {
          emit_model_block()
          replaced = 1
        }
        in_model_block = 1
        next
      }

      if (in_model_block) {
        if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]*$/) {
          in_model_block = 0
          print $0
        }
        next
      }

      print $0
    }
    END {
      if (!replaced) {
        if (NR > 0) {
          print ""
        }
        emit_model_block()
      }
    }
  ' "${HERMES_CONFIG}" > "${tmp_file}"
  mv "${tmp_file}" "${HERMES_CONFIG}"
}

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
    read -rsp "Paste your Gemini API key here: " API_KEY
    echo ""
    if [[ -z "${API_KEY}" ]]; then
      error "No API key entered. Aborting."
    fi

    upsert_env_var "GOOGLE_API_KEY" "${API_KEY}" "${HERMES_ENV}"
    success "API key written to ${HERMES_ENV}"

    PROVIDER="${DEFAULT_PROVIDER}"
    MODEL="${DEFAULT_MODEL}"
    write_model_config "${PROVIDER}" "${MODEL}" "${DEFAULT_CONTEXT_LENGTH}"
    success "Config updated in ${HERMES_CONFIG}"
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
    MODEL="${DEFAULT_MODEL}"

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
if hermes chat --help 2>/dev/null | grep -q -- "--prompt"; then
  if hermes chat \
      --provider "${PROVIDER}" \
      --model "${MODEL}" \
      --max-turns 1 \
      --toolsets skills \
      --prompt "Reply with exactly: Gemini is working"; then
    echo ""
    success "Smoke test passed."
  else
    echo ""
    warn "Smoke test exited non-zero — check the output above for errors."
  fi
else
  echo ""
  warn "Skipping automated smoke test: this Hermes build does not expose --prompt."
  info "Run manually: hermes chat --provider ${PROVIDER} --model ${MODEL} --toolsets terminal,skills"
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
