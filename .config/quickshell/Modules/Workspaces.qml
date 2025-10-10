import QtQuick
import Quickshell
import qs.Clients
import qs.Shared
import qs.Components

PanelWindow {
   id: workspaces
   implicitWidth: Settings.settings.sizing.base * 4

   color: Theme.colors.background

   Connections {
      target: Niri
      function onWindowFocusChanged(id) {
         console.log("Workspaces changed:", JSON.stringify(id));
      }
   }

   anchors {
      left: true
      bottom: true
      top: true
   }
   Column {
      anchors.fill: parent

      Repeater {
         model: Object.entries(Niri.workspaces)

         delegate: BetterButton {
            property string workspaceId: modelData[0]
            property var workspace: modelData[1]
            property string name: workspace.name || workspace.idx
            onClicked: () => {
               console.log("Switching to workspace:", JSON.stringify(Niri.workspaces));
               Niri.toWorkspace(workspace.idx, true);
            }
            text: name
         }
      }
   }
}
