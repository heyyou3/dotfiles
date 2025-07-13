#!/usr/bin/env zx

import fs from 'fs/promises';
import path from 'path';

async function copyToClipboard(text) {
    let copyCommand;
    switch (process.platform) {
        case 'darwin':
            copyCommand = ['pbcopy'];
            break;
        case 'win32':
            copyCommand = ['clip'];
            break;
        default:
            copyCommand = ['xsel', '--clipboard'];
            break;
    }
    try {
        await $({input: text})`${copyCommand}`
    } catch (err) {
        console.error(`Failed to copy to clipboard. Is '${copyCommand[0]}' installed?`);
        throw err;
    }
}

try {
    const snippetsPath = path.join(process.env.HOME, 'dotfiles/.heyyou', 'snippets.txt');
    const content = await fs.readFile(snippetsPath, 'utf-8');
    const lines = content.trim().split('\n');

    const snippets = lines.map(line => {
        const match = line.match(/\[(.*?)\]\s*\((.*)\)/);
        if (!match) return null;
        return { description: match[1], command: match[2] };
    }).filter(Boolean);

    const descriptions = snippets.map(s => s.description);

    const proc = $`fzf --height=40% --reverse`;
    proc.stdin.write(descriptions.join('\n'));
    proc.stdin.end();
    const { stdout } = await proc;
    const selectedDescription = stdout.trim();

    if (selectedDescription) {
        const selectedSnippet = snippets.find(s => s.description === selectedDescription);
        if (selectedSnippet) {
            await copyToClipboard(selectedSnippet.command);
        }
    }
} catch (p) {
    // Exit cleanly if fzf is cancelled (exit code 130)
    // or if no selection is made (empty stdout).
    if (p.exitCode === 130 || (p.stdout === '' && p.stderr === '')) {
        process.exit(0);
    }
    console.error(p);
}
