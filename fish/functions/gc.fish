function gc --description "Add all and commit with a message; optional spotless first"
    argparse 's/spotless' 'h/help' -- $argv
    or return

    if set -q _flag_help
        echo "Usage:"
        echo "  gc \"commit message\""
        echo "  gc -s \"commit message\"        # run ./gradlew spotless first"
        return 0
    end

    if test (count $argv) -eq 0
        echo "gc: missing commit message."
        echo "Try: gc \"your message\" or gc -s \"your message\""
        return 1
    end

    set commit_message (string join ' ' -- $argv)

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

    echo "Staging changes (git add .)…"
    git add .
    if test $status -ne 0
        echo "gc: git add failed."
        return 1
    end

    echo "Committing: $commit_message"
    git commit -m "$commit_message"
end
