DUMP_PATH="/tmp/$(date +'%Y%m%d%H%M%S')"
zellij action dump-screen $DUMP_PATH
nvim --server $NVIM_LISTEN_ADDRESS --remote $DUMP_PATH
