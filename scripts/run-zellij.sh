#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Set session name from the current directory name
SESSION_NAME=$(basename "$(pwd)")

# Set environment variables
export EDITOR="nvr"
export SESSION_NAME
export NVIM_LISTEN_ADDRESS="/tmp/${SESSION_NAME}.socket"

# Define the path to the Zellij layout, expanding the home directory tilde
ZELLIJ_LAYOUT_PATH="$HOME/dotfiles/zellij/ide-layout.kdl"

# Check if the layout file exists
if [ ! -f "$ZELLIJ_LAYOUT_PATH" ]; then
    echo "Error: Zellij layout file not found at $ZELLIJ_LAYOUT_PATH" >&2
    exit 1
fi

# Execute Zellij with the specified layout.
# The 'exec' command replaces the shell process with the zellij process,
# ensuring that all signals are passed correctly to zellij.
zellij -l "$ZELLIJ_LAYOUT_PATH"

