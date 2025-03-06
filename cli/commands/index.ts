import type { Command } from "commander";
import { setupCommand } from "./setup";

/**
 * Register all commands with the program
 */
export function registerCommands(program: Command): void {
   setupCommand(program);
}
