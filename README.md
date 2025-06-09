# dotfiles

My personal configurations for a productive development environment, previously managed with Stow, now is an idempotent ansible playbook!

This setup configures: Zsh (with Zinit), Tmux (with TPM), Git, SSH, uv, Neovim, Komorebi (Windows), and other CLI tools.

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

#### Interactive Mode (Default)
In admin rights PowerShell:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.ps1'))
```

#### Installation Modes
For automated installations without prompts, you can specify different modes:

**Complete Installation** - Installs everything:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex "& { $(iwr -useb 'https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.ps1') } complete"
```

**Developer Mode** - Perfect for office/work environments (productivity + development tools, excludes gaming):
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex "& { $(iwr -useb 'https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.ps1') } developer"
```

**Minimal Installation** - Only essential development tools:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex "& { $(iwr -useb 'https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.ps1') } minimal"
```

#### What Each Mode Includes:

- **Complete**: All applications available in the script
- **Developer**: VS Code, Docker, WezTerm, Todoist, Obsidian, Zotero, Notion, 7-Zip, VLC, Zen Browser, PowerToys, AutoHotkey, Komorebi, Windows Terminal, Spotify
- **Minimal**: VS Code, WezTerm, 7-Zip, Zen Browser, PowerToys

#### Local Usage
If you have the repository cloned locally:
```powershell
# Interactive mode
.\bootstrap.ps1

# Specific modes
.\bootstrap.ps1 complete
.\bootstrap.ps1 developer
.\bootstrap.ps1 minimal
```

---

## Cheatsheets

### TMUX

My Tmux leader key is `Ctrl+s`. Tmux configuration is at `~/.config/tmux/tmux.conf` (managed by `stow`).
Windows and panes start at **1** instead of 0 for easier keyboard navigation.

**System Management:**
- **Reload Config:** `Ctrl+s, r` - Reloads tmux configuration with confirmation
- **Install Plugins:** `Ctrl+s, I` (capital 'i') - Install TPM plugins after adding them to config

**Window Management:**
- **Quick Switch:** `Alt+H` / `Alt+L` - Previous/next window (no prefix needed)
- **Create Window:** `Ctrl+s, c`
- **Close Window:** `Ctrl+s, &`
- **Rename Window:** `Ctrl+s, ,`

**Pane Management:**
- **Split Horizontal:** `Ctrl+s, |` - Split pane horizontally (intuitive)
- **Split Vertical:** `Ctrl+s, -` - Split pane vertically (intuitive)
- **Navigate Panes:** `Ctrl+s, h/j/k/l` - Vim-style pane navigation
- **Resize Panes:** `Ctrl+s, Shift+H/J/K/L` - Resize panes (repeatable)
- **Close Pane:** `Ctrl+s, x`

**Copy Mode (Vim-style):**
- **Enter Copy Mode:** `Ctrl+s, [`
- **Start Selection:** `v` (in copy mode)
- **Rectangle Selection:** `Ctrl+v` (in copy mode)
- **Copy Selection:** `y` (in copy mode)
- **Paste:** `Ctrl+s, ]`

**Theme:** Uses Dracula theme with CPU usage, RAM usage, and time display.

For a complete Tmux cheatsheet, see: [tmuxcheatsheet.com](https://tmuxcheatsheet.com/).

---

### Komorebi (Windows Tiling Manager)

Komorebi uses the **Windows key** as the modifier to avoid conflicts with tmux Alt shortcuts.

**System Management:**
- **Reload whkd:** `Win+O` - Restart the hotkey daemon
- **Reload Komorebi:** `Win+Shift+O` - Reload komorebi configuration

**Window Management:**
- **Close Window:** `Win+Q`
- **Minimize Window:** `Win+M`
- **Toggle Float:** `Win+T` - Toggle floating mode
- **Toggle Monocle:** `Win+Shift+F` - Full-screen current window

**Window Focus:**
- **Navigate:** `Win+H/J/K/L` - Vim-style window focus
- **Cycle Focus:** `Win+Shift+[` / `Win+Shift+]` - Cycle through windows

**Window Movement:**
- **Move Window:** `Win+Shift+H/J/K/L` - Move window in direction
- **Promote Window:** `Win+Shift+Enter` - Move window to master position

**Window Stacking:**
- **Stack Windows:** `Win+Arrow Keys` - Stack window in direction
- **Unstack:** `Win+;` - Remove window from stack
- **Cycle Stack:** `Win+[` / `Win+]` - Navigate stacked windows

**Resizing:**
- **Horizontal:** `Win++` / `Win+-` - Increase/decrease horizontal size
- **Vertical:** `Win+Shift++` / `Win+Shift+-` - Increase/decrease vertical size

**Layout Management:**
- **Flip Horizontal:** `Win+X` - Flip layout horizontally
- **Flip Vertical:** `Win+Y` - Flip layout vertically
- **Retile:** `Win+Shift+R` - Force retiling of all windows
- **Pause/Resume:** `Win+P` - Toggle window management

**Workspaces:**
- **Switch Workspace:** `Win+1-8` - Focus workspace 1-8
- **Move to Workspace:** `Win+Shift+1-8` - Move current window to workspace

---

## CLI Tools

### yazi

Modern file manager with vim-like keybindings and rich features.
Check: https://www.youtube.com/watch?v=iKb3cHDD9hw
