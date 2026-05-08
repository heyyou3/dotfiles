function ccommit
    set -l msg (git diff --cached | claude -p "以下の git diff の内容から、簡潔で分かりやすいコミットメッセージを1行で生成してください。返信はメッセージ内容だけにしてください。日本語で")
    if test -n "$msg"
        git commit -m "$msg"
    end
end
