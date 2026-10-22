# Writing-style eval

Measures whether chat replies follow the countable rules in `~/.claude/WRITING.md`. Run it before and after changing any instruction file, and compare the two runs.

`run.sh` sends each prompt in `prompts.json` to headless Claude Code (`claude -p`) from an empty directory, so only the user-scope config applies. `score.py` then counts words, average sentence length, sentences over 25 words, warm-up openers, wind-down closers, banned phrases, dashes, leaked results lines, and missing confidence lines.

```bash
./run.sh                                   # all prompts, default model
./run.sh claude-haiku-4-5-20251001 yesno   # cheap subset, for a smoke test
python3 score.py runs/<new> runs/<old>     # compare against a baseline run
```

Replies land in `runs/<timestamp>-<model>/`, with `summary.json` alongside. A full run makes 12 model calls. Hooks and plugins still apply, so a style plugin such as caveman changes the result.
