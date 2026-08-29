#!/usr/bin/env nu

let picture_dir = ($env.HOME | path join "Pictures" "wallpapers")
let picture = ($picture_dir | path join "neowall.png")
let state_candidates = [
  ($env.HOME | path join ".local" "state" "neowall" "state")
  ($env.HOME | path join ".config" "neowall" "state")
]
let cache_dir = ($env.HOME | path join ".cache" "neowall")
let render_cache_dir = ($cache_dir | path join "renders")
let shader_probe_cache_dir = ($cache_dir | path join "shader-probes")
let signature_file = ($cache_dir | path join "last-signature")
let mode_file = ($cache_dir | path join "display-mode")
let shader_cache_file = ($cache_dir | path join "last-shader")
let settings_file = ($env.HOME | path join ".config" "DankMaterialShell" "settings.json")
let neowall_config_file = ($env.HOME | path join ".config" "neowall" "config.vibe")
let neowall_shader_dir = ($env.HOME | path join ".config" "neowall" "shaders")
let renderer_script = ($env.HOME | path join "dotfiles" "scripts" "render_neowall_shader.py")

mkdir $picture_dir
mkdir $cache_dir
mkdir $render_cache_dir
mkdir $shader_probe_cache_dir

def notify-sync [urgency: string, summary: string, body: string] {
  null
}

def get-output-picture [output_name: string] {
  $picture_dir | path join $"neowall-($output_name).png"
}

def get-output-aspect-distance [output_name: string] {
  let outputs_json = (safe-niri-json "msg" "--json" "outputs")
  if ($outputs_json | is-empty) {
    return 9999.0
  }

  try {
    let outputs = ($outputs_json | from json)
    let output = ($outputs | get $output_name)
    let width = ($output.logical.width | into float)
    let height = ($output.logical.height | into float)
    let aspect = ($width / $height)
    (( $aspect - (16.0 / 9.0) ) | math abs)
  } catch {
    9999.0
  }
}

def get-symlink-output [lines: list<string>] {
  let output_names = (get-live-output-names $lines)
  if ($output_names | is-empty) {
    return ""
  }

  (
    $output_names
    | each {|output_name|
        {
          output: $output_name
          distance: (get-output-aspect-distance $output_name)
        }
      }
    | sort-by distance output
    | get output.0?
    | default ""
  )
}

def update-shared-picture-link [lines: list<string>] {
  let symlink_output = (get-symlink-output $lines)
  if ($symlink_output | is-empty) {
    return false
  }

  let source_picture = (get-output-picture $symlink_output)
  if not ($source_picture | path exists) {
    return false
  }

  let result = (do -i { ^ln -sfn $source_picture $picture } | complete)
  $result.exit_code == 0
}

def resolve-state-file [] {
  $state_candidates | where {|candidate| $candidate | path exists } | first
}

def read-state-lines [state_file: string] {
  open $state_file | lines
}

def has-niri-socket [] {
  (resolve-niri-socket | is-not-empty)
}

def resolve-runtime-dir [] {
  let runtime_dir = ($env.XDG_RUNTIME_DIR? | default "")
  if ($runtime_dir | is-not-empty) {
    return $runtime_dir
  }

  let uid = ((do -i { ^id -u } | complete).stdout | str trim)
  if ($uid | is-not-empty) {
    return $"/run/user/($uid)"
  }

  ""
}

def resolve-niri-socket [] {
  let configured = ($env.NIRI_SOCKET? | default "")
  if (($configured | is-not-empty) and ($configured | path exists)) {
    return $configured
  }

  let runtime_dir = (resolve-runtime-dir)
  if ($runtime_dir | is-empty) {
    return ""
  }

  let result = (do -i { ^find $runtime_dir -maxdepth 1 -type s -name "niri*.sock" } | complete)
  if $result.exit_code != 0 {
    return ""
  }

  $result.stdout
  | lines
  | first
  | default ""
}

def safe-niri-json [...args: string] {
  let niri_socket = (resolve-niri-socket)
  if ($niri_socket | is-empty) {
    return ""
  }

  let result = (with-env { NIRI_SOCKET: $niri_socket } {
    do -i { ^niri ...$args } | complete
  })
  if $result.exit_code == 0 {
    $result.stdout
  } else {
    ""
  }
}

