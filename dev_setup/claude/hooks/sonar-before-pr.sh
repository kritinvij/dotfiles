#!/bin/bash
# PreToolUse hook: block `gh pr create` in Gradle repos until the Sonar check
# has run for the current HEAD (sonar-mark.sh records it).

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')
cwd=$(echo "$input" | jq -r '.cwd // ""')

# Only a statement that starts with `gh pr create`, so quoted mentions pass.
echo "$command" | sed 's/[;&|][;&|]*/\n/g' | sed 's/^[[:space:]]*//' | sed 's/^cd [^&]*&&[[:space:]]*//' \
  | grep -qE '^gh[[:space:]]+pr[[:space:]]+create\b' || exit 0

# `cd <dir> && gh pr create` runs in <dir>, not in the hook's cwd.
cd_dir=$(echo "$command" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^&;]+[^[:space:]&;])[[:space:]]*&&.*/\1/p' | head -1)
[[ -n "$cd_dir" ]] && cwd="${cd_dir/#\~/$HOME}"

root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
[[ -f "$root/build.gradle" || -f "$root/settings.gradle" || -f "$root/build.gradle.kts" || -f "$root/settings.gradle.kts" ]] || exit 0

head_sha=$(git -C "$root" rev-parse HEAD)
marker="$HOME/.claude/state/sonar-checked/$(echo -n "$root" | shasum | cut -c1-16)"
[[ -f "$marker" && "$(cat "$marker")" == "$head_sha" ]] && exit 0

cat >&2 <<EOF
BLOCKED: Sonar check has not run for HEAD ($head_sha) in $root.
Before this PR opens, and before the java-pr-gate checks:
1. Run analyze_code_snippet (sonarqube-local MCP) on each Java file this branch adds or changes. Pass the repo-relative filePath, language java, scope MAIN or TEST, projectKey webedx-spark_<repo-name>. Ignore S1598.
2. Fix each finding on your lines, or say why you skipped it.
3. Run: ~/.claude/hooks/sonar-mark.sh $root
4. Retry gh pr create. A new commit means running the check again.
EOF
exit 2
