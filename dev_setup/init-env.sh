#!/bin/zsh
# Initialize lazy-loaded tools for Claude Code
# Runs at SessionStart and writes env vars to CLAUDE_ENV_FILE
# ~/.claude/hooks/init-env.sh

# NVM
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi

# pyenv
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
fi

# tfenv
if [ -d "$HOME/.tfenv/bin" ]; then
    export PATH="$HOME/.tfenv/bin:$PATH"
fi

# Write resolved env to CLAUDE_ENV_FILE so Claude Code picks it up
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo "PATH=$PATH" >> "$CLAUDE_ENV_FILE"
    echo "NVM_DIR=$NVM_DIR" >> "$CLAUDE_ENV_FILE"
    [ -n "$NVM_BIN" ]     && echo "NVM_BIN=$NVM_BIN"         >> "$CLAUDE_ENV_FILE"
    [ -n "$PYENV_ROOT" ]  && echo "PYENV_ROOT=$PYENV_ROOT"   >> "$CLAUDE_ENV_FILE"
fi

exit 0
