export PATH=$HOME/bin:/usr/local/bin:$PATH
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

export ZPLUG_HOME=$HOME/.zplug
source $ZPLUG_HOME/init.zsh

zplug 'b4b4r07/enhancd', use:init.sh
zplug 'zsh-users/zsh-completions'
zplug 'zsh-users/zsh-autosuggestions'
zplug 'dracula/zsh', as:theme

zplug load

ENHANCD_FILTER=peco; export ENHANCD_FILTER

local ret_status="%(?:%{$fg_bold[green]%}$ :%{$fg_bold[red]%}$ [%?])"

PROMPT='${ret_status}%{$fg_bold[green]%}%C $(git_prompt_info)% %{$reset_color%}'

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
for env in $(ls $HOME/.anyenv/envs); do
  export PATH="$HOME/.anyenv/envs/$env/shims/:$PATH"
  export PATH="$HOME/.anyenv/envs/$env/bin:$PATH"
done
# eval "$(anyenv init -)"
# eval "$(goenv init -)"

# Python
export PYENV_ROOT=$HOME/.anyenv/envs/pyenv

# Go
export GO_VERSION=1.11.2
export GO111MODULE=on
export GOROOT=$HOME/.anyenv/envs/goenv/versions/$GO_VERSION
export GOPATH=$HOME/go_work
export PATH=$GOROOT/bin:$PATH
export PATH=$GOPATH/bin:$PATH
alias gotest='(){go test -v -coverprofile=cover.out; go tool cover -html=cover.out}'
alias tf='terraform'
alias pvim='vim $(ls | peco)'
alias less='less -X'
alias tmux='TERM=screen-256color-bce tmux -u'
