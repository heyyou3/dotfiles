"""scripts/tb-bookmark.py のテスト。

実行: python3 -m unittest discover -s scripts/tests
外部コマンド(fzf / zellij / osascript / terminal-browser)は実行せず、runner と input_fn を差し替える。
"""
import importlib.util
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import tomllib
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

SCRIPT = Path(__file__).resolve().parent.parent / "tb-bookmark.py"
spec = importlib.util.spec_from_file_location("tb_bookmark", SCRIPT)
tb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tb)


class FakeRunner:
    """subprocess.run の代わり。呼ばれた引数を記録し、決めた結果を返す。"""

    def __init__(self, returncode=0, stdout=""):
        self.calls = []
        self.returncode = returncode
        self.stdout = stdout

    def __call__(self, args, **kwargs):
        self.calls.append((args, kwargs))
        return SimpleNamespace(returncode=self.returncode, stdout=self.stdout)


def fzf_selects(*indexes):
    """fzf が指定のインデックスの行を選んだときの出力を返す runner。"""
    return FakeRunner(stdout="".join(f"{i}\tname\turl\n" for i in indexes))


def answers(*values):
    """input() の代わり。順に値を返し、値が例外なら投げる。"""
    queue = list(values)
    prompts = []

    def input_fn(prompt=""):
        prompts.append(prompt)
        value = queue.pop(0)
        if isinstance(value, BaseException):
            raise value
        return value

    input_fn.prompts = prompts
    return input_fn


class FakeBrowser:
    """1 接続 1 リクエストで JSON 1 行を返す偽の interop ソケットサーバー。"""

    def __init__(self, replies):
        self.dir = tempfile.mkdtemp(dir="/tmp")
        self.path = os.path.join(self.dir, "s")
        self.replies = list(replies)
        self.requests = []
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server.bind(self.path)
        self.server.listen()
        self.thread = threading.Thread(target=self._serve, daemon=True)
        self.thread.start()

    def _serve(self):
        for reply in self.replies:
            conn, _ = self.server.accept()
            with conn:
                buf = b""
                while b"\n" not in buf:
                    chunk = conn.recv(65536)
                    if not chunk:
                        break
                    buf += chunk
                req = json.loads(buf.split(b"\n", 1)[0])
                self.requests.append(req)
                if reply is None:
                    continue  # 何も返さずに閉じる
                if isinstance(reply, bytes):
                    conn.sendall(reply)
                    continue
                conn.sendall((json.dumps(dict(reply, id=req["id"])) + "\n").encode())

    def close(self):
        self.thread.join(timeout=2)
        self.server.close()
        shutil.rmtree(self.dir, ignore_errors=True)


def tabs_reply(*tabs):
    return {"ok": True, "data": {"tabs": list(tabs)}}


class TempDirTestCase(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.dir, ignore_errors=True)
        self.file = self.dir / "bookmarks.toml"

    def browser(self, *replies):
        b = FakeBrowser(replies)
        self.addCleanup(b.close)
        return b

    def write(self, items):
        self.file.write_text(tb.dump_bookmarks(items), encoding="utf-8")


class TestCleanAndToml(unittest.TestCase):
    def test_clean_replaces_control_chars_and_strips(self):
        self.assertEqual(tb.clean("  a\tb\nc\rd\x7fe\x85f  "), "a b c d e f")

    def test_clean_keeps_unicode(self):
        self.assertEqual(tb.clean("日本語 タイトル"), "日本語 タイトル")

    def test_toml_str_escapes(self):
        self.assertEqual(tb.toml_str('a"b\\c'), '"a\\"b\\\\c"')
        self.assertEqual(tb.toml_str("x\ny\x7f"), '"x\\u000ay\\u007f"')

    def test_round_trip_with_special_chars(self):
        items = [
            {"name": 'quote " and \\ backslash', "url": "https://example.com/?q=\"x\"&a=\\"},
            {"name": "改行\nタブ\t制御\x01DEL\x7f", "url": "https://例え.jp/パス"},
            {"name": "", "url": ""},
        ]
        text = tb.dump_bookmarks(items)
        self.assertEqual(tomllib.loads(text)["bookmarks"], items)

    def test_dump_empty(self):
        self.assertEqual(tb.dump_bookmarks([]), "")


