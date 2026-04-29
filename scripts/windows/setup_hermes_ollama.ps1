# scripts/windows/setup_hermes_ollama.ps1
# Windows/WSL2 setup script for Hermes Agent + Ollama

$DefaultOllamaUrl = "http://127.0.0.1:11434/v1"
$DefaultModel = "qwen2.5-coder:7b"
$DefaultContextLength = "32768"

# --- UI Helpers ---
function Write-Info ($Message) { Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success ($Message) { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning ($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error ($Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Host "===============================================" -ForegroundColor Green
Write-Host "   Hermes Agent + Ollama Setup for Windows/WSL2" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# 1. Check for WSL2 installation
Write-Info "Checking for WSL2 installation..."
$wslCheck = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($null -eq $wslCheck) {
    Write-Error "WSL is not installed on this system."
    Write-Info "To install WSL2, please run the following command in an Administrator PowerShell:"
    Write-Host "    wsl --install" -ForegroundColor Cyan
    Write-Info "After installation, you MUST reboot your computer and then run this script again."
    exit 1
}

# Check if WSL is actually enabled/functional
try {
    $wslStatus = wsl --status 2>$null
    if ($null -eq $wslStatus) {
        throw "WSL status check failed."
    }
} catch {
    Write-Warning "WSL is present but may not be fully configured."
    Write-Info "Please ensure 'Virtual Machine Platform' and 'Windows Subsystem for Linux' features are enabled."
}

Write-Success "WSL2 is available."

# 2. Check for Linux Distribution
Write-Info "Checking for a Linux distribution..."
$distroList = wsl --list --quiet 2>$null
if ($null -eq $distroList -or $distroList.Count -eq 0) {
    Write-Error "No WSL distributions found."
    Write-Info "Please install a distribution (e.g., Ubuntu) from the Microsoft Store or via:"
    Write-Host "    wsl --install -d Ubuntu" -ForegroundColor Cyan
    exit 1
}

# Identify default distro
$defaultDistroMatch = wsl --list --verbose | Select-String "\*"
if ($defaultDistroMatch) {
    $defaultDistro = $defaultDistroMatch.ToString().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[1].Trim()
} else {
    $defaultDistro = $distroList[0].Trim()
}
Write-Success "Using distribution: $defaultDistro"

# 3. Install Hermes Agent inside WSL
Write-Info "Installing Hermes Agent inside $defaultDistro..."
# Idempotency check inside WSL: check if 'hermes' command exists
$installCmd = @"
if ! command -v hermes &> /dev/null; then
    echo 'Installing Hermes Agent...'
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
else
    echo 'Hermes Agent is already installed.'
fi
"@

wsl -d $defaultDistro bash -c $installCmd

# 4. Check for Ollama on Windows
Write-Info "Checking for Ollama on Windows..."
$ollamaCheck = Get-Command ollama.exe -ErrorAction SilentlyContinue
if ($null -eq $ollamaCheck) {
    Write-Warning "Ollama not found in Windows PATH."
    Write-Info "It is recommended to run Ollama on Windows for GPU acceleration."
    Write-Info "Download from: https://ollama.com/download/windows"
} else {
    Write-Success "Ollama for Windows is installed."
    
    # Check if running
    try {
        $tags = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -Method Get -ErrorAction Stop
        Write-Success "Ollama service is running on localhost."
    } catch {
        Write-Warning "Ollama service is not responding on localhost:11434."
        Write-Info "Please ensure the Ollama application is running (check your system tray)."
    }
}

# 5. WSL Networking & Ollama Endpoint Setup
Write-Host ""
Write-Info "--- WSL Networking & Ollama Configuration ---"
Write-Host "Hermes Agent (running in WSL) needs to communicate with Ollama (running on Windows)."

# Try to find the host IP from WSL's perspective
$hostIP = wsl bash -c "ip route | grep default | awk '{print `$3}'" 2>$null
if (!$hostIP) {
    # Fallback: Get the IP of the WSL vEthernet adapter on Windows
    $hostIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'vEthernet (WSL)' -ErrorAction SilentlyContinue).IPAddress
}

Write-Host "Step 1: Allow Ollama to accept external connections" -ForegroundColor Yellow
Write-Host "   - Set the OLLAMA_HOST environment variable in Windows to 0.0.0.0"
Write-Host "   - Restart the Ollama application."

Write-Host "Step 2: Configure HERMES_BASE_URL in WSL" -ForegroundColor Yellow
Write-Host "   In your $defaultDistro terminal, add the following to ~/.bashrc or ~/.zshrc:"
if ($hostIP) {
    Write-Host "   export HERMES_BASE_URL='http://$($hostIP.Trim()):11434/v1'" -ForegroundColor Cyan
} else {
    Write-Host "   export HERMES_BASE_URL='http://\$(hostname).local:11434/v1'" -ForegroundColor Cyan
}

Write-Host ""
Write-Info "--- Hermes Provider Setup (inside WSL) ---"
Write-Host "Run: hermes model"
Write-Host "Select: Custom endpoint"
Write-Host "Use:"
if ($hostIP) {
    Write-Host "  URL:            http://$($hostIP.Trim()):11434/v1" -ForegroundColor Cyan
} else {
    Write-Host "  URL:            $DefaultOllamaUrl" -ForegroundColor Cyan
}
Write-Host "  API key:        ollama" -ForegroundColor Cyan
Write-Host "  Model:          $DefaultModel" -ForegroundColor Cyan
Write-Host "  Context length: $DefaultContextLength" -ForegroundColor Cyan
Write-Warning "Avoid hermes3 for agentic tool use; prefer qwen2.5-coder models."

# 6. Verification and Troubleshooting
Write-Host ""
Write-Info "--- Verification ---"
Write-Host "1. Restart your WSL terminal or run 'source ~/.bashrc'."
Write-Host "2. Pull model: 'ollama pull $DefaultModel' (on Windows or WSL)."
Write-Host "3. Configure provider: 'hermes model' (inside WSL)."
Write-Host "4. Start chat: 'hermes chat --provider custom --model $DefaultModel --toolsets terminal,skills --max-turns 12'."

Write-Host ""
Write-Info "--- Common Windows/WSL Errors ---"
Write-Warning "Connection Refused: Ensure Windows Firewall allows port 11434."
Write-Warning "WSL IP Change: If the IP changes, update HERMES_BASE_URL or use your PC's mDNS name."
Write-Warning "Docker: Some Hermes features require Docker. Install Docker Desktop for Windows and enable WSL2 integration."

Write-Success "Setup script completed!"
