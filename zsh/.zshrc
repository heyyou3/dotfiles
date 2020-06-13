export DOT_FILES_PATH="$HOME/dotfiles"

export HISTFILE=$HOME/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY
export ENHANCD_FILTER=fzf

export ZINIT_HOME=$HOME/.zinit
if [ -d "$ZINIT_HOME" ]; then
  source "$ZINIT_HOME/bin/zinit.zsh"
  zinit wait lucid for \
    zsh-users/zsh-syntax-highlighting \
    b4b4r07/enhancd

  zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
    zsh-users/zsh-completions \
    zsh-users/zsh-autosuggestions
fi

source "$DOT_FILES_PATH/common_sh/common"

eval "$(starship init zsh)"
