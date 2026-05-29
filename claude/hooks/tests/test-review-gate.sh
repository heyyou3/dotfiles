#!/usr/bin/env bash
# review-gate.sh の動作確認テスト。
# フックを実際に標準入力へ JSON を渡して起動し、exit code と permissionDecision を assert する。
# 本体ロジックは変更せず、観点を網羅する素直な bash テスト。
#
# セッション別 gate(.heyyou/state/gates/<session-key>)スキームに対応。
# session-key は env CLAUDE_CODE_SESSION_ID を第一参照し、空のとき stdin の .session_id にフォールバックする。
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/review-gate.sh"

pass=0
fail=0

# テスト全体で使う既定のセッションキー
SESSION_KEY="test-sess"

# 一時プロジェクトを作って毎回まっさらな状態から検査する
setup() {
  ROOT=$(mktemp -d)
  mkdir -p "$ROOT/.heyyou/state/gates"
  SESSION_KEY="test-sess"
}
teardown() { rm -rf "$ROOT"; }

# 指定 key の gate に slug を記録する(第2引数省略時は $SESSION_KEY)
set_gate() {
  local slug="$1" key="${2:-$SESSION_KEY}"
  printf '%s\n' "$slug" > "$ROOT/.heyyou/state/gates/$key"
}

# 指定 slug の design-review.md を作る(verdict 付き)
make_review() {
  local slug="$1" verdict="$2"
  mkdir -p "$ROOT/.heyyou/tasks/$slug/reviewer"
  printf 'verdict: %s\n' "$verdict" > "$ROOT/.heyyou/tasks/$slug/reviewer/design-review.md"
}

