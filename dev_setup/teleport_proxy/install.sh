#!/usr/bin/env bash
# Installs a login-time launchd agent that keeps a Teleport app proxy up (e.g. MySQL for IntelliJ).
#   ./install.sh <app> [port]          port default: 33308
#   ./install.sh uninstall [app]       remove the agent
# Needs: tsh on PATH and a Teleport login. The agent cannot log in for you: when the login has
# expired it exits and retries every 5 minutes, so run `tsh login --proxy=$TELEPORT_PROXY`.
set -euo pipefail

ACTION=install
if [[ "${1:-}" == "uninstall" ]]; then ACTION=uninstall; shift; fi
APP="${1:?usage: install.sh <app> [port] (set TELEPORT_PROXY first)}"
PORT="${2:-33308}"
PROXY="${TELEPORT_PROXY:?set TELEPORT_PROXY to your Teleport proxy host}"

LABEL="com.${USER}.tsh-proxy-${APP}"
BIN="$HOME/.local/bin"
WRAPPER="$BIN/tsh-proxy-agent-${APP}.zsh"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LOG="$HOME/Library/Logs/tsh-proxy-${APP}.log"
DOMAIN="gui/$(id -u)"

if [[ "$ACTION" == "uninstall" ]]; then
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  rm -f "$PLIST" "$WRAPPER"
  echo "removed $LABEL"
  exit 0
fi

TSH="$(command -v tsh || true)"
[[ -n "$TSH" ]] || { echo "tsh not found on PATH" >&2; exit 1; }
if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "port $PORT is already in use. Stop that process first (lsof -nP -iTCP:$PORT -sTCP:LISTEN)." >&2
  exit 1
fi

mkdir -p "$BIN" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cat > "$WRAPPER" <<EOF
#!/bin/zsh
# Keeps the Teleport app proxy for $APP on localhost:$PORT up. Run by launchd.
export PATH=$(dirname "$TSH"):/usr/bin:/bin:/usr/sbin:/sbin

# Login needs a browser flow, so exit and let launchd retry instead.
if ! "$TSH" status --proxy=$PROXY >/dev/null 2>&1; then
  echo "\$(date '+%H:%M:%S') Teleport login missing or expired. Run: tsh login --proxy=$PROXY"
  exit 1
fi

exec "$TSH" proxy app $APP --port $PORT
EOF
chmod +x "$WRAPPER"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/zsh</string><string>$WRAPPER</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>300</integer>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF
plutil -lint "$PLIST" >/dev/null

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$PLIST" 2>/dev/null || true
launchctl kickstart -k "$DOMAIN/$LABEL"

echo "installed $LABEL: localhost:$PORT -> $APP. Log: $LOG"
echo "If it won't connect: tsh login --proxy=$PROXY, then wait up to 5 minutes or re-run this script."
