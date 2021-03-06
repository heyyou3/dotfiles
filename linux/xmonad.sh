#!/usr/bin/env bash

# View wallpaper
/usr/bin/feh --bg-fill $HOME/dotfiles/wallpaper.png

# Run xkeysnail
P=$(cat ~/start_config | base64 -d)
echo $P | sudo -S pkill 'xkeysnail'
sleep 0.2
if [ $(echo -e 'devices' | bluetoothctl | perl -anlE 'if($_=~/Device/&&$_=~/HHKB-BT/){say "info ".$F[1]}' | bluetoothctl | perl -anlE 'if($_=~/Connected:/){say $F[1]}') = 'yes' ]; then
  hhkb_event=$(cat /proc/bus/input/devices | perl -anlE '$hhkb_i; if($_=~/HHKB-BT Keyboard/){$hhkb_i=$.}if($hhkb_i>4&&($hhkb_i+4)==$.){say $F[3]}')
  echo $P | sudo -S /usr/local/bin/xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py --device "/dev/input/$hhkb_event" &
else
  echo $P | sudo -S /usr/local/bin/xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py &
fi
sleep 0.2

# set xset rate
/usr/bin/xset r rate 300 99 &

sleep 0.2

# Run compton
compton --config $HOME/dotfiles/linux/compton.conf &

# Run fcitx
ps aux | grep 'fcitx' | perl -nlE 'if($_!~/grep/){say $_}' | perl -anlE 'system("kill $F[1]")'
fcitx -d

# Run ulauncher
ulauncher &
