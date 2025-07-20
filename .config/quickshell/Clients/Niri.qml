import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    // --- Workspace State ---
    property list<var> allWorkspaces: []
    property int focusedWorkspaceIndex: 0
    property string focusedWorkspaceId: ""
    property var currentOutputWorkspaces: []
    property string currentOutput: ""

    // --- Window State ---
    property list<var> windows: []
    property int focusedWindowIndex: -1
    property string focusedWindowTitle: "(No active window)"
    property string focusedWindowId: ""

    // --- UI State ---
    property bool inOverview: false

    // --- Feature Availability ---
    property bool niriAvailable: false

    // --- Initialization ---
    Component.onCompleted: {
        console.log("[Niri] Initializing client...")
        checkNiriAvailability()
    }

    // --- Niri Availability Check ---
    Process {
        id: niriCheck
        command: ["which", "niri"]
        onExited: (exitCode) => {
            root.niriAvailable = (exitCode === 0)
            if (root.niriAvailable) {
                console.log("[Niri] niri found, starting event stream and loading initial data")
                eventStreamProcess.running = true
                loadInitialWorkspaceData()
            } else {
                console.log("[Niri] niri not found, workspace features disabled")
            }
        }
    }
    function checkNiriAvailability() {
        niriCheck.running = true
    }

    // --- Initial Workspace Data ---
    Process {
        id: initialDataQuery
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) {
                    try {
                        console.log("[Niri] Loaded initial workspace data")
                        const workspaces = JSON.parse(text.trim())
                        handleWorkspacesChanged({ workspaces })
                    } catch (e) {
                        console.warn("[Niri] Failed to parse initial workspace data:", e)
                    }
                }
            }
        }
    }

    function loadInitialWorkspaceData() {
        console.log("[Niri] Loading initial workspace data...")
        initialDataQuery.running = true
    }

    // --- Event Stream ---
    Process {
        id: eventStreamProcess
        command: ["niri", "msg", "-j", "event-stream"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim())
                    handleNiriEvent(event)
                } catch (e) {
                    console.warn("[Niri] Failed to parse event:", data, e)
                }
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0 && root.niriAvailable) {
                console.warn("[Niri] Event stream exited with code", exitCode, "restarting in 2 seconds")
                restartTimer.start()
            }
        }
    }
    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: {
            if (root.niriAvailable) {
                eventStreamProcess.running = true
            }
        }
    }

    // --- Event Handlers ---
    function handleNiriEvent(event) {
        if (event.WorkspacesChanged) {
            handleWorkspacesChanged(event.WorkspacesChanged)
        } else if (event.WorkspaceActivated) {
            handleWorkspaceActivated(event.WorkspaceActivated)
        } else if (event.WindowsChanged) {
            handleWindowsChanged(event.WindowsChanged)
        } else if (event.WindowClosed) {
            handleWindowClosed(event.WindowClosed)
        } else if (event.WindowFocusChanged) {
            handleWindowFocusChanged(event.WindowFocusChanged)
        } else if (event.OverviewOpenedOrClosed) {
            handleOverviewChanged(event.OverviewOpenedOrClosed)
        }
    }

    function handleWorkspacesChanged(data) {
        allWorkspaces = [...data.workspaces].sort((a, b) => a.idx - b.idx)
        focusedWorkspaceIndex = allWorkspaces.findIndex(w => w.is_focused)
        if (focusedWorkspaceIndex >= 0) {
            let focusedWs = allWorkspaces[focusedWorkspaceIndex]
            focusedWorkspaceId = focusedWs.id
            currentOutput = focusedWs.output || ""
        } else {
            focusedWorkspaceIndex = 0
            focusedWorkspaceId = ""
            currentOutput = ""
        }
        updateCurrentOutputWorkspaces()
    }

    function handleWorkspaceActivated(data) {
        focusedWorkspaceId = data.id
        focusedWorkspaceIndex = allWorkspaces.findIndex(w => w.id === data.id)
        if (focusedWorkspaceIndex < 0) {
            focusedWorkspaceIndex = 0
            return
        }
        let activatedWs = allWorkspaces[focusedWorkspaceIndex]
        // Deactivate all workspaces on this output
        allWorkspaces.forEach(ws => {
            if (ws.output === activatedWs.output) {
                ws.is_active = false
                ws.is_focused = false
            }
        })
        // Activate the new workspace
        activatedWs.is_active = true
        activatedWs.is_focused = data.focused || false
        currentOutput = activatedWs.output || ""
        updateCurrentOutputWorkspaces()
    }

    function handleWindowsChanged(data) {
        windows = [...data.windows].sort((a, b) => a.id - b.id)
        updateFocusedWindow()
    }

    function handleWindowClosed(data) {
        windows = windows.filter(w => w.id !== data.id)
        updateFocusedWindow()
    }

    function handleWindowFocusChanged(data) {
        if (data.id) {
            focusedWindowId = data.id
            focusedWindowIndex = windows.findIndex(w => w.id === data.id)
        } else {
            focusedWindowId = ""
            focusedWindowIndex = -1
        }
        updateFocusedWindow()
    }

    function handleOverviewChanged(data) {
        inOverview = !!data.is_open
    }

    // --- Workspace/Window Helpers ---
    function updateCurrentOutputWorkspaces() {
        currentOutputWorkspaces = currentOutput
            ? allWorkspaces.filter(w => w.output === currentOutput)
            : allWorkspaces
    }

    function updateFocusedWindow() {
        if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.length) {
            let focusedWin = windows[focusedWindowIndex]
            focusedWindowTitle = focusedWin.title || "(Unnamed window)"
        } else {
            focusedWindowTitle = "(No active window)"
        }
    }

    // --- Public API ---
    function switchToWorkspace(workspaceId) {
        if (!niriAvailable) return false
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspaceId.toString()])
        return true
    }

    function switchToWorkspaceByIndex(index) {
        if (!niriAvailable || index < 0 || index >= allWorkspaces.length) return false
        return switchToWorkspace(allWorkspaces[index].id)
    }

    function switchToWorkspaceByNumber(number, output) {
        if (!niriAvailable) return false
        let targetOutput = output || currentOutput
        if (!targetOutput) {
            console.warn("[Niri] No output specified for workspace switching")
            return false
        }
        let outputWorkspaces = allWorkspaces.filter(w => w.output === targetOutput).sort((a, b) => a.idx - b.idx)
        if (number >= 1 && number <= outputWorkspaces.length) {
            return switchToWorkspace(outputWorkspaces[number - 1].id)
        }
        console.warn("[Niri] No workspace", number, "found on output", targetOutput)
        return false
    }

    function getWorkspaceByIndex(index ) {
        return (index >= 0 && index < allWorkspaces.length) ? allWorkspaces[index] : null
    }

    function getCurrentOutputWorkspaceNumbers() {
        return currentOutputWorkspaces.map(w => w.idx + 1)
    }

    function getCurrentWorkspaceNumber() {
        return (focusedWorkspaceIndex >= 0 && focusedWorkspaceIndex < allWorkspaces.length)
            ? allWorkspaces[focusedWorkspaceIndex].idx + 1
            : 1
    }

    function isWorkspaceActive(workspaceNumber) {
        return workspaceNumber === getCurrentWorkspaceNumber()
    }
}
