#!/usr/bin/env zx

try {
  // 1. PowerShellでプロセスIDとウィンドウタイトルのリストを取得
  const windowListResult = await $`powershell.exe -Command "Get-Process | Where-Object { \\$_.MainWindowTitle -ne '' } | Select-Object Id,ProcessName"`;

  // 2. fzfで表示するために、先頭が数字以外の行を除外
  const windowListOutput = windowListResult.stdout;
  const lines = windowListOutput.split(/\r?\n/);
  const filteredLines = lines.filter(line => /^\s*\d/.test(line));
  const filteredLinesString = filteredLines.join('\n');

  // fzfに渡して選択させる
  const selection = await $`echo -n ${filteredLinesString} | fzf`;

  // 3. 選択された行からプロセスIDを抽出
  const processId = selection.stdout.trim().split(' ')[0];

  // 4. IDが見つからない場合は処理を中断
  if (!processId) {
    process.exit(0);
  }

  await $`powershell.exe -Command "(New-Object -ComObject WScript.Shell).AppActivate((Get-Process -Id ${processId}).MainWindowTitle)"`;

} catch (error) {
  // エラー処理
  if (error.exitCode !== null && error.exitCode !== 0) {
    console.error(chalk.red('スクリプトの実行中にエラーが発生しました:'));
    console.error(error.stderr);
  }

}
