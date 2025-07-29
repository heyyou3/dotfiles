#!/bin/sh

# Get the window name using tmux display-message and write it to a temporary file
tmux display-message -p '#{window_name}' > /tmp/yazi_current_window_name