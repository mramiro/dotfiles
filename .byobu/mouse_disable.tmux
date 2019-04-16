set -g mouse off
set -g mouse-utf8 off
bind-key C-m source $BYOBU_CONFIG_DIR/mouse_enable.tmux \; display-message "Mouse: ON"
