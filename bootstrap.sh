#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Prevent errors in a pipeline from being masked.
set -o pipefail

# --- Configuration ---
DOTFILES_DIR_DEFAULT="${HOME}/dotfiles"
FZF_INSTALL_DIR="${HOME}/.fzf"
SSH_KEY_PATH_ED25519="${HOME}/.ssh/id_ed25519"
SSH_KEY_PATH_RSA="${HOME}/.ssh/id_rsa" # Check for RSA as a fallback
NON_INTERACTIVE=false
FORCE_WSL=false  # Add this flag
DOTFILES_SSH_URL="" # To be filled by prompt or --dotfiles-ssh-url arg

# --- Helper Functions ---
msg() { echo -e "\n\033[1;32m===> $1\033[0m\n"; }
info() { echo -e "\033[1;34mINFO:\033[0m $1"; }
warn() { echo -e "\033[1;33mWARN:\033[0m $1"; }
error() { echo -e "\033[1;31mERROR:\033[0m $1" >&2; exit 1; }
check_command() { command -v "$1" &>/dev/null; }

ask_yes_no() {
    if [ "$NON_INTERACTIVE" = true ]; then
        info "Non-interactive mode: Answering YES to '$1'"
        return 0
    fi
    local question="$1"; local default_answer="${2:-yes}"; local answer
    while true; do
        if [[ "$default_answer" == "yes" ]]; then
            read -r -p "$question [Y/n]: " answer; answer=${answer:-Y}
        else
            read -r -p "$question [y/N]: " answer; answer=${answer:-N}
        fi
        case "$answer" in
            [Yy]* ) return 0;; [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Check if running in WSL
is_wsl() {
    [[ "$FORCE_WSL" == "true" ]] || [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null
}

# --- Setup Functions ---

install_initial_dependencies() {
    msg "Updating package list and installing initial dependencies for bootstrap..."
    sudo apt update
    sudo apt install -y \
        git \
        curl \
        wget \
        xclip # For copying SSH key
    info "Initial dependencies installed."
}

setup_ssh_key_configuration() {
    msg "SSH Key Configuration"

    # Check if we're in WSL
    if is_wsl; then
        info "WSL environment detected."

        # If --wsl flag was used, try Windows SSH keys first
        if [[ "$FORCE_WSL" == "true" ]]; then
            info "WSL mode: Attempting to use Windows SSH keys..."
            if setup_wsl_ssh_symlinks; then
                return 0
            else
                warn "Could not find Windows SSH keys. Falling back to other options."
            fi
        fi

        echo "SSH Key options for WSL:"
        echo "1. Use existing SSH keys from Windows host"
        echo "2. Generate new SSH keys in WSL"
        echo "3. Skip SSH key setup (use HTTPS for Git operations)"
        echo "4. I already have SSH keys configured in WSL"

        while true; do
            read -r -p "Choose option (1-4): " wsl_choice
            case "$wsl_choice" in
                1)
                    setup_wsl_ssh_symlinks
                    return 0
                    ;;
                2)
                    setup_ssh_key_generation
                    return 0
                    ;;
                3)
                    info "Skipping SSH key setup. Will use HTTPS for Git operations."
                    return 1  # Indicate SSH not set up
                    ;;
                4)
                    verify_existing_ssh_keys
                    return $?
                    ;;
                *)
                    echo "Please choose 1, 2, 3, or 4."
                    ;;
            esac
        done
    else
        # Non-WSL environment
        echo "SSH Key options:"
        echo "1. Generate new SSH keys"
        echo "2. Use existing SSH keys"
        echo "3. Skip SSH key setup (use HTTPS for Git operations)"

        while true; do
            read -r -p "Choose option (1-3): " choice
            case "$choice" in
                1)
                    setup_ssh_key_generation
                    return 0
                    ;;
                2)
                    verify_existing_ssh_keys
                    return $?
                    ;;
                3)
                    info "Skipping SSH key setup. Will use HTTPS for Git operations."
                    return 1  # Indicate SSH not set up
                    ;;
                *)
                    echo "Please choose 1, 2, or 3."
                    ;;
            esac
        done
    fi
}

