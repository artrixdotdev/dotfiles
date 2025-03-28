#!/usr/bin/env bun

import { $ } from "bun";

const args = Bun.argv.slice(2);
const HOME = Bun.env.HOME;

const settings: { apps: Record<string, string> } = await Bun.file(
   `${HOME}/.settings.json`,
).json();

if (args.length < 1) {
   console.log("Usage: apps.ts <app>");
   process.exit(1);
}

const app = args[0];
const rest = args.slice(1);

if (settings?.apps && Object.keys(settings.apps).includes(app)) {
   if (settings.apps[app] === null) {
      await $`notify-send "No app set for ${app}"`;
      process.exit(1);
   }
   const [executable, ...extra] = settings.apps[app].split(" ");
   const args = [executable, ...extra, ...rest];
   await $`notify-send "Running ${app}" ${args.join(" ")}`;
   const proc = Bun.spawn(args, {
      stdout: "ignore",
   });

   proc.unref(); // Save memory
} else {
   await $`notify-send "Unknown app: ${app}"`;
}
