export DOT_FILES_PATH="$HOME/dotfiles"

source "$DOT_FILES_PATH/common_sh/common"

[ -f "$DOT_FILES_PATH/bash/.fzf.bash" ] && source "$DOT_FILES_PATH/bash/.fzf.bash"

source "$DOT_FILES_PATH/bash/git-prompt.sh"
source "$DOT_FILES_PATH/bash/git-completion"

eval "$(starship init bash)"

# 常用シェルは fish。bash でも対話ログイン時は fish へ exec する(zsh/.zshrc と同じ)
if [[ $- == *i* ]] && command -v fish >/dev/null; then
    exec fish
fi
