# Zinit Plugin Manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Add pure theme
zinit ice pick"async.zsh" src"pure.zsh" # with zsh-async library that's bundled with it.
zinit light sindresorhus/pure

# Add ZSH plugins
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# Open git in the browser
zinit light paulirish/git-open
# Git aliases
zinit snippet OMZ::plugins/git/git.plugin.zsh
# tmux aliases (maybe I could do this by hand so I don't have to load the plugin)
zinit snippet OMZ::plugins/tmux/tmux.plugin.zsh
# Add sudo pressing esc 2 times
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

# Z travel
zinit light agkozak/zsh-z

# Load completions
autoload -U compinit && compinit

# Add PyEnv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Add UV
. "$HOME/.local/bin/env"



##################
# Custom Aliases #
##################

# nvim
alias vi='nvim'
alias vim='nvim'
alias cvim='vim'

#use bat instead of cat
alias cat='batcat'
alias catn='/bin/cat'
alias catnl='bat --paging=never'

#apt package manager
alias aptup='sudo apt update && sudo apt upgrade'
alias aptupd='sudo apt udpate'
alias aptupg='sudo apt upgrade'
alias aptin='sudo apt install'
alias aptrm='sudo apt remove'

# update zinit
alias ziup='zinit update'
# update zinit plugins
alias ziupg='zinit update --all'


# folder usage
alias usage='du -h -d1'

# lsd
alias lsn='ls'
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'
