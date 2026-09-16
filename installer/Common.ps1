Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([Parameter(Mandatory)][string]$Message)
    Write-Warning $Message
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Refresh-ProcessPath {
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()
    if ($machine) { $parts += $machine }
    if ($user) { $parts += $user }
    if ($parts.Count -gt 0) {
        $env:Path = ($parts -join ";")
    }
}

function Require-Command {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$InstallHint = ""
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        $suffix = if ($InstallHint) { " $InstallHint" } else { "" }
        throw "Required command '$Name' was not found.$suffix"
    }
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments
    )

    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
    }
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$DisplayName = $Id
    )

    Require-Command winget "Install Microsoft App Installer / winget first."

    Write-Step "Ensuring $DisplayName is installed"
    & winget install `
        --id $Id `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    # winget may return a non-zero code for some "already installed/no update" cases.
    # Refresh PATH and validate the expected command separately in caller code.
    Refresh-ProcessPath
}

function Get-OpenCodeSkillsRoot {
    return (Join-Path $HOME ".config\opencode\skills")
}

function Get-OpenCodeConfigPath {
    $dir = Join-Path $HOME ".config\opencode"
    Ensure-Directory $dir

    $jsonc = Join-Path $dir "opencode.jsonc"
    $json  = Join-Path $dir "opencode.json"

    if (Test-Path -LiteralPath $jsonc) { return $jsonc }
    if (Test-Path -LiteralPath $json)  { return $json }

    return $json
}

function Copy-Skill {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Name
    )

    $skillsRoot = Get-OpenCodeSkillsRoot
    Ensure-Directory $skillsRoot

    $destination = Join-Path $skillsRoot $Name
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    Copy-Item -LiteralPath $Source -Destination $destination -Recurse -Force

    $skillFile = Join-Path $destination "SKILL.md"
    if (-not (Test-Path -LiteralPath $skillFile)) {
        throw "Installed skill '$Name' does not contain SKILL.md at $skillFile"
    }

    Write-Ok "Installed skill: $Name"
}

function Clone-Repo {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination
    )

    Require-Command git
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }

    Invoke-Checked git config --global core.longpaths true

    Invoke-Checked git clone --depth 1 $Url $Destination
}


function Set-OpenCodeSkillFrontmatter {
    param(
        [Parameter(Mandatory)][string]$SkillName,
        [Parameter(Mandatory)][string]$Description,
        [string]$License = ""
    )

    $path = Join-Path (Get-OpenCodeSkillsRoot) "$SkillName\SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Cannot normalize missing skill: $path"
    }

    $content = Get-Content -LiteralPath $path -Raw
    $match = [regex]::Match(
        $content,
        '(?s)\A---\s*\r?\n.*?\r?\n---\s*\r?\n(.*)\z'
    )

    if (-not $match.Success) {
        throw "Could not parse YAML frontmatter in $path"
    }

    $body = $match.Groups[1].Value
    $escapedDescription = $Description.Replace('"', '\"')

    $frontmatter = @"
---
name: $SkillName
description: "$escapedDescription"
"@

    if ($License) {
        $frontmatter += "`r`nlicense: $License"
    }

    $frontmatter += "`r`n---`r`n`r`n"

    Set-Content -LiteralPath $path -Value ($frontmatter + $body) -Encoding utf8
    Write-Ok "Normalized OpenCode frontmatter: $SkillName"
}

function Add-SkillRuntimeNote {
    param(
        [Parameter(Mandatory)][string]$SkillName,
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Marker
    )

    $path = Join-Path (Get-OpenCodeSkillsRoot) "$SkillName\SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) {
        return
    }

    $content = Get-Content -LiteralPath $path -Raw
    if ($content.Contains($Marker)) {
        return
    }

    Add-Content -LiteralPath $path -Value "`r`n`r`n$Text`r`n"
    Write-Ok "Added OpenCode runtime note to $SkillName"
}

function Backup-File {
    param([Parameter(Mandatory)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backup = "$Path.bak-$stamp"
        Copy-Item -LiteralPath $Path -Destination $backup -Force
        Write-Host "Backup: $backup"
        return $backup
    }

    return $null
}

function Merge-OpenCodeMcpServer {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Command
    )

    Require-Command uv "Run 00-Install-Prerequisites.ps1 first."

    $configPath = Get-OpenCodeConfigPath
    Backup-File $configPath | Out-Null

    $mergeScript = Join-Path $PSScriptRoot "Merge-OpenCodeMcp.py"
    if (-not (Test-Path -LiteralPath $mergeScript)) {
        throw "Missing helper: $mergeScript"
    }

    $commandJson = $Command | ConvertTo-Json -Compress
    Invoke-Checked uv run --quiet --with json5 python $mergeScript $configPath $Name $commandJson

    Write-Ok "Configured MCP server '$Name' in $configPath"
}

function Get-OpenCodePython {
    return (Join-Path $HOME ".venvs\opencode-jupyter\Scripts\python.exe")
}

function Test-NodeVersion {
    param([version]$Minimum = [version]"22.12.0")

    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) { return $false }

    try {
        $raw = (& node --version).Trim().TrimStart("v")
        $version = [version]$raw
        return $version -ge $Minimum
    }
    catch {
        return $false
    }
}
