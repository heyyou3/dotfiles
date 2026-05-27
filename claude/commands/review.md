---
description: 指定した Design Doc/タスクを reviewer subagent でレビューする
argument-hint: <slug>
allowed-tools: Read, Edit, Bash, Task
---

slug: `$1`

あなたは worker(メインセッション)です。次の手順でレビューを依頼してください。

1. `.heyyou/design/$1.md` が存在するか確認する。なければ、利用可能な slug 一覧(`ls .heyyou/design`)を提示して中断する。
2. `.heyyou/discussions/$1.md` と `.heyyou/reviews/$1.md` が無ければ空で用意し、`.heyyou/design/$1.md` の frontmatter の status を `review-requested` に更新する。
3. もし直前のラウンドで指摘へ対応済みなら、その応答を `.heyyou/discussions/$1.md` の末尾に「### worker — 応答」として追記してからレビューを依頼する。
4. reviewer subagent(subagent_type: reviewer)を起動し、slug `$1` を渡してレビューさせる。
5. subagent 終了後、`.heyyou/reviews/$1.md` を読み、判定(approved / changes-requested)と主要な指摘を私(人間)に要約して伝える。
6. `changes-requested` の場合は、対応方針を提案し、私の指示を待つ(勝手に実装しない)。`approved` の場合は実装に進んでよいか確認する。
