#!/usr/bin/env zx

$.verbose = false;

try {
  // 1. Get PR list and pipe directly to fzf to select one.
  // This is more robust for handling newlines than storing in a variable and echoing.
  const selectedLine = (await $`gh pr list | fzf`).stdout.trim();

  if (!selectedLine) {
    console.log("No PR selected, or no PRs found. Exiting.");
    process.exit(0);
  }

  // 2. Extract branch name from the selected PR
  const branchName = selectedLine.split('\t')[2];
  if (!branchName) {
    // This might happen if the gh pr list format changes.
    console.error('Could not parse branch name from the selected PR.');
    console.error('Selected line:', selectedLine);
    process.exit(1);
  }

  // 3. Create a worktree directory name with a timestamp
  const timestamp = Date.now();
  const sanitizedBranchName = branchName.replace(/[/]/g, '-');
  const worktreeDirName = `${sanitizedBranchName}-${timestamp}`;
  const worktreePath = `/tmp/${worktreeDirName}`;

  // 4. Create the git worktree
  console.log(`Creating git worktree at ${worktreePath}`);
  await $`git worktree add ${worktreePath} ${branchName}`;

  // 5. Create a new tmux window with the worktree directory as the current path
  console.log(`Creating tmux window '${worktreeDirName}'`);
  await $`tmux new-window -n ${worktreeDirName} -c ${worktreePath}`;

  console.log('✅ Successfully created worktree and tmux window.');

} catch (p) {
  // When fzf is exited via escape or Ctrl-C, it returns a non-zero exit code.
  // zx throws an exception in this case. We'll catch it and exit gracefully.
  if (p.exitCode > 0 && p.stdout === '') {
      console.log("No PR selected. Exiting.");
      process.exit(0);
  }
  
  // For other errors, print the error and exit.
  console.error(`An error occurred:`);
  if(p.stderr) console.error(p.stderr);
  if(p.stdout) console.error(p.stdout);
  process.exit(1);
}
