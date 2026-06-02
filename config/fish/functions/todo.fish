function todo
  set -q TODO_RTP; or set TODO_RTP ~/code/projects/todo.nvim
  set -q TODO_FILE; or set TODO_FILE ~/Documents/notes/my.todo
  nvim --cmd "set rtp+=$TODO_RTP" $TODO_FILE
end
