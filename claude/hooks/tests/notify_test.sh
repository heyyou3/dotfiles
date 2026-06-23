#!/bin/bash
# Tests for claude/hooks/notify.sh (cross-platform notification hook).
#
# 方針: 本番コードは変更しない。PATH 先頭に stub(uname / terminal-notifier /
# notify-send / jq)を置いて差し替え、stub は呼び出し引数を一時ファイルに記録する。
# 各テストはその記録内容を assert する。
#
# 実行: bash claude/hooks/tests/notify_test.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SH="$SCRIPT_DIR/../notify.sh"

pass=0
fail=0

# --- stub 環境を作るヘルパ --------------------------------------------------
# $1: uname が返す OS 文字列 (Darwin / Linux)。空なら uname stub を置かない。
# 戻り値経由ではなく、グローバル変数 STUB_BIN / CALL_LOG を設定する。
setup_stub_env() {
  local uname_os="$1"
  shift
  # $@: 用意するバックエンド stub 名(terminal-notifier / notify-send)

  STUB_DIR="$(mktemp -d)"
  STUB_BIN="$STUB_DIR/bin"
  CALL_LOG="$STUB_DIR/calls.log"
  mkdir -p "$STUB_BIN"
  : >"$CALL_LOG"

  # jq stub: notify.sh は .cwd と .notification_type を引く。
  # 入力 JSON から該当値を返す簡易実装(本物の jq に依存しないため stub 化)。
  cat >"$STUB_BIN/jq" <<EOF
#!/bin/bash
# args: -r '.field'
input=\$(cat)
field="\${2#.}"
case "\$field" in
  cwd) printf '%s\n' "\$CWD_VALUE" ;;
  notification_type) printf '%s\n' "\$NTYPE_VALUE" ;;
esac
EOF
  chmod +x "$STUB_BIN/jq"

  if [ -n "$uname_os" ]; then
    cat >"$STUB_BIN/uname" <<EOF
#!/bin/bash
printf '%s\n' "$uname_os"
EOF
    chmod +x "$STUB_BIN/uname"
  fi

  # 各バックエンド stub: 引数を CALL_LOG に1行で記録する。
  local tool
  for tool in "$@"; do
    cat >"$STUB_BIN/$tool" <<EOF
#!/bin/bash
{ printf '%s' "$tool"; for a in "\$@"; do printf '\t%s' "\$a"; done; printf '\n'; } >>"$CALL_LOG"
EOF
    chmod +x "$STUB_BIN/$tool"
  done
}

teardown_stub_env() {
  [ -n "${STUB_DIR:-}" ] && rm -rf "$STUB_DIR"
}

# notify.sh を stub PATH 配下で実行する。
# $1: cwd の値, $2: notification_type の値
run_notify() {
  local cwd="$1"
  local ntype="$2"
  # jq stub に値を渡すための env、CALL_LOG を stub に教える env。
  # ZELLIJ_SESSION_NAME はテスト環境から漏れうるので env -u で明示的に外す。
  env -u ZELLIJ_SESSION_NAME \
    CWD_VALUE="$cwd" NTYPE_VALUE="$ntype" CALL_LOG="$CALL_LOG" PATH="$STUB_BIN:$PATH" \
    bash "$NOTIFY_SH" <<<'{}'
  return $?
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass=$((pass + 1))
    printf '  ok   %s\n' "$desc"
  else
    fail=$((fail + 1))
    printf '  FAIL %s\n    expected: [%s]\n    actual:   [%s]\n' "$desc" "$expected" "$actual"
  fi
}

assert_empty_log() {
  local desc="$1"
  if [ ! -s "$CALL_LOG" ]; then
    pass=$((pass + 1))
    printf '  ok   %s\n' "$desc"
  else
    fail=$((fail + 1))
    printf '  FAIL %s (log not empty)\n%s\n' "$desc" "$(cat "$CALL_LOG")"
  fi
}

# ---------------------------------------------------------------------------
# Case 1: uname=Darwin → terminal-notifier が期待引数で呼ばれる
# ---------------------------------------------------------------------------
echo "Case 1: Darwin -> terminal-notifier args"
setup_stub_env Darwin terminal-notifier notify-send
run_notify "/x/myproj" "stop"
expected=$(printf 'terminal-notifier\t-title\tClaude Code\t-subtitle\tmyproj\t-message\tタスク完了\t-sound\tGlass')
assert_eq "terminal-notifier called with -title/-subtitle/-message/-sound" \
  "$expected" "$(cat "$CALL_LOG")"
