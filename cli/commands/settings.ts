import type { Command } from "commander";
import chalk from "chalk";
import { log, success, info, error } from "../utils/logger";
import {
   quickSettings,
   readSettingsFile,
   writeSettingsFile,
} from "../utils/config";
import { DEFAULT_SETTINGS } from "../constants";

export function settingsCommand(program: Command): void {
   const settings = program.command("settings").description("Manage settings");

   settings
      .command("edit")
      .description("Interactively edit settings")
      .action(async () => {
         try {
            info(chalk.bold("Artrix Dots Settings Configuration"));
            await quickSettings();
         } catch (err) {
            error(`Settings configuration failed: ${err.message}`);
         }
      });

   settings
      .command("reset")
      .description("Reset settings to default values")
      .action(async () => {
         try {
            await writeSettingsFile(DEFAULT_SETTINGS);
            success("Settings have been reset to default values");
         } catch (err) {
            error(`Settings reset failed: ${err.message}`);
         }
      });

   settings
      .command("show")
      .description("Display current settings")
      .action(async () => {
         try {
            const currentSettings = await readSettingsFile();
            log(chalk.bold("\nCurrent Settings:"));
            log(JSON.stringify(currentSettings, null, 3));
         } catch (err) {
            error(`Could not display settings: ${err.message}`);
         }
      });
}
