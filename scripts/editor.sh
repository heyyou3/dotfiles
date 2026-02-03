#!/bin/bash
FILE_PATH="$1"

if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    nvim --server "$NVIM_LISTEN_ADDRESS" --remote "$FILE_PATH"
else
    nvim "$FILE_PATH"
fi
