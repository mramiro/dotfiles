# Fish config

if not functions -q fisher
  echo "fisher not found. Install with"
  echo "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
  echo "fisher update"
end

# Check if running inside WSL
if uname -a | grep "Microsoft" > /dev/null
    # WSL 1 needs a dedicated XServer running in Windows
    set -x DISPLAY localhost:0.0
    set -x DOCKER_HOST tcp://localhost:2375
else if uname -a | grep "microsoft-standard" > /dev/null; and not which wslg.exe > /dev/null
    # Old versions of WSL 2 (without WSLg) also need an XServer, but the Windows host has its own IP
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

# dotnet installation is messed up in jammy (only dotnet6 is supported):
# See https://github.com/dotnet/core/issues/7038#issuecomment-1110377345 and https://github.com/MicrosoftDocs/live-share/issues/4646#issuecomment-1134736154
# Had to install all sdks using a shell script https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install
if test -d "$HOME/.dotnet"
    set -x PATH "$HOME/.dotnet:$PATH"
end

if test (umask) = "0000"
    umask 0022
end

if [ -f ~/.fzf.fish ]
    source ~/.fzf.fish
end

if functions -q fish_ssh_agent
  fish_ssh_agent
end

fish_vi_key_bindings

set -x GCM_CREDENTIAL_STORE secretservice
