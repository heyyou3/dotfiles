#!/usr/bin/env bash

# Terminate already running bar instances
pkill polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar
for m in $(polybar --list-monitors | cut -d":" -f1); do
    MONITOR=$m polybar main -c $(dirname $0)/config.ini &
done