class TestLoadAppendWrite(TempDirTestCase):
    def test_load_missing_file_returns_empty(self):
        self.assertEqual(tb.load_bookmarks(self.file), [])

    def test_load_fills_missing_keys_and_stringifies(self):
        self.file.write_text('[[bookmarks]]\nname = "a"\n\n[[bookmarks]]\nurl = "u"\nname = 1\n')
        self.assertEqual(
            tb.load_bookmarks(self.file),
            [{"name": "a", "url": ""}, {"name": "1", "url": "u"}],
        )

    def test_load_file_without_bookmarks_table(self):
        self.file.write_text('title = "x"\n')
        self.assertEqual(tb.load_bookmarks(self.file), [])

    def test_load_invalid_toml_raises(self):
        self.file.write_text("[[bookmarks]\n")
        with self.assertRaises(tomllib.TOMLDecodeError):
            tb.load_bookmarks(self.file)

    def test_append_to_missing_file(self):
        tb.append_bookmark(self.file, "n", "u")
        self.assertEqual(self.file.read_text(), '[[bookmarks]]\nname = "n"\nurl = "u"\n')

    def test_append_to_blank_file_has_no_leading_separator(self):
        self.file.write_text("\n\n")
        tb.append_bookmark(self.file, "n", "u")
        self.assertEqual(tb.load_bookmarks(self.file), [{"name": "n", "url": "u"}])
        self.assertTrue(self.file.read_text().startswith("\n\n[[bookmarks]]"))

    def test_append_after_trailing_newline(self):
        self.write([{"name": "a", "url": "1"}])
        tb.append_bookmark(self.file, "b", "2")
        self.assertIn('url = "1"\n\n[[bookmarks]]\nname = "b"', self.file.read_text())
        self.assertEqual(
            tb.load_bookmarks(self.file),
            [{"name": "a", "url": "1"}, {"name": "b", "url": "2"}],
        )

    def test_append_to_file_without_trailing_newline(self):
        self.file.write_text('[[bookmarks]]\nname = "a"\nurl = "1"')
        tb.append_bookmark(self.file, "b", "2")
        self.assertEqual(
            tb.load_bookmarks(self.file),
            [{"name": "a", "url": "1"}, {"name": "b", "url": "2"}],
        )

    def test_append_escapes_values(self):
        tb.append_bookmark(self.file, 'x"\n[[bookmarks]]', "https://e.com/\\")
        self.assertEqual(
            tb.load_bookmarks(self.file),
            [{"name": 'x"\n[[bookmarks]]', "url": "https://e.com/\\"}],
        )

    def test_write_creates_backup_and_replaces(self):
        original = '[[bookmarks]]\nname = "a"\nurl = "1"\n'
        self.file.write_text(original)
        tb.write_bookmarks(self.file, [{"name": "b", "url": "2"}])
        self.assertEqual(tb.load_bookmarks(self.file), [{"name": "b", "url": "2"}])
        self.assertEqual((self.dir / "bookmarks.toml.bak").read_text(), original)
        self.assertFalse((self.dir / "bookmarks.toml.tmp").exists())

    def test_write_without_existing_file_has_no_backup(self):
        tb.write_bookmarks(self.file, [{"name": "b", "url": "2"}])
        self.assertTrue(self.file.exists())
        self.assertFalse((self.dir / "bookmarks.toml.bak").exists())


