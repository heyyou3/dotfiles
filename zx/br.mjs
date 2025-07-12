#!/usr/bin/env zx
import fs from "fs";
import os from "os";

try {
  const line = await $`cat ${os.homedir()}/dotfiles/.heyyou/bookmark.md | fzf`;

  if (line) {
    const url = String(line).match(/\((.*)\)/)?.[1];
    if (url) {
      await $`nohup ${process.env['BROWSER_BIN']} ${url} > /dev/null 2>&1 &`;
    }
  }
  process.on('exit', () => process.exit(0));
} catch (err) {
  process.on('exit', () => process.exit(1));
}
