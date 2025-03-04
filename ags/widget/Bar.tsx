import { App, Astal, Gtk, type Gdk } from "astal/gtk4";
import { bind, Variable } from "astal";
import Hyprland from "gi://AstalHyprland";
import Tray from "gi://AstalTray";
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
                        ⦿ {ws.name}
                     </button>
                  );
               }),
         )}
      </box>
   );
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
   const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

   return (
      <window
         visible
         cssClasses={["Bar"]}
         gdkmonitor={gdkmonitor}
         exclusivity={Astal.Exclusivity.EXCLUSIVE}
         anchor={TOP | LEFT | RIGHT}
         application={App}
      >
         <centerbox cssName="centerbox">
            <SysTray />
            <Workspaces />
            <DynamicMenu />
            <menubutton hexpand halign={Gtk.Align.CENTER}>
               <label label={time()} />
               <popover>
                  <Gtk.Calendar />
               </popover>
            </menubutton>
         </centerbox>
      </window>
   );
}
