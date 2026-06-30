function tmuxsessionlist
  set -l current $argv[1]
  set -l sessions (tmux list-sessions -F '#{session_name}')
  for name in $sessions
    if [ "$name" = "$current" ]
      printf '#[range=user|session=%s]#[fg=cyan,bg=black]#[fg=#2e3440,bg=cyan]#[fg=black,bg=cyan] %s #[fg=cyan,bg=#2e3440] #[norange]' $name $name
    else
      printf '#[range=user|session=%s]#[fg=brightblack,bg=#2e3440]#[fg=#2e3440,bg=brightblack]#[fg=white,bg=brightblack] %s #[fg=brightblack,bg=#2e3440] #[norange]' $name $name
    end
  end
end