def safe-ffmpeg-copy [source: string, target: string] {
  let source_path = ($source | path expand)
  let target_path = ($target | path expand)

  if $source_path == $target_path {
    return ($target_path | path exists)
  }

  let result = (do -i { ^ffmpeg -loglevel error -y -i $source $target } | complete)
  $result.exit_code == 0
}

def safe-render-shader [shader: string, target: string, width: int, height: int, shader_speed: float] {
  let result = (do -i {
    ^python3 $renderer_script --shader $shader --output $target --width ($width | into string) --height ($height | into string) --speed ($shader_speed | into string) --cache-dir $render_cache_dir
  } | complete)

  $result.exit_code == 0
}

def shader-probe-key [shader: string] {
  let shader_path = ($shader | path expand)
  if not ($shader_path | path exists) {
    return ""
  }

  let stat = (ls -D $shader_path | first)
  $"v2-surfaceless-egl-(($shader_path | str replace '/' '_'))-($stat.modified)"
}

def is-renderable-shader [shader: string] {
  if (
    ($shader | is-empty)
    or (not (($shader | str downcase) | str ends-with ".glsl"))
    or (not ($shader | path exists))
  ) {
    return false
  }

  let key = (shader-probe-key $shader)
  if ($key | is-empty) {
    return false
  }

  let success_marker = ($shader_probe_cache_dir | path join $"($key).ok")
  let failure_marker = ($shader_probe_cache_dir | path join $"($key).fail")

  if ($success_marker | path exists) {
    return true
  }

  if ($failure_marker | path exists) {
    return false
  }

  let probe_target = ($shader_probe_cache_dir | path join $"($key).png")
  let result = (do -i {
    ^python3 $renderer_script --shader $shader --output $probe_target --width "64" --height "64" --speed "1.0"
  } | complete)

  if $result.exit_code == 0 {
    "" | save --force $success_marker
    if ($failure_marker | path exists) {
      rm -f $failure_marker
    }
    true
  } else {
    ($result.stderr | str trim | default "unsupported shader") | save --force $failure_marker
    false
  }
}

def safe-dms-set [target: string, lines: list<string>] {
  let output_names = (get-live-output-names $lines)
  if ($output_names | is-empty) {
    let result = (do -i { ^dms ipc wallpaper set $target } | complete)
    return ($result.exit_code == 0)
  }

  $output_names
  | all {|output_name|
    let result = (do -i { ^dms ipc wallpaper setFor $output_name $target } | complete)
    $result.exit_code == 0
  }
}

def safe-systemctl-user [action: string, unit: string] {
  let result = (do -i { ^systemctl --user $action $unit } | complete)
  $result.exit_code == 0
}

def is-systemctl-user-active [unit: string] {
  let result = (do -i { ^systemctl --user is-active $unit } | complete)
  (($result.stdout | str trim) == "active") or (($result.stdout | str trim) == "activating")
}

def safe-neowall-kill [] {
  let command_result = (do -i { ^neowall kill } | complete)
  if $command_result.exit_code == 0 {
    return true
  }

  let pkill_result = (do -i { ^pkill -TERM -x neowall } | complete)
  ($pkill_result.exit_code == 0) or ($pkill_result.exit_code == 1)
}

def safe-neowall-restart [] {
  let _ = (safe-systemctl-user "stop" "neowall.service")
  let _ = (safe-neowall-kill)
  safe-systemctl-user "start" "neowall.service"
}

def get-active-workspaces [] {
  let workspaces_json = (safe-niri-json "msg" "--json" "workspaces")
  if ($workspaces_json | is-empty) {
    return []
  }

  try {
    (
      $workspaces_json
      | from json
      | where {|ws| ($ws.is_active? | default false) == true }
    )
  } catch {
    []
  }
}

def is-overview-open [] {
  let overview_json = (safe-niri-json "msg" "--json" "overview-state")
  if ($overview_json | is-empty) {
    return false
  }

  try {
    ($overview_json | from json | get is_open? | default false)
  } catch {
    false
  }
}

