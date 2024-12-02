# dotfiles

## Packages

### APT 

- zsh
- stow
- lsd
- bat
- neovim

### PIP

- virtualenvwrapper
- thefuck (deprecated)

## WSL

https://dev.to/front-commerce/set-up-a-wsl-development-environment-44jk

## Installation

```bash
git clone git@github.com:LittleHaku/dotfiles.git
```

```bash
cd dotfiles
```

```bash
stow .
```

## Current

- Apps: (modded) catppuccin-mocha
- Cursor: Sanity-Cursor
- Icons: Tela purple theme
- Shell: (modded) catppuccin-mocha
- Chrome: Catppuccin Chrome Theme - Mocha
- Terminal: Kitty

## Screenshots

![desktop1](/screenshots/w1.png)
![desktop2](/screenshots/w2.png)
![desktop3](/screenshots/w3.png)
![desktop4](/screenshots/w4.png)

## Keybinds

- super+0..9: desktop
- super+w: rename desktop
- super+enter: new terminal
- alt+space: search bar
- ctrl+s: tmux leader

## STOW Instructions

STOW Tutorial: https://www.youtube.com/watch?v=y6XCebnB9gs

TLDR; You place the dotfiles folder in your home directory so `~/dotfiles` and here replicate the same structure, that is:
A file that would be in `~` you put in `~/dotfiles` and if it should be in `~/zsh` you place it in `~/dotfiles/zsh`, then remove the originals from the home (making sure you still have them in the `dotfiles`, so just do `mv` and move them) and inside the `dotfiles` directory do `stow .` for all or `stow <name>` and it will create a symbolic link in the parent folder, i.e. home `~` (dont worry the `.git` dir won't get linked)

Create a git repo directly in your home folder, .g. `~/dotfiles`

In this directory, you create a folder with a *"package name"* and in it the exact folder structure this app has it's config files in your home folder.

Let's take `i3` for example, which has its config file in `~/.config/i3/config`

Move this file into `~/dotfiles/i3/.config/i3/config`. Now you can `git add` and `git commit` it, like usual.

In your terminal, `cd dotfiles`. From there, you can do this:

```bash
stow i3
```

This will enter the folder `i3`, which we created (as the mentioned "package name") and everything in it will be **symlinked** exactly one directory above where you currently are.

This means, from `~/dotfiles` it jumps one folder up (so it's `~`) and there the folder structure inside your *"i3"* package will be *symlinked*.

This means your moved config file now is at the same place as before, but symlinks into your git repo. Now you can edit your config as usual and your changes are automatically tracked. Clone on another device, stow i3 and boom! you have the same config there.

If you want to stow your `~/.Xresources`, the file would be e.g. at `~/dotfiles/Xresources/.Xresources` and you would do a `stow Xresources` in there.

You can also do your whole configuration into one *"package"*, so you just have to stow once.

Very easy stuff to set up and you only need `git` and `stow` for it.

`yadm` is, a wrapper for this workflow and does some things on top of it. E.g. you can append your hostname at the file name, so `yadm` checks which file for which hostname it should link.

For example two files for two machines:

```zsh
~/dotfiles/i3/.config/i3/config##myworkstation
~/dotfiles/i3/.config/i3/config##trollwutslaptop
```

Source: <https://www.reddit.com/r/archlinux/comments/bloeme/dot_files_backup_tool/>

all credit to most excellent post from [/u/Trollw00t](https://www.reddit.com/user/Trollw00t) explaining how to use `stow` + `git`

## ZSH

<https://www.youtube.com/watch?v=MSPu-lYF-A8>

## TMUX

- **reload config**: `leader + R`
- **fetch plugins**: `leader + I`
- **right click menu**: mantener click derecho

## Copy

- **copiar normal**: seleccionar text con el raton usando shift, y luego click derecho manteniendo el shift y copiar
- **enter copy mode**: `leader + [` o scroll mouse
- **paste tmux buffer**: `leader + ]`
- **start selecting text**: `space`
- **copy text**: `enter`
- **copy it to clipboard**: `leader + y`

### Panes

- **new pane vertical**: `leader+%`
- **new pane horizontal**: `leader+"`
- **close pane**: `leader+x` or `ctrl+d`
- **move around panes**: `leader+h,j,k,l` (vim style)
- **rotate panes**: `leader+space`
- **master navigate**: `leader+w`

### Windows

- **new window**: `leader+c`
- **close window**: `leader+&`
- **rename window**: `leader+,`
- **go to window n**: `leader+0..9`
- **go to next window**: `leader+n`
- **go to previous window**: `leader+p`
- **go to last window**: `leader+l` (ahora no va x haber puesto lo de vim)
- **master navigate**: `leader+w`

### Sessions

- **list sessions**: `tmux ls` o con zsh `tl`
- **rename session**: `leader+$`
- **dettach**: `leader+d`
- **new session with name**: `tmux new -s nombre` o `ts`
- **attach**: `tmux attach -t nombre` o `tmux a -t nombre` o `ta`
- **attack to last session**: `tmux attach` o `tmux a`
- **show all sessions**: `leader+s`
- **close session**: `tmux kill-ses -t nombre` o `tkss`
- **close all except current**: `tmux kill-ses -a`
- **close all except name**: `tmux kill-ses -a -t nombre`
- **close all sessions**: `tksv` o `tmux kill-server`
- **save session with tmux resurrect**: `leader + ctrl s`
- **restore session with tmux resurrect**: `leader + ctrl r`

### Others

- **reload config**: `leader+r`

## Gnome settings

Save:
`dconf dump / > gnome-settings.ini`

Load:
`dconf load / < dconf-settings.ini`


