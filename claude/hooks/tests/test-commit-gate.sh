#!/usr/bin/env bash
# commit-gate.sh の動作確認テスト。
# フックを実際に標準入力へ JSON(tool_input.command, session_id)を渡して起動し、
# exit code と permissionDecision を assert する。本体ロジックは変更しない。
#
# セッション別 gate(.heyyou/state/gates/<session-key>)スキームに対応。
# session-key は env CLAUDE_CODE_SESSION_ID を第一参照し、空のとき stdin の .session_id にフォールバックする。
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/commit-gate.sh"

pass=0
fail=0

SESSION_KEY="test-sess"

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

# 新パスの diff-review.md / security-reviewer/report.md を作る
make_diff_review() {
  local slug="$1" v="$2"
  mkdir -p "$ROOT/.heyyou/tasks/$slug/reviewer"
  printf 'verdict: %s\n' "$v" > "$ROOT/.heyyou/tasks/$slug/reviewer/diff-review.md"
}
make_security() {
  local slug="$1" v="$2"
  mkdir -p "$ROOT/.heyyou/tasks/$slug/security-reviewer"
  printf 'verdict: %s\n' "$v" > "$ROOT/.heyyou/tasks/$slug/security-reviewer/report.md"
}

WORKER_MODE_ENV=(env)

# フック実行: env CLAUDE_CODE_SESSION_ID=$SESSION_KEY を渡す。stdin に session_id は含めない。
run_hook() {
  local cmd="$1"
  local json
  json=$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}}')
  OUT=$(printf '%s' "$json" | CLAUDE_PROJECT_DIR="$ROOT" CLAUDE_CODE_SESSION_ID="$SESSION_KEY" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
  CODE=$?
}

