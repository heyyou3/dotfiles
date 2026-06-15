#!/usr/bin/env bash
# heyyou プラグインの shell テストをまとめて実行する。
set -uo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$dir"/*.test.sh; do
  echo "=== $(basename "$t") ==="
  bash "$t" || rc=1
  echo
done
exit "$rc"
