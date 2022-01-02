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

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}}/.zinit/zinit.git"
if [ -d "$ZINIT_HOME" ]; then
  source "${ZINIT_HOME}/zinit.zsh"

  zinit wait lucid for \
    zsh-users/zsh-syntax-highlighting \
    b4b4r07/enhancd

  zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions \
    zsh-users/zsh-autosuggestions
fi

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line

source "$DOT_FILES_PATH/common_sh/common"

eval "$(starship init zsh)"
eval "$(direnv hook zsh)"
