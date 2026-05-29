#!/usr/bin/env bash
# review-gate.sh の動作確認テスト。
# フックを実際に標準入力へ JSON を渡して起動し、exit code と permissionDecision を assert する。
# 本体ロジックは変更せず、観点を網羅する素直な bash テスト。
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/review-gate.sh"

pass=0
fail=0

# 一時プロジェクトを作って毎回まっさらな状態から検査する
setup() {
  ROOT=$(mktemp -d)
  mkdir -p "$ROOT/.heyyou/state"
}
teardown() { rm -rf "$ROOT"; }

# gate に slug を記録する
set_gate() { printf '%s\n' "$1" > "$ROOT/.heyyou/state/gate"; }

# 指定 slug の design-review.md を作る(verdict 付き)
make_review() {
  local slug="$1" verdict="$2"
  mkdir -p "$ROOT/.heyyou/tasks/$slug/reviewer"
  printf 'verdict: %s\n' "$verdict" > "$ROOT/.heyyou/tasks/$slug/reviewer/design-review.md"
}

# フック実行: 引数 = file_path(空可)。CLAUDE_PROJECT_DIR=$ROOT で起動。
# stdout を OUT、exit code を CODE に格納。
run_hook() {
  local fp="$1"
  local json
  json=$(jq -cn --arg fp "$fp" '{tool_input:{file_path:$fp}}')
  OUT=$(printf '%s' "$json" | CLAUDE_PROJECT_DIR="$ROOT" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
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
assert_allow "approved slug + 新パス design-review.md approved で .heyyou 外編集を許可"
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

# --- ケース5: slug に英数字ハイフンアンダースコア以外を含む(スラッシュ) → deny(新規分岐) ---
setup
set_gate "foo/bar"
run_hook "src/app.ts"
assert_deny "slug に / を含むと deny(新規文字集合制限)"
teardown

# --- ケース6: slug にドット(..) → deny(新規文字集合制限。. は許可外文字) ---
setup
set_gate "..evil"
run_hook "src/app.ts"
assert_deny "slug に . を含むと deny(新規文字集合制限)"
teardown

# --- ケース7: .heyyou/* パスは素通り(allow) ---
setup
# gate も review も無い状態でも .heyyou 配下は許可リストで素通り
run_hook ".heyyou/tasks/change-ai-team-flow/design.md"
assert_allow ".heyyou/* パスは素通り(allow)"
teardown

# --- ケース8: ネストした */.heyyou/* パスも素通り ---
setup
run_hook "/abs/project/.heyyou/state/gate"
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

# --- ケース12: gate ファイルが無い → deny ---
setup
run_hook "src/app.ts"
assert_deny "gate ファイルが無いと deny"
teardown

# --- ケース13: gate が空 → deny ---
setup
: > "$ROOT/.heyyou/state/gate"
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

echo "------------------------------------------"
echo "review-gate: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
