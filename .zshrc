# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
export PATH=$HOME/.toolbox/bin:$PATH
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_231.jdk/Contents/Home
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don't want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

dir_status_check() {
	inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"

	if [ "$inside_git_repo" ]; then
  		clear && git status
	else
  		clear
	fi
}

#######################################################################################################################
# for 'too many open files' issue
ulimit -n 16000

sublime_link="/usr/local/bin/subl"
########################################################################################################################
default_branch_git() {
    local branchName='';

    # Check if the current directory is in a Git repository.
    if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then

        # check if the current directory is in .git before running git checks
        if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]; then

            # Ensure the index is up to date.
            git update-index --really-refresh -q &>/dev/null;
        fi;

        # Get the short symbolic ref.
        # If HEAD isnÃ¢ÂÂt a symbolic ref, get the short SHA for the latest commit
        # Otherwise, just give up.
        echo "$(git symbolic-ref HEAD | grep -oh [a-zA-Z]*[\/]*$)";
        return 0;
    else
        return 1;
    fi;
}

switch_to_mainline_and_update() {
    local main_branch=$(default_branch_git)
    git co $main_branch
    git pull --rebase
    git status
}

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
            if [[ $(git rev-parse --verify refs/stash &>/dev/null) ]]; then
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


precmd() {
    setopt PROMPT_SUBST
    PROMPT="${bold}${yellow}$(date "+%T") ${userStyle}kritin ${white}in ${green}%9c $(prompt_git)${reset}
$ "
}


########################################################################################################################
# PERSONAL
alias ls="command ls ${colorflag}"
alias grep='grep --color=auto'
alias sudo='sudo '
# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

alias ..='cd ..'
alias c='clear'
alias ls='ls -a'

alias sz='source ~/.zshrc'
alias prof='subl ~/.zshrc'
alias prompt='subl ~/.bash_prompt'

alias mainline=switch_to_mainline_and_update
alias diff='git diff -w'
alias diffc='git diff -w --cached'
alias st='dir_status_check'
alias pull='git pull origin `default_branch_git` --rebase'
alias br='git co -b'
alias add='git add .'
alias comm='git commit -m'
alias trim='git branch --merged | egrep -v "(^\*|`default_branch_git`)" | xargs git branch -d'
alias ame='git commit --amend'
alias cane='git commit --amend --no-edit'
alias log='git log --graph --oneline --all'

################
