import chalk from "chalk";
import type { Command } from "commander";
import inquirer from "inquirer";
import {
   DOTFILES_BACKUP_DIR,
   DOTFILES_INSTALL_DIR,
   DOTFILES_REPO_URL,
   REQUIRED_PACKAGES,
} from "../constants";
import { quickSettings, writeSettingsFile } from "../utils/config";
import {
   cloneDotfilesRepo,
   installAurHelper,
   installRequiredPackages,
   runDotfilesSync,
} from "../utils/installer";
import { error, info, success, warn } from "../utils/logger";
import {
   backupDotfiles,
   checkDistribution,
   getAurHelperOptions,
   getConflictingDotfiles,
} from "../utils/system";

export function setupCommand(program: Command): void {
   program
      .command("setup")
      .description("Set up Artrix dotfiles and dependencies")
      .action(async () => {
         try {
            // Check if running on Arch Linux
            const isArch = await checkDistribution();
            if (!isArch) {
               error(
                  "This script is designed to run exclusively on Arch Linux.",
               );
               process.exit(1);
            }

            // Banner
            info(chalk.bold("Starting Artrix Dots setup..."));

            // Check and install AUR helper
            const aurHelperOptions = await getAurHelperOptions();
            let aurHelper = null;

            if (aurHelperOptions.length === 0) {
               // No AUR helper found, ask user which one to install
               const { helper } = await inquirer.prompt([
                  {
                     type: "list",
                     name: "helper",
                     message:
                        "No AUR helper found. Which one would you like to install?",
                     choices: ["paru", "yay"],
                  },
               ]);

               info(`Installing ${helper}...`);
               await installAurHelper(helper);
               aurHelper = helper;
            } else if (aurHelperOptions.length === 1) {
               // Only one AUR helper found, use that
               aurHelper = aurHelperOptions[0];
               info(`Using existing AUR helper: ${aurHelper}`);
            } else {
               // Multiple AUR helpers found, ask user which one to use
               const { helper } = await inquirer.prompt([
                  {
                     type: "list",
                     name: "helper",
                     message:
                        "Multiple AUR helpers found. Which one would you like to use?",
                     choices: aurHelperOptions,
                  },
               ]);
               aurHelper = helper;
               info(`Using AUR helper: ${aurHelper}`);
            }

            // Install required packages
            info("Checking for required packages...");
            await installRequiredPackages(REQUIRED_PACKAGES, aurHelper);

            // Settings file prompt
            info("Creating settings file...");
            await quickSettings();

            // Check for potentially conflicting dotfiles
            const conflictingFiles = await getConflictingDotfiles(
               DOTFILES_INSTALL_DIR,
               "~/.config",
            );

            // If there are conflicts, ask user if they want to back them up
            if (conflictingFiles.length > 0) {
               info(
                  `Found potentially conflicting dotfiles: ${conflictingFiles.join(", ")}`,
               );

               const { backup } = await inquirer.prompt([
                  {
                     type: "confirm",
                     name: "backup",
                     message:
                        "Do you want to backup your existing dotfiles before proceeding?",
                     default: true,
                  },
               ]);

               if (backup) {
                  await backupDotfiles(
                     conflictingFiles,
                     "~/.config",
                     DOTFILES_BACKUP_DIR,
                  );
                  success(`Dotfiles backed up to ${DOTFILES_BACKUP_DIR}`);
               } else {
                  warn(
                     "Proceeding without backing up existing dotfiles. They may be overwritten.",
                  );
               }
            }

            // Clone dotfiles repository
            await cloneDotfilesRepo(DOTFILES_REPO_URL, DOTFILES_INSTALL_DIR);

            // Run sync script
            await runDotfilesSync(DOTFILES_INSTALL_DIR);

            success("Artrix Dots setup completed successfully!");
            info("Your dotfiles have been installed and configured.");
            info(
               "To get started, log out and log back in to apply all changes.",
            );
         } catch (err) {
            error(`Setup failed: ${(err as Error).message}`);
            process.exit(1);
         }
      });
}
