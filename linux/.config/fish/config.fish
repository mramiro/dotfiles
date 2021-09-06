# Fish config

if not functions -q fisher
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
    fisher update
end

if [ -f ~/.fzf.fish ]
    source ~/.fzf.fish
end

if uname -a | grep "Microsoft" > /dev/null
    set -x DISPLAY localhost:0.0
    set -x DOCKER_HOST tcp://localhost:2375
else if uname -a | grep "microsoft-standard" > /dev/null
    set -x DISPLAY (cat /etc/resolv.conf | grep nameserver | cut -d ' ' -f 2)":0.0"
    set -x LIBGL_ALWAYS_INDIRECT 1
end

# set PATH so it includes user's private bin if it exists
if test -d "$HOME/bin"
    set -x PATH "$HOME/bin:$PATH"
end

# set PATH so it includes user's private bin if it exists
if test -d "$HOME/.local/bin"
    set -x PATH "$HOME/.local/bin:$PATH"
end

if test (umask) = "0000"
    umask 0022
end

fish_ssh_agent
fish_vi_key_bindings