# フック実行: 引数 = file_path(空可)。CLAUDE_PROJECT_DIR=$ROOT で起動。
# env CLAUDE_CODE_SESSION_ID=$SESSION_KEY を渡す(空文字なら未設定相当)。
# stdin JSON には session_id を含めない(env 経路を検証)。
# stdout を OUT、exit code を CODE に格納。
run_hook() {
  local fp="$1"
  local json
  json=$(jq -cn --arg fp "$fp" '{tool_input:{file_path:$fp}}')
  OUT=$(printf '%s' "$json" | CLAUDE_PROJECT_DIR="$ROOT" CLAUDE_CODE_SESSION_ID="$SESSION_KEY" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
  CODE=$?
}

# env を一切渡さず、stdin JSON の session_id のみでフックを起動する(フォールバック経路の検証)。
# 引数: file_path  stdin_session_id
run_hook_stdin_only() {
  local fp="$1" sid="$2"
  local json
  json=$(jq -cn --arg fp "$fp" --arg sid "$sid" '{tool_input:{file_path:$fp},session_id:$sid}')
  OUT=$(printf '%s' "$json" | env -u CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR="$ROOT" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
  CODE=$?
}

# env と stdin の双方に session_id を渡す(env 優先を検証)。
# 引数: file_path  env_session_id  stdin_session_id
run_hook_env_and_stdin() {
  local fp="$1" envsid="$2" stdinsid="$3"
  local json
  json=$(jq -cn --arg fp "$fp" --arg sid "$stdinsid" '{tool_input:{file_path:$fp},session_id:$sid}')
  OUT=$(printf '%s' "$json" | CLAUDE_PROJECT_DIR="$ROOT" CLAUDE_CODE_SESSION_ID="$envsid" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
  CODE=$?
}

WORKER_MODE_ENV=(env)

# permissionDecision を OUT から取り出す(なければ空)
decision() { printf '%s' "$OUT" | jq -r '.hookSpecificOutput.permissionDecision // ""' 2>/dev/null; }

assert_allow() {
  local name="$1"
  if [ "$CODE" -eq 0 ] && [ -z "$(decision)" ]; then
    echo "ok   - $name (allow: exit0, no decision)"; pass=$((pass+1))
  else
    echo "FAIL - $name (expected allow; CODE=$CODE decision=$(decision) OUT=$OUT)"; fail=$((fail+1))
  fi
}

assert_deny() {
  local name="$1"
  if [ "$CODE" -eq 0 ] && [ "$(decision)" = "deny" ]; then
    echo "ok   - $name (deny)"; pass=$((pass+1))
  else
    echo "FAIL - $name (expected deny; CODE=$CODE decision=$(decision) OUT=$OUT)"; fail=$((fail+1))
  fi
}

# --- ケース1: 承認済み slug + 新パスに approved の design-review.md → .heyyou 外編集が許可 ---
setup
set_gate "change-ai-team-flow"
make_review "change-ai-team-flow" "approved"
run_hook "claude/hooks/commit-gate.sh"
assert_allow "approved slug + gates/<key> design-review.md approved で .heyyou 外編集を許可"
teardown

# --- ケース2: design-review.md が欠落 → deny ---
setup
set_gate "change-ai-team-flow"   # review ファイルは作らない
run_hook "src/app.ts"
assert_deny "design-review.md 欠落で deny"
teardown

# --- ケース3: verdict が approved 以外(rejected) → deny ---
setup
set_gate "change-ai-team-flow"
make_review "change-ai-team-flow" "rejected"
run_hook "src/app.ts"
assert_deny "未承認(verdict=rejected)で deny"
teardown

# --- ケース4: file_path に .. を含む → deny(既存の .. 拒否が維持されている) ---
setup
set_gate "change-ai-team-flow"
make_review "change-ai-team-flow" "approved"
run_hook "../etc/passwd"
assert_deny "file_path に .. を含むと deny(既存防御の維持)"
teardown

# --- ケース5: slug に英数字ハイフンアンダースコア以外を含む(スラッシュ) → deny ---
setup
set_gate "foo-slug"          # gate ファイル名は正当なまま、中身の slug を不正にする
printf '%s\n' "foo/bar" > "$ROOT/.heyyou/state/gates/$SESSION_KEY"
run_hook "src/app.ts"
assert_deny "slug に / を含むと deny(slug 文字集合制限)"
teardown

# --- ケース6: slug にドット(..) → deny(. は許可外文字) ---
setup
printf '%s\n' "..evil" > "$ROOT/.heyyou/state/gates/$SESSION_KEY"
run_hook "src/app.ts"
assert_deny "slug に . を含むと deny(slug 文字集合制限)"
teardown

# --- ケース7: .heyyou/* パスは素通り(allow) ---
setup
# gate も review も無い状態でも .heyyou 配下は許可リストで素通り
run_hook ".heyyou/tasks/change-ai-team-flow/design.md"
assert_allow ".heyyou/* パスは素通り(allow)"
teardown

# --- ケース8: ネストした */.heyyou/* パスも素通り ---
setup
run_hook "/abs/project/.heyyou/state/gates/test-sess"
assert_allow "*/.heyyou/* パスは素通り(allow)"
teardown

# --- ケース9: file_path 無し(空)は素通り ---
setup
run_hook ""
assert_allow "file_path 無しは素通り(allow)"
teardown

# --- ケース10: claude memory ストアは素通り ---
setup
run_hook "/home/u/.claude/projects/p/memory/notes.md"
assert_allow "claude memory ストアは素通り(allow)"
teardown

# --- ケース11: business モードは素通り(gate 一切無視) ---
setup
WORKER_MODE_ENV=(env CLAUDE_WORKER_MODE=business)
run_hook "src/app.ts"
assert_allow "business モードは素通り(allow)"
WORKER_MODE_ENV=(env)
teardown

# --- ケース12: このセッションの gate ファイルが無い → deny ---
setup
run_hook "src/app.ts"
assert_deny "gate ファイルが無いと deny"
teardown

# --- ケース13: gate が空 → deny ---
setup
: > "$ROOT/.heyyou/state/gates/$SESSION_KEY"
run_hook "src/app.ts"
assert_deny "gate が空だと deny"
teardown

# --- ケース14: 自己ロック検証 — gate=change-ai-team-flow のまま別の dotfiles ファイル編集が通る ---
setup
set_gate "change-ai-team-flow"
make_review "change-ai-team-flow" "approved"
run_hook "claude/hooks/review-gate.sh"
assert_allow "自己ロック検証: design-review.md 複製が効き .heyyou 外ファイル編集が通る"
teardown

# --- ケース15: session key が空(env 空 & stdin に session_id 無し) → fail-closed deny ---
setup
SESSION_KEY=""            # env で空文字 → 未設定相当
set_gate "change-ai-team-flow" "test-sess"   # 別 key には gate がある
make_review "change-ai-team-flow" "approved"
# stdin にも session_id を入れない素の JSON で起動
json=$(jq -cn --arg fp "src/app.ts" '{tool_input:{file_path:$fp}}')
OUT=$(printf '%s' "$json" | env -u CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR="$ROOT" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
CODE=$?
assert_deny "session key が空(env空 & stdin無し)で fail-closed deny"
teardown

# --- ケース16: session key に不正文字(スラッシュ) → deny(新規分岐) ---
setup
SESSION_KEY="bad/key"
set_gate "change-ai-team-flow" "test-sess"   # 正当な key には gate を置く(到達しないこと確認)
make_review "change-ai-team-flow" "approved"
run_hook "src/app.ts"
assert_deny "session key に / を含むと deny(key 文字集合制限)"
teardown

# --- ケース17: session key に .. を含む(トラバーサル) → deny ---
setup
SESSION_KEY="..traversal"
run_hook "src/app.ts"
assert_deny "session key に . を含むと deny(トラバーサル防止)"
teardown

# --- ケース18: env 経路 — stdin に session_id 無くても env key の gate を読む(allow) ---
setup
SESSION_KEY="env-only-sess"
set_gate "change-ai-team-flow"   # env key の gate
make_review "change-ai-team-flow" "approved"
run_hook "src/app.ts"
assert_allow "env CLAUDE_CODE_SESSION_ID の gate を読んで allow(env 経路)"
teardown

# --- ケース19: stdin フォールバック — env 未設定なら stdin の session_id の gate を読む(allow) ---
setup
set_gate "change-ai-team-flow" "stdin-sess"   # stdin の session_id に対応する gate
make_review "change-ai-team-flow" "approved"
run_hook_stdin_only "src/app.ts" "stdin-sess"
assert_allow "env 未設定時は stdin session_id の gate を読んで allow(フォールバック)"
teardown

# --- ケース20: env 優先 — env=A / stdin=B のとき gates/A を読む(B は読まない) ---
# gates/A に approved slug、gates/B には未承認 slug を置き、allow になれば A が使われた証左。
setup
printf '%s\n' "change-ai-team-flow" > "$ROOT/.heyyou/state/gates/keyA"
make_review "change-ai-team-flow" "approved"
printf '%s\n' "other-slug" > "$ROOT/.heyyou/state/gates/keyB"
make_review "other-slug" "rejected"
run_hook_env_and_stdin "src/app.ts" "keyA" "keyB"
assert_allow "env=keyA / stdin=keyB のとき gates/keyA を読んで allow(env 優先)"
teardown

# --- ケース21: env 優先(逆) — env=keyB(未承認) / stdin=keyA(承認)のとき gates/keyB を読み deny ---
setup
printf '%s\n' "change-ai-team-flow" > "$ROOT/.heyyou/state/gates/keyA"
make_review "change-ai-team-flow" "approved"
printf '%s\n' "other-slug" > "$ROOT/.heyyou/state/gates/keyB"
make_review "other-slug" "rejected"
run_hook_env_and_stdin "src/app.ts" "keyB" "keyA"
assert_deny "env=keyB(未承認)/ stdin=keyA(承認)のとき gates/keyB を読んで deny(env 優先で stdin に依存しない)"
teardown

# --- ケース22: 並行性 — gates/keyA と gates/keyB に別 slug。env=keyA で走ると keyA のみ判定対象 ---
setup
# keyA: 承認済み / keyB: 全く別の(未承認)slug。keyA で走らせて allow なら keyB は無干渉。
printf '%s\n' "task-a" > "$ROOT/.heyyou/state/gates/keyA"
make_review "task-a" "approved"
printf '%s\n' "task-b" > "$ROOT/.heyyou/state/gates/keyB"
make_review "task-b" "rejected"
SESSION_KEY="keyA"
run_hook "src/app.ts"
assert_allow "並行性: env=keyA は gates/keyA(task-a 承認)のみ判定、keyB の未承認は無干渉(allow)"
teardown

# --- ケース23: 並行性(逆) — 同じ並びで env=keyB で走ると keyB の未承認で deny(keyA は無干渉) ---
setup
printf '%s\n' "task-a" > "$ROOT/.heyyou/state/gates/keyA"
make_review "task-a" "approved"
printf '%s\n' "task-b" > "$ROOT/.heyyou/state/gates/keyB"
make_review "task-b" "rejected"
SESSION_KEY="keyB"
run_hook "src/app.ts"
assert_deny "並行性: env=keyB は gates/keyB(task-b 未承認)で deny、keyA の承認は無干渉(deny)"
teardown

echo "------------------------------------------"
echo "review-gate: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
