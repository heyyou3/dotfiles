# fzf shell integration
# nix 導入の fzf を使うため、旧 git インストーラの ~/.fzf/shell/*.bash は参照しない
# 旧 fzf(shell 統合フラグ非対応)では統合を読み込まない
if command -v fzf >/dev/null; then
  __fzf_bash_integration="$(fzf --bash 2>/dev/null)" && eval "$__fzf_bash_integration"
  unset __fzf_bash_integration
fi
