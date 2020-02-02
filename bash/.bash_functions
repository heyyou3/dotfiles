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

PORTABLE_DEV_ENV='portable_dev_env'

dev_env_init() {
  cp -r "$HOME/dotfiles/$PORTABLE_DEV_ENV" ./
}

dev_env_setup() {
   PROJECT_NAME=$(basename $(pwd))
   cd $PORTABLE_DEV_ENV && PROJECT_NAME=$PROJECT_NAME docker-compose build --no-cache && cd -
}

dev_env_up() {
   PROJECT_NAME=$(basename $(pwd))
   cd $PORTABLE_DEV_ENV && PROJECT_NAME=$PROJECT_NAME docker-compose up -d && cd -
}

dev_env_attach() {
   PROJECT_NAME=$(basename $(pwd))
   echo "$PROJECT_NAME"_dev_env_container
   docker exec -it "$PROJECT_NAME"_dev_env_container /bin/bash
}

dev_env_clean() {
  PROJECT_NAME=$(basename $(pwd))
  cd $PORTABLE_DEV_ENV && docker-compose down --rmi all -v && cd -
  rm -rf ./$PORTABLE_DEV_ENV
}

