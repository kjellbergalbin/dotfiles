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
