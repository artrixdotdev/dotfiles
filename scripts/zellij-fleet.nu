#!/usr/bin/env nu

const default_port = 8082
const default_remote_session = "fleet"
const default_local_session = "fleet-client"
const vault_item_prefix = "zellij-web/"
const remote_token_name = "zellij-fleet"

def bitwarden-session-file [] {
  let cache_home = ($env | get -o XDG_CACHE_HOME | default ($env.HOME | path join ".cache"))
  $cache_home | path join "zellij-fleet" "bw-session"
}

def --env load-bitwarden-session-cache [] {
  if (($env | get -o BW_SESSION | default "") | is-not-empty) {
    return
  }

  let session_file = (bitwarden-session-file)
  if not ($session_file | path exists) {
    return
  }

  let cached = (open $session_file | into string | str trim)
  if ($cached | is-not-empty) {
    $env.BW_SESSION = $cached
  }
}

def persist-bitwarden-session [session: string] {
  let session_file = (bitwarden-session-file)
  let session_dir = ($session_file | path dirname)
  mkdir $session_dir
  $session | save --force $session_file
  ^chmod 600 $session_file | complete | ignore
}

def --env bitwarden-status [] {
  load-bitwarden-session-cache

  let status_result = (^bw status | complete)
  if $status_result.exit_code != 0 {
    return "unavailable"
  }

  try { $status_result.stdout | from json | get status } catch { "unavailable" }
}

def log-info [message: string] {
  print $"(ansi cyan_bold)→(ansi reset) ($message)"
}

def log-success [message: string] {
  print $"(ansi green_bold)✓(ansi reset) ($message)"
}

def log-warn [message: string] {
  print --stderr $"(ansi yellow_bold)!(ansi reset) ($message)"
}

def sanitized [message: string, secrets: list<string> = []] {
  $secrets
  | where {|secret| $secret | is-not-empty }
  | reduce --fold ($message | str trim) {|secret, text|
      $text | str replace --all $secret "<redacted>"
    }
}

def fail [message: string, --detail: string = "", --secrets: list<string> = []] {
  print --stderr $"(ansi red_bold)✗ zellij-fleet:(ansi reset) ($message)"
  if ($detail | str trim | is-not-empty) {
    print --stderr $"  (ansi dark_gray)└─(ansi reset) (sanitized $detail $secrets)"
  }
  exit 1
}

def kdl-string [value: string] {
  $value
  | str replace --all '\\' '\\\\'
  | str replace --all '"' '\\"'
  | str replace --all "\n" '\\n'
}

def normalized-host [value: any] {
  $value
  | into string
  | str trim
  | str lowercase
  | str replace -r '^https?://' ''
  | split row '/'
  | first
  | str replace -r ':\d+$' ''
  | str trim --char '.'
}

def local-machine-identities [] {
  mut identities = [
    (normalized-host (sys host | get hostname))
    (normalized-host ($env | get -o HOSTNAME | default ""))
  ]

  if (which tailscale | is-empty) {
    fail "cannot safely build fleet: Tailscale CLI is unavailable" --detail "Self-detection is required to prevent attaching this device to itself."
  }

  let status = (^tailscale status --json | complete)
  if $status.exit_code != 0 {
    fail "cannot safely build fleet: Tailscale self-detection failed" --detail $"tailscale status exited ($status.exit_code): ($status.stderr)"
  }

  let self = (try { $status.stdout | from json | get -o Self } catch { null })
  if $self == null {
    fail "cannot safely build fleet: Tailscale returned no local node identity"
  }
  $identities = (
    $identities
    | append (normalized-host ($self | get -o DNSName | default ""))
    | append ($self | get -o TailscaleIPs | default [] | each {|ip| normalized-host $ip })
  )

  $identities
  | where {|identity| $identity | is-not-empty }
  | uniq
}

