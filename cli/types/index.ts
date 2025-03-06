/**
 * Settings file structure
 */
export interface Settings {
   apps: {
      terminal: string;
      terminalExecute: string;
      browser: string;
      chromeBrowser: string;
      fileManager: string;
      chat: string;
      entertainment: string;
      music: string;
      [key: string]: string; // Allow for additional app settings
   };
   [key: string]: string | null; // Allow for additional setting categories
}
