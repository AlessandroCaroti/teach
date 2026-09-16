[CmdletBinding()]
param(
    [switch]$SkipPandoc,
    [switch]$SkipTesseract
)

. (Join-Path $PSScriptRoot "Common.ps1")

Write-Step "Checking Windows prerequisites"

if ($env:OS -ne "Windows_NT") {
    throw "This installer suite is designed for Windows PowerShell / PowerShell 7."
}

Require-Command winget "Install Microsoft App Installer first."

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Install-WingetPackage -Id "Git.Git" -DisplayName "Git"
}
Refresh-ProcessPath
Require-Command git

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Install-WingetPackage -Id "astral-sh.uv" -DisplayName "uv"
}
Refresh-ProcessPath
Require-Command uv

if (-not (Test-NodeVersion)) {
    Install-WingetPackage -Id "OpenJS.NodeJS.LTS" -DisplayName "Node.js LTS"
}
Refresh-ProcessPath
if (-not (Test-NodeVersion)) {
    throw "Node.js >= 22.12 is required for the Anki MCP server. Current node: $(& node --version 2>$null)"
}
Write-Ok "Node.js $(& node --version)"

if (-not $SkipPandoc) {
    if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
        Install-WingetPackage -Id "JohnMacFarlane.Pandoc" -DisplayName "Pandoc"
    }
    Refresh-ProcessPath
    if (Get-Command pandoc -ErrorAction SilentlyContinue) {
        Write-Ok "Pandoc available"
    } else {
        Write-Warn "Pandoc was not found after installation. Reopen PowerShell before using DOCX workflows."
    }
}

if (-not $SkipTesseract) {
    if (-not (Get-Command tesseract -ErrorAction SilentlyContinue)) {
        Install-WingetPackage -Id "UB-Mannheim.TesseractOCR" -DisplayName "Tesseract OCR"
    }
    Refresh-ProcessPath
    if (Get-Command tesseract -ErrorAction SilentlyContinue) {
        Write-Ok "Tesseract available"
    } else {
        Write-Warn "Tesseract was not found in the current PATH after installation. Reopen PowerShell if needed."
    }
}

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    throw "OpenCode is not installed or is not in PATH. Install OpenCode first, then rerun this script."
}
Write-Ok "OpenCode available: $(& opencode --version 2>$null)"

Write-Ok "Prerequisites completed."
