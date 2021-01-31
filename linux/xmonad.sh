#!/usr/bin/env bash
P=$(cat ~/start_config | base64 -d)

if [ "$(ps aux | grep 'xkeysnail' | perl -nlE 'if($_!~/grep/){say $_}' | perl -nlE 'END{say $.}')" -le 0 ]; then
  echo $P | sudo -S /usr/local/bin/xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py &
  sleep 2
fi

ps aux | grep 'xmobarrc' | perl -nlE 'if($_!~/grep/){say $_}' | perl -anlE 'system("kill $F[1]")'
sleep 1
/usr/bin/xmobar $HOME/.xmobarrc &
/usr/bin/xset r rate 300 99 &
