install_starship() {
    if command -v starship &>/dev/null; then
        info "starship already installed: $(command -v starship)"
        return
    fi
    step "Installing starship..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install starship
    else
        local installer="$WORKDIR/install-starship.sh"
        curl -fsSL https://starship.rs/install.sh -o "$installer"
        sh "$installer" --yes
    fi
}
