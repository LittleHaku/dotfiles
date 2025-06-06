###################
# ZINIT SETUP     #
###################

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Profiling (uncomment to enable)
# zmodload zsh/zprof

###################
# SHELL OPTIONS   #
###################

# History
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt append_history
setopt share_history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

###################
# KEY BINDINGS    #
###################

# History navigation
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Word navigation
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[3;5~' kill-word         # Ctrl+Delete

# Vim motions
set -o vi

# Restore useful emacs bindings in vi mode
bindkey '^E' end-of-line            # Ctrl+E to end of line
bindkey '^A' beginning-of-line      # Ctrl+A to beginning of line

###################
# COMPLETIONS     #
###################

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# Completion with colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Disable default completion menu for fzf
zstyle ':completion:*' menu no
# fzf previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --group-directories-first --icons'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --group-directories-first --icons'

###################
# THEME           #
###################

# Pure theme
zinit ice lucid pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

###################
# PLUGINS         #
###################

# Core functionality plugins (loaded first)
zinit ice wait'0a' lucid atload"_zsh_autosuggest_start; bindkey '^E' autosuggest-accept"
zinit light zsh-users/zsh-autosuggestions

zinit ice wait'0b' lucid
zinit light zsh-users/zsh-completions

# Syntax highlighting (load last among core plugins)
zinit ice wait'0c' lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Enhanced functionality plugins
zinit ice wait'1' lucid
zinit light Aloxaf/fzf-tab

zinit ice wait'1' lucid
zinit light paulirish/git-open

# OMZ plugins
zinit ice wait'1' lucid
zinit light wfxr/forgit

zinit ice wait'1' lucid
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

zinit ice wait'1' lucid
zinit snippet OMZ::plugins/dotenv/dotenv.plugin.zsh

zinit ice wait'1' lucid
zinit snippet OMZ::plugins/command-not-found/command-not-found.plugin.zsh

###################
# ENVIRONMENT     #
###################


# UV
if [[ -f "$HOME/.local/bin/env" ]]; then
    zinit ice lucid wait'2'
    zinit snippet "$HOME/.local/bin/env"
fi

# PATH additions
paths_to_add=(
    "$HOME/dotfiles/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.fzf/bin"
)

for path_dir in "${paths_to_add[@]}"; do
    [[ -d "$path_dir" ]] && export PATH="$path_dir:$PATH"
done

# Less configuration
export LESS='-R --mouse'

###################
# ALIASES         #
###################

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# System
alias cl='clear'
alias usage='du -h -d1'

# Editors
alias vi='nvim'
alias vim='nvim'
alias cvim='vim'

# File listing (eza)
alias lsn='ls'
alias ls='eza --group-directories-first --icons'
alias l='eza --group-directories-first --icons'
alias ll='eza -l --group-directories-first --icons --git'
alias la='eza -a --group-directories-first --icons'
alias lla='eza -la --group-directories-first --icons --git'
alias lt='eza --tree --level=2 --group-directories-first --icons'

# Cat alternatives
alias cat='bat'
alias catn='/bin/cat'
alias catnl='bat --paging=never'

# Package management
alias aptup='sudo apt update && sudo apt upgrade'
alias aptupd='sudo apt update'
alias aptupg='sudo apt upgrade'
alias aptin='sudo apt install'
alias aptrm='sudo apt remove'

# Zinit management
alias ziup='zinit update'
alias ziupg='zinit update --all'

# Tmux
alias ta='tmux attach'
alias tad='tmux attach -d -t'
alias tkss='tmux kill-session -t'
alias tksv='tmux kill-server'
alias tl='tmux list-sessions'
alias tmux='command tmux'
alias tmuxconf='$EDITOR ~/.config/tmux/tmux.conf'
alias ts='tmux new-session -s'

###################
# FUNCTIONS       #
###################

# Yazi with auto-cd
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

###################
# INTEGRATIONS    #
###################

# fzf (load early for other tools to use)
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
    [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
fi

# zoxide (load last)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Profiling output (uncomment to enable)
# [[ "$PROFILE_STARTUP" == true ]] && zprof
