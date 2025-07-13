#!/usr/bin/env zx
import fs from 'fs/promises';
import os from 'os';
import path from 'path';

try {
    const bookmarkPath = path.join(os.homedir(), 'dotfiles', '.heyyou', 'bookmark.md');
    const content = await fs.readFile(bookmarkPath, 'utf-8');
    const lines = content.trim().split('\n');

    const bookmarks = lines.map(line => {
        const match = line.match(/\[(.*?)\]\((.*?)\)/);
        if (!match) return null;
        return { description: match[1], url: match[2] };
    }).filter(Boolean);

    if (bookmarks.length === 0) {
        console.log("No bookmarks found.");
        process.exit(0);
    }

    const descriptions = bookmarks.map(b => b.description);

    const proc = $({input: descriptions.join('\n')})`fzf`;
    const { stdout } = await proc;
    const selectedDescription = stdout.trim();

    if (selectedDescription) {
        const selectedBookmark = bookmarks.find(b => b.description === selectedDescription);
        if (selectedBookmark && selectedBookmark.url) {
            const browser = process.env['BROWSER_BIN'];
            await $`nohup ${browser} ${selectedBookmark.url} >/dev/null 2>&1 &`;
        }
    }
} catch (p) {
    if (p.exitCode === 130 || (p.stdout === '' && p.stderr === '')) {
        process.exit(0);
    }
    console.error("An error occurred:", p);
    process.exit(1);
}
