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

## 作業報告書(必須・全モード共通)

このルールは core.md 単体で自己完結する(business モードでは engineer.md は注入されないため)。
engineer / business のどちらでも、**コード変更の有無を問わず**ここで定義する報告書を作成する。

- worker(あなた)は、**実質的な作業を完了したら必ず**作業報告書を
  `.heyyou/reports/<slug>.md` に提出する。これはタスク完了の必須ステップであり省略しない。
- 対象(報告書を作る)/ 対象外(作らない)は具体例で固定する:
    - 対象: 実装、**コード変更を伴わない PR レビュー・調査・設計検討**、文章作成、外部サービス連携など
      成果物・調査結論・判断のいずれかを伴う作業。
    - 対象外: 単なる質問への回答、コードリーディングのみ、雑談。
- 報告書の要否判断は、engineer モードの review-gate / commit-gate の**発動条件とは独立**。
  gate が発動しないレビューのみ・調査のみの作業でも、報告書は作成する。
- slug の採番: その作業を表す kebab-case。`tasks/` 経由で投入された作業はそのタスク名を slug に使う。
  task ディレクトリを作らない business 作業でも、作業内容から kebab-case の slug を付ける。
  既存と衝突する場合は連番(`-2`)または日付を付与して一意にする。
- 報告書には少なくとも次を含める:
    - これはなに / なぜやったか(背景・目的)
    - 何をしたか(対象と具体的な作業内容・成果物)
    - 結果(検証結果・調査結論・判断とその根拠)
    - 残課題・フォロー事項(あれば)
- モード固有の追記事項は各モードのルールに従う(engineer は変更ファイル一覧、tester / reviewer 差分 /
  security-reviewer の判定サマリを加える)。

## 開発ツールの導入(Nix を使う)

- 開発ツールが必要になっても **`brew install` でホストに入れない**。
- ツールは `.heyyou/flake.nix` の `devShell` に追記して `nix develop` 内で使う。
  必要なツールが無ければ、まず `.heyyou/flake.nix` を参照し、無ければそこへ追記する。
- `.heyyou` は gitignore 対象のため flake が git に追跡されず、`nix develop` の既定の
  `.` 参照では解決できない。`path:` 参照で起動すること:
  `nix develop "path:$HOME/dotfiles/.heyyou"`(評価のみ確認は
  `nix eval "path:$HOME/dotfiles/.heyyou#devShells.$(nix eval --raw --impure --expr builtins.currentSystem).default.name"`)。
- 再現性のため `.heyyou/flake.lock` で nixpkgs を固定する(`nix flake lock "path:$HOME/dotfiles/.heyyou"`)。
