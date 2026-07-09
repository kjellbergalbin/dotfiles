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
