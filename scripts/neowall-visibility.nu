#!/usr/bin/env nu

let power_preference = "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"

def niri-json [socket: string, subject: string] {
  let result = (with-env { NIRI_SOCKET: $socket } {
    do -i { ^niri msg --json $subject } | complete
  })
  if $result.exit_code != 0 {
    error make { msg: $result.stderr }
  }
  $result.stdout | from json
}

def niri-socket [] {
  let configured = ($env.NIRI_SOCKET? | default "")
  if ($configured | path exists) {
    return $configured
  }
  let runtime = ($env.XDG_RUNTIME_DIR? | default $"/run/user/(^id -u | str trim)")
  glob ($runtime | path join "niri*.sock") | first
}

def has-visible-window [socket: string] {
  let workspaces = (niri-json $socket "workspaces")
  let windows = (niri-json $socket "windows")
  let active_ids = ($workspaces | where {|ws| $ws.is_active } | each {|ws| $ws.id })
  $windows | any {|window| $window.workspace_id in $active_ids }
}

def should-pause [] {
  if ($power_preference | path exists) {
    let preference = (open $power_preference | str trim)
    if $preference in [power balance_power] {
      return true
    }
  }

  let socket = (niri-socket)
  if ($socket | is-empty) {
    error make { msg: "Niri socket unavailable" }
  }
  if (niri-json $socket "overview-state" | get is_open? | default false) {
    return false
  }
  has-visible-window $socket
}

def main [--once] {
  mut previous = ""
  loop {
    try {
      let pause = (should-pause)
      if $once {
        print (if $pause { "pause" } else { "render" })
        return
      }
      let action = if $pause { "pause-shader" } else { "resume-shader" }
      if $action != $previous {
        let result = (do -i { ^neowall $action } | complete)
        if $result.exit_code == 0 {
          $previous = $action
        } else {
          print --stderr $result.stderr
        }
      }
    } catch {|error|
      if $once { error make { msg: $error.msg } }
      print --stderr $"NeoWall visibility check: ($error.msg)"
    }
    sleep 1sec
  }
}
