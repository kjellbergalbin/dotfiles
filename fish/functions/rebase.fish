function rebase --description "Rebase changes to HEAD"
    argparse 'd/main' 's/stash' 'h/help' 'i/interactive' -- $argv
    or return

    if set -q _flag_help
        echo "Usage:"
        echo "   rebase [<commit>]"
        echo "   rebase -s [<commit>]    # stash current changes before rebasing"
        echo "   rebase -d               # rebase from origin/main"
        return 0
    end

    if set -q _flag_stash
        echo "Stash current changes"
        git add .
        git stash
    end

    if set -q _flag_main
        echo "Rebasing from origin/main"
        git fetch
        git rebase origin/main $_flag_interactive
    else
        if test (count $argv) -eq 0
            echo "rebase: missing commit to rebase from"
            echo "Try: rebase main or rebase -d"
        else
            git rebase $argv $_flag_interactive
        end
    end

    if set -q _flag_stash
        echo "Reinstating changes"
        git stash pop
    end
end
