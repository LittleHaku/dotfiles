# dotfiles

## Current
- Apps: Colloid-Dark
- Cursor: Sanity-Cursor
- Icons: Tela purple theme
- Shell: Colloid-Dark1


## STOW Instructions

Create a git repo directly in your home folder, .g. `~/dotfiles`

In this directory, you create a folder with a *"package name"* and in it the exact folder structure this app has it's config files in your home folder.

Let's take `i3` for example, which has its config file in `~/.config/i3/config`

Move this file into `~/dotfiles/i3/.config/i3/config`. Now you can `git add` and `git commit` it, like usual.

In your terminal, `cd dotfiles`. From there, you can do this:

```
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

```
~/dotfiles/i3/.config/i3/config##myworkstation
~/dotfiles/i3/.config/i3/config##trollwutslaptop
```

#### Source: https://www.reddit.com/r/archlinux/comments/bloeme/dot_files_backup_tool/

all credit to most excellent post from [/u/Trollw00t](https://www.reddit.com/user/Trollw00t) explaining how to use `stow` + `git`