def machine-record [] {
  let from_record = (
    $env
    | get -o TAILSCALE_URLS
    | default {}
  )

  let discovered = if (
    (($from_record | describe) | str starts-with "record")
    and ($from_record | is-not-empty)
  ) {
    $from_record
  } else {
    $env
    | transpose name value
    | where {|row|
        ($row.name | str starts-with "TAILSCALE_") and $row.name != "TAILSCALE_URLS"
      }
    | reduce --fold {} {|row, machines|
        let name = ($row.name | str replace -r '^TAILSCALE_' '' | str lowercase)
        $machines | upsert $name ($row.value | into string)
      }
  }

  let configured_dotfiles = ($env | get -o DOTFILES_DIR | default ($env.HOME | path join "dotfiles"))
  let policy_file = ($configured_dotfiles | path join ".encrypted" "zellij-fleet.json")
  let file_config = if ($policy_file | path exists) {
    try { open $policy_file } catch { {} }
  } else {
    {}
  }
  let config_exclusions = (
    $file_config
    | get -o exclude
    | default ($env | get -o ZELLIJ_FLEET_CONFIG.exclude | default [])
  )
  let env_exclusions = (
    $env
    | get -o ZELLIJ_FLEET_EXCLUDE
    | default ""
    | into string
    | split row ','
  )
  let exclusions = (
    $config_exclusions
    | append $env_exclusions
    | each {|name| $name | into string | str trim | str lowercase }
    | where {|name| $name | is-not-empty }
    | uniq
  )

  let local_identities = (local-machine-identities)
  let local_exclusions = (
    $discovered
    | transpose name host
    | where {|machine|
        (($machine.name | str lowercase) in $local_identities) or ((normalized-host $machine.host) in $local_identities)
      }
    | get -o name
    | default []
  )
  let all_exclusions = ($exclusions | append $local_exclusions | uniq)

  $discovered
  | reject -o ...$all_exclusions
}

def machine-rows [machines: record] {
  $machines
  | transpose name host
  | collect {|rows| $rows | sort-by name }
}

def remote-url [host_value: any, remote_session: string] {
  let raw = ($host_value | into string | str trim | str trim --char '/')
  if ($raw | is-empty) {
    return null
  }

  let authority = (
    $raw
    | str replace -r '^https?://' ''
    | split row '/'
    | first
  )
  let host_and_port = if $authority =~ ':\d+$' {
    $authority
  } else {
    $"($authority):($default_port)"
  }
  let encoded_session = ($remote_session | url encode --all)

  $"https://($host_and_port)/($encoded_session)"
}

def ssh-target [host_value: any] {
  $host_value
  | into string
  | str replace -r '^https?://' ''
  | split row '/'
  | first
  | str replace -r ':\d+$' ''
}

def machine-online [host_value: any] {
  let target = (ssh-target $host_value)
  let result = (^tailscale ping --timeout=2s $target | complete)
  $result.exit_code == 0
}

def vault-item-name [machine: string] {
  $"($vault_item_prefix)($machine)"
}

def --env require-bitwarden [--allow-unlock] {
  if (which bw | is-empty) {
    fail "Bitwarden CLI is not installed"
  }

  let status = (bitwarden-status)

  if $status == "unlocked" {
    log-success "Bitwarden vault is unlocked"
    return
  }

  if $status == "unauthenticated" {
    fail "Bitwarden is not logged in" --detail "Run `bw login` first, then retry."
  }

  if not $allow_unlock {
    fail "Bitwarden is not unlocked" --detail "Unlock Bitwarden from the fleet launcher, then retry."
  }

  log-info "Bitwarden vault is locked; unlock required before continuing"
  let unlock = (^bw unlock --raw | complete)
  if $unlock.exit_code != 0 {
    fail "Bitwarden unlock failed" --detail $unlock.stderr
  }

  let session = ($unlock.stdout | str trim)
  if ($session | is-empty) {
    fail "Bitwarden unlock returned an empty session"
  }

  $env.BW_SESSION = $session
  persist-bitwarden-session $session
  log-success "Bitwarden vault is unlocked"
}

