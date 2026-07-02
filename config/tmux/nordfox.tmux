# Nightfox colors for Tmux
# Style: nordfox
# Upstream: https://github.com/edeneast/nightfox.nvim/raw/main/extra/nordfox/nordfox.tmux
set -g mode-style "fg=black,bg=#abb1bb"
set -g message-style "fg=black,bg=#abb1bb"
set -g message-command-style "fg=black,bg=#abb1bb"
set -g pane-border-style "fg=#abb1bb"
set -g pane-active-border-style "fg=blue"
set -g status "on"
set -g status-justify "left"
set -g status-style "fg=#abb1bb,bg=black"
set -g status-left-length "100"
set -g status-right-length "100"
set -g status-left-style NONE
set -g status-right-style NONE
set -g status-right "#[fg=#abb1bb,bg=#2e3440]#[fg=black,bg=#abb1bb] #{pane_current_path} #[fg=blue,bg=#abb1bb,nobold,nounderscore,noitalics]#[fg=black,bg=blue,bold] #h "
setw -g window-status-activity-style "underscore,fg=#7e8188,bg=black"
setw -g window-status-separator ""
set -g window-status-format "#[fg=#2e3440,bg=brightblack,nobold,noitalics,nounderscore] #[fg=white,bg=brightblack]#I #[fg=white,bg=brightblack,nobold,noitalics,nounderscore] #[fg=white,bg=brightblack]#W #[fg=brightblack,bg=#2e3440,nobold,noitalics,nounderscore]"
set -g window-status-current-format "#[fg=#2e3440,bg=cyan,nobold,noitalics,nounderscore] #[fg=black,bg=cyan]#I #[fg=black,bg=cyan,nobold,noitalics,nounderscore] #[fg=black,bg=cyan]#W #[fg=cyan,bg=#2e3440,nobold,noitalics,nounderscore]"
