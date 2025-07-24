#!/usr/bin/env zx

const translateUrl = 'https://www.deepl.com/ja/translator#en/ja/'
const browser = process.env['BROWSER_BIN'];

if (process.argv[3] == null) {
  const target = await question('英語を入力してください: ');
  await $`${browser} ${translateUrl}${target}`;
} else {
  await $`${browser} ${translateUrl}${process.argv[3]}`;
}

