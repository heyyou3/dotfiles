---
title: AIエージェントチーム(作業者/レビュワー)のローカル構築
status: draft
author: heyyou
created: 2026-05-27
updated: 2026-05-29
---

# AIエージェントチーム(作業者/レビュワー)のローカル構築

## これはなに?

Claude Code を使い、ローカルに「作業者(worker)」と「レビュワー(reviewer)」の役割を作り、
作業者が作成した Design Doc やタスクをレビュワーがレビューする仕組みを作る。

人間は **worker 1つにだけ指示**し、worker が必要なときにレビュワー subagent を呼ぶ(構成1)。
エージェント間の議論はファイルに残し、後から追える状態にする。

### なぜこの変更をおこなうのか

- Design Doc / タスクの品質を、人間がレビューする前に AI どうしで一次レビューさせ、手戻りを減らしたい。
- 指示の窓口を1つにして、ペイン間を行き来する運用負荷をなくしたい。
- AGENTS.md の「実装前に Design Doc を md で残す」「セルフレビュー項目」を専任レビュワーに継続適用させたい。

### この変更で何が起きるのか

- 人間は1つの claude セッション(worker)にだけ指示すればよくなる。
- worker が `/review` でレビュワー subagent を呼び、レビュー結果と議論がファイルに残る。
- レビューはスラッシュコマンドで手動起動する(自動フックは使わない)。

## 採用する構成(構成1: 単一セッション + reviewer subagent)

```
            あなた
              │ 指示(Design Doc 作成 / 実装 / 修正対応)
              ▼
   ┌─────────────────────────────┐
   │ worker = メインセッション   │
   │  - Design Doc / タスク作成  │
   │  - 承認後に実装             │
   │  - /review でレビュワー呼出 │
   └──────────────┬──────────────┘
                  │ Agent ツールで subagent 起動
                  ▼
        ┌────────────────────┐
        │ reviewer subagent  │  ← 呼ばれるたびに起動・終了
        │  - 設計/タスクを精査 │
        │  - 指摘を出力        │
        └────────────────────┘
```

### なぜ構成2(常駐2セッション)ではなく構成1か

- **指示先が1つ**。人間は worker にだけ話せばよく、ペインの行き来が不要。
- subagent はメインに最終結果しか返さない弱点があるが、**議論をファイルに残す**ことで解消する(下記プロトコル)。
- レビュワーがセッション記憶を持てない弱点も、**毎回ログを読み直す**ことで補う。
- 並行作業や常駐対話が必要になったら構成2 / teammate へ拡張できる(「やらないこと」参照)。

### 連携手段: ファイル経由(`.heyyou/`)

- 信頼できる唯一の情報源は **md ファイル**。共有場所はプロジェクト直下の `.heyyou/`。
- subagent とメインは同一 cwd を共有し、`.heyyou/` 配下のファイルで受け渡す。

```
.heyyou/
  tasks/<slug>/
    design.md                    # worker が作成。frontmatter の status でフェーズ管理
    discussions.md               # worker と reviewer の議論を時系列で追記(append-only)
    reviewer/design-review.md    # reviewer の Design Doc 判定(上書き) ← review-gate が読む
    reviewer/diff-review.md      # reviewer の差分判定(上書き) ← commit-gate が読む
    tester/report.md             # tester の結果
    security-reviewer/report.md  # security-reviewer の判定 ← commit-gate が読む
  reports/<slug>.md              # worker 作業報告書(必須・全モード共通)
```

`.heyyou/` はエージェントチームの作業領域とし、対象プロジェクトの `.gitignore` に追加する(コミット要否は利用者判断)。

作業報告書 `reports/<slug>.md` は engineer / business の**全モード共通の必須成果物**で、コード変更を伴わない
レビュー・調査でも作成する(定義は `ai-agent/core.md`「作業報告書(必須・全モード共通)」。
`tasks/<slug>/` を作らない business 作業でも slug を付けて提出する)。

### frontmatter ステータス遷移

```
draft → review-requested → (changes-requested → review-requested)* → approved
```

| status | 意味 | 次のアクション |
|---|---|---|
| `draft` | 作成中 | worker が書き上げる |
| `review-requested` | レビュー待ち | worker が `/review` でレビュワー起動 |
| `changes-requested` | 修正依頼あり | worker が指摘対応し再レビュー |
| `approved` | 承認済み | worker が実装へ進む |

### 議論ログ(`.heyyou/tasks/<slug>/discussions.md`)

subagent は途中経過を残さないため、worker と reviewer の往復を**明示的に追記**する。フォーマット:

```markdown
# 議論ログ: <slug>

## ラウンド1
### worker — 設計意図 (2026-05-27T10:00)
このDesign Docで○○を狙った。△△は意図的に採用しなかった。

### reviewer — 指摘 (2026-05-27T10:05) 判定: changes-requested
1. [責務] 関数Xが2つのことをしている
2. [命名] foo は意図が読めない

### worker — 応答 (2026-05-27T10:10)
1. → 関数Xを分割した
2. → bar にリネーム / または: 〜の理由で現状維持したい
```

