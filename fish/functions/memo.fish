function memo
    set -l ext .adoc
    set -l base "$HOME/work/work_log"
    set -l year (date +'%Y')
    set -l dir "$base/$year"
    if not test -e "$dir"
        mkdir -p "$dir"
    end
    if test -z "$argv[1]"
        echo "$dir/"(date +'%m-%d')"$ext"
    else
        echo "$dir/"(date +'%m-%d')"-$argv[1]$ext"
    end
end
