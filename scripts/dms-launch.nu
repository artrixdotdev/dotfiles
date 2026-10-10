#!/usr/bin/env nu

def active-display [runtime: string] {
  let configured = ($env.WAYLAND_DISPLAY? | default "")
  if ($configured | is-not-empty) and (($runtime | path join $configured | path type) == "socket") {
    return $configured
  }

  let sockets = (glob ($runtime | path join "wayland-[0-9]*")
    | where {|socket| ($socket | path basename) =~ '^wayland-[0-9]+$' and ($socket | path type) == "socket" })
  if ($sockets | is-empty) { return "" }
  $sockets | first | path basename
}

def main [--probe] {
  let runtime = ($env.XDG_RUNTIME_DIR? | default $"/run/user/(^id -u | str trim)")

  loop {
    let display = (active-display $runtime)
    if ($display | is-not-empty) {
      if $probe { print $display; return }
      exec /usr/bin/env $"WAYLAND_DISPLAY=($display)" "QT_QPA_PLATFORM=wayland" /usr/bin/dms run --session
    }
    if $probe { error make { msg: "No active Wayland display" } }
    sleep 1sec
  }
}