- reviewer は指摘時にこのログへ追記し、`.heyyou/tasks/<slug>/reviewer/design-review.md` に最新版の判定をまとめる。
- worker は対応時に各指摘への応答をログへ追記してから再レビューを依頼する。
- reviewer は起動時にまずログを読み、前回の指摘の対応状況を踏まえて再評価する。

## 標準フロー(人間は worker にだけ指示)

1. あなた → worker:「○○の Design Doc を書いて」。worker が `.heyyou/tasks/<slug>/design.md` を `status: draft` で作成。
2. あなた → worker:「`/review <slug>`」。worker が status を `review-requested` に更新し、reviewer subagent を起動。
3. reviewer が design(と関連差分)を読み、レビュー観点で評価。`.heyyou/tasks/<slug>/reviewer/design-review.md` に判定+指摘を書き、`.heyyou/tasks/<slug>/discussions.md` に追記。design の frontmatter を `approved` / `changes-requested` に更新して終了。
4. worker が結果を要約し、あなたに提示。`changes-requested` なら、あなたの指示で worker が指摘へ対応(応答をログに追記) → 再度 `/review` でステップ3へループ。
5. `approved` になったら、あなたの指示で worker が実装に進む。

### 開発ワークフロー(誰に指示するか)

- **指示先は常に worker(メインセッション)1つだけ。** reviewer は worker が `/review` で呼ぶので、あなたが直接話す相手ではない。
- reviewer の判断根拠を知りたいときは、`.heyyou/tasks/<slug>/discussions.md` を読めば往復がすべて残っている。
- 人間はペインを行き来しない。Zellij は worker ペイン + `.heyyou/` を眺める watcher ペインの構成で十分。

```
あなた ⇄ worker(メイン) ──/review──▶ reviewer subagent
                │                          │
                │   .heyyou/tasks/<slug>/reviewer/design-review.md(判定)
                └── .heyyou/tasks/<slug>/discussions.md(議論の記録)
```

### レビュー観点(reviewer に埋め込む)

AGENTS.md のセルフレビュー項目をそのまま使う:

- 命名: 名前から意図が読み取れるか、誤解の余地がないか
- 関数の責務: 一度に1つのことをしているか、長すぎないか(目安50行)
- ネスト: 3段以上深くないか、早期リターンで平坦化できないか
- コメント: WHY が書かれているか、WHAT の繰り返しになっていないか
- 重複: 同じロジックが複数箇所に書かれていないか

加えて Design Doc 固有の観点:

- これはなに?/なぜ/何が起きるのか が埋まっているか
- 動作確認項目が差分・影響範囲を網羅しているか

## 作成する成果物

| # | パス | 役割 |
|---|---|---|
| 1 | `claude/agents/reviewer.md` | reviewer subagent 定義。レビュー観点を埋め込み、書込みは `.heyyou/tasks/<slug>/reviewer/`・`.heyyou/tasks/<slug>/discussions.md` と design frontmatter に限定 |
| 2 | `claude/commands/review.md` | worker 用 `/review <slug>`: status 更新 → reviewer subagent 起動 → 結果要約 |
| 3 | `zellij/agent-team-layout.kdl` | worker(claude)ペイン + `.heyyou/` watcher ペインのレイアウト |
| 4 | `Taskfile.yaml` | `claude/agents`・`claude/commands` を `~/.claude/` に symlink する task を定義(go-task v3) |

worker は専用エージェント定義を作らず、メインセッション + プロジェクトの AGENTS.md で運用する(必要なら後から `claude/agents/worker.md` を足す)。

### 役割の安全分離

- reviewer subagent は `tools` を読み取り中心に制限(Read / Grep / Glob と `.heyyou/tasks/<slug>/reviewer/`・`.heyyou/tasks/<slug>/discussions.md` への Write のみ)。コードや design 本文は書き換えさせない。
- worker(メイン)は通常の編集権限を持つ。

## やらないこと

- レビューの自動起動(フック)。手動スラッシュコマンドのみ。
- 構成2(常駐2セッション)・teammate / SendMessage によるセッション間直接通信。
- 統括(マネージャ)エージェント。人間が worker に指示する形で十分。
- 3つ目以降のエージェント(設計者・テスター等)への拡張。

## 未確定・要検証

- reviewer subagent の `tools` でディレクトリ単位の Write 制限がどこまで効くか(効かない場合は agent の指示文で `.heyyou/` 外への書込み禁止を明示)。
- agents / commands を user スコープ(`~/.claude`)に置く方針。dotfiles 流に合わせ symlink で配置する。

## 進捗状況

- [x] 構成方針の合意(構成1: 単一セッション + reviewer subagent / 手動レビュー / `.heyyou/` ファイル連携 / 議論ログ)
- [x] Design Doc 作成(本ファイル)
- [x] reviewer subagent 定義の作成(`claude/agents/reviewer.md`)
- [x] `/review` スラッシュコマンドの作成(`claude/commands/review.md`)
- [x] Zellij レイアウトの作成(`zellij/agent-team-layout.kdl`)
- [x] Taskfile.yaml への symlink task 追加(`deploy:claude` / `agent-team`)
- [x] `task deploy:claude` で `~/.claude/` へ symlink 済み
- [ ] 一連のフロー(draft → review → approved + 議論ログ)の動作確認 ※ claude 再起動後に実機確認
