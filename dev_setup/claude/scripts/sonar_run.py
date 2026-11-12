"""Run the sonarqube-local MCP server's analyze_code_snippet on every Java file a branch changes.

Usage: python3 sonar_run.py <repo_dir> <project_key> [file ...]
Spawns the same pinned image the Claude Code plugin uses, speaks MCP JSON-RPC over stdio,
and prints one line per finding. SONARQUBE_TOKEN and SONARQUBE_ORG come from the environment.
"""
import json
import os
import select
import subprocess
import sys
import time

IMAGE = "sonarsource/sonarqube-mcp@sha256:e1a31da56d1006e45bfb2b0f4f4a9ce2de5051d84e07446c5dafabdff13b0415"
repo, project_key = sys.argv[1], sys.argv[2]

files = subprocess.run(["git", "-C", repo, "diff", "--name-only", "origin/main...HEAD", "--", "*.java"],
                       capture_output=True, text=True, check=True).stdout.split()
if len(sys.argv) > 3:
    files = [f for f in files if f in sys.argv[3:]]

if not os.environ.get("SONARQUBE_ORG"):
    sys.exit("Set SONARQUBE_ORG to your SonarCloud organization key.")
env = dict(os.environ, TELEMETRY_DISABLED="true", SONARQUBE_FORCE_LOCAL_ANALYSIS="true")
proc = subprocess.Popen(
    ["docker", "run", "--init", "--pull=missing", "-i", "--rm", "--cap-drop=ALL", "--security-opt=no-new-privileges",
     "-e", "SONARQUBE_TOKEN", "-e", "SONARQUBE_ORG", "-e", "TELEMETRY_DISABLED", "-e", "SONARQUBE_FORCE_LOCAL_ANALYSIS",
     "-v", f"{repo}:/app/mcp-workspace:ro", IMAGE],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, env=env, text=True, bufsize=1)

next_id = 0


def send(method, params=None, notify=False):
    global next_id
    msg = {"jsonrpc": "2.0", "method": method}
    if params is not None:
        msg["params"] = params
    if not notify:
        next_id += 1
        msg["id"] = next_id
    proc.stdin.write(json.dumps(msg) + "\n")
    proc.stdin.flush()
    return None if notify else next_id


def recv(want_id, timeout=600):
    deadline = time.time() + timeout
    while time.time() < deadline:
        r, _, _ = select.select([proc.stdout], [], [], 5)
        if not r:
            continue
        line = proc.stdout.readline()
        if not line:
            sys.exit("server exited")
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue
        if msg.get("id") == want_id:
            return msg
    sys.exit(f"timeout waiting for response {want_id}")


recv(send("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                         "clientInfo": {"name": "sonar-run", "version": "1"}}))
send("notifications/initialized", notify=True)
tools = recv(send("tools/list", {}))["result"]["tools"]
tool = next(t for t in tools if t["name"] == "analyze_code_snippet")
props = tool["inputSchema"].get("properties", {})
print("analyze_code_snippet params:", sorted(props))

total = 0
for rel in files:
    path = os.path.join(repo, rel)
    if not os.path.exists(path):
        print(f"{rel}: deleted, skipped (no content to analyze)")
        continue
    scope = "TEST" if "/src/test/" in rel or rel.startswith("src/test/") else "MAIN"
    args = {"projectKey": project_key, "codeSnippet": open(path).read(), "language": "java"}
    if "scope" in props:
        args["scope"] = scope
    if "filePath" in props:
        args["filePath"] = rel
    for attempt in range(30):
        res = recv(send("tools/call", {"name": "analyze_code_snippet", "arguments": args}))
        body = "".join(c.get("text", "") for c in res.get("result", {}).get("content", []))
        if "Server initialization is taking longer" not in body:
            break
        time.sleep(10)  # The analyzers are still loading.
    if "error" in res:
        print(f"{rel}: ERROR {res['error'].get('message')}")
        continue
    text = "".join(c.get("text", "") for c in res["result"].get("content", []))
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        data = None
    issues = (data or {}).get("issues", []) if isinstance(data, dict) else []
    issues = [i for i in issues if not str(i.get("ruleKey", "")).endswith("S1598")]
    total += len(issues)
    if data is None:
        print(f"{rel}: {text[:300]}")
    for i in issues:
        rng = i.get("textRange") or {}
        print(f"{rel}:{rng.get('startLine', '?')} {i.get('ruleKey')} {i.get('severity', '')} {i.get('message', '')}")
    if data is not None and not issues:
        print(f"{rel}: clean")
print(f"TOTAL findings (S1598 ignored): {total} across {len(files)} files")
proc.stdin.close()
proc.terminate()
