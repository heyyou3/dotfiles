#!/usr/bin/env bash
# reviewer の approved を得るまで本体コード/設定ファイルの編集を拒否する PreToolUse フック。
# 不具合時(jq無し・パース失敗・gate不正)はすべて安全側 deny に倒す。
set -uo pipefail

deny() {
  printf '%s' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

command -v jq >/dev/null 2>&1 || deny "review-gate: jq が無いため安全側で拒否します"

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

# file_path を持たないツール呼び出しは対象外
[ -z "$file_path" ] && exit 0

# パストラバーサル防止: 許可 glob は .. を正規化しないため、memory/.. や .heyyou/.. 経由で
# 本体ファイル(gate スクリプト自身を含む)を素通り編集できてしまう。許可判定の手前で .. を拒否する。
case "$file_path" in
  *..*) deny "review-gate: パスに .. を含むため安全側で拒否します" ;;
esac

# 許可リスト: .heyyou/ 配下(作業領域)と Claude auto memory ストア。
# memory は repo 本体ではなく Claude 自身の記憶領域のため未レビューでも素通りさせる。
case "$file_path" in
  .heyyou/*|*/.heyyou/*) exit 0 ;;
  */.claude/projects/*/memory/*) exit 0 ;;
esac

# ゲート検査
root="${CLAUDE_PROJECT_DIR:-$PWD}"
gate="$root/.heyyou/state/gate"
[ -f "$gate" ] || deny "未承認: reviewer の approved がありません。Design Doc を書きレビューを通し、approved 後に .heyyou/state/gate へ slug を記録してください"

slug=$(head -n1 "$gate" | tr -d '[:space:]')
[ -n "$slug" ] || deny "review-gate: .heyyou/state/gate が空です"

review="$root/.heyyou/reviews/${slug}.md"
[ -f "$review" ] || deny "review-gate: レビューファイルがありません (slug=$slug)"

verdict=$(grep -m1 '^verdict:' "$review" | sed 's/^verdict:[[:space:]]*//' | tr -d '[:space:]')
[ "$verdict" = "approved" ] || deny "review-gate: slug=$slug は approved ではありません (verdict=${verdict:-なし})"

exit 0
