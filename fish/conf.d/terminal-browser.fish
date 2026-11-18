# zellij は tmux のような wrapper と判定されず TERM_PROGRAM=ghostty を引き継ぐため、Ghostty 向けの差分描画(Patched)が選ばれてちらつく
if set -q ZELLIJ; and not set -q TERMINAL_BROWSER_PRESENT
    set -gx TERMINAL_BROWSER_PRESENT full
end
