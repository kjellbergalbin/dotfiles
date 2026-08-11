# dotfiles

Personal setup scripts for macOS and Debian/Ubuntu (including WSL). Installs
fish, starship, fonts, git/SSH config, and syncs fish config via symlinks.

## Quick start

On a fresh machine, `curl` may not be installed yet. Install it first, then
fetch and run the bootstrap script:

```sh
command -v curl >/dev/null || (sudo apt-get update -q && sudo apt-get install -y curl)
curl -fsSL https://raw.githubusercontent.com/kjellbergalbin/dotfiles/main/bootstrap.sh | bash
```

(macOS ships with `curl` preinstalled, so the first line is a no-op there.)

This clones the repo into `~/Repositories/dotfiles` (pulling latest if it's
already there) and runs `install.sh`.

Already have the repo cloned? Just run:

```sh
./install.sh
```

Both scripts are safe to re-run.

## What it sets up

- **Homebrew** (macOS) or base build tools via `apt` (Linux)
- **fish** as the default shell
- **starship** prompt
- **JetBrains Mono Nerd Font** (skipped in headless/server mode or WSL, where
  it's installed on the Windows host instead)
- **SSH key + config**: generates `~/.ssh/id_ed25519` if missing, adds it to
  the macOS Keychain or a Linux ssh-agent, and prints the public key at the
  end to add to GitHub/GitLab
- **fish config sync**: symlinks `fish/config.fish`, `fish/conf.d/*`, and
  `fish/functions/*` from this repo into `~/.config/fish/`

Detects WSL and headless Linux (no `DISPLAY`/`WAYLAND_DISPLAY`) and adjusts
steps accordingly (e.g. skips fonts, sets up Git Credential Manager on WSL).

## Structure

```
bootstrap.sh          entry point for a fresh machine — clones this repo, runs install.sh
install.sh            main install script, run from an already-cloned repo
modules/               one file per concern, sourced by install.sh
  apt.sh               Homebrew / base apt packages
  fish.sh              install fish, set as default shell, sync config
  fonts.sh             Nerd Font install
  git.sh               WSL git credential manager setup
  ssh.sh               SSH key generation + agent setup
  starship.sh          starship prompt install
fish/
  config.fish          main fish config
  conf.d/               autoloaded fish config snippets
  functions/             fish functions
```

## Private companion repo

Anything sensitive (credential rotation scripts, internal config) lives in a
separate private repo, [dotfiles-private](https://github.com/kjellbergalbin/dotfiles-private),
kept out of this public repo on purpose. If cloned at
`~/Repositories/dotfiles-private`, `install.sh` will detect it and surface any
available follow-up steps (e.g. rotating a Claude Code API key). On a brand
new machine, `install.sh` prints the clone command to run once your new SSH
key has been added to GitHub.
