import { App } from "astal/gtk4";
import Hyprland from "gi://AstalHyprland";
import style from "./style.scss";
import Bar from "./widget/Bar";
import Applauncher from "./widget/Launcher";
import Dock from "./widget/Dock";

App.start({
   css: style,
   main() {
      const hyprland = Hyprland.get_default();
      hyprland.get_monitors().map(Bar);
      hyprland.get_monitors().map(Dock);
      Applauncher();
   },

   requestHandler(req: string, res: (response: any) => void) {
      switch (req) {
         case "AppLauncher":
            App.toggle_window("AppLauncher");
            break;
         case "echo2":
            break;
      }
      return res("");
   },
});
