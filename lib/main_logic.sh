#!/bin/bash

# Convert repository to SSH if it exists and is HTTPS
function convert_repo_to_ssh_if_needed {
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        current_dir=$(pwd)
        cd "$DOTFILES_DIR" || return 1 # Exit if cd fails
        current_remote=$(git remote get-url origin 2>/dev/null || echo "")

        if [[ "$current_remote" == "$DOTFILES_REPO_HTTPS" ]]; then
            __task "Converting repository remote from HTTPS to SSH"
            if _cmd "git remote set-url origin $DOTFILES_REPO_SSH"; then
                _task_done
            else
                # _cmd would have exited on error, but defensive coding
                _task_error "Failed to convert remote to SSH."
            fi
        elif [[ "$current_remote" == "$DOTFILES_REPO_SSH" ]]; then
            echo -e "${GREEN}Dotfiles repository is already using SSH remote.${NC}"
        elif [[ -n "$current_remote" ]]; then
            echo -e "${YELLOW}Dotfiles repository remote is '$current_remote', not changing.${NC}"
        fi
        cd "$current_dir" || return 1
    fi
}

# Show help information
function show_help {
    echo -e "${BLUE}DotFiles Management Script${NC}"
    echo -e "${GREEN}Usage:${NC} $(basename "${BASH_SOURCE[0]}") [COMMAND] [ANSIBLE_OPTIONS...]"
    echo
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  ${GREEN}install${NC}        (Default) Full dotfiles setup: OS prep, SSH, clone/update, run Ansible."
    echo -e "  ${GREEN}update${NC}         Update dotfiles repo and run Ansible playbook."
    echo -e "  ${GREEN}cleanup${NC}        Run system cleanup tasks via Ansible (tags: cleanup)."
    echo -e "  ${GREEN}ssh_setup${NC}     Interactive SSH key setup for GitHub."
    echo -e "  ${GREEN}help${NC}           Show this help message."
    echo
    echo -e "${YELLOW}Ansible Options:${NC}"
    echo -e "  Any additional arguments are passed directly to ansible-playbook."
    echo -e "  Example: $(basename "${BASH_SOURCE[0]}") install --tags common,nvim"
    echo -e "  Example: $(basename "${BASH_SOURCE[0]}") update --check"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${BLUE}dotfiles${NC}                 # Full setup (install)"
    echo -e "  ${BLUE}dotfiles install${NC}"
    echo -e "  ${BLUE}dotfiles update --tags vim${NC} # Update and run only vim tasks"
    echo -e "  ${BLUE}dotfiles cleanup${NC}"
    echo -e "  ${BLUE}dotfiles ssh_setup${NC}"
}

function run_ansible_playbook {
    local ansible_args=("$@") # Capture all arguments passed to this function

    # Change to dotfiles directory
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        _task_error "Dotfiles directory $DOTFILES_DIR not found. Cannot run Ansible playbook."
    fi
    cd "$DOTFILES_DIR" || _task_error "Could not cd to $DOTFILES_DIR"

    # Install Ansible Galaxy requirements if they exist
    if [[ -f "requirements.yml" ]]; then
        __task "Installing Ansible Galaxy requirements"
        _cmd "ansible-galaxy install -r requirements.yml"
        _task_done
    fi

    # Determine playbook name
    local playbook_file=""
    if [[ -f "main.yml" ]]; then playbook_file="main.yml";
    elif [[ -f "playbook.yml" ]]; then playbook_file="playbook.yml";
    elif [[ -f "site.yml" ]]; then playbook_file="site.yml";
    else
        _task_error "No Ansible playbook found (expected main.yml, playbook.yml, or site.yml in $DOTFILES_DIR)"
    fi

    __task "Running Ansible playbook: $playbook_file ${ansible_args[*]}"
    # Use _cmd_with_output to see Ansible's output
    # Pass --ask-become-pass unless it's already provided or not needed
    local ask_become_pass_needed=true
    for arg in "${ansible_args[@]}"; do
        if [[ "$arg" == "--ask-become-pass" || "$arg" == "-K" ]]; then
            ask_become_pass_needed=false
            break
        fi
    done
    # Also check if sudo is passwordless for the user
    if sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}Passwordless sudo detected, not adding --ask-become-pass.${NC}"
        ask_become_pass_needed=false
    fi


    if $ask_become_pass_needed; then
        # Check if running in a non-interactive environment
        if [[ ! -t 0 && ! -t 1 ]]; then # No tty for stdin and stdout
            echo -e "${YELLOW}Non-interactive environment detected. Ansible might require sudo password.${NC}"
            echo -e "${YELLOW}If sudo requires a password, this will likely fail or hang.${NC}"
            echo -e "${YELLOW}Consider configuring passwordless sudo or running interactively.${NC}"
            # In non-interactive, --ask-become-pass will fail.
            # It's better to let Ansible fail if it needs sudo password than to hang.
            # So, we don't add --ask-become-pass here.
            # The user should handle sudo password via other means (e.g. ansible_become_password).
        else
             ansible_args+=("--ask-become-pass")
        fi
    fi

    _cmd_with_output "ansible-playbook $playbook_file ${ansible_args[*]}"
    _task_done
}