def vault-item-id [machine: string] {
  let item_name = (vault-item-name $machine)
  let result = (^bw list items --search $item_name | complete)
  if $result.exit_code != 0 {
    fail $"Bitwarden lookup failed for ($machine)" --detail $"exit ($result.exit_code): ($result.stderr)"
  }

  $result.stdout
  | from json
  | where name == $item_name
  | get -o 0.id
}

def vault-token [machine: string] {
  let item_id = (vault-item-id $machine)
  if $item_id == null {
    return null
  }

  let result = (^bw get password $item_id | complete)
  if $result.exit_code != 0 {
    fail $"Bitwarden could not read the token for ($machine)" --detail $"exit ($result.exit_code): ($result.stderr)"
  }

  $result.stdout | str trim
}

def delete-vault-item [machine: string] {
  let item_id = (vault-item-id $machine)
  if $item_id == null {
    return
  }
  let result = (^bw delete item $item_id --permanent | complete)
  if $result.exit_code != 0 {
    fail $"Bitwarden could not remove the malformed token for ($machine)" --detail $"exit ($result.exit_code): ($result.stderr)"
  }
}

def create-vault-item [machine: string, endpoint: string, token: string] {
  let item = {
    type: 1
    name: (vault-item-name $machine)
    notes: "Managed by zellij-fleet.nu. Delete this item to provision a replacement token."
    favorite: false
    login: {
      username: "zellij"
      password: $token
      uris: [{uri: $endpoint, match: null}]
    }
  }
  let encoded = ($item | to json | encode base64)
  let result = ($encoded | ^bw create item | complete)
  {
    ok: ($result.exit_code == 0)
    exit_code: $result.exit_code
    stderr: (sanitized $result.stderr [$token $endpoint])
  }
}

def create-remote-token [machine: string, ssh_target: string] {
  # A missing vault item means any same-named remote token is unrecoverable.
  # Revoke it first so this operation is safely repeatable after partial runs.
  log-info $"($machine): clearing any unrecoverable managed token"
  let revoke = (
    ^ssh -F /dev/null -o BatchMode=yes $ssh_target -- zellij web --revoke-token $remote_token_name
    | complete
  )
  if $revoke.exit_code != 0 {
    log-warn $"($machine): no previous managed token was revoked; continuing"
  }

  log-info $"($machine): requesting a new token from remote Zellij"
  mut result = (
    ^ssh -F /dev/null -o BatchMode=yes $ssh_target -- zellij web --create-token --token-name $remote_token_name
    | complete
  )
  if (
    $result.exit_code != 0
    and ($result.stderr | str contains "cannot be used with one or more of the other specified arguments")
  ) {
    log-warn $"($machine): remote Zellij does not support named token creation; retrying compatible syntax"
    $result = (
      ^ssh -F /dev/null -o BatchMode=yes $ssh_target -- zellij web --create-token
      | complete
    )
  }
  if $result.exit_code != 0 {
    let trust_hint = if ($result.stderr | str contains "Host key verification failed") {
      $" Run `zellij-fleet.nu trust ($machine)`, verify the fingerprint, then retry."
    } else {
      ""
    }
    fail $"remote token creation failed on ($machine)" --detail $"ssh/zellij exited ($result.exit_code): ($result.stderr)($trust_hint)" --secrets [$ssh_target]
  }

  # Zellij 0.44 emits a generated label followed by a colon and a multi-word
  # token. Preserve the entire value after the first colon.
  let token_line = (
    $result.stdout
    | lines
    | where {|line| $line | str contains ':' }
    | last
  )
  let token_parts = ($token_line | split row ':')
  let token_name = ($token_parts | first | str trim)
  let token = ($token_parts | skip 1 | str join ':' | str trim)
  if ($token | is-empty) {
    fail $"remote Zellij returned an empty token for ($machine)"
  }

  log-success $"($machine): remote token created"
  {name: $token_name, value: $token}
}

