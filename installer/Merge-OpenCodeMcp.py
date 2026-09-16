from __future__ import annotations

import json
import sys
from pathlib import Path

import json5


def load_config(path: Path) -> dict:
    if not path.exists() or not path.read_text(encoding="utf-8").strip():
        return {"$schema": "https://opencode.ai/config.json"}

    text = path.read_text(encoding="utf-8-sig")
    data = json5.loads(text)
    if not isinstance(data, dict):
        raise SystemExit(f"OpenCode config root must be an object: {path}")
    return data


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(
            "Usage: Merge-OpenCodeMcp.py <config> <server-name> <command-json>"
        )

    path = Path(sys.argv[1])
    server_name = sys.argv[2]
    command = json.loads(sys.argv[3])

    if not isinstance(command, list) or not all(isinstance(x, str) for x in command):
        raise SystemExit("MCP command must be a JSON array of strings")

    data = load_config(path)
    data.setdefault("$schema", "https://opencode.ai/config.json")

    mcp = data.get("mcp")
    if mcp is None:
        mcp = {}
        data["mcp"] = mcp
    elif not isinstance(mcp, dict):
        raise SystemExit("Existing top-level 'mcp' value is not an object")

    server = {
        "type": "local",
        "command": command,
    }

    # Native OpenCode V2 layout:
    #   "mcp": { "servers": { "name": {...} } }
    #
    # Older/V1 layout:
    #   "mcp": { "name": {...} }
    #
    # The user's installed OpenCode currently exposes the older interactive
    # `opencode mcp add [name]` interface. V2 also documents migration support
    # for supported V1 configuration, so when no layout exists we deliberately
    # create the legacy/direct layout for maximum compatibility.
    if isinstance(mcp.get("servers"), dict):
        mcp["servers"][server_name] = server
    else:
        mcp[server_name] = server

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
