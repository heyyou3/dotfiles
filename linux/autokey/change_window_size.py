#!/usr/bin/env python3

from subprocess import PIPE, run
get_window_cmd = ['xdotool', 'getwindowfocus']
window_num = run(get_window_cmd, stdout=PIPE, stderr=PIPE, universal_newlines=True)
move_window_cmd = ['xdotool', 'windowsize', window_num.stdout, '1700', '1000']
run(move_window_cmd)