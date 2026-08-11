#!/usr/bin/env bash
# Fetch and run with:
#   curl -fsSL https://raw.githubusercontent.com/kjellbergalbin/dotfiles/main/bootstrap.sh | bash
set -euo pipefail

REPO_URL="https://github.com/kjellbergalbin/dotfiles.git"
REPOS_DIR="$HOME/Repositories"
DOTFILES_DIR="$REPOS_DIR/dotfiles"

step() { echo "==> $*"; }
info() { echo "    $*"; }

ensure_git() {
    command -v git &>/dev/null && return
    step "Installing git..."
    if [[ "$(uname -s)" == "Linux" ]]; then
        sudo apt-get update -q
        sudo apt-get install -y git
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        xcode-select --install
    fi
}

clone_or_update() {
    mkdir -p "$REPOS_DIR"

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        step "dotfiles already cloned, pulling latest..."
        git -C "$DOTFILES_DIR" pull --ff-only
    else
        step "Cloning dotfiles into $DOTFILES_DIR..."
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
}

main() {
    ensure_git
    clone_or_update

    step "Running install.sh..."
    exec bash "$DOTFILES_DIR/install.sh"
}

main "$@"