class TestRequest(TempDirTestCase):
    def test_request_sends_payload_with_id_and_returns_data(self):
        b = self.browser({"ok": True, "data": {"x": 1}})
        self.assertEqual(tb.request(b.path, {"cmd": "targets"}), {"x": 1})
        self.assertEqual(b.requests[0]["cmd"], "targets")
        self.assertTrue(b.requests[0]["id"])

    def test_request_without_data_returns_empty_dict(self):
        b = self.browser({"ok": True})
        self.assertEqual(tb.request(b.path, {"cmd": "open-tab"}), {})

    def test_request_ok_false_raises_with_error(self):
        b = self.browser({"ok": False, "error": "boom"})
        with self.assertRaisesRegex(RuntimeError, "boom"):
            tb.request(b.path, {"cmd": "targets"})

    def test_request_empty_reply_raises(self):
        b = self.browser(None)
        with self.assertRaisesRegex(RuntimeError, "応答がありません"):
            tb.request(b.path, {"cmd": "targets"})

    def test_request_invalid_json_raises_value_error(self):
        b = self.browser(b"not json\n")
        with self.assertRaises(ValueError):
            tb.request(b.path, {"cmd": "targets"})

    def test_request_missing_socket_raises_oserror(self):
        with self.assertRaises(OSError):
            tb.request(str(self.dir / "nope"), {"cmd": "targets"})

    def test_active_tab_returns_active(self):
        b = self.browser(tabs_reply(
            {"id": 1, "url": "https://a", "active": False},
            {"id": 2, "url": "https://b", "active": True},
        ))
        self.assertEqual(tb.active_tab(b.path)["id"], 2)

    def test_active_tab_none_active_raises(self):
        b = self.browser(tabs_reply({"id": 1, "url": "https://a", "active": False}))
        with self.assertRaisesRegex(RuntimeError, "前面のタブ"):
            tb.active_tab(b.path)

    def test_active_tab_without_tabs_raises(self):
        b = self.browser({"ok": True, "data": {}})
        with self.assertRaises(RuntimeError):
            tb.active_tab(b.path)

    def test_active_tab_ok_false_raises(self):
        b = self.browser({"ok": False, "error": "no"})
        with self.assertRaisesRegex(RuntimeError, "no"):
            tb.active_tab(b.path)


class TestFzf(TempDirTestCase):
    def test_find_fzf_uses_which(self):
        with mock.patch.object(tb.shutil, "which", return_value="/x/fzf"):
            self.assertEqual(tb.find_fzf(), "/x/fzf")

    def test_find_fzf_falls_back_to_dirs(self):
        missing = self.dir / "missing"
        found = self.dir / "bin"
        found.mkdir()
        fzf = found / "fzf"
        fzf.write_text("#!/bin/sh\n")
        fzf.chmod(0o755)
        with mock.patch.object(tb.shutil, "which", return_value=None), \
                mock.patch.object(tb, "FZF_FALLBACK_DIRS", [missing, found]):
            self.assertEqual(tb.find_fzf(), str(fzf))

    def test_find_fzf_not_found_raises(self):
        with mock.patch.object(tb.shutil, "which", return_value=None), \
                mock.patch.object(tb, "FZF_FALLBACK_DIRS", [self.dir]):
            with self.assertRaisesRegex(RuntimeError, "fzf"):
                tb.find_fzf()

    def test_fzf_pick_args_and_input_lines(self):
        runner = fzf_selects(1)
        items = [{"name": "a\tb", "url": "u1"}, {"name": "c\nd", "url": "u2"}]
        with mock.patch.object(tb, "find_fzf", return_value="fzf"):
            self.assertEqual(tb.fzf_pick(items, False, "p> ", runner), [1])
        args, kwargs = runner.calls[0]
        self.assertEqual(args, ["fzf", "--delimiter", "\t", "--with-nth", "2..", "--prompt", "p> "])
        self.assertEqual(kwargs["input"], "0\ta b\tu1\n1\tc d\tu2\n")
        self.assertIs(kwargs["stdout"], subprocess.PIPE)

    def test_fzf_pick_multi_adds_m_and_returns_all(self):
        runner = fzf_selects(0, 2)
        with mock.patch.object(tb, "find_fzf", return_value="fzf"):
            picked = tb.fzf_pick([{"name": "a", "url": "u"}] * 3, True, "p> ", runner)
        self.assertEqual(picked, [0, 2])
        self.assertIn("-m", runner.calls[0][0])

    def test_fzf_pick_cancel_codes(self):
        for code in (1, 130):
            with self.subTest(code=code), mock.patch.object(tb, "find_fzf", return_value="fzf"):
                with self.assertRaises(tb.Cancelled):
                    tb.fzf_pick([{"name": "a", "url": "u"}], False, "p> ", FakeRunner(returncode=code))

    def test_fzf_pick_other_error(self):
        with mock.patch.object(tb, "find_fzf", return_value="fzf"):
            with self.assertRaisesRegex(RuntimeError, "2"):
                tb.fzf_pick([{"name": "a", "url": "u"}], False, "p> ", FakeRunner(returncode=2))


