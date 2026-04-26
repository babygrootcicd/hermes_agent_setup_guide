# scripts/common/verify.ps1
# Verification script for Hermes Agent + Ollama (PowerShell)

# --- UI Helpers ---
function Write-Info ($Message) { Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success ($Message) { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning ($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error ($Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Host "===============================================" -ForegroundColor Green
Write-Host "   Hermes Agent + Ollama Verification" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# 1. Check Hermes Agent version
Write-Info "Checking Hermes Agent installation..."
$hermesCheck = Get-Command hermes -ErrorAction SilentlyContinue
if ($hermesCheck) {
    try {
        $version = & hermes --version 2>&1
        Write-Success "Hermes Agent found: $version"
    } catch {
        Write-Warning "Hermes Agent found but failed to report version."
    }
} else {
    # Check common path
    $hermesPath = Join-Path $HOME ".hermes\bin\hermes.exe"
    if (Test-Path $hermesPath) {
        $version = & $hermesPath --version 2>&1
        Write-Success "Hermes Agent found at $hermesPath: $version"
        Write-Warning "Hermes is not in your PATH."
    } else {
        # Check if in WSL
        Write-Warning "Hermes Agent command not found in PowerShell."
        Write-Info "If you installed Hermes inside WSL, please run the verification script inside WSL."
    }
}

# 2. Verify config file existence
Write-Info "Checking configuration file..."
$configFile = Join-Path $HOME ".hermes\config.yaml"
if (Test-Path $configFile) {
    Write-Success "Configuration file found at $configFile"
} else {
    Write-Warning "Configuration file not found at $configFile"
    Write-Info "Note: This is normal if you haven't run 'hermes' yet or configured it manually."
}

# 3. Test Ollama endpoint
Write-Info "Testing Ollama API endpoint..."
$ollamaUrl = if ($env:HERMES_BASE_URL) { $env:HERMES_BASE_URL } else { "http://127.0.0.1:11434/v1" }
Write-Info "Using Ollama URL: $ollamaUrl"

try {
    $response = Invoke-WebRequest -Uri "$ollamaUrl/models" -Method Get -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Success "Ollama API is responding correctly (HTTP 200)."
    } else {
        Write-Error "Ollama API returned status code: $($response.StatusCode)"
    }
} catch {
    Write-Error "Ollama API is not responding. $($_.Exception.Message)"
    Write-Info "Ensure Ollama is running and HERMES_BASE_URL is correctly set."
}

# 4. Check for pulled models
Write-Info "Checking for pulled models in Ollama..."
$ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollamaCmd) {
    $models = ollama list
    if ($models.Count -gt 1) {
        Write-Success "Models found in Ollama:"
        $models | Select-Object -Skip 1 | ForEach-Object {
            $name = $_.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
            Write-Host "  - $name"
        }
    } else {
        Write-Warning "No models found in Ollama. You may need to run 'ollama pull hermes3'."
    }
} else {
    # Try API
    try {
        $modelsJson = Invoke-RestMethod -Uri "$ollamaUrl/models" -Method Get -ErrorAction SilentlyContinue
        if ($null -ne $modelsJson -and $null -ne $modelsJson.data) {
            Write-Success "Models found via API."
        } else {
            Write-Warning "Could not list models via 'ollama' command or API."
        }
    } catch {
        Write-Warning "Could not list models via 'ollama' command or API."
    }
}

Write-Host ""
Write-Info "Verification complete."
