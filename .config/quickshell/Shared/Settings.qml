pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.platform
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
   id: root

   readonly property string homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)
   readonly property string configUrl: homeUrl + "/.config"
   readonly property string dotfilesUrl: homeUrl + "/dotfiles"

   FileView {
      id: settingsFile
      path: dotfilesUrl + "/settings.json"
      watchChanges: true
      blockLoading: true
   }
   readonly property var settings: JSON.parse(settingsFile.text())
}
