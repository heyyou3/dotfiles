#!/usr/bin/env bash
# 不可逆・高コストな Bash コマンドを検出し、承認(ask)を要求する PreToolUse フック。
# 前方一致の permission ルールでは拾えないもの(コマンド途中のフラグ、クラウドCLIの更新系動詞、
# パイプ・リダイレクト経由の破壊操作)をここで判定する。参照系は素通りさせる。
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

ask() {
  printf '%s' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# クラウドCLIの更新系動詞(動詞-名詞 形式)。参照系(list/describe/get/search/wait/scan/query)は含めない。
mutating_verb='create|delete|update|put|modify|terminate|run|reboot|register|deregister|attach|detach|associate|disassociate|enable|disable|remove|add|set|reset|cancel|purchase|release|revoke|authorize|restore|copy|move|tag|untag|start|stop|replace|import|publish|invoke|send|deploy|provision|destroy'

# aws / gcloud / az のいずれかを含む場合、更新系動詞・破壊サブコマンドを承認制にする
if grep -Eq '(^|[^[:alnum:]_-])(aws|gcloud|az)([^[:alnum:]_-]|$)' <<<"$cmd"; then
  if grep -Eq "\\b(${mutating_verb})-[a-z]" <<<"$cmd" \
     || grep -Eq 'aws[[:space:]]+s3[[:space:]]+(rm|cp|mv|sync)\b' <<<"$cmd" \
     || grep -Eq '\b(delete|create|update|deploy|destroy|remove)\b' <<<"$cmd"; then
    ask "クラウドCLIの更新系コマンドのため承認が必要です"
  fi
fi

# パイプ・リダイレクト・フラグ経由で前方一致ルールを回避する破壊操作
grep -Eq '\bfind\b.*-delete\b'                       <<<"$cmd" && ask "find -delete による削除のため承認が必要です"
grep -Eq 'xargs[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(rm|rmdir|shred)\b' <<<"$cmd" && ask "xargs 経由の削除のため承認が必要です"
grep -Eq '>[[:space:]]*/dev/(sd|disk|nvme|hd)'       <<<"$cmd" && ask "ブロックデバイスへの書き込みのため承認が必要です"
grep -Eq 'of=/dev/(sd|disk|nvme|hd)'                 <<<"$cmd" && ask "ブロックデバイスへの dd 書き込みのため承認が必要です"
grep -Eq '\brm\b.*(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b.*[[:space:]]/(\s|$)' <<<"$cmd" && ask "ルート近傍の rm -rf のため承認が必要です"

exit 0
