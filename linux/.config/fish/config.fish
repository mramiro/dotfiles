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

if test -d "$HOME/.local/share/coursier/bin"
    set -x PATH "$HOME/.local/share/coursier/bin:$PATH"
end

# dotnet installation is messed up in jammy (only dotnet6 is supported):
# See https://github.com/dotnet/core/issues/7038#issuecomment-1110377345 and https://github.com/MicrosoftDocs/live-share/issues/4646#issuecomment-1134736154
# Had to install all sdks using a shell script https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install
# if test -d "$HOME/.dotnet"
#     set -x PATH "$HOME/.dotnet:$PATH"
# end

if test -d "$HOME/.dotnet/tools"
    set -x PATH "$HOME/.dotnet/tools:$PATH"
end

# Homebrew
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

set -x JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# set -x HADOOP_HOME /opt/apache/hadoop-3.3.1
# set -x HADOOP_CONF_DIR "$HADOOP_HOME/etc/hadoop"
# set -x PATH "$PATH:$HADOOP_HOME/bin"

# set -x SPARK_HOME /opt/apache/spark-3.1.2-bin-without-hadoop
# set -x PATH "$PATH:$SPARK_HOME/bin"
# set -x SPARK_DIST_CLASSPATH (hadoop classpath)

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
