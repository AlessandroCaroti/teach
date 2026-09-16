[CmdletBinding()]
param(
    [switch]$SkipAnki
)

. (Join-Path $PSScriptRoot "Common.ps1")

Require-Command uv "Run 00-Install-Prerequisites.ps1 first."
Require-Command node "Run 00-Install-Prerequisites.ps1 first."
Require-Command npx "Run 00-Install-Prerequisites.ps1 first."

Write-Step "Pre-warming Docling MCP local environment"
& uvx --from "docling-mcp[local]" python -c "from docling.document_converter import DocumentConverter; DocumentConverter(); print('Docling local ready')"
if ($LASTEXITCODE -ne 0) {
    throw "Docling MCP local dependencies could not be initialized through uvx."
}

Write-Step "Testing Docling MCP local server package"
& uvx --from "docling-mcp[local]" docling-mcp-server --help | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Docling MCP local server could not be launched through uvx."
}

Write-Step "Configuring Docling MCP for local conversion"
Merge-OpenCodeMcpServer `
    -Name "docling" `
    -Command @("uvx", "--from", "docling-mcp[local]", "docling-mcp-server", "--transport", "stdio") `
    -Environment @{ DOCLING_MCP_CONVERSION_MODE = "local" }

if (-not $SkipAnki) {
    Write-Step "Testing Anki MCP package"
    & npx -y "@ankimcp/anki-mcp-server" --help | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Anki MCP package could not be launched through npx."
    }

    Write-Step "Configuring Anki MCP"
    Merge-OpenCodeMcpServer `
        -Name "anki" `
        -Command @("npx", "-y", "@ankimcp/anki-mcp-server", "--stdio")
}

Write-Step "OpenCode MCP list"
& opencode mcp list
Write-Ok "Core MCP configuration complete."
