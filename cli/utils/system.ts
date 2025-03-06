import { existsSync, mkdirSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join } from "node:path";
import { PackageSpec } from "../constants";
import { failSpinner, info, startSpinner, succeedSpinner } from "./logger";

/**
 * Check if the current system is running Arch Linux
 */
export async function checkDistribution(): Promise<boolean> {
   try {
      const proc = Bun.spawn(["cat", "/etc/os-release"]);
      const output = await new Response(proc.stdout).text();
      return output.toLowerCase().includes("arch linux");
   } catch (err) {
      return false;
   }
}

/**
 * Check if a package is installed
 */
export async function checkPackageInstalled(
   packageName: string,
): Promise<boolean> {
   try {
      const proc = Bun.spawn(["pacman", "-Q", packageName], {
         stderr: "ignore",
      });
      const exitCode = await proc.exited;
      return exitCode === 0;
   } catch (err) {
      return false;
   }
}

/**
 * Get available AUR helpers
 */
export async function getAurHelperOptions(): Promise<string[]> {
   const helpers = ["paru", "yay"];
   const installed: string[] = [];

   for (const helper of helpers) {
      if (await checkPackageInstalled(helper)) {
         installed.push(helper);
      }
   }

   return installed;
}

/**
 * Execute a command with spinner
 */
export async function execWithSpinner(
   command: string[],
   startMessage: string,
   successMessage: string,
   errorMessage: string,
   options: any = {},
): Promise<string> {
   startSpinner(startMessage);

   try {
      const proc = Bun.spawn(command, {
         ...options,
         stdout: "pipe",
         stderr: "pipe",
      });

      const exitCode = await proc.exited;

      if (exitCode !== 0) {
         const stderr = await new Response(proc.stderr).text();
         failSpinner(errorMessage);
         throw new Error(stderr);
      }

      const stdout = await new Response(proc.stdout).text();
      succeedSpinner(successMessage);
      return stdout;
   } catch (err) {
      failSpinner(errorMessage);
      throw err;
   }
}

/**
 * Execute a shell command with spinner
 */
export async function shellExecWithSpinner(
   commandString: string,
   startMessage: string,
   successMessage: string,
   errorMessage: string,
): Promise<string> {
   startSpinner(startMessage);

   try {
      const proc = Bun.$`${commandString}`;
      const result = await proc;

      if (!result.success) {
         failSpinner(errorMessage);
         throw new Error(result.stderr.toString());
      }

      succeedSpinner(successMessage);
      return result.stdout.toString();
   } catch (err) {
      failSpinner(errorMessage);
      throw err;
   }
}

/**
 * Get potentially conflicting dotfiles
 */
export async function getConflictingDotfiles(
   repoPath: string,
   configDir: string,
): Promise<string[]> {
   const expandedRepoPath = repoPath.replace(/^~/, homedir());
   const expandedConfigDir = configDir.replace(/^~/, homedir());

   if (!existsSync(expandedRepoPath) || !existsSync(expandedConfigDir)) {
      return [];
   }

   try {
      const repoFiles = readdirSync(join(expandedRepoPath), {
         withFileTypes: true,
      })
         // Finds folders with .cfg in them since they are the only ones that will override the dotfiles
         .filter((f) =>
            f.isDirectory()
               ? readdirSync(`${expandedRepoPath}/${f.name}`).includes(".cfg")
               : false,
         )
         .map((f) => f.name);
      const configFiles = readdirSync(expandedConfigDir);

      // Return files/folders that exist in both locations
      return configFiles.filter((file) => repoFiles.includes(file));
   } catch (err) {
      info(`Error checking for conflicting dotfiles: ${err.message}`);
      return [];
   }
}

/**
 * Backup conflicting dotfiles
 */
export async function backupDotfiles(
   conflictingFiles: string[],
   configDir: string,
   backupDir: string,
): Promise<void> {
   const expandedConfigDir = configDir.replace(/^~/, homedir());
   const expandedBackupDir = backupDir.replace(/^~/, homedir());

   // Create backup directory if it doesn't exist
   if (!existsSync(expandedBackupDir)) {
      mkdirSync(expandedBackupDir, { recursive: true });
   }

   for (const file of conflictingFiles) {
      const sourcePath = join(expandedConfigDir, file);
      const destPath = join(expandedBackupDir, file);

      // Create parent directory if it doesn't exist
      const destDir = dirname(destPath);
      if (!existsSync(destDir)) {
         mkdirSync(destDir, { recursive: true });
      }

      await shellExecWithSpinner(
         `cp -r "${sourcePath}" "${destPath}"`,
         `Backing up ${file}...`,
         `Backed up ${file}`,
         `Failed to backup ${file}`,
      );
   }
}
