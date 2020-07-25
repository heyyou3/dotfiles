if [ -z $TMUX ]; then
  export PATH="${HOME}/local/bin:${PATH}"
  if [ "$(uname)" == 'Linux' ]; then
    xmodmap "${HOME}/dotfiles/archlinux/.xmodmap"
    xmodmap "${HOME}/dotfiles/archlinux/.xmodmap"
    xmonad --replace > /dev/null 2> /dev/null &
  fi
fi
