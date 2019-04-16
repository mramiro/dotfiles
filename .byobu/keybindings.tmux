# unbind-key -n C-o
unbind -
unbind _
unbind |
unbind \\
bind - display-panes \; split-window -v -c "#{pane_current_path}"
bind _ display-panes \; split-window -v -c "#{pane_current_path}" -p 25
bind | display-panes \; split-window -h -c "#{pane_current_path}"
source $BYOBU_CONFIG_DIR/mouse_enable.tmux

unbind-key -n C-b
unbind-key -n C-a
set -g prefix ^A
set -g prefix2 F12
bind a send-prefix
