[CmdletBinding()]
param(
    [switch]$IncludeOptional
)

. (Join-Path $PSScriptRoot "Common.ps1")

$failed = $false
$skillsRoot = Get-OpenCodeSkillsRoot

Write-Step "Verifying installed skills"

$coreSkills = @(
    "teach",
    "pdf",
    "docx",
    "pptx",
    "xlsx",
    "mermaid-diagram",
    "jupyter-notebooks",
    "grounded-citations"
)

$optionalSkills = @("arxiv", "socrates")

foreach ($name in $coreSkills) {
    $path = Join-Path $skillsRoot "$name\SKILL.md"
    if (Test-Path -LiteralPath $path) {
        Write-Ok "$name"
    } else {
        Write-Host "[MISSING] $name -> $path" -ForegroundColor Red
        $failed = $true
    }
}

if ($IncludeOptional) {
    foreach ($name in $optionalSkills) {
        $path = Join-Path $skillsRoot "$name\SKILL.md"
        if (Test-Path -LiteralPath $path) {
            Write-Ok "$name"
        } else {
            Write-Host "[MISSING] $name -> $path" -ForegroundColor Red
            $failed = $true
        }
    }
}

Write-Step "Verifying dedicated Python/Jupyter environment"
$python = Get-OpenCodePython

if (Test-Path -LiteralPath $python) {
    $versionText = (& $python --version 2>&1 | Out-String).Trim()
    Write-Ok $versionText

    if ($versionText -notmatch "^Python 3\.14\.") {
        Write-Host "[FAIL] Expected Python 3.14 for OpenCode tooling." -ForegroundColor Red
        $failed = $true
    }

    & $python -m jupyter --version
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Jupyter verification failed." -ForegroundColor Red
        $failed = $true
    }

    $kernels = (& $python -m jupyter kernelspec list 2>&1 | Out-String)
    if ($kernels -match "opencode-jupyter") {
        Write-Ok "Jupyter kernel opencode-jupyter registered"
    } else {
        Write-Host "[FAIL] opencode-jupyter kernel is missing." -ForegroundColor Red
        $failed = $true
    }
} else {
    Write-Host "[MISSING] $python" -ForegroundColor Red
    $failed = $true
}

Write-Step "Verifying MCP executables"

& uvx --from docling-mcp docling-mcp-server --help | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Ok "Docling MCP executable"
} else {
    Write-Host "[FAIL] Docling MCP executable" -ForegroundColor Red
    $failed = $true
}

& npx -y "@ankimcp/anki-mcp-server" --help | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Ok "Anki MCP executable"
} else {
    Write-Host "[FAIL] Anki MCP executable" -ForegroundColor Red
    $failed = $true
}

Write-Step "Verifying OpenCode MCP configuration"
& opencode mcp list
if ($LASTEXITCODE -ne 0) {
    Write-Warn "OpenCode could not list MCP servers. Inspect $(Get-OpenCodeConfigPath)."
    $failed = $true
}

Write-Step "Checking AnkiConnect (non-fatal if Anki is currently closed)"
try {
    $body = '{"action":"version","version":6}'
    $response = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8765" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -TimeoutSec 2

    Write-Ok "AnkiConnect responded. Version result: $($response.result)"
}
catch {
    Write-Warn "AnkiConnect is not responding. This is expected if Anki is closed; start/restart Anki and verify again."
}

if ($failed) {
    throw "One or more required verification checks failed."
}

Write-Ok "OpenCode study setup verification completed."
