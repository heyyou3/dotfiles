function nv-l
    set -l socket "/tmp/"(tmux display-message -p '#{window_name}.nvim.socket')
    nvim --listen "$socket" $argv
end
