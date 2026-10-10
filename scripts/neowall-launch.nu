#!/usr/bin/env nu

def main [--print-config] {
  let config_home = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config"))
  let source = ($config_home | path join "neowall/config.vibe")
  let config = (open --raw $source)

  if $print_config {
    print --no-newline $config
    return
  }

  let runtime = ($env.XDG_RUNTIME_DIR? | default $"/run/user/(^id -u | str trim)")
  let generated = ($runtime | path join "neowall-config.vibe")
  $config | save --force $generated
  exec /usr/bin/neowall -f -c $generated
}
