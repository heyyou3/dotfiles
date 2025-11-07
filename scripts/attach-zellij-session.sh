#!/bin/bash

# This script lists all running Zellij sessions and provides a fuzzy finder
# interface (fzf) to select and attach to one of them.

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the list of running zellij sessions.
# The `zellij ls` command output includes a header line.
# `sed 1d` is used to remove this header line.
SESSIONS=$(zellij ls -n)

# If there are no running sessions, inform the user and exit.
if [ -z "$SESSIONS" ]; then
    echo "No running Zellij sessions found."
    exit 0
fi

# Use fzf to present the list of sessions to the user for selection.
# The selected line (which contains the session name and other info) is stored.
# If the user cancels fzf (e.g., by pressing Esc), the variable will be empty.
SELECTED_SESSION=$(echo "$SESSIONS" | fzf --prompt=" Select a Zellij session to attach to: ")

# Check if a session was actually selected.
if [ -n "$SELECTED_SESSION" ]; then
    # The output of `zellij ls` is space-separated, with the session name
    # being the first column. `awk '{print $1}'` extracts this name.
    SESSION_NAME=$(echo "$SELECTED_SESSION" | awk '{print $1}')

    # Attach to the selected Zellij session.
    zellij attach "$SESSION_NAME"
else
    # If no session was selected (fzf was cancelled), inform the user.
    echo "No session selected."
fi
