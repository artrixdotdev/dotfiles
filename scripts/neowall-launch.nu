#!/usr/bin/env nu

use neowall-hardware.nu [system-batteries gpu-count]

def main [--sys-root: string = "/sys", --print-config] {
  let config_home = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config"))
  let source = ($config_home | path join "neowall/config.vibe")
  let base = (open --raw $source)
  let capped = ((system-batteries $sys_root | is-not-empty) and (gpu-count $sys_root) == 1)

  if not ($base | str contains "  vsync true\n") {
    error make { msg: $"Expected 'vsync true' in ($source)" }
  }

  let config = if $capped {
    $base | str replace "  vsync true\n" "  vsync false\n  shader_fps 30\n"
  } else {
    $base
  }

  if $print_config {
    print --no-newline $config
    return
  }

  let runtime = ($env.XDG_RUNTIME_DIR? | default $"/run/user/(^id -u | str trim)")
  let generated = ($runtime | path join "neowall-config.vibe")
  $config | save --force $generated
  exec /usr/bin/neowall -f -c $generated
}
