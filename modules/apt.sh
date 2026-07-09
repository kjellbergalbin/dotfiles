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

install_base_packages() {
    step "Installing base packages..."
    sudo apt-get update -q
    sudo apt-get install -y build-essential git curl wget unzip gnupg
}
