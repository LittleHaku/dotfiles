#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Prevent errors in a pipeline from being masked.
set -o pipefail

# --- Configuration ---
DOTFILES_DIR_DEFAULT="${HOME}/dotfiles"
GIT_USER_NAME=""                # For full git config
GIT_USER_EMAIL=""               # For SSH key and full git config
FZF_INSTALL_DIR="${HOME}/.fzf"
SSH_KEY_PATH_ED25519="${HOME}/.ssh/id_ed25519"
SSH_KEY_PATH_RSA="${HOME}/.ssh/id_rsa" # Check for RSA as a fallback
NON_INTERACTIVE=false
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

prompt_for_git_email() {
    # This function ensures GIT_USER_EMAIL is set, primarily for SSH key generation.
    # Full git config (name, etc.) happens later.
    if [[ -n "$GIT_USER_EMAIL" ]]; then # If passed as arg
        info "Using provided Git user email for SSH key: $GIT_USER_EMAIL"
        return
    fi

    msg "Git User Email for SSH Key"
    local current_email
    current_email=$(git config --global user.email || true)

    if [ "$NON_INTERACTIVE" = true ]; then
        if [[ -n "$current_email" ]]; then
            GIT_USER_EMAIL="$current_email"
            info "Non-interactive mode: Using existing global Git email for SSH key: $GIT_USER_EMAIL"
        else
            error "Non-interactive mode: --git-email must be provided for SSH key generation if not set globally."
        fi
        return
    fi

    if [[ -n "$current_email" ]]; then
        read -r -p "Enter your email (for SSH key & later Git config) [current: $current_email]: " GIT_USER_EMAIL_INPUT
        GIT_USER_EMAIL=${GIT_USER_EMAIL_INPUT:-$current_email}
    else
        while [[ -z "$GIT_USER_EMAIL" ]]; do
            read -r -p "Enter your email (this will be used for your SSH key and Git config): " GIT_USER_EMAIL
        done
    fi
}

