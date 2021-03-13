#!/bin/sh
feh --bg-fill $HOME/dotfiles/wallpaper.png

P=$(cat ~/start_config | base64 -d)
echo $P | sudo -S pkill 'xkeysnail'
sleep 0.1
echo $P | sudo -S xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py &
