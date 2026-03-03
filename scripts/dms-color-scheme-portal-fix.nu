#!/usr/bin/env nu

const pref_name = "layout.css.prefers-color-scheme.content-override"
const zen_dir = "/home/artrix/.zen"
const dms_zen_css = "/home/artrix/.config/DankMaterialShell/zen.css"

def current_color_scheme [] {
  try {
    gsettings get org.gnome.desktop.interface color-scheme | str trim | str replace --all "'" ""
  } catch {
    ""
  }
}

def set_pref [file: string, name: string, value: int] {
  if not ($file | path exists) {
    return
  }

  let pref_line = ('user_pref("' + $name + '", ' + ($value | into string) + ');')
  let content = open --raw $file

  if ($content | str contains ('user_pref("' + $name + '"')) {
    $content
    | str replace --regex ('user_pref\("' + $name + '",\s*[^;]+\);') $pref_line
    | save --force $file
  } else {
    $content + "\n" + $pref_line + "\n" | save --force $file
  }
}

def css_theme_scheme [] {
  if not ($dms_zen_css | path exists) {
    return null
  }

  let css = open --raw $dms_zen_css
  let background = ($css | parse --regex '--zen-main-browser-background:\s*#(?P<hex>[0-9a-fA-F]{6})' | get hex | first)

  if ($background | is-empty) {
    return null
  }

  let r = ($background | str substring 0..2 | into int --radix 16)
  let g = ($background | str substring 2..4 | into int --radix 16)
  let b = ($background | str substring 4..6 | into int --radix 16)
  let luminance = ((0.2126 * $r) + (0.7152 * $g) + (0.0722 * $b))

  if $luminance < 128 { "prefer-dark" } else { "prefer-light" }
}

def sync_zen_content_scheme [scheme: string] {
  let value = if $scheme == "prefer-dark" { 0 } else { 1 }

  ls $zen_dir
  | where type == dir
  | each {|profile|
    set_pref ($profile.name | path join "user.js") $pref_name $value
    set_pref ($profile.name | path join "prefs.js") $pref_name $value
  }
  | ignore
}

def normalize_color_scheme [] {
  mut scheme = current_color_scheme

  if $scheme == "default" {
    $scheme = (css_theme_scheme | default "prefer-light")
    gsettings set org.gnome.desktop.interface color-scheme $scheme
  }

  sync_zen_content_scheme $scheme
}

loop {
  normalize_color_scheme
  sleep 2sec
}
