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

source "$DOT_FILES_PATH/common_sh/common"
source "$DOT_FILES_PATH/zsh/zinit/main.zsh"

