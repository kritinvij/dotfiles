# Keep this one on top so all ls functionalities are replaced
# brew install lsd otherwise won't work
alias ls='lsd'

########################## History Configuration ##########################
HISTFILE=~/.zsh_history
HISTSIZE=99999
SAVEHIST=99999
setopt EXTENDED_HISTORY          # Write timestamp to history
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt SHARE_HISTORY             # Share history across sessions
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
setopt HIST_VERIFY               # Show before executing history commands

# Security Note: Commands starting with a space won't be saved to history
# Use this pattern for sensitive commands: ' command_with_password'

########################## Colors and Formatting ##########################
# Cache tput colors to avoid subprocess overhead on every shell start
if [[ ! -f ~/.zsh_colors ]] || [[ ~/.zshrc -nt ~/.zsh_colors ]]; then
    cat > ~/.zsh_colors << 'EOF'
bold=$'\e[1m'
reset=$'\e[0m'
black=$'\e[30m'
blue=$'\e[38;5;33m'
cyan=$'\e[38;5;37m'
green=$'\e[38;5;64m'
orange=$'\e[38;5;166m'
red=$'\e[38;5;124m'
white=$'\e[97m'
yellow=$'\e[38;5;136m'
EOF
fi
source ~/.zsh_colors

# Highlight the user name when logged in as root.
if [[ "${USER}" == "root" ]]; then
    userStyle="${red}";
else
    userStyle="${orange}";
fi;

########################## Easy Git ##########################
dir_status_check() {
    inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

    if [ "$inside_git_repo" ]; then
        clear && git status
    else
        clear && ls
    fi
}

