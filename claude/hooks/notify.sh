#!/bin/bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
project=$(basename "$cwd")
notification_type=$(echo "$input" | jq -r '.notification_type')
session_suffix="${ZELLIJ_SESSION_NAME:+ [${ZELLIJ_SESSION_NAME}]}"
os="$(uname)"

notify() {
  local message="$1"
  local sound="$2"
  if [ "$os" = 'Darwin' ] && command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Claude Code" -subtitle "$project" -message "$message" -sound "$sound"
  elif [ "$os" = 'Linux' ] && command -v notify-send >/dev/null 2>&1; then
    notify-send "Claude Code" "${project}: ${message}"
  fi
}

case "$notification_type" in
  "permission_prompt") notify "許可待ち${session_suffix}" "Ping" ;;
  "idle_prompt")       : ;;  # 入力待ちは通知しない
  "stop")              notify "タスク完了${session_suffix}" "Glass" ;;
  *)                   notify "通知${session_suffix}" "" ;;
esac
