#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FISH_CONFIG_DIR="$HOME/.config/fish"

mkdir -p "$FISH_CONFIG_DIR/conf.d" "$FISH_CONFIG_DIR/functions"

ln -sf "$DOTFILES_DIR/fish/config.fish" "$FISH_CONFIG_DIR/config.fish"

for f in "$DOTFILES_DIR/fish/conf.d/"*.fish; do
    ln -sf "$f" "$FISH_CONFIG_DIR/conf.d/$(basename "$f")"
done

for f in "$DOTFILES_DIR/fish/functions/"*.fish; do
    ln -sf "$f" "$FISH_CONFIG_DIR/functions/$(basename "$f")"
done

echo "Fish config synced from $DOTFILES_DIR/fish"
