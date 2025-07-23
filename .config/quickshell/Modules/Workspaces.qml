import QtQuick
import Quickshell
import qs.Clients
import qs.Shared

PanelWindow {
   id: workspacePanel

   anchors {
      left: true
      bottom: true
      top: true
   }

   width: Settings.settings.sizing.base * 4

   color: "transparent"

   Rectangle {
      anchors.fill: parent
      color: Theme.colors.background

      Row {
         id: workspaceRow
         anchors {
            top: parent.top
            verticalCenter: parent.verticalCenter
         }
         spacing: 8

         Repeater {
            model: Niri.currentOutputWorkspaces

            Rectangle {
               id: workspaceButton

               property var workspace: modelData
               property bool isActive: workspace ? workspace.is_active : false
               property bool isFocused: workspace ? workspace.is_focused : false
               property int workspaceNumber: workspace ? workspace.idx + 1 : 0

               width: 32
               height: 24
               radius: 4

               color: {
                  if (isFocused)
                     return "#cba6f7";
                  if (isActive)
                     return "#89b4fa";
                  if (workspace && workspace.windows && workspace.windows.length > 0)
                     return "#f38ba8";
                  return "#45475a";
               }

               Text {
                  anchors.centerIn: parent
                  text: workspaceNumber
                  color: {
                     if (isFocused || isActive)
                        return "#1e1e2e";
                     return "#cdd6f4";
                  }
                  font.pointSize: 10
                  font.bold: isFocused
               }

               MouseArea {
                  anchors.fill: parent
                  onClicked: {
                     if (workspace) {
                        Niri.switchToWorkspace(workspace.id);
                     }
                  }

                  hoverEnabled: true
                  onEntered: parent.color = Qt.lighter(parent.color, 1.2)
                  onExited: parent.color = Qt.binding(() => {
                     if (isFocused)
                        return "#cba6f7";
                     if (isActive)
                        return "#89b4fa";
                     if (workspace && workspace.windows && workspace.windows.length > 0)
                        return "#f38ba8";
                     return "#45475a";
                  })
               }

               //                // Tooltip for workspace info
               //                ToolTip {
               //                   visible: parent.MouseArea.containsMouse
               //                   text: workspace ? `Workspace ${workspaceNumber}${workspace.name ? ` (${workspace.name})` : ""}
               // Windows: ${workspace.windows ? workspace.windows.length : 0}` : ""
               //                   delay: 500
               //                }
            }
         }
      }

      // Current window title
      Text {
         anchors {
            left: workspaceRow.right
            leftMargin: 24
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 12
         }

         text: Niri.focusedWindowTitle
         color: "#cdd6f4"
         font.pointSize: 9
         elide: Text.ElideRight
         opacity: Niri.focusedWindowTitle !== "(No active window)" ? 1.0 : 0.6
      }

      // Overview indicator
      Rectangle {
         anchors {
            right: parent.right
            rightMargin: 8
            verticalCenter: parent.verticalCenter
         }

         visible: Niri.inOverview
         width: 8
         height: 8
         radius: 4
         color: "#fab387"

         SequentialAnimation {
            running: Niri.inOverview
            loops: Animation.Infinite

            PropertyAnimation {
               target: parent
               property: "opacity"
               to: 0.3
               duration: 800
            }
            PropertyAnimation {
               target: parent
               property: "opacity"
               to: 1.0
               duration: 800
            }
         }
      }
   }
}
