import { App, Astal, Gtk, Gdk } from "astal/gtk4";
import { bind, Variable } from "astal";
import Hyprland from "gi://AstalHyprland";
const time = Variable("").poll(1000, "date");

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
                        ⦿
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
            <Workspaces />

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
