#!/usr/bin/env nu

const repo_url = "https://github.com/artrixdotdev/dotfiles.git"
const dotfiles_dir_name = "dotfiles"

def banner [] {
  clear
  print $"(ansi magenta_bold)╭────────────────────────────────────────────╮(ansi reset)"
  print $"(ansi magenta_bold)│        Artrix Arch Dotfiles Setup          │(ansi reset)"
  print $"(ansi magenta_bold)╰────────────────────────────────────────────╯(ansi reset)"
  print $"(ansi cyan)Requires: Arch Linux, paru, nushell, zellij(ansi reset)"
  print ""
}

def step [name: string] {
  print $"(ansi green_bold)▶(ansi reset) ($name)"
}

def warn [message: string] {
  print $"(ansi yellow_bold)!(ansi reset) ($message)"
}

def fail [message: string] {
  print $"(ansi red_bold)✗ ($message)(ansi reset)"
  exit 1
}

def confirm [prompt: string] {
  let answer = (input $"(ansi cyan)?(ansi reset) ($prompt) [y/N] " | str downcase | str trim)
  $answer in ["y" "yes"]
}

def ensure-command [name: string] {
  if (which $name | is-empty) {
    fail $"Required command not found: ($name)"
  }
}

def flatten-package-table [table: record] {
  $table
  | transpose group packages
  | each { |row| $row.packages }
  | flatten
}

def load-deps [deps_file: path] {
  if not ($deps_file | path exists) {
    fail $"Missing dependency file: ($deps_file)"
  }

  let deps = (open $deps_file)
  if "packages" not-in ($deps | columns) {
    fail "deps.toml must contain a [packages] table"
  }

  $deps
}

def select-packages [deps: record] {
  let required = (flatten-package-table $deps.packages)
  let optional = if "optional" in ($deps | columns) { $deps.optional } else { {} }
  let selected_optional = if ($optional | is-empty) {
    []
  } else {
    print ""
    print $"(ansi magenta_bold)Optional package groups(ansi reset)"
    $optional
    | transpose group packages
    | each { |row|
      print $"(ansi light_gray)($row.group):(ansi reset) (($row.packages | str join ', '))"
      if (confirm $"Install optional group '($row.group)'?") { $row.packages } else { [] }
    }
    | flatten
  }

  $required
  | append $selected_optional
  | uniq
  | sort
}

def run-or-fail [description: string, command: closure] {
  step $description
  let result = (do $command | complete)
  if $result.exit_code != 0 {
    if ($result.stderr | str trim | is-not-empty) { print $result.stderr }
    fail $"Failed: ($description)"
  }
}

def install-packages [packages: list<string>] {
  if ($packages | is-empty) {
    warn "No packages found in deps.toml"
    return
  }

  print $"(ansi light_gray)Packages:(ansi reset) (($packages | str join ', '))"
  if (confirm "Install these packages with paru?") {
    run-or-fail "Installing packages with paru" { ^paru -S --needed ...$packages }
  } else {
    warn "Skipped package installation"
  }
}

def configure-chaotic-aur [] {
  print ""
  print $"(ansi magenta_bold)Chaotic-AUR(ansi reset)"
  print "Chaotic-AUR can make AUR-heavy installs faster by using prebuilt packages."
  if not (confirm "Enable Chaotic-AUR before installing packages?") { return }

  run-or-fail "Installing Chaotic-AUR keyring" {
    ^sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  }
  run-or-fail "Signing Chaotic-AUR keyring" {
    ^sudo pacman-key --lsign-key 3056513887B78AEB
  }
  run-or-fail "Installing Chaotic-AUR packages" {
    ^sudo pacman -U --needed --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
  }

  let pacman_conf = "/etc/pacman.conf"
  let has_repo = (open --raw $pacman_conf | str contains "[chaotic-aur]")
  if $has_repo {
    warn "Chaotic-AUR is already present in /etc/pacman.conf"
  } else {
    run-or-fail "Adding Chaotic-AUR to pacman.conf" {
      "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | ^sudo tee --append $pacman_conf
    }
  }

  run-or-fail "Refreshing package databases" { ^sudo pacman -Syy }
}

