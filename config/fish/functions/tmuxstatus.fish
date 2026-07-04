function tmuxstatus
  set -l pid $argv[1]
  set -l stat (ps -o etime=,rss= -p $pid | string trim | string split -n ' ')
  set -l days 0
  if string match -q '*-*' $stat[1]
    set days (string split - $stat[1])[1]
  end
  set -l mem (math -s0 $stat[2] / 1024)
  # Server RSS climbing toward ~277M preceded the 3.6a grid crash (tmux/tmux#4777)
  set -l dot '#[fg=green]●#[fg=white]'
  if test $mem -ge 150
    set dot '#[fg=red]●#[fg=white]'
  end
  set -l windows (tmux list-windows -a | count)
  set -l panes (tmux list-panes -a | count)
  # Caps:   rounded    pointed   ▐ ▌ square   █ █ flush
  # Dividers:  thin-pointed   │ bar   ▏hairline   ● ○ ◉ ◎ dots   ░ ▒ shade
  set -l cap_l 
  set -l cap_r 
  set -l div │
  printf '#[fg=brightblack,bg=#2e3440]%s#[fg=white,bg=brightblack] %s ↑ %sd %s 󰍛 %sMB %s %s win %s %s panes #[fg=brightblack,bg=#2e3440]%s' \
    $cap_l $dot $days $div $mem $div $windows $div $panes $cap_r
end
