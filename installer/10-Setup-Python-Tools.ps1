[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot "Common.ps1")

Require-Command git "Run 00-Install-Prerequisites.ps1 first."

$skillsRoot = Get-OpenCodeSkillsRoot
Ensure-Directory $skillsRoot

$tempRoot = Join-Path $env:TEMP ("opencode-study-skills-" + [guid]::NewGuid().ToString("N"))
Ensure-Directory $tempRoot

try {
    Write-Step "Installing teach from AlessandroCaroti/teach"
    $teachRepo = Join-Path $tempRoot "teach-repo"
    Clone-Repo -Url "https://github.com/AlessandroCaroti/teach.git" -Destination $teachRepo

    $teachSource = Join-Path $teachRepo "skills\teach"
    if (-not (Test-Path -LiteralPath (Join-Path $teachSource "SKILL.md"))) {
        throw "teach skill was not found at $teachSource"
    }

    Copy-Skill -Source $teachSource -Name "teach"

    Write-Step "Installing Anthropic PDF/DOCX/PPTX/XLSX skills"
    $anthropic = Join-Path $tempRoot "anthropic-skills"
    Clone-Repo -Url "https://github.com/anthropics/skills.git" -Destination $anthropic

    foreach ($name in @("pdf", "docx", "pptx", "xlsx")) {
        $source = Join-Path $anthropic "skills\$name"
        if (-not (Test-Path -LiteralPath (Join-Path $source "SKILL.md"))) {
            throw "Anthropic skill '$name' was not found at $source"
        }
        Copy-Skill -Source $source -Name $name
    }

    Write-Step "Installing Mermaid diagram skill"
    $mermaid = Join-Path $tempRoot "mermaid-diagram-skill"
    Clone-Repo -Url "https://github.com/mgranberry/mermaid-diagram-skill.git" -Destination $mermaid
    Copy-Skill -Source $mermaid -Name "mermaid-diagram"

    Write-Step "Installing Jupyter notebooks skill"
    $openai = Join-Path $tempRoot "openai-role-specific-plugins"
    Clone-Repo -Url "https://github.com/openai/role-specific-plugins.git" -Destination $openai
    $jupyterSource = Join-Path $openai "plugins\data-analytics\skills\jupyter-notebooks"
    Copy-Skill -Source $jupyterSource -Name "jupyter-notebooks"

    Write-Step "Installing grounded-citations skill"
    $hermes = Join-Path $tempRoot "hermes-agent"
    Clone-Repo -Url "https://github.com/NousResearch/hermes-agent.git" -Destination $hermes
    $citationsSource = Join-Path $hermes "skills\research\grounded-citations"
    Copy-Skill -Source $citationsSource -Name "grounded-citations"
    Set-OpenCodeSkillFrontmatter `
        -SkillName "grounded-citations" `
        -Description "Ground answers and documents in cited, verifiable sources." `
        -License "MIT"

    $python = Get-OpenCodePython
    $runtimeMarker = "<!-- opencode-windows-runtime -->"

    $runtimeText = @"
$runtimeMarker
## OpenCode Windows runtime

For Python-based local processing on this Windows machine, use this dedicated
Python executable instead of the system/default ``python`` or ``py``:

``$python``

The system Python may be Python 3.15; do not use it for these workflows unless
the user explicitly requests it. The dedicated environment is Python 3.14 and
contains the document/Jupyter dependencies installed by the OpenCode study
installer.
"@

    foreach ($name in @("pdf", "docx", "pptx", "xlsx", "jupyter-notebooks")) {
        Add-SkillRuntimeNote -SkillName $name -Text $runtimeText -Marker $runtimeMarker
    }

    $jupyterMarker = "<!-- opencode-jupyter-kernel -->"
    $jupyterNote = @"
$jupyterMarker
## OpenCode Jupyter kernel

Use the registered kernel ``opencode-jupyter`` when an explicit kernelspec is
needed. Execute notebooks with:

```
& "$python" -m jupyter nbconvert --execute --to notebook --inplace <notebook.ipynb>
```

If the related ``validate-data`` skill is unavailable, perform a local
reasonableness/consistency check rather than failing solely because that skill
is not installed.
"@
    Add-SkillRuntimeNote -SkillName "jupyter-notebooks" -Text $jupyterNote -Marker $jupyterMarker

    Write-Ok "Core skills installed under $skillsRoot"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
