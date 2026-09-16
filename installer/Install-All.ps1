[CmdletBinding()]
param(
    [string]$TeachPath = (Join-Path $PSScriptRoot "..\skills\teach"),
    [switch]$UseRemoteTeach,
    [switch]$IncludeOptional,
    [switch]$SkipAnki,
    [switch]$ForceStopAnki
)

$ErrorActionPreference = "Stop"

function Run-Step {
    param(
        [Parameter(Mandatory)][string]$Script,
        [hashtable]$Arguments = @{}
    )

    $path = Join-Path $PSScriptRoot $Script
    Write-Host ""
    Write-Host "########################################################################" -ForegroundColor DarkCyan
    Write-Host "# $Script" -ForegroundColor Cyan
    Write-Host "########################################################################" -ForegroundColor DarkCyan

    & $path @Arguments
}

Run-Step "00-Install-Prerequisites.ps1"
Run-Step "10-Setup-Python-Tools.ps1"
Run-Step "20-Install-Core-Skills.ps1" @{ TeachPath = $TeachPath; UseRemoteTeach = $UseRemoteTeach }

if (-not $SkipAnki) {
    Run-Step "31-Install-Anki-And-AnkiConnect.ps1" @{ ForceStopAnki = $ForceStopAnki }
}

Run-Step "30-Install-Core-MCP.ps1" @{ SkipAnki = $SkipAnki }

if ($IncludeOptional) {
    Run-Step "40-Install-Optional-Skills.ps1"
}

Run-Step "90-Verify-OpenCode-Study-Setup.ps1" @{ IncludeOptional = $IncludeOptional }

Write-Host ""
Write-Host "Installation complete." -ForegroundColor Green
Write-Host "Restart OpenCode so it rediscovers the installed skills and MCP configuration."
if (-not $SkipAnki) {
    Write-Host "Keep Anki Desktop running whenever you want OpenCode to use the Anki MCP."
}
