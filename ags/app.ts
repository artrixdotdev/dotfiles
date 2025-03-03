import { App } from "astal/gtk4";
import style from "./style.scss";
import Bar from "./widget/Bar";
import Applauncher from "./widget/Launcher";

App.start({
   css: style,
   main() {
      App.get_monitors().map(Bar);
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
