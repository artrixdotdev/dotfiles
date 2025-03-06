import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import inquirer from "inquirer";
import { DEFAULT_SETTINGS } from "../constants";
import type { Settings } from "../types";
import { info, success } from "./logger";

/**
 * Transform camelCase to Words with spaces
 */
function camelCaseToWords(str: string): string {
   // Replace camelCase with spaces and capitalize first letter
   const result = str
      .replace(/([A-Z])/g, " $1")
      .replace(/^./, (str) => str.toUpperCase());
   return result;
}

/**
 * Get the path to the settings file
 */
export function getSettingsPath(): string {
   return join(homedir(), ".settings.json");
}

/**
 * Read settings from JSON file in home directory
 */
export async function readSettingsFile(): Promise<Settings> {
   const settingsPath = getSettingsPath();

   try {
      const file = Bun.file(settingsPath);
      if (await file.exists()) {
         return await file.json();
      }
   } catch (err) {
      info(`Could not read settings file: ${err.message}`);
   }

   return DEFAULT_SETTINGS;
}

/**
 * Write settings to JSON file in home directory
 */
export async function writeSettingsFile(settings: Settings): Promise<void> {
   const settingsPath = getSettingsPath();

   const settingsContent = JSON.stringify(settings, null, 3);

   try {
      await Bun.write(settingsPath, settingsContent);
      success(`Settings file saved to ${settingsPath}`);
   } catch (err) {
      throw new Error(`Failed to write settings file: ${err.message}`);
   }
}

/**
 * Open an interactive prompt to quickly configure settings
 */
export async function quickSettings(): Promise<Settings> {
   // Start with current settings or default if not found
   const settings = await readSettingsFile();

   if (!settings.apps) {
      settings.apps = DEFAULT_SETTINGS.apps;
   }

   info("Configure your application preferences:");

   // Get all app settings
   const apps = Object.entries(settings.apps);

   for (const [name, value] of apps) {
      // Create a more user-friendly label
      const label = camelCaseToWords(name);

      // Prompt for each setting
      const response = await inquirer.prompt([
         {
            type: "input",
            name: "value",
            message: `${label}:`,
            default: value || "",
         },
      ]);

      // Update the setting
      settings.apps[name] = response.value;
   }

   // Save the updated settings
   await writeSettingsFile(settings);

   success("Settings updated successfully!");
   return settings;
}

/**
 * Utility function to get a specific app setting
 */
export async function getAppSetting(
   appName: string,
): Promise<string | undefined> {
   const settings = await readSettingsFile();
   return settings.apps?.[appName];
}
