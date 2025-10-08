pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.platform
import Quickshell
import Quickshell.Io

Singleton {
   id: root

   readonly property string homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)
   readonly property string cacheUrl: homeUrl + "/.cache"
   readonly property string themeUrl: cacheUrl + "/theme"

   FileView {
      id: colorsFile
      path: themeUrl + "/colors.json"
      watchChanges: true
      onFileChanged: reload()
      onAdapterUpdated: reload()
      blockLoading: true
   }
   readonly property var colors: JSON.parse(colorsFile.text())
}
