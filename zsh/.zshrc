# Zinit Plugin Manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# For profiling - UNCOMMENT FOR USE, COMMENT OUT FOR NORMAL OPERATION
# zmodload zsh/zprof

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt append_history         # append to history file
setopt share_history          # share history between sessions
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_ignore_all_dups   # ignore duplicated commands history list
setopt hist_save_no_dups      # do not save duplicates
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_find_no_dups      # do not save duplicates

# case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# completion with colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# disable default completion to use fzf
zstyle ':completion:*' menu no
# add fzf preview for cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd --group-dirs=first'
# add fzf preview for z
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd --group-dirs=first'

# Pure theme - light priority
zinit ice lucid pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

# Syntax highlighting, suggestions, and completions - now loaded asynchronously
zinit ice wait'!' lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

zinit ice wait'!' lucid atinit"zicompinit; zicdreplay"
zinit light zsh-users/zsh-completions

# Load this last as it's the heaviest - already async
zinit ice wait'!' lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Git-related - now loaded asynchronously
zinit ice wait'!' lucid
zinit light paulirish/git-open

zinit ice wait'!' lucid
zinit snippet OMZ::plugins/git/git.plugin.zsh

# fzf - now loaded asynchronously
zinit ice wait'!' lucid
zinit light Aloxaf/fzf-tab

# dotenv - now loaded asynchronously
zinit ice wait'!' lucid
zinit snippet OMZP::dotenv

zinit ice wait'!' lucid
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

zinit ice wait'!' lucid
zinit light agkozak/zsh-z

zinit ice wait'!' lucid
zinit snippet OMZP::command-not-found

# Add PyEnv - already async
export PYENV_ROOT="$HOME/.pyenv"
# Add to PATH immediately if other tools/aliases might need pyenv commands before full init
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# Defer pyenv init - adjust wait time if needed
zinit ice lucid wait'!' atload'eval "$(pyenv init - zsh)"'
zinit snippet /dev/null # Dummy snippet for atload

# Add UV (defer if not immediately needed) - already async
zinit ice lucid wait'!' # Adjust wait time
zinit snippet "$HOME/.local/bin/env"

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
alias aptupd='sudo apt update'
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

# tmux

alias ta='tmux attach -t'              			# Attach new tmux session to already running named session
alias tad='tmux attach -d -t'          			# Detach named tmux session
alias tkss='tmux kill-session -t'      			# Terminate named running tmux session
alias tksv='tmux kill-server'          			# Terminate all running tmux sessions
alias tl='tmux list-sessions'          			# Displays a list of running tmux sessions
alias tmux='command tmux'              			# Use the standard tmux command
alias tmuxconf='$EDITOR ~/.config/tmux/tmux.conf' 	# Open tmux.conf file with an editor
alias ts='tmux new-session -s'         			# Create a new named tmux session

# Allow mouse scroll in less (batcat)
export LESS='-R --mouse'

# Removed explicit source ~/.fzf.zsh as fzf-tab usually handles this.


# End startup time measurement - UNCOMMENT FOR USE, COMMENT OUT FOR NORMAL OPERATION
# if [[ "$PROFILE_STARTUP" == true ]]; then
#   zprof
# fi
