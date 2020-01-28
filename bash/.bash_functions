mo_to_gif() {
  ffmpeg -i "$1" -r 10 "$2"
}

cdp() {
  cd ${1:-~/work/}$(ls -la ${1:-~/work/} | peco | awk '{print $9}')
}

memo() {
  WORK_LOG_BASE_PATH="$HOME/work/work_log"
  YEAR=$(date +'%Y')
  WORK_LOG_PATH="$WORK_LOG_BASE_PATH/$YEAR"
  # 書き込む年のディレクトリが存在しなければ作成する
  if ! [ -e "$WORK_LOG_PATH" ]; then
    mkdir -p "$WORK_LOG_PATH"
  fi

  # 引数が存在しなければ今日の日付のみでファイルを作成、編集する
  if [ -z $1 ]; then
    echo "$WORK_LOG_PATH/$(date +'%m-%d').md"
  else
    echo "$WORK_LOG_PATH/$(date +'%m-%d')-$1.md"
  fi
}

