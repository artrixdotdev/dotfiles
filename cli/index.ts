#!/usr/bin/env bun

import chalk from "chalk";
import { program } from "commander";
import figlet from "figlet";
import { registerCommands } from "./commands";

// Display banner
console.log(
   chalk.cyan(
      figlet.textSync("Artrix Dots", {
         font: "Standard",
         horizontalLayout: "default",
         verticalLayout: "default",
         width: 80,
         whitespaceBreak: true,
      }),
   ),
);

// Set up the program
program
   .name("adots")
   .description("Artrix dotfiles management system")
   .version("1.0.0");

// Register all commands
registerCommands(program);

// Parse command line arguments
program.parse(process.argv);

// If no arguments provided, show help
if (process.argv.length <= 2) {
   program.help();
}