teardown_stub_env

# ---------------------------------------------------------------------------
# Case 2: uname=Linux → notify-send が "Claude Code" / "<project>: <msg>" で呼ばれる
# ---------------------------------------------------------------------------
echo "Case 2: Linux -> notify-send args"
setup_stub_env Linux terminal-notifier notify-send
run_notify "/x/myproj" "stop"
expected=$(printf 'notify-send\tClaude Code\tmyproj: タスク完了')
assert_eq "notify-send called with summary and 'project: message' body" \
  "$expected" "$(cat "$CALL_LOG")"
teardown_stub_env

# ---------------------------------------------------------------------------
# Case 3: notification_type 別の出し分け(Darwin で sound/message を確認)
# ---------------------------------------------------------------------------
echo "Case 3a: permission_prompt -> 許可待ち / Ping"
setup_stub_env Darwin terminal-notifier notify-send
run_notify "/x/p" "permission_prompt"
expected=$(printf 'terminal-notifier\t-title\tClaude Code\t-subtitle\tp\t-message\t許可待ち\t-sound\tPing')
assert_eq "permission_prompt -> message=許可待ち sound=Ping" "$expected" "$(cat "$CALL_LOG")"
teardown_stub_env

echo "Case 3b: stop -> タスク完了 / Glass"
setup_stub_env Darwin terminal-notifier notify-send
run_notify "/x/p" "stop"
expected=$(printf 'terminal-notifier\t-title\tClaude Code\t-subtitle\tp\t-message\tタスク完了\t-sound\tGlass')
assert_eq "stop -> message=タスク完了 sound=Glass" "$expected" "$(cat "$CALL_LOG")"
teardown_stub_env

echo "Case 3c: その他(unknown) -> 通知 / sound 空"
setup_stub_env Darwin terminal-notifier notify-send
run_notify "/x/p" "some_other_type"
expected=$(printf 'terminal-notifier\t-title\tClaude Code\t-subtitle\tp\t-message\t通知\t-sound\t')
assert_eq "default -> message=通知 sound=empty" "$expected" "$(cat "$CALL_LOG")"
teardown_stub_env

echo "Case 3d: idle_prompt -> 無通知"
setup_stub_env Darwin terminal-notifier notify-send
run_notify "/x/p" "idle_prompt"
assert_empty_log "idle_prompt -> no backend called"
teardown_stub_env

# ---------------------------------------------------------------------------
# Case 4: バックエンド不在 → 何も呼ばれず exit 0
# ---------------------------------------------------------------------------
echo "Case 4a: Darwin, terminal-notifier 不在 -> 何も呼ばれず exit 0"
setup_stub_env Darwin  # バックエンド stub を置かない
run_notify "/x/p" "stop"
rc=$?
assert_eq "Darwin without terminal-notifier -> exit 0" "0" "$rc"
assert_empty_log "Darwin without terminal-notifier -> no call"
teardown_stub_env

echo "Case 4b: Linux, notify-send 不在 -> 何も呼ばれず exit 0"
setup_stub_env Linux  # バックエンド stub を置かない
run_notify "/x/p" "stop"
rc=$?
assert_eq "Linux without notify-send -> exit 0" "0" "$rc"
assert_empty_log "Linux without notify-send -> no call"
teardown_stub_env

# ---------------------------------------------------------------------------
# 追加: ZELLIJ_SESSION_NAME による suffix(分岐網羅補強)
# ---------------------------------------------------------------------------
echo "Case 5: ZELLIJ_SESSION_NAME -> message に [session] suffix"
setup_stub_env Linux terminal-notifier notify-send
CWD_VALUE="/x/proj" NTYPE_VALUE="stop" CALL_LOG="$CALL_LOG" \
  ZELLIJ_SESSION_NAME="dev" PATH="$STUB_BIN:$PATH" \
  bash "$NOTIFY_SH" <<<'{}'
expected=$(printf 'notify-send\tClaude Code\tproj: タスク完了 [dev]')
assert_eq "stop with zellij session -> body has [dev] suffix" "$expected" "$(cat "$CALL_LOG")"
teardown_stub_env

# ---------------------------------------------------------------------------
echo
echo "=============================="
printf 'PASS: %d  FAIL: %d\n' "$pass" "$fail"
echo "=============================="
[ "$fail" -eq 0 ]
