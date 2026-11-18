#!/usr/bin/env python3
"""terminal-browser のコマンドパレットから bookmarks.toml のブックマークを開く・追加・削除する。

パレット(register-app)から起動されると zellij のフローティングペインを開き、その中で --ui として自分を実行し直す。
"""
import sys

# tomllib は 3.11 から。zellij サーバーの PATH では /usr/bin/python3(3.9)が選ばれうるため、import より前に確認する
if sys.version_info < (3, 11):
    sys.stderr.write("tb-bookmark: Python 3.11 以上が必要です\n")
    sys.exit(1)

import argparse
import json
import os
import shutil
import socket
import subprocess
import tomllib
import uuid
from pathlib import Path

DEFAULT_FILE = Path.home() / "dotfiles" / ".heyyou" / "bookmarks.toml"
FZF_FALLBACK_DIRS = [Path.home() / ".local" / "share" / "mise" / "shims", Path("/opt/homebrew/bin")]
APPS = [
    ("heyyou-bookmark-open", "Bookmarks: Open", "open"),
    ("heyyou-bookmark-add", "Bookmarks: Add current page", "add"),
    ("heyyou-bookmark-delete", "Bookmarks: Delete", "delete"),
]
# 1: 一致する行が無いまま Enter、130: Esc / Ctrl-C
FZF_CANCEL_CODES = (1, 130)


class Cancelled(Exception):
    pass


def clean(text):
    return "".join(" " if ord(c) < 0x20 or 0x7F <= ord(c) <= 0x9F else c for c in text).strip()


def toml_str(value):
    out = []
    for c in value:
        if c == '"':
            out.append('\\"')
        elif c == "\\":
            out.append("\\\\")
        elif ord(c) < 0x20 or ord(c) == 0x7F:
            out.append(f"\\u{ord(c):04x}")
        else:
            out.append(c)
    return '"' + "".join(out) + '"'


def bookmark_block(name, url):
    return f"[[bookmarks]]\nname = {toml_str(name)}\nurl = {toml_str(url)}\n"


def dump_bookmarks(items):
    return "\n".join(bookmark_block(b["name"], b["url"]) for b in items)


def load_bookmarks(path):
    if not path.exists():
        return []
    with path.open("rb") as f:
        data = tomllib.load(f)
    raw = data.get("bookmarks", [])
    if not isinstance(raw, list) or not all(isinstance(b, dict) for b in raw):
        raise ValueError(f"bookmarks の形式が不正です: {path}")
    return [{"name": str(b.get("name", "")), "url": str(b.get("url", ""))} for b in raw]


def append_bookmark(path, name, url):
    existing = path.read_bytes() if path.exists() else b""
    if not existing.strip():
        sep = ""
    elif existing.endswith(b"\n"):
        sep = "\n"
    else:
        sep = "\n\n"
    with path.open("a", encoding="utf-8") as f:
        f.write(sep + bookmark_block(name, url))


def write_bookmarks(path, items):
    if path.exists():
        shutil.copy2(path, path.with_name(path.name + ".bak"))
    tmp = path.with_name(path.name + ".tmp")
    try:
        tmp.write_text(dump_bookmarks(items), encoding="utf-8")
        os.replace(tmp, path)
    finally:
        tmp.unlink(missing_ok=True)


def request(sock_path, payload, timeout=5.0):
    message = dict(payload, id=uuid.uuid4().hex)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)
        s.connect(sock_path)
        s.sendall((json.dumps(message) + "\n").encode())
        buf = b""
        while b"\n" not in buf:
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
    line = buf.split(b"\n", 1)[0]
    if not line.strip():
        raise RuntimeError("ブラウザから応答がありません")
    reply = json.loads(line)
    if not reply.get("ok"):
        raise RuntimeError(f"ブラウザがエラーを返しました: {reply.get('error')}")
    return reply.get("data") or {}


def active_tab(sock_path):
    for tab in request(sock_path, {"cmd": "targets"}).get("tabs") or []:
        if tab.get("active"):
            return tab
    raise RuntimeError("前面のタブが見つかりません")


def find_fzf():
    found = shutil.which("fzf")
    if found:
        return found
    for d in FZF_FALLBACK_DIRS:
        candidate = d / "fzf"
        if os.access(candidate, os.X_OK):
            return str(candidate)
    raise RuntimeError("fzf が見つかりません")


def fzf_pick(items, multi, prompt, runner=subprocess.run):
    lines = [f"{i}\t{clean(b['name'])}\t{clean(b['url'])}" for i, b in enumerate(items)]
    args = [find_fzf(), "--delimiter", "\t", "--with-nth", "2..", "--prompt", prompt]
    if multi:
        args.append("-m")
    result = runner(args, input="\n".join(lines) + "\n", text=True, stdout=subprocess.PIPE)
    if result.returncode in FZF_CANCEL_CODES:
        raise Cancelled()
    if result.returncode != 0:
        raise RuntimeError(f"fzf が終了コード {result.returncode} で終わりました")
    return [int(line.split("\t", 1)[0]) for line in result.stdout.splitlines() if line]


