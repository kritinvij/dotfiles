# sonarqube-local MCP

Runs the SonarQube MCP server in Docker so Claude can analyze a Java file for Sonar issues before a push. SonarCloud only.

## Setup

1. Run Docker. With Rancher Desktop, run `docker context use rancher-desktop`.
2. Create a SonarCloud token at https://sonarcloud.io/account/security.
3. Export `SONARQUBE_TOKEN` and `SONARQUBE_ORG` (your SonarCloud organization key) in `~/.zshrc`. Never commit the token.
4. Pull the image once with the reference in `mcp.json`, so the first connection does not time out.
5. Register it from a terminal, in the repo root: `claude mcp add-json sonarqube-local "$(cat ~/Documents/dotfiles/dev_setup/claude/mcp/sonarqube-local/mcp.json | jq -c '.mcpServers["sonarqube-local"]')"`.

Start Claude Code from a terminal, in the repo root. A Dock launch does not read `~/.zshrc`, so the token is missing. The container mounts the working directory read-only, so a session started from `~` exposes `~/.ssh` and `~/.aws` to it.

## Use

`analyze_code_snippet` checks one file per call. Pass the repo-relative `filePath`, `language: java`, `scope: MAIN` or `TEST`, and `projectKey`. Ignore rule S1598.

Upstream deprecated `analyze_code_snippet`. If it disappears, switch to `analyze_file_list` or `run_advanced_code_analysis`.

## Known issues

- The server shows as failed when Docker is not running or `docker` is not on the shell PATH.
- The first call can time out while analyzers download. Retry once.
- Claude Code caches a failed connection for about 15 minutes. Editing the config forces a retry.
- Deny `change_sonar_issue_status` and `change_security_hotspot_status` in permissions for analysis-only use.