def get-output-names [lines: list<string>] {
  $lines
  | where {|line| $line | str starts-with "name=" }
  | each {|line| $line | str replace "name=" "" }
}

# The NeoWall state file is persistent and may still contain outputs from a
# previous monitor layout. Prefer the compositor's current output list, and
# only use state as a startup/failure fallback.
def get-live-output-names [lines: list<string>] {
  let outputs_json = (safe-niri-json "msg" "--json" "outputs")
  if ($outputs_json | is-not-empty) {
    try {
      let names = ($outputs_json | from json | columns | sort)
      if ($names | is-not-empty) {
        return $names
      }
    } catch {
    }
  }

  get-output-names $lines
}

def resolve-target-output [lines: list<string>] {
  let configured = if ($settings_file | path exists) {
    try {
      open $settings_file | get matugenTargetMonitor? | default ""
    } catch {
      ""
    }
  } else {
    ""
  }

  if ($configured | is-not-empty) {
    return $configured
  }

  let focused_json = (safe-niri-json "msg" "--json" "focused-output")
  let focused = if ($focused_json | is-not-empty) {
    try {
      $focused_json | from json | get name? | default ""
    } catch {
      ""
    }
  } else {
    ""
  }

  if ($focused | is-not-empty) {
    return $focused
  }

  $lines
  | where {|line| $line | str starts-with "name=" }
  | first
  | default ""
  | str replace "name=" ""
}

def read-output-field [lines: list<string>, target_output: string, field: string] {
  mut in_output = false

  for line in $lines {
    if $line == "[output]" {
      $in_output = false
      continue
    }

    if ($line | str starts-with "name=") {
      $in_output = (($line | str replace "name=" "") == $target_output)
      continue
    }

    if $in_output and ($line | str starts-with $"($field)=") {
      return ($line | str replace $"($field)=" "")
    }
  }

  ""
}

def get-render-source [lines: list<string>] {
  let output_names = (get-output-names $lines)

  for output_name in $output_names {
    let wallpaper_path = (read-output-field $lines $output_name "wallpaper")
    if (($wallpaper_path | is-not-empty) and (($wallpaper_path | str downcase) | str ends-with ".glsl")) {
      return {
        output: $output_name
        wallpaper: $wallpaper_path
        cycle_index: (read-output-field $lines $output_name "cycle_index")
      }
    }
  }

  for output_name in $output_names {
    let wallpaper_path = (read-output-field $lines $output_name "wallpaper")
    if ($wallpaper_path | is-not-empty) {
      return {
        output: $output_name
        wallpaper: $wallpaper_path
        cycle_index: (read-output-field $lines $output_name "cycle_index")
      }
    }
  }

  null
}

def remember-shader [shader_path: string] {
  if (
    ($shader_path | is-not-empty)
    and (($shader_path | str downcase) | str ends-with ".glsl")
    and ($shader_path | path exists)
  ) {
    $shader_path | save --force $shader_cache_file
  }
}

def is-exported-picture [wallpaper_path: string] {
  if ($wallpaper_path | is-empty) {
    return false
  }

  let expanded = ($wallpaper_path | path expand)
  if $expanded == ($picture | path expand) {
    return true
  }

  let basename = ($expanded | path basename)
  ($basename == "neowall.png") or ($basename | str starts-with "neowall-")
}

def get-output-size [target_output: string] {
  let outputs_json = (safe-niri-json "msg" "--json" "outputs")
  if ($outputs_json | is-empty) {
    return {
      width: 3840
      height: 2160
    }
  }

  try {
    let outputs = ($outputs_json | from json)
    let output = ($outputs | get $target_output)
    {
      width: (($output.logical.width | into int) * 2)
      height: (($output.logical.height | into int) * 2)
    }
  } catch {
    {
      width: 3840
      height: 2160
    }
  }
}

def render-output-image [shader_path: string, output_name: string, shader_speed: float] {
  let size = (get-output-size $output_name)
  let output_picture = (get-output-picture $output_name)
  safe-render-shader $shader_path $output_picture $size.width $size.height $shader_speed
}

