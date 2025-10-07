let is_git_repo = if ($env.PWD | path exists) {
    ($env.PWD | path join ".git" | path exists)
} else {
    false
}

if $is_git_repo {
   onefetch
} else {
    pfetch
}


def start_zellij [] {
  if ('ZELLIJ' not-in ($env | columns) and 'TERM' in ($env | columns)) {
    let sessions = (
      zellij ls
      | lines
      | str replace -r '^(.*?)\s*\[.*$' '$1'
      | ansi strip
    )

    let session = (
      zellij ls
      | fzf --ansi --print-query
      | str trim
      | str replace -r '^(.*?)\s*\[.*$' '$1'
      | ansi strip
    )

    # Cancel if no session is selected
    if ($session | is-empty) {
      return
    }

    if $session in $sessions {
      zellij attach $session
    } else {
      zellij attach $session --create
    }
  }
}

# Only start zellij if not in a login shell
if (not $nu.is-login) {
    start_zellij
}


