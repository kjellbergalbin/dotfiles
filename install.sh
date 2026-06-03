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

WORKDIR=""

step() { echo "==> $*"; }
info() { echo "    $*"; }

# ── Homebrew (macOS) ──────────────────────────────────────────────────────────
install_homebrew() {
    command -v brew &>/dev/null && return
    step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for brew_prefix in /opt/homebrew /usr/local; do
        if [[ -x "$brew_prefix/bin/brew" ]]; then
            eval "$("$brew_prefix/bin/brew" shellenv)"
            break
        fi
    done
}

# ── Base packages (Linux) ─────────────────────────────────────────────────────
install_base_packages() {
    step "Installing base packages..."
    sudo apt-get update -q
    sudo apt-get install -y build-essential git curl wget unzip gnupg
}

# ── Fish ──────────────────────────────────────────────────────────────────────
install_fish() {
    if command -v fish &>/dev/null; then
        info "fish already installed: $(command -v fish)"
        return
    fi
    step "Installing fish..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install fish
    elif [[ "$OS" == "Linux" ]]; then
        echo 'deb https://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/ /' \
            | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
        curl -fsSL https://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/Release.key \
            | gpg --dearmor \
            | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
        sudo apt-get update -q
        sudo apt-get install -y fish
    fi
}

set_default_shell() {
    local fish_path
    fish_path="$(command -v fish)"
    if ! grep -qxF "$fish_path" /etc/shells; then
        step "Registering $fish_path in /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells
    fi
    if [[ "$SHELL" != "$fish_path" ]]; then
        step "Setting default shell to fish..."
        chsh -s "$fish_path"
    fi
}

# ── Starship ──────────────────────────────────────────────────────────────────
install_starship() {
    if command -v starship &>/dev/null; then
        info "starship already installed: $(command -v starship)"
        return
    fi
    step "Installing starship..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install starship
    else
        # Download to isolated temp dir rather than piping directly into sh
        local installer="$WORKDIR/install-starship.sh"
        curl -fsSL https://starship.rs/install.sh -o "$installer"
        sh "$installer" --yes
    fi
}

# ── JetBrains Mono Nerd Font ──────────────────────────────────────────────────
install_font() {
    if [[ "$IS_WSL" == true ]]; then
        info "WSL detected: install JetBrains Mono Nerd Font on Windows manually."
        info "Download from: https://www.nerdfonts.com/font-downloads"
        info "Then set it in Windows Terminal: Settings > Profiles > Appearance > Font face."
        return
    fi

    if [[ "$OS" == "Darwin" ]]; then
        if fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd" || \
           ls ~/Library/Fonts/JetBrainsMonoNerd* &>/dev/null 2>&1; then
            info "JetBrains Mono Nerd Font already installed."
            return
        fi
        step "Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font

    elif [[ "$OS" == "Linux" ]]; then
        local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
        if fc-list 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
            info "JetBrains Mono Nerd Font already installed."
            return
        fi
        step "Installing JetBrains Mono Nerd Font..."
        mkdir -p "$font_dir"
        curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
            -o "$WORKDIR/JetBrainsMono.zip"
        unzip -o "$WORKDIR/JetBrainsMono.zip" -d "$font_dir" '*.ttf'
        fc-cache -f "$font_dir"
    fi
}

# ── SSH key + agent ───────────────────────────────────────────────────────────
setup_ssh() {
    local ssh_key="$HOME/.ssh/id_ed25519"
    local ssh_config="$HOME/.ssh/config"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ ! -f "$ssh_key" ]]; then
        step "Generating SSH key (~/.ssh/id_ed25519)..."
        ssh-keygen -t ed25519 -C "$(git config --global user.email 2>/dev/null || hostname)" -f "$ssh_key"
    else
        info "SSH key already exists: $ssh_key"
    fi

    # Enforce permissions unconditionally
    chmod 600 "$ssh_key"
    [[ -f "$ssh_key.pub" ]] && chmod 644 "$ssh_key.pub"

    if ! grep -q "^Host \*" "$ssh_config" 2>/dev/null; then
        step "Writing ~/.ssh/config..."
        {
            echo "Host *"
            echo "  AddKeysToAgent yes"
            [[ "$OS" == "Darwin" ]] && echo "  UseKeychain yes"
            echo "  IdentityFile $ssh_key"
        } >> "$ssh_config"
    fi
    chmod 600 "$ssh_config"

    mkdir -p "$HOME/.config/fish/conf.d"

    if [[ "$OS" == "Darwin" ]]; then
        step "Adding SSH key to macOS Keychain..."
        ssh-add --apple-use-keychain "$ssh_key"
    else
        # Use a stable socket path in ~/.ssh so it's never world-writable.
        # The agent starts once per WSL/login session; ssh-add prompts for
        # the passphrase only when the socket doesn't exist yet.
        cat > "$HOME/.config/fish/conf.d/ssh-agent.fish" << 'FISH'
set -gx SSH_AUTH_SOCK $HOME/.ssh/agent.sock
if not test -S $SSH_AUTH_SOCK
    rm -f $SSH_AUTH_SOCK
    ssh-agent -a $SSH_AUTH_SOCK >/dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519
end
FISH
    fi
}

# ── Git credential manager (WSL) ──────────────────────────────────────────────
setup_git_credentials() {
    step "Configuring Git credential manager for WSL..."
    local gcm_path=""
    for p in \
        "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe" \
        "/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"; do
        if [[ -x "$p" ]]; then
            gcm_path="$p"
            break
        fi
    done
    if [[ -n "$gcm_path" ]]; then
        git config --global credential.helper "$gcm_path"
        info "Credential helper set to: $gcm_path"
    else
        info "Warning: Git for Windows not found at expected paths."
        info "Install Git for Windows on the host, then re-run this script."
    fi
}

# ── Fish config ───────────────────────────────────────────────────────────────
sync_fish_config() {
    step "Syncing fish config..."
    local fish_dir="$HOME/.config/fish"
    mkdir -p "$fish_dir/conf.d" "$fish_dir/functions"

    ln -sf "$DOTFILES_DIR/fish/config.fish" "$fish_dir/config.fish"

    for f in "$DOTFILES_DIR/fish/conf.d/"*.fish; do
        [[ -e "$f" ]] || continue
        ln -sf "$f" "$fish_dir/conf.d/$(basename "$f")"
    done

    for f in "$DOTFILES_DIR/fish/functions/"*.fish; do
        [[ -e "$f" ]] || continue
        ln -sf "$f" "$fish_dir/functions/$(basename "$f")"
    done
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    WORKDIR="$(mktemp -d)"
    trap 'rm -rf "$WORKDIR"' EXIT

    [[ "$OS" == "Darwin" ]] && install_homebrew
    [[ "$OS" == "Linux" ]]  && install_base_packages
    install_fish
    set_default_shell
    install_starship
    install_font
    setup_ssh
    [[ "$IS_WSL" == true ]] && setup_git_credentials
    sync_fish_config

    echo ""
    echo "Your SSH public key — add this to GitHub/GitLab/etc.:"
    echo "──────────────────────────────────────────────────────"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo "──────────────────────────────────────────────────────"
    echo ""
    echo "Done! Re-login or open a new terminal to start using fish."
}

main "$@"
