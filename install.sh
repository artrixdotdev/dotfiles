#!/bin/bash

echo "Starting dotfile installation..."
echo "---"

DOTFILES_DIR="$HOME/dotfiles"
GITIGNORE_PATH="$DOTFILES_DIR/.gitignore"

# Function to safely create a symlink
# Args: source_path, target_path
create_symlink() {
    local source_path="$1"
    local target_path="$2"
    local type="" # "file" or "directory"

    # Determine if source is a file or directory
    if [ -d "$source_path" ]; then
        type="directory"
    elif [ -f "$source_path" ]; then
        type="file"
    else
        echo "Warning: Source path does not exist or is not a regular file/directory: $source_path"
        return 1
    fi

    # Ensure parent directory exists for the target
    mkdir -p "$(dirname "$target_path")"

    if [ -L "$target_path" ]; then
        echo "Removing existing symlink: $target_path"
        rm "$target_path"
    elif [ "$type" == "directory" ] && [ -d "$target_path" ]; then
        echo "Moving existing directory: $target_path to $target_path.bak"
        mv "$target_path" "$target_path.bak"
    elif [ "$type" == "file" ] && [ -f "$target_path" ]; then
        echo "Moving existing file: $target_path to $target_path.bak"
        mv "$target_path" "$target_path.bak"
    fi

    echo "Creating symlink: $source_path -> $target_path"
    ln -s "$source_path" "$target_path"
}

# Read .gitignore line by line
# Look for lines that start with '!'
while IFS= read -r line; do
    # Trim whitespace from the line
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Skip empty lines or comment lines
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
    fi

    # Check if the line starts with '!'
    if [[ "$line" =~ ^! ]]; then
        # Remove the '!' prefix
        relative_path="${line#!}"

        # Adjust for "./" prefix if present
        if [[ "$relative_path" =~ ^\./ ]]; then
            relative_path="${relative_path#./}"
        fi

        SOURCE_PATH="$DOTFILES_DIR/$relative_path"
        TARGET_PATH="$HOME/$relative_path"

        # Special handling for `.config` subdirectory inside `~/dotfiles`
        # if [[ "$relative_path" =~ ^\.config/ ]]; then
        #     # The source is already correctly formed.
        #     # The target is already correctly formed (e.g., ~/.config/app)
        #     : # No special modification needed here, source/target are already correct
        # fi

        create_symlink "$SOURCE_PATH" "$TARGET_PATH"
    fi
done < "$GITIGNORE_PATH"

echo "---"
echo "Dotfile setup complete!"
echo "Please restart your terminal or source your shell configuration (e.g., 'source ~/.zshrc') for changes to take effect."
