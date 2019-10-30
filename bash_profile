# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

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
if which brew &> /dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
	# Ensure existing Homebrew v1 completions continue to work
	export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d";
	source "$(brew --prefix)/etc/profile.d/bash_completion.sh";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null; then
	complete -o default -o nospace -F _git g;
fi;

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
		# If HEAD isn’t a symbolic ref, get the short SHA for the latest commit
		# Otherwise, just give up.
		echo "$(git symbolic-ref HEAD | grep -oh [a-zA-Z]*[\/]*$)";
		return 0;
	else
		return 1;
	fi;
}

#######################################################################################################################
export PATH="$HOME/bin:$PATH";
# for 'too many open files' issue
ulimit -n 16000

sublime_link="/usr/local/bin/subl"
if [[ ! -L ${sublime_link} ]]; then
	ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/local/bin/subl
fi

if [ -f ~/.git-completion.bash ]; then
	. ~/.git-completion.bash
else
	curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
fi


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

alias prof='subl ~/.bash_profile'
alias prompt='subl ~/.bash_prompt'

alias master=switch_to_master_and_update
alias diff='clear && git diff -w && git status'
alias st='clear && git status'
alias pull='git pull origin `default_branch_git` --rebase'
alias br='git co -b'
alias add='git add .'
alias comm='git commit -m'
alias trim='git branch --merged | egrep -v "(^\*|`default_branch_git`)" | xargs git branch -d'

