# Keep this one on top so all ls functionalities are replaced
# brew install lsd otherwise won't work
alias ls='lsd'

########################## Colors and Formatting ##########################
bold=$(tput bold);
reset=$(tput sgr0);

# Solarized colors, taken from http://git.io/solarized-colors.
black=$(tput setaf 0);
blue=$(tput setaf 33);
cyan=$(tput setaf 37);
green=$(tput setaf 64);
orange=$(tput setaf 166);
purple=$(tput setaf 125);
red=$(tput setaf 124);
violet=$(tput setaf 61);
white=$(tput setaf 15);
yellow=$(tput setaf 136);

# Highlight the user name when logged in as root.
if [[ "${USER}" == "root" ]]; then
    userStyle="${red}";
else
    userStyle="${orange}";
fi;

# Highlight the hostname when connected via SSH.
if [[ "${SSH_TTY}" ]]; then
    hostStyle="${bold}${red}";
else
    hostStyle="${yellow}";
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

    # Check if the current directory is in a Git repository.
    if [[ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]]; then

        # check if the current directory is in .git before running git checks
        if [[ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]]; then

            # Ensure the index is up to date.
            git update-index --really-refresh -q &>/dev/null;

            # Check for uncommitted changes in the index.
            if [[ -n $(git diff --quiet --ignore-submodules --cached) ]]; then
                s+='+';
            fi;

            # Check for unstaged changes.
            if [[ -n $(git diff-files --quiet --ignore-submodules --) ]]; then
                s+='!';
            fi;

            # Check for untracked files.
            if [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
                s+='?';
            fi;

            # Check for stashed files.
            if [[ $(git rev-parse --verify refs/stash 2> /dev/null) ]]; then
                s+='$';
            fi;

        fi;

        # Get the short symbolic ref.
        # If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
        # Otherwise, just give up.
        branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
            git rev-parse --short HEAD 2> /dev/null || \
            echo 'unknown')";

        [ -n "${s}" ] && s=" [${s}]";

        echo -e "${white}on ${blue}${1}${branchName}${2}${s}";
    else
        echo "";
    fi;
}

# git auto-complete
autoload -Uz compinit && compinit

########################## Paths ##########################
export PATH="$HOME/bin:$PATH";
export PATH="/usr/local/sbin:$PATH"

# yarn
# export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# pyenv
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

# If pyenv is installed, this alias helps the `brew doctor` not complain about python config files
# alias brew='env PATH=${PATH//$(pyenv root)/shims:/} brew'

# export PATH="/usr/local/opt/ruby/bin:$PATH"
# export PATH="/usr/local/opt/openjdk@11/bin:$PATH"
# export JAVA_HOME="/usr/local/opt/openjdk@11/"

# nvm
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

sublime_link="/usr/local/bin/subl"
if [ -L ${sublime_link} ] && [ -e ${sublime_link} ] ; then
    # do nothing, the link exists and is good.
else
   ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
   export EDITOR='subl -w'
fi

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

########################## Personal Aliases ##########################
alias grep='grep --color=auto'
alias sudo='sudo '

alias ..='cd ..'
alias c='clear'
alias la='ls -a'

alias sz='source ~/.zshrc'
alias prof='subl ~/.zshrc'

alias diff='git diff -w'
alias diffc='git diff -w --cached'
alias st='dir_status_check'
alias pull='git pull origin $(git rev-parse --abbrev-ref HEAD) --rebase; git fetch;'
alias sync='git pull origin $(git rev-parse --abbrev-ref HEAD) --rebase; git fetch;'
alias br='git co -b'
alias add='git add .'
alias comm='git commit -m'
alias trim='git branch --merged | egrep -v "(^\*|main)" | xargs git branch -d'
alias pr='gh pr create'
alias ame='git commit --amend'
alias cane='git commit --amend --no-edit'
alias acane='git add . && git commit --amend --no-edit'
alias log='git log --graph --oneline --all'
alias doc='brew upgrade && brew cleanup && brew doctor'
alias gcp='git cherry-pick '

cd ~; ls;
