---
name: claude-config
description: Rules for modifying Claude Code configuration. Use when editing ~/.claude.json, ~/.claude/settings.json, or discussing MCP servers, permissions, or tool allowlists.
type: process
---

**When this applies:** any change to Claude Code config files, MCP server setup, or permission allowlists.

## Scope rule

All Claude config = **user scope only**. Never project scope.

| Config type | File |
|-------------|------|
| MCP servers | `~/.claude.json` top-level `mcpServers` |
| Permissions, allowlists, hooks, skills | `~/.claude/settings.json` |
| Personal Claude config | `~/.claude/settings.json` |

## Never

- Create `.claude/` directories inside any project repo.
- Create `settings.local.json` or `.mcp.json` inside a project repo.
- Add permissions to project-level settings; use `~/.claude/settings.json`.

## When a permission prompt fires mid-session

Add to `~/.claude/settings.json` `permissions.allow` array. Not to any project-level file.
