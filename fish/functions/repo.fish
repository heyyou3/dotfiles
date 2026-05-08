function repo
    set -l dir (ghq list -p | fzf)
    if test -n "$dir"
        cd "$dir"
    end
end
