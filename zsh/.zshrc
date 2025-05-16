# Zinit Plugin Manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Measure startup time - add at the beginning
zmodload zsh/zprof

# Pure theme - light priority
zinit ice wait'!' lucid pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

# Syntax highlighting and suggestions - can be deferred a bit
zinit ice wait lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zsh-users/zsh-completions

# Load this last as it's the heaviest
zinit ice wait'2' lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Git-related - medium priority
zinit ice wait lucid
zinit light paulirish/git-open

zinit ice wait lucid
zinit snippet OMZ::plugins/git/git.plugin.zsh

# Other utilities - they can be deferred
zinit ice wait lucid
zinit snippet OMZ::plugins/tmux/tmux.plugin.zsh

zinit ice wait lucid
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

zinit ice wait lucid
zinit light agkozak/zsh-z

# Load completions
zinit ice wait lucid atinit"zicompinit; zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

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


# End startup time measurement - add at the end of your .zshrc
if [[ "$PROFILE_STARTUP" == true ]]; then
  zprof
fi
