#!/usr/bin/env bun

import { $ } from "bun";
const args = Bun.argv.slice(2);
const HOME = Bun.env.HOME;

const settings: Record<string, string> = await Bun.file(
  `${HOME}/.settings.json`,
).json();

if (args.length < 1) {
  console.log("Usage: apps.ts <app>");
  process.exit(1);
}

console.log(settings);

const app = args[0];
const rest = args.slice(1);

if (settings && settings.apps && Object.keys(settings.apps).includes(app)) {
  const executable = settings.apps[app];

  const proc = Bun.spawn([executable, ...rest]);
  proc.unref(); // Save memory
} else {
  console.error(`Unknown app: ${app}`);
}
