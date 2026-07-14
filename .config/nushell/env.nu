# Nushell Environment Config File
#
# version = "0.95.0"



def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

def create_right_prompt [] {
    starship prompt --right --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}




# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.XDG_CONFIG_HOME = $env.HOME + "/.config"
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }
$env.EDITOR = "nvim"

# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and it's taking up a lot of space
# because every command entered takes up 2 lines instead of 1. You can then uncomment
# the line below so that previously entered commands show with a single `🚀`.
# $env.TRANSIENT_PROMPT_COMMAND = {|| "🚀 " }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# Add zvm to PATH if it exists
use std "path add"
if ("~/.zvm/bin" | path expand | path exists) {
   path add ~/.zvm/bin
}

if ("~/.turso" | path expand | path exists) {
   path add ~/.turso
}

if ("~/.cargo/bin" | path expand | path exists) {
   path add ~/.cargo/bin
}

if ("~/.bun/bin" | path expand | path exists) {
   path add ~/.bun/bin
}

# Turns { desktop: "desktop.tailscale.com" } into $env.TAILSCALE_DESKTOP
let tailscale_urls_file = "~/dotfiles/.encrypted/tailscale.json" | path expand
if ($tailscale_urls_file | path exists) {
   let tailscale_urls = open $tailscale_urls_file
   let tailscale_env = (
      $tailscale_urls
      | transpose key value
      | reduce --fold {} { |item, acc|
         $acc | merge { ($"TAILSCALE_($item.key | str uppercase)"): $item.value }
      }
   )

   $env.TAILSCALE_URLS = $tailscale_urls
   load-env $tailscale_env
}

# Optional encrypted, machine-specific fleet policy. The launcher remains
# generic while exclusions and future policy stay out of plaintext config.
let zellij_fleet_file = "~/dotfiles/.encrypted/zellij-fleet.json" | path expand
if ($zellij_fleet_file | path exists) {
   $env.ZELLIJ_FLEET_CONFIG = (open $zellij_fleet_file)
}

mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
zoxide init nushell | save -f ~/.zoxide.nu
$env.RUSTC_WRAPPER = "/usr/bin/sccache"
$env.STARSHIP_CONFIG = ($env.XDG_CONFIG_HOME | path join "starship/starship.toml")
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
$env.FZF_DEFAULT_OPTS = "--height=40% --layout=reverse --border --margin=1,20%"
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu
let bitwarden_ssh_agent_socket = "~/.bitwarden-ssh-agent.sock" | path expand
if ($bitwarden_ssh_agent_socket | path exists) {
    $env.SSH_AUTH_SOCK = $bitwarden_ssh_agent_socket
}



# pnpm
$env.PNPM_HOME = "/home/artrix/.local/share/pnpm"
$env.PATH = ($env.PATH | split row (char esep) | prepend $env.PNPM_HOME )
# pnpm end
