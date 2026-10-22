#!/bin/bash
# Run each prompt through headless Claude Code with the user-scope config, then score the replies.
# Usage: ./run.sh [model] [prompt-id-filter]   e.g. ./run.sh claude-opus-5-5   or   ./run.sh claude-haiku-4-5-20251001 yesno
set -euo pipefail
MODEL="${1:-claude-opus-5-5}"; FILTER="${2:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/runs/$(date +%Y%m%d-%H%M%S)-$MODEL"; mkdir -p "$OUT"
WORK="$(mktemp -d)"   # empty dir, so no repo CLAUDE.md or code leaks into the reply
python3 -c 'import json,sys; [print(p["id"]+"\t"+p["prompt"]) for p in json.load(open(sys.argv[1]))]' "$HERE/prompts.json" |
while IFS=$'\t' read -r id prompt; do
  [[ -n "$FILTER" && "$id" != *"$FILTER"* ]] && continue
  echo "running $id" >&2
  (cd "$WORK" && claude -p "$prompt" --model "$MODEL" --no-session-persistence --allowedTools "" < /dev/null) > "$OUT/$id.md" 2>"$OUT/$id.err" || echo "failed: $id" >&2
done
rmdir "$WORK" 2>/dev/null || true
python3 "$HERE/score.py" "$OUT"
