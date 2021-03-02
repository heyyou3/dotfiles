#!/bin/env zsh
if [ -e "$HOME/.org_tmux_command_list" ]; then
  cat_cmd=$(cat "$HOME/.org_tmux_command_list" "$HOME/dotfiles/tmux/command_list")
else
  cat_cmd=$(cat "$HOME/dotfiles/tmux/command_list")
fi
echo $cat_cmd | fzf-tmux | perl -F# -anlE 'say $F[2]' | xargs -I{} -d'\n' tmux send-keys {}
