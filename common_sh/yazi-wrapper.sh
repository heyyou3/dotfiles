#!/bin/sh
# Read the address from the temp file
window_name="$(cat /tmp/yazi_current_window_name)"

export NVIM_LISTEN_ADDRESS="/tmp/$window_name"
export EDITOR=nvr

cwd=$(nvr --remote-expr 'expand("%:p:h")' 2>/dev/null)
if [ -z "$cwd" ] || [ "$cwd" = "." ]; then
  cwd=$(nvr --remote-expr 'getcwd()' 2>/dev/null)
fi

if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  yazi "$cwd"
else
  yazi
fi
