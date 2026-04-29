# scripts/common/verify.ps1
# Verification script for Hermes Agent session persistence + security baseline + Ollama

# --- UI Helpers ---
function Write-Info ($Message)    { Write-Host "[INFO]  $Message" -ForegroundColor Blue }
function Write-Ok ($Message)      { Write-Host "[OK]    $Message" -ForegroundColor Green }
function Write-Warn ($Message)    { Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Fail ($Message)    { Write-Host "[FAIL]  $Message" -ForegroundColor Red }
function Write-Section ($Message) { Write-Host "`n── $Message ──" -ForegroundColor Cyan }

$checksTotal = 0
$checksOk = 0
$checksWarn = 0
$checksFail = 0

function Mark-Ok ($Message) {
    $script:checksTotal++
    $script:checksOk++
    Write-Ok $Message
}

function Mark-Warn ($Message) {
    $script:checksTotal++
    $script:checksWarn++
    Write-Warn $Message
}

function Mark-Fail ($Message) {
    $script:checksTotal++
    $script:checksFail++
    Write-Fail $Message
}

function Config-Key-True([string]$Path, [string]$Key) {
    if (-not (Test-Path $Path)) {
        return $false
    }
    $pattern = "^\s*$([regex]::Escape($Key))\s*:\s*true(\s*#.*)?$"
    return Select-String -Path $Path -Pattern $pattern -Quiet
}

Write-Host "===============================================" -ForegroundColor Green
Write-Host "   Hermes Agent Verification" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

$hermesDir = Join-Path $HOME ".hermes"
$configFile = Join-Path $hermesDir "config.yaml"
$stateDb = Join-Path $hermesDir "state.db"
$hermesPath = $null

Write-Section "Hermes Installation"
$hermesCmd = Get-Command hermes -ErrorAction SilentlyContinue
if ($hermesCmd) {
    $hermesPath = $hermesCmd.Source
    try {
        $version = (& $hermesPath --version 2>&1 | Out-String).Trim()
        if ($version) {
            Mark-Ok "Hermes found: $version"
        } else {
            Mark-Warn "Hermes found, but version output was empty."
        }
    } catch {
        Mark-Warn "Hermes found, but version command failed."
    }
} else {
    $fallbackPath = Join-Path $hermesDir "bin\hermes.exe"
    if (Test-Path $fallbackPath) {
        $hermesPath = $fallbackPath
        try {
            $version = (& $hermesPath --version 2>&1 | Out-String).Trim()
            Mark-Ok "Hermes found at $fallbackPath: $version"
            Mark-Warn "Hermes is not in your PATH."
        } catch {
            Mark-Warn "Hermes executable found at $fallbackPath, but version command failed."
        }
    } else {
        Mark-Fail "Hermes command not found in PATH or $fallbackPath"
        Write-Info "If Hermes was installed in WSL, run the Bash verifier inside WSL."
    }
}

Write-Section "Session Persistence Files"
if (Test-Path $hermesDir) { Mark-Ok "Hermes data directory exists: $hermesDir" } else { Mark-Warn "Hermes data directory missing: $hermesDir" }
if (Test-Path $configFile) { Mark-Ok "Configuration file exists: $configFile" } else { Mark-Warn "Configuration file missing: $configFile" }
if (Test-Path $stateDb) { Mark-Ok "Session database exists: $stateDb" } else { Mark-Warn "Session database missing: $stateDb" }
if (Test-Path (Join-Path $hermesDir "sessions")) { Mark-Ok "Raw sessions directory exists." } else { Mark-Warn "Raw sessions directory missing." }
if (Test-Path (Join-Path $hermesDir "logs")) { Mark-Ok "Logs directory exists." } else { Mark-Warn "Logs directory missing." }
if (Test-Path (Join-Path $hermesDir "cron")) { Mark-Ok "Cron directory exists." } else { Mark-Warn "Cron directory missing." }

Write-Section "Session CLI Commands"
if ($hermesPath) {
    $chatHelp = (& $hermesPath chat --help 2>&1 | Out-String)
    if ($chatHelp -match "--continue") { Mark-Ok "`hermes chat --continue` is available." } else { Mark-Warn "Could not verify `--continue` flag." }
    if ($chatHelp -match "--resume") { Mark-Ok "`hermes chat --resume` is available." } else { Mark-Warn "Could not verify `--resume` flag." }

    try {
        & $hermesPath sessions list --help *> $null
        if ($LASTEXITCODE -eq 0) { Mark-Ok "`hermes sessions list` command is available." } else { Mark-Warn "`hermes sessions list --help` failed." }
    } catch {
        Mark-Warn "`hermes sessions list --help` failed."
    }

    $searchVerified = $false
    try {
        & $hermesPath session search --help *> $null
        if ($LASTEXITCODE -eq 0) { $searchVerified = $true }
    } catch {}
    if (-not $searchVerified) {
        try {
            & $hermesPath sessions search --help *> $null
            if ($LASTEXITCODE -eq 0) { $searchVerified = $true }
        } catch {}
    }
    if ($searchVerified) { Mark-Ok "Session search command is available." } else { Mark-Warn "Could not verify a session search command." }
} else {
    Mark-Warn "Skipping CLI command checks because Hermes is unavailable."
}

Write-Section "Security Baseline (config.yaml)"
if (Test-Path $configFile) {
    if (Config-Key-True -Path $configFile -Key "dangerous_command_approval") {
        Mark-Ok "dangerous_command_approval: true"
    } else {
        Mark-Warn "dangerous_command_approval is missing or not true."
    }

    if (Config-Key-True -Path $configFile -Key "context_scan_enabled") {
        Mark-Ok "context_scan_enabled: true"
    } else {
        Mark-Warn "context_scan_enabled is missing or not true."
    }

    if (Config-Key-True -Path $configFile -Key "prompt_injection_detection") {
        Mark-Ok "prompt_injection_detection: true"
    } else {
        Mark-Warn "prompt_injection_detection is missing or not true."
    }

    if (Select-String -Path $configFile -Pattern "^\s*backend\s*:\s*docker(\s*#.*)?$" -Quiet) {
        Mark-Ok "terminal backend is set to docker."
    } else {
        Mark-Warn "terminal backend is not explicitly set to docker."
    }
} else {
    Mark-Warn "Skipping security baseline checks because config.yaml is missing."
}

Write-Section "Session Database Shape"
if (Test-Path $stateDb) {
    $sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if ($sqliteCmd) {
        try {
            $tableCount = (& sqlite3 $stateDb "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('sessions','messages');" 2>$null | Out-String).Trim()
            if ($tableCount -eq "2") {
                Mark-Ok "state.db includes required tables: sessions, messages."
            } else {
                Mark-Warn "state.db does not expose both sessions/messages tables (count=$tableCount)."
            }

            $lastSessionId = (& sqlite3 $stateDb "SELECT session_id FROM sessions ORDER BY created_at DESC LIMIT 1;" 2>$null | Out-String).Trim()
            if (-not $lastSessionId) {
                Mark-Warn "No sessions found yet in state.db."
            } elseif ($lastSessionId -match "^[0-9]{8}_[0-9]{6}_[0-9a-fA-F]+$") {
                Mark-Ok "Latest session_id format looks valid: $lastSessionId"
            } else {
                Mark-Warn "Latest session_id format differs from expected pattern: $lastSessionId"
            }
        } catch {
            Mark-Warn "Could not inspect state.db using sqlite3."
        }
    } else {
        Mark-Warn "sqlite3 is not installed; skipping state.db schema/session-id checks."
    }
} else {
    Mark-Warn "Skipping state.db checks because the database file is missing."
}

Write-Section "Ollama Connectivity"
$ollamaUrl = if ($env:HERMES_BASE_URL) { $env:HERMES_BASE_URL.TrimEnd('/') } else { "http://127.0.0.1:11434/v1" }
Write-Info "Using Ollama URL: $ollamaUrl"

try {
    $response = Invoke-WebRequest -Uri "$ollamaUrl/models" -Method Get -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Mark-Ok "Ollama models endpoint responded HTTP 200."
    } else {
        Mark-Warn "Ollama models endpoint returned HTTP $($response.StatusCode)."
    }
} catch {
    Mark-Warn "Ollama models endpoint request failed. $($_.Exception.Message)"
}

$ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollamaCmd) {
    $models = ollama list 2>$null
    if ($models -and $models.Count -gt 1) {
        Mark-Ok "Ollama CLI reports pulled model(s)."
        $models | Select-Object -Skip 1 | ForEach-Object {
            $name = $_.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
            if ($name) { Write-Host "  - $name" }
        }
    } else {
        Mark-Warn "No pulled models detected via `ollama list`."
    }
} else {
    Mark-Warn "ollama CLI not found; skipped local model inventory."
}

Write-Host ""
Write-Host "Summary: total=$checksTotal ok=$checksOk warn=$checksWarn fail=$checksFail" -ForegroundColor Cyan
if ($checksFail -gt 0) {
    Write-Fail "Verification completed with failure(s)."
    exit 1
}
Write-Info "Verification completed."
