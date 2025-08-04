#!/usr/bin/env zx

import { spawn } from 'child_process';

// --- Helper Functions ---

/**
 * Checks if a command exists in the system's PATH.
 * @param {string} cmd The command name.
 * @returns {Promise<boolean>}
 */
async function commandExists(cmd) {
  try {
    await which(cmd);
    return true;
  } catch {
    return false;
  }
}

/**
 * Determines if the script is running in Windows Subsystem for Linux (WSL).
 * @returns {boolean}
 */
function isWSL() {
  return os.platform() === 'linux' && !!process.env.WSL_DISTRO_NAME;
}

/**
 * Spawns an interactive editor and waits for it to close.
 * @param {string} editor The editor command (e.g., 'nvim', 'vim').
 * @param {string} file The absolute path to the file to edit.
 * @returns {Promise<void>}
 */
function spawnEditor(editor, file) {
  return new Promise((resolve, reject) => {
    const [cmd, ...args] = [...editor.split(' '), file];
    const editorProcess = spawn(cmd, args, {
      stdio: 'inherit' // This is the key change
    });

    editorProcess.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        // We reject here, but will handle it gracefully in the main block
        reject(new Error(`Editor exited with code ${code}`));
      }
    });

    editorProcess.on('error', (err) => {
      reject(new Error(`Failed to start editor: ${err.message}`));
    });
  });
}


// --- Clipboard Logic ---

/**
 * Copies the given data to the system clipboard, automatically selecting the best tool.
 * @param {string | Buffer} data The data to copy.
 */
async function copyToClipboard(data) {
  if (await commandExists('lemonade')) {
    const p = $`lemonade copy`;
    p.stdin.write(data);
    p.stdin.end();
    await p;
    return;
  }

  const platform = os.platform();
  if (isWSL()) {
    const p = $`powershell.exe -command "$input | Set-Clipboard"`;
    p.stdin.write(data);
    p.stdin.end();
    await p;
  } else if (platform === 'darwin') {
    const p = $`pbcopy`;
    p.stdin.write(data);
    p.stdin.end();
    await p;
  } else if (platform === 'linux' && (await commandExists('xclip'))) {
    const p = $`xclip -selection clipboard`;
    p.stdin.write(data);
    p.stdin.end();
    await p;
  } else {
    throw new Error('No clipboard utility found (lemonade, powershell.exe, pbcopy, or xclip)');
  }
}

/**
 * Pastes content from the system clipboard, automatically selecting the best tool.
 * @returns {Promise<string>} The clipboard content.
 */
async function pasteFromClipboard() {
  if (await commandExists('lemonade')) {
    return (await $`lemonade paste`).stdout;
  }

  const platform = os.platform();
  if (isWSL()) {
    return (await $`powershell.exe -command "Get-Clipboard"`).stdout;
  } else if (platform === 'darwin') {
    return (await $`pbpaste`).stdout;
  } else if (platform === 'linux' && (await commandExists('xclip'))) {
    return (await $`xclip -selection clipboard -o`).stdout;
  } else {
    throw new Error('No clipboard utility found (lemonade, powershell.exe, pbpaste, or xclip)');
  }
}


// --- Main Execution ---

let tmpdir;
try {
  // 1. Get content from clipboard
  let content = '';
  try {
    content = await pasteFromClipboard();
  } catch (e) {
    console.error(chalk.yellow(`Could not read from clipboard: ${e.message}. Starting with empty content.`));
  }

  if (!content.trim()) {
    console.log('Clipboard is empty. Starting editor...');
  }

  // 2. Create a temporary file and write content to it
  tmpdir = await fs.mkdtemp(path.join(os.tmpdir(), 'clipper-'));
  const tmpfile = path.join(tmpdir, 'edit.txt');
  await fs.writeFile(tmpfile, content);

  // 3. Open the file in an editor using spawn
  const editor = process.env.EDITOR || 'nvim';
  
  await spawnEditor(editor, tmpfile);

  // 4. Read the edited content back
  const editedContent = await fs.readFile(tmpfile, 'utf-8');

  // 5. Copy the new content to the clipboard
  await copyToClipboard(editedContent);
} catch (err) {
  // Gracefully handle editor exit codes and other errors
  if (err.message.startsWith('Editor exited')) {
    console.error(chalk.yellow(err.message));
  } else {
    console.error(chalk.red(`An error occurred: ${err.message}`));
    process.exit(1);
  }
} finally {
  // 6. Clean up the temporary directory
  if (tmpdir) {
    await fs.rm(tmpdir, { recursive: true, force: true });
  }
}
