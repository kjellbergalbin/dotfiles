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
