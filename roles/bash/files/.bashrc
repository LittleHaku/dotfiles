# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

#------------------------------------------------------------------------------
# HISTORY
#------------------------------------------------------------------------------
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
export HISTSIZE=5000
export HISTFILESIZE=$HISTSIZE
export HISTFILE=~/.bash_history

#------------------------------------------------------------------------------
# COMPLETION
#------------------------------------------------------------------------------
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# For case-insensitive completion, add to ~/.inputrc:
# set completion-ignore-case on

#------------------------------------------------------------------------------
# PROMPT (Simple, Colored, with Git Branch via PROMPT_COMMAND)
#------------------------------------------------------------------------------
# Function to get Git branch - This function now sets ONLY the branch string, no colors.
__prompt_git_branch() {
    local branch
    local dirty_indicator=""
    # Check if we're in a Git repository
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            # Check for dirty state (modified files)
            if [[ -n $(git status --porcelain 2> /dev/null) ]]; then # More reliable check for dirty
                dirty_indicator="*"
            fi
            GIT_BRANCH_INFO=" (${branch}${dirty_indicator})" # e.g., " (main*)" or " (feature/foo)"
        else
            GIT_BRANCH_INFO="" # Not on a branch (e.g., detached HEAD)
        fi
    else
        GIT_BRANCH_INFO="" # Not a git repo
    fi
}

# Set prompt elements (Color definitions remain the same)
C_USER_HOST="\[\033[01;32m\]" # Bold Green
C_PATH="\[\033[01;34m\]"      # Bold Blue
C_GIT_INFO_COLOR="\[\033[01;33m\]"  # Bold Yellow for Git info text
C_NONE="\[\033[00m\]"        # No Color

# Update GIT_BRANCH_INFO before each prompt
PROMPT_COMMAND="__prompt_git_branch${PROMPT_COMMAND:+;$PROMPT_COMMAND}" # Append to existing PROMPT_COMMAND safely

# PS1 Structure: user@host:path (git_branch)$
# Apply colors around the GIT_BRANCH_INFO variable expansion
PS1="${C_USER_HOST}\u@\h${C_NONE}:${C_PATH}\w${C_NONE}"
# Conditionally add Git info only if GIT_BRANCH_INFO is not empty
PS1+="\$(if [ -n \"\${GIT_BRANCH_INFO}\" ]; then echo \"${C_GIT_INFO_COLOR}\${GIT_BRANCH_INFO}${C_NONE}\"; fi)"
PS1+="\$ "


# Terminal title
case "$TERM" in
xterm*|rxvt*|*-256color|tmux*)
    # The PS1_TITLE should also correctly bracket non-printing sequences
    PS1_TITLE="\[\e]0;\u@\h: \w\a\]"
    PS1="${PS1_TITLE}${PS1}"
    ;;
*)
    ;;
esac

shopt -s checkwinsize
shopt -s globstar # For ** globbing

#------------------------------------------------------------------------------
# FZF Setup (Essential for good history search and file finding)
#------------------------------------------------------------------------------
if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
fi


#------------------------------------------------------------------------------
# UV Setup
#------------------------------------------------------------------------------
# If "$HOME/.local/bin/env" is your custom script that sets UV's path:
if [ -f "$HOME/.local/bin/env" ]; then
    source "$HOME/.local/bin/env"
fi
# Or ensure UV's path is set directly if known (e.g., from cargo or pipx)
# export PATH="$HOME/.cargo/bin:$PATH"
# export PATH="$HOME/.local/bin:$PATH" # Common for pipx installs like uv

#------------------------------------------------------------------------------
# ALIASES (Core set)
#------------------------------------------------------------------------------
# nvim
alias vi='nvim'
alias vim='nvim'

# bat (cat replacement)
if command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never --style=plain'
    alias bat='batcat'
elif command -v bat &> /dev/null; then
    alias cat='bat --paging=never --style=plain'
    alias bat='bat'
fi
alias catn='/bin/cat' # Unaliased cat

# apt
alias aptup='sudo apt update && sudo apt upgrade -y'
alias aptin='sudo apt install'
alias aptrm='sudo apt remove'

# lsd (ls replacement)
if command -v lsd &> /dev/null; then
    alias ll='lsd -lh --group-dirs=first'
    alias la='lsd -a --group-dirs=first'
    alias l='lsd --group-dirs=first'
    alias ls='lsd --group-dirs=first'
else # Fallback ls aliases
    alias ll='ls -alFh --color=auto' # added -h for human readable
    alias la='ls -Ah --color=auto'  # added -h
    alias l='ls -CF --color=auto'
    alias ls='ls --color=auto'
fi

# TMUX Aliases
alias ta='tmux attach -t'
alias tl='tmux list-sessions'
alias ts='tmux new-session -s'
alias tmux='command tmux'
if [ -n "$EDITOR" ]; then
    alias tmuxconf='$EDITOR ~/.config/tmux/tmux.conf'
else
    alias tmuxconf='echo "EDITOR not set; using nvim: "; nvim ~/.config/tmux/tmux.conf'
fi


#------------------------------------------------------------------------------
# Path Sanity: Ensure .local/bin is in PATH
#------------------------------------------------------------------------------
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Add dotfiles bin directory to PATH
if [[ -d "$HOME/dotfiles/bin" ]] && [[ ":$PATH:" != *":$HOME/dotfiles/bin:"* ]]; then
    export PATH="$HOME/dotfiles/bin:$PATH"
fi

#------------------------------------------------------------------------------
# Source .bash_aliases if it exists for further user customization
#------------------------------------------------------------------------------
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Original .bashrc elements (lesspipe)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Ensure dircolors are set up if lsd is not used (for basic ls colors)
if ! command -v lsd &> /dev/null && [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Allow mouse scroll in less (batcat)
export LESS='-R --mouse'
. "$HOME/.cargo/env"
