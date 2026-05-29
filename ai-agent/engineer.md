# engineer モード

エンジニアリング作業(設計・実装・レビュー・コミット/PR・IaC)に固有の手続き。
共通ルールは core.md を参照。

# コードを生成するときのルール

- コメントは最小限で残す
    - 残す場合はやらなかったことだけを記載する
- コードを提案する前に必ず Design Doc を記載して、md ファイルを作成してからコードを提案すること

# テストコードを書く際のルール

- カバレッジ率は 80 % を維持する
- 過度な抽象化はしないこと

# コミットメッセージのルール

- 日本語で残すこと
- https://www.conventionalcommits.org/ja/v1.0.0 をに準拠すること
- コミット前に、対象 slug の reviewer 差分レビュー(`tasks/<slug>/reviewer/diff-review.md`)と
  security-reviewer(`tasks/<slug>/security-reviewer/report.md`)が両方 `verdict: approved` であること。
  これは検証フェーズ(step9 reviewer 差分 / step10 security)の approved を確認・再保証する最終ゲート。
  PreToolUse(Bash)の commit-gate フックでも強制される(未承認・欠落・gate 不正は安全側 deny)。
  `--amend` も対象、`--dry-run` のみ除外。alias 経由(`g c` 等)は検知できないため手順として遵守すること。

# PR を作成する場合のルール

- 作成する項目
    - これはなに？
        - なぜこの変更をおこなったのか
        - この変更で何が起きるのか
    - 動作確認
        - 差分を確認して、リポジトリ全体を確認して、影響がある箇所はすべて動作確認項目として列挙する
- PR を作成したあとは gh コマンドを使用して、ブラウザで作成した PR を開いてください
    - 許可の確認は不要です
- 必ず Draft で作成してください
- 必ずセルフレビューをおこなってください
    - 命名: 名前から意図が読み取れるか、誤解の余地がないか
    - 関数の責務: 一度に1つのことをしているか、行数が長すぎないか(目安50行)
    - ネスト: 3段以上深くないか、早期リターンで平坦化できないか
    - コメント: WHYが書かれているか、WHATの繰り返しになっていないか
    - 重複: 同じロジックが複数箇所に書かれていないか

# タスクをプランし、作業する前のルール

- セッションが切れてもよいように Design Doc に進捗状況を記載すること

# タスクごとの記録レイアウト

タスク 1 件の成果物は、すべて `.heyyou/tasks/<slug>/` 配下に集約する(per-task ディレクトリ)。

```
.heyyou/tasks/<slug>/
├── design.md                      # Design Doc
├── discussions.md                 # worker↔reviewer 議論ログ
├── reviewer/
│   ├── design-review.md           # Design Doc レビュー判定 ← review-gate が verdict を読む
│   └── diff-review.md             # 差分レビュー判定 ← commit-gate が verdict を読む
├── tester/
│   └── report.md                  # テスト結果
└── security-reviewer/
    └── report.md                  # セキュリティレビュー判定 ← commit-gate が verdict を読む

.heyyou/reports/<slug>.md          # worker 作業報告書(必須)
```

# worker 作業報告書(必須)

- worker(あなた)は、コード/設定変更を伴うタスクを完了したら **必ず** 作業報告書を
  `.heyyou/reports/<slug>.md` に提出する。これはタスク完了の必須ステップであり省略しない。
- 報告書には少なくとも次を含める:
    - これはなに / なぜやったか(背景・目的)
    - 何を変更したか(対象ファイルと変更点)
    - 検証結果(tester / reviewer 差分 / security-reviewer の判定サマリ、動作確認の結果)
    - 残課題・フォロー事項(あれば)

# 自動レビューのワークフロー

コード/設定変更を伴うタスクでは、明示的な `/review` を待たず、worker(あなた)が
自分から reviewer subagent を起動して次のループを必ず回すこと。

1. slug(タスクを表す kebab-case)を決める。採用前に `ls .heyyou/tasks` で既存を確認し、
   衝突する場合は連番(`-2`)または日付を付与して一意にする。
2. タスクディレクトリを作成する: `mkdir -p .heyyou/tasks/<slug>`。以後この slug の記録は
   すべてこの配下に置く。
3. `.heyyou/tasks/<slug>/design.md` に Design Doc を書く。
4. reviewer subagent(Task, subagent_type: reviewer)を起動し Design Doc レビューを受ける。
   verdict を待ち、`approved` になるまで実装に進まない。
5. `changes-requested` の場合は対応方針を提示し、ユーザー指示を待って Design Doc を改訂し再レビュー。
   `approved` の場合はユーザー確認を取ってから実装する。
