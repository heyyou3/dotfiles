#!/usr/bin/env zx
import fs from "fs";
import os from "os";

try {
  const line = await $`cat ${os.homedir()}/dotfiles/.heyyou/bookmark.md | fzf`;

  if (line) {
    const url = String(line).match(/\((.*)\)/)?.[1];
    if (url) {
      await $`${process.env['BROWSER_BIN']} ${url}`;
    }
  }
} catch (err) {
  // pass
}
