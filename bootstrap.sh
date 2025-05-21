#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Prevent errors in a pipeline from being masked.
set -o pipefail

# --- Configuration ---
DOTFILES_DIR="${HOME}/dotfiles" # Default location of your dotfiles for stow
GIT_USER_NAME=""                # Leave blank to be prompted
GIT_USER_EMAIL=""               # Leave blank to be prompted
FZF_INSTALL_DIR="${HOME}/.fzf"
SSH_KEY_PATH_ED25519="${HOME}/.ssh/id_ed25519"
SSH_KEY_PATH_RSA="${HOME}/.ssh/id_rsa"

# --- Helper Functions ---
msg() {
    echo -e "\n\033[1;32m===> $1\033[0m\n"
}

info() {
    echo -e "\033[1;34mINFO:\033[0m $1"
}

warn() {
    echo -e "\033[1;33mWARN:\033[0m $1"
}

error() {
    echo -e "\033[1;31mERROR:\033[0m $1" >&2
    exit 1
}

check_command() {
    command -v "$1" &>/dev/null
}

ask_yes_no() {
    local question="$1"
    local default_answer="${2:-yes}" # Default to yes if not specified
    local answer

    while true; do
        if [[ "$default_answer" == "yes" ]]; then
            read -r -p "$question [Y/n]: " answer
            answer=${answer:-Y}
        else
            read -r -p "$question [y/N]: " answer
            answer=${answer:-N}
        fi

        case "$answer" in
            [Yy]* ) return 0;; # Yes
            [Nn]* ) return 1;; # No
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}


# --- Main Setup Functions ---

install_core_packages() {
    msg "Updating package list and installing core packages..."
    sudo apt update
    # Ensure there are NO comments or blank lines between package names in this block
    sudo apt install -y \
        git \
        zsh \
        curl \
        stow \
        wget \
        xclip \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        llvm \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libffi-dev \
        liblzma-dev \
        python3-openssl \
        ca-certificates
    info "Core packages installed. (Includes git, zsh, curl, stow, wget, xclip, build-essential, etc.)"
}

install_zsh_and_set_default() {
    if ! check_command zsh; then
        error "Zsh was not installed with core packages. Please check for errors."
        return 1
    fi
    info "Zsh is installed."

    if [[ "$SHELL" != "$(which zsh)" ]]; then
        if ask_yes_no "Set Zsh as your default shell?"; then
            msg "Setting Zsh as default shell..."
            if sudo chsh -s "$(which zsh)" "$USER"; then
                info "Zsh set as default shell for $USER. You will need to log out and log back in for this to take full effect."
            else
                error "Failed to set Zsh as default shell. Please try manually: sudo chsh -s $(which zsh) $USER"
            fi
        else
            info "Skipping setting Zsh as default shell."
        fi
    else
        info "Zsh is already the default shell for $USER."
    fi
}

