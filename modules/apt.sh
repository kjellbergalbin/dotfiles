install_homebrew() {
    if ! command -v brew &>/dev/null; then
        step "Installing Homebrew..."
        if [[ "$OS" == "Linux" ]] && $NO_SUDO; then
            local brew_home="$HOME/.homebrew"
            [[ -d "$brew_home" ]] || git clone https://github.com/Homebrew/brew "$brew_home"
            eval "$("$brew_home/bin/brew" shellenv)"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            for brew_prefix in /opt/homebrew /usr/local; do
                if [[ -x "$brew_prefix/bin/brew" ]]; then
                    eval "$("$brew_prefix/bin/brew" shellenv)"
                    break
                fi
            done
        fi
    fi

    command -v jq &>/dev/null || brew install jq
}

install_base_packages() {
    step "Installing base packages..."
    sudo apt-get update -q
    sudo apt-get install -y build-essential git curl wget unzip gnupg jq
}
