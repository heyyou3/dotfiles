# -*- coding: utf-8 -*-

import re
from xkeysnail.transform import *

define_multipurpose_modmap({
    # SandS
    Key.SPACE: [Key.SPACE, Key.LEFT_SHIFT],
})
define_modmap({
    Key.CAPSLOCK: Key.LEFT_CTRL,
    Key.MUHENKAN: Key.LEFT_META,
    Key.HENKAN: Key.RIGHT_ALT,
    Key.KATAKANAHIRAGANA: Key.RIGHT_ALT,
    Key.RIGHT_META: Key.RIGHT_ALT,
    Key.LEFT_ALT: Key.LEFT_CTRL,
    Key.PAGE_UP: Key.BTN_LEFT,
    Key.PAGE_DOWN: Key.BTN_RIGHT,
    Key.RIGHT_ALT: Key.LEFT_CTRL,
})
define_keymap(None, {
    K('key_0'): K('Shift-key_0'),
    K('Shift-key_0'): K('key_0'),
    K('key_1'): K('Shift-key_1'),
    K('Shift-key_1'): K('key_1'),
    K('key_2'): K('Shift-key_2'),
    K('Shift-key_2'): K('key_2'),
    K('key_3'): K('Shift-key_3'),
    K('Shift-key_3'): K('key_3'),
    K('key_4'): K('Shift-key_4'),
    K('Shift-key_4'): K('key_4'),
    K('key_5'): K('Shift-key_5'),
    K('Shift-key_5'): K('key_5'),
    K('key_6'): K('Shift-key_6'),
    K('Shift-key_6'): K('key_6'),
    K('key_7'): K('Shift-key_7'),
    K('Shift-key_7'): K('key_7'),
    K('key_8'): K('Shift-key_8'),
    K('Shift-key_8'): K('key_8'),
    K('key_9'): K('Shift-key_9'),
    K('Shift-key_9'): K('key_9'),
})

