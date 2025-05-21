# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Source .bashrc if it exists
if [ -f "${HOME}/.bashrc" ]; then
    source "${HOME}/.bashrc"
fi

