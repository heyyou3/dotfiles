#!/usr/bin/env zx

try {
  const query = await question('検索文字列: ');
  const browser = process.env['BROWSER_BIN'];
  const url = new URL(`https://google.com/search?q=${query}`).toString();
  await $`${browser} ${url}`;
  procese.exit(0);
} catch (error) {
  console.log(error);
  process.exit(1);
}

