complete -c wt -f -a '(for p in (git worktree list --porcelain 2>/dev/null | string replace -f "worktree " ""); printf "%s\t%s\n" (path basename $p) $p; end)'
