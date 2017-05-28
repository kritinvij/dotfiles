# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for many Bash commands
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

#######################################################################################################################
export PATH="$HOME/bin:$PATH";
# for 'too many open files' issue
ulimit -n 16000

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

alias master='git checkout master && git pull && st'
alias diff='clear && git diff -w && git status'
alias st='clear && git status'
alias pull='git pull origin master'
alias br='git co -b'
alias add='git add .'
alias comm='git commit -m'
alias trim='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d'