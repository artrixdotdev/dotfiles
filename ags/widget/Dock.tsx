import { App, Astal, Gtk, type Gdk } from "astal/gtk4";
import Hyprland from "gi://AstalHyprland";
import Apps from "gi://AstalApps";
import { bind, derive } from "astal";

// E.G com.mitchellh.ghostty
const isRDN = (s: string) => /\b[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+){2,}\b/.test(s);

function AppButton({
   app,
   client,
   focused = false,
}: { app: Apps.Application; client: Hyprland.Client; focused?: boolean }) {
   return (
      <box onButtonPressed={() => client.focus()} name={app.name}>
         <image
            iconName={app.get_icon_name()}
            pixelSize={48}
            valign={Gtk.Align.CENTER}
         />
      </box>
   );
}

export default function Dock(monitor: Hyprland.Monitor) {
   const { BOTTOM } = Astal.WindowAnchor;
   const hyprland = Hyprland.get_default();
   const apps = new Apps.Apps({
      nameMultiplier: 2,
      entryMultiplier: 0,
      executableMultiplier: 2,
   });

   const workspace = bind(monitor, "activeWorkspace");
   const focusedClient = bind(hyprland, "focusedClient").as((c) => c.address);

   return (
      <window
         anchor={BOTTOM}
         monitor={monitor.id}
         visible
         cssClasses={["Dock"]}
         name={"Dock"}
         keymode={Astal.Keymode.NONE}
         valign={Gtk.Align.CENTER} //
         vexpand
         exclusivity={Astal.Exclusivity.IGNORE}
         application={App}
      >
         {workspace.as((ws) => (
            <box>
               {bind(ws, "clients").as((clients) => (
                  <box>
                     {clients.map((c) => {
                        const title = isRDN(c.initialClass)
                           ? c.initialClass.split(".").pop()
                           : c.initialTitle || c.initialClass;
                        const app = apps.fuzzy_query(title)[0];
                        print(monitor.id, title);

                        return app ? (
                           <AppButton
                              app={app}
                              focused={c.address === focusedClient.get()}
                              client={c}
                           />
                        ) : null;
                     })}
                  </box>
               ))}
            </box>
         ))}
      </window>
   );
}
