function ranger
    if test -z "$RANGER_LEVEL"
        $HOME/.nix-profile/bin/ranger $argv
    else
        exit
    end
end
