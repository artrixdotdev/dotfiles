/**
 * Required packages type definition
 */
export type PackageSpec =
   | string
   | {
        name: string;
        installName?: string;
        installScript?: string;
        dependencies?: PackageSpec[];
     };

/**
 * Required packages to install
 */
export const REQUIRED_PACKAGES: PackageSpec[] = [
   // Core
   { name: "bun", installName: "bun" },
   "git",
   "neovim",

   // Desktop
   "hyprland",
   "hyprshot",
   "hypridle",
   { name: "ags", installName: "aylurs-gtk-shell" },

   // Terminal tools
   "btop",
   "lazygit", // For neovim config
   "zsh",
   "cava",
   "fastfetch",

   "eza",
   "fzf",
];

export const RECOMMENDED_PACKAGES: PackageSpec[] = [
   // Terminal tools
   "bat",
];
export const OPTIONAL_PACKAGES: PackageSpec[] = [
   // Misc apps
   {
      name: "spotify",
      dependencies: [{ name: "spicetify", installName: "spicetify-cli" }],
   },
];

/**
 * Default settings
 */
export const DEFAULT_SETTINGS = {
   apps: {
      terminal: "ghostty",
      terminalExecute: "ghostty --font-size=14 -e",
      browser: "zen-browser",
      chromeBrowser: "microsoft-edge-dev",
      fileManager: "nautilus",
      chat: "vesktop",
      entertainment: null,
      music: "spotify",
   },
};

/**
 * Dotfiles repository URL
 */
export const DOTFILES_REPO_URL = "https://github.com/artrixdotdev/dotfiles";

/**
 * Dotfiles installation directory
 */
export const DOTFILES_INSTALL_DIR = "~/dotfiles";

/**
 * Dotfiles backup directory
 */
export const DOTFILES_BACKUP_DIR = "~/dotfiles-archive";
