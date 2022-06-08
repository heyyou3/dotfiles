# Enter script code
from subprocess import run, PIPE
import time
run(['rofi', '-show', 'window', '-window-format', '[{n}]: {t}'], stdout=PIPE, stderr=PIPE, universal_newlines=True)
get_window_cmd = ['xdotool', 'getwindowfocus']
window_num = run(get_window_cmd, stdout=PIPE, stderr=PIPE, universal_newlines=True)
move_window_cmd = ['xdotool', 'mousemove', '--window', window_num.stdout, '--polar', '0', '0']
time.sleep(0.2)
run(move_window_cmd)