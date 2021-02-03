#!/usr/bin/env bash
ps aux | grep 'xmobarrc' | perl -nlE 'if($_!~/grep/){say $_}' | perl -anlE 'system("kill $F[1]")'
sleep 0.5
/usr/bin/xmobar $HOME/.xmobarrc &
sleep 0.5
/usr/bin/feh --bg-fill $HOME/dotfiles/wallpaper.png

P=$(cat ~/start_config | base64 -d)

if [ "$(ps aux | grep 'xkeysnail' | perl -nlE 'if($_!~/grep/){say $_}' | perl -nlE 'END{say $.}')" -le 0 ]; then
  echo $P | sudo -S /usr/local/bin/xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py &
  sleep 0.5
fi

sleep 0.5
/usr/bin/xset r rate 300 99 &
