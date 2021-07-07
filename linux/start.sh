#!/usr/bin/env bash
# View wallpaper
feh --bg-fill $HOME/dotfiles/wallpaper.png

# Run xkeysnail
P=$(cat ~/start_config | base64 -d)
if [ $(ps aux | perl -nlE '$c;BEGIN{$c=0}if(/xkeysnail/&&!/grep xkeysnail/){$c++}END{say $c}') -eq 0 ]; then
  if [ $(echo -e 'devices' | bluetoothctl | perl -anlE 'if($_=~/Device/&&$_=~/HHKB-BT/){say "info ".$F[1]}' | bluetoothctl | perl -anlE 'if($_=~/Connected:/){say $F[1]}') = 'yes' ]; then
    hhkb_event=$(cat /proc/bus/input/devices | perl -anlE '$hhkb_i; if($_=~/HHKB-BT Keyboard/){$hhkb_i=$.}if($hhkb_i>4&&($hhkb_i+4)==$.){say $F[3]}')
    echo $P | sudo -S xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py --device "/dev/input/$hhkb_event" &
  else
    echo $P | sudo -S xkeysnail $HOME/dotfiles/linux/xkeysnail/config.py &
  fi
fi

# set xset rate
xset r rate 300 99 &

xset s off -dpms

sleep 0.1

xsetroot -cursor_name left_ptr

# Run compton
compton --config $HOME/dotfiles/linux/compton.conf &