def revoke-remote-token [ssh_target: string, token_name: string = $remote_token_name] {
  ^ssh -F /dev/null -o BatchMode=yes $ssh_target -- zellij web --revoke-token $token_name
  | complete
  | ignore
}

def ensure-tokens [machines: record, remote_session: string] {
  log-info "Checking token prerequisites"
  let initial_sync = (^bw sync | complete)
  if $initial_sync.exit_code != 0 {
    fail "Bitwarden sync failed" --detail $"exit ($initial_sync.exit_code): ($initial_sync.stderr)"
  }
  log-success "Bitwarden vault synchronized"

  for machine in (machine-rows $machines) {
    let ssh_target = (ssh-target $machine.host)
    if not (machine-online $machine.host) {
      log-warn $"($machine.name): offline; its tab will connect automatically when it returns"
      continue
    }
    log-info $"($machine.name): checking Bitwarden"
    if (vault-item-id $machine.name) != null {
      let existing_token = (vault-token $machine.name)
      if (($existing_token | split words | length) > 1) {
        log-success $"($machine.name): using existing vault token"
        continue
      }
      log-warn $"($machine.name): stored token is malformed; replacing it"
      delete-vault-item $machine.name
    }

    log-warn $"($machine.name): vault token is missing; provisioning"
    let endpoint = (remote-url $machine.host $remote_session)
    let token = (create-remote-token $machine.name $ssh_target)
    log-info $"($machine.name): storing token in Bitwarden"
    let vault_create = (create-vault-item $machine.name $endpoint $token.value)
    if not $vault_create.ok {
      revoke-remote-token $ssh_target $token.name
      fail $"vault storage failed for ($machine.name); the remote token was rolled back" --detail $"bw exited ($vault_create.exit_code): ($vault_create.stderr)"
    }
    log-success $"($machine.name): token safely stored in Bitwarden"
  }

  let final_sync = (^bw sync | complete)
  if $final_sync.exit_code != 0 {
    fail "final Bitwarden sync failed" --detail $"exit ($final_sync.exit_code): ($final_sync.stderr)"
  }
  log-success "All machine tokens are ready"
}

def layout-for [machines: record, remote_session: string, script_path: string] {
  let tabs = (
    machine-rows $machines
    | enumerate
    | each --keep-empty {|entry|
        let machine = $entry.item
        let local_port = (18082 + $entry.index)
        let url = $"http://127.0.0.1:($local_port)/(($remote_session | url encode --all))"
        if $url == null {
          return
        }

        let name = (kdl-string ($machine.name | into string))
        let endpoint = (kdl-string $url)
        let target = (kdl-string (ssh-target $machine.host))
        let script = (kdl-string $script_path)
        $'    tab name="($name)" {
        pane size=1 borderless=true {
            plugin location="tab-bar"
        }
        pane focus=true borderless=true command="nu" {
            args "($script)" "attach" "($name)" "($endpoint)" "($target)" "($local_port)"
        }
    }'
      }
    | str join "\n"
  )

  $'layout {
($tabs)
}'
}

