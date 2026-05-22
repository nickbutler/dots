if status --is-interactive
  source (starship init fish --print-full-init | psub)
  if type -q tmux; and not set -q TMUX
    if not set -q SSH_CLIENT
      tmux -f ~/.config/tmux/tmux.conf new-session -A -s main -n Home
    end
  else if set -q TMUX
    set -l window_name (tmux display -p '#{window_name}')

    # Bindings
    set fish_key_bindings fish_default_key_bindings

    # Biome
    set -g _biome_mask_char ''

    # Set tab width
    tabs -2

    # For new windows
    set -l npanes (tmux display-message -p '#{window_panes}')
    if [ "$npanes" -eq 1 ]
      if ! contains "$window_name" Home New fish
        # Run $window_name if it's a valid command
        type -q $window_name
        and $window_name

        # Try to cd to $window_name with z
        or z $window_name >/dev/null
      end
    end
  end
end
