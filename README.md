# dotfiles

My personal configurations for a productive development environment, managed with `stow` and an automated bootstrap script.

This setup configures: Zsh (with Zinit), Tmux (with TPM), Git, SSH, PyEnv, uv, Neovim, and other CLI tools.

---

## Installation

### Linux: Bootstrap Script (Recommended)

This script automates the entire setup process.

**1. Run:**
   ```bash
   bash <(wget -qO- https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.sh)
   ```
   *(Or with `curl`: `bash <(curl -sSL https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.sh)`) *

**2. Follow Prompts:**
   Requires `sudo` privileges. It will guide you through SSH key setup for GitHub, cloning these dotfiles, and installing software.

**Non-Interactive Mode:**
   ```bash
   bash <(wget -qO- https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.sh) -- \
     --non-interactive \
     --git-email "your_github_email@example.com" \
     --git-name "Your Git Name" \
     --dotfiles-ssh-url "git@github.com:LittleHaku/dotfiles.git"
   ```
   **Arguments:** `--git-email`, `--git-name`, `--dotfiles-dir`, `--dotfiles-ssh-url`, `--yes` (or `-y`, `--non-interactive`).

---

### Windows
In admin rights PowerShell:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.ps1'))
```

---
## WSL
To move WSL distribution to another drive:
```powershell
wsl --unmount
# cd to the target directory in PowerShell
wsl --manage Ubuntu --move . # Replace 'Ubuntu' if your distro name is different
```
---
## STOW (Dotfile Management)

These dotfiles use `GNU Stow`. The bootstrap script handles stowing `zsh` and `tmux` packages from `~/dotfiles` to `~`.
For more on Stow, see this [excellent explanation by /u/Trollw00t](https://www.reddit.com/r/archlinux/comments/bloeme/comment/emq8f5k/).

The structure for Stow means a file like `~/.config/tmux/tmux.conf` would be stored as `~/dotfiles/tmux/.config/tmux/tmux.conf`.

---
## PyEnv Cheatsheet

- `pyenv install <version>`: Install a Python version.
- `pyenv versions`: List installed versions.
- `pyenv global <version>`: Set global Python version.
- `pyenv local <version>`: Set Python version for current directory (creates `.python-version`).
- `pyenv shell <version>`: Set Python version for current shell session.
- `pyenv uninstall <version>`: Uninstall a Python version.
- `pyenv update`: Update PyEnv.

---
## TMUX Cheatsheet

My Tmux leader key is `Ctrl+s`. Tmux configuration is typically at `~/.config/tmux/tmux.conf` (managed by `stow`).
For a general Tmux cheatsheet, see: [tmuxcheatsheet.com](https://tmuxcheatsheet.com/).

**Key Custom Actions:**
- **Reload Tmux Config:** `leader + R` (ensure this is mapped in your `tmux.conf`).
- **Install TPM Plugins:** `leader + I` (capital 'i') (after adding them to `tmux.conf`).
- **Vim-style navigation between panes:** `leader + h, j, k, l` (if configured).
