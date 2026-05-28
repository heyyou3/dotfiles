#!/usr/bin/env bash
# git commit の確定前に、対象 slug の reviewer 差分レビューと security-reviewer が
# 両方 approved であることを要求する PreToolUse(Bash)フック。
# 不具合時(jq無し・パース失敗・gate不正・ファイル欠落・verdict不一致)はすべて安全側 deny に倒す。
set -uo pipefail

# 理由文字列に slug/verdict 等の値を埋め込むため、jq で JSON エスケープして生成する
# (未エスケープだと " や \ で deny JSON が壊れ fail-open する)。jq 不在時は静的文字列で deny。
deny() {
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  else
    printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"commit-gate: jq が無いため安全側で拒否します"}}'
  fi
  exit 0
}

# business モードではコミット前レビューゲートを課さない(雑務に儀式は不要)。
[ "${CLAUDE_WORKER_MODE:-engineer}" = business ] && exit 0

command -v jq >/dev/null 2>&1 || deny "commit-gate: jq が無いため安全側で拒否します"
cmd=$(jq -r '.tool_input.command // ""')

# git commit 検知。git のあと(`-c key=val` 等のトークンを挟んでも可)に
# サブコマンド commit が「直前が空白・直後が空白/終端」で現れる場合のみ対象。
# この境界条件により commit-graph / commit-tree(後続が -)、echo "git commit"(後続が ")、
# git log --grep=commit(直前が =)は除外される。
grep -Eq '\bgit\b([[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' <<<"$cmd" || exit 0

# --dry-run 除外は「単一コマンドで dry-run フラグを持つ」場合のみ。クオート除去後に判定し、
# コミットメッセージ内の文字列(例: -m "fix --dry-run")や、チェーン後段の本物 commit
# (例: `git commit --dry-run && git commit -m real`)を誤って素通りさせない(fail-closed)。
stripped=$(printf '%s' "$cmd" | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g')
if grep -Eq '(^|[[:space:]])--dry-run([[:space:]]|=|$)' <<<"$stripped" \
   && ! grep -Eq '(&&|\|\||;|\|)' <<<"$stripped"; then
  exit 0
fi

# ゲート検査
root="${CLAUDE_PROJECT_DIR:-$PWD}"
gate="$root/.heyyou/state/gate"
[ -f "$gate" ] || deny "commit-gate: .heyyou/state/gate がありません。レビュー承認後に slug を記録してください"

slug=$(head -n1 "$gate" | tr -d '[:space:]')
[ -n "$slug" ] || deny "commit-gate: .heyyou/state/gate が空です"

# パストラバーサル防止: slug を英数字・ハイフン・アンダースコアのみに制限。
# `/` や `..` を弾き、.heyyou/ 外の任意 approved ファイルを参照されないようにする。
case "$slug" in
  *[!A-Za-z0-9_-]*) deny "commit-gate: slug に使用できない文字が含まれます (slug=$slug)" ;;
esac

check_verdict() {
  file="$1"
  label="$2"
  [ -f "$file" ] || deny "commit-gate: ${label}がありません (slug=$slug)"
  verdict=$(grep -m1 '^verdict:' "$file" | sed 's/^verdict:[[:space:]]*//' | tr -d '[:space:]')
  [ "$verdict" = "approved" ] || deny "commit-gate: ${label}が approved ではありません (slug=$slug, verdict=${verdict:-なし})"
}

check_verdict "$root/.heyyou/reviews/${slug}.diff.md" "reviewer 差分レビュー(reviews/${slug}.diff.md)"
check_verdict "$root/.heyyou/security/${slug}.md" "security-reviewer(security/${slug}.md)"

exit 0
