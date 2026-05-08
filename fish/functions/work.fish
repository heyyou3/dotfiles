function work
    set -l dir (find $HOME/work -maxdepth 1 -mindepth 1 -type d | fzf)
    if test -n "$dir"
        cd "$dir"
    end
end
