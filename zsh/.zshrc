# ~/.zshrc file for zsh interactive shells.
# see /usr/share/doc/zsh/examples/zshrc for examples

setopt autocd              # change directory just by typing its name
# Trying fuck meanwhile
#setopt correct            # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"


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

#cd up directories
alias ..='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'

# mkdir creates parent directories
alias mkdir='mkdir -pv'

# confirmation when overwrite
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'
alias ln='ln -i'

# folder usage
alias usage='du -h -d1'

# This line or it doesnt work in WSL
#export PATH=$HOME/.local/bin:$PATH
# FUCK
# eval "$(thefuck --alias)"

# Kitty update (launch n so it doesnt execute)
alias kittyupdate='curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n'


# Plugins
plugins=(
    git
    dotenv
    # https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md
    zsh-syntax-highlighting
    # https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
    # Se avanza con la flecha
    zsh-autosuggestions
    # h: history, hs: history grep
    history
    # dos esc ponen sudo
    sudo
    # poner z y la carpeta a la que queremos ir, se va acordando
    z
    # simplifica tmux
    tmux
)
# source /usr/share/zsh-plugins/sudo.plugin.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ivan/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ivan/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ivan/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ivan/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# trying pyenv now
# Virtual env
# export WORKON_HOME=$HOME/.virtualenvs
# export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
# export PROJECT_HOME=$HOME/Devel
# source /usr/local/bin/virtualenvwrapper.sh

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
source $ZSH/oh-my-zsh.sh

# PATH
export PATH="/snap/bin:$PATH"
export PATH=$PATH:/opt/modelsim_ase/bin

# PYENV
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# added to the end because it didnt work if not
#different ls
alias lsn='ls'
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'

# comment all below to disable theme pure
fpath+=($HOME/.oh-my-zsh/themes/pure)
autoload -U promptinit; promptinit
prompt pure