# env を渡さず stdin JSON の session_id のみで起動(フォールバック経路の検証)。
run_hook_stdin_only() {
  local cmd="$1" sid="$2"
  local json
  json=$(jq -cn --arg c "$cmd" --arg sid "$sid" '{tool_input:{command:$c},session_id:$sid}')
  OUT=$(printf '%s' "$json" | env -u CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR="$ROOT" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
  CODE=$?
}

# env と stdin の双方に session_id を渡す(env 優先を検証)。
run_hook_env_and_stdin() {
  local cmd="$1" envsid="$2" stdinsid="$3"
  local json
  json=$(jq -cn --arg c "$cmd" --arg sid "$stdinsid" '{tool_input:{command:$c},session_id:$sid}')
  OUT=$(printf '%s' "$json" | CLAUDE_PROJECT_DIR="$ROOT" CLAUDE_CODE_SESSION_ID="$envsid" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
  CODE=$?
}

decision() { printf '%s' "$OUT" | jq -r '.hookSpecificOutput.permissionDecision // ""' 2>/dev/null; }

assert_allow() {
  local name="$1"
  if [ "$CODE" -eq 0 ] && [ -z "$(decision)" ]; then
    echo "ok   - $name (allow)"; pass=$((pass+1))
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

# --- ケース1: 新パスの両ファイル approved で git commit が通る ---
setup
set_gate "change-ai-team-flow"
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "approved"
run_hook 'git commit -m "done"'
assert_allow "gates/<key> diff-review.md と security-reviewer/report.md が両方 approved で commit 許可"
teardown

# --- ケース2: diff-review.md 欠落 → deny ---
setup
set_gate "change-ai-team-flow"
make_security "change-ai-team-flow" "approved"
run_hook 'git commit -m "x"'
assert_deny "diff-review.md 欠落で deny"
teardown

# --- ケース3: security-reviewer/report.md 欠落 → deny ---
setup
set_gate "change-ai-team-flow"
make_diff_review "change-ai-team-flow" "approved"
run_hook 'git commit -m "x"'
assert_deny "security-reviewer/report.md 欠落で deny"
teardown

# --- ケース4: 片方が未承認(diff-review rejected) → deny ---
setup
set_gate "change-ai-team-flow"
make_diff_review "change-ai-team-flow" "rejected"
make_security "change-ai-team-flow" "approved"
run_hook 'git commit -m "x"'
assert_deny "diff-review が未承認で deny"
teardown

# --- ケース5: security が未承認 → deny ---
setup
set_gate "change-ai-team-flow"
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "rejected"
run_hook 'git commit -m "x"'
assert_deny "security が未承認で deny"
teardown

# --- ケース6: git commit でないコマンドは素通り(既存挙動) ---
setup
set_gate "change-ai-team-flow"
run_hook 'git status'
assert_allow "git status は対象外で素通り"
teardown

# --- ケース7: --dry-run の単一 commit は除外(既存挙動) ---
setup
set_gate "change-ai-team-flow"   # レビューファイル無しでも素通りすべき
run_hook 'git commit --dry-run'
assert_allow "git commit --dry-run は除外で素通り"
teardown

# --- ケース8: チェーン後段の本物 commit は --dry-run 除外しない(fail-closed) ---
setup
set_gate "change-ai-team-flow"   # レビュー無し → deny されるべき
run_hook 'git commit --dry-run && git commit -m real'
assert_deny "dry-run + 本物 commit のチェーンは deny(誤素通りしない)"
teardown

# --- ケース9: commit-graph は commit 検知に該当しない(境界条件) ---
setup
set_gate "change-ai-team-flow"
run_hook 'git commit-graph write'
assert_allow "git commit-graph は commit 検知に該当せず素通り"
teardown

# --- ケース10: echo \"git commit\" は対象外(後続が \") ---
setup
set_gate "change-ai-team-flow"
run_hook 'echo "git commit"'
assert_allow 'echo "git commit" は対象外で素通り'
teardown

# --- ケース11: slug に不正文字(スラッシュ) → deny ---
setup
printf '%s\n' "foo/bar" > "$ROOT/.heyyou/state/gates/$SESSION_KEY"
run_hook 'git commit -m x'
assert_deny "slug に / を含むと deny"
teardown

# --- ケース12: このセッションの gate 欠落 → deny ---
setup
run_hook 'git commit -m x'
assert_deny "gate 欠落で deny"
teardown

# --- ケース13: gate が空 → deny ---
setup
: > "$ROOT/.heyyou/state/gates/$SESSION_KEY"
run_hook 'git commit -m x'
assert_deny "gate が空で deny"
teardown

# --- ケース14: business モードは素通り ---
setup
WORKER_MODE_ENV=(env CLAUDE_WORKER_MODE=business)
run_hook 'git commit -m x'
assert_allow "business モードは素通り"
WORKER_MODE_ENV=(env)
teardown

# --- ケース15: -c key=val を挟んだ git commit も検知 ---
setup
set_gate "change-ai-team-flow"   # レビュー無し → 検知されれば deny
run_hook 'git -c user.name=x commit -m y'
assert_deny "git -c ... commit を検知し(レビュー無しで)deny"
teardown

# --- ケース16: session key が空(env 空 & stdin に session_id 無し) → fail-closed deny ---
setup
set_gate "change-ai-team-flow" "test-sess"   # 別 key には完備した gate を置く
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "approved"
json=$(jq -cn --arg c 'git commit -m x' '{tool_input:{command:$c}}')
OUT=$(printf '%s' "$json" | env -u CLAUDE_CODE_SESSION_ID CLAUDE_PROJECT_DIR="$ROOT" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
CODE=$?
assert_deny "session key が空(env空 & stdin無し)で fail-closed deny"
teardown

# --- ケース17: session key に不正文字(スラッシュ) → deny(新規分岐) ---
setup
SESSION_KEY="bad/key"
set_gate "change-ai-team-flow" "test-sess"
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "approved"
run_hook 'git commit -m x'
assert_deny "session key に / を含むと deny(key 文字集合制限)"
teardown

# --- ケース18: session key に .. を含む(トラバーサル) → deny ---
setup
SESSION_KEY="..traversal"
run_hook 'git commit -m x'
assert_deny "session key に . を含むと deny(トラバーサル防止)"
teardown

# --- ケース19: env 経路 — stdin に session_id 無くても env key の gate を読む(allow) ---
setup
SESSION_KEY="env-only-sess"
set_gate "change-ai-team-flow"
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "approved"
run_hook 'git commit -m x'
assert_allow "env CLAUDE_CODE_SESSION_ID の gate を読んで allow(env 経路)"
teardown

# --- ケース20: stdin フォールバック — env 未設定なら stdin session_id の gate を読む(allow) ---
setup
set_gate "change-ai-team-flow" "stdin-sess"
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "approved"
run_hook_stdin_only 'git commit -m x' "stdin-sess"
assert_allow "env 未設定時は stdin session_id の gate を読んで allow(フォールバック)"
teardown

# --- ケース21: env 優先 — env=keyA(承認) / stdin=keyB(未承認)のとき gates/keyA を読み allow ---
setup
printf '%s\n' "change-ai-team-flow" > "$ROOT/.heyyou/state/gates/keyA"
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "approved"
printf '%s\n' "other-slug" > "$ROOT/.heyyou/state/gates/keyB"
make_diff_review "other-slug" "rejected"
make_security "other-slug" "rejected"
run_hook_env_and_stdin 'git commit -m x' "keyA" "keyB"
assert_allow "env=keyA / stdin=keyB のとき gates/keyA を読んで allow(env 優先)"
teardown

# --- ケース22: env 優先(逆) — env=keyB(未承認) / stdin=keyA(承認)のとき gates/keyB を読み deny ---
setup
printf '%s\n' "change-ai-team-flow" > "$ROOT/.heyyou/state/gates/keyA"
make_diff_review "change-ai-team-flow" "approved"
make_security "change-ai-team-flow" "approved"
printf '%s\n' "other-slug" > "$ROOT/.heyyou/state/gates/keyB"
make_diff_review "other-slug" "rejected"
make_security "other-slug" "rejected"
run_hook_env_and_stdin 'git commit -m x' "keyB" "keyA"
assert_deny "env=keyB(未承認)/ stdin=keyA(承認)のとき gates/keyB を読んで deny(env 優先で stdin に依存しない)"
teardown

# --- ケース23: 並行性 — gates/keyA と gates/keyB に別 slug。env=keyA で走ると keyA のみ判定対象 ---
setup
printf '%s\n' "task-a" > "$ROOT/.heyyou/state/gates/keyA"
make_diff_review "task-a" "approved"
make_security "task-a" "approved"
printf '%s\n' "task-b" > "$ROOT/.heyyou/state/gates/keyB"
make_diff_review "task-b" "rejected"
make_security "task-b" "rejected"
SESSION_KEY="keyA"
run_hook 'git commit -m x'
assert_allow "並行性: env=keyA は gates/keyA(task-a 両 approved)のみ判定、keyB は無干渉(allow)"
teardown

# --- ケース24: 並行性(逆) — 同じ並びで env=keyB で走ると keyB の未承認で deny(keyA は無干渉) ---
setup
printf '%s\n' "task-a" > "$ROOT/.heyyou/state/gates/keyA"
make_diff_review "task-a" "approved"
make_security "task-a" "approved"
printf '%s\n' "task-b" > "$ROOT/.heyyou/state/gates/keyB"
make_diff_review "task-b" "rejected"
make_security "task-b" "rejected"
SESSION_KEY="keyB"
run_hook 'git commit -m x'
assert_deny "並行性: env=keyB は gates/keyB(task-b 未承認)で deny、keyA は無干渉(deny)"
teardown

echo "------------------------------------------"
echo "commit-gate: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
