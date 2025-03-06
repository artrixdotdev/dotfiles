import type { Command } from "commander";
import { setupCommand } from "./setup";
import { settingsCommand } from "./settings";

/**
 * Register all commands with the program
 */
export function registerCommands(program: Command): void {
   setupCommand(program);
   settingsCommand(program);
}
