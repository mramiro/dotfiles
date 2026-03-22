# Init Layout

This folder contains provisioning assets for each platform, with one shared Ubuntu bootstrap script.

## Structure

- `.init/common/bootstrap-ubuntu.sh`
  - Shared installer used by bare metal, cloud VM, and WSL.
- `.init/ubuntu-2404/cloud-init.yaml`
  - cloud-init template for Ubuntu 24.04 cloud VMs.
- `.init/ubuntu-2404-wsl/cloud-init.yaml`
  - cloud-init template for Ubuntu WSL installations.
- `.init/win11/imageDefinition.yaml`
  - Windows Dev Box image definition.

## What Gets Installed (Ubuntu)

- Core: `git`, `jq`, `neovim`, `python3`, `python3-pip`, `build-essential`
- Microsoft stack: `azure-cli`, `powershell`, `code`, `.NET SDK 9`
- Node.js: NodeSource LTS channel
- Docker engine stack (bare metal/cloud targets)

For `wsl` target, Docker engine install is skipped in favor of Docker Desktop WSL integration.

## Usage

### 1) Local Bare Metal Ubuntu

Run from repo root:

```bash
bash .init/common/bootstrap-ubuntu.sh baremetal
```

### 2) Cloud VM (Ubuntu 24.04)

Use `.init/ubuntu-2404/cloud-init.yaml` as your user-data.

Before use, update repo defaults in that file:

- `DOTFILES_REPO_URL`
- `DOTFILES_REPO_BRANCH`

### 3) WSL Ubuntu

Use `.init/ubuntu-2404-wsl/cloud-init.yaml` as a tokenized template.

Render it into `~/.cloud-init/Ubuntu-24.04.user-data` on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .init/ubuntu-2404-wsl/render-user-data.ps1 -UserName miramiro -Gecos "Mira Miro" -RepoUrl "https://github.com/mramiro/dotfiles.git" -Branch master
```

Renderer inputs:

- `UserName`
- `Gecos`
- `RepoUrl`
- `Branch`

This keeps WSL-first cloud-init syntax while still allowing full username parameterization.

## Notes

- The bootstrap script can auto-detect target if no argument is passed.
- Re-running is generally safe for packages and repo setup.
- If Docker group membership changes, sign out/in before using `docker` without `sudo`.
