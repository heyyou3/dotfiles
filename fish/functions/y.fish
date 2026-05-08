function y
    set -l tmp (mktemp -t yazi-cwd.XXXXX)
    yazi --cwd-file="$tmp" $argv
    if test -f "$tmp"
        set -l cwd (cat "$tmp")
        if test -n "$cwd"
            cd "$cwd"
        end
    end
    rm -f "$tmp"
end