class CommandTestCase(TempDirTestCase):
    def setUp(self):
        super().setUp()
        patcher = mock.patch.object(tb, "find_fzf", return_value="fzf")
        patcher.start()
        self.addCleanup(patcher.stop)
        # print の出力をテスト結果に混ぜない
        out = mock.patch("sys.stdout", new_callable=lambda: open(os.devnull, "w"))
        self.stdout = out.start()
        self.addCleanup(out.stop)
        self.addCleanup(self.stdout.close)


class TestCmdOpen(CommandTestCase):
    def test_open_sends_open_tab_with_selected_url(self):
        self.write([{"name": "a", "url": "https://a"}, {"name": "b", "url": "https://b"}])
        b = self.browser({"ok": True})
        self.assertIsNone(tb.cmd_open(b.path, self.file, answers(), fzf_selects(1)))
        self.assertEqual(b.requests[0]["cmd"], "open-tab")
        self.assertEqual(b.requests[0]["url"], "https://b")

    def test_open_without_bookmarks_raises(self):
        with self.assertRaisesRegex(RuntimeError, "ブックマークがありません"):
            tb.cmd_open("unused", self.file, answers(), FakeRunner())

    def test_open_empty_selection_cancels(self):
        self.write([{"name": "a", "url": "https://a"}])
        with self.assertRaises(tb.Cancelled):
            tb.cmd_open("unused", self.file, answers(), FakeRunner(stdout=""))


class TestCmdAdd(CommandTestCase):
    def test_add_with_typed_name(self):
        b = self.browser(tabs_reply({"url": "https://new", "title": "T", "active": True}))
        tb.cmd_add(b.path, self.file, answers("  My Name  "))
        self.assertEqual(tb.load_bookmarks(self.file), [{"name": "My Name", "url": "https://new"}])

    def test_add_empty_enter_uses_cleaned_title(self):
        self.write([{"name": "a", "url": "https://a"}])
        b = self.browser(tabs_reply({"url": " https://new ", "title": "Line1\nLine2\tX ", "active": True}))
        tb.cmd_add(b.path, self.file, answers(""))
        self.assertEqual(tb.load_bookmarks(self.file)[-1], {"name": "Line1 Line2 X", "url": "https://new"})

    def test_add_typed_name_is_cleaned(self):
        b = self.browser(tabs_reply({"url": "https://new", "title": "T", "active": True}))
        tb.cmd_add(b.path, self.file, answers("a\nb"))
        self.assertEqual(tb.load_bookmarks(self.file)[0]["name"], "a b")

    def test_add_without_title_uses_url(self):
        b = self.browser(tabs_reply({"url": "https://new", "title": "", "active": True}))
        tb.cmd_add(b.path, self.file, answers("   "))
        self.assertEqual(tb.load_bookmarks(self.file), [{"name": "https://new", "url": "https://new"}])

    def test_add_existing_url_returns_notice_without_writing(self):
        self.write([{"name": "Already", "url": "https://dup"}])
        before = self.file.read_text()
        b = self.browser(tabs_reply({"url": "https://dup", "title": "T", "active": True}))
        input_fn = answers()
        self.assertIn("Already", tb.cmd_add(b.path, self.file, input_fn))
        self.assertEqual(self.file.read_text(), before)
        self.assertEqual(input_fn.prompts, [])

    def test_add_empty_or_blank_url_raises(self):
        for url in ("", None, "about:blank"):
            with self.subTest(url=url):
                b = self.browser(tabs_reply({"url": url, "title": "T", "active": True}))
                with self.assertRaisesRegex(RuntimeError, "URL がありません"):
                    tb.cmd_add(b.path, self.file, answers())
        self.assertFalse(self.file.exists())

    def test_add_cancel_with_ctrl_c_or_ctrl_d(self):
        for exc in (KeyboardInterrupt(), EOFError()):
            with self.subTest(exc=type(exc).__name__):
                b = self.browser(tabs_reply({"url": "https://new", "title": "T", "active": True}))
                with self.assertRaises(tb.Cancelled):
                    tb.cmd_add(b.path, self.file, answers(exc))
        self.assertFalse(self.file.exists())


