set -gx LC_ALL en_US.UTF-8
set -gx LANG en_US.UTF-8
set -gx STARSHIP_CONFIG $DOT_FILES_PATH/.starship/starship.toml
set -gx TERM xterm-256color
set -gx DIRENV_LOG_FORMAT ''
set -gx ZELLIJ_SOCKET_DIR $HOME

set -gx PATH $PATH $HOME/bin /usr/local/bin $HOME/.local/bin

if test (uname) = Darwin
    set -gx HOMEBREW_CASK_OPTS "--appdir=/Applications"
end

if test -d $HOME/.cargo
    set -gx PATH $HOME/.cargo/bin $PATH
end

if test -d $HOME/.local/share/mise/shims
    # 先頭に置く: mise が CLI ツールの主たる供給元なので、共有 brew(/opt/homebrew/bin、他ユーザー所有)等の同名ツールより優先させる。
    set -gx PATH $HOME/.local/share/mise/shims $PATH
end

if test -d $HOME/go
    set -gx GOBIN $HOME/go/bin
    set -gx GO111MODULE on
end

if test -d $HOME/work/helix/runtime
    set -gx HELIX_RUNTIME $HOME/work/helix/runtime
end

if test -f $DOT_FILES_PATH/.heyyou/not-shared.fish
    source $DOT_FILES_PATH/.heyyou/not-shared.fish
end
