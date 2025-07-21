import "Clients/Niri.qml" as Niri
import QtQuick
import Quickshell
import Quickshell.Io
import "Shared/Settings.qml" as Settings

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            // we can then set the window's screen to the injected property

            // the screen from the screens list will be injected into this
            // property
            property var client: Niri
            property var settings: Settings
            property var modelData: {
            }

            implicitHeight: 32

            anchors {
                top: true
                right: true
                left: true
            }

            Text {
                id: settingsText

                anchors.centerIn: parent
            }

            Text {
                id: clock

                anchors.centerIn: parent

                Process {
                    id: dateProc

                    command: ["date"]
                    running: true

                    stdout: StdioCollector {
                        onStreamFinished: clock.text = this.text
                    }

                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: () => {
                        dateProc.running = true;
                    }
                }

            }

        }

    }

}