setup_ssh_github() {
    msg "Checking SSH keys for GitHub..."
    local key_to_display=""
    local key_type_found=""

    if [[ -f "$SSH_KEY_PATH_ED25519.pub" ]]; then
        key_to_display="$SSH_KEY_PATH_ED25519.pub"
        key_type_found="ed25519"
        info "Existing ed25519 SSH public key found: $key_to_display"
    elif [[ -f "$SSH_KEY_PATH_RSA.pub" ]]; then
        key_to_display="$SSH_KEY_PATH_RSA.pub"
        key_type_found="RSA"
        info "Existing RSA SSH public key found: $key_to_display"
    fi

    if [[ -n "$key_to_display" ]]; then
        info "Ensure this key is added to your GitHub account."
        if check_command xclip; then
            cat "$key_to_display" | xclip -selection clipboard
            info "The existing public key has been copied to your clipboard."
        else
            warn "xclip not found. Please copy the key manually from $key_to_display"
        fi

        if ! ask_yes_no "Do you want to proceed to generate a new ed25519 key anyway (not recommended if the existing key is in use)?"; then
            info "Skipping new SSH key generation."
            return
        fi
    fi

    if [[ -z "$key_to_display" ]] || ask_yes_no "Generate a new ed25519 SSH key for GitHub?"; then
        local ssh_email
        if [[ -n "$GIT_USER_EMAIL" ]]; then
            read -r -p "Enter your email for the SSH key [default: $GIT_USER_EMAIL]: " ssh_email_input
            ssh_email=${ssh_email_input:-$GIT_USER_EMAIL}
        else
            while [[ -z "$ssh_email" ]]; do read -r -p "Enter your email for the SSH key: " ssh_email; done
        fi

        info "Generating ed25519 SSH key..."
        mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
        rm -f "${SSH_KEY_PATH_ED25519}" "${SSH_KEY_PATH_ED25519}.pub" # Remove old ed25519 if regenerating
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$SSH_KEY_PATH_ED25519" -N ""
        info "SSH key generated at $SSH_KEY_PATH_ED25519"
        warn "The key was generated WITHOUT a passphrase for script simplicity. For higher security, consider generating one with a passphrase manually."

        msg "IMPORTANT: Add this public SSH key to your GitHub account:"
        info "1. The public key content is displayed below."
        if check_command xclip; then
            cat "${SSH_KEY_PATH_ED25519}.pub" | xclip -selection clipboard
            info "   IT HAS BEEN COPIED TO YOUR CLIPBOARD. Just paste it into GitHub."
        else
            warn "   xclip not found. Please MANUALLY COPY the entire content below (starting with ssh-ed25519...):"
        fi
        echo -e "\033[1;33m"
        cat "${SSH_KEY_PATH_ED25519}.pub"
        echo -e "\033[0m"
        info "2. Go to GitHub > Settings > SSH and GPG keys > New SSH key."
        info "3. Paste the key and give it a title (e.g., 'Dev Laptop $(hostname)')."
        read -r -p "Press [Enter] to continue after you've added the key to GitHub..."
    else
        info "Skipping SSH key generation."
    fi
}


install_fzf_from_git() {
    if [[ -d "$FZF_INSTALL_DIR" ]] && check_command fzf; then
        info "fzf appears to be already installed in $FZF_INSTALL_DIR."
        return
    fi
    msg "Installing fzf from Git..."
    if [[ -d "$FZF_INSTALL_DIR" ]]; then
        info "Updating existing fzf installation in $FZF_INSTALL_DIR..."
        (cd "$FZF_INSTALL_DIR" && git pull)
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_INSTALL_DIR"
    fi
    info "Running fzf install script..."
    "${FZF_INSTALL_DIR}/install" --all --no-update-rc --no-bash --no-fish
    info "fzf installed. Your .zshrc should source ~/.fzf.zsh to enable it."
}


install_pyenv() {
    if check_command pyenv; then
        info "pyenv command is already available. Assuming it's correctly installed."
        return
    fi
    msg "Installing pyenv..."
    if [[ -d "${HOME}/.pyenv" ]]; then
        warn "Found existing ~/.pyenv directory. Skipping clone, but attempting to update."
        (cd "${HOME}/.pyenv" && git pull)
    else
        git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    fi
    info "pyenv cloned to ~/.pyenv. Your .zshrc should handle initialization."
}

install_uv() {
    if check_command uv; then
        info "uv is already installed."
        return
    fi
    msg "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    info "uv installation script completed. Your .zshrc should handle PATH setup."
}

install_bat() {
    if check_command batcat || check_command bat; then
        info "bat (or batcat) is already installed."
        return
    fi
    msg "Installing bat (as batcat via apt package 'bat')..."
    if sudo apt install -y bat; then
        info "bat installed. It should be available as 'batcat' (and often 'bat'). Your .zshrc aliases 'cat' to 'batcat'."
    else
        warn "Failed to install 'bat' via apt. You might need to install it from GitHub releases manually."
    fi
}

install_lsd() {
    if check_command lsd; then
        info "lsd is already installed."
        return
    fi
    msg "Installing lsd (modern ls)..."
    LSD_VERSION=$(curl -s "https://api.github.com/repos/lsd-rs/lsd/releases/latest" | grep -Po '"tag_name": "\K[^"]*' || echo "0.23.1")
    if [[ -z "$LSD_VERSION" ]]; then
        warn "Could not fetch latest lsd version. Using fallback $LSD_VERSION."
        LSD_VERSION="0.23.1"
    fi
    ARCH=$(dpkg --print-architecture)
    DEB_NAME="lsd_${LSD_VERSION}_${ARCH}.deb"
    DOWNLOAD_URL="https://github.com/lsd-rs/lsd/releases/download/${LSD_VERSION}/${DEB_NAME}"
    info "Attempting to download lsd version ${LSD_VERSION} for ${ARCH} from $DOWNLOAD_URL"
    TEMP_DEB=$(mktemp --suffix=.deb)
    if wget -O "$TEMP_DEB" "$DOWNLOAD_URL"; then
        info "lsd downloaded. Installing..."
        if sudo apt install -y "$TEMP_DEB"; then info "lsd installed successfully."; else error "Failed to install lsd from .deb."; fi
        rm -f "$TEMP_DEB"
    else
        error "Failed to download lsd .deb package. Please check the URL or install manually."
        rm -f "$TEMP_DEB"
    fi
}