class TestCmdDelete(CommandTestCase):
    def test_delete_only_selected_index_among_duplicates(self):
        dup = {"name": "same", "url": "https://same"}
        self.write([dup, {"name": "other", "url": "https://o"}, dup])
        tb.cmd_delete("unused", self.file, answers("y"), fzf_selects(2))
        self.assertEqual(tb.load_bookmarks(self.file), [dup, {"name": "other", "url": "https://o"}])
        self.assertEqual(len(tb.load_bookmarks(self.dir / "bookmarks.toml.bak")), 3)

    def test_delete_multiple(self):
        items = [{"name": str(i), "url": f"https://{i}"} for i in range(4)]
        self.write(items)
        input_fn = answers(" Y ")
        tb.cmd_delete("unused", self.file, input_fn, fzf_selects(3, 0))
        self.assertEqual(tb.load_bookmarks(self.file), items[1:3])
        self.assertIn("2 件", input_fn.prompts[0])

    def test_delete_not_confirmed_keeps_file(self):
        self.write([{"name": "a", "url": "https://a"}])
        before = self.file.read_text()
        for answer in ("", "n", "yes"):
            with self.subTest(answer=answer):
                with self.assertRaises(tb.Cancelled):
                    tb.cmd_delete("unused", self.file, answers(answer), fzf_selects(0))
        self.assertEqual(self.file.read_text(), before)
        self.assertFalse((self.dir / "bookmarks.toml.bak").exists())

    def test_delete_ctrl_c_at_confirm_cancels(self):
        self.write([{"name": "a", "url": "https://a"}])
        with self.assertRaises(tb.Cancelled):
            tb.cmd_delete("unused", self.file, answers(KeyboardInterrupt()), fzf_selects(0))

    def test_delete_without_bookmarks_raises(self):
        with self.assertRaises(RuntimeError):
            tb.cmd_delete("unused", self.file, answers(), FakeRunner())

    def test_delete_empty_selection_cancels(self):
        self.write([{"name": "a", "url": "https://a"}])
        with self.assertRaises(tb.Cancelled):
            tb.cmd_delete("unused", self.file, answers(), FakeRunner(stdout=""))