def copy-output-image [source_path: string, output_name: string] {
  let output_picture = (get-output-picture $output_name)
  safe-ffmpeg-copy $source_path $output_picture
}

def ensure-all-output-images [lines: list<string>, source_path: string] {
  let output_names = (get-live-output-names $lines)
  if ($output_names | is-empty) {
    return false
  }

  let lowered = ($source_path | str downcase)
  if ($lowered | str ends-with ".glsl") {
    let render_shader_path = (resolve-renderable-shader $lines)
    if ($render_shader_path | is-empty) {
      return false
    }

    remember-shader $render_shader_path
    let shader_speed = get-shader-speed
    let success = (
      $output_names
      | all {|output_name| render-output-image $render_shader_path $output_name $shader_speed }
    )
    if $success {
      let _ = (update-shared-picture-link $lines)
    }
    $success
  } else if (
    ($lowered | str ends-with ".png")
    or ($lowered | str ends-with ".jpg")
    or ($lowered | str ends-with ".jpeg")
    or ($lowered | str ends-with ".webp")
    or ($lowered | str ends-with ".bmp")
  ) {
    let success = (
      $output_names
      | all {|output_name| copy-output-image $source_path $output_name }
    )
    if $success {
      let _ = (update-shared-picture-link $lines)
    }
    $success
  } else {
    false
  }
}

def get-shader-speed [] {
  if not ($neowall_config_file | path exists) {
    return 1.0
  }

  let line = (
    open $neowall_config_file
    | lines
    | where {|line| ($line | str trim | str starts-with "shader_speed ") }
    | first
    | default ""
  )

  if ($line | is-empty) {
    1.0
  } else {
    try {
      ($line | str trim | split row " " | last | into float)
    } catch {
      1.0
    }
  }
}

def resolve-live-shader [lines: list<string>] {
  if ($shader_cache_file | path exists) {
    let cached_shader = (open $shader_cache_file | str trim)
    if (($cached_shader | is-not-empty) and ($cached_shader | path exists)) {
      return $cached_shader
    }
  }

  let current_state = (
    get-output-names $lines
    | each {|output_name|
        {
          output: $output_name
          wallpaper: (read-output-field $lines $output_name "wallpaper")
        }
      }
  )

  let preferred_shader = (
    $current_state
    | where {|row| (($row.wallpaper | str downcase) | str ends-with ".glsl") and ($row.wallpaper | path exists) }
    | first
    | get wallpaper?
    | default ""
  )

  if ($preferred_shader | is-not-empty) {
    remember-shader $preferred_shader
    return $preferred_shader
  }

  let source_record = (get-render-source $lines)
  if (
    ($source_record != null)
    and (($source_record.wallpaper | str downcase) | str ends-with ".glsl")
    and ($source_record.wallpaper | path exists)
  ) {
    remember-shader $source_record.wallpaper
    return $source_record.wallpaper
  }

  if ($neowall_config_file | path exists) {
    let configured_shader = (
      open $neowall_config_file
      | lines
      | where {|line| (($line | str trim) | str starts-with "shader ") }
      | first
      | default ""
      | str trim
      | split row " "
      | last
      | default ""
    )
    if (
      ($configured_shader | is-not-empty)
      and (($configured_shader | str downcase) | str ends-with ".glsl")
      and ($configured_shader | path exists)
    ) {
      return $configured_shader
    }
  }

  let fallback = (
    ls $neowall_shader_dir
    | where {|row| (($row.name | str downcase) | str ends-with ".glsl") }
    | sort-by name
    | get name.0?
    | default ""
  )

  if ($fallback | is-not-empty) {
    return $fallback
  }

  ""
}

def resolve-renderable-shader [lines: list<string>] {
  let preferred = (resolve-live-shader $lines)
  if (($preferred | is-not-empty) and (is-renderable-shader $preferred)) {
    return $preferred
  }

  let fallback = (
    ls $neowall_shader_dir
    | where {|row| is-renderable-shader $row.name }
    | sort-by name
    | get name.0?
    | default ""
  )

  $fallback
}