def clone-dotfiles [dotfiles_dir: path] {
  if ($dotfiles_dir | path exists) {
    warn $"($dotfiles_dir) already exists"
    if not (confirm "Pull latest changes in the existing repo?") { return }
    run-or-fail "Updating ~/dotfiles" { ^git -C $dotfiles_dir pull --ff-only }
    return
  }

  run-or-fail $"Cloning dotfiles into ($dotfiles_dir)" { ^git clone $repo_url $dotfiles_dir }
}

def safe-symlink [source: path, target: path] {
  if not ($source | path exists) {
    warn $"Missing source: ($source)"
    return
  }

  mkdir ($target | path dirname)

  if ($target | path exists) {
    if (($target | path type) == "symlink") {
      rm $target
    } else {
      let backup = $"($target).bak.(date now | format date '%Y%m%d%H%M%S')"
      warn $"Moving existing target to ($backup)"
      mv $target $backup
    }
  }

  ln -s $source $target
  print $"  (ansi green)linked(ansi reset) ($target)"
}

def link-scripts [dotfiles_dir: path] {
  let scripts_dir = ($dotfiles_dir | path join "scripts")
  let bin_dir = ($env.HOME | path join ".local" "bin")

  if not ($scripts_dir | path exists) {
    warn $"No scripts directory found: ($scripts_dir)"
    return
  }

  mkdir $bin_dir
  ls $scripts_dir | where type == file | each { |script|
    let target = ($bin_dir | path join ($script.name | path basename))
    safe-symlink $script.name $target
  }
}

def link-config [dotfiles_dir: path] {
  let config_dir = ($dotfiles_dir | path join ".config")
  let target_dir = ($env.HOME | path join ".config")

  if not ($config_dir | path exists) {
    warn $"No .config directory found: ($config_dir)"
    return
  }

  mkdir $target_dir
  ls $config_dir | each { |item|
    let target = ($target_dir | path join ($item.name | path basename))
    safe-symlink $item.name $target
  }
}

def install-services [dotfiles_dir: path] {
  let services_dir = ($dotfiles_dir | path join "services")
  let user_systemd_dir = ($env.HOME | path join ".config" "systemd" "user")

  if not ($services_dir | path exists) {
    warn $"No services directory found: ($services_dir)"
    return
  }

  mkdir $user_systemd_dir
  ls $services_dir | where name =~ '\.service$' | each { |service|
    let name = ($service.name | path basename)
    safe-symlink $service.name ($user_systemd_dir | path join $name)
  }

  run-or-fail "Reloading user systemd" { ^systemctl --user daemon-reload }

  ls $services_dir | where name =~ '\.service$' | each { |service|
    let name = ($service.name | path basename)
    print $"  (ansi cyan)enable(ansi reset) ($name)"
    let result = (^systemctl --user enable $name | complete)
    if $result.exit_code != 0 {
      warn $"Could not enable ($name); adding it to default.target instead"
      let linked_service = ($user_systemd_dir | path join $name)
      ^systemctl --user add-wants default.target $linked_service
    }
  }
}

def show-summary [dotfiles_dir: path] {
  print ""
  print $"(ansi green_bold)Setup complete.(ansi reset)"
  print $"Dotfiles: ($dotfiles_dir)"
  print "Linked: scripts -> ~/.local/bin, ~/dotfiles/.config/* -> ~/.config/*"
  print "Services: installed under ~/.config/systemd/user"
  print ""
  print $"(ansi light_gray)Start or restart your user session when you are ready.(ansi reset)"
}

def main [] {
  banner
  ensure-command "nu"
  ensure-command "zellij"
  ensure-command "paru"
  ensure-command "git"

  let script_dir = ($env.CURRENT_FILE | path dirname)
  let deps_file = ($script_dir | path join "deps.toml")
  let dotfiles_dir = ($env.HOME | path join $dotfiles_dir_name)
  let deps = (load-deps $deps_file)
  let packages = (select-packages $deps)

  print "This will install packages, clone/update ~/dotfiles, replace selected paths with symlinks, and install user services."
  if not (confirm "Continue?") { exit 0 }

  configure-chaotic-aur
  install-packages $packages
  clone-dotfiles $dotfiles_dir

  if (confirm "Symlink scripts into ~/.local/bin?") { step "Linking scripts"; link-scripts $dotfiles_dir }
  if (confirm "Symlink ~/dotfiles/.config entries into ~/.config?") { step "Linking config"; link-config $dotfiles_dir }
  if (confirm "Install user systemd services?") { step "Installing services"; install-services $dotfiles_dir }

  show-summary $dotfiles_dir
}
