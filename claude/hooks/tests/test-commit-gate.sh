#!/usr/bin/env bash
# commit-gate.sh の動作確認テスト。
# フックを実際に標準入力へ JSON(tool_input.command)を渡して起動し、exit code と
# permissionDecision を assert する。本体ロジックは変更しない。
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/commit-gate.sh"

pass=0
fail=0

setup() {
  ROOT=$(mktemp -d)
  mkdir -p "$ROOT/.heyyou/state"
}
teardown() { rm -rf "$ROOT"; }

set_gate() { printf '%s\n' "$1" > "$ROOT/.heyyou/state/gate"; }

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

run_hook() {
  local cmd="$1"
  local json
  json=$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}}')
  OUT=$(printf '%s' "$json" | CLAUDE_PROJECT_DIR="$ROOT" "${WORKER_MODE_ENV[@]}" bash "$HOOK")
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
assert_allow "新パス diff-review.md と security-reviewer/report.md が両方 approved で commit 許可"
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
set_gate "foo/bar"
run_hook 'git commit -m x'
assert_deny "slug に / を含むと deny"
teardown

# --- ケース12: gate 欠落 → deny ---
setup
run_hook 'git commit -m x'
assert_deny "gate 欠落で deny"
teardown

# --- ケース13: gate が空 → deny ---
setup
: > "$ROOT/.heyyou/state/gate"
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

echo "------------------------------------------"
echo "commit-gate: pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
