[CmdletBinding()]
param(
    [switch]$ForceStopAnki
)

. (Join-Path $PSScriptRoot "Common.ps1")

Write-Step "Installing/ensuring Anki Desktop"
Install-WingetPackage -Id "Anki.Anki" -DisplayName "Anki"

$ankiProcesses = Get-Process -Name "anki" -ErrorAction SilentlyContinue
if ($ankiProcesses) {
    if ($ForceStopAnki) {
        Write-Step "Stopping Anki so AnkiConnect can be updated safely"
        $ankiProcesses | Stop-Process -Force
        Start-Sleep -Seconds 2
    } else {
        throw "Anki is running. Close Anki and rerun this script, or use -ForceStopAnki."
    }
}

Require-Command git

$addonsRoot = Join-Path $env:APPDATA "Anki2\addons21"
$addonPath = Join-Path $addonsRoot "2055492159"
Ensure-Directory $addonsRoot

$tempRoot = Join-Path $env:TEMP ("ankiconnect-" + [guid]::NewGuid().ToString("N"))

try {
    Write-Step "Downloading current AnkiConnect upstream source"
    # Canonical upstream moved from GitHub to SourceHut. Fall back to a
    # current public mirror when SourceHut is unavailable.
    try {
        Clone-Repo -Url "https://git.sr.ht/~foosoft/anki-connect" -Destination $tempRoot
    }
    catch {
        Write-Warn "SourceHut clone failed; trying GitHub mirror JSchoreels/anki-connect."
        Clone-Repo -Url "https://github.com/JSchoreels/anki-connect.git" -Destination $tempRoot
    }

    $plugin = Join-Path $tempRoot "plugin"
    if (-not (Test-Path -LiteralPath (Join-Path $plugin "__init__.py"))) {
        throw "Unexpected AnkiConnect repository layout: plugin\__init__.py not found."
    }

    if (Test-Path -LiteralPath $addonPath) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backup = "$addonPath.backup-$stamp"
        Move-Item -LiteralPath $addonPath -Destination $backup
        Write-Host "Existing AnkiConnect backed up to: $backup"
    }

    Ensure-Directory $addonPath
    Copy-Item -Path (Join-Path $plugin "*") -Destination $addonPath -Recurse -Force

    if (-not (Test-Path -LiteralPath (Join-Path $addonPath "__init__.py"))) {
        throw "AnkiConnect installation did not produce __init__.py in $addonPath"
    }

    Write-Ok "AnkiConnect installed at $addonPath"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Start/restart Anki before using the Anki MCP server." -ForegroundColor Yellow
Write-Host "AnkiConnect listens locally on http://localhost:8765 while Anki is running."
