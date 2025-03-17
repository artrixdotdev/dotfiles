import Hyprland from "gi://AstalHyprland";
import Tray from "gi://AstalTray";
import { Variable, bind } from "astal";
import { App, Astal, type Gdk, Gtk } from "astal/gtk4";
const time = Variable("").poll(1000, "date");

function SysTray() {
   const tray = Tray.get_default();

   return (
      <box>
         {bind(tray, "items").as((items) =>
            items.map((item) => (
               <menubutton
                  tooltipMarkup={bind(item, "tooltipMarkup")}
                  usePopover={false}
                  actionGroup={bind(item, "actionGroup").as((ag) => [
                     "dbusmenu",
                     ag,
                  ])}
                  menuModel={bind(item, "menuModel")}
               >
                  <image iconName={bind(item, "iconName")} />
               </menubutton>
            )),
         )}
      </box>
   );
}

function DynamicMenu() {
   const hyprland = Hyprland.get_default();
   const focused = bind(hyprland, "focusedClient");

   return (
      <box className="Focused" visible={focused.as(Boolean)}>
         {focused.as(
            (client) =>
               client && (
                  <label
                     label={bind(client, "title").as((s) => s.split(" — ")[0])}
                  />
               ),
         )}
      </box>
   );
}

function Workspaces() {
   const hyprland = Hyprland.get_default();

   return (
      <box>
         {bind(hyprland, "workspaces").as((ws) =>
            ws
               .filter((w) => !(w.id >= -99 && w.id <= -2)) // filter out special workspaces
               .sort((a, b) => a.id - b.id)
               .map((ws) => {
                  return (
                     <button name={ws.name} onClicked={() => ws.focus()}>
                        <centerbox>{ws.name}</centerbox>
                     </button>
                  );
               }),
         )}
      </box>
   );
}

export default function Bar(monitor: Hyprland.Monitor) {
   const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

   return (
      <window
         visible
         cssClasses={["Bar"]}
         monitor={monitor.id}
         exclusivity={Astal.Exclusivity.EXCLUSIVE}
         anchor={TOP | LEFT | RIGHT}
         application={App}
      >
         <centerbox cssName="centerbox">
            <Workspaces />
            <DynamicMenu />
            <menubutton hexpand>
               <label label={time()} />
               <popover>
                  <Gtk.Calendar />
               </popover>
            </menubutton>
         </centerbox>
      </window>
   );
}
