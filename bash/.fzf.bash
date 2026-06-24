# fzf shell integration
# nix 導入の fzf を使うため、旧 git インストーラの ~/.fzf/shell/*.bash は参照しない
command -v fzf >/dev/null && eval "$(fzf --bash)"
