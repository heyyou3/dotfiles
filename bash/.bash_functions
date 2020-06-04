mo_to_gif() {
  ffmpeg -i "$1" -r 10 "$2"
}

cdp() {
  default_path=~/work/
  cd ${1:-"$default_path"}$(ls -la ${1:-"$default_path"} | ruby -nle 'if $_[0]=="d" then puts $_ end' | peco | ruby -anle 'puts $F[8]' )
}

memo() {
  EXT='.adoc'
  WORK_LOG_BASE_PATH="$HOME/work/work_log"
  YEAR=$(date +'%Y')
  WORK_LOG_PATH="$WORK_LOG_BASE_PATH/$YEAR"
  # 書き込む年のディレクトリが存在しなければ作成する
  if ! [ -e "$WORK_LOG_PATH" ]; then
    mkdir -p "$WORK_LOG_PATH"
  fi

  # 引数が存在しなければ今日の日付のみでファイルを作成、編集する
  if [ -z $1 ]; then
    echo "$WORK_LOG_PATH/$(date +'%m-%d')$EXT"
  else
    echo "$WORK_LOG_PATH/$(date +'%m-%d')-$1$EXT"
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
  cd $PORTABLE_DEV_ENV && PROJECT_NAME=$PROJECT_NAME docker-compose down --rmi all -v && cd -
  rm -rf ./$PORTABLE_DEV_ENV
}

load_anyenv() {
  for env in $(ls $HOME/.anyenv/envs); do
    export PATH="$HOME/.anyenv/envs/$env/shims/:$PATH"
    export PATH="$HOME/.anyenv/envs/$env/bin:$PATH"
  done
  eval "$(anyenv init -)"
  eval "$(goenv init -)"
  eval "$(pyenv init -)"
  eval "$(direnv hook bash)"
}

carun() {
  cargo run $1
}

acc_perl_test() {
  for i in $(seq 1 $(ls tests/ | perl -nE 'END{say $./2}')); do diff -uw <(perl main.pl < ./tests/sample-$i.in) <(cat ./tests/sample-$i.out); done
}

acc_go_test() {
  for i in $(seq 1 $(ls tests/ | perl -nE 'END{say $./2}')); do diff -uw <(go run main.go < ./tests/sample-$i.in) <(cat ./tests/sample-$i.out); if [ $? -ne 0 ]; then echo "$i 件目のテストが失敗"; fi; done
}

acrt() {
  cargo atcoder test $1
}

acrs() {
  cargo atcoder submit $1
}

set_tmux_env() {
  tmux setenv $1 $2 && eval $(tmux showenv $1)
}

make_vim_settings() {
  target_dir="$(pwd)/.vim_settings"
  mkdir $target_dir
  touch "$target_dir/settings.vim"
}

