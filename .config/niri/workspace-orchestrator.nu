#!/usr/bin/env nu

const LOCK_PATH = "/home/artrix/.cache/niri-workspace-orchestrator.lock"
const LOG_PATH = "/tmp/niri-workspace-orchestrator.log"
const POLL_INTERVAL_SECS = 1

const WORKSPACE_TARGETS = [
  {name: "chat", apps: [["vesktop"]]}
  {name: "music", apps: [["spotify"]]}
  {name: "research", apps: [["zen-browser"]]}
  {name: "monitor", apps: [["missioncenter"]]}
  {name: "code", apps: [["ghostty"] ["zeditor"]]}
  {
    name: "work",
    apps: [
      ["microsoft-edge-dev"]
      ["notion-app"]
      ["notion-calendar"]
    ]
  }
]

def log [message: string] {
  let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
  $"($timestamp) ($message)\n" | save --append --raw $LOG_PATH
}

def ensure-single-instance [] {
  mkdir ~/.cache

  if ($LOCK_PATH | path exists) {
    let existing = (open $LOCK_PATH | from json)
    let existing_pid = ($existing | get -o pid | default 0)
    if $existing_pid != 0 {
      let running = (ps | where pid == $existing_pid)
      if not ($running | is-empty) {
        log $"watcher already running as pid ($existing_pid), exiting"
        exit 0
      }
    }
  }

  {pid: $nu.pid, started_at: (date now | format date '%+') } | to json | save -f $LOCK_PATH
}

def spawn-app [workspace_name: string, cmd: list<string>] {
  log $"spawning for workspace=($workspace_name): ($cmd | str join ' ')"
  ^niri msg action spawn -- ...$cmd | ignore
}

def ensure-workspace-apps [
  workspace_name: string,
  workspace_id: int,
  windows: list<any>,
  cooldowns: record
] {
  let target_rows = ($WORKSPACE_TARGETS | where name == $workspace_name)
  if ($target_rows | is-empty) {
    return $cooldowns
  }

  let target = ($target_rows | first)
  let workspace_window_ids = (
    $windows
    | where workspace_id == $workspace_id
    | get id
  )

  log $"workspace=($workspace_name) workspace_id=($workspace_id) windows=($workspace_window_ids | to json)"
  if not ($workspace_window_ids | is-empty) {
    log $"workspace=($workspace_name) already has windows, skipping launches"
    return $cooldowns
  }

  for cmd in $target.apps {
    spawn-app $workspace_name $cmd
  }

  $cooldowns
}

def focused-workspace [workspaces: list<any>] {
  $workspaces | where is_focused == true | get -o 0
}

ensure-single-instance
"" | save -f $LOG_PATH
log "watcher started"

mut last_focused_workspace = null
mut cooldowns = {}

while true {
  let workspaces = (^niri msg --json workspaces | from json)
  let windows = (^niri msg --json windows | from json)
  let focused = (focused-workspace $workspaces)

  if not ($focused | is-empty) {
    let focused_name = ($focused | get -o name)
    if not ($focused_name | is-empty) and $last_focused_workspace != $focused_name {
      log $"focused workspace changed to ($focused_name)"
      $cooldowns = (ensure-workspace-apps $focused_name $focused.id $windows $cooldowns)
      $last_focused_workspace = $focused_name
    }
  }

  sleep ($POLL_INTERVAL_SECS | into duration --unit sec)
}
