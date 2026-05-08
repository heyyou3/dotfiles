function nv-ex
    nvim --headless --server "$NVIM_LISTEN_ADDRESS" --remote-expr "$argv[1]"
end
