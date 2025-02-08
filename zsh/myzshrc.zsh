# vim: set tabstop=4 shiftwidth=4 expandtab:

# if "brew" is installed, prioritize its packages in PATH over system
if type brew > /dev/null; then
    BREW_PREFIX=$(brew --prefix)
    BREW_ZSH_FPATH="$BREW_PREFIX/share/zsh/site-functions"
    [[ :$PATH: == :$BREW_PREFIX/bin:* ]] || PATH=$BREW_PREFIX/bin:$PATH
    [[ :$PATH: == :$BREW_ZSH_FPATH:* ]] || FPATH="${BREW_ZSH_FPATH}:${FPATH}"
fi

# History
HISTSIZE=100000
SAVEHIST=$HISTSIZE
setopt hist_ignore_all_dups
setopt hist_ignore_space

# Persistent auth socket
MY_SSH_AUTH_SOCK=$HOME/.ssh/ssh_auth_sock
if [ -S "$SSH_AUTH_SOCK" ] && [ "$MY_SSH_AUTH_SOCK" != "$SSH_AUTH_SOCK" ]; then
    ln -sf "$SSH_AUTH_SOCK" "$MY_SSH_AUTH_SOCK"
fi
if tmux show-environment -g SSH_AUTH_SOCK &> /dev/null; then
    eval "$(tmux show-environment -g SSH_AUTH_SOCK)"
    export SSH_AUTH_SOCK
fi


ARCH=$(uname -m)
OPT=${HOME}/opt

# # Import user ~/opt
# if [ -d "${OPT}/arch/${ARCH}" ]; then
#     for ITEM in "${OPT}/arch/${ARCH}"/*
#     do
#         if [ -d "$ITEM/bin" ]; then
#             [[ :$PATH: == :$ITEM/bin:* ]] || PATH=$PATH:$ITEM/bin
#         fi
#     done
# fi
# if [ -d "${OPT}" ]; then
#     for ITEM in "${OPT}"/*
#     do
#         if [ -d "$ITEM/bin" ]; then
#             [[ :$PATH: == :$ITEM/bin:* ]] || PATH=$PATH:$ITEM/bin
#         fi
#     done
# fi

export GOPATH=$OPT/arch/$ARCH/go
[[ ! -d "$GOPATH" ]] && mkdir -p "$GOPATH"

# Look at my local in folder first
[[ :$PATH: == :$HOME/bin:* ]] || PATH=$HOME/bin:$PATH

if type vim > /dev/null; then
    export EDITOR=vim
fi

function cwd_toplevel() {
    PREFIX=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    echo "${PREFIX//$HOME/~}"
}

function cwd_git_prefix() {
    GIT_PREFIX=$(git rev-parse --show-prefix 2>/dev/null)
    echo "/$GIT_PREFIX"
}

function cwd_git_branch() {
    GIT_BRANCH="$(git branch 2>/dev/null | head -n 1 | sed 's/\*\s*//g')" || "$(echo -n '')"
    if [ -z "$GIT_BRANCH" ]; then
        echo ""
    else
        echo "[%{$fg[magenta]%}$GIT_BRANCH%{$reset_color%}]"
    fi
}

function chpwd_update_repo_path() {
    CWD_REPO_TOPLEVEL=$(cwd_toplevel)
    CWD_REPO_SUFFIX=$(cwd_git_prefix)
    CWD_GIT_BRANCH=$(cwd_git_branch)
    export CWD_REPO_TOPLEVEL
    export CWD_REPO_SUFFIX
    export CWD_GIT_BRANCH
}

_newline=$'\n'

unset RPROMPT
unset PROMPT

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_update_repo_path

case $(uname -s) in
    Linux)
        HOST_SYMBOL='🐧'
        alias ls='ls --color --classify'
        ;;
    Darwin)
        HOST_SYMBOL=''
        alias ls='ls -FG'
        alias supernice='nice -n 20 taskpolicy -d throttle'
        ;;
    *)
        HOST_SYMBOL=$(hostname -s)
        export HOST_SYMBOL
esac

setopt prompt_subst
autoload -U colors && colors

