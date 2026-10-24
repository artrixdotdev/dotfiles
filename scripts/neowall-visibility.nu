#!/usr/bin/env nu

use neowall-hardware.nu system-batteries

let power_preference = "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"
let niri_blur = ($env.HOME | path join ".config/niri/dms/power-blur.kdl")
let niri_blur_default = ($env.HOME | path join ".config/niri/config/power-blur.kdl")
let niri_opacity = ($env.HOME | path join ".config/niri/dms/power-opacity.kdl")
let niri_opacity_default = ($env.HOME | path join ".config/niri/config/power-opacity.kdl")
let dms_power_override = ($env.HOME | path join ".config/DankMaterialShell/config.d/90-laptop-power.json")

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

def power-saver-active [] {
  let profile = (do -i { ^powerprofilesctl get } | complete)
  if $profile.exit_code == 0 {
    return (($profile.stdout | str trim) == "power-saver")
  }
  if ($power_preference | path exists) {
    return ((open $power_preference | str trim) == "power")
  }
  false
}

def sync-low-power-visuals [power_saver: bool] {
  let blur = if $power_saver { "// Window blur paused in power-saver mode\n" } else { open --raw $niri_blur_default }
  let opacity_default = (open --raw $niri_opacity_default)
  let opacity = if $power_saver { $opacity_default | str replace 'opacity 0.80' 'opacity 1.00' } else { $opacity_default }
  let blur_changed = not ($niri_blur | path exists) or (open --raw $niri_blur) != $blur
  let opacity_changed = not ($niri_opacity | path exists) or (open --raw $niri_opacity) != $opacity
  if $blur_changed or $opacity_changed {
    if $blur_changed { $blur | save --force $niri_blur }
    if $opacity_changed { $opacity | save --force $niri_opacity }
    let reload = (do -i { ^niri msg action load-config-file } | complete)
    if $reload.exit_code != 0 { error make { msg: $reload.stderr } }
  }

  let dms_override = if $power_saver {
    { blurEnabled: false, popupTransparency: 1, foregroundLayerTransparency: 1 }
  } else { {} }
  if not ($dms_power_override | path exists) or (open $dms_power_override) != $dms_override {
    mkdir ($dms_power_override | path dirname)
    $dms_override | to json | save --force $dms_power_override
  }
}

def should-pause [batteries: list<string>, power_saver: bool] {
  if ($batteries | is-not-empty) {
    for battery in $batteries {
      let capacity = ($battery | path join "capacity")
      if ($capacity | path exists) and (open $capacity | str trim | into int) <= 50 {
        return true
      }
    }

    if $power_saver { return true }
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
      let batteries = (system-batteries)
      let power_saver = if ($batteries | is-empty) { false } else { power-saver-active }
      if ($batteries | is-not-empty) and not $once { sync-low-power-visuals $power_saver }
      let pause = (should-pause $batteries $power_saver)
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
    sleep 3sec
  }
}