def get-output-modes [lines: list<string>] {
  let overview_open = (is-overview-open)
  let active_workspaces = (get-active-workspaces)

  get-live-output-names $lines
  | each {|output_name|
      let has_window = if $overview_open {
        false
      } else {
        ($active_workspaces | any {|ws|
          (($ws.output? | default "") == $output_name) and (($ws.active_window_id? | default null) != null)
        })
      }
      # Freeze each output as soon as it has a visible window. Outputs without
      # a window continue using the live shader.
      let mode = if $has_window { "static" } else { "shader" }

      {
        output: $output_name
        mode: $mode
      }
    }
}

def build-neowall-config [output_modes: list<any>, live_shader: string] {
  mut lines = [
    "# Auto-generated by neowall-dms-sync.nu"
    "# Do not edit manually."
    ""
  ]

  # Keep a valid default for every output, including outputs that appear after
  # a hotplug/reconfigure and therefore are not in the old state file yet.
  let shader_speed = (get-shader-speed)
  $lines = ($lines | append "default {")
  $lines = ($lines | append $"  shader ($live_shader)")
  $lines = ($lines | append $"  shader_speed ($shader_speed)")
  $lines = ($lines | append "  pause_on_fullscreen true")
  $lines = ($lines | append "}")
  $lines = ($lines | append "")
  $lines = ($lines | append "output {")

  for row in $output_modes {
    if $row.mode == "static" {
      $lines = ($lines | append $"  ($row.output) {")
      $lines = ($lines | append $"    path (get-output-picture $row.output)")
      $lines = ($lines | append "    mode fill")
      $lines = ($lines | append "  }")
    } else {
      $lines = ($lines | append $"  ($row.output) {")
      $lines = ($lines | append $"    shader ($live_shader)")
      $lines = ($lines | append $"    shader_speed (get-shader-speed)")
      $lines = ($lines | append "    pause_on_fullscreen true")
      $lines = ($lines | append "  }")
    }
  }

  $lines = ($lines | append "}")

  $lines | str join "\n"
}

def apply-output-modes [lines: list<string>] {
  let output_modes = (get-output-modes $lines)
  let live_shader = (resolve-live-shader $lines)
  if ($live_shader | is-empty) {
    notify-sync "critical" "NeoWall Sync Failed" "No usable shader was available for live outputs"
    return
  }
  let target_signature = (
    $output_modes
    | each {|row| $"($row.output)=($row.mode)" }
    | str join "|"
  )
  let current_signature = if ($mode_file | path exists) {
    open $mode_file | str trim
  } else {
    ""
  }

  let generated_config = (build-neowall-config $output_modes $live_shader)
  let existing_config = if ($neowall_config_file | path exists) {
    open $neowall_config_file
  } else {
    ""
  }
  let config_changed = ($generated_config != $existing_config)
  let service_active = (is-systemctl-user-active "neowall.service")

  if (not $config_changed) and ($target_signature == $current_signature) and $service_active {
    return
  }

  $generated_config | save --force $neowall_config_file

  if (safe-neowall-restart) {
    $target_signature | save --force $mode_file
  } else {
    notify-sync "critical" "NeoWall Sync Failed" "Failed to apply per-output NeoWall configuration"
  }
}

