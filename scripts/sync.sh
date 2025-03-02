#!/bin/bash

DOTFILES_DIR=~/dotfiles
CONFIG_DIR=~/.config

# Ensure the dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory does not exist."
    exit 1
fi

# Loop through directories in dotfiles
for dir in "$DOTFILES_DIR"/*/; do
    # Check if the directory contains a file named ".cfg"
    if [ -f "$dir/.cfg" ]; then
        dirname=$(basename "$dir")
        ln -sfn "$dir" "$CONFIG_DIR/$dirname"
        echo "Linked: $dirname"
    fi
done

