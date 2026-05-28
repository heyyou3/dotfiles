#!/usr/bin/env bash
# SessionStart フックの実体。CLAUDE_WORKER_MODE に応じて core + overlay のマニュアルを出力する。
# mode はホワイトリストで完全一致検証し、不正値は engineer にフォールバック(未検証の env 値で
# 任意ファイルを cat しない)。ファイルが無ければ何も出さず正常終了。
set -uo pipefail

dir="$HOME/dotfiles/ai-agent"
mode="${CLAUDE_WORKER_MODE:-engineer}"
case "$mode" in
  engineer|business) ;;
  *) mode=engineer ;;
esac

for f in "$dir/core.md" "$dir/${mode}.md"; do
  [ -f "$f" ] && cat "$f"
done
exit 0
