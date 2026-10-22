#!/bin/bash
# PreToolUse hook: block writes to project-level .gitignore files.
# Only ~/.gitignore is allowed without explicit user confirmation.

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

if [[ -z "$file_path" || "$file_path" == "null" ]]; then
  exit 0
fi

home_gitignore="$HOME/.gitignore"

if [[ "$file_path" == *".gitignore" && "$file_path" != "$home_gitignore" ]]; then
  echo "BLOCKED: write to project-level .gitignore ($file_path)" >&2
  echo "Prefer ~/.gitignore. State reason and ask user to confirm before editing project .gitignore." >&2
  exit 2
fi

exit 0
