set -g mouse on
set -g mouse-utf8 on
bind-key C-m source $BYOBU_CONFIG_DIR/mouse_disable.tmux \; display-message "Mouse: OFF"
