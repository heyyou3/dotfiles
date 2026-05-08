function tk
    set -l name (task --list-all | awk 'NR>1 {print $2}' | sed 's/://' | fzf --preview 'task {} --summary')
    if test -n "$name"
        task $name
    end
end
