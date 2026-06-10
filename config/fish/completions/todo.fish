complete -c todo -f -a "(
    set -q TODO_HOME; or set TODO_HOME ~/Documents/notes/todo
    for f in \$TODO_HOME/*.todo
        basename \$f .todo
    end
)"
