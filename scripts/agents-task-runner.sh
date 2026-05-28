#!/usr/bin/env bash
# AGENTS_TASK runner — file-state-machine + zellij-resident loop.
# See .heyyou/design/agents-task-runner.md (rev7+).
# AGENTS_WORK_DIR は ^[a-zA-Z0-9_/.-]+ の安全な絶対パスのみを想定(空白・$・"・` を含めない)。
set -euo pipefail
umask 077

WORK="${AGENTS_WORK_DIR:-$HOME/work/ai-agents}"
# kdl/シェルへの展開前に fail-fast(security review round1 #1)
if [[ ! "$WORK" =~ ^/[a-zA-Z0-9_./-]+$ ]]; then
  echo "agents-task-runner: AGENTS_WORK_DIR must match ^/[a-zA-Z0-9_./-]+$, got: $WORK" >&2
  exit 2
fi
TASKS="$WORK/tasks"
HEY="$WORK/.heyyou"
LOCKDIR="$HEY/lock.d"
RUNNER_LOG="$HEY/log/runner.log"
TASK_LOG_DIR="$HEY/log/tasks"
STATE_DIR="$HEY/state/sessions"
LAYOUT_DIR="$HEY/state/layouts"
NAME_RE='^[a-zA-Z0-9_-]+$'
START_GUARD_SEC=5
LOOP_INTERVAL_SEC="${AGENTS_LOOP_INTERVAL:-60}"

log() {
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$RUNNER_LOG"
}

ensure_dirs() {
  mkdir -p "$TASKS"/{todo,doing,done,failed}/{engineer,business} \
           "$TASK_LOG_DIR" "$STATE_DIR" "$LAYOUT_DIR"
  # design 「機密」節: failed/ や log/ にタスク本文が残るため traversable にしない
  chmod 700 "$WORK" "$HEY" "$TASKS" "$TASK_LOG_DIR" "$STATE_DIR" "$LAYOUT_DIR" 2>/dev/null || true
  chmod 700 "$TASKS"/{todo,doing,done,failed} 2>/dev/null || true
  chmod 700 "$TASKS"/{todo,doing,done,failed}/{engineer,business} 2>/dev/null || true
}

acquire_lock() {
  # mkdir is atomic on local fs; works on macOS where flock(1) is absent.
  if ! mkdir "$LOCKDIR" 2>/dev/null; then
    if [[ -f "$LOCKDIR/pid" ]]; then
      local pid
      pid=$(cat "$LOCKDIR/pid" 2>/dev/null || echo "")
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        return 1
      fi
      # stale lock — owner gone
      rm -rf "$LOCKDIR"
      mkdir "$LOCKDIR" || return 1
    else
      return 1
    fi
  fi
  echo $$ >"$LOCKDIR/pid"
  return 0
}

release_lock() {
  rm -rf "$LOCKDIR"
}

session_exists() {
  zellij list-sessions --no-formatting --short 2>/dev/null | grep -Fxq "$1"
}

now_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

epoch_of() {
  # parse ISO8601 UTC → epoch seconds (BSD date)
  date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null
}

write_failed_reason() {
  # design 170-183 行: 後追いで「session 消滅 failed」と「state 欠落 failed」を区別できるよう
  # reason を failed/<profile>/<name>.reason.json に残す。
  local name="$1" profile="$2" reason="$3"
  jq -n \
    --arg name "$name" --arg profile "$profile" --arg reason "$reason" \
    --arg at "$(now_utc)" \
    '{name:$name, profile:$profile, reason:$reason, failed_at:$at}' \
    >"$TASKS/failed/$profile/$name.reason.json"
  chmod 600 "$TASKS/failed/$profile/$name.reason.json"
}

