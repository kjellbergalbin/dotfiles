# ---- Prompt ----
# Use the built-in "fish_prompt" or set a simple custom one
function fish_prompt
    set_color brgreen
    echo -n (whoami)" "
    set_color green
    echo -n (prompt_pwd)

    # Git info
    set_color brblue
    echo -n (__fish_git_prompt)   
   
    set_color normal
    echo -n "> "
end

if test -d /opt/homebrew/bin
    set -gx PATH /opt/homebrew/bin $PATH
end

# Optional: make sure Homebrew’s bash is first
if test -x /opt/homebrew/bin/bash
    set -gx PATH /opt/homebrew/bin $PATH
end


# ---- Aliases ----
alias ll="ls -lh"
alias la="ls -lah"
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"

alias gstat="git status"
alias gpush="git push"
alias gpull="git pull"
alias gs="git switch"
alias create="git switch -c"
alias log="git log --oneline"

alias sherwood="git switch sherwood"
alias develop="sherwood"

alias v="vim"
alias spray="./db-spray.sh"
alias spray-old="./spray.sh -s"
alias run-all="./run.sh -ldb"
alias cli-tool="docker run -i --shm-size=2g --network veritrade_internal -e VERITRADE_CLUSTER_ADDRESSES=172.16.202.2 -e VERITRADE_MIRROR_ADDRESSES=172.16.202.5 -e VERITRADE_CMD_TEST=true -t ghcr.io/vermicfintech/veritrade-tex-cmd -i"
alias activate="source venv/bin/activate.fish"

alias veritrade="cd ~/Repositories/veritrade"
alias web-veritrade="cd ~/Repositories/veritrade/tex/web/client"
alias vericap="cd ~/Repositories/vericap"
alias veriload="cd ~/Repositories/veriload"

# ---- Environment variables ----
set -gx EDITOR vim
set -gx VISUAL vim
set -gx PAGER less

# ---- Homebrew completions (optional) ----
if test -d /opt/homebrew/share/fish/completions
    set -gx fish_complete_path /opt/homebrew/share/fish/completions $fish_complete_path
end

# ---- Custom command ----
function export
    if [ $argv ] 
        set var (echo $argv | cut -f1 -d=)
        set val (echo $argv | cut -f2 -d=)
        set -g -x $var $val
    else
        echo 'export var=value'
    end
end


function gc --description "Add all and commit with a message; optional spotless first"
    # Parse options:
    # -s / --spotless  : run ./gradlew spotless before adding & committing
    # -h / --help      : show usage
    argparse 's/spotless' 'h/help' -- $argv
    or return

    if set -q _flag_help
        echo "Usage:"
        echo "  gc \"commit message\""
        echo "  gc -s \"commit message\"        # run ./gradlew spotless first"
        return 0
    end

    # Ensure a commit message is provided (remaining args after options)
    if test (count $argv) -eq 0
        echo "gc: missing commit message."
        echo "Try: gc \"your message\" or gc -s \"your message\""
        return 1
    end

    # Support multi-word commit messages without needing extra quotes if you want
    set commit_message (string join ' ' -- $argv)

    # Optional spotless step
    if set -q _flag_spotless
        if test -x ./gradlew
            echo "Running ./gradlew spotless…"
            ./gradlew spotlessApply
            if test $status -ne 0
                echo "gc: spotless failed; aborting."
                return 1
            end
        else
            echo "gc: ./gradlew not found or not executable; skipping spotless."
        end
    end

    # Stage and commit
    echo "Staging changes (git add .)…"
    git add .
    if test $status -ne 0
        echo "gc: git add failed."
        return 1
    end

    echo "Committing: $commit_message"
    git commit -m "$commit_message"
end

function rebase --description "Rebase changes to HEAD"
   # Parse options:
   # -d / develop	: fetch and rebase develop to HEAD
   # -s / stash		: stash current changes before rebasing
   # -i / interactive 	: interative rebase
   # -h / help		: show usage
   argparse 'd/develop' 's/stash' 'h/help' 'i/interactive' -- $argv
   or return

   if set -q _flag_help
       echo "Usage:"
       echo "   rebase [<commit>]"
       echo "   rebase -s [<commit>]    # stash current changes before rebasing"
       echo "   rebase -d		# rebase from origin/develop"
       return 0
   end

   if set -q _flag_stash
       echo "Stash current changes"
       git add .
       git stash
   end 

   if set -q _flag_develop
       echo "Rebasing from origin/sherwood"
       git fetch
       git rebase origin/sherwood $_flag_interactive
   else
       # Ensure commit is not empty
       if test (count $argv) -eq 0
	   echo "rebase: missing commit to rebase from"
	   echo "Try: rebase develop"
       else 
           git rebase $argv $_flag_interactive
       end
   end

   if set -q _flag_stash
       echo "Reinstating changes"
       git stash pop
   end
end



function gpush --description "Push local changes to GitHub; optional force with lease"
    # Parse options:
    # -f / --force	: run command with force flag
    # -h / --help       : show usage
    argparse 'f/force' 'h/help' -- $argv
    or return

    if set -q _flag_help
        echo "Usage:"
        echo "  gpush"
        echo "  gpush -f	# run with flag force-with-lease"
        return 0
    end

    if set -q _flag_force
	echo "Pushing changes with force…"
	git push --force-with-lease
    else
	echo "Pushing changes…"
        git push
    end
end

function rebuild
    echo "🔨 Building with gradle..."
    ./build-images.sh -b

    echo "🚀 Starting system (no monitoring)..."
    run-all

    echo "✅ Rebuild finished!"
end

function rebuildw
     echo "🔨 Building web with gradle..."
    ./build-images.sh -b -s web-server

    echo "🚀 Starting system (no monitoring)..."
    run-all

    echo "✅ Rebuild finished!"
end

function rebuildr
     echo "🔨 Building refdata with gradle..."
    ./build-images.sh -b -s reference-data

    echo "🚀 Starting system (no monitoring)..."
    run-all

    echo "✅ Rebuild finished!"
end 

function rebuilda
    echo "🔨 Building with gradle..."
    ./build-images.sh -b

    echo "🧹 Cleaning old system..."
    ./run.sh -w

    echo "🚀 Starting system (no monitoring)..."
    run-all

    echo "✅ Rebuild finished!"
end

function restart
   echo "🧹 Cleaning old system..."
    ./run.sh -w

    echo "🚀 Starting system (no monitoring)..."
    run-all
end

function conan-rebuild
    echo "Configuring the build..."
    conan install --build missing -pr gcc17Release .

    echo "Building the project..."
    conan build -pr gcc17Release .

    echo "✅ Rebuild finished!"
end

function rebase-origin
    git stash
    git fetch origin
    git rebase origin/develop
    git stash pop
end

starship init fish | source
