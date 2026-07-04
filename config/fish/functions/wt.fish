function wt --description "List git worktrees, or cd to one"
    if test (count $argv) -eq 0
        git worktree list
        return
    end

    set -l target $argv[1]
    for path in (git worktree list --porcelain | string replace -f 'worktree ' '')
        if test "$path" = "$target"; or test (path basename $path) = "$target"
            cd $path
            return
        end
    end

    echo "wt: no worktree matching '$target'" >&2
    return 1
end