sweep_state() {
  shopt -s nullglob
  local f name profile started_at started_epoch now_epoch doing_path
  # (1) state.json 起点
  for f in "$STATE_DIR"/*.json; do
    name=$(jq -r '.name' "$f" 2>/dev/null || echo "")
    profile=$(jq -r '.profile' "$f" 2>/dev/null || echo "")
    started_at=$(jq -r '.started_at' "$f" 2>/dev/null || echo "")
    # 信頼境界の再確認(security review round1 #5): state.json は手で編集可能。
    if [[ ! "$name" =~ $NAME_RE ]] || [[ "$profile" != "engineer" && "$profile" != "business" ]]; then
      log "sweep: malformed state file $f (name=$name profile=$profile) — removing"
      rm -f "$f"
      continue
    fi
    doing_path="$TASKS/doing/$profile/$name.md"
    if [[ ! -f "$doing_path" ]]; then
      log "sweep: $name completed — clearing state"
      rm -f "$f" "$LAYOUT_DIR/$name.kdl"
      continue
    fi
    if session_exists "$name"; then
      continue
    fi
    started_epoch=$(epoch_of "$started_at" || echo 0)
    now_epoch=$(date -u +%s)
    if (( now_epoch - started_epoch < START_GUARD_SEC )); then
      continue
    fi
    log "sweep: $name session vanished — moving to failed"
    mv -n "$doing_path" "$TASKS/failed/$profile/$name.md" || true
    if [[ -f "$TASK_LOG_DIR/$name.log" ]]; then
      cp -p "$TASK_LOG_DIR/$name.log" "$TASKS/failed/$profile/$name.log" || true
    fi
    write_failed_reason "$name" "$profile" "session-vanished"
    rm -f "$f" "$LAYOUT_DIR/$name.kdl"
  done
  # (2) doing/ 起点孤児
  local p
  for profile in engineer business; do
    for p in "$TASKS/doing/$profile"/*.md; do
      [[ -e "$p" ]] || continue
      name=$(basename "$p" .md)
      [[ -f "$STATE_DIR/$name.json" ]] && continue
      log "sweep: orphan $name (state missing) — moving to failed"
      mv -n "$p" "$TASKS/failed/$profile/$name.md" || true
      write_failed_reason "$name" "$profile" "state-missing-orphan"
      rm -f "$LAYOUT_DIR/$name.kdl"
    done
  done
  shopt -u nullglob
}

write_layout() {
  local name="$1" profile="$2"
  local task_rel="tasks/doing/$profile/$name.md"
  local layout_path="$LAYOUT_DIR/$name.kdl"
  # prompt は KDL double-quote と shell single-quote の二重エスケープに乗せるため
  # '/"/\\/改行 を含めない契約。<name> はサニタイズ済、<profile> は固定文字列、
  # 指示本文も同様にこの 4 文字を使わずに書く(rev7 / hotfix design 参照)。
  local prompt="${task_rel} を読み、本文の指示を実行してください。完了したら必ず: (1) このファイルを tasks/done/${profile}/${name}.md に mv (2) .heyyou/state/sessions/${name}.json を削除 (3) /exit。途中で人間判断が必要になったら mv も削除も /exit もせず停止してください。"
  # zellij 0.43 では pane { env { ... } } 構文が無効なので、bash -lc 経由で
  # WORKER_PROFILE を export する。args は KDL の複数引数渡し(2 トークン分け)で書く。
  cat >"$layout_path" <<KDL
layout {
  cwd "$WORK"
  tab name="claude" {
    pane {
      command "bash"
      args "-lc" "WORKER_PROFILE=$profile exec claude '$prompt'"
    }
  }
}
KDL
  chmod 600 "$layout_path"
  printf '%s\n' "$layout_path"
}

write_state_json() {
  # tmp+rename でアトミック書き込み(security review round1 #2)。
  # 直接リダイレクトだと部分書き込みが sweep の malformed 判定で消されうる。
  local name="$1" profile="$2" task_file="$3"
  local state_path="$STATE_DIR/$name.json"
  local tmp
  tmp=$(mktemp "$state_path.XXXXXX")
  jq -n \
    --arg name "$name" \
    --arg profile "$profile" \
    --arg started_at "$(now_utc)" \
    --arg session "$name" \
    --arg task_file "$task_file" \
    '{name:$name, profile:$profile, started_at:$started_at, session:$session, task_file:$task_file}' \
    >"$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$state_path"
}

update_state_task_file() {
  # task_file は informational(sweep は profile/name から path を再構成する)。
  # state-first-write と mv の race 解析時にデバッグ手がかりになる。
  local name="$1" new_path="$2"
  local state_path="$STATE_DIR/$name.json"
  local tmp
  tmp=$(mktemp "$state_path.XXXXXX")
  jq --arg p "$new_path" '.task_file = $p' "$state_path" >"$tmp" && mv "$tmp" "$state_path"
}

pick_one() {
  shopt -s nullglob
  local profile p name todo_path doing_path layout_path
  for profile in engineer business; do
    for p in "$TASKS/todo/$profile"/*.md; do
      [[ -e "$p" ]] || continue
      name=$(basename "$p" .md)
      if [[ ! "$name" =~ $NAME_RE ]]; then
        log "pick: skip invalid name '$name' (must match $NAME_RE)"
        continue
      fi
      if session_exists "$name"; then
        log "pick: skip '$name' — zellij session already exists"
        continue
      fi
      if [[ -f "$TASKS/done/$profile/$name.md" || -f "$TASKS/failed/$profile/$name.md" ]]; then
        log "pick: skip '$name' — done/ or failed/ has same name"
        continue
      fi
      todo_path="$p"
      doing_path="$TASKS/doing/$profile/$name.md"
      write_state_json "$name" "$profile" "$todo_path"
      mv "$todo_path" "$doing_path"
      update_state_task_file "$name" "$doing_path"
      layout_path=$(write_layout "$name" "$profile")
      log "pick: launching '$name' profile=$profile layout=$layout_path"
      # fire-and-forget: client が TTY panic しても server + pane は生存する(spike 確認済)
      zellij -s "$name" -n "$layout_path" \
        </dev/null >>"$TASK_LOG_DIR/$name.log" 2>&1 &
      disown || true
      shopt -u nullglob
      return 0
    done
  done
  shopt -u nullglob
  return 1
}

one_iteration() {
  ensure_dirs
  if ! acquire_lock; then
    log "iteration: lock held — skip"
    return 0
  fi
  trap release_lock EXIT
  sweep_state
  pick_one || true
  release_lock
  trap - EXIT
}

main() {
  ensure_dirs
  if [[ "${1:-}" == "--loop" ]]; then
    log "runner: loop start (interval=${LOOP_INTERVAL_SEC}s)"
    while true; do
      one_iteration
      sleep "$LOOP_INTERVAL_SEC"
    done
  else
    one_iteration
  fi
}

main "$@"
