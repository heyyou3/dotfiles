#!/usr/bin/env bash
# load-context.sh (plugin 版) のテスト。bats が無い環境向けの素の bash ランナー。
# 変更点は `dir="${CLAUDE_PLUGIN_ROOT:-$HOME/dotfiles}/ai-agent"` の 1 行。
# 本物の dotfiles を汚さないよう mktemp 配下に ai-agent を作り、
# CLAUDE_PLUGIN_ROOT / HOME を差し替えて実行する。
set -uo pipefail

HOOK="/Users/heyyou/dotfiles/claude/plugins/heyyou/hooks/load-context.sh"

pass=0
fail=0

# run_plugin <plugin_root> <mode_or_UNSET>
# CLAUDE_PLUGIN_ROOT 経路で実行。HOME は誤フォールバックを検出するため別の空ディレクトリへ向ける。
run_plugin() {
  local root="$1" mode="$2"
  if [ "$mode" = "UNSET" ]; then
    OUT=$(HOME="$HOMEBOGUS" CLAUDE_PLUGIN_ROOT="$root" bash "$HOOK"); RC=$?
  else
    OUT=$(HOME="$HOMEBOGUS" CLAUDE_PLUGIN_ROOT="$root" CLAUDE_WORKER_MODE="$mode" bash "$HOOK"); RC=$?
  fi
}

# run_fallback <home> <mode_or_UNSET>
# CLAUDE_PLUGIN_ROOT 未設定。$HOME/dotfiles/ai-agent への degrade 経路を実行。
run_fallback() {
  local home="$1" mode="$2"
  if [ "$mode" = "UNSET" ]; then
    OUT=$(env -u CLAUDE_PLUGIN_ROOT HOME="$home" bash "$HOOK"); RC=$?
  else
    OUT=$(env -u CLAUDE_PLUGIN_ROOT HOME="$home" CLAUDE_WORKER_MODE="$mode" bash "$HOOK"); RC=$?
  fi
}

expect_eq() {
  local name="$1" want="$2"
  if [ "$RC" -eq 0 ] && [ "$OUT" = "$want" ]; then
    pass=$((pass+1)); echo "ok   - $name"
  else
    fail=$((fail+1)); echo "FAIL - $name (rc=$RC out=[$OUT] want=[$want])"
  fi
}

TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

# CLAUDE_PLUGIN_ROOT が向く同梱版 ai-agent(全ファイルあり)
ROOT="$TMPROOT/plugin"
mkdir -p "$ROOT/ai-agent"
printf 'CORE-CONTENT\n'     > "$ROOT/ai-agent/core.md"
printf 'ENGINEER-CONTENT\n' > "$ROOT/ai-agent/engineer.md"
printf 'BUSINESS-CONTENT\n' > "$ROOT/ai-agent/business.md"
# 不正 mode がそのまま展開されれば "$dir/evil.md" を cat する。作っておき、
# それが出力されないこと(=フォールバックしたこと)を検証する。
printf 'EVIL-CONTENT\n'     > "$ROOT/ai-agent/evil.md"

# HOME が誤って参照された場合に検出できるよう、HOME 側に別内容を仕込む
HOMEBOGUS="$TMPROOT/homebogus"
mkdir -p "$HOMEBOGUS/dotfiles/ai-agent"
printf 'HOME-CORE\n'     > "$HOMEBOGUS/dotfiles/ai-agent/core.md"
printf 'HOME-ENGINEER\n' > "$HOMEBOGUS/dotfiles/ai-agent/engineer.md"

# --- 1) CLAUDE_PLUGIN_ROOT 設定時、同梱版を参照する ---
run_plugin "$ROOT" "engineer"
expect_eq "PLUGIN_ROOT 設定+engineer で 同梱版 core+engineer を出力" $'CORE-CONTENT\nENGINEER-CONTENT'

# --- 3) mode 切り替え: business ---
run_plugin "$ROOT" "business"
expect_eq "PLUGIN_ROOT 設定+business で 同梱版 core+business を出力" $'CORE-CONTENT\nBUSINESS-CONTENT'

# env 未設定の mode → engineer 既定(PLUGIN_ROOT 経路)
run_plugin "$ROOT" "UNSET"
expect_eq "WORKER_MODE 未設定で engineer 既定" $'CORE-CONTENT\nENGINEER-CONTENT'

# --- 4) 不正 mode は engineer にフォールバック(任意ファイルを cat しない) ---
run_plugin "$ROOT" "evil"
expect_eq "不正 mode 'evil' は engineer にフォールバック(evil.md を読まない)" $'CORE-CONTENT\nENGINEER-CONTENT'

run_plugin "$ROOT" "../../etc/passwd"
expect_eq "パストラバーサル mode は engineer にフォールバック" $'CORE-CONTENT\nENGINEER-CONTENT'

# --- 2) CLAUDE_PLUGIN_ROOT 未設定 → $HOME/dotfiles/ai-agent へ degrade ---
run_fallback "$HOMEBOGUS" "engineer"
expect_eq "PLUGIN_ROOT 未設定で HOME/dotfiles/ai-agent へフォールバック" $'HOME-CORE\nHOME-ENGINEER'

# --- 5) 参照先ファイルが無い場合 → 何も出さず exit 0 ---
EMPTY="$TMPROOT/empty"
mkdir -p "$EMPTY/ai-agent"
run_plugin "$EMPTY" "engineer"
expect_eq "ファイルが無ければ何も出さず正常終了" ""

# core.md 欠落 → overlay のみ(分岐: 1ファイルのみ存在)
COREONLY="$TMPROOT/coreonly"
mkdir -p "$COREONLY/ai-agent"
printf 'ONLY-ENGINEER\n' > "$COREONLY/ai-agent/engineer.md"
run_plugin "$COREONLY" "engineer"
expect_eq "core.md 欠落時は engineer.md のみ出力" "ONLY-ENGINEER"

# overlay 欠落 → core のみ
NOOVERLAY="$TMPROOT/nooverlay"
mkdir -p "$NOOVERLAY/ai-agent"
printf 'ONLY-CORE\n' > "$NOOVERLAY/ai-agent/core.md"
run_plugin "$NOOVERLAY" "engineer"
expect_eq "overlay 欠落時は core.md のみ出力" "ONLY-CORE"

echo
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
