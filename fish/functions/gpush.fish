function gpush --description "Push local changes to GitHub; optional force with lease"
    argparse 'f/force' 'h/help' -- $argv
    or return

    if set -q _flag_help
        echo "Usage:"
        echo "  gpush"
        echo "  gpush -f    # run with --force-with-lease"
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
