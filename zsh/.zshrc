export DOT_FILES_PATH="$HOME/dotfiles"

export HISTFILE=$HOME/.zsh_history
export HISTSIZE=10000
export SAVEHIST=100000
export ENHANCD_FILTER=fzf
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=60'

setopt histappend
setopt share_history
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

function select_history() {
  BUFFER=$(history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="history > ")
  CURSOR=$#BUFFER
}
zle -N select_history
bindkey '^r' select_history

# ZIM SETTING START
zstyle ':zim:zmodule' use 'degit'
ZIM_HOME=~/.zim

if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

source ${ZIM_HOME}/init.zsh
# ZIM SETTING END

source "$DOT_FILES_PATH/common_sh/common"
