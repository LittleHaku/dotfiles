# dotfiles

My personal configurations for a "productive"" development environment, previously managed with Stow (you can still find the branch), now is an idempotent ansible playbook!

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

This single command will detect your OS (Ubuntu/Arch), install required packages, generate SSH keys, guide you through GitHub setup, clone the dotfiles repository, and run the complete Ansible playbook to configure your environment with Zsh, Tmux, Git, and all development tools.

On Linux, the dotfiles binary is added to your PATH, so you can run `dotfiles` from anywhere to update your configuration.

---

### Windows

#### Interactive Mode (Default)
In admin rights PowerShell:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/LittleHaku/dotfiles/main/bootstrap.ps1'))
```

#### Installation Modes
For automated installations without prompts, you can specify different modes by appending the mode name right after the command:

- **Complete Installation** - Installs everything: `complete`
- **Developer Mode** - Perfect for office/work environments (productivity + development tools, excludes gaming): `developer`  
- **Minimal Installation** - Only essential development tools: `minimal`

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
- **Navigate Panes:** `Ctrl+s, h/j/k/l` - Vim-style pane navigation (works without leader when not in neovim)
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

- **Lock Screen:** `Ctrl+Win+L` - Lock the system

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

## CLI Tools Cheatsheet

### yazi
Modern file manager with vim-like keybindings and rich features.
- **When to use:** File browsing, bulk operations, visual file management
- **Launch:** `yazi` or `y` (alias)
- **Key features:** Image previews, syntax highlighting, bulk rename
- **Navigate:** `h/j/k/l` - vim-style navigation
- **Select:** `Space` - toggle selection, `v` - visual mode
- **Actions:** `d` - delete, `r` - rename, `c` - copy, `x` - cut

Check: https://www.youtube.com/watch?v=iKb3cHDD9hw

### Key CLI Tools Overview

**File Operations:**
- `eza` - Modern `ls` replacement with icons and git status
- `fd` - Fast `find` alternative with intuitive syntax
- `ripgrep` (rg) - Ultra-fast text search tool
- `bat` - `cat` with syntax highlighting and git integration

**Navigation:**
- `zoxide` (z) - Smart directory jumping based on frequency
- `fzf` - Fuzzy finder for files, history, processes

**Git:**
- `lazygit` - Terminal UI for git operations
- `difftastic` - Structural diff tool that understands syntax

**System:**
- `lsd` - LSDeluxe, another modern `ls` with icons
- `tmux` - Terminal multiplexer for session management
- `uv` - Fast Python package installer and resolver

**Development:**
- `neovim` - Modern vim-based editor
- `rust` toolchain - Systems programming language
- `npm` - Node.js package manager
