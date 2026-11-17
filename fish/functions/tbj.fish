function tbj --description "terminal-browser のタブを fzf で選び、そのタブと起動元の zellij ペインへ移動する"
    for cmd in terminal-browser jq fzf zellij
        if not command -q $cmd
            echo "tbj: $cmd が見つかりません" >&2
            return 1
        end
    end

    set -l rows (terminal-browser ls --all --json 2>/dev/null | jq -r '
        def clean: (. // "") | gsub("[\t\n\r]"; " ");
        .browsers[] | . as $b | .tabs[]?
        | [$b.key, (.id | tostring), ($b.tty // ""), (.title | clean), (.url | clean)]
        | @tsv' 2>/dev/null)
    if test (count $rows) -eq 0
        echo "tbj: terminal-browser のタブがありません" >&2
        return 1
    end

    set -l picked (printf '%s\n' $rows | fzf --delimiter '\t' --with-nth 4,5 --prompt 'tab> ')
    or return 0

    set -l f (string split \t -- $picked)
    set -l key $f[1]
    set -l tab_id $f[2]
    set -l tty $f[3]

    # --follow はコマンド実行時にだけ効くため、無害な get url をダミーとして付ける
    if not terminal-browser action --browser $key --tab $tab_id --follow -- get url >/dev/null 2>&1
        echo "tbj: タブを前面に出せませんでした(browser=$key tab=$tab_id)" >&2
    end

    set -l target (__tbj_pane_env $tty)
    or begin
        echo "tbj: zellij 外で起動されたブラウザなので移動しません" >&2
        return 1
    end

    __tbj_jump $target[1] $target[2]
end

function __tbj_pane_env --description "tty で動くプロセスの env から zellij の session と pane id を返す"
    test -n "$argv[1]"; or return 1
    for pid in (ps -t (path basename -- $argv[1]) -o pid= 2>/dev/null)
        set -l line (ps eww -o command= -p (string trim -- $pid) 2>/dev/null)
        set -l session (string match -rg '(?:^|\s)ZELLIJ_SESSION_NAME=([A-Za-z0-9._-]+)' -- $line)
        set -l pane (string match -rg '(?:^|\s)ZELLIJ_PANE_ID=(\d+)' -- $line)
        if test -n "$session" -a -n "$pane"
            printf '%s\n' $session $pane
            return 0
        end
    end
    return 1
end

function __tbj_jump --description "zellij の session / pane へフォーカスを移す"
    set -l session $argv[1]
    set -l pane $argv[2]
    echo "→ zellij: $session / pane $pane"

    if not set -q ZELLIJ
        echo "tbj: zellij の外なので移動しません。zellij attach $session で接続してください" >&2
        return 1
    end

    if test "$session" = "$ZELLIJ_SESSION_NAME"
        zellij action focus-pane-id terminal_$pane
    else
        zellij action switch-session $session --pane-id terminal_$pane
    end
end
