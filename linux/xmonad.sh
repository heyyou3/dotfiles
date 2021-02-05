#!/usr/bin/env bash

# Run xmobar
ps aux | grep 'xmobarrc' | perl -nlE 'if($_!~/grep/){say $_}' | perl -anlE 'system("kill $F[1]")'
sleep 0.2
/usr/bin/xmobar $HOME/.xmobarrc &
sleep 0.2

# View wallpaper
/usr/bin/feh --bg-fill $HOME/dotfiles/wallpaper.png

# Run xkeysnail
P=$(cat ~/start_config | base64 -d)
if [ "$(ps aux | grep 'xkeysnail' | perl -nlE 'if($_!~/grep/){say $_}' | perl -nlE 'END{say $.}')" -le 0 ]; then
  echo $P | sudo -S /usr/local/bin/xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py &
  sleep 0.2
fi

# set xset rate
/usr/bin/xset r rate 300 99 &

sleep 0.2

# Run compton
compton --config $HOME/dotfiles/linux/compton.conf &

# Run fcitx
ps aux | grep 'fcitx' | perl -nlE 'if($_!~/grep/){say $_}' | perl -anlE 'system("kill $F[1]")'
fcitx -d