PROMPT_EXIT_CODE='%(?..%{$fg_bold[red]%}[exit code %?]%{$reset_color%}${_newline})'
PROMPT_SEPARATOR='%{$fg[faint_white]%}${(r:$COLUMNS::. :)}%{$reset_color%}${_newline}'
PROMPT_CWD=$PROMPT'$HOST_SYMBOL $CWD_REPO_TOPLEVEL$CWD_GIT_BRANCH$CWD_REPO_SUFFIX'
# PROMPT_CWD=$PROMPT'$HOST_SYMBOL $CWD_REPO_TOPLEVEL$CWD_GIT_BRANCH$CWD_REPO_SUFFIX${_newline}'
PROMPT_CLI=$PROMPT'%{$fg_bold[green]%}>%{$reset_color%} '
PROMPT=$PROMPT_EXIT_CODE$PROMPT_SEPARATOR$PROMPT_CWD$PROMPT_CLI

chpwd_update_repo_path

autoload -Uz compinit
compinit

if type fzf > /dev/null; then
    eval $(fzf --zsh)
fi

function jupyter-lab() {
    ${HOME}/opt/arch/$(uname -m)/jupyter-lab/bin/jupyter-lab --notebook-dir=~/Library/CloudStorage/Box-Box/hajir/notebooks --ServerApp.token=''
}

function open-webui() {
    OPENWEBUIDIR=$HOME/Documents/open-webui
    # curl https://hub.docker.com/v2/namespaces/searxng/repositories/searxng/tags\?page_size\=100 | jq -r '.results[].name'
    SEARXNG_NAME=searxng
    SEARXNG_VER=2025.1.21-bee267792
    # openwebui
    OPENWEBUI_NAME=open-webui
    OPENWEBUI_VER=v0.5.10

    docker stop $OPENWEBUI_NAME
    docker rm $OPENWEBUI_NAME
    docker stop $SEARXNG_NAME
    docker rm $SEARXNG_NAME

    # cat Documents/open-webui/settings.yml | yq '.search.formats +=  "blah"'
    docker run -d -p 8080:8080 -v $OPENWEBUIDIR/searxng/settings.yml:/etc/searxng/settings.yml --name $SEARXNG_NAME searxng/searxng:$SEARXNG_VER
    docker run -d --privileged=true -p 3000:8080 -e WEBUI_AUTH=False -v $OPENWEBUIDIR/open-webui:/app/backend/data --name $OPENWEBUI_NAME --restart always ghcr.io/open-webui/open-webui:$OPENWEBUI_VER
    # WEBUI_AUTH=False DATA_DIR=~/Documents/open-webui-data  ~/opt/arch/$(uname -m)/open-webui/bin/open-webui serve
}

function vscodium-install-extensions() {
    if type codium >> /dev/null; then
        codium \
            --install-extension "eamodio.gitlens" \
            --install-extension "golang.go" \
            --install-extension "itspngu.jsonnet-format" \
            --install-extension "grafana.vscode-jsonnet" \
            --install-extension "bierner.markdown-preview-github-styles" \
            --install-extension "zxh404.vscode-proto3" \
            --install-extension "ms-python.python" \
            --install-extension "charliermarsh.ruff" \
            --install-extension "puppet.puppet-vscode" \
            --install-extension "redhat.vscode-yaml" \
            --install-extension "timonwong.shellcheck" \
            --install-extension "streetsidesoftware.code-spell-checker" \
            --install-extension "ms-azuretools.vscode-docker" \
            --install-extension "bazelbuild.vscode-bazel"
            # --install-extension "ms-python.pylint" \
            # --install-extension "ms-python.black-formatter" \
            # --install-extension "zhuangtongfa.material-theme" \
            # --install-extension "tombonnike.vscode-status-bar-format-toggle" \
            # --install-extension "gruntfuggly.todo-tree" \
            # --install-extension "github.vscode-pull-request-github" \
    fi
}

fucntion fetchrepos() {
    REPOS_DIR=$1
    for REPO in ${REPOS_DIR}/*
    do
        echo "\n\nFetching '$REPO'\n"
        git -C $REPO fetch --all --prune
        git -C $REPO fetch --quiet --auto-maintenance --auto-gc upstream $(git -C $REPO remote show upstream | sed -n '/HEAD branch/s/.*: //p') &
    done
    wait
    # wait $(jobs -rp) 2> /dev/null
}
