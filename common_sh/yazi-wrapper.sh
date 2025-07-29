#!/bin/sh
# Read the address from the temp file
window_name="$(cat /tmp/yazi_current_window_name)"
export NVIM_LISTEN_ADDRESS="/tmp/$window_name"
export EDITOR=nvr

yazi
