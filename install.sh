#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
IS_WSL=false
if [[ "$OS" == "Linux" ]]; then
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=true
    fi
fi

# Detect server/headless environment: no DISPLAY, WAYLAND_DISPLAY, or macOS GUI session
SERVER_MODE=false
if [[ "$OS" == "Linux" ]]; then
    if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "$IS_WSL" == false ]]; then
        SERVER_MODE=true
    fi
fi

WORKDIR=""
PRIVATE_REPO_MISSING=false
FISH_ONLY=false
[[ "${1:-}" == "--fish-only" ]] && FISH_ONLY=true

step() { echo "==> $*"; }
info() { echo "    $*"; }

source "$DOTFILES_DIR/modules/apt.sh"
source "$DOTFILES_DIR/modules/fish.sh"
source "$DOTFILES_DIR/modules/git.sh"
source "$DOTFILES_DIR/modules/ssh.sh"
source "$DOTFILES_DIR/modules/starship.sh"
if ! $SERVER_MODE; then
    source "$DOTFILES_DIR/modules/fonts.sh"
fi

run_private_hooks() {
    local private_dir="$HOME/Repositories/dotfiles-private"
    if [[ -f "$private_dir/rotate-claude-key.sh" ]]; then
        info "Found dotfiles-private: run '$private_dir/rotate-claude-key.sh <key>' to set your Claude Code key."
    elif [[ ! -d "$private_dir" ]]; then
        PRIVATE_REPO_MISSING=true
    fi
}

main() {
    WORKDIR="$(mktemp -d)"
    trap 'rm -rf "$WORKDIR"' EXIT

    if $SERVER_MODE; then
        info "Server/headless mode detected — skipping fonts and desktop modules."
    fi

    [[ "$OS" == "Darwin" ]] && install_homebrew
    [[ "$OS" == "Linux" ]]  && install_base_packages
    install_fish
    set_default_shell
    install_starship
    if ! $SERVER_MODE; then
        install_font
    fi
    sync_fish_config
    if ! $FISH_ONLY; then
        setup_ssh
        [[ "$IS_WSL" == true ]] && setup_git_credentials
        run_private_hooks

        echo ""
        echo "Your SSH public key — add this to GitHub/GitLab/etc.:"
        echo "──────────────────────────────────────────────────────"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo "──────────────────────────────────────────────────────"
        if $PRIVATE_REPO_MISSING; then
            echo "Once the key above is added to GitHub, fetch dotfiles-private and rotate your Claude Code key:"
            echo "  git clone git@github.com:kjellbergalbin/dotfiles-private.git ~/Repositories/dotfiles-private"
            echo "  ~/Repositories/dotfiles-private/rotate-claude-key.sh <key>"
            echo ""
        fi
    fi

    echo "Done! Re-login or open a new terminal to start using fish."
}

main "$@"
