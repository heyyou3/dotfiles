#!/usr/bin/env bash
P=$(cat ~/start_config | base64 -d)

echo $P | sudo -S /usr/local/bin/xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py &
/usr/bin/xmobar $HOME/.xmobarrc &
sleep 2
/usr/bin/xset r rate 300 99 &
sleep 2
synclient TouchpadOff=1