setup_ssh_key_and_add_to_github() {
    msg "GitHub SSH Key Setup"
    local key_to_display=""
    local ssh_output # To capture output from ssh -T

    # Check for existing keys first
    if [[ -f "$SSH_KEY_PATH_ED25519.pub" ]]; then
        key_to_display="$SSH_KEY_PATH_ED25519.pub"
        info "Existing ed25519 SSH public key found: $key_to_display"
    elif [[ -f "$SSH_KEY_PATH_RSA.pub" ]]; then
        key_to_display="$SSH_KEY_PATH_RSA.pub"
        info "Existing RSA SSH public key found: $key_to_display (ed25519 is preferred)"
    fi

    if [[ -n "$key_to_display" ]]; then
        if check_command xclip; then
            cat "$key_to_display" | xclip -selection clipboard
            info "The existing public key has been copied to your clipboard."
        fi
        info "Please ensure this key is added to your GitHub account: https://github.com/settings/keys"

        if ! ask_yes_no "The key above exists. Do you want to generate a NEW ed25519 key (overwriting if exists)?"; then
            info "Attempting to use existing SSH key for GitHub."
            info "Testing SSH connection to GitHub..."
            # Capture all output (stdout and stderr) from ssh -T
            # ssh -T git@github.com prints success message to stderr and exits 1.
            if ssh_output=$(ssh -o LogLevel=ERROR -T git@github.com 2>&1); then # -o LogLevel=ERROR to suppress verbose connection messages on success
                # This 'then' block will likely not be hit due to exit code 1 on success.
                # We primarily care about the output captured.
                : # Do nothing here, success is determined by output check below
            else
                # This 'else' block WILL be hit on success because exit code is 1.
                # It's also hit on other errors (exit code 255, etc.).
                : # Do nothing here, success is determined by output check below
            fi

            # Check if the specific success message is in the captured output
            if echo "$ssh_output" | grep -q "You've successfully authenticated"; then
                 info "SSH connection to GitHub successful with existing key!"
                 # You can optionally print the success message from GitHub:
                 # info "GitHub says: $ssh_output"
                 return 0 # Success
            else
                 warn "SSH connection test with existing key FAILED or did not confirm authentication."
                 warn "Output from GitHub (if any): $ssh_output"
                 warn "The key might not be on GitHub or there's another issue."
                 if ! ask_yes_no "Connection failed or unconfirmed. Generate a new ed25519 key instead?"; then
                    error "SSH setup incomplete. Cannot reliably clone dotfiles via SSH without a working key."
                 fi
                 # If yes, proceed to generate a new key (will fall through to generation block)
            fi
        fi
    fi

    # Generate new key if none found or user opted to regenerate
    if [[ -z "$GIT_USER_EMAIL" ]]; then # Should have been set by prompt_for_git_email
        error "Developer error: GIT_USER_EMAIL is not set before SSH key generation."
    fi

    info "Generating new ed25519 SSH key using email: $GIT_USER_EMAIL"
    mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
    rm -f "${SSH_KEY_PATH_ED25519}" "${SSH_KEY_PATH_ED25519}.pub" # Remove if overwriting
    ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$SSH_KEY_PATH_ED25519" -N "" # No passphrase
    info "New SSH key generated: $SSH_KEY_PATH_ED25519.pub"
    warn "This key was generated WITHOUT a passphrase. For higher security, use a passphrase and ssh-agent."

    msg "IMPORTANT: Add this NEW public SSH key to your GitHub account"
    info "1. The public key content is displayed below."
    if check_command xclip; then
        cat "${SSH_KEY_PATH_ED25519}.pub" | xclip -selection clipboard
        info "   IT HAS BEEN COPIED TO YOUR CLIPBOARD. Paste it into GitHub."
    else
        warn "   xclip not found. Please MANUALLY COPY the entire content below:"
    fi
    echo -e "\033[1;33m"
    cat "${SSH_KEY_PATH_ED25519}.pub"
    echo -e "\033[0m"
    info "2. Go to: https://github.com/settings/keys"
    info "3. Click 'New SSH key', paste the key, and give it a title (e.g., 'DevMachine $(hostname)')."

    if [ "$NON_INTERACTIVE" = true ]; then
        info "Non-interactive mode: Assuming SSH key will be added to GitHub manually or by other automation."
        info "Attempting a final SSH test to GitHub. This may fail if the key is not yet active on GitHub."
        if ssh_output_non_interactive=$(ssh -o LogLevel=ERROR -T git@github.com 2>&1); then :; else :; fi
        if echo "$ssh_output_non_interactive" | grep -q "You've successfully authenticated"; then
            info "Non-interactive SSH test successful."
        else
            warn "Non-interactive SSH test failed or unconfirmed. Key might not be on GitHub yet or network issue."
            warn "Output: $ssh_output_non_interactive"
        fi
        return 0 # Continue in non-interactive
    fi

    # Interactive loop for testing the newly added key
    while true; do
        read -r -p "Press [Enter] AFTER adding the key to GitHub to test, or type 'skip' to continue without testing now: " user_input
        if [[ "$user_input" == "skip" ]]; then
            warn "Skipping SSH connection test. Ensure the key is added for SSH clones to work."
            return 0 # User skipped
        fi
        info "Testing SSH connection to GitHub..."
        if ssh_output_new=$(ssh -o LogLevel=ERROR -T git@github.com 2>&1); then :; else :; fi # Capture output, ignore exit status for now

        if echo "$ssh_output_new" | grep -q "You've successfully authenticated"; then
            info "SSH connection to GitHub successful!"
            # info "GitHub says: $ssh_output_new"
            return 0 # Success
        else
            warn "SSH connection to GitHub FAILED. Output from GitHub (if any): $ssh_output_new"
            warn "Please double-check:"
            warn "  - The key was correctly copied and pasted into https://github.com/settings/keys"
            warn "  - There are no leading/trailing spaces or missing characters in the copied key on GitHub."
            warn "  - You saved the new key on GitHub."
            warn "  - Network connectivity is okay."
        fi
    done
}

