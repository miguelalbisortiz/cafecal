---
description: "Deactivate an active MCP for this project (e.g. `/mcp-off context7`). Removes it from opencode.json and requires restart. Reverses `/mcp-on`."
agent: build
---

# MCP Off Command

Disable an active MCP for this project.

## Usage

`/mcp-off <name>` — where `<name>` is an MCP currently present in `opencode.json` under `mcp`.

## Steps

1. If `$ARGUMENTS` is empty, run `node .opencode/bin/setup-mcp.js status` and show the user which MCPs are active.
2. Run: `node .opencode/bin/setup-mcp.js disable <name>`
3. Report success + tell the user to **restart opencode** (`opencode .`) for the change to apply.

## When to use

- User wants to cut token/boot cost and stop a rarely-used MCP.
- User wants to swap MCPs (off one, on another).
