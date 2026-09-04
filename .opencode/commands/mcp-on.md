---
description: "Activate an optional MCP (context7, playwright, github, postgres, ...) for this project. Patches opencode.json and requires restart. List available with `/setup-mcp --list`."
agent: build
---

# MCP On Command

Enable an optional MCP for this project.

## Usage

`/mcp-on <name>` — where `<name>` is one of the optional MCPs defined in `.opencode/mcp.optional.json` (run `/setup-mcp --list` to see them).

## Steps

1. If `$ARGUMENTS` is empty or the name is unknown, run `node .opencode/bin/setup-mcp.js --list` and show the user the available names.
2. Run: `node .opencode/bin/setup-mcp.js activate <name>`
3. Report success + tell the user to **restart opencode** (`opencode .`) for the MCP to load.
4. Note: MCPs are closed by default (token optimization). `context7` and `playwright` moved to opt-in on 2026-08-12.

## When to use

- User needs live library docs → `/mcp-on context7`
- User needs browser automation / E2E → `/mcp-on playwright`
- Other names from the catalog as needed.
