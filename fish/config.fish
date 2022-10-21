if type -q brew
    set -x BREW_PREFIX (brew --prefix)
    fish_add_path --prepend --move $BREW_PREFIX/bin
end

if test -d $HOME/bin
    set fish_user_paths $HOME/bin
end

if status is-interactive
    set __fish_git_prompt_show_informative_status
    set __fish_git_prompt_showcolorhints
    set __fish_git_prompt_showdirtystate
end
