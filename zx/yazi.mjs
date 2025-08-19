#!/usr/bin/env zx

$.verbose = false;

let window_name = '';
try {
  window_name = (await fs.readFile('/tmp/yazi_current_window_name', 'utf-8')).trim();
} catch {
  // file might not exist, ignore
}

if (window_name) {
  $.env.NVIM_LISTEN_ADDRESS = `/tmp/${window_name}.nvim.socket`;
}
$.env.EDITOR = 'nvr';

let cwd = '';
try {
    let p = await $`nvr --remote-expr 'expand("%:p:h")'`;
    cwd = p.stdout.trim();

    if (!cwd || cwd === '.') {
      p = await $`nvr --remote-expr 'getcwd()'`;
      cwd = p.stdout.trim();
    }
} catch (error) {
    // nvr might not be available or fail.
    // cwd will remain empty, and we'll use the fallback which is the current directory.
}

let isDir = false;
if (cwd) {
    try {
        isDir = (await fs.stat(cwd)).isDirectory();
    } catch {
        isDir = false;
    }
}

if (isDir) {
  await $`yazi ${cwd}`;
} else {
  await $`yazi`;
}