def ask(prompt, input_fn):
    try:
        return input_fn(prompt)
    except (EOFError, KeyboardInterrupt):
        raise Cancelled() from None


def cmd_open(sock_path, path, input_fn, runner=subprocess.run):
    items = load_bookmarks(path)
    if not items:
        raise RuntimeError(f"ブックマークがありません: {path}")
    picked = fzf_pick(items, False, "open> ", runner)
    if not picked:
        raise Cancelled()
    request(sock_path, {"cmd": "open-tab", "url": items[picked[0]]["url"]})
    return None


def cmd_add(sock_path, path, input_fn, runner=subprocess.run):
    tab = active_tab(sock_path)
    url = (tab.get("url") or "").strip()
    if not url or url == "about:blank":
        raise RuntimeError("前面のタブに URL がありません")
    for b in load_bookmarks(path):
        if b["url"] == url:
            return f"すでに登録されています: {clean(b['name'])}"
    default = clean(tab.get("title") or "") or url
    print(f"URL : {clean(url)}\n既定: {default}")
    name = clean(ask("名前(空 Enter で既定、Ctrl-C でキャンセル): ", input_fn)) or default
    append_bookmark(path, name, url)
    return None


def cmd_delete(sock_path, path, input_fn, runner=subprocess.run):
    items = load_bookmarks(path)
    if not items:
        raise RuntimeError(f"ブックマークがありません: {path}")
    picked = set(fzf_pick(items, True, "delete> ", runner))
    if not picked:
        raise Cancelled()
    for i in sorted(picked):
        print(f"  - {clean(items[i]['name'])}")
    if ask(f"{len(picked)} 件を削除しますか? [y/N] ", input_fn).strip().lower() != "y":
        raise Cancelled()
    write_bookmarks(path, [b for i, b in enumerate(items) if i not in picked])
    return None


COMMANDS = {"open": cmd_open, "add": cmd_add, "delete": cmd_delete}


def pause(input_fn):
    try:
        input_fn("Enter で閉じます")
    except (EOFError, KeyboardInterrupt):
        pass


def run_ui(cmd, sock_path, path, input_fn=input, runner=subprocess.run):
    try:
        notice = COMMANDS[cmd](sock_path, path, input_fn, runner)
    except Cancelled:
        return 0
    except (RuntimeError, OSError, ValueError, IndexError) as e:
        print(f"tb-bookmark: {clean(str(e))}", file=sys.stderr)
        pause(input_fn)
        return 1
    if notice:
        print(notice)
        pause(input_fn)
    return 0


def notify(message, runner=subprocess.run):
    script = ["-e", "on run argv", "-e", 'display notification (item 1 of argv) with title "tb-bookmark"', "-e", "end run"]
    runner(["osascript", *script, message], check=False)


def launch_in_zellij(cmd, sock_path, path, env, runner=subprocess.run):
    if not env.get("ZELLIJ"):
        notify("zellij の中で開いたブラウザでのみ使えます", runner)
        return 1
    args = [
        "zellij", "run", "-f", "-c", "-n", "bookmarks", "--",
        sys.executable, str(Path(__file__).resolve()), cmd, "--ui",
        "--socket", sock_path, "--file", str(path.resolve()),
    ]
    try:
        return runner(args, check=False).returncode
    except OSError as e:
        notify(f"zellij を起動できませんでした: {e}", runner)
        return 1


def register(runner=subprocess.run):
    bin_path = str(Path(__file__).resolve())
    for app_id, name, arg in APPS:
        runner(["terminal-browser", "register-app", "--name", name, "--bin", bin_path, "--id", app_id, "--args", arg], check=True)
    return 0


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="tb-bookmark")
    parser.add_argument("cmd", choices=[*COMMANDS, "register"])
    parser.add_argument("--ui", action="store_true")
    parser.add_argument("--socket")
    parser.add_argument("--file")
    return parser.parse_args(argv)


def main(argv=None, env=None):
    args = parse_args(argv)
    env = os.environ if env is None else env
    if args.cmd == "register":
        return register()
    path = Path(args.file or env.get("TB_BOOKMARKS_FILE") or DEFAULT_FILE).expanduser()
    if args.ui:
        if not args.socket:
            print("tb-bookmark: --ui には --socket が必要です", file=sys.stderr)
            return 1
        return run_ui(args.cmd, args.socket, path)
    sock_path = env.get("TERMINAL_BROWSER_INTEROP_TARGET")
    if not sock_path:
        print("tb-bookmark: terminal-browser のコマンドパレットから起動してください", file=sys.stderr)
        return 1
    return launch_in_zellij(args.cmd, sock_path, path, env)


if __name__ == "__main__":
    sys.exit(main())
