# if "brew" is installed, prioritize its packages in PATH
if type brew > /dev/null; then
	BREW_PREFIX=$(brew --prefix)
	[[ :$PATH: == :$BREW_PREFIX/bin:* ]] || PATH=$BREW_PREFIX/bin:$PATH
fi

# Look at my local in folder first
[[ :$PATH: == :$HOME/bin:* ]] || PATH=$HOME/bin:$PATH

if type vim > /dev/null; then
	export EDITOR=vim
fi

function cwd_toplevel() {
	PREFIX=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
	echo ${PREFIX//$HOME/'~'}
}

function cwd_git_prefix() {
	GIT_PREFIX=$(git rev-parse --show-prefix 2>/dev/null)
	echo /$GIT_PREFIX
}

function cwd_git_branch() {
	GIT_BRANCH=$(git branch 2>/dev/null | cat) || ""
	if [ -z $GIT_BRANCH ]; then
		echo ""
	else
		echo "[%{$fg[magenta]%}$GIT_BRANCH%{$reset_color%}]"
	fi
}

function chpwd_update_repo_path() {
	CWD_REPO_TOPLEVEL=$(cwd_toplevel)
	CWD_REPO_SUFFIX=$(cwd_git_prefix)
	CWD_GIT_BRANCH=$(cwd_git_branch)
}

_newline=$'\n'

unset RPROMPT
unset PROMPT

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_update_repo_path

case $(uname -s) in
	Linux)
		HOST_SYMBOL='🐧'
		;;
	Darwin)
		HOST_SYMBOL=''
		;;
	*)
		HOST_SYMBOL=$(hostname -s)
esac

setopt prompt_subst
autoload -U colors && colors

PROMPT_EXIT_CODE='%(?..%{$fg_bold[red]%}[exit code %?]%{$reset_color%}${_newline})'
PROMPT_SEPARATOR='%{$fg[faint_white]%}${(r:$COLUMNS::- :)}%{$reset_color%}${_newline}'
PROMPT_CWD=$PROMPT'$HOST_SYMBOL $CWD_REPO_TOPLEVEL$CWD_GIT_BRANCH$CWD_REPO_SUFFIX${_newline}'
PROMPT_CLI=$PROMPT'%{$fg_bold[green]%}>%{$reset_color%} '
PROMPT=$PROMPT_EXIT_CODE$PROMPT_SEPARATOR$PROMPT_CWD$PROMPT_CLI

chpwd_update_repo_path