# Run cleanup tasks only
function run_cleanup_tasks {
    echo -e "\n${ARROW} ${BLUE}Running system cleanup tasks...${NC}\n"
    run_ansible_playbook --tags cleanup "$@" # Pass remaining args
    echo -e "\n${CHECK_MARK} ${GREEN}System cleanup tasks completed!${NC}"
}

# Perform initial OS setup (package installs)
function perform_os_setup {
    OS=$(detect_os)
    __task "Detected OS: $OS"
    if is_wsl; then
        echo -e "${BLUE}Running in WSL environment${NC}"
    fi
    _task_done

    case $OS in
        ubuntu|debian) # Added debian as it's similar
            ubuntu_setup
            ;;
        endeavouros|arch)
            arch_setup
            ;;
        *)
            _task_error "Unsupported OS: $OS. This script currently supports Ubuntu, Debian, EndeavourOS, and Arch Linux."
            ;;
    esac
}

# Clone or update dotfiles repository
function manage_dotfiles_repo {
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
        __task "Cloning dotfiles repository"
        local clone_url="$DOTFILES_REPO_HTTPS"
        if [[ "$USE_SSH" == "true" ]]; then
            clone_url="$DOTFILES_REPO_SSH"
        fi
        _cmd "git clone $clone_url $DOTFILES_DIR"
        _task_done
    else
        __task "Updating dotfiles repository"
        current_dir=$(pwd)
        cd "$DOTFILES_DIR" || _task_error "Could not cd to $DOTFILES_DIR"
        # Stash local changes before pull, then try to pop
        local stashed=false
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo -e "${YELLOW}Local changes detected. Stashing...${NC}"
            if _cmd "git stash push -u -m 'dotfiles-script auto-stash'"; then
                stashed=true
            else
                _task_error "Failed to stash local changes. Please commit or stash them manually."
            fi
        fi

        _cmd "git pull --ff-only" # Fast-forward only to avoid merge conflicts here

        if $stashed; then
            echo -e "${YELLOW}Attempting to reapply stashed changes...${NC}"
            if ! git stash pop; then
                echo -e "${RED}Failed to automatically reapply stashed changes.${NC}"
                echo -e "${YELLOW}Your changes are still in the stash. Run 'git stash list' and 'git stash apply' manually in $DOTFILES_DIR.${NC}"
            fi
        fi
        cd "$current_dir" || _task_error "Could not cd back to $current_dir"
        _task_done

        # If SSH was set up, ensure repo uses SSH remote
        if [[ "$USE_SSH" == "true" ]]; then
            convert_repo_to_ssh_if_needed
        fi
    fi
}


