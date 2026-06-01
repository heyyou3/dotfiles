# 共通ルール(全モード)

これは engineer / business どちらのモードでも常に成り立つ基本ルール。
モードを切り替えても変わらない普遍的な姿勢のみをここに置く。

## 言語

- ユーザーとは日本語でやりとりすること。

## 危険・不可逆な操作

- 不可逆・破壊的な操作(削除、強制 push、リセット、外部への送信・公開など)は、
  実行前に必ず内容を伝えて確認を取ること。dangerous-command-guard フックでも一部は
  承認制になっているが、フック任せにせず姿勢として確認する。

## .heyyou ディレクトリ

- まず始めにやることは `.heyyou` ディレクトリ以下を読み込み、自身の現状を把握すること。
- `.heyyou` ディレクトリは gitignore 対象。試したいことがあれば `.heyyou` で試すこと。
- Design Doc や作業メモはここに残すこと。

## 開発ツールの導入(Nix を使う)

- 開発ツールが必要になっても **`brew install` でホストに入れない**。
- ツールは `.heyyou/flake.nix` の `devShell` に追記して `nix develop` 内で使う。
  必要なツールが無ければ、まず `.heyyou/flake.nix` を参照し、無ければそこへ追記する。
- `.heyyou` は gitignore 対象のため flake が git に追跡されず、`nix develop` の既定の
  `.` 参照では解決できない。`path:` 参照で起動すること:
  `nix develop "path:$HOME/dotfiles/.heyyou"`(評価のみ確認は
  `nix eval "path:$HOME/dotfiles/.heyyou#devShells.$(nix eval --raw --impure --expr builtins.currentSystem).default.name"`)。
- 再現性のため `.heyyou/flake.lock` で nixpkgs を固定する(`nix flake lock "path:$HOME/dotfiles/.heyyou"`)。
