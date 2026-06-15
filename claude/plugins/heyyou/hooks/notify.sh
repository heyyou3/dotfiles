#!/bin/bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
project=$(basename "$cwd")
notification_type=$(echo "$input" | jq -r '.notification_type')
session_suffix="${ZELLIJ_SESSION_NAME:+ [${ZELLIJ_SESSION_NAME}]}"

case "$notification_type" in
  "permission_prompt")
    terminal-notifier -title "Claude Code" -subtitle "$project" -message "許可待ち${session_suffix}" -sound "Ping"
    ;;
  "idle_prompt")
    # terminal-notifier -title "Claude Code" -subtitle "$project" -message "入力待ち${session_suffix}" -sound "Purr"
    ;;
  "stop")
    terminal-notifier -title "Claude Code" -subtitle "$project" -message "タスク完了${session_suffix}" -sound "Glass"
    ;;
  *)
    terminal-notifier -title "Claude Code" -subtitle "$project" -message "通知${session_suffix}" -sound ""
    ;;
esac

