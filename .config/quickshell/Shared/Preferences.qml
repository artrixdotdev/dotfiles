pragma Singleton
pragma ComponentBehavior: Bound

import Qt.labs.platform
import Quickshell
import Quickshell.Io

Singleton {
   id: root

   readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") + "/settings"

   FileView {
      id: settingsFile
      path: root.configDir + "preferences.json"
      watchChanges: true
      blockLoading: true
      onFileChanged: reload()

      // when changes are made to properties in the adapter, save them
      onAdapterUpdated: writeAdapter()
   }
}
