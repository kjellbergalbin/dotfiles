function rebase-origin
    git stash
    git fetch origin
    git rebase origin/main
    git stash pop
end
