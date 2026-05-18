if test -d /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end

set -gx EDITOR vim
set -gx VISUAL vim
set -gx PAGER less

if test -d /opt/homebrew/share/fish/completions
    set -gx fish_complete_path /opt/homebrew/share/fish/completions $fish_complete_path
end

starship init fish | source