clone_dotfiles_via_ssh() {
    local dotfiles_target_dir="$1"

    if [[ -d "$dotfiles_target_dir/.git" ]]; then
        info "Dotfiles directory $dotfiles_target_dir already exists as a Git repository. Checking for updates..."
        if ask_yes_no "Do you want to attempt 'git pull' in $dotfiles_target_dir?"; then
            (cd "$dotfiles_target_dir" && git pull) || warn "git pull failed in $dotfiles_target_dir. Continuing with existing local version."
        fi
        return 0
    elif [[ -d "$dotfiles_target_dir" ]] && [[ -n "$(ls -A "$dotfiles_target_dir")" ]]; then
        warn "Directory $dotfiles_target_dir exists and is not empty, but not a git repo. Skipping clone."
        warn "Please remove or move it if you want to clone your dotfiles here."
        if ! ask_yes_no "Continue setup without cloning dotfiles (some things might not work)?"; then
            error "Exiting as dotfiles directory is problematic."
        fi
        return 1 # Indicate dotfiles are not properly set up
    fi

    local dotfiles_ssh_url_to_use="$DOTFILES_SSH_URL" # Use URL from script args if provided

    if [[ -z "$dotfiles_ssh_url_to_use" ]]; then
        if [ "$NON_INTERACTIVE" = true ]; then
            error "Non-interactive mode: --dotfiles-ssh-url must be provided to clone dotfiles."
        fi
        while [[ -z "$dotfiles_ssh_url_to_use" ]]; do
            read -r -p "Enter the SSH URL for your dotfiles repository (e.g., git@github.com:user/repo.git): " dotfiles_ssh_url_to_use
            if [[ -n "$dotfiles_ssh_url_to_use" && ! "$dotfiles_ssh_url_to_use" =~ ^git@ ]]; then
                warn "The URL doesn't look like an SSH URL (should start with git@). Please verify or re-enter."
                dotfiles_ssh_url_to_use="" # Clear to re-prompt
            fi
        done
    fi

    msg "Cloning dotfiles via SSH from $dotfiles_ssh_url_to_use to $dotfiles_target_dir..."
    if git clone "$dotfiles_ssh_url_to_use" "$dotfiles_target_dir"; then
        info "Dotfiles cloned successfully."
    else
        error "Failed to clone dotfiles repository using SSH. Check URL, SSH key on GitHub, and network."
        return 1 # Indicate failure
    fi
    return 0
}

install_remaining_core_packages() {
    msg "Installing remaining core system packages (Zsh, Stow, build tools)..."
    # build-essential and others were defined in the original `install_core_packages`
    # We ensure they are all installed here, after dotfiles might be present
    # (though their installation is not typically dependent on dotfiles)
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
        ca-certificates # ensure ca-certs are here for any https ops by tools
    info "Remaining core system packages installed."
}


# (Keep original install_zsh_and_set_default, install_fzf_from_git, install_pyenv, install_uv, install_neovim, install_tpm, install_bat, install_lsd functions)
# (Keep original configure_git, stow_dotfiles functions)
# These functions are now called *after* dotfiles are cloned and core tools are installed.

# --- [PREVIOUSLY DEFINED FUNCTIONS - Keep these as they were in your script] ---
# install_zsh_and_set_default() { ... }
# install_fzf_from_git() { ... }
# install_pyenv() { ... }
# install_uv() { ... }
# install_neovim() { ... }
# install_tpm() { ... }
# install_bat() { ... }
# install_lsd() { ... }
# configure_git() { ... } (This one can be called after `prompt_for_git_email` and after dotfiles are stowed if .gitconfig is part of it)
# stow_dotfiles() { ... }
# --- [END OF PREVIOUSLY DEFINED FUNCTIONS PLACEHOLDER] ---
# For brevity, I'll re-paste the simplified stubs or ensure they are called correctly.

