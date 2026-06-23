function todo
  set -q TODO_HOME; or set TODO_HOME ~/Documents/notes/todo
  set -q TODO_RTP; or set TODO_RTP ~/code/projects/todo.nvim

  set TODO_FILE $TODO_HOME/main.todo

  if set -q argv[1]
    set TODO_FILE $argv[1]

    if not string match -q '*/*' -- $TODO_FILE; and not string match -q '*.todo' -- $TODO_FILE
      set TODO_FILE $TODO_HOME/$TODO_FILE.todo
    end
  end

  nvim --cmd "set rtp+=$TODO_RTP" +'normal!GzzM{' -- $TODO_FILE

end
