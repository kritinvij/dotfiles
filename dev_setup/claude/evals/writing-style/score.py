"""Score chat replies against the measurable rules in ~/.claude/WRITING.md.

Usage: python3 score.py <run-dir> [<baseline-run-dir>]
Each <id>.md in a run dir is one reply. Prints per-reply metrics and a summary,
and with a baseline dir prints the change in each summary metric.
"""

import json
import re
import sys
from pathlib import Path

WRITING = Path.home() / ".claude" / "WRITING.md"

OPENERS = re.compile(
    r"^\W*(good question|great (question|catch)|short answer|here'?s what i found|"
    r"to answer your question|let me (explain|break)|sure[,!]|certainly|absolutely|great[,!])",
    re.I,
)
CLOSERS = re.compile(
    r"(let me know if|hope this helps|happy to help|feel free to|in summary|to summarize|"
    r"want me to|would you like|shall i|tell me .{0,80} and i|i can (write|help|draft|show|walk))",
    re.I,
)
FILLER = re.compile(r"\b(basically|essentially|actually|simply|just|really|quite|fairly|very|honestly|obviously|clearly)\b", re.I)
BOLD_BULLET = re.compile(r"^\s*([-*]|\d+\.)\s+\*\*[^*\n]+\*\*", re.M)
RESULTS_LINE = re.compile(r"Lint:\s.*Readability:", re.I)
CONFIDENCE = re.compile(r"\[Confidence:\s*0?\.\d+\]")


def banlist() -> list[str]:
    # Backticked phrases in the "Plain words" section are the ban list.
    text = WRITING.read_text()
    start = text.index("## Plain words")
    end = text.index("\n## ", start + 1)
    return sorted({p.lower() for p in re.findall(r"`([^`]+)`", text[start:end])})


def strip_gap(md: str) -> str:
    """Drop the required gap sentence above a tag with confidence below 0.80; it is not counted."""
    m = re.search(r"\n([^\n]+)\n+\[Confidence:\s*(0?\.\d+)\]\s*$", md.rstrip())
    return md[: m.start()] + "\n" + md[m.start() + len(m.group(1)) + 1 :] if m and float(m.group(2)) < 0.8 else md


def prose(md: str) -> str:
    md = strip_gap(md)
    md = re.sub(r"```.*?```", "", md, flags=re.S)
    md = re.sub(r"`[^`\n]*`", "", md)
    md = CONFIDENCE.sub("", md)
    return "\n".join(line for line in md.splitlines() if not line.lstrip().startswith("|"))


def sentences(text: str) -> list[str]:
    parts = []
    for line in text.splitlines():
        line = re.sub(r"^\s*([-*]|\d+\.)\s+", "", line).strip()
        parts += [s for s in re.split(r"(?<=[.?!])\s+", line) if len(s.split()) >= 3]
    return parts


def score(md: str, bans: list[str]) -> dict:
    body = prose(md)
    sents = sentences(body)
    lengths = [len(s.split()) for s in sents] or [0]
    # Check the raw start and end: a 2-word opener like "Great question!" is dropped from `sents`.
    lines = [line.strip() for line in body.splitlines() if line.strip()]
    first = lines[0][:80] if lines else ""
    last = lines[-1][-120:] if lines else ""
    low = body.lower()
    return {
        "words": len(body.split()),
        "sentences": len(sents),
        "avg_len": round(sum(lengths) / len(lengths), 1),
        "over_25": sum(n > 25 for n in lengths),
        "opener": bool(OPENERS.search(first)),
        "closer": bool(CLOSERS.search(last)),
        "banned": [b for b in bans if re.search(rf"\b{re.escape(b)}\b", low)],
        "filler_words": len(FILLER.findall(body)),
        "bold_bullets": len(BOLD_BULLET.findall(md)),
        "dashes": body.count("—") + body.count("–"),
        "results_line": bool(RESULTS_LINE.search(md)),
        "confidence": bool(CONFIDENCE.search(md)),
    }


def summarize(rows: dict) -> dict:
    n = len(rows) or 1
    return {
        "replies": len(rows),
        "avg_words": round(sum(r["words"] for r in rows.values()) / n, 1),
        "replies_over_40": sum(r["words"] > 40 for r in rows.values()),
        "replies_over_80": sum(r["words"] > 80 for r in rows.values()),
        "avg_sentence_len": round(sum(r["avg_len"] for r in rows.values()) / n, 1),
        "sentences_over_25": sum(r["over_25"] for r in rows.values()),
        "openers": sum(r["opener"] for r in rows.values()),
        "closers": sum(r["closer"] for r in rows.values()),
        "banned_hits": sum(len(r["banned"]) for r in rows.values()),
        "filler_words": sum(r["filler_words"] for r in rows.values()),
        "bold_bullets": sum(r["bold_bullets"] for r in rows.values()),
        "dashes": sum(r["dashes"] for r in rows.values()),
        "results_line_leaks": sum(r["results_line"] for r in rows.values()),
        "missing_confidence": sum(not r["confidence"] for r in rows.values()),
    }


def load(run_dir: Path, bans: list[str]) -> dict:
    return {
        f.stem: score(f.read_text(), bans)
        for f in sorted(run_dir.glob("*.md"))
        if f.read_text().strip()
    }


def main() -> None:
    bans = banlist()
    run = Path(sys.argv[1])
    rows = load(run, bans)
    for rid, r in rows.items():
        print(rid, json.dumps(r))
    summary = summarize(rows)
    print("\nSUMMARY", json.dumps(summary, indent=2))
    (run / "summary.json").write_text(json.dumps({"summary": summary, "rows": rows}, indent=2))
    if len(sys.argv) > 2:
        base = summarize(load(Path(sys.argv[2]), bans))
        print("\nCHANGE vs baseline (negative is better for every metric except replies)")
        for k, v in summary.items():
            print(f"  {k}: {base[k]} -> {v} ({v - base[k]:+})")


if __name__ == "__main__":
    main()
