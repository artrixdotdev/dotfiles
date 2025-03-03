#!/bin/bash

DOTFILES_DIR=$HOME/dotfiles
CONFIG_DIR=$HOME/.config

# Ensure the dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory does not exist."
    exit 1
fi
shopt -s dotglob
# Loop through directories in dotfiles
for dir in "$DOTFILES_DIR"/*/; do
    # Check if the directory contains a file named ".cfg"
    if [ -f "$dir/.cfg" ]; then
        dirname=$(basename "$dir")

        if [ "$dirname" = "home" ]; then
            # Copy files from "home" directory to $HOME
            for file in "$dir"/*; do
               echo "$file"
               [ "$file" != "$dir/.cfg" ] && [ "$file" != "$dir/.zshrc" ] && ln -sfn "$file" "$HOME/$(basename "$file")" && echo "Linked: $file -> $HOME/$(basename "$file")"
            done
            echo "Linked: home -> $HOME"

        elif [ "$dirname" = "root" ]; then
            # Copy files from "root" directory to CONFIG_DIR directly
            for file in "$dir"/*; do
                [ "$file" != "$dir/.cfg" ] && ln -sfn "$file" "$CONFIG_DIR/$(basename "$file")"
            done
            echo "Linked: root -> $CONFIG_DIR"

        else
            # Default behavior for other directories
            ln -sfn "$dir" "$CONFIG_DIR/$dirname"
            echo "Linked: $dirname -> $CONFIG_DIR/$dirname"
        fi
    fi
done

SOURCE_TEXT="source \$HOME/dotfiles/home/.zshrc"

if [ "$(head -n 1 "$HOME/.zshrc")" != "$SOURCE_TEXT" ]; then
    echo "Appending source \$HOME/dotfiles/home/.zshrc to $HOME/.zshrc"
    echo "$(echo -e $SOURCE_TEXT)$(cat "$HOME/.zshrc")" > "$HOME/.zshrc"
fi