# Simplified stubs for functions that were in your original script - fill with your previous definitions
install_zsh_and_set_default() {
    if ! check_command zsh; then error "Zsh not installed. Run install_remaining_core_packages."; fi
    info "Zsh is installed."
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        if ask_yes_no "Set Zsh as your default shell?"; then
            msg "Setting Zsh as default shell..."
            if sudo chsh -s "$(which zsh)" "$USER"; then info "Zsh set as default. Relogin needed.";
            else error "Failed to set Zsh as default."; fi
        else info "Skipping setting Zsh as default."; fi
    else info "Zsh is already default."; fi
}
install_fzf_from_git() {
    if [[ -d "$FZF_INSTALL_DIR" ]] && check_command fzf; then info "fzf already installed."; return; fi
    msg "Installing fzf from Git..."; if [[ -d "$FZF_INSTALL_DIR" ]]; then (cd "$FZF_INSTALL_DIR" && git pull); else git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_INSTALL_DIR"; fi
    "${FZF_INSTALL_DIR}/install" --all --no-update-rc --no-bash --no-fish; info "fzf installed. .zshrc should source it."
}
install_pyenv() {
    if check_command pyenv; then info "pyenv already installed."; return; fi
    msg "Installing pyenv..."; if [[ -d "${HOME}/.pyenv" ]]; then (cd "${HOME}/.pyenv" && git pull); else git clone https://github.com/pyenv/pyenv.git ~/.pyenv; fi
    info "pyenv cloned. .zshrc should handle init."
}
install_uv() {
    if check_command uv; then info "uv already installed."; return; fi
    msg "Installing uv..."; curl -LsSf https://astral.sh/uv/install.sh | sh; info "uv installed. .zshrc should handle PATH."
}
install_neovim() {
    if check_command nvim; then info "Neovim already installed."; return; fi
    msg "Installing Neovim..."; if sudo apt install -y neovim; then info "Neovim installed via apt.";
    else warn "Failed to install Neovim via apt."; fi
}
install_tpm() {
    local tpm_path="$HOME/.tmux/plugins/tpm"; if [ -d "$tpm_path" ]; then info "TPM already installed."; return; fi
    msg "Installing TPM..."; if git clone https://github.com/tmux-plugins/tpm "$tpm_path"; then info "TPM installed. Press prefix + I in Tmux.";
    else error "Failed to clone TPM."; fi
}
install_bat() {
    if check_command batcat || check_command bat; then info "bat/batcat already installed."; return; fi
    msg "Installing bat..."; if sudo apt install -y bat; then info "bat installed (as batcat/bat).";
    else warn "Failed to install bat via apt."; fi
}
install_lsd() {
    if check_command lsd; then info "lsd already installed."; return; fi
    msg "Installing lsd..."; LSD_VERSION=$(curl -s "https://api.github.com/repos/lsd-rs/lsd/releases/latest" | grep -Po '"tag_name": "\K[^"]*' || echo "0.23.1");
    ARCH=$(dpkg --print-architecture); DEB_NAME="lsd_${LSD_VERSION}_${ARCH}.deb"; DOWNLOAD_URL="https://github.com/lsd-rs/lsd/releases/download/${LSD_VERSION}/${DEB_NAME}";
    TEMP_DEB=$(mktemp --suffix=.deb); if wget -O "$TEMP_DEB" "$DOWNLOAD_URL"; then sudo apt install -y "$TEMP_DEB"; info "lsd installed."; rm -f "$TEMP_DEB";
    else error "Failed to download lsd."; rm -f "$TEMP_DEB"; fi
}
configure_git() { # Full git config (name primarily)
    msg "Configuring Global Git User Name..."
    local current_name
    current_name=$(git config --global user.name || true)

    if [[ -z "$GIT_USER_NAME" ]]; then # Only prompt if not set by script argument
        if [ "$NON_INTERACTIVE" = true ] && [[ -z "$current_name" ]]; then
            warn "Non-interactive mode: Git user name not set and no current global config. Please set it manually."
        elif [ "$NON_INTERACTIVE" = true ] && [[ -n "$current_name" ]]; then
            GIT_USER_NAME="$current_name"
            info "Non-interactive mode: Using existing global Git user name: $GIT_USER_NAME"
        else # Interactive mode
            if [[ -n "$current_name" ]]; then
                read -r -p "Enter your Git user name [current: $current_name]: " GIT_USER_NAME_INPUT
                GIT_USER_NAME=${GIT_USER_NAME_INPUT:-$current_name}
            else
                while [[ -z "$GIT_USER_NAME" ]]; do read -r -p "Enter your Git user name: " GIT_USER_NAME; done
            fi
        fi
    fi

    if [[ -n "$GIT_USER_NAME" ]]; then
        git config --global user.name "$GIT_USER_NAME"
        info "Git global user.name set to: $GIT_USER_NAME"
    fi
    # GIT_USER_EMAIL should already be set and configured if --git-email was passed or prompted earlier
    if [[ -n "$GIT_USER_EMAIL" ]]; then
        git config --global user.email "$GIT_USER_EMAIL" # Ensure it's set globally
        info "Git global user.email confirmed: $GIT_USER_EMAIL"
    else
        warn "Git user email was not set. Please configure it manually: git config --global user.email 'you@example.com'"
    fi
    info "Global Git settings configured."
}
stow_dotfiles() {
    local dotfiles_actual_dir="$1"
    if ! check_command stow; then error "Stow not installed."; return 1; fi
    if [[ ! -d "$dotfiles_actual_dir" ]]; then error "Dotfiles dir $dotfiles_actual_dir not found."; return 1; fi
    msg "Stowing dotfiles from $dotfiles_actual_dir..."
    pushd "$dotfiles_actual_dir" > /dev/null
    local stow_packages=("zsh" "tmux", "bash") # Add nvim, git (.gitconfig) etc.
    info "Attempting to stow: ${stow_packages[*]}"
    for pkg in "${stow_packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            info "Stowing $pkg..."; stow --restow --target="$HOME" "$pkg"; info "$pkg stowed."
        else warn "Stow package '$pkg' not found in $dotfiles_actual_dir. Skipping."; fi
    done
    popd > /dev/null; info "Dotfiles stowed."
}


