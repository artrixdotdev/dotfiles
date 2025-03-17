import Apps from "gi://AstalApps";
import Hyprland from "gi://AstalHyprland";
import { Variable, bind } from "astal";
import { App, Astal, Gdk, Gtk, hook } from "astal/gtk4";

export default function Applauncher() {
   const hyprland = Hyprland.get_default();
   const apps = new Apps.Apps({
      nameMultiplier: 2,
      entryMultiplier: 0,
      executableMultiplier: 2,
   });
   const appList = apps.fuzzy_query("");

   function AppButton({ app }: { app: Apps.Application }): JSX.Element {
      //print(app);
      return (
         <box
            cssClasses={["appbutton"]}
            tooltipText={app.name}
            name={app.name}
            onButtonPressed={(self) => {
               app.launch();
               App.toggle_window("AppLauncher");
               self.set_state_flags(Gtk.StateFlags.NORMAL, true);
               entry.grab_focus();
            }}
         >
            <image pixelSize={64} iconName={app.get_icon_name() || ""} />
         </box>
      );
   }

   const appButtons = appList.map((app) => <AppButton app={app} />);
   let first_visible_child: Gtk.Widget | undefined;

   function filterList(text: string) {
      for (const appButton of appButtons) {
         const appName = appButton.name.toLowerCase();
         const isVisible = appName.includes(text.toLowerCase());
         appButton.set_visible(isVisible);
         appButton.set_state_flags(Gtk.StateFlags.NORMAL, true);
      }
   }

   const entry = (
      <entry
         placeholderText={"ctrl+tab to select"}
         onChanged={(self) => {
            const app_name = self.get_text();
            filterList(app_name);
            if (!app_name) return;
            // Select the first visible child
            first_visible_child = appButtons.find(
               (appButton) => appButton.visible,
            );
            first_visible_child?.set_state_flags(Gtk.StateFlags.SELECTED, true);
         }}
         onKeyModifier={() => print("thing")}
         onButtonPressed={(self) => {
            first_visible_child?.activate();
            self.text = "";
         }}
      />
   );

   return (
      <window
         exclusivity={Astal.Exclusivity.EXCLUSIVE}
         keymode={Astal.Keymode.EXCLUSIVE}
         name={"AppLauncher"}
         application={App}
         defaultWidth={600}
         defaultHeight={400}
         monitor={bind(hyprland, "focused_monitor").as((monitor) => monitor.id)}
         onKeyPressed={(self, keyval) =>
            keyval === Gdk.KEY_Escape && self.hide()
         }
         setup={(self) =>
            hook(entry, self, "notify::visible", () => entry.grab_focus())
         }
      >
         <box
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            vertical={true}
         >
            {entry}
            <box vertical={true}>{appButtons}</box>
         </box>
      </window>
   );
}
