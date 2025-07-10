#!/usr/bin/env nu

print "Starting dotfile installation..."
print "---"

let dotfiles_dir = $"($env.HOME)/dotfiles"
let config_dir = $"($dotfiles_dir)/.config"

# Function to safely create a symlink
def create_symlink [source_path: string, target_path: string] {
    let source_exists = ($source_path | path exists)

    if not $source_exists {
        print $"Warning: Source path does not exist: ($source_path)"
        return
    }

    let source_type = if ($source_path | path type) == "dir" { "directory" } else { "file" }

    # Ensure parent directory exists for the target
    mkdir ($target_path | path dirname)

    # Handle existing target
    if ($target_path | path exists) {
        if ($target_path | path type) == "symlink" {
            print $"Removing existing symlink: ($target_path)"
            rm $target_path
        } else if $source_type == "directory" and ($target_path | path type) == "dir" {
            print $"Moving existing directory: ($target_path) to ($target_path).bak"
            mv $target_path $"($target_path).bak"
        } else if $source_type == "file" and ($target_path | path type) == "file" {
            print $"Moving existing file: ($target_path) to ($target_path).bak"
            mv $target_path $"($target_path).bak"
        }
    }

    print $"Creating symlink: ($source_path) -> ($target_path)"
    ln -s $source_path $target_path
}

# Check if .config directory exists
if not ($config_dir | path exists) {
    print $"Error: .config directory not found at ($config_dir)"
    exit 1
}

# Process all items inside the .config directory
ls $config_dir | each { |item|
    let item_name = ($item.name | path basename)
    let source_path = $"($config_dir)/($item_name)"
    let target_path = $"($env.HOME)/.config/($item_name)"

    create_symlink $source_path $target_path
}

print "---"
print "Dotfile setup complete!"
