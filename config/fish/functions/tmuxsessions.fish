function tmuxsessions
  argparse 'd/debug' -- $argv

  set -l sessions (tmux list-sessions -F '#{session_name}')
  set -l current (tmux display-message -p '#{session_name}')
  # set -l opts '-T "#[align=centre]Sessions" -x C -y C'
  set -l opts '-T "#[align=centre]New Window" -x 0 -y W'
  set -l command 'tmux display-menu ' $opts

  for i in (seq (count $sessions))
    set -l name $sessions[$i]
    if [ "$name" = "$current" ]
      set command $command "'$name (current)'" $i "'switch-client -t \'$name\''"
    else
      set command $command "'$name'" $i "'switch-client -t \'$name\''"
    end
  end

  set command $command "''" "'[New]'" n
  set command $command "'command-prompt -p \'New session:\' \'new-session -s \"%%\"\''"

  set -q _flag_debug
  and echo $command
  or eval $command
end
