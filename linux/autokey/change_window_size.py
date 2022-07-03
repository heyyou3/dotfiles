#!/usr/bin/env python3

from subprocess import PIPE, run
get_window_cmd = ['xdotool', 'getwindowfocus']
window_num = run(get_window_cmd, stdout=PIPE, stderr=PIPE, universal_newlines=True)
change_window_size_cmd = ['xdotool', 'windowsize', window_num.stdout, '25%', '45%']
run(change_window_size_cmd)
