function tbx --description "terminal-browser に表示中のテキストを fzf で複数選んでクリップボードへコピーする"
    for cmd in terminal-browser jq fzf pbcopy
        if not command -q $cmd
            echo "tbx: $cmd が見つかりません" >&2
            return 1
        end
    end

    # コマンド置換は改行で分割するため、JS は 1 つの引数にまとめて渡す
    set -l js (__tbx_js | string collect)
    set -l raw (__tbx_eval $js)
    or return 1
    set raw (string join \n -- $raw | string collect)

    # 要素に改行が入るため、JSON は fish の配列にせず 1 つの文字列のまま扱う
    set -l items (printf '%s' $raw | jq -c 'if type == "string" then fromjson else . end | arrays' 2>/dev/null | string collect)
    if test -z "$items"; or test (printf '%s' $items | jq length) -eq 0
        echo "tbx: 表示中のテキストが見つかりません" >&2
        return 1
    end

    set -l picked (printf '%s' $items \
        | jq -r 'to_entries[] | "\(.key)\t\(.value | gsub("\n"; " ⏎ ") | gsub("[\\u0000-\\u001f\\u007f-\\u009f]"; " "))"' \
        | fzf -m --delimiter '\t' --with-nth 2.. --prompt 'copy> ')
    or return 0

    set -l idx (printf '%s\n' (string split -f1 \t -- $picked) | jq -sc .)
    printf '%s' $items | jq -j --argjson idx $idx '
        [.[$idx[]]] as $s
        | ($s | any(contains("\n"))) as $multi
        | $s | join(if $multi then "\n\n" else "\n" end)' \
        | env LC_CTYPE=UTF-8 pbcopy
    if test $pipestatus[-1] -ne 0
        echo "tbx: クリップボードへのコピーに失敗しました" >&2
        return 1
    end
    echo "tbx: "(count $picked)" 件コピーしました"
end

function __tbx_eval --description "この端末タブのブラウザ、無ければ選んだブラウザの前面タブで JS を実行する"
    set -l here (terminal-browser ls --json 2>/dev/null | jq '.browsers | length' 2>/dev/null)
    if test -n "$here"; and test "$here" -gt 0
        terminal-browser action -- eval $argv[1]
        return $status
    end

    set -l key (__tbx_pick_browser)
    or return 1
    terminal-browser action --browser $key -- eval $argv[1]
end

function __tbx_pick_browser --description "ls --all のブラウザから 1 つ選んで key を返す"
    set -l rows (terminal-browser ls --all --json 2>/dev/null | jq -r '
        .browsers[]
        | [.key, (first((.tabs[]? | select(.active) | .title // ""), "") | gsub("[\\u0000-\\u001f\\u007f-\\u009f]"; " "))]
        | @tsv' 2>/dev/null)
    switch (count $rows)
        case 0
            echo "tbx: terminal-browser が開いていません" >&2
            return 1
        case 1
            string split -f1 \t -- $rows[1]
        case '*'
            set -l picked (printf '%s\n' $rows | fzf --delimiter '\t' --prompt 'browser> ')
            or begin
                echo "tbx: ブラウザの選択をキャンセルしました" >&2
                return 1
            end
            string split -f1 \t -- $picked
    end
end

function __tbx_js --description "表示中のテキストを単位ごとに集めて JSON 配列で返す JS"
    # fish の単一引用符内では ' を書けず \\ が \ に詰められるため、JS では ' と \ を使わない
    printf '%s' '(() => {
  const NL = String.fromCharCode(10);
  const vh = innerHeight, vw = innerWidth;
  const UNIT = "li,tr,article,[role=listitem],[role=row],[role=article]";
  const SKIP = "script,style,noscript,[aria-hidden=true]";
  const isBlock = (el) => {
    const d = getComputedStyle(el).display;
    return !d.startsWith("inline") && d !== "contents";
  };
  const visible = (el) => {
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.bottom >= 0 && r.top <= vh && r.right >= 0 && r.left <= vw;
  };
  const units = new Set(), blocks = new Set();
  const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n; (n = w.nextNode());) {
    if (!n.nodeValue.trim()) continue;
    let el = n.parentElement;
    if (!el || el.closest(SKIP)) continue;
    while (el.parentElement && !isBlock(el)) el = el.parentElement;
    const u = el.closest(UNIT);
    if (u && u.getBoundingClientRect().height <= vh) {
      if (visible(u)) units.add(u);
    } else if (visible(el)) {
      blocks.add(el);
    }
  }
  const us = [...units], bs = [...blocks];
  const outer = us.filter((u) => !us.some((o) => o !== u && o.contains(u)));
  const inner = bs.filter((b) => !bs.some((o) => o !== b && b.contains(o)) && !us.some((u) => b.contains(u)));
  const order = (a, b) => (a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1);
  const text = (el) => {
    let t = el.innerText;
    while (t.includes(NL + NL + NL)) t = t.replaceAll(NL + NL + NL, NL + NL);
    return t.trim();
  };
  return JSON.stringify([...outer, ...inner].sort(order).map(text).filter(Boolean));
})()'
end