prompt_git() {
    local s='';
    local branchName='';

    # Quick check if in git repo
    git rev-parse --is-inside-work-tree &>/dev/null || return 0

    # Skip if inside .git directory
    [[ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" == 'true' ]] && return 0

    # Use git status --porcelain for faster status check
    local git_status=$(git status --porcelain 2>/dev/null)

    # Check for changes using native zsh pattern matching
    [[ "$git_status" == *$'\nM'* || "$git_status" == $'M'* ]] && s+='!'
    [[ "$git_status" == *$'\nA'* || "$git_status" == $'A'* || "$git_status" == *$'\nM'* || "$git_status" == $'M'* ]] && s+='+'
    [[ "$git_status" == *$'\n??'* || "$git_status" == $'??'* ]] && s+='?'

    # Check for stash
    git rev-parse --verify refs/stash &>/dev/null && s+='$'

    # Get branch name
    branchName="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || \
        git rev-parse --short HEAD 2>/dev/null || \
        echo 'unknown')";

    [ -n "${s}" ] && s=" [${s}]";

    echo -e "${white}on ${blue}${1}${branchName}${2}${s}";
}

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/krvij/.docker/completions $fpath)
# End of Docker CLI completions

########################## Paths ##########################
# Consolidated PATH - order matters (earlier = higher priority)
export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/php@7.4/bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/base/coursera/arcanist/bin:$PATH"

# pyenv
# Lazy-load pyenv - only initialize when actually used
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv &>/dev/null; then
  _load_pyenv() {
    unset -f pyenv python python3 pip pip3
    eval "$(pyenv init -)"
  }

  pyenv() { _load_pyenv && pyenv "$@"; }
  python() { _load_pyenv && python "$@"; }
  python3() { _load_pyenv && python3 "$@"; }
  pip() { _load_pyenv && pip "$@"; }
  pip3() { _load_pyenv && pip3 "$@"; }
fi

# If pyenv is installed, this function helps the `brew doctor` not complain about python config files
brew() {
  # Only filter pyenv if it's actually available and initialized
  if command -v pyenv &>/dev/null && [[ -n "${PYENV_ROOT}" ]]; then
    env PATH=${PATH//$(pyenv root)/shims:/} command brew "$@"
  else
    command brew "$@"
  fi
}

# tfenv
# Lazy-load tfenv - only initialize when actually used
export PATH="$HOME/.tfenv/bin:$PATH"

if [ -d "$HOME/.tfenv" ]; then
  _load_tfenv() {
    unset -f tfenv terraform
    # tfenv is already in PATH, just need to ensure terraform shim works
  }

  tfenv() { _load_tfenv && command tfenv "$@"; }
  terraform() { _load_tfenv && command terraform "$@"; }
fi

# nvm
export NVM_DIR="$HOME/.nvm"

# Add default node version to PATH for non-interactive scripts (e.g., git hooks)
# This ensures node/npm are available without requiring lazy-load initialization
if [ -d "$NVM_DIR/versions/node" ]; then
  DEFAULT_NODE_PATH="$NVM_DIR/versions/node/$(ls -1 $NVM_DIR/versions/node | sort -V | tail -1)/bin"
  export PATH="$DEFAULT_NODE_PATH:$PATH"
fi

# Lazy-load nvm - only initialize when actually used (for interactive shell)
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _load_nvm() {
    unset -f nvm node npm npx yarn # this unsets the wrapper functions we defined below for the rest of the session
    source "$NVM_DIR/nvm.sh" # future calls to nvm/npm/node/npx/yarn in this session will now use the real executables
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
  }

  # Create wrapper functions that trigger nvm initialization
  nvm() { _load_nvm && nvm "$@"; }
  node() { _load_nvm && node "$@"; }
  npm() { _load_nvm && npm "$@"; }
  npx() { _load_nvm && npx "$@"; }
  yarn() { _load_nvm && yarn "$@"; }
fi

############### DO NOT UPLOAD THIS TO GITHUB ###############
############### DO NOT UPLOAD THIS TO GITHUB ###############
############### DO NOT UPLOAD THIS TO GITHUB ###############
export GH_TOKEN=""
############### DO NOT UPLOAD THIS TO GITHUB ###############
############### DO NOT UPLOAD THIS TO GITHUB ###############
############### DO NOT UPLOAD THIS TO GITHUB ###############

sublime_link="/usr/local/bin/subl"
if [ -L "${sublime_link}" ] && [ -e "${sublime_link}" ]; then
    # The link exists and is good. Do nothing.
    :
else
   ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
fi

# Always set EDITOR
export EDITOR='subl -w'


########################## zsh ##########################
precmd() {
    setopt PROMPT_SUBST
    PROMPT="${bold}${yellow}$(date "+%T") ${userStyle}kritin ${white}in ${green}%9c $(prompt_git)${reset}
$ "
#  ${white}at ${cyan}${(%):-%m} // to display host address for cloud desktops
}

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don't want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;


# microsoft inshellisense
[ -f ~/.inshellisense/key-bindings.zsh ] && source ~/.inshellisense/key-bindings.zsh

# scala completions fpath
# >>> scala-cli completions >>>
fpath=("$HOME/Library/Application Support/ScalaCli/completions/zsh" $fpath)
# <<< scala-cli completions <<<

# Optimize compinit - only rebuild cache if older than 24 hours
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C  # Skip check, use cached version
fi

# Completion options
setopt COMPLETE_IN_WORD          # Complete from cursor position
setopt ALWAYS_TO_END             # Move cursor to end after completion
setopt AUTO_MENU                 # Show menu on successive tab press
zstyle ':completion:*' menu select  # Use menu for completion selection

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Shell behavior options
setopt AUTO_PUSHD                # cd pushes old directory onto stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicates
setopt CORRECT                   # Suggest corrections for typos
setopt NO_BEEP                   # Disable beep on error

# scala-cli completions setup (fpath already configured above)
if [[ ! -f "$HOME/Library/Application Support/ScalaCli/completions/zsh/_scala-cli" ]]; then
    eval "$(scala-cli install completions --env --shell zsh)"
fi

########################## Gradle Commands ##########################
# No tests, lint, format
alias gbb='./gradlew build -x check'
alias gql='./gradlew lintAndAutofixGraphqlFiles'
alias gcb='./gradlew clean build spotlessApply checkstyleMain test; ./gradlew generateProto;'
alias gcbnt='./gradlew clean build spotlessApply checkstyleMain; ./gradlew generateProto;'
alias gb='./gradlew build spotlessApply checkstyleMain test; ./gradlew generateProto;'
alias gbnt='./gradlew spotlessApply checkstyleMain build; ./gradlew generateProto;'
alias gp='./gradlew preview -PKEEP_SECONDS=259200'
alias gpr='./gradlew preview -PRUN_VALIDATIONS=true'
alias gpub='./gradlew publish'
alias gt='./gradlew test'
alias glint='./gradlew spotlessApply checkstyleMain'
alias gmvn='./gradlew publishToMavenLocal'
alias grun='./gradlew bootRun'


########################## Personal Aliases ##########################
alias grep='grep --color=auto'
alias sudo='sudo '

alias ..='cd ..'
alias c='clear'
alias la='ls -a'
alias c3='cal -3'

alias sz='source ~/.zshrc'
alias prof='subl ~/.zshrc'

alias diff='git diff -w'
alias diffc='git diff -w --cached'
alias st='dir_status_check'

# Git aliases optimized to avoid subshell spawns
pull() {
  # Check if in git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -z "$branch" ]]; then
    echo "Error: Could not determine current branch" >&2
    return 1
  fi

  git pull origin "$branch" --rebase && git fetch
}

sync() {
  # Check if in git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -z "$branch" ]]; then
    echo "Error: Could not determine current branch" >&2
    return 1
  fi

  git pull origin "$branch" --rebase && git fetch && trim
}

main() {
  # Check if in git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [[ -z "$default_branch" ]]; then
    echo "Error: Could not determine default branch. Run: git remote set-head origin --auto" >&2
    return 1
  fi

  git co "$default_branch" && sync
}

alias br='git co -b'
alias add='git add .'
alias comm='git commit -m'

trim() {
  # Check if in git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  local primary=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [[ -z "$primary" ]]; then
    echo "Error: Could not determine default branch. Run: git remote set-head origin --auto" >&2
    return 1
  fi

  local current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

  # Get branches to delete
  local branches_to_delete=$(git branch --format='%(refname:short)' | grep -v "^$primary$" | grep -v "^$current$")

  if [[ -z "$branches_to_delete" ]]; then
    echo "No branches to delete"
    return 0
  fi

  echo "$branches_to_delete" | xargs -I {} git branch -D {}
}

alias pr='gh pr create'
alias ame='git commit --amend'
alias cane='git commit --amend --no-edit'
alias acane='git add . && git commit --amend --no-edit'
alias log='git log --graph --oneline --all'
alias doc='brew upgrade && brew cleanup && brew doctor'
alias gcp='git cherry-pick '
alias hm='cd ~/'
