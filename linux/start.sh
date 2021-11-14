#!/usr/bin/env bash
# View wallpaper
feh --bg-fill $HOME/dotfiles/wallpaper.png

xmodmap $HOME/dotfiles/linux/Xmodmap
pkill xcape
xcape -e '#65=space'

# set xset rate
xset r rate 300 99 &

xset s off -dpms

sleep 0.1

xsetroot -cursor_name left_ptr

# Run compton
compton --config $HOME/dotfiles/linux/compton.conf &

