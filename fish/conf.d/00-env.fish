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

if test -d $HOME/.nix-profile
    # nix develop の中では dev shell の PATH を優先する。
    # nix-profile を prepend すると flake 固定版が profile 版に隠される(jq/gh 等の drift)。
    if not set -q IN_NIX_SHELL
        set -gx PATH /nix/var/nix/profiles/default/bin $PATH
        set -gx PATH $HOME/.nix-profile/bin $PATH
    end
    set -gx LOCALE_ARCHIVE (readlink ~/.nix-profile/lib/locale)/locale-archive
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
