#!/bin/bash
# Record that the Sonar check ran for the current HEAD of the given repo.
# Usage: sonar-mark.sh <repo-root>

root=$(git -C "${1:-.}" rev-parse --show-toplevel) || exit 1
dir="$HOME/.claude/state/sonar-checked"
mkdir -p "$dir"
git -C "$root" rev-parse HEAD > "$dir/$(echo -n "$root" | shasum | cut -c1-16)"
echo "Sonar check recorded for $(git -C "$root" rev-parse --short HEAD) in $root"
