# heyyou プラグイン

heyyou ハーネス(Design Doc 駆動の自動レビュー/ゲート群)を Claude Code の Plugin として
バンドルしたもの。`~/.claude` への symlink + `settings.json` インライン hooks による手配線を、
`${CLAUDE_PLUGIN_ROOT}` 相対の自己完結パッケージに置き換える。

## 同梱物

| 種別 | 中身 |
|---|---|
| agents | `reviewer` / `tester` / `security-reviewer` |
| commands | `review`(→ `/heyyou:review`) |
| hooks | `review-gate` / `commit-gate` / `dangerous-command-guard`(PreToolUse)、`notify`(Stop/Notification)、`load-context`(SessionStart) |
| ai-agent | モード別コンテキスト `core.md` / `engineer.md` / `business.md`(`load-context.sh` が読む) |

hooks のパスは `${CLAUDE_PLUGIN_ROOT}/hooks/*.sh`。`load-context.sh` は同梱 `ai-agent/` を
単一ソースとして参照する(env 未供給時のみ `$HOME/dotfiles/ai-agent` へ degrade=移行期間限定)。

## ローカルでテスト(非破壊)

```bash
claude --plugin-dir ~/dotfiles/claude/plugins/heyyou
```

別セッションが立ち上がり、現行の `~/.claude` 配線に影響を与えずにプラグインを試せる。
`/agents` に reviewer/tester/security-reviewer が出るか、`/heyyou:review` が使えるか、
各 hook(編集/コミット/破壊コマンドのゲート)が発火するかを確認する。

## marketplace 経由で有効化(cutover / グローバル設定変更)

```bash
claude plugin marketplace add ~/dotfiles/claude/plugins
/plugin install heyyou@heyyou-dotfiles
```

その後、重複する手配線を除去する:

1. `~/.claude/settings.json` の `hooks` ブロックを削除(プラグインが供給)
2. symlink を削除: `~/.claude/agents/{reviewer,tester,security-reviewer}.md`,
   `~/.claude/commands/review.md`, `~/.claude/hooks/{review-gate,commit-gate,dangerous-command-guard,load-context,notify}.sh`
   (同名の user 定義が残るとプラグイン側が override される)
3. `~/dotfiles/ai-agent` を撤去(同梱 `ai-agent/` へ単一ソース化)

### ロールバック(逆順・順序厳守)

プラグイン有効のまま symlink を戻すと override で衝突するため、必ず次の逆順で戻す:

1. `~/.claude/settings.json` をバックアップから復元(`hooks` を戻す)
2. `/plugin uninstall heyyou@heyyou-dotfiles`
3. `enabledPlugins` から `heyyou@heyyou-dotfiles` を除去(uninstall で消えなければ手動)
4. `claude plugin marketplace remove heyyou-dotfiles`
5. symlink を再作成 / `~/dotfiles/ai-agent` を戻す

## 既知の制約

- **`permissions.ask`(破壊コマンド承認リスト)はプラグインに載らない。** プラグインの
  `settings.json` は `agent` / `subagentStatusLine` キーのみ対応のため、ask リストは
  `~/.claude/settings.json` に据え置く。`dangerous-command-guard.sh` と一部コマンドで二重に
  ask が出うるが、両者とも `ask` のため安全側・実害なし(既知・現状維持)。
- `${CLAUDE_PLUGIN_ROOT}` に依存するのは `load-context.sh` のみ。gate 系 3 本は
  `CLAUDE_PROJECT_DIR` 相対で自己完結し、env 未供給でも誤動作しない。