6. 実装に入る直前に、承認済み slug を**このセッションの** gate に記録する:
   `mkdir -p .heyyou/state/gates && echo <slug> > .heyyou/state/gates/$CLAUDE_CODE_SESSION_ID`。
   gate はセッション別ファイル(key = `$CLAUDE_CODE_SESSION_ID`)なので、並行する別セッションの
   gate と競合しない。この記録が無いと PreToolUse フック(review-gate)が本体ファイルの編集を deny する。
7. worker が実装する。
8. テスト対象なら tester subagent(subagent_type: tester)を起動し、テスト追加とカバレッジ検証を行う。
9. reviewer を「差分レビューモード」で起動し、実装と tester 追加テストを一括でレビューさせる。
   `changes-requested` なら修正し再レビュー。差分レビュー結果は `tasks/<slug>/reviewer/diff-review.md` に出る。
10. セキュリティ対象なら security-reviewer subagent(subagent_type: security-reviewer)を起動する。
11. worker 作業報告書 `.heyyou/reports/<slug>.md` を提出する(上記「worker 作業報告書(必須)」参照)。
12. コミットする。commit-gate フックがこのセッションの gate slug の `tasks/<slug>/reviewer/diff-review.md` と
    `tasks/<slug>/security-reviewer/report.md` の両 approved を検証するため、gate はコミット完了まで残しておくこと。
13. コミット完了後に gate をクリアする: `rm -f .heyyou/state/gates/$CLAUDE_CODE_SESSION_ID`。
    記録と消去は必ずセット(使い切り)。クリアは必ず最後(コミット後)。コミット前にクリアすると
    commit-gate が slug を読めず deny になる。クリアしないと同一セッションの無関係な後続タスクの本体編集まで通る。

注: review-gate フックは、このセッションの gate(`.heyyou/state/gates/$CLAUDE_CODE_SESSION_ID`)の slug に
対応する `.heyyou/tasks/<slug>/reviewer/design-review.md` の `verdict: approved`(Design Doc レビューの承認)を
実際に検証する。gate のキーは worker・フック双方が env `CLAUDE_CODE_SESSION_ID` で解決するため一致する。
レビューを通さず gate に書くだけでは deny される。差分レビューは `tasks/<slug>/reviewer/diff-review.md` に
出力され gate を閉じない。

## 検証フェーズの発動条件(過剰起動を避ける / 判定主体は worker)

- tester(step8): テスト可能なロジックを含む変更時のみ。対象例=`.sh` の関数/分岐、アプリのロジック。
  非対象例=`.toml`/`.kdl` の値変更のみ、リンク追加のみの Taskfile/Makefile。不要なら「テスト不要」で省く。
- reviewer 差分レビュー(step9): 常に行う(品質の基本線)。
- security-reviewer(step10): 外部入力・権限・認証・秘匿情報・シェル実行/ネットワーク等
  セキュリティ影響がある変更時のみ。純粋な見た目/設定変更では起動しない。

## 発動条件

- 発動する: リポジトリ本体のコード・設定(挙動が変わる .toml/.kdl/.sh/Makefile/Taskfile 等)の変更。
- 発動しない: 質問への回答・調査・コードリーディングのみ。次の変更も発動しない。
    - `.heyyou/` 配下での試行(設計・レビュー・議論ファイルの読み書きそのもの)
    - ドキュメントのみの修正(実行されないテキスト)
    - 挙動が変わらない単純なリネーム/移動

## 役割分担

- reviewer は Design Doc / 実装段階のレビュー担当(可読性・責務など品質5観点)。
- tester はテスト作成とカバレッジ80%の検証担当。
- security-reviewer はセキュリティ観点(注入・権限・秘匿情報・入力検証等)のレビュー担当。
- 「PR を作成する場合のルール」のセルフレビュー(品質5観点)は PR 作成直前の最終確認。
  段階が異なるため二度手間にしない。

# subagent 起動時のルール

- worker が **ファイル編集を伴う subagent** を起動する場合(例: 実装作業を別の
  subagent に任せる、複数 subagent を並列で走らせて編集させる)は、Task 呼び出しに
  `isolation: "worktree"` を指定して git worktree 上で隔離して作業させる。
  - 理由: 複数 subagent が同時に同じ作業ツリーを編集すると、未コミット差分が衝突する。
- 読み取り専用の subagent(Explore / reviewer / tester / security-reviewer 等、
  ファイルを書き換えないもの)では `isolation` の指定は不要。
- worker 自身(メインセッション)の編集は単独実行のため worktree 隔離の対象外。
  並行性の問題は subagent 並列起動時にのみ発生する。
- worktree 上の変更は subagent 終了時に自動回収される(差分が無ければ削除、ある
  場合はパスとブランチが結果に返る)。worker 側で取り込み判断を行う。

# Terraform のルール

- plan の結果は省力せずにすべてを見せること
- apply は明示的な指示がない限りはしないこと