# Internal entry point used by each generated tab.
def "main attach" [machine: string, endpoint: string, ssh_target: string, local_port: int] {
  let forward = $"127.0.0.1:($local_port):127.0.0.1:($default_port)"
  # The outer fleet client is only a transport/tab switcher. Locking it passes
  # application shortcuts (eg. Alt+n) through to the remote child Zellij.
  ^zellij action switch-mode locked | complete | ignore
  # The remote client is intentionally nested one level inside the local fleet
  # session. Removing these markers prevents Zellij from treating it as a local
  # nested session.
  hide-env --ignore-errors ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID
  require-bitwarden

  loop {
    let control_socket = (
      ($env | get -o TMPDIR | default "/tmp")
      | path join $"zellij-fleet-ssh-(random uuid).sock"
    )
    log-info $"($machine): checking Tailscale reachability"
    let ping = (^tailscale ping --timeout=2s $ssh_target | complete)
    if $ping.exit_code != 0 {
      log-warn $"($machine): offline on Tailscale; retrying in 5 seconds"
      sleep 5sec
      continue
    }
    log-success $"($machine): reachable over Tailscale"

    # Resurrected fleet sessions can already have a live background tunnel.
    # Reuse it instead of failing on an occupied deterministic local port.
    let existing_health = (
      ^curl --silent --output /dev/null --write-out "%{http_code}" --connect-timeout 1 --max-time 2 $endpoint
      | complete
    )
    mut owns_tunnel = false
    if $existing_health.exit_code == 0 and ($existing_health.stdout | str trim) != "000" {
      log-success $"($machine): reusing existing SSH tunnel"
    } else {
      log-info $"($machine): opening verified SSH tunnel"
      let tunnel = (
        ^ssh -F /dev/null -M -S $control_socket -f -N -L $forward -o BatchMode=yes -o ConnectTimeout=5 -o ExitOnForwardFailure=yes $ssh_target
        | complete
      )
      if $tunnel.exit_code != 0 {
        log-warn $"($machine): Tailscale is reachable but SSH tunnel failed; retrying in 5 seconds"
        let detail = (sanitized $tunnel.stderr [$ssh_target])
        if ($detail | is-not-empty) {
          print --stderr $"  (ansi dark_gray)└─(ansi reset) ($detail)"
        }
        sleep 5sec
        continue
      }
      $owns_tunnel = true
    }

    let health = (
      ^curl --silent --show-error --output /dev/null --write-out "%{http_code}" --connect-timeout 3 --max-time 5 $endpoint
      | complete
    )
    if $health.exit_code != 0 or ($health.stdout | str trim) == "000" {
      if $owns_tunnel {
        ^ssh -F /dev/null -S $control_socket -O exit $ssh_target | complete | ignore
      }
      log-warn $"($machine): Zellij web service is not ready; retrying in 5 seconds"
      sleep 5sec
      continue
    }
    log-success $"($machine): connected through SSH tunnel"

    log-info $"($machine): loading token from Bitwarden"
    let existing_token = (vault-token $machine)
    let token = if ($existing_token == null) or (($existing_token | split words | length) < 2) {
      if $existing_token != null {
        log-warn $"($machine): replacing malformed vault token"
        delete-vault-item $machine
      }
      let created = (create-remote-token $machine $ssh_target)
      let stored = (create-vault-item $machine $endpoint $created.value)
      if not $stored.ok {
        revoke-remote-token $ssh_target $created.name
        fail $"could not store a new token for ($machine)" --detail $stored.stderr
      }
      $created.value
    } else {
      $existing_token
    }

    log-info $"($machine): attaching to remote Zellij session"
    ^zellij attach $endpoint --token $token --remember
    let attach_exit = $env.LAST_EXIT_CODE
    if $owns_tunnel {
      ^ssh -F /dev/null -S $control_socket -O exit $ssh_target | complete | ignore
      rm --force $control_socket
    }

    if $attach_exit == 2 {
      log-warn $"($machine): authentication was rejected; rotating token on retry"
      delete-vault-item $machine
    } else {
      log-warn $"($machine): connection ended; reconnecting in 5 seconds"
    }
    sleep 5sec
  }
}

def "main tokens" [--remote-session: string = $default_remote_session] {
  require-bitwarden --allow-unlock
  let machines = (machine-record)
  if ($machines | is-empty) {
    fail "no machines found; set TAILSCALE_URLS or one or more TAILSCALE_<NAME> variables"
  }
  ensure-tokens $machines $remote_session
}