# --- Main Execution ---
main() {
    local DOTFILES_DIR="$DOTFILES_DIR_DEFAULT"

    # Parse arguments first
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --git-name) GIT_USER_NAME="$2"; shift 2 ;;
            --git-email) GIT_USER_EMAIL="$2"; shift 2 ;; # This email is crucial
            --dotfiles-dir) DOTFILES_DIR="$2"; shift 2 ;;
            --dotfiles-ssh-url) DOTFILES_SSH_URL="$2"; shift 2;; # For non-interactive dotfiles clone
            --yes | -y | --non-interactive) NON_INTERACTIVE=true; shift ;;
            *) error "Unknown option: $1" ;;
        esac
    done

    msg "Starting Bootstrap Script (Interactive: $([ "$NON_INTERACTIVE" = true ] && echo "NO" || echo "YES"))"

    # Step 1: Minimal dependencies for Git & SSH setup
    install_initial_dependencies

    # Step 2: Get email for SSH key (critical before SSH setup)
    prompt_for_git_email

    # Step 3: Setup SSH key and ensure it's added to GitHub
    if ! setup_ssh_key_and_add_to_github; then
        # This function now errors internally or user skips test. If it returns non-zero, it's a problem.
        # However, setup_ssh_key_and_add_to_github is designed to be blocking until user confirms or skips.
        # If user skips and key is not working, clone_dotfiles_via_ssh will fail.
        warn "SSH key setup might have been skipped or failed the test. Cloning dotfiles via SSH may not work."
    fi

    # Step 4: Clone dotfiles repository using SSH
    if ! clone_dotfiles_via_ssh "$DOTFILES_DIR"; then
        error "Failed to clone or access dotfiles repository. Essential setup cannot proceed."
        # Consider if script should offer to continue installing some tools even if dotfiles are missing.
        # For a dotfile-centric setup, it often makes sense to stop here.
        exit 1
    fi

    # Step 5: Install Zsh, Stow, and other build dependencies
    # These are needed before setting Zsh as default or stowing configs.
    install_remaining_core_packages

    # Step 6: Set Zsh as default (optional, prompted)
    install_zsh_and_set_default

    # Step 7: Configure Git (name, ensure email is globally set)
    # This can happen after dotfiles are cloned, in case .gitconfig is part of them and gets stowed.
    configure_git

    # Step 8: Stow dotfiles
    if [[ -d "$DOTFILES_DIR" ]]; then # Check again, though clone_dotfiles should ensure it
        if ask_yes_no "Stow dotfiles from $DOTFILES_DIR now?"; then
            stow_dotfiles "$DOTFILES_DIR"
        else
            info "Skipping stowing dotfiles. Manual configuration will be needed."
        fi
    else
        warn "Dotfiles directory $DOTFILES_DIR not found. Cannot stow."
    fi

    # Step 9: Install optional tools (Neovim, fzf, pyenv, uv, bat, lsd, TPM)
    msg "Installing Optional Tools..."
    if ask_yes_no "Install Neovim?"; then install_neovim; else info "Skipping Neovim."; fi
    if ask_yes_no "Install fzf (fuzzy finder)?"; then install_fzf_from_git; else info "Skipping fzf."; fi
    if ask_yes_no "Install PyEnv?"; then install_pyenv; else info "Skipping PyEnv."; fi
    if ask_yes_no "Install uv?"; then install_uv; else info "Skipping uv."; fi
    if ask_yes_no "Install bat (cat clone)?"; then install_bat; else info "Skipping bat."; fi
    if ask_yes_no "Install lsd (ls clone)?"; then install_lsd; else info "Skipping lsd."; fi
    if ask_yes_no "Install TPM (Tmux Plugin Manager)?"; then install_tpm; else info "Skipping TPM."; fi

    msg "Bootstrap script finished!"
    info "---------------------------------------------------------------------"
    info "IMPORTANT NEXT STEPS:"
    info "1. If Zsh was set as default, YOU MUST LOG OUT AND LOG BACK IN for the change to take effect."
    info "2. Open a new terminal. Your Zsh (with stowed .zshrc) should load."
    info "3. If you installed TPM, open Tmux and press 'prefix + I' (capital 'i') to install Tmux plugins."
    info "4. If you installed PyEnv, use 'pyenv install <version>' to install Python versions."
    info "---------------------------------------------------------------------"
}

# Run the main function
main "$@"