def sync-once [] {
  let state_file = resolve-state-file
  if ($state_file | is-empty) {
    return
  }

  let lines = read-state-lines $state_file
  let source_record = (get-render-source $lines)
  if ($source_record == null) {
    return
  }

  let wallpaper_path = ($source_record.wallpaper)
  let cycle_index = ($source_record.cycle_index)
  let signature = $"($source_record.output)|($wallpaper_path)|($cycle_index)"
  let previous_signature = if ($signature_file | path exists) {
    open $signature_file | str trim
  } else {
    ""
  }

  if $signature == $previous_signature {
    return
  }

  sleep 2sec

  let state_file_after = resolve-state-file
  if ($state_file_after | is-empty) {
    return
  }

  let lines_after = read-state-lines $state_file_after
  let source_record_after = (get-render-source $lines_after)
  if ($source_record_after == null) {
    return
  }

  let wallpaper_path_after = ($source_record_after.wallpaper)
  let cycle_index_after = ($source_record_after.cycle_index)
  let stable_signature = $"($source_record_after.output)|($wallpaper_path_after)|($cycle_index_after)"
  let current_signature = if ($signature_file | path exists) {
    open $signature_file | str trim
  } else {
    ""
  }

  if ($stable_signature == $current_signature) and (not (is-exported-picture $wallpaper_path_after)) {
    return
  }

  mut rendered = false
  mut status_message = ""

  if (is-exported-picture $wallpaper_path_after) {
    # A generated PNG is an output freeze, not a new wallpaper source. Rebuild
    # it from the real shader, then let output modes decide per monitor.
    let render_shader_path = (resolve-live-shader $lines_after)
    if (($render_shader_path | is-empty) or (not ($render_shader_path | path exists))) {
      $stable_signature | save --force $signature_file
      return
    }

    let rendered = (ensure-all-output-images $lines_after $render_shader_path)
    if $rendered {
      let _ = (update-shared-picture-link $lines_after)
      let dms_picture = $picture
      if ($dms_picture | path exists) and (safe-dms-set $dms_picture $lines_after) {
        $stable_signature | save --force $signature_file
        apply-output-modes $lines_after
      }
    } else {
      $stable_signature | save --force $signature_file
    }
    return
  } else if (($wallpaper_path_after | is-not-empty) and ($wallpaper_path_after | path exists)) {
    let lowered = ($wallpaper_path_after | str downcase)
    $rendered = (ensure-all-output-images $lines_after $wallpaper_path_after)
    if (
      ($lowered | str ends-with ".png")
      or ($lowered | str ends-with ".jpg")
      or ($lowered | str ends-with ".jpeg")
      or ($lowered | str ends-with ".webp")
      or ($lowered | str ends-with ".bmp")
    ) {
      $status_message = if $rendered {
        $"Updated per-output wallpaper images from: ($wallpaper_path_after | path basename)"
      } else {
        $"Failed to update per-output wallpaper images from: ($wallpaper_path_after | path basename)"
      }
    } else if ($lowered | str ends-with ".glsl") {
      let render_shader_path = (resolve-live-shader $lines_after)
      $status_message = if $rendered and ($render_shader_path | is-not-empty) {
        $"Rendered per-output shader images from: ($render_shader_path | path basename)"
      } else {
        $"Failed to render per-output shader images for: ($wallpaper_path_after | path basename)"
      }
    } else {
      $status_message = $"Unsupported wallpaper type: ($wallpaper_path_after | path basename)"
    }
  } else {
    $status_message = "Wallpaper path missing from neowall state"
  }

  let _ = (update-shared-picture-link $lines_after)
  let dms_picture = $picture

  if $rendered and ($dms_picture | path exists) {
    if (safe-dms-set $dms_picture $lines_after) {
      $stable_signature | save --force $signature_file
      apply-output-modes $lines_after
      notify-sync "normal" "NeoWall Sync Complete" $status_message
    } else {
      notify-sync "critical" "NeoWall Sync Failed" "DMS rejected the rendered wallpaper"
    }
  } else {
    notify-sync "critical" "NeoWall Sync Failed" $status_message
  }
}

mut last_observed = ""

loop {
  let state_file = resolve-state-file
  let loop_lines = if ($state_file | is-not-empty) {
    read-state-lines $state_file
  } else {
    []
  }

  if ($state_file | is-not-empty) {
    let source_record = (get-render-source $loop_lines)
    if ($source_record != null) {
      let observed_signature = $"($source_record.output)|($source_record.wallpaper)|($source_record.cycle_index)"
      if $observed_signature != $last_observed {
        $last_observed = $observed_signature
        try {
          sync-once
        } catch {
          notify-sync "critical" "NeoWall Sync Failed" "Unexpected watcher error"
        }
      }
    }
  }

  try {
    if (($loop_lines | length) > 0) {
      apply-output-modes $loop_lines
    }
  } catch {
  }

  sleep 1sec
}
