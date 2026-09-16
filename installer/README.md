# OpenCode Study / Teach Installer (Windows)

PowerShell installer suite for the OpenCode study stack:

## Core skills

- `teach` — cloned from `https://github.com/AlessandroCaroti/teach`
- `pdf`
- `docx`
- `pptx`
- `xlsx`
- `mermaid-diagram`
- `jupyter-notebooks`
- `grounded-citations`

## Core MCP servers

- `docling`
- `anki`

## Optional skills

- `arxiv`
- `socrates`

## Why this installer handles Python specially

The machine that this installer was prepared for has Python 3.15 installed.
A previous Jupyter install failed because `pywinpty` did not have a compatible
prebuilt wheel, causing pip to build it from Rust source; that build then failed
because NuGet was missing.

This suite therefore creates and consistently uses:

    %USERPROFILE%\.venvs\opencode-jupyter

with Python **3.14**, and registers the kernel:

    opencode-jupyter

The environment is also populated with common PDF/DOCX/PPTX/XLSX reading
dependencies so OpenCode does not need to fall back to Python 3.15.

## OpenCode MCP compatibility

The installed OpenCode CLI on the target machine exposes the older interactive:

    opencode mcp add [name]

and did not accept:

    opencode mcp add name -- command ...

The installer therefore merges the MCP definitions into the global OpenCode
configuration rather than depending on that CLI syntax.

Existing config is backed up before each MCP merge.

Global configuration:

    %USERPROFILE%\.config\opencode\opencode.json(c)

The merge helper understands both:

- legacy/V1 direct `mcp.<server>` layout
- V2 `mcp.servers.<server>` layout

When no MCP layout exists yet, it deliberately uses the legacy/direct form for
compatibility with the installed OpenCode. OpenCode V2 documents migration
support for supported V1 configuration.

## Fastest installation

Open **PowerShell** from the repository root and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\installer\Install-All.ps1 -IncludeOptional
```

The installer uses the repository's local `skills\teach` source by default. To
run this installer from a standalone copy, use `-UseRemoteTeach` to clone the
published teach repository instead.

If Anki is currently running, close it first.

To let the installer terminate Anki automatically:

```powershell
.\installer\Install-All.ps1 -IncludeOptional -ForceStopAnki
```

To install everything except Anki:

```powershell
.\installer\Install-All.ps1 -IncludeOptional -SkipAnki
```

## Install in individual steps

```powershell
.\installer\00-Install-Prerequisites.ps1
.\installer\10-Setup-Python-Tools.ps1
.\installer\20-Install-Core-Skills.ps1
.\installer\31-Install-Anki-And-AnkiConnect.ps1
.\installer\30-Install-Core-MCP.ps1
.\installer\40-Install-Optional-Skills.ps1
.\installer\90-Verify-OpenCode-Study-Setup.ps1 -IncludeOptional
```

## What each script does

### `00-Install-Prerequisites.ps1`

Ensures:

- Git
- `uv`
- Node.js >= 22.12
- Pandoc
- Tesseract OCR
- OpenCode already exists

It uses WinGet for missing prerequisites.

### `10-Setup-Python-Tools.ps1`

Creates:

    %USERPROFILE%\.venvs\opencode-jupyter

with Python 3.14 and installs Jupyter plus document-analysis packages including:

- JupyterLab
- nbformat / nbclient / ipykernel
- pandas / numpy / matplotlib / scipy
- openpyxl
- python-docx
- python-pptx
- pypdf / pdfplumber
- pytesseract / pdf2image
- `markitdown[all]`

It then registers:

    Python 3.14 (OpenCode)
    kernel id: opencode-jupyter

### `20-Install-Core-Skills.ps1`

Downloads the current upstream repositories and copies skills to:

    %USERPROFILE%\.config\opencode\skills

The `teach` skill is cloned from:

    https://github.com/AlessandroCaroti/teach.git

and installed specifically from:

    skills/teach

This means rerunning the installer fetches the current repository version instead
of relying on a bundled `teach.zip`. The installer package therefore does **not**
need to contain a copy of the `teach` skill. Internet access to GitHub is required
when `20-Install-Core-Skills.ps1` runs.

It also adds an OpenCode/Windows note to Python-dependent skills telling them to
use the dedicated Python 3.14 environment.

Hermes-derived skills are normalized to minimal OpenCode-compatible YAML
frontmatter while their actual skill instructions/support files are preserved.

Third-party repositories are **not bundled** in this installer. They are cloned
at installation time.

### `31-Install-Anki-And-AnkiConnect.ps1`

Installs/ensures Anki via:

    winget install --id Anki.Anki

Then installs the current AnkiConnect upstream plugin source under:

    %APPDATA%\Anki2\addons21\2055492159

Anki must be closed while the add-on is installed.

Afterward start/restart Anki. AnkiConnect is available on:

    http://127.0.0.1:8765

while Anki is running.

### `30-Install-Core-MCP.ps1`

Configures:

#### Docling

Docling is configured for **local conversion**:

```text
uvx --from "docling-mcp[local]" docling-mcp-server --transport stdio
```

with:

```text
DOCLING_MCP_CONVERSION_MODE=local
```

Before writing the MCP configuration, the installer pre-warms the uvx environment
by constructing a `DocumentConverter`. This downloads/resolves the heavier local
Docling dependencies before OpenCode performs its first MCP handshake, avoiding a
first-run timeout caused by uvx environment creation.

#### Anki

```text
npx -y @ankimcp/anki-mcp-server --stdio
```

### `40-Install-Optional-Skills.ps1`

Installs:

- `arxiv`
- `socrates`

The Socrates skill receives a local note telling OpenCode to treat it as an
explicit Socratic/oral-practice mode so that it does not override normal
teaching behavior accidentally.

### `90-Verify-OpenCode-Study-Setup.ps1`

Checks:

- every skill's `SKILL.md`
- Python 3.14 environment
- Jupyter installation
- `opencode-jupyter` kernelspec
- Docling MCP executable
- Anki MCP executable
- OpenCode MCP listing
- AnkiConnect, when Anki is running

## Updating

The skill installers are intentionally idempotent: rerunning them replaces the
locally installed copies with fresh upstream clones. In particular, rerunning
`20-Install-Core-Skills.ps1` refreshes `teach` from
`https://github.com/AlessandroCaroti/teach.git` together with the other core skills.

For MCP configuration, the OpenCode config is backed up before modifications.

## Sources used for this installer

- OpenCode skill locations and MCP config: official OpenCode documentation
- Teach skill: `AlessandroCaroti/teach`
- Anthropic office/PDF skills: `anthropics/skills`
- Mermaid: `mgranberry/mermaid-diagram-skill`
- Jupyter notebooks: `openai/role-specific-plugins`
- Grounded citations / arXiv: `NousResearch/hermes-agent`
- Docling MCP: `docling-project/docling-mcp`
- Anki MCP: `ankimcp/anki-mcp-server`
- AnkiConnect: canonical `git.sr.ht/~foosoft/anki-connect`
- Socrates: `bevibing/socrates-skill`
