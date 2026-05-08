function set_tmux_env
    tmux setenv $argv[1] $argv[2]; or return 1
    set -l line (tmux showenv $argv[1])
    set -l parts (string split -m1 = -- $line)
    set -gx $parts[1] $parts[2]
end
