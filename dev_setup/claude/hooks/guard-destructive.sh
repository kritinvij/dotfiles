#!/bin/bash
# PreToolUse hook: block high-blast-radius Bash commands.
# Requires explicit user confirmation (exit 2 -> Claude Code shows message to user).

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

block() {
  echo "BLOCKED: $1" >&2
  echo "State the exact command and reason, then ask user to confirm before proceeding." >&2
  exit 2
}

# Split on shell statement separators into individual statements for analysis
while IFS= read -r stmt; do
  # Strip leading whitespace and 'cd ... && ' prefixes
  clean=$(echo "$stmt" | sed 's/^[[:space:]]*//' | sed 's/^cd [^&]*&&[[:space:]]*//')

  [[ -z "$clean" ]] && continue

  # git force push: confirm it's a push command AND has a force flag
  if echo "$clean" | grep -qE '^git[[:space:]]+push[[:space:]]' && \
     echo "$clean" | grep -qE '(^|[[:space:]])(--force|--force-with-lease|-f)([[:space:]]|$)'; then
    block "git force-push: $clean"
  fi

  # git reset --hard
  if echo "$clean" | grep -qE '^git[[:space:]]+reset[[:space:]]+--hard\b'; then
    block "git reset --hard: $clean"
  fi

  # Destructive SQL keyword at start of statement (piped to a client)
  if echo "$clean" | grep -iqE '^(DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)|TRUNCATE[[:space:]]+TABLE)\b'; then
    block "destructive SQL: $clean"
  fi

  # rm -rf on non-safe paths
  if echo "$clean" | grep -qE '^rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f|^rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r'; then
    safe_pattern='(\.worktrees/|node_modules/|/target/|\.gradle/|__pycache__/|\.next/|/dist/|/build/|/tmp/)'
    if ! echo "$clean" | grep -qE "$safe_pattern"; then
      block "rm -rf on non-safe path: $clean"
    fi
  fi

done < <(echo "$command" | sed 's/[;&|][;&|]*/\n/g')

exit 0