configure_git() {
    msg "Configuring Git..."
    local current_name current_email
    current_name=$(git config --global user.name || true)
    current_email=$(git config --global user.email || true)

    if [[ -z "$GIT_USER_NAME" ]]; then
        if [[ -n "$current_name" ]]; then
            read -r -p "Enter your Git user name [current: $current_name]: " GIT_USER_NAME_INPUT
            GIT_USER_NAME=${GIT_USER_NAME_INPUT:-$current_name}
        else
            while [[ -z "$GIT_USER_NAME" ]]; do read -r -p "Enter your Git user name: " GIT_USER_NAME; done
        fi
    fi
    if [[ -z "$GIT_USER_EMAIL" ]]; then
        if [[ -n "$current_email" ]]; then
            read -r -p "Enter your Git user email [current: $current_email]: " GIT_USER_EMAIL_INPUT
            GIT_USER_EMAIL=${GIT_USER_EMAIL_INPUT:-$current_email}
        else
            while [[ -z "$GIT_USER_EMAIL" ]]; do read -r -p "Enter your Git user email: " GIT_USER_EMAIL; done
        fi
    fi
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    info "Git user name set to: $GIT_USER_NAME"
    info "Git user email set to: $GIT_USER_EMAIL"
    info "Git configured."
}

stow_dotfiles() {
    if ! check_command stow; then
        error "Stow is not installed (should have been in core packages)."
        return 1
    fi
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        error "Dotfiles directory not found at $DOTFILES_DIR. Please clone or create it first."
        return 1
    fi
    msg "Stowing dotfiles from $DOTFILES_DIR..."
    pushd "$DOTFILES_DIR" > /dev/null
    local stow_packages=("zsh" "tmux") # Customize as needed
    info "Attempting to stow: ${stow_packages[*]}"
    for pkg in "${stow_packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            info "Stowing $pkg..."
            stow --restow --target="$HOME" "$pkg"
            info "$pkg stowed."
        else
            warn "Stow package directory '$pkg' not found in $DOTFILES_DIR. Skipping."
        fi
    done
    popd > /dev/null
    info "Dotfiles stowed."
}

# --- Main Execution ---
main() {
    msg "Starting Development Environment Setup"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --git-name) GIT_USER_NAME="$2"; shift 2 ;;
            --git-email) GIT_USER_EMAIL="$2"; shift 2 ;;
            --dotfiles-dir) DOTFILES_DIR="$2"; shift 2 ;;
            *) error "Unknown option: $1" ;;
        esac
    done

    install_core_packages       # Essential, non-optional (now includes xclip)
    install_zsh_and_set_default # Zsh itself is core, setting default is prompted
    configure_git               # Essential for dev work, prompts for info
    setup_ssh_github            # Prompted internally, now with xclip support

    if ask_yes_no "Install fzf (fuzzy finder) from Git?"; then install_fzf_from_git; else info "Skipping fzf."; fi
    if ask_yes_no "Install PyEnv (Python version manager)?"; then install_pyenv; else info "Skipping PyEnv."; fi
    if ask_yes_no "Install uv (Python package/virtual env manager)?"; then install_uv; else info "Skipping uv."; fi
    if ask_yes_no "Install bat (cat clone with syntax highlighting)?"; then install_bat; else info "Skipping bat."; fi
    if ask_yes_no "Install lsd (modern ls with icons)?"; then install_lsd; else info "Skipping lsd."; fi

    stow_dotfiles # Stow after tools are available, as dotfiles might reference them

    msg "Setup script finished!"
    info "IMPORTANT: Some changes (like default shell or SSH keys) may require you to:"
    info "1. Log out and log back in."
    info "2. Or, for immediate effect in the current Zsh shell (if already running Zsh),"
    info "   source your newly stowed .zshrc: source ~/.zshrc"
    info "Please also ensure your new SSH key (if generated) is added to GitHub if you haven't already."
}

# Run the main function
main "$@"