class TestRunUi(CommandTestCase):
    def setUp(self):
        super().setUp()
        err = mock.patch("sys.stderr", new_callable=lambda: open(os.devnull, "w"))
        self.stderr = err.start()
        self.addCleanup(err.stop)
        self.addCleanup(self.stderr.close)

    def test_success_returns_0_without_pause(self):
        self.write([{"name": "a", "url": "https://a"}])
        b = self.browser({"ok": True})
        input_fn = answers()
        self.assertEqual(tb.run_ui("open", b.path, self.file, input_fn, fzf_selects(0)), 0)
        self.assertEqual(input_fn.prompts, [])

    def test_fzf_escape_returns_0(self):
        self.write([{"name": "a", "url": "https://a"}])
        self.assertEqual(tb.run_ui("open", "unused", self.file, answers(), FakeRunner(returncode=130)), 0)

    def test_error_pauses_and_returns_1(self):
        input_fn = answers("")
        self.assertEqual(tb.run_ui("open", "unused", self.file, input_fn, FakeRunner()), 1)
        self.assertEqual(input_fn.prompts, ["Enter で閉じます"])

    def test_socket_error_pauses_and_returns_1(self):
        input_fn = answers(EOFError())
        self.assertEqual(tb.run_ui("add", str(self.dir / "nope"), self.file, input_fn), 1)
        self.assertEqual(len(input_fn.prompts), 1)

    def test_invalid_toml_returns_1(self):
        self.file.write_text("[[bookmarks]\n")
        self.assertEqual(tb.run_ui("delete", "unused", self.file, answers(""), FakeRunner()), 1)

    def test_notice_pauses_and_returns_0(self):
        self.write([{"name": "a", "url": "https://dup"}])
        b = self.browser(tabs_reply({"url": "https://dup", "title": "T", "active": True}))
        input_fn = answers(KeyboardInterrupt())
        self.assertEqual(tb.run_ui("add", b.path, self.file, input_fn), 0)
        self.assertEqual(input_fn.prompts, ["Enter で閉じます"])


class TestLaunchAndRegister(TempDirTestCase):
    def test_launch_in_zellij_passes_sys_executable_and_absolute_paths(self):
        runner = FakeRunner(returncode=0)
        rel = Path(os.path.relpath(self.file))
        rc = tb.launch_in_zellij("add", "/tmp/sock", rel, {"ZELLIJ": "0"}, runner)
        self.assertEqual(rc, 0)
        args, kwargs = runner.calls[0]
        self.assertEqual(args, [
            "zellij", "run", "-f", "-c", "-n", "bookmarks", "--",
            sys.executable, str(SCRIPT), "add", "--ui",
            "--socket", "/tmp/sock", "--file", str(self.file.resolve()),
        ])
        self.assertTrue(Path(args[8]).is_absolute())
        self.assertIs(kwargs["check"], False)

    def test_launch_returns_runner_returncode(self):
        self.assertEqual(tb.launch_in_zellij("open", "/s", self.file, {"ZELLIJ": "0"}, FakeRunner(returncode=3)), 3)

    def test_launch_outside_zellij_notifies(self):
        runner = FakeRunner()
        self.assertEqual(tb.launch_in_zellij("open", "/s", self.file, {}, runner), 1)
        self.assertEqual(len(runner.calls), 1)
        args = runner.calls[0][0]
        self.assertEqual(args[0], "osascript")
        self.assertEqual(args[-1], "zellij の中で開いたブラウザでのみ使えます")

    def test_launch_oserror_notifies(self):
        calls = []

        def runner(args, **kwargs):
            calls.append(args)
            if args[0] == "zellij":
                raise FileNotFoundError("zellij")
            return SimpleNamespace(returncode=0)

        self.assertEqual(tb.launch_in_zellij("open", "/s", self.file, {"ZELLIJ": "0"}, runner), 1)
        self.assertEqual([c[0] for c in calls], ["zellij", "osascript"])
        self.assertIn("zellij を起動できませんでした", calls[1][-1])

    def test_register_calls_register_app_three_times(self):
        runner = FakeRunner()
        self.assertEqual(tb.register(runner), 0)
        self.assertEqual([c[0] for c in runner.calls], [
            ["terminal-browser", "register-app", "--name", name, "--bin", str(SCRIPT), "--id", app_id, "--args", arg]
            for app_id, name, arg in [
                ("heyyou-bookmark-open", "Bookmarks: Open", "open"),
                ("heyyou-bookmark-add", "Bookmarks: Add current page", "add"),
                ("heyyou-bookmark-delete", "Bookmarks: Delete", "delete"),
            ]
        ])
        self.assertTrue(all(c[1]["check"] is True for c in runner.calls))


