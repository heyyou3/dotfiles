function split_tmux_pane
    set -l cwd (tmux display -p '#{pane_current_path}')
    tmux select-pane -t bottom-right
    if test -n "$IN_NIX_SHELL"
        tmux split-pane -c "$cwd" "nix-shell --run fish"
    else
        tmux split-pane -c "$cwd"
    end
end
