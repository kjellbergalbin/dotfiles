#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect environment ───────────────────────────────────────────────────────
OS="$(uname -s)"
IS_WSL=false
if [[ "$OS" == "Linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

step() { echo "==> $*"; }
info() { echo "    $*"; }

# ── macOS: ensure Homebrew ───────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]] && ! command -v brew &>/dev/null; then
    step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for brew_prefix in /opt/homebrew /usr/local; do
        if [[ -x "$brew_prefix/bin/brew" ]]; then
            eval "$("$brew_prefix/bin/brew" shellenv)"
            break
        fi
    done
fi

# ── Linux: base packages ─────────────────────────────────────────────────────
if [[ "$OS" == "Linux" ]]; then
    step "Installing base packages..."
    sudo apt-get update -q
    sudo apt-get install -y build-essential git curl wget unzip gnupg
fi

# ── Install fish ─────────────────────────────────────────────────────────────
if ! command -v fish &>/dev/null; then
    step "Installing fish..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install fish
    elif [[ "$OS" == "Linux" ]]; then
        echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/ /' \
            | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
        curl -fsSL https://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/Release.key \
            | gpg --dearmor \
            | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
        sudo apt-get update -q
        sudo apt-get install -y fish
    fi
else
    info "fish already installed: $(command -v fish)"
fi

# ── Set fish as default shell ────────────────────────────────────────────────
FISH_PATH="$(command -v fish)"
if ! grep -qxF "$FISH_PATH" /etc/shells; then
    step "Registering $FISH_PATH in /etc/shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
if [[ "$SHELL" != "$FISH_PATH" ]]; then
    step "Setting default shell to fish..."
    chsh -s "$FISH_PATH"
fi

# ── Install starship ─────────────────────────────────────────────────────────
if ! command -v starship &>/dev/null; then
    step "Installing starship..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install starship
    else
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
    fi
else
    info "starship already installed: $(command -v starship)"
fi

# ── JetBrains Mono Nerd Font ─────────────────────────────────────────────────
if [[ "$IS_WSL" == true ]]; then
    info "WSL detected: install JetBrains Mono Nerd Font on Windows manually."
    info "Download from: https://www.nerdfonts.com/font-downloads"
    info "Then set it in Windows Terminal: Settings > Profiles > Appearance > Font face."
elif [[ "$OS" == "Darwin" ]]; then
    if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd" && \
       ! ls ~/Library/Fonts/JetBrainsMonoNerd* &>/dev/null 2>&1; then
        step "Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
    else
        info "JetBrains Mono Nerd Font already installed."
    fi
elif [[ "$OS" == "Linux" ]]; then
    FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
    if ! fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
        step "Installing JetBrains Mono Nerd Font..."
        mkdir -p "$FONT_DIR"
        curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
            -o /tmp/JetBrainsMono.zip
        unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR" '*.ttf'
        rm /tmp/JetBrainsMono.zip
        fc-cache -f "$FONT_DIR"
    else
        info "JetBrains Mono Nerd Font already installed."
    fi
fi

# ── WSL: Git credential manager ──────────────────────────────────────────────
if [[ "$IS_WSL" == true ]]; then
    step "Configuring Git credential manager for WSL..."
    GCM_PATH=""
    for p in \
        "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe" \
        "/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"; do
        if [[ -x "$p" ]]; then
            GCM_PATH="$p"
            break
        fi
    done
    if [[ -n "$GCM_PATH" ]]; then
        git config --global credential.helper "$GCM_PATH"
        info "Credential helper set to: $GCM_PATH"
    else
        info "Warning: Git for Windows not found at expected paths."
        info "Install Git for Windows on the host, then re-run this script."
    fi
fi

# ── Symlink fish config ───────────────────────────────────────────────────────
step "Syncing fish config..."
FISH_CONFIG_DIR="$HOME/.config/fish"
mkdir -p "$FISH_CONFIG_DIR/conf.d" "$FISH_CONFIG_DIR/functions"

ln -sf "$DOTFILES_DIR/fish/config.fish" "$FISH_CONFIG_DIR/config.fish"

for f in "$DOTFILES_DIR/fish/conf.d/"*.fish; do
    [[ -e "$f" ]] || continue
    ln -sf "$f" "$FISH_CONFIG_DIR/conf.d/$(basename "$f")"
done

for f in "$DOTFILES_DIR/fish/functions/"*.fish; do
    [[ -e "$f" ]] || continue
    ln -sf "$f" "$FISH_CONFIG_DIR/functions/$(basename "$f")"
done

echo ""
echo "Done! Re-login or open a new terminal to start using fish."
