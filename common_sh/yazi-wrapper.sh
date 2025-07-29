#!/bin/sh
# Read the address from the temp file
if [ -f /tmp/nvim_listen_address ]; then
  export NVIM_LISTEN_ADDRESS=$(cat /tmp/nvim_listen_address)
fi

export EDITOR=nvr

yazi
