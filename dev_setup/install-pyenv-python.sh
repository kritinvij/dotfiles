#!/bin/zsh

# Version to install (keep in sync with install-deps-new-laptop.py PYTHON_VERSION_TO_INSTALL)
PYTHON_VERSION="3.13.2"

# Check if pyenv is installed
if ! command -v pyenv &> /dev/null; then
    echo "pyenv could not be found, starting install..."
    curl https://pyenv.run | zsh
    # Add lazy-load pyenv block only if not already present
    if ! grep -q '_pyenv_commands' ~/.zshrc 2>/dev/null; then
        cat >> ~/.zshrc << 'PYENV_LAZY'
# pyenv
# Lazy-load pyenv - only initialize when actually used
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv &>/dev/null; then
  _pyenv_commands=(pyenv python python3 pip pip3)

  _load_pyenv() {
    unset -f pyenv python python3 pip pip3 _load_pyenv 2>/dev/null
    eval "$(pyenv init -)"
  }

  for cmd in "${_pyenv_commands[@]}"; do
    eval "${cmd}() { _load_pyenv && ${cmd} \"\$@\"; }"
  done
fi
PYENV_LAZY
    fi
    source ~/.zshrc
else
    echo "pyenv is already installed."
fi

# Ensure pyenv is active in this shell (script may run non-interactively without .zshrc)
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export PATH="$PYENV_ROOT/bin:$PATH"
if [[ -x "$PYENV_ROOT/bin/pyenv" ]]; then
  eval "$(pyenv init -)"
fi

# Install Python $PYTHON_VERSION if it's not installed
version=$(pyenv version-name)
if [[ $version != ${PYTHON_VERSION}* ]]; then
    echo "Python ${PYTHON_VERSION} is not installed, starting install..."
    pyenv install "$PYTHON_VERSION"
    pyenv global "$PYTHON_VERSION"
    python3 -m pip install requests tqdm
    echo "Please restart your zsh shell."
else
    python3 -m pip install requests tqdm
    echo "Python ${PYTHON_VERSION} is already installed."
fi
