import { existsSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import inquirer from "inquirer";
import { DEFAULT_SETTINGS, type PackageSpec } from "../constants";
import { error, info, success, warn } from "./logger";
import { camelCaseToWords } from "./strings";
import {
   checkPackageInstalled,
   execWithSpinner,
   shellExecWithSpinner,
} from "./system";

/**
 * Install a specific AUR helper
 */
export async function installAurHelper(helperName: string): Promise<void> {
   // Make sure base-devel and git are installed
   await shellExecWithSpinner(
      "sudo pacman -S --needed --noconfirm base-devel git",
      "Installing base dependencies...",
      "Base dependencies installed",
      "Failed to install base dependencies",
   );

   const tmpDir = `/tmp/${helperName}`;

   // Clone the repository
   await shellExecWithSpinner(
      `rm -rf ${tmpDir} && git clone https://aur.archlinux.org/${helperName}.git ${tmpDir}`,
      `Cloning ${helperName} repository...`,
      `${helperName} repository cloned`,
      `Failed to clone ${helperName} repository`,
   );

   // Build and install
   await shellExecWithSpinner(
      `cd ${tmpDir} && makepkg -si --noconfirm`,
      `Building and installing ${helperName}...`,
      `${helperName} installed successfully`,
      `Failed to install ${helperName}`,
   );
}

/**
 * Get package name to use for installation
 */
function getPackageInstallName(pkg: PackageSpec): string {
   if (typeof pkg === "string") {
      return pkg;
   }
   return pkg.installName || pkg.name;
}

/**
 * Get package name for checking if installed
 */
function getPackageName(pkg: PackageSpec): string {
   if (typeof pkg === "string") {
      return pkg;
   }
   return pkg.installName || pkg.name;
}

/**
 * Check if package has custom install script
 */
function hasCustomInstallScript(pkg: PackageSpec): boolean {
   return typeof pkg !== "string" && !!pkg.installScript;
}

/**
 * Get custom install script
 */
function getCustomInstallScript(pkg: PackageSpec): string | undefined {
   return typeof pkg !== "string" ? pkg.installScript : undefined;
}

/**
 * Install required packages checking if they are already installed
 */
export async function installRequiredPackages(
   packages: PackageSpec[],
   aurHelper: string,
): Promise<void> {
   const packagesToInstall: string[] = [];
   const customInstallPackages: PackageSpec[] = [];

   // Check which packages need to be installed
   for (const pkg of packages) {
      const pkgName = getPackageName(pkg);
      const isInstalled = await checkPackageInstalled(pkgName);

      if (!isInstalled) {
         if (hasCustomInstallScript(pkg)) {
            customInstallPackages.push(pkg);
         } else {
            packagesToInstall.push(getPackageInstallName(pkg));
         }
      } else {
         info(`${pkgName} is already installed, skipping...`);
      }
   }

   // Install missing packages using AUR helper
   if (packagesToInstall.length > 0) {
      const packagesStr = packagesToInstall.join(" ");
      await shellExecWithSpinner(
         `${aurHelper} -S --needed --noconfirm ${packagesStr}`,
         `Installing missing packages: ${packagesStr}...`,
         "Packages installed successfully",
         "Failed to install packages",
      );
   }

   // Install packages with custom install scripts
   for (const pkg of customInstallPackages) {
      const pkgName = getPackageName(pkg);
      const installScript = getCustomInstallScript(pkg);

      if (installScript) {
         await shellExecWithSpinner(
            installScript,
            `Installing ${pkgName} with custom script...`,
            `${pkgName} installed successfully`,
            `Failed to install ${pkgName}`,
         );
      }
   }

   if (packagesToInstall.length === 0 && customInstallPackages.length === 0) {
      success("All required packages are already installed");
   }
}

/**
 * Clone and setup dotfiles repository
 */
export async function cloneDotfilesRepo(
   repoUrl: string,
   installDir: string,
): Promise<void> {
   const expandedInstallDir = installDir.replace(/^~/, homedir());

   // Create directory if it doesn't exist
   const parentDir = dirname(expandedInstallDir);
   if (!existsSync(parentDir)) {
      mkdirSync(parentDir, { recursive: true });
   }

   // Clone the repository
   if (!existsSync(expandedInstallDir)) {
      await shellExecWithSpinner(
         `git clone ${repoUrl} ${expandedInstallDir}`,
         "Cloning dotfiles repository...",
         "Dotfiles repository cloned successfully",
         "Failed to clone dotfiles repository",
      );
   } else {
      // Pull the latest changes if the repository already exists
      await shellExecWithSpinner(
         `cd ${expandedInstallDir} && git pull`,
         "Updating existing dotfiles repository...",
         "Dotfiles repository updated successfully",
         "Failed to update dotfiles repository",
      );
   }

   // Make sync script executable
   await shellExecWithSpinner(
      `chmod +x ${expandedInstallDir}/scripts/sync.sh`,
      "Making sync script executable...",
      "Sync script is now executable",
      "Failed to make sync script executable",
   );
}

/**
 * Run the dotfiles sync script
 */
export async function runDotfilesSync(installDir: string): Promise<void> {
   const expandedInstallDir = installDir.replace(/^~/, homedir());

   await shellExecWithSpinner(
      `cd ${expandedInstallDir} && ./scripts/sync.sh`,
      "Syncing dotfiles...",
      "Dotfiles synced successfully",
      "Failed to sync dotfiles",
   );
}

export type Settings = Partial<
   Record<
      "apps" | "colors" | "fonts" | "wallpapers",
      Record<string, string | null>
   >
>;

export async function quickSettings(): Promise<Settings> {
   const settings: Settings = DEFAULT_SETTINGS;
   if (!settings.apps) {
      return;
   }
   const apps = Object.entries(settings.apps ?? {});
   for (const [name, value] of apps) {
      const { value: newValue } = await inquirer.prompt([
         {
            name,
            message: camelCaseToWords(name),
            default: value ?? undefined,
            type: "input",
         },
      ]);

      settings.apps[name] = newValue;
   }

   return settings;
}
