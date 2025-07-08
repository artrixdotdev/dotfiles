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

   // Special case mapping - extend this for specific apps
   const specialCases: Record<string, string> = {
      vesktop: "vesktop",
      "com.mitchellh.ghostty": "Ghostty",
      "dev.zed.Zed-Preview": "Zed",
      zen: "Zen Browser",
   };

   // Check special cases first
   if (specialCases[initialClass]) {
      return specialCases[initialClass];
   }

   // Handle common browser patterns
   if (
      windowClass.includes("-edge") ||
      windowClass.includes("-chrome") ||
      windowClass.includes("-firefox") ||
      windowClass.includes("-brave")
   ) {
      // Transform microsoft-edge
      return windowClass
         .split("-")
         .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
         .join(" ");
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

   // Extract browser name from window title using multiple patterns
   // Pattern 1: content — Browser Name
   const emDashMatch = / — ([^—]+)$/.exec(title);
   if (emDashMatch && emDashMatch[1]) {
      return emDashMatch[1].trim();
   }

   // Pattern 2: content - Profile x - Browser Name (Microsoft Edge style)
   const edgeStyleMatch = /- (?:Profile \d+ - )?(.*?)$/i.exec(title);
   if (
      edgeStyleMatch &&
      edgeStyleMatch[1] &&
      (edgeStyleMatch[1].includes("Edge") ||
         edgeStyleMatch[1].includes("Chrome") ||
         edgeStyleMatch[1].includes("Firefox") ||
         edgeStyleMatch[1].includes("Browser"))
   ) {
      return edgeStyleMatch[1].trim();
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
      // For browser initialTitles that follow "page - browser" pattern
      const browserInitialMatch = /- ([^-]+)$/.exec(initialTitle);
      if (
         browserInitialMatch &&
         browserInitialMatch[1] &&
         (browserInitialMatch[1].includes("Edge") ||
            browserInitialMatch[1].includes("Chrome") ||
            browserInitialMatch[1].includes("Firefox"))
      ) {
         return browserInitialMatch[1].trim();
      }

      return initialTitle;
   }

   // Handle hyphenated class names that weren't caught by earlier rules
   if (windowClass.includes("-")) {
      // For hyphenated app names, convert to Title Case
      return windowClass
         .split("-")
         .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
         .join(" ");
   }

   // Clean up class name for fallback (for electron apps)
   if (windowClass.toLowerCase().includes("electron")) {
      // Try to extract a meaningful name from title
      const appName = title.split(" ")[0];
      if (appName && appName.length > 2 && !appName.includes("@")) {
         return appName;
      }
   }

   // For terminal emulators
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
