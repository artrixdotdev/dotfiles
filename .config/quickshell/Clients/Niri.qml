pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
   id: root

   // ========== Enums ==========

   enum Direction {
      Up,
      Down,
      Left,
      Right
   }

   enum LayoutSwitch {
      Next,
      Prev
   }

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
   property var _currentCallback: null

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

   // ========== Core Messaging ==========

   function msg(request: var, callback: var) {
      console.log("Niri request:", JSON.stringify(request));
      if (!root.available) {
         console.error("Niri socket not available");
         if (callback)
            callback({
               error: "Niri socket not available"
            });
         return;
      }

      root._requestQueue.push({
         request,
         callback
      });

      if (!root._socketBusy) {
         root._processNextRequest();
      }
   }

   function _processNextRequest() {
      if (root._requestQueue.length === 0 || root._socketBusy)
         return;

      const {
         request,
         callback
      } = root._requestQueue.shift();
      root._socketBusy = true;
      root._currentCallback = callback;

      if (!requestSocket.connected) {
         requestSocket.connected = true;
      }

      const requestJson = JSON.stringify(request) + "\n";
      requestSocket.write(requestJson);
   }

   function _handleResponse(response: var) {
      root._socketBusy = false;

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

      if (root._requestQueue.length > 0) {
         root._processNextRequest();
      } else {
         requestSocket.connected = false;
      }
   }

   // ========== Helper Functions ==========

   function _parseWorkspaceRef(ref: var, isIndex = false): var {
      let reference = null;
      if (typeof ref === "number") {
         // Could be enum value or index
         // Check if it's a direction enum
         if (ref === Niri.Up || ref === Niri.Down || ref === Niri.Left || ref === Niri.Right) {
            return null; // Handle separately
         }

         if (isIndex) {
            reference = {
               Index: ref
            };
         } else {
            reference = {
               Id: ref
            };
         }
      }
      if (typeof ref === "string") {
         reference = {
            Name: ref
         };
      }

      return {
         reference
      };
   }

   // ========== Workspace Methods ==========

   function toWorkspace(ref: var, callback: var, isIndex = false) {
      if (ref === Niri.Up) {
         msg({
            Action: "FocusWorkspaceUp"
         }, callback);
      } else if (ref === Niri.Down) {
         msg({
            Action: "FocusWorkspaceDown"
         }, callback);
      } else {
         const wsRef = _parseWorkspaceRef(ref, isIndex);
         if (wsRef) {
            msg({
               Action: {
                  FocusWorkspace: wsRef
               }
            }, callback);
         }
      }
   }

   function moveWindowToWorkspace(ref: var, callback: var, isIndex = false) {
      if (ref === Niri.Up) {
         msg({
            Action: "MoveWindowToWorkspaceUp"
         }, callback);
      } else if (ref === Niri.Down) {
         msg({
            Action: "MoveWindowToWorkspaceDown"
         }, callback);
      } else {
         const wsRef = _parseWorkspaceRef(ref, isIndex);
         if (wsRef) {
            msg({
               Action: {
                  MoveWindowToWorkspace: wsRef
               }
            }, callback);
         }
      }
   }

   // ========== Window Methods ==========

   function toWindow(ref: var, callback: var) {
      if (ref === Niri.Up) {
         msg({
            Action: "FocusWindowUp"
         }, callback);
      } else if (ref === Niri.Down) {
         msg({
            Action: "FocusWindowDown"
         }, callback);
      } else if (ref === Niri.Left) {
         msg({
            Action: "FocusWindowLeft"
         }, callback);
      } else if (ref === Niri.Right) {
         msg({
            Action: "FocusWindowRight"
         }, callback);
      } else if (typeof ref === "number") {
         msg({
            Action: {
               FocusWindow: {
                  id: ref
               }
            }
         }, callback);
      }
   }

   function closeWindow(windowId: int, callback: var) {
      msg({
         Action: {
            CloseWindow: {
               id: windowId
            }
         }
      }, callback);
   }

   function moveWindow(direction: int, callback: var) {
      if (direction === Niri.Up) {
         msg({
            Action: "MoveWindowUp"
         }, callback);
      } else if (direction === Niri.Down) {
         msg({
            Action: "MoveWindowDown"
         }, callback);
      } else if (direction === Niri.Left) {
         msg({
            Action: "MoveColumnLeft"
         }, callback);
      } else if (direction === Niri.Right) {
         msg({
            Action: "MoveColumnRight"
         }, callback);
      }
   }

   function moveWindowOrToWorkspace(direction: int, callback: var) {
      if (direction === Niri.Up) {
         msg({
            Action: "MoveWindowUpOrToWorkspaceUp"
         }, callback);
      } else if (direction === Niri.Down) {
         msg({
            Action: "MoveWindowDownOrToWorkspaceDown"
         }, callback);
      }
   }

   function toColumn(direction: int, callback: var) {
      if (direction === Niri.Left) {
         msg({
            Action: "FocusColumnLeft"
         }, callback);
      } else if (direction === Niri.Right) {
         msg({
            Action: "FocusColumnRight"
         }, callback);
      }
   }

   function fullscreenWindow(callback: var) {
      msg({
         Action: "FullscreenWindow"
      }, callback);
   }

   function setWindowHeight(height: string, callback: var) {
      msg({
         Action: {
            SetWindowHeight: height
         }
      }, callback);
   }

   function setColumnWidth(width: string, callback: var) {
      msg({
         Action: {
            SetColumnWidth: width
         }
      }, callback);
   }

   function maximizeColumn(callback: var) {
      msg({
         Action: "MaximizeColumn"
      }, callback);
   }

   // ========== Output/Monitor Methods ==========

   function toOutput(direction: int, callback: var) {
      if (direction === Niri.Up) {
         msg({
            Action: "FocusMonitorUp"
         }, callback);
      } else if (direction === Niri.Down) {
         msg({
            Action: "FocusMonitorDown"
         }, callback);
      } else if (direction === Niri.Left) {
         msg({
            Action: "FocusMonitorLeft"
         }, callback);
      } else if (direction === Niri.Right) {
         msg({
            Action: "FocusMonitorRight"
         }, callback);
      }
   }

   function moveWindowToOutput(direction: int, callback: var) {
      if (direction === Niri.Up) {
         msg({
            Action: "MoveWindowToMonitorUp"
         }, callback);
      } else if (direction === Niri.Down) {
         msg({
            Action: "MoveWindowToMonitorDown"
         }, callback);
      } else if (direction === Niri.Left) {
         msg({
            Action: "MoveWindowToMonitorLeft"
         }, callback);
      } else if (direction === Niri.Right) {
         msg({
            Action: "MoveWindowToMonitorRight"
         }, callback);
      }
   }

   // ========== Keyboard Layout Methods ==========

   function switchLayout(layout: var, callback: var) {
      if (layout === Niri.Next) {
         msg({
            Action: {
               SwitchLayout: "Next"
            }
         }, callback);
      } else if (layout === Niri.Prev) {
         msg({
            Action: {
               SwitchLayout: "Prev"
            }
         }, callback);
      } else if (typeof layout === "number") {
         msg({
            Action: {
               SwitchLayout: {
                  Layout: layout
               }
            }
         }, callback);
      } else if (typeof layout === "string") {
         msg({
            Action: {
               SwitchLayout: {
                  Layout: layout
               }
            }
         }, callback);
      }
   }

   // ========== Query Methods ==========

   function getWorkspaces(callback: var) {
      msg("Workspaces", callback);
   }

   function getWindows(callback: var) {
      msg("Windows", callback);
   }

   function getOutputs(callback: var) {
      msg("Outputs", callback);
   }

   function getFocusedWindow(callback: var) {
      msg("FocusedWindow", callback);
   }

   function getFocusedOutput(callback: var) {
      msg("FocusedOutput", callback);
   }

   function getVersion(callback: var) {
      msg("Version", callback);
   }

   function getKeyboardLayouts(callback: var) {
      msg("KeyboardLayouts", callback);
   }

   // ========== Other Actions ==========

   function screenshot(callback: var) {
      msg({
         Action: "Screenshot"
      }, callback);
   }

   function screenshotScreen(callback: var) {
      msg({
         Action: "ScreenshotScreen"
      }, callback);
   }

   function screenshotWindow(callback: var) {
      msg({
         Action: "ScreenshotWindow"
      }, callback);
   }

   function quit(callback: var) {
      msg({
         Action: {
            Quit: {
               skip_confirmation: true
            }
         }
      }, callback);
   }

   function powerOffMonitors(callback: var) {
      msg({
         Action: "PowerOffMonitors"
      }, callback);
   }

   function spawn(args: var, callback: var) {
      const cmdArray = Array.isArray(args) ? args : [args];
      msg({
         Action: {
            Spawn: cmdArray
         }
      }, callback);
   }

   // ========== Private Event Handler ==========

   function _handleEvent(event: var) {
      if (!event)
         return;

      if (event.WorkspacesChanged !== undefined) {
         const ws = {};
         event.WorkspacesChanged.workspaces.forEach(w => {
            ws[w.id] = w;
         });
         root.workspaces = ws;
      } else if (event.WorkspaceActivated !== undefined) {
         const wa = event.WorkspaceActivated;
         workspaceActivated(wa.id, wa.focused);
      } else if (event.WorkspaceActiveWindowChanged !== undefined)
      // Update internal state if needed
      {} else if (event.WindowsChanged !== undefined) {
         const wins = {};
         event.WindowsChanged.windows.forEach(w => {
            wins[w.id] = w;
         });
         root.windows = wins;
      } else if (event.WindowOpenedOrChanged !== undefined) {
         const window = event.WindowOpenedOrChanged.window;
         windowOpenedOrChanged(window);
      } else if (event.WindowClosed !== undefined) {
         windowClosed(event.WindowClosed.id);
      } else if (event.WindowFocusChanged !== undefined) {
         root.focusedWindow = event.WindowFocusChanged.id;
         windowFocusChanged(event.WindowFocusChanged.id);
      } else if (event.OutputsChanged !== undefined) {
         const outs = {};
         event.OutputsChanged.outputs.forEach(o => {
            outs[o.name] = o;
         });
         root.outputs = outs;
      } else if (event.KeyboardLayoutsChanged !== undefined) {
         keyboardLayoutsChanged(event.KeyboardLayoutsChanged.keyboard_layouts);
      } else if (event.KeyboardLayoutSwitched !== undefined) {
         root.keyboardLayout = event.KeyboardLayoutSwitched.idx.toString();
         keyboardLayoutSwitched(event.KeyboardLayoutSwitched.idx);
      }
   }

   // ========== Initialization ==========

   function populate() {
      getWindows(result => {
         if (result.Windows) {
            root.windows = result.Windows;
            console.log(`Found ${Object.keys(root.windows).length} windows`);
         }
      });
      getWorkspaces(result => {
         if (result.Workspaces) {
            root.workspaces = result.Workspaces;
            console.log(`Found ${Object.keys(root.workspaces).length} workspaces`);
         }
      });
      getOutputs(result => {
         if (result.Outputs) {
            root.outputs = result.Outputs;
            console.log(`Found ${Object.keys(root.outputs).length} outputs`);
         }
      });
   }

   Component.onCompleted: populate()
   onAvailableChanged: populate()
}
