pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
   id: root

   // ========== Properties ==========

   readonly property string socketPath: Quickshell.env("NIRI_SOCKET") ?? ""
   readonly property bool available: socketPath !== ""

   // Event stream state
   readonly property bool eventStreamActive: eventStreamProcess.running
   property var workspaces: ({})
   property var windows: ({})
   property var outputs: ({})
   property var focusedWindow: null
   property var focusedOutput: null
   property string keyboardLayout: ""

   // ========== Signals ==========

   signal windowOpenedOrChanged(window: var)
   signal windowClosed(id: int)
   signal windowFocusChanged(id: var)
   signal workspaceActivated(id: int, focused: bool)
   signal keyboardLayoutsChanged(layouts: var)
   signal keyboardLayoutSwitched(idx: int)

   // ========== Private Properties ==========

   property var _requestQueue: []
   property bool _socketBusy: false

   // ========== Event Stream Process ==========

   Process {
      id: eventStreamProcess
      running: root.available
      command: ["niri", "msg", "--json", "event-stream"]

      stdout: SplitParser {
         splitMarker: "\n"

         onRead: data => {
            try {
               const event = JSON.parse(data);
               root._handleEvent(event);
            } catch (e) {
               console.error("Failed to parse niri event:", e, "Data:", data);
            }
         }
      }

      stderr: SplitParser {
         splitMarker: "\n"
         onRead: data => console.error("Niri event stream error:", data)
      }

      onExited: (exitCode, exitStatus) => {
         console.warn("Niri event stream exited with code:", exitCode);
      }
   }

   // ========== Request Socket ==========

   Socket {
      id: requestSocket
      path: root.socketPath

      parser: SplitParser {
         splitMarker: "\n"

         onRead: data => {
            try {
               const response = JSON.parse(data);
               root._handleResponse(response);
            } catch (e) {
               console.error("Failed to parse niri response:", e, "Data:", data);
               root._handleResponse({
                  Err: "Parse error: " + e
               });
            }
         }
      }

      onConnectedChanged: {
         if (connected && root._requestQueue.length > 0) {
            root._processNextRequest();
         }
      }
   }

   // ========== Public Methods ==========

   function msg(command: var, callback: var) {
      if (!root.available) {
         console.error("Niri socket not available");
         if (callback)
            callback({
               Err: "Niri socket not available"
            });
         return;
      }

      // Convert command to request object
      let request;

      if (Array.isArray(command)) {
         const cmd = command[0];
         const args = command.slice(1);

         // Parse common commands
         if (cmd === "action") {
            const actionName = args[0];
            const actionArgs = args.slice(1);

            // Map action names to Request format
            request = root._buildActionRequest(actionName, actionArgs);
         } else if (cmd === "workspaces") {
            request = "Workspaces";
         } else if (cmd === "windows") {
            request = "Windows";
         } else if (cmd === "outputs") {
            request = "Outputs";
         } else if (cmd === "focused-window") {
            request = "FocusedWindow";
         } else if (cmd === "focused-output") {
            request = "FocusedOutput";
         } else if (cmd === "version") {
            request = "Version";
         } else if (cmd === "keyboard-layouts") {
            request = "KeyboardLayouts";
         }
      } else if (typeof command === "string") {
         request = command;
      } else {
         request = command;
      }

      // Queue the request
      root._requestQueue.push({
         request,
         callback
      });

      // Process if not busy
      if (!root._socketBusy) {
         root._processNextRequest();
      }
   }

   function _buildActionRequest(actionName: string, args: var): var {
      // Convert action name to proper format
      const actionMap = {
         "focus-workspace": data => ({
                  Action: {
                     FocusWorkspace: JSON.parse(data)
                  }
               }),
         "focus-workspace-down": () => ({
                  Action: "FocusWorkspaceDown"
               }),
         "focus-workspace-up": () => ({
                  Action: "FocusWorkspaceUp"
               }),
         "move-window-to-workspace": data => ({
                  Action: {
                     MoveWindowToWorkspace: JSON.parse(data)
                  }
               }),
         "move-window-to-workspace-down": () => ({
                  Action: "MoveWindowToWorkspaceDown"
               }),
         "move-window-to-workspace-up": () => ({
                  Action: "MoveWindowToWorkspaceUp"
               }),
         "focus-window": () => ({
                  Action: {
                     FocusWindow: {
                        id: parseInt(args[1])
                     }
                  }
               }),
         "close-window": () => ({
                  Action: {
                     CloseWindow: {
                        id: parseInt(args[1])
                     }
                  }
               }),
         "focus-window-down": () => ({
                  Action: "FocusWindowDown"
               }),
         "focus-window-up": () => ({
                  Action: "FocusWindowUp"
               }),
         "focus-window-left": () => ({
                  Action: "FocusWindowLeft"
               }),
         "focus-window-right": () => ({
                  Action: "FocusWindowRight"
               }),
         "focus-column-left": () => ({
                  Action: "FocusColumnLeft"
               }),
         "focus-column-right": () => ({
                  Action: "FocusColumnRight"
               }),
         "move-column-left": () => ({
                  Action: "MoveColumnLeft"
               }),
         "move-column-right": () => ({
                  Action: "MoveColumnRight"
               }),
         "move-window-down": () => ({
                  Action: "MoveWindowDown"
               }),
         "move-window-up": () => ({
                  Action: "MoveWindowUp"
               }),
         "move-window-down-or-to-workspace-down": () => ({
                  Action: "MoveWindowDownOrToWorkspaceDown"
               }),
         "move-window-up-or-to-workspace-up": () => ({
                  Action: "MoveWindowUpOrToWorkspaceUp"
               }),
         "fullscreen-window": () => ({
                  Action: "FullscreenWindow"
               }),
         "set-window-height": () => ({
                  Action: {
                     SetWindowHeight: args[0]
                  }
               }),
         "set-column-width": () => ({
                  Action: {
                     SetColumnWidth: args[0]
                  }
               }),
         "maximize-column": () => ({
                  Action: "MaximizeColumn"
               }),
         "focus-monitor-down": () => ({
                  Action: "FocusMonitorDown"
               }),
         "focus-monitor-up": () => ({
                  Action: "FocusMonitorUp"
               }),
         "focus-monitor-left": () => ({
                  Action: "FocusMonitorLeft"
               }),
         "focus-monitor-right": () => ({
                  Action: "FocusMonitorRight"
               }),
         "move-window-to-monitor-down": () => ({
                  Action: "MoveWindowToMonitorDown"
               }),
         "move-window-to-monitor-up": () => ({
                  Action: "MoveWindowToMonitorUp"
               }),
         "move-window-to-monitor-left": () => ({
                  Action: "MoveWindowToMonitorLeft"
               }),
         "move-window-to-monitor-right": () => ({
                  Action: "MoveWindowToMonitorRight"
               }),
         "switch-layout": () => {
            if (args[0] === "next")
               return {
                  Action: {
                     SwitchLayout: "Next"
                  }
               };
            if (args[0] === "prev")
               return {
                  Action: {
                     SwitchLayout: "Prev"
                  }
               };
            return {
               Action: {
                  SwitchLayout: {
                     Layout: parseInt(args[1])
                  }
               }
            };
         },
         "screenshot": () => ({
                  Action: "Screenshot"
               }),
         "screenshot-screen": () => ({
                  Action: "ScreenshotScreen"
               }),
         "screenshot-window": () => ({
                  Action: "ScreenshotWindow"
               }),
         "quit": () => ({
                  Action: {
                     Quit: {
                        skip_confirmation: true
                     }
                  }
               }),
         "power-off-monitors": () => ({
                  Action: "PowerOffMonitors"
               }),
         "spawn": () => ({
                  Action: {
                     Spawn: args
                  }
               })
      };

      const builder = actionMap[actionName];
      if (builder) {
         return builder(args[0]);
      }

      console.error("Unknown action:", actionName);
      return {
         Action: actionName
      };
   }

   function _processNextRequest() {
      if (root._requestQueue.length === 0 || root._socketBusy) {
         return;
      }

      const {
         request,
         callback
      } = root._requestQueue.shift();
      root._socketBusy = true;
      root._currentCallback = callback;

      // Connect if not connected
      if (!requestSocket.connected) {
         requestSocket.connected = true;
      }

      // Send request as JSON + newline
      const requestJson = JSON.stringify(request) + "\n";
      requestSocket.write(requestJson);
   }

   function _handleResponse(response: var) {
      root._socketBusy = false;

      // Call the callback with unwrapped response
      if (root._currentCallback) {
         if (response.Ok !== undefined) {
            root._currentCallback(response.Ok);
         } else if (response.Err !== undefined) {
            console.error("Niri error:", response.Err);
            root._currentCallback({
               error: response.Err
            });
         } else {
            root._currentCallback(response);
         }
         root._currentCallback = null;
      }

      // Process next request in queue
      if (root._requestQueue.length > 0) {
         root._processNextRequest();
      } else {
         // Disconnect after processing all requests
         requestSocket.connected = false;
      }
   }

   property var _currentCallback: null

   // ========== Workspace Methods ==========

   function focusWorkspace(reference: var) {
      msg(["action", "focus-workspace", JSON.stringify({
            reference
         })]);
   }

   function focusWorkspaceByIndex(index: int) {
      focusWorkspace({
         Index: index
      });
   }

   function focusWorkspaceById(id: int) {
      focusWorkspace({
         Id: id
      });
   }

   function focusWorkspaceByName(name: string) {
      focusWorkspace({
         Name: name
      });
   }

   function focusWorkspaceDown() {
      msg(["action", "focus-workspace-down"]);
   }

   function focusWorkspaceUp() {
      msg(["action", "focus-workspace-up"]);
   }

   function moveToWorkspace(reference: var) {
      msg(["action", "move-window-to-workspace", JSON.stringify({
            reference
         })]);
   }

   function moveToWorkspaceByIndex(index: int) {
      moveToWorkspace({
         Index: index
      });
   }

   function moveToWorkspaceById(id: int) {
      moveToWorkspace({
         Id: id
      });
   }

   function moveToWorkspaceByName(name: string) {
      moveToWorkspace({
         Name: name
      });
   }

   function moveToWorkspaceDown() {
      msg(["action", "move-window-to-workspace-down"]);
   }

   function moveToWorkspaceUp() {
      msg(["action", "move-window-to-workspace-up"]);
   }

   // ========== Window Methods ==========

   function focusWindow(windowId: int) {
      msg(["action", "focus-window", "--id", windowId.toString()]);
   }

   function closeWindow(windowId: int) {
      msg(["action", "close-window", "--id", windowId.toString()]);
   }

   function focusWindowDown() {
      msg(["action", "focus-window-down"]);
   }

   function focusWindowUp() {
      msg(["action", "focus-window-up"]);
   }

   function focusWindowLeft() {
      msg(["action", "focus-window-left"]);
   }

   function focusWindowRight() {
      msg(["action", "focus-window-right"]);
   }

   function focusColumnLeft() {
      msg(["action", "focus-column-left"]);
   }

   function focusColumnRight() {
      msg(["action", "focus-column-right"]);
   }

   function moveColumnLeft() {
      msg(["action", "move-column-left"]);
   }

   function moveColumnRight() {
      msg(["action", "move-column-right"]);
   }

   function moveWindowDown() {
      msg(["action", "move-window-down"]);
   }

   function moveWindowUp() {
      msg(["action", "move-window-up"]);
   }

   function moveWindowDownOrToWorkspaceDown() {
      msg(["action", "move-window-down-or-to-workspace-down"]);
   }

   function moveWindowUpOrToWorkspaceUp() {
      msg(["action", "move-window-up-or-to-workspace-up"]);
   }

   function fullscreenWindow() {
      msg(["action", "fullscreen-window"]);
   }

   function setWindowHeight(height: string) {
      msg(["action", "set-window-height", height]);
   }

   function setColumnWidth(width: string) {
      msg(["action", "set-column-width", width]);
   }

   function maximizeColumn() {
      msg(["action", "maximize-column"]);
   }

   // ========== Output Methods ==========

   function focusOutputDown() {
      msg(["action", "focus-monitor-down"]);
   }

   function focusOutputUp() {
      msg(["action", "focus-monitor-up"]);
   }

   function focusOutputLeft() {
      msg(["action", "focus-monitor-left"]);
   }

   function focusOutputRight() {
      msg(["action", "focus-monitor-right"]);
   }

   function moveWindowToOutputDown() {
      msg(["action", "move-window-to-monitor-down"]);
   }

   function moveWindowToOutputUp() {
      msg(["action", "move-window-to-monitor-up"]);
   }

   function moveWindowToOutputLeft() {
      msg(["action", "move-window-to-monitor-left"]);
   }

   function moveWindowToOutputRight() {
      msg(["action", "move-window-to-monitor-right"]);
   }

   // ========== Query Methods ==========

   function queryWorkspaces(callback: var) {
      msg(["workspaces"], callback);
   }

   function queryWindows(callback: var) {
      msg(["windows"], callback);
   }

   function queryOutputs(callback: var) {
      msg(["outputs"], callback);
   }

   function queryFocusedWindow(callback: var) {
      msg(["focused-window"], callback);
   }

   function queryFocusedOutput(callback: var) {
      msg(["focused-output"], callback);
   }

   function queryVersion(callback: var) {
      msg(["version"], callback);
   }

   function queryKeyboardLayouts(callback: var) {
      msg(["keyboard-layouts"], callback);
   }

   // ========== Keyboard Methods ==========

   function switchKeyboardLayout(layout: var) {
      if (typeof layout === "number") {
         msg(["action", "switch-layout", "--layout", layout.toString()]);
      } else {
         msg(["action", "switch-layout", "--layout", layout]);
      }
   }

   function switchKeyboardLayoutNext() {
      msg(["action", "switch-layout", "next"]);
   }

   function switchKeyboardLayoutPrev() {
      msg(["action", "switch-layout", "prev"]);
   }

   // ========== Other Actions ==========

   function screenshot() {
      msg(["action", "screenshot"]);
   }

   function screenshotScreen() {
      msg(["action", "screenshot-screen"]);
   }

   function screenshotWindow() {
      msg(["action", "screenshot-window"]);
   }

   function quit() {
      msg(["action", "quit", "--skip-confirmation"]);
   }

   function powerOffMonitors() {
      msg(["action", "power-off-monitors"]);
   }

   function spawn(args) {
      msg(["action", "spawn", ...args]);
   }

   // ========== Private Event Handler ==========

   function _handleEvent(event: var) {
      if (!event)
         return;

      // WorkspacesChanged
      if (event.WorkspacesChanged !== undefined) {
         const ws = {};
         event.WorkspacesChanged.workspaces.forEach(w => {
            ws[w.id] = w;
         });
         root.workspaces = ws;
      } else

      // WorkspaceActivated
      if (event.WorkspaceActivated !== undefined) {
         const wa = event.WorkspaceActivated;
         workspaceActivated(wa.id, wa.focused);
      } else

      // WorkspaceActiveWindowChanged
      if (event.WorkspaceActiveWindowChanged !== undefined) {} else

      // WindowsChanged
      if (event.WindowsChanged !== undefined) {
         const wins = {};
         event.WindowsChanged.windows.forEach(w => {
            wins[w.id] = w;
         });
         root.windows = wins;
      } else

      // WindowOpenedOrChanged
      if (event.WindowOpenedOrChanged !== undefined) {
         const window = event.WindowOpenedOrChanged.window;
         windowOpenedOrChanged(window);
      } else

      // WindowClosed
      if (event.WindowClosed !== undefined) {
         windowClosed(event.WindowClosed.id);
      } else

      // WindowFocusChanged
      if (event.WindowFocusChanged !== undefined) {
         root.focusedWindow = event.WindowFocusChanged.id;
         windowFocusChanged(event.WindowFocusChanged.id);
      } else

      // OutputsChanged
      if (event.OutputsChanged !== undefined) {
         const outs = {};
         event.OutputsChanged.outputs.forEach(o => {
            outs[o.name] = o;
         });
         root.outputs = outs;
      } else

      // KeyboardLayoutsChanged
      if (event.KeyboardLayoutsChanged !== undefined) {
         keyboardLayoutsChanged(event.KeyboardLayoutsChanged.keyboard_layouts);
      } else

      // KeyboardLayoutSwitched
      if (event.KeyboardLayoutSwitched !== undefined) {
         root.keyboardLayout = event.KeyboardLayoutSwitched.idx.toString();
         keyboardLayoutSwitched(event.KeyboardLayoutSwitched.idx);
      }
   }

   // ========== Initialization ==========

   function populate() {
      root.queryWindows(result => {
         if (result.Windows)
            root.windows = result.Windows;
         console.log(`Found ${Object.keys(root.windows).length} windows`);
      });
      root.queryWorkspaces(result => {
         if (result.Workspaces)
            root.workspaces = result.Workspaces;
         console.log(`Found ${Object.keys(root.workspaces).length} workspaces`);
      });
      root.queryOutputs(result => {
         if (result.Outputs)
            root.outputs = result.Outputs;
         console.log(`Found ${Object.keys(root.outputs).length} outputs`);
      });
   }

   Component.onCompleted: populate()
   onAvailableChanged: populate()
}
