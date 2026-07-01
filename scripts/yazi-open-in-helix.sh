#!/usr/bin/env bash
# yazi の opener から呼ばれ、選択ファイルを稼働中の Helix(hx)ペインで開く。
# Helix には外部から開かせる IPC が無いため、zellij の pane 操作 CLI で
# hx ペインを特定し、focus を動かさず :open <path> を送り込む。
set -uo pipefail

[ "$#" -eq 0 ] && exit 0

# zellij 外では従来どおり EDITOR で直接開く(端末を引き継ぐ)。
if [ -z "${ZELLIJ:-}" ]; then
	exec "${EDITOR:-hx}" "$@"
fi

# command=hx で起動された tiled ペインの pane-id(terminal_<id>)を特定する。
pane_id=""
if command -v jq >/dev/null 2>&1; then
	id=$(zellij action list-panes --json --command 2>/dev/null | jq -r '
		[ .[]
		  | select(.is_plugin == false and .exited == false)
		  | select((.terminal_command // "") | test("(^|/)hx(\\s|$)")) ]
		| first | .id // empty' 2>/dev/null)
	[ -n "$id" ] && pane_id="terminal_${id}"
fi

# hx ペインが見つからなければ EDITOR で新規ペインに開く(フォールバック)。
if [ -z "$pane_id" ]; then
	for f in "$@"; do
		zellij action edit "$f"
	done
	exit 0
fi

# normal mode を保証してから各ファイルを :open で開く。
zellij action write --pane-id "$pane_id" 27 # Esc
for f in "$@"; do
	abs=$(realpath -- "$f" 2>/dev/null || printf '%s' "$f")
	# 制御文字(改行/CR/ESC 等)を含むパスは :open のタイプ経路だと
	# コマンドが途中確定して残りが Helix にキー入力として注入されるため、
	# argv 渡しの edit(新規ペイン)に落として注入経路を断つ。
	if [[ "$abs" == *[[:cntrl:]]* ]]; then
		zellij action edit "$f"
		continue
	fi
	zellij action write-chars --pane-id "$pane_id" ":open ${abs}"
	zellij action write --pane-id "$pane_id" 13 # Enter
done

# 開いたファイルをそのまま編集できるよう Helix ペインへ focus を移す。
zellij action focus-pane-id "$pane_id"
