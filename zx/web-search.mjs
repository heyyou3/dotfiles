#!/usr/bin/env zx

try {
  const query = await question('search: ');
  const browser = process.env['BROWSER_BIN'];
  if (/(^https:\/\/|^http:\/\/)/.test(query)) {
    await $`${browser} ${query}`;
    process.exit(0);
  }
  const url = new URL(`https://google.com/search?q=${query}`).toString();
  await $`${browser} ${url}`;
  procese.exit(0);
} catch (error) {
  console.log(error);
  process.exit(1);
}

