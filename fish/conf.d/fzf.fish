if status is-interactive
    if type -q fzf
        # 旧 fzf(shell 統合フラグ非対応)では統合を読み込まない
        fzf --fish 2>/dev/null | source
    end
end