# Main execution logic
function main_execution {
    local command="install" # Default command
    local ansible_playbook_args=()

    # Simple argument parsing
    if [[ $# -gt 0 ]]; then
        case $1 in
            install|update|cleanup|ssh_setup|help)
                command="$1"
                shift
                ;;
            *) # Default to install if first arg is not a known command
                # and assume other args are for ansible
                ;;
        esac
        ansible_playbook_args=("$@") # Remaining arguments are for Ansible
    fi

    if [[ "$command" == "help" ]]; then
        show_help
        exit 0
    fi

    echo -e "${ARROW} ${BLUE}Dotfiles script action: $command ${NC}\n"

    if [[ "$command" == "ssh_setup" ]]; then
        full_ssh_setup_workflow
        if [[ $? -eq 0 ]]; then
            echo -e "${CHECK_MARK} ${GREEN}SSH setup process completed.${NC}"
        else
            echo -e "${X_MARK} ${RED}SSH setup process had issues or was skipped.${NC}"
        fi
        exit 0
    fi

    # For install, update, cleanup:
    perform_os_setup # Installs git, ansible, python if needed

    # SSH Setup for 'install' or if repo doesn't exist yet for 'update'
    if [[ "$command" == "install" ]] || [[ "$command" == "update" && ! -d "$DOTFILES_DIR/.git" ]]; then
        __task "Checking existing SSH setup with GitHub"
        ssh_status_code=$(check_existing_ssh_setup; echo $?) # Capture return code

        case $ssh_status_code in
            0) # SSH OK
                echo -e "${GREEN}SSH connection to GitHub is working!${NC}"
                _task_done
                USE_SSH=true
                ;;
            1) # Keys exist, but GitHub connection failed
                echo -e "${YELLOW}SSH keys found but GitHub connection failed.${NC}"
                _task_done
                read -r -p "Do you want to reconfigure SSH for GitHub? (Y/n): " reply
                if [[ ! "$reply" =~ ^[Nn]$ ]]; then
                    full_ssh_setup_workflow # This sets USE_SSH
                else
                    echo -e "${YELLOW}Skipping SSH reconfiguration. Will use HTTPS if needed.${NC}"
                    USE_SSH=false
                fi
                ;;
            2) # No keys found
                echo -e "${YELLOW}No usable SSH keys found for GitHub.${NC}"
                _task_done
                read -r -p "Do you want to set up SSH keys for GitHub? (Y/n): " reply
                if [[ ! "$reply" =~ ^[Nn]$ ]]; then
                    full_ssh_setup_workflow # This sets USE_SSH
                else
                    echo -e "${YELLOW}Skipping SSH setup. Will use HTTPS if needed.${NC}"
                    USE_SSH=false
                fi
                ;;
        esac
    elif [[ -d "$DOTFILES_DIR/.git" ]]; then
        # For 'update' or 'cleanup' if repo exists, check current remote
        current_dir_before_cd_main_logic=$(pwd)
        cd "$DOTFILES_DIR" || _task_error "Could not cd to $DOTFILES_DIR"
        current_remote_main_logic=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$current_remote_main_logic" == "$DOTFILES_REPO_SSH" ]]; then
            USE_SSH=true
        else
            USE_SSH=false # Assume HTTPS or other
        fi
        cd "$current_dir_before_cd_main_logic" || _task_error "Could not cd back"
        echo -e "${BLUE}Dotfiles repo remote: $current_remote_main_logic (USE_SSH=$USE_SSH)${NC}"
    else
        USE_SSH=false # Default for cleanup if repo doesn't exist (though cleanup needs repo)
    fi


    manage_dotfiles_repo # Clones or pulls

    if [[ "$command" == "cleanup" ]]; then
        run_cleanup_tasks "${ansible_playbook_args[@]}"
    else # install or update
        run_ansible_playbook "${ansible_playbook_args[@]}"
    fi

    echo -e "\n${CHECK_MARK} ${GREEN}Dotfiles '$command' process completed successfully!${NC}"
    if [[ "$command" == "install" || "$command" == "update" ]]; then
        echo -e "${ARROW} ${YELLOW}You may need to restart your shell or reboot for all changes to take effect.${NC}"
        echo -e "${ARROW} ${BLUE}Tmux reminder (if installed): Start tmux and press Prefix + I (usually Ctrl+b I or Ctrl+s I) to install plugins.${NC}"
    fi

    if [[ "$USE_SSH" == "true" ]]; then
        echo -e "${ARROW} ${GREEN}Dotfiles repository is configured to use SSH for GitHub operations.${NC}"
    else
        echo -e "${ARROW} ${YELLOW}Dotfiles repository is configured to use HTTPS for GitHub operations.${NC}"
    fi
}
