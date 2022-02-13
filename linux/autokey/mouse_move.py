from subprocess import PIPE, run
get_window_cmd = ['xdotool', 'getwindowfocus']
window_num = run(get_window_cmd, stdout=PIPE, stderr=PIPE, universal_newlines=True)
move_window_cmd = ['xdotool', 'mousemove', '--window', window_num.stdout, '--polar', '0', '0']
run(move_window_cmd)