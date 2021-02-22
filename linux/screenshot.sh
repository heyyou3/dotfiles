#!/bin/bash
slop=$(slop -f "%g") || exit 1
read -r G < <(echo $slop)
current_date=$(date '+%Y%m%d%H%M%S')
import -window root -crop $G "$HOME/capture/$current_date.png"
