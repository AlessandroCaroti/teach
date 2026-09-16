[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "Common.ps1")

Require-Command git "Run 00-Install-Prerequisites.ps1 first."

$tempRoot = Join-Path $env:TEMP ("opencode-optional-skills-" + [guid]::NewGuid().ToString("N"))
Ensure-Directory $tempRoot

try {
    Write-Step "Installing arxiv"
    $hermes = Join-Path $tempRoot "hermes-agent"
    Clone-Repo -Url "https://github.com/NousResearch/hermes-agent.git" -Destination $hermes
    $arxivSource = Join-Path $hermes "skills\research\arxiv"
    Copy-Skill -Source $arxivSource -Name "arxiv"
    Set-OpenCodeSkillFrontmatter `
        -SkillName "arxiv" `
        -Description "Search and retrieve academic papers from arXiv and related scholarly sources." `
        -License "MIT"

    Write-Step "Installing socrates"
    $socrates = Join-Path $tempRoot "socrates-skill"
    Clone-Repo -Url "https://github.com/bevibing/socrates-skill.git" -Destination $socrates
    Copy-Skill -Source $socrates -Name "socrates"

    $socratesMarker = "<!-- opencode-manual-socrates -->"
    $socratesNote = @"
$socratesMarker
## OpenCode integration

Use this as an explicitly requested Socratic/oral-practice mode. Do not let its
"never give a direct answer" behavior override normal teaching performed by the
``teach`` skill unless the user explicitly asks for Socratic mode.
"@
    Add-SkillRuntimeNote -SkillName "socrates" -Text $socratesNote -Marker $socratesMarker

    Write-Ok "Optional skills installed."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
