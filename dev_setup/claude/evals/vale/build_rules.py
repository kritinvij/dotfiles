"""Generate Vale rules from ~/.claude/WRITING.md so the linter tracks the guide.

Run after editing the ban list or the limits: python3 build_rules.py
"""
import re
from pathlib import Path

HERE = Path(__file__).parent
STYLE = HERE / "styles" / "Slop"
STYLE.mkdir(parents=True, exist_ok=True)
text = (Path.home() / ".claude" / "WRITING.md").read_text()
sec = text[text.index("## Plain words"): text.index("\n## Say it once")]
bans = sorted({p.lower() for p in re.findall(r"`([^`]+)`", sec)})

def rule(name: str, body: str) -> None:
    (STYLE / f"{name}.yml").write_text(body)

rule("Banned", "extends: existence\nmessage: \"'%s' is on the ban list in WRITING.md. Use a plain word or cut it.\"\nlevel: error\nignorecase: true\nscope: text\ntokens:\n" + "".join("  - '" + b.replace("'", "''") + "'\n" for b in bans))
rule("Filler", "extends: existence\nmessage: \"'%s' is filler. Delete it.\"\nlevel: warning\nignorecase: true\nscope: text\ntokens:\n" + "".join(f"  - '{w}'\n" for w in ["basically", "essentially", "actually", "simply", "just", "really", "quite", "fairly", "very", "obviously", "clearly"]))
rule("Pivot", "extends: existence\nmessage: \"Contrast pivot '%s'. State what the thing is.\"\nlevel: error\nignorecase: true\nscope: text\ntokens:\n  - '\\bnot (just|only) \\w+'\n  - '\\bnot [^.,;\\n]{1,30}, but\\b'\n  - ', never \\w+'\n")
rule("Openers", "extends: existence\nmessage: \"'%s' is a stretchy opener. Start with the subject and verb.\"\nlevel: warning\nignorecase: true\nscope: sentence\nraw:\n  - '^(there (is|are|was|were)|it is (\\w+ )?that|the fact that)'\n")
rule("SentenceLong", "extends: occurrence\nmessage: \"Sentence has more than 25 words. Split it.\"\nlevel: error\nscope: sentence\nmax: 25\ntoken: '\\b[\\w-]+\\b'\n")
rule("SentenceOver20", "extends: occurrence\nmessage: \"Sentence has more than 20 words. Aim for under 20.\"\nlevel: suggestion\nscope: sentence\nmax: 20\ntoken: '\\b[\\w-]+\\b'\n")
rule("Dashes", "extends: existence\nmessage: \"No em or en dash. Use a period, comma, or colon.\"\nlevel: error\nscope: text\nnonword: true\ntokens:\n  - '—'\n  - '–'\n")
print(f"wrote {len(list(STYLE.glob('*.yml')))} rules, {len(bans)} banned phrases")
