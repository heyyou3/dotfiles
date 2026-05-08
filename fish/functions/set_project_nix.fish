function set_project_nix
    echo 'use_nix' >> ./.envrc
    touch ./shell.nix
end
