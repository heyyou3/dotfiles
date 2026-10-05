function split_tmux_pane
    set -l cwd (tmux display -p '#{pane_current_path}')
    tmux select-pane -t bottom-right
    tmux split-pane -c "$cwd"
end
