# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/heyyou/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/Users/heyyou/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/heyyou/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/heyyou/.fzf/shell/key-bindings.bash"
