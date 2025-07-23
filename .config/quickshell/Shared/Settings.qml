pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.platform
import Quickshell
import Quickshell.Io

Singleton {
   id: root

   readonly property string homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)
   readonly property string dotfilesUrl: homeUrl + "/dotfiles"

   FileView {
      id: settingsFile
      path: root.dotfilesUrl + "/settings.json"
      watchChanges: true
      blockLoading: true
   }
   readonly property var settings: JSON.parse(settingsFile.text())
}