def "main trust" [machine: string] {
  let machines = (machine-record)
  let host = ($machines | get -o $machine)
  if $host == null {
    fail $"unknown machine '($machine)'" --detail $"Available inventory keys: (($machines | columns | sort | str join ', '))"
  }

  let target = (ssh-target $host)
  log-info $"($machine): opening SSH host-key verification"
  log-warn "Confirm only after verifying the displayed fingerprint belongs to this device"
  ^ssh -F /dev/null $target -- true
  let exit_code = $env.LAST_EXIT_CODE
  if $exit_code != 0 {
    fail $"SSH trust setup failed for ($machine)" --detail $"ssh exited ($exit_code)" --secrets [$target]
  }
  log-success $"($machine): SSH host key is trusted"
}

def session-exists [name: string] {
  let sessions = (^zellij list-sessions --short --no-formatting | complete)
  if $sessions.exit_code != 0 {
    return false
  }
  $name in ($sessions.stdout | lines | each {|session| $session | str trim })
}

def delete-session [name: string] {
  let result = (^zellij delete-session $name --force | complete)
  if $result.exit_code != 0 {
    fail $"could not delete existing Zellij session '($name)'" --detail $"zellij exited ($result.exit_code): ($result.stderr)"
  }
}

def main [
  --remote-session: string = $default_remote_session
  --local-session: string = $default_local_session
  --skip-token-sync
] {
  if (which zellij | is-empty) {
    fail "zellij is not installed"
  }

  let initial_bw_status = if $skip_token_sync {
    null
  } else {
    bitwarden-status
  }
  if not $skip_token_sync {
    require-bitwarden --allow-unlock
  }

  # Fast path: a healthy fleet-client already owns its tunnels and tabs. Do not
  # repeat inventory, Tailscale, SSH, or Bitwarden work just to focus it.
  let existing_fleet = (session-exists $local_session)
  let current_session = ($env | get -o ZELLIJ_SESSION_NAME | default "")
  let inside_zellij = (
    ($current_session | is-not-empty) and (session-exists $current_session)
  )
  if $existing_fleet {
    if (not $skip_token_sync) and $initial_bw_status != "unlocked" {
      log-info $"Recreating Zellij session '($local_session)' after Bitwarden unlock"
      delete-session $local_session
    } else {
    ^zellij --session $local_session action switch-mode locked | complete | ignore
    if $inside_zellij and $current_session == $local_session {
      log-success $"Already using Zellij session '($local_session)'"
    } else if $inside_zellij {
      log-info $"Switching to existing Zellij session '($local_session)'"
      ^zellij action switch-session $local_session
    } else {
      log-info $"Attaching to existing Zellij session '($local_session)'"
      hide-env --ignore-errors ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID
      ^zellij attach $local_session --force-run-commands options --default-mode locked
    }
    return
    }
  }

  let machines = (machine-record)
  if ($machines | is-empty) {
    fail "no machines found; set TAILSCALE_URLS or one or more TAILSCALE_<NAME> variables"
  }

  if not $skip_token_sync {
    ensure-tokens $machines $remote_session
  }

  let script_path = ($env.CURRENT_FILE | path expand)
  log-info $"Generating tabs for (($machines | columns | length)) machines"
  let layout = (layout-for $machines $remote_session $script_path)

  if $inside_zellij {
    log-info $"Creating and switching to Zellij session '($local_session)'"
    ^zellij action switch-session $local_session --layout-string $layout
  } else {
    log-info $"Creating Zellij session '($local_session)'"
    hide-env --ignore-errors ZELLIJ ZELLIJ_SESSION_NAME ZELLIJ_PANE_ID
    # --session with --layout-string only targets an existing session in
    # Zellij 0.44. New sessions require the dedicated layout-file command.
    let layout_file = (
      ($env | get -o TMPDIR | default "/tmp")
      | path join $"zellij-fleet-(random uuid).kdl"
    )
    $layout | save --force $layout_file
    ^zellij --session $local_session --new-session-with-layout $layout_file
    rm --force $layout_file
  }
}
