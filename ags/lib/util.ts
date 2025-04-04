/**
 * Get a consistent, accurate application name from window properties
 */
export function getAppName(windowInfo: {
   initialClass: string;
   initialTitle: string;
   class: string;
   title: string;
}): string {
   const { initialClass, initialTitle, class: windowClass, title } = windowInfo;

   // Special case mapping - extend this for any specific apps that need custom handling
   const specialCases: Record<string, string> = {
      "com.mitchellh.ghostty": "Ghostty",
      "dev.zed.Zed-Preview": "Zed",
      zen: "Zen Browser",
   };

   // Check special cases first
   if (specialCases[initialClass]) {
      return specialCases[initialClass];
   }

   // Process RDN-style class names (com.example.AppName)
   if (/\b[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+){2,}\b/.test(initialClass)) {
      const lastPart = initialClass.split(".").pop() || "";

      // Handle hyphenated names (like Zed-Preview → Zed)
      if (lastPart.includes("-")) {
         const baseName = lastPart.split("-")[0];
         return baseName.charAt(0).toUpperCase() + baseName.slice(1);
      }

      // Return proper-cased last part of RDN
      return lastPart.charAt(0).toUpperCase() + lastPart.slice(1);
   }

   // For browser windows, extract app name from title if available
   const browserAppMatch = / — ([^—]+)$/.exec(title);
   if (
      browserAppMatch &&
      browserAppMatch[1] &&
      (initialClass === "firefox" ||
         initialClass === "chrome" ||
         initialClass === "brave" ||
         initialClass === "zen")
   ) {
      return browserAppMatch[1].trim();
   }

   // Use initialTitle if it's meaningful and not a terminal path/prompt
   if (
      initialTitle &&
      initialTitle.trim() !== "" &&
      !initialTitle.includes("@") &&
      !initialTitle.includes("~") &&
      !initialTitle.includes("/") &&
      !initialTitle.match(/^[A-Za-z0-9_-]+:$/)
   ) {
      return initialTitle;
   }

   // Clean up class name for fallback (for electron apps often have electron in class)
   if (windowClass.toLowerCase().includes("electron")) {
      // Try to extract a meaningful name from title
      const appName = title.split(" ")[0];
      if (appName && appName.length > 2 && !appName.includes("@")) {
         return appName;
      }
   }

   // For regular terminal emulators that aren't covered by special cases
   if (
      windowClass.toLowerCase().includes("term") ||
      windowClass.toLowerCase().includes("konsole") ||
      windowClass.toLowerCase().includes("xterm")
   ) {
      const termMatch = /^([A-Za-z0-9_-]+)/.exec(windowClass);
      if (termMatch && termMatch[1]) {
         return termMatch[1].charAt(0).toUpperCase() + termMatch[1].slice(1);
      }
      return "Terminal";
   }

   // If class starts with uppercase, assume it's already a proper name
   if (windowClass.charAt(0) === windowClass.charAt(0).toUpperCase()) {
      return windowClass;
   }

   // As a fallback, use the class name with first letter capitalized
   // But preserve known lowercase app names
   const lowercaseApps = ["vesktop", "spotify", "discord", "steam"];
   return lowercaseApps.includes(windowClass.toLowerCase())
      ? windowClass.toLowerCase()
      : windowClass.charAt(0).toUpperCase() + windowClass.slice(1);
}
