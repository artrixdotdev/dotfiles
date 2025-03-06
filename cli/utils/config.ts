import { homedir } from "node:os";
import { join } from "node:path";
import { success } from "./logger";

/**
 * Write settings to JSON file in home directory
 */
export async function writeSettingsFile(settings: any): Promise<void> {
   const settingsPath = join(homedir(), ".settings.json");
   const settingsContent = JSON.stringify(settings, null, 2);

   try {
      await Bun.write(settingsPath, settingsContent);
      success(`Settings file created at ${settingsPath}`);
   } catch (err) {
      throw new Error(`Failed to write settings file: ${err.message}`);
   }
}