setup_wsl_ssh_symlinks() {
    msg "Setting up SSH key symlinks to Windows host"

    # Common Windows SSH key locations from WSL
    local windows_ssh_paths=(
        "/mnt/c/Users/$(whoami)/.ssh"
        "/mnt/c/Users/${USER}/.ssh"
    )

    # Try to find Windows user directory
    local windows_user_dirs=(/mnt/c/Users/*)
    if [[ ${#windows_user_dirs[@]} -eq 1 ]]; then
        windows_ssh_paths+=("${windows_user_dirs[0]}/.ssh")
    fi

    local found_windows_ssh=false
    for windows_ssh_dir in "${windows_ssh_paths[@]}"; do
        if [[ -d "$windows_ssh_dir" ]] && [[ -f "$windows_ssh_dir/id_ed25519" || -f "$windows_ssh_dir/id_rsa" ]]; then
            info "Found Windows SSH directory: $windows_ssh_dir"
            found_windows_ssh=true

            # Create WSL .ssh directory
            mkdir -p "${HOME}/.ssh"
            chmod 700 "${HOME}/.ssh"

            # Create symlinks
            for key_type in id_ed25519 id_rsa; do
                if [[ -f "$windows_ssh_dir/$key_type" ]]; then
                    ln -sf "$windows_ssh_dir/$key_type" "${HOME}/.ssh/$key_type"
                    ln -sf "$windows_ssh_dir/$key_type.pub" "${HOME}/.ssh/$key_type.pub"
                    info "Symlinked $key_type keys from Windows"
                fi
            done

            # Copy/symlink config if it exists
            if [[ -f "$windows_ssh_dir/config" ]]; then
                ln -sf "$windows_ssh_dir/config" "${HOME}/.ssh/config"
                info "Symlinked SSH config from Windows"
            fi

            break
        fi
    done

    if [[ "$found_windows_ssh" = false ]]; then
        if [[ "$FORCE_WSL" == "true" ]]; then
            warn "Could not find Windows SSH keys in expected locations."
            return 1  # Return failure for auto-mode
        fi

        warn "Could not find Windows SSH keys in expected locations."
        echo "Please manually specify the Windows SSH directory path:"
        read -r -p "Windows SSH directory (e.g., /mnt/c/Users/YourName/.ssh): " custom_windows_ssh

        if [[ -d "$custom_windows_ssh" ]]; then
            mkdir -p "${HOME}/.ssh"
            chmod 700 "${HOME}/.ssh"

            for key_type in id_ed25519 id_rsa; do
                if [[ -f "$custom_windows_ssh/$key_type" ]]; then
                    ln -sf "$custom_windows_ssh/$key_type" "${HOME}/.ssh/$key_type"
                    ln -sf "$custom_windows_ssh/$key_type.pub" "${HOME}/.ssh/$key_type.pub"
                    info "Symlinked $key_type keys from $custom_windows_ssh"
                fi
            done
        else
            error "Invalid Windows SSH directory path: $custom_windows_ssh"
        fi
    fi

    # Test the symlinked keys
    verify_existing_ssh_keys
}

verify_existing_ssh_keys() {
    msg "Verifying existing SSH keys"

    local key_to_use=""
    if [[ -f "$SSH_KEY_PATH_ED25519" ]]; then
        key_to_use="$SSH_KEY_PATH_ED25519"
        info "Found ed25519 SSH key: $SSH_KEY_PATH_ED25519"
    elif [[ -f "$SSH_KEY_PATH_RSA" ]]; then
        key_to_use="$SSH_KEY_PATH_RSA"
        info "Found RSA SSH key: $SSH_KEY_PATH_RSA"
    else
        warn "No SSH keys found in expected locations."
        return 1
    fi

    # Display public key
    if [[ -f "${key_to_use}.pub" ]]; then
        info "Public key content:"
        echo -e "\033[1;33m"
        cat "${key_to_use}.pub"
        echo -e "\033[0m"

        if check_command xclip; then
            cat "${key_to_use}.pub" | xclip -selection clipboard
            info "Public key copied to clipboard."
        fi
    fi

    # Test SSH connection to GitHub
    if ask_yes_no "Test SSH connection to GitHub?"; then
        test_github_ssh_connection
        return $?
    fi

    return 0
}

setup_ssh_key_generation() {
    msg "SSH Key Generation"

    # Prompt for email (still needed for SSH key generation)
    local git_email=""
    git_email=$(git config --global user.email 2>/dev/null || true)

    if [[ -n "$git_email" ]]; then
        read -r -p "Enter email for SSH key [current Git email: $git_email]: " email_input
        git_email=${email_input:-$git_email}
    else
        while [[ -z "$git_email" ]]; do
            read -r -p "Enter email for SSH key generation: " git_email
        done
    fi

    # Check for existing keys
    if [[ -f "$SSH_KEY_PATH_ED25519" ]]; then
        warn "SSH key already exists: $SSH_KEY_PATH_ED25519"
        if ! ask_yes_no "Overwrite existing key?"; then
            info "Using existing key."
            verify_existing_ssh_keys
            return $?
        fi
    fi

    # Generate new key
    info "Generating new ed25519 SSH key with email: $git_email"
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    # Ask about passphrase
    local use_passphrase=false
    if ask_yes_no "Use a passphrase for the SSH key (recommended for security)?"; then
        use_passphrase=true
        info "You will be prompted to enter a passphrase for the key."
        ssh-keygen -t ed25519 -C "$git_email" -f "$SSH_KEY_PATH_ED25519"
    else
        warn "Generating key WITHOUT passphrase. Consider using ssh-agent for better security practices."
        ssh-keygen -t ed25519 -C "$git_email" -f "$SSH_KEY_PATH_ED25519" -N ""
    fi

    info "SSH key generated: ${SSH_KEY_PATH_ED25519}.pub"

    # Display and copy public key
    msg "Your new SSH public key:"
    echo -e "\033[1;33m"
    cat "${SSH_KEY_PATH_ED25519}.pub"
    echo -e "\033[0m"

    if check_command xclip; then
        cat "${SSH_KEY_PATH_ED25519}.pub" | xclip -selection clipboard
        info "Public key copied to clipboard."
    fi

    info "Add this key to your GitHub account: https://github.com/settings/keys"

    # Interactive loop for testing
    while true; do
        read -r -p "Press [Enter] after adding the key to GitHub to test, or type 'skip' to continue: " user_input
        if [[ "$user_input" == "skip" ]]; then
            warn "Skipping SSH test. Ensure the key is added for SSH operations to work."
            return 0
        fi

        if test_github_ssh_connection; then
            return 0
        else
            warn "SSH test failed. Please verify the key was added correctly to GitHub."
        fi
    done
}

test_github_ssh_connection() {
    info "Testing SSH connection to GitHub..."
    local ssh_output

    # Capture SSH output
    if ssh_output=$(ssh -o LogLevel=ERROR -T git@github.com 2>&1); then
        :  # Success case (unlikely due to exit code 1)
    else
        :  # Expected case (GitHub returns exit code 1 on successful auth)
    fi

    if echo "$ssh_output" | grep -q "You've successfully authenticated"; then
        info "SSH connection to GitHub successful!"
        return 0
    else
        warn "SSH connection failed or unconfirmed."
        warn "GitHub response: $ssh_output"
        return 1
    fi
}

clone_dotfiles_repository() {
    local dotfiles_target_dir="$1"
    local use_ssh="$2"  # true/false

    if [[ -d "$dotfiles_target_dir/.git" ]]; then
        info "Dotfiles directory already exists as a Git repository."
        if ask_yes_no "Update existing dotfiles with 'git pull'?"; then
            (cd "$dotfiles_target_dir" && git pull) || warn "git pull failed. Continuing with existing version."
        fi
        return 0
    elif [[ -d "$dotfiles_target_dir" ]] && [[ -n "$(ls -A "$dotfiles_target_dir")" ]]; then
        warn "Directory $dotfiles_target_dir exists and is not empty."
        if ask_yes_no "Remove existing directory and clone fresh?"; then
            rm -rf "$dotfiles_target_dir"
        else
            warn "Cannot proceed with existing non-git directory."
            return 1
        fi
    fi

    # Get repository URL
    local repo_url=""
    if [[ -n "$DOTFILES_SSH_URL" ]]; then
        repo_url="$DOTFILES_SSH_URL"
    else
        if [[ "$use_ssh" == "true" ]]; then
            while [[ -z "$repo_url" ]]; do
                read -r -p "Enter SSH URL for dotfiles (git@github.com:user/repo.git): " repo_url
                if [[ ! "$repo_url" =~ ^git@ ]]; then
                    warn "SSH URL should start with 'git@'. Please verify."
                    repo_url=""
                fi
            done
        else
            while [[ -z "$repo_url" ]]; do
                read -r -p "Enter HTTPS URL for dotfiles (https://github.com/user/repo.git): " repo_url
                if [[ ! "$repo_url" =~ ^https:// ]]; then
                    warn "HTTPS URL should start with 'https://'. Please verify."
                    repo_url=""
                fi
            done
        fi
    fi

    # Clone repository
    msg "Cloning dotfiles from $repo_url..."
    if git clone "$repo_url" "$dotfiles_target_dir"; then
        info "Dotfiles cloned successfully."
        return 0
    else
        error "Failed to clone dotfiles repository."
        return 1
    fi
}

install_remaining_core_packages() {
    msg "Installing remaining core system packages..."
    sudo apt install -y \
        zsh \
        stow \
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
    info "Core system packages installed."
}

# Keep your existing functions for tool installation
install_zsh_and_set_default() {
    if ! check_command zsh; then error "Zsh not installed. Run install_remaining_core_packages."; fi
    info "Zsh is installed."
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        if ask_yes_no "Set Zsh as your default shell?"; then
            msg "Setting Zsh as default shell..."
            if sudo chsh -s "$(which zsh)" "$USER"; then
                info "Zsh set as default. You'll need to log out and back in for this to take effect."
            else
                error "Failed to set Zsh as default."
            fi
        else
            info "Skipping setting Zsh as default."
        fi
    else
        info "Zsh is already the default shell."
    fi
}

# Fixed function name
install_fzf() {
    if [[ -d "$FZF_INSTALL_DIR" ]] && check_command fzf; then
        info "fzf already installed."
        return
    fi
    msg "Installing fzf from Git..."
    if [[ -d "$FZF_INSTALL_DIR" ]]; then
        (cd "$FZF_INSTALL_DIR" && git pull)
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_INSTALL_DIR"
    fi
    "${FZF_INSTALL_DIR}/install" --all --no-update-rc --no-bash --no-fish
    info "fzf installed. Your .zshrc should source it."
}

install_pyenv() {
    if check_command pyenv; then
        info "pyenv already installed."
        return
    fi
    msg "Installing pyenv..."
    if [[ -d "${HOME}/.pyenv" ]]; then
        (cd "${HOME}/.pyenv" && git pull)
    else
        git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    fi
    info "pyenv installed. Your .zshrc should handle initialization."
}

install_uv() {
    if check_command uv; then
        info "uv already installed."
        return
    fi
    msg "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    info "uv installed. Your .zshrc should handle PATH."
}

install_neovim() {
    if check_command nvim; then
        info "Neovim already installed."
        return
    fi
    msg "Installing latest stable Neovim..."
    if sudo add-apt-repository -y ppa:neovim-ppa/stable 2>/dev/null; then
        sudo apt update
        if sudo apt install -y neovim; then
            info "Latest stable Neovim installed from PPA."
            return
        fi
    fi

    warn "PPA installation failed. Trying system package..."
    if sudo apt install -y neovim; then
        info "Neovim installed via system package."
    else
        warn "Failed to install Neovim."
    fi
}

install_tpm() {
    local tmp_path="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tmp_path" ]]; then
        info "TPM already installed."
        return
    fi
    msg "Installing TPM (Tmux Plugin Manager)..."
    if git clone https://github.com/tmux-plugins/tpm "$tmp_path"; then
        info "TPM installed. Press prefix + I in Tmux to install plugins."
    else
        error "Failed to install TPM."
    fi
}

install_bat() {
    if check_command batcat || check_command bat; then
        info "bat already installed."
        return
    fi
    msg "Installing bat..."
    if sudo apt install -y bat; then
        info "bat installed (available as 'batcat' or 'bat')."
    else
        warn "Failed to install bat."
    fi
}

install_lsd() {
    if check_command lsd; then
        info "lsd already installed."
        return
    fi
    msg "Installing lsd..."
    local lsd_version
    lsd_version=$(curl -s "https://api.github.com/repos/lsd-rs/lsd/releases/latest" | grep -Po '"tag_name": "\K[^"]*' || echo "0.23.1")
    local arch
    arch=$(dpkg --print-architecture)
    local deb_name="lsd_${lsd_version}_${arch}.deb"
    local download_url="https://github.com/lsd-rs/lsd/releases/download/${lsd_version}/${deb_name}"
    local temp_deb
    temp_deb=$(mktemp --suffix=.deb)

    if wget -O "$temp_deb" "$download_url"; then
        sudo apt install -y "$temp_deb"
        info "lsd installed."
        rm -f "$temp_deb"
    else
        error "Failed to download lsd."
        rm -f "$temp_deb"
    fi
}

install_vscode() {
    if is_wsl; then
        warn "Skipping VS Code installation in WSL environment."
        return
    fi
    if check_command code; then
        info "VS Code already installed."
        return
    fi

    msg "Installing Visual Studio Code…"
    # Import Microsoft GPG key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
    rm microsoft.gpg
    # Add VS Code repo
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] \
      https://packages.microsoft.com/repos/code stable main" \
      | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo apt update
    sudo apt install -y code
    info "Visual Studio Code installed."
}

# Add new installers
install_docker() {
    if is_wsl; then
        warn "Skipping Docker in WSL; use Docker Desktop on Windows."
        return
    fi
    msg "Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    info "Docker installed. Log out and back in to use without sudo."
}

install_spotify_adblock() {
    if is_wsl; then
        warn "Skipping spotify-adblock in WSL."
        return
    fi
    msg "Installing spotify-adblock..."
    sudo rm -rf /opt/spotify-adblock
    sudo git clone https://github.com/abba23/spotify-adblock.git /opt/spotify-adblock
    sudo bash /opt/spotify-adblock/install.sh
    info "spotify-adblock installed."
}

install_discord() {
    if is_wsl; then
        warn "Skipping Discord in WSL."
        return
    fi
    msg "Installing Discord via snap..."
    if check_command snap; then
        sudo snap install discord
        info "Discord installed."
    else
        warn "snap not available; Discord skipped."
    fi
}

install_steam() {
    if is_wsl; then
        warn "Skipping Steam in WSL."
        return
    fi
    msg "Installing Steam..."
    sudo apt install -y steam
    info "Steam installed."
}

install_vlc() {
    if is_wsl; then
        warn "Skipping VLC in WSL."
        return
    fi
    msg "Installing VLC..."
    sudo apt install -y vlc
    info "VLC installed."
}

install_torbrowser() {
    if is_wsl; then
        warn "Skipping Tor Browser in WSL."
        return
    fi
    msg "Installing Tor Browser Launcher..."
    sudo apt install -y torbrowser-launcher
    info "Tor Browser Launcher installed."
}

stow_dotfiles() {
    local dotfiles_dir="$1"
    if ! check_command stow; then
        error "Stow not installed."
        return 1
    fi
    if [[ ! -d "$dotfiles_dir" ]]; then
        error "Dotfiles directory $dotfiles_dir not found."
        return 1
    fi

    msg "Stowing dotfiles from $dotfiles_dir..."
    pushd "$dotfiles_dir" > /dev/null

    # collect all sub-dirs
    local all_packages=()
    for dir in */; do
        all_packages+=("${dir%/}")
    done

    # Windows-only packages to drop
    local windows_packages=(ahk komorebi whkd)

    # build list excluding windows ones
    local available_packages=()
    for pkg in "${all_packages[@]}"; do
        if [[ " ${windows_packages[*]} " == *" $pkg "* ]]; then
            info "Skipping Windows-specific package: $pkg"
            continue
        fi
        available_packages+=("$pkg")
    done

    if [[ ${#available_packages[@]} -eq 0 ]]; then
        warn "No suitable packages found for this environment"
        popd > /dev/null
        return 1
    fi

    info "Available packages for this environment: ${available_packages[*]}"

    # prompt only on the remaining packages
    for pkg in "${available_packages[@]}"; do
        if ask_yes_no "Stow $pkg?"; then
            info "Stowing $pkg..."
            stow --restow --target="$HOME" "$pkg" \
              && info "$pkg stowed successfully." \
              || warn "Failed to stow $pkg."
        else
            info "Skipping $pkg."
        fi
    done

    popd > /dev/null
    info "Dotfiles stowing completed."
}

# --- Main Execution ---
main() {
    local DOTFILES_DIR="$DOTFILES_DIR_DEFAULT"
    local ssh_configured=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dotfiles-dir) DOTFILES_DIR="$2"; shift 2 ;;
            --dotfiles-ssh-url) DOTFILES_SSH_URL="$2"; shift 2 ;;
            --yes | -y | --non-interactive) NON_INTERACTIVE=true; shift ;;
            --wsl) FORCE_WSL=true; shift ;;
            *) error "Unknown option: $1" ;;
        esac
    done

    msg "Starting Bootstrap Script"
    info "Interactive mode: $([ "$NON_INTERACTIVE" = true ] && echo "NO" || echo "YES")"
    if is_wsl; then
        info "WSL environment detected"
        if [[ "$FORCE_WSL" == "true" ]]; then
            info "WSL mode enabled via --wsl flag"
        fi
    fi

    # Step 1: Install initial dependencies
    install_initial_dependencies

    # Step 2: Configure SSH (interactive choice)
    if setup_ssh_key_configuration; then
        ssh_configured=true
        info "SSH keys configured successfully."
    else
        ssh_configured=false
        info "SSH keys not configured. Will use HTTPS for Git operations."
    fi

    # Step 3: Clone dotfiles (Git config will come from stowed dotfiles)
    if ask_yes_no "Clone/update dotfiles repository?"; then
        if ! clone_dotfiles_repository "$DOTFILES_DIR" "$ssh_configured"; then
            warn "Failed to clone dotfiles. Some setup steps may not work correctly."
        fi
    else
        info "Skipping dotfiles clone."
    fi

    # Step 4: Install core packages
    install_remaining_core_packages

    # Step 5: Set up Zsh
    if ask_yes_no "Install and configure Zsh?"; then
        install_zsh_and_set_default
    fi

    # Step 6: Stow dotfiles (this will set up Git config)
    if [[ -d "$DOTFILES_DIR" ]] && ask_yes_no "Stow dotfiles?"; then
        stow_dotfiles "$DOTFILES_DIR"
        info "Git configuration has been applied from your dotfiles."
    fi

    # Step 7: Install optional tools
    msg "Optional Tools Installation"

    # WSL-optimized tool list
    local tools=()
    if is_wsl; then
        tools=(
            "neovim:Install Neovim?"
            "fzf:Install fzf (fuzzy finder)?"
            "pyenv:Install PyEnv?"
            "uv:Install uv (Python package manager)?"
            "bat:Install bat (better cat)?"
            "lsd:Install lsd (better ls)?"
            "tpm:Install TPM (Tmux Plugin Manager)?"
        )
        info "WSL detected: Skipping GUI applications (VS Code, Discord, Steam, VLC, Tor Browser, Docker, Spotify)"
    else
        tools=(
            "neovim:Install Neovim?"
            "fzf:Install fzf (fuzzy finder)?"
            "pyenv:Install PyEnv?"
            "uv:Install uv (Python package manager)?"
            "bat:Install bat (better cat)?"
            "lsd:Install lsd (better ls)?"
            "tpm:Install TPM (Tmux Plugin Manager)?"
            "vscode:Install VS Code?"
            "docker:Install Docker?"
            "spotify_adblock:Install Spotify (adblock)?"
            "discord:Install Discord?"
            "steam:Install Steam?"
            "vlc:Install VLC?"
            "torbrowser:Install Tor Browser?"
        )
    fi

    for tool_info in "${tools[@]}"; do
        IFS=':' read -r tool_name tool_question <<< "$tool_info"

        if ask_yes_no "$tool_question"; then
            # Call the function using the correct name
            "install_$tool_name"
        else
            info "Skipping $tool_name."
        fi
    done

    # Final message
    msg "Bootstrap script completed!"
    info "=========================================="
    info "NEXT STEPS:"
    info "1. If Zsh was set as default, log out and back in"
    info "2. Open a new terminal to test your configuration"
    info "3. If TPM was installed, use 'prefix + I' in Tmux"
    info "4. If PyEnv was installed, use 'pyenv install <version>'"
    if [[ "$ssh_configured" == "false" ]]; then
        info "5. Consider setting up SSH keys for easier Git operations"
    fi
    info "=========================================="
}

# Run the main function
main "$@"