class TestMain(TempDirTestCase):
    def setUp(self):
        super().setUp()
        err = mock.patch("sys.stderr", new_callable=lambda: open(os.devnull, "w"))
        self.stderr = err.start()
        self.addCleanup(err.stop)
        self.addCleanup(self.stderr.close)

    def test_register(self):
        with mock.patch.object(tb, "register", return_value=0) as reg:
            self.assertEqual(tb.main(["register"], env={}), 0)
        reg.assert_called_once_with()

    def test_ui_requires_socket(self):
        with mock.patch.object(tb, "run_ui") as run_ui:
            self.assertEqual(tb.main(["open", "--ui"], env={}), 1)
        run_ui.assert_not_called()

    def test_ui_uses_file_argument(self):
        with mock.patch.object(tb, "run_ui", return_value=0) as run_ui:
            self.assertEqual(tb.main(["delete", "--ui", "--socket", "/s", "--file", str(self.file)], env={}), 0)
        run_ui.assert_called_once_with("delete", "/s", self.file)

    def test_file_argument_wins_over_env(self):
        with mock.patch.object(tb, "run_ui", return_value=0) as run_ui:
            tb.main(["open", "--ui", "--socket", "/s", "--file", str(self.file)],
                    env={"TB_BOOKMARKS_FILE": "/other.toml"})
        self.assertEqual(run_ui.call_args.args[2], self.file)

    def test_env_file_and_expanduser(self):
        with mock.patch.object(tb, "run_ui", return_value=0) as run_ui:
            tb.main(["open", "--ui", "--socket", "/s"], env={"TB_BOOKMARKS_FILE": "~/x.toml"})
        self.assertEqual(run_ui.call_args.args[2], Path.home() / "x.toml")

    def test_default_file(self):
        with mock.patch.object(tb, "run_ui", return_value=0) as run_ui:
            tb.main(["open", "--ui", "--socket", "/s"], env={})
        self.assertEqual(run_ui.call_args.args[2], Path.home() / "dotfiles" / ".heyyou" / "bookmarks.toml")

    def test_palette_without_target_returns_1(self):
        with mock.patch.object(tb, "launch_in_zellij") as launch:
            self.assertEqual(tb.main(["open"], env={"ZELLIJ": "0"}), 1)
        launch.assert_not_called()

    def test_palette_launches_zellij(self):
        env = {"TERMINAL_BROWSER_INTEROP_TARGET": "/s", "TB_BOOKMARKS_FILE": str(self.file)}
        with mock.patch.object(tb, "launch_in_zellij", return_value=0) as launch:
            self.assertEqual(tb.main(["add"], env=env), 0)
        launch.assert_called_once_with("add", "/s", self.file, env)

    def test_invalid_command_exits_2(self):
        with self.assertRaises(SystemExit) as cm:
            tb.main(["bogus"], env={})
        self.assertEqual(cm.exception.code, 2)


class TestVersionGuard(unittest.TestCase):
    def test_old_python_exits_1(self):
        source = SCRIPT.read_text(encoding="utf-8")
        with mock.patch.object(sys, "version_info", (3, 9, 6)), \
                mock.patch("sys.stderr", new_callable=lambda: open(os.devnull, "w")) as err:
            with self.assertRaises(SystemExit) as cm:
                exec(compile(source, str(SCRIPT), "exec"), {"__name__": "tb_bookmark_old"})
            err.close()
        self.assertEqual(cm.exception.code, 1)


if __name__ == "__main__":
    unittest.main()
