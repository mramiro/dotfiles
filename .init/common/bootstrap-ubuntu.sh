#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-auto}"

if [[ "${EUID}" -eq 0 ]]; then
  SUDO_CMD=""
else
  if command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
  else
    echo "This script needs root privileges for package installation. Install sudo or run as root." >&2
    exit 1
  fi
fi

run_root() {
  if [[ -n "${SUDO_CMD}" ]]; then
    ${SUDO_CMD} "$@"
  else
    "$@"
  fi
}

if [[ "${TARGET}" == "auto" ]]; then
  if grep -qi microsoft /proc/version 2>/dev/null; then
    TARGET="wsl"
  elif [[ -f /run/cloud-init/status.json ]] || [[ -d /var/lib/cloud ]]; then
    TARGET="cloud"
  else
    TARGET="baremetal"
  fi
fi

export DEBIAN_FRONTEND=noninteractive

has_pkg() {
  dpkg -s "$1" >/dev/null 2>&1
}

install_if_missing() {
  local pkg
  for pkg in "$@"; do
    if ! has_pkg "${pkg}"; then
      run_root apt-get install -y "${pkg}"
    fi
  done
}

ensure_apt_baseline() {
  run_root apt-get update -y
  install_if_missing ca-certificates curl gnupg lsb-release software-properties-common apt-transport-https
}

ensure_ms_repo() {
  run_root install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f /etc/apt/keyrings/microsoft.gpg ]]; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | run_root tee /etc/apt/keyrings/microsoft.gpg >/dev/null
    run_root chmod a+r /etc/apt/keyrings/microsoft.gpg
  fi

  if [[ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]]; then
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/${VERSION_ID}/prod ${VERSION_CODENAME} main" | run_root tee /etc/apt/sources.list.d/microsoft-prod.list >/dev/null
  fi
}

ensure_vscode_repo() {
  if [[ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]]; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | run_root tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
    run_root chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
  fi

  if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | run_root tee /etc/apt/sources.list.d/vscode.list >/dev/null
  fi
}

ensure_nodesource_repo() {
  if [[ ! -f /etc/apt/sources.list.d/nodesource.list ]]; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  fi
}

ensure_docker_repo() {
  run_root install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | run_root tee /etc/apt/keyrings/docker.gpg >/dev/null
    run_root chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" | run_root tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi
}

install_common_packages() {
  install_if_missing \
    git jq neovim unzip \
    python3 python3-pip \
    build-essential
}

install_microsoft_tools() {
  install_if_missing azure-cli powershell code dotnet-sdk-9.0
}

install_node() {
  install_if_missing nodejs
}

install_docker() {
  if [[ "${TARGET}" == "wsl" ]]; then
    echo "Skipping Docker Engine install in WSL target. Prefer Docker Desktop WSL integration."
    return
  fi

  install_if_missing docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  local target_user
  target_user="${SUDO_USER:-${USER:-}}"
  if [[ -n "${target_user}" ]] && id -u "${target_user}" >/dev/null 2>&1; then
    run_root usermod -aG docker "${target_user}" || true
  fi
}

main() {
  echo "Bootstrap target: ${TARGET}"

  ensure_apt_baseline
  ensure_ms_repo
  ensure_vscode_repo
  ensure_nodesource_repo
  ensure_docker_repo

  run_root apt-get update -y

  install_common_packages
  install_microsoft_tools
  install_node
  install_docker

  run_root apt-get autoremove -y

  echo "Ubuntu bootstrap completed for target: ${TARGET}"
  echo "If Docker group membership changed, sign out/in before using docker without sudo."
}

main
