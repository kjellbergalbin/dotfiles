install_fish() {
    if command -v fish &>/dev/null; then
        info "fish already installed: $(command -v fish)"
        return
    fi
    step "Installing fish..."
    if [[ "$OS" == "Darwin" ]] || $NO_SUDO; then
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

    if $NO_SUDO; then
        if [[ "$SHELL" == "$fish_path" ]]; then
            return
        fi
        step "Setting default shell to fish..."
        if grep -qxF "$fish_path" /etc/shells 2>/dev/null && chsh -s "$fish_path" 2>/dev/null; then
            return
        fi
        info "chsh unavailable without sudo — launching fish automatically from login instead."
        local rc_file="$HOME/.bashrc"
        [[ -f "$rc_file" ]] || rc_file="$HOME/.profile"
        if ! grep -qF "exec \"$fish_path\" -l" "$rc_file" 2>/dev/null; then
            {
                echo ''
                echo 'if [ -t 1 ]; then'
                echo "    exec \"$fish_path\" -l"
                echo 'fi'
            } >> "$rc_file"
        fi
        return
    fi

    if ! grep -qxF "$fish_path" /etc/shells; then
        step "Registering $fish_path in /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells
    fi
    if [[ "$SHELL" != "$fish_path" ]]; then
        step "Setting default shell to fish..."
        if [[ "$OS" == "Linux" ]]; then
            # chsh authenticates via PAM against the account password, which
            # WSL users often never set — use usermod (via sudo) instead, it
            # edits /etc/passwd directly with no separate password prompt.
            sudo usermod -s "$fish_path" "$USER"
        else
            chsh -s "$fish_path"
        fi
    fi
}

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
