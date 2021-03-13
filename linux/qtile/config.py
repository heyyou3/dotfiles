# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
import os
import subprocess
from typing import List  # noqa: F401

from libqtile import bar, layout, widget, hook
from libqtile.config import Click, Drag, Group, Key, Screen, Match
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

mod = "mod4"
terminal = guess_terminal()

keys = [
     ### The essentials
     Key([mod], "Return",
         lazy.spawn(terminal),
         desc='Launches My Terminal'
         ),
     Key([mod], "Tab",
         lazy.next_layout(),
         desc='Toggle through layouts'
         ),
     Key([mod], "c",
         lazy.window.kill(),
         desc='Kill active window'
         ),
     Key([mod, "shift"], "r",
         lazy.restart(),
         desc='Restart Qtile'
         ),
     Key([mod, "shift"], "q",
         lazy.shutdown(),
         desc='Shutdown Qtile'
         ),
     Key([mod], "slash",
         lazy.spawn('rofi -show drun'),
         desc='Launches rofi'
         ),
     ### Switch focus to specific monitor (out of three)
     Key([mod], "w",
         lazy.to_screen(0),
         desc='Keyboard focus to monitor 1'
         ),
     Key([mod], "e",
         lazy.to_screen(1),
         desc='Keyboard focus to monitor 2'
         ),
     Key([mod], "r",
         lazy.to_screen(2),
         desc='Keyboard focus to monitor 3'
         ),
     ### Switch focus of monitors
     Key([mod], "period",
         lazy.next_screen(),
         desc='Move focus to next monitor'
         ),
     Key([mod], "comma",
         lazy.prev_screen(),
         desc='Move focus to prev monitor'
         ),
     ### Treetab controls
     Key([mod, "control"], "k",
         lazy.layout.section_up(),
         desc='Move up a section in treetab'
         ),
     Key([mod, "control"], "j",
         lazy.layout.section_down(),
         desc='Move down a section in treetab'
         ),
     ### Window controls
     Key([mod], "k",
         lazy.layout.down(),
         desc='Move focus down in current stack pane'
         ),
     Key([mod], "j",
         lazy.layout.up(),
         desc='Move focus up in current stack pane'
         ),
     Key([mod, "shift"], "k",
         lazy.layout.shuffle_down(),
         desc='Move windows down in current stack'
         ),
     Key([mod, "shift"], "j",
         lazy.layout.shuffle_up(),
         desc='Move windows up in current stack'
         ),
     Key([mod], "h",
         lazy.layout.shrink(),
         lazy.layout.decrease_nmaster(),
         desc='Shrink window (MonadTall), decrease number in master pane (Tile)'
         ),
     Key([mod], "l",
         lazy.layout.grow(),
         lazy.layout.increase_nmaster(),
         desc='Expand window (MonadTall), increase number in master pane (Tile)'
         ),
     Key([mod], "n",
         lazy.layout.normalize(),
         desc='normalize window size ratios'
         ),
     Key([mod], "m",
         lazy.layout.maximize(),
         desc='toggle window between minimum and maximum sizes'
         ),
     Key([mod], "z",
         lazy.window.toggle_floating(),
         desc='toggle floating'
         ),
     Key([mod, "shift"], "m",
         lazy.window.toggle_fullscreen(),
         desc='toggle fullscreen'
         ),
     ### Stack controls
     Key([mod, "shift"], "space",
         lazy.layout.rotate(),
         lazy.layout.flip(),
         desc='Switch which side main pane occupies (XmonadTall)'
         ),
     Key([mod], "space",
         lazy.layout.next(),
         desc='Switch window focus to other pane(s) of stack'
         ),
     Key([mod, "control"], "Return",
         lazy.layout.toggle_split(),
         desc='Toggle between split and unsplit sides of stack'
         ),
]

groups = [
    Group("a", layout='monadtall'),
    Group("s", layout='monadtall'),
    Group("d", layout='monadtall'),
    Group("f", layout='monadtall'),
    Group("u", layout='monadtall'),
    Group("i", layout='monadtall'),
    Group("o", layout='monadtall'),
    Group("p", layout='monadtall'),
]

for i in groups:
    keys.extend([
        # mod1 + letter of group = switch to group
        Key([mod], i.name, lazy.group[i.name].toscreen(),
            desc="Switch to group {}".format(i.name)),

        # mod1 + shift + letter of group = switch to & move focused window to group
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True),
            desc="Switch to & move focused window to group {}".format(i.name)),
        # Or, use below if you prefer not to switch to that group.
        # # mod1 + shift + letter of group = move focused window to group
        # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
        #     desc="move focused window to group {}".format(i.name)),
    ])

layout_theme = {"border_width": 2,
                "margin": 8,
                "border_focus": "e1acff",
                "border_normal": "1D2330"
                }

layouts = [
    #layout.MonadWide(**layout_theme),
    #layout.Bsp(**layout_theme),
    #layout.Stack(stacks=2, **layout_theme),
    #layout.Columns(**layout_theme),
    #layout.RatioTile(**layout_theme),
    #layout.VerticalTile(**layout_theme),
    #layout.Matrix(**layout_theme),
    #layout.Zoomy(**layout_theme),
    layout.MonadTall(**layout_theme),
    layout.Max(**layout_theme),
    layout.Tile(shift_windows=True, **layout_theme),
    layout.Stack(num_stacks=2),
    layout.TreeTab(
         font = "Ubuntu",
         fontsize = 10,
         sections = ["FIRST", "SECOND"],
         section_fontsize = 11,
         bg_color = "141414",
         active_bg = "90C435",
         active_fg = "000000",
         inactive_bg = "384323",
         inactive_fg = "a0a0a0",
         padding_y = 5,
         section_top = 10,
         panel_width = 320
         ),
    layout.Floating(**layout_theme)
]

widget_defaults = dict(
    font='sans',
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayout(),
                widget.GroupBox(),
                widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        'launch': ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                widget.Systray(),
                widget.Clock(format='%Y-%m-%d %a %I:%M %p'),
                widget.QuickExit(),
            ],
            24,
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
main = None
follow_mouse_focus = False
bring_front_click = True
cursor_warp = False
floating_layout = layout.Floating(float_rules=[
    # Run the utility of `xprop` to see the wm class and name of an X client.
    {'wmclass': 'confirm'},
    {'wmclass': 'dialog'},
    {'wmclass': 'download'},
    {'wmclass': 'error'},
    {'wmclass': 'file_progress'},
    {'wmclass': 'notification'},
    {'wmclass': 'splash'},
    {'wmclass': 'toolbar'},
    {'wmclass': 'confirmreset'},  # gitk
    {'wmclass': 'makebranch'},  # gitk
    {'wmclass': 'maketag'},  # gitk
    {'wname': 'branchdialog'},  # gitk
    {'wname': 'pinentry'},  # GPG key password entry
    {'wmclass': 'ssh-askpass'},  # ssh-askpass
    # Match(wmname='Ulancher'),
])
auto_fullscreen = True
focus_on_window_activation = "smart"

@hook.subscribe.startup
def start_once():
    subprocess.call(['/home/heyyou/dotfiles/linux/qtile/autostart.sh'])

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
