# dotfiles

My personal configurations for a productive development environment, previously managed with Stow, now is an idempotent ansible playbook!

This setup configures: Zsh (with Zinit), Tmux (with TPM), Git, SSH, PyEnv, uv, Neovim, and other CLI tools.

Lots of inspiration has been taken from this highly suggested video: [My Neovim & Tmux Terminal Dev Workflow as a Principal Engineer](https://www.youtube.com/watch?v=yCgieVu13VQ)

---

## Installation

### One-Line Install (Recommended)

**Complete setup with single curl command:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bin/dotfiles)
```

**Or with wget:**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bin/dotfiles)
```

**For WSL environments:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bin/dotfiles) --wsl
```

This single command will:
1. ✅ Detect your OS (Ubuntu/Arch) and install required packages
2. ✅ Generate SSH keys and guide you through GitHub setup
3. ✅ Clone the dotfiles repository (HTTPS or SSH)
4. ✅ Run the complete Ansible playbook to configure your environment
5. ✅ Set up Zsh, Tmux, Git, and all development tools

### Alternative: Bootstrap Script

For environments that need additional setup or legacy systems:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.sh)
```

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

---
## CLI Tools

### yazi

Check: https://www.youtube.com/watch?v=iKb3cHDD9hw
