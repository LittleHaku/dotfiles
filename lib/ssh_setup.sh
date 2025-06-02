#!/bin/bash

# SSH_KEY_PATH and WINDOWS_SSH_DIR are global, expected to be set in main script or by functions here

# List Windows SSH keys
function list_windows_ssh_keys {
    local windows_ssh_dir="$1"
    if [[ -d "$windows_ssh_dir" ]]; then
        # Find private keys (not .pub files)
        find "$windows_ssh_dir" -maxdepth 1 -type f -name "id_*" ! -name "*.pub" 2>/dev/null || echo ""
    fi
}

# Check if Windows SSH keys exist
function check_windows_ssh_keys {
    if is_wsl; then
        __task "Checking for existing Windows SSH keys"

        WINDOWS_SSH_DIR=$(find_windows_ssh_dir) # This will update the global
        if [[ -n "$WINDOWS_SSH_DIR" ]]; then
            local ssh_keys
            ssh_keys=($(list_windows_ssh_keys "$WINDOWS_SSH_DIR"))
            if [[ ${#ssh_keys[@]} -gt 0 ]]; then
                echo -e "${GREEN}Found Windows SSH directory: $WINDOWS_SSH_DIR${NC}"
                echo -e "${GREEN}Found SSH keys:${NC}"
                for key in "${ssh_keys[@]}"; do
                    echo -e "  ${BLUE}$(basename "$key")${NC}"
                done
                _task_done
                return 0 # Keys found
            fi
        fi
        echo -e "${YELLOW}No existing Windows SSH keys found or Windows SSH directory not determined.${NC}"
        _task_done
        return 1 # No keys found
    fi
    return 1 # Not WSL or no keys
}


# Link Windows SSH keys to WSL
function link_windows_ssh_keys {
    local windows_ssh_dir="$1" # Parameter
    local ssh_keys
    ssh_keys=($(list_windows_ssh_keys "$windows_ssh_dir"))

    if [[ ${#ssh_keys[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No SSH keys found in $windows_ssh_dir to link.${NC}"
        return 1
    fi

    __task "Linking Windows SSH keys to WSL"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    local selected_key_path=""
    if [[ ${#ssh_keys[@]} -eq 1 ]]; then
        selected_key_path="${ssh_keys[0]}"
    else
        echo -e "${YELLOW}Multiple Windows SSH keys found. Please select one to link:${NC}"
        local options=()
        for key_path in "${ssh_keys[@]}"; do
            options+=("$(basename "$key_path") (from $key_path)")
        done

        select opt_display in "${options[@]}"; do
            if [[ -n "$opt_display" ]]; then
                # Extract the original path from the display string
                # Find the index of the selected option
                for i in "${!options[@]}"; do
                    if [[ "${options[$i]}" == "$opt_display" ]]; then
                        selected_key_path="${ssh_keys[$i]}"
                        break
                    fi
                done
                break
            else
                echo "Invalid selection. Try again."
            fi
        done
        if [[ -z "$selected_key_path" ]]; then
             _task_error "No key selected." # Exits
        fi
    fi


    if [[ -n "$selected_key_path" ]]; then
        local key_name
        key_name=$(basename "$selected_key_path")
        local pub_key_path="${selected_key_path}.pub"
        local wsl_priv_key_path="$HOME/.ssh/$key_name"
        local wsl_pub_key_path="$HOME/.ssh/${key_name}.pub"

        # Symlink private key
        ln -sf "$selected_key_path" "$wsl_priv_key_path"
        # WSL needs strict permissions for the actual target of the symlink if it's on a Windows mount.
        # However, for the symlink itself, chmod doesn't affect the target on /mnt/*.
        # The key is that the Windows file permissions must be correct.
        # For keys used by WSL's ssh client, the symlink in ~/.ssh must have 600.
        chmod 600 "$wsl_priv_key_path"


        # Symlink public key if it exists
        if [[ -f "$pub_key_path" ]]; then
            ln -sf "$pub_key_path" "$wsl_pub_key_path"
            chmod 644 "$wsl_pub_key_path"
        fi

        # Update SSH_KEY_PATH to point to the linked key in WSL's .ssh directory
        SSH_KEY_PATH="$wsl_priv_key_path" # Update global

        echo -e "${GREEN}Successfully linked SSH key: $key_name (symlinked from Windows)${NC}"
        _task_done
        return 0
    fi
    _task_error "Failed to select or link key." # Exits
    return 1 # Should not be reached
}

# Setup SSH in Windows (guide user through it)
function setup_windows_ssh_keys {
    echo -e "\n${ARROW} ${BLUE}Setting up SSH keys in Windows...${NC}\n"
    echo -e "${YELLOW}We'll help you set up SSH keys in Windows and then link them to WSL.${NC}"
    echo -e "${BLUE}Please follow these steps in a Windows PowerShell (not as administrator unless necessary for ssh-agent):${NC}\n"

    local win_user
    win_user=$(get_windows_username) # Call the function
    local suggested_email=""

    echo -e "${BLUE}1. Open PowerShell as your regular user.${NC}"
    echo -e "${BLUE}2. If you don't have OpenSSH client, install it via Windows Settings > Apps > Optional features.${NC}"
    echo -e "${BLUE}3. Run the following command to generate an SSH key:${NC}"

    read -r -p "Enter your email for the SSH key (e.g., your_email@example.com): " suggested_email
    while [[ -z "$suggested_email" ]]; do
        read -r -p "Email cannot be empty. Please enter your email: " suggested_email
    done

    echo -e "\n${GREEN}ssh-keygen -t ed25519 -C \"$suggested_email\"${NC}\n"
    echo -e "${BLUE}   When prompted for file location, press Enter to use default (e.g., C:\\Users\\$win_user\\.ssh\\id_ed25519).${NC}"
    echo -e "${BLUE}   When prompted for passphrase, you can press Enter for no passphrase (less secure) or type a strong one.${NC}"
    echo -e "${BLUE}4. Start the ssh-agent in PowerShell (if not already running):${NC}"
    echo -e "${GREEN}Get-Service ssh-agent | Set-Service -StartupType Automatic; Start-Service ssh-agent${NC}"
    echo -e "${BLUE}5. Add your new key to the agent:${NC}"
    echo -e "${GREEN}ssh-add ~\\.ssh\\id_ed25519${NC}\n" # Assuming default key name
    echo -e "${YELLOW}After generating and adding the key in Windows:${NC}"
    echo -e "${BLUE}6. Copy the PUBLIC key content with this command in PowerShell:${NC}"
    echo -e "${GREEN}Get-Content ~\\.ssh\\id_ed25519.pub | Set-Clipboard${NC}\n"
    echo -e "${BLUE}7. Add the key to GitHub at: https://github.com/settings/keys${NC}\n"

    read -r -p "Press Enter when you've completed the SSH key setup in Windows and added it to GitHub..."

    # Now try to find and link the keys
    # Re-check for Windows SSH keys as they might have just been created
    if check_windows_ssh_keys && [[ -n "$WINDOWS_SSH_DIR" ]]; then
        if link_windows_ssh_keys "$WINDOWS_SSH_DIR"; then
            # SSH_KEY_PATH should now be updated by link_windows_ssh_keys
            # No need to call setup_ssh_agent from here as it's done on Windows side
            # copy_ssh_key_to_clipboard is also done on Windows side
            # wait_for_github_setup was prompted above
            return 0
        fi
    fi

    echo -e "${RED}Could not automatically find or link the Windows SSH keys after setup guide. Please ensure they were created in the default location (C:\\Users\\$win_user\\.ssh\\).${NC}"
    echo -e "${RED}You might need to run the 'link_windows_ssh_keys' option manually if they exist in a non-standard location recognized by 'find_windows_ssh_dir'.${NC}"
    return 1
}


# Generate SSH key (for Linux or direct WSL generation)
function generate_ssh_key {
    # SSH_KEY_PATH is global
    if [[ -f "$SSH_KEY_PATH" ]]; then
        echo -e "${YELLOW}SSH key already exists at $SSH_KEY_PATH${NC}"
        read -r -p "Do you want to use this existing key? (Y/n): " reply
        if [[ "$reply" =~ ^[Nn]$ ]]; then
            read -r -p "Enter a new SSH key name (e.g., id_ed25519_new, will be saved in ~/.ssh/): " key_name_base
            if [[ -z "$key_name_base" ]]; then
                _task_error "Key name cannot be empty."
            fi
            SSH_KEY_PATH="$HOME/.ssh/$key_name_base" # Update global
        else
            echo -e "${GREEN}Using existing key: $SSH_KEY_PATH${NC}"
            return 0 # Key exists and user wants to use it
        fi
    fi

    # If we reach here, either key didn't exist or user wants a new one
    if [[ -f "$SSH_KEY_PATH" ]]; then # Check again if user provided an existing name
         echo -e "${YELLOW}The specified key $SSH_KEY_PATH already exists.${NC}"
         read -r -p "Overwrite $SSH_KEY_PATH? (y/N): " overwrite_reply
         if [[ ! "$overwrite_reply" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Skipping SSH key generation.${NC}"
            return 1 # User chose not to overwrite
         fi
    fi


    __task "Generating SSH key at $SSH_KEY_PATH"
    local email
    read -r -p "Enter your email for the SSH key: " email
    while [[ -z "$email" ]]; do
        read -r -p "Email cannot be empty. Please enter your email: " email
    done

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Generate SSH key, -N "" for no passphrase
    if ssh-keygen -t ed25519 -C "$email" -f "$SSH_KEY_PATH" -N ""; then
        chmod 600 "$SSH_KEY_PATH"
        chmod 644 "${SSH_KEY_PATH}.pub"
        _task_done
        return 0
    else
        _task_error "SSH key generation failed."
    fi
}

# Copy SSH key to clipboard
function copy_ssh_key_to_clipboard {
    if [[ ! -f "${SSH_KEY_PATH}.pub" ]]; then
        _task_error "Public SSH key not found at ${SSH_KEY_PATH}.pub"
        return 1
    fi

    __task "Copying SSH public key to clipboard"
    local copied=false
    if is_wsl; then
        if command -v clip.exe &>/dev/null; then
            cat "${SSH_KEY_PATH}.pub" | clip.exe
            echo -e "${GREEN}SSH key copied to Windows clipboard via clip.exe${NC}"
            copied=true
        elif command -v powershell.exe &>/dev/null; then
            # Ensure the path is correctly formatted for powershell if it contains spaces or special chars
            # However, cat output is piped, so direct path issues are less likely here.
            cat "${SSH_KEY_PATH}.pub" | powershell.exe -Command "\$input | Set-Clipboard"
            echo -e "${GREEN}SSH key copied to Windows clipboard via PowerShell${NC}"
            copied=true
        fi
    else # Regular Linux
        if command -v xclip &>/dev/null; then
            cat "${SSH_KEY_PATH}.pub" | xclip -selection clipboard
            echo -e "${GREEN}SSH key copied to clipboard via xclip${NC}"
            copied=true
        elif command -v xsel &>/dev/null; then
            cat "${SSH_KEY_PATH}.pub" | xsel --clipboard --input
            echo -e "${GREEN}SSH key copied to clipboard via xsel${NC}"
            copied=true
        fi
    fi

    if ! $copied; then
        echo -e "${YELLOW}Could not automatically copy to clipboard. Please copy the key manually:${NC}"
        cat "${SSH_KEY_PATH}.pub"
        echo # Newline after key
    fi
    _task_done
}

# Setup SSH agent (for Linux or direct WSL keys)
function setup_ssh_agent {
    __task "Setting up SSH agent and adding key: $SSH_KEY_PATH"

    # Start ssh-agent if not running or socket is invalid
    # The check for SSH_AUTH_SOCK might be true but agent not working, so test it.
    if ! ssh-add -l &>/dev/null; then
        echo "Attempting to start ssh-agent..."
        eval "$(ssh-agent -s)" >/dev/null
    fi

    # Add key to ssh-agent
    if ssh-add "$SSH_KEY_PATH"; then
        _task_done
    else
        # If adding fails, it might be because the key has a passphrase and ssh-askpass is not set up,
        # or the key is invalid.
        _task_error "Failed to add SSH key $SSH_KEY_PATH to agent. If it has a passphrase, you may need to enter it."
        # Don't exit here, user might still proceed or key might be added manually.
        # The test_github_ssh will be the final check.
    fi
}

# Wait for user to add SSH key to GitHub
function wait_for_github_setup {
    echo -e "\n${ARROW} ${YELLOW}Please add your SSH public key to GitHub:${NC}"
    echo -e "${BLUE}1. The public key should be on your clipboard (or printed above).${NC}"
    echo -e "${BLUE}2. Go to https://github.com/settings/keys${NC}"
    echo -e "${BLUE}3. Click 'New SSH key' or 'Add SSH key'.${NC}"
    echo -e "${BLUE}4. Give it a title (e.g., 'My WSL Laptop', 'My Linux Desktop').${NC}"
    echo -e "${BLUE}5. Paste the key into the 'Key' field.${NC}"
    echo -e "${BLUE}6. Click 'Add SSH key'.${NC}"
    echo
    read -r -p "Press Enter when you've added the SSH key to GitHub..."
}

# Check if SSH is already set up and working with GitHub
function check_existing_ssh_setup {
    # Check if any local SSH private keys exist
    local local_ssh_keys_exist=false
    if compgen -G "$HOME/.ssh/id_*" > /dev/null && [[ -n "$(find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' -print -quit)" ]]; then
        local_ssh_keys_exist=true
    fi

    # If WSL, also check for Windows SSH keys that could be linked
    local wsl_windows_keys_linkable=false
    if is_wsl; then
        # Temporarily suppress __task output from check_windows_ssh_keys for this check
        local original_task="$TASK"
        TASK=""
        if check_windows_ssh_keys >/dev/null 2>&1; then # check_windows_ssh_keys returns 0 if found
            wsl_windows_keys_linkable=true
        fi
        TASK="$original_task" # Restore task
    fi

    if ! $local_ssh_keys_exist && ! $wsl_windows_keys_linkable; then
        return 2 # No SSH keys found (neither local nor linkable Windows keys)
    fi

    # At this point, keys exist (or are linkable). Try to test GitHub SSH connection silently.
    # Use a longer timeout for the initial check as it might involve host key verification.
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        # If successful, ensure SSH_KEY_PATH is set to a valid key if not already.
        # This is tricky as we don't know *which* key worked.
        # For now, assume if it works, the agent is configured or a default key is being used.
        # If SSH_KEY_PATH is not a file, try to find one.
        if [[ ! -f "$SSH_KEY_PATH" ]]; then
            local found_key
            found_key=$(find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' -print -quit)
            if [[ -n "$found_key" ]]; then
                SSH_KEY_PATH="$found_key" # Update global
            fi
        fi
        return 0  # SSH is set up and working with GitHub
    else
        return 1  # SSH keys exist (or are linkable) but GitHub connection failed
    fi
}


# Test SSH connection to GitHub
function test_github_ssh {
    __task "Testing SSH connection to GitHub"
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "Hi .*! You've successfully authenticated"; then
        echo -e "${GREEN}SSH connection to GitHub successful!${NC}"
        _task_done
        return 0
    else
        # Output the error from ssh -T for more diagnostics
        local ssh_error
        ssh_error=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -T git@github.com 2>&1)
        echo -e "${RED}SSH connection to GitHub failed.${NC}"
        echo -e "${YELLOW}Reason: $ssh_error${NC}"
        echo -e "${YELLOW}Please ensure your SSH key is added to your GitHub account (https://github.com/settings/keys) and your local SSH agent is configured correctly.${NC}"
        _task_done # Mark task as done even if it failed, to avoid overwrite issues
        return 1
    fi
}

# WSL SSH setup workflow
function setup_wsl_ssh {
    echo -e "\n${ARROW} ${BLUE}WSL SSH Setup Options:${NC}\n"

    local has_windows_keys=false
    # Temporarily suppress __task output from check_windows_ssh_keys for this decision logic
    local original_task="$TASK"; TASK=""
    if check_windows_ssh_keys; then # check_windows_ssh_keys returns 0 if found
        has_windows_keys=true
    fi
    TASK="$original_task" # Restore task

    local choice
    if $has_windows_keys; then
        echo -e "${GREEN}Found existing Windows SSH keys!${NC} (in $WINDOWS_SSH_DIR)"
        options=(
            "Link existing Windows SSH keys to WSL (recommended)"
            "Create new SSH keys in Windows (and link them)"
            "Create new SSH keys directly in WSL (not recommended if you use Git on Windows too)"
            "Skip SSH setup for now"
        )
        select opt in "${options[@]}"; do
            if [[ -n "$opt" ]]; then
                choice="$REPLY"
                break
            else
                echo "Invalid selection."
            fi
        done

        case $choice in
            1)
                if [[ -n "$WINDOWS_SSH_DIR" ]]; then
                    if link_windows_ssh_keys "$WINDOWS_SSH_DIR"; then # This updates SSH_KEY_PATH
                        # For linked keys, agent setup is typically on Windows side.
                        # However, we might need to inform WSL's agent if it's running.
                        # For simplicity, let's assume Windows agent handles it.
                        # We still need to test the connection.
                        # copy_ssh_key_to_clipboard # Not needed if already on GitHub
                        # wait_for_github_setup # Not needed if already on GitHub
                        echo -e "${GREEN}Windows SSH keys linked. Ensure they are added to GitHub.${NC}"
                        return 0 # Success
                    else
                        echo -e "${RED}Failed to link Windows SSH keys.${NC}"
                        return 1 # Failure
                    fi
                else
                    echo -e "${RED}Windows SSH directory not found, cannot link.${NC}"
                    return 1
                fi
                ;;
            2) # Create new in Windows
                if setup_windows_ssh_keys; then # This guides user, then links. SSH_KEY_PATH updated.
                    # Agent setup and key copy/paste to GitHub is part of setup_windows_ssh_keys guide
                    return 0 # Success
                else
                    echo -e "${RED}Failed to complete Windows SSH key setup guide.${NC}"
                    return 1 # Failure
                fi
                ;;
            3) # Create new in WSL
                if generate_ssh_key; then # SSH_KEY_PATH updated
                    setup_ssh_agent # For WSL-specific key
                    copy_ssh_key_to_clipboard
                    wait_for_github_setup
                    return 0 # Success
                else
                    echo -e "${RED}Failed to generate SSH keys in WSL.${NC}"
                    return 1 # Failure
                fi
                ;;
            4) # Skip
                echo -e "${YELLOW}Skipping SSH setup.${NC}"
                return 2 # User skipped
                ;;
            *)
                echo -e "${RED}Invalid option selected.${NC}"
                return 1
                ;;
        esac
    else # No existing Windows keys found
        echo -e "${YELLOW}No existing usable Windows SSH keys found.${NC}"
        options=(
            "Create new SSH keys in Windows and link to WSL (recommended)"
            "Create new SSH keys directly in WSL"
            "Skip SSH setup for now"
        )
        select opt in "${options[@]}"; do
            if [[ -n "$opt" ]]; then
                choice="$REPLY"
                break
            else
                echo "Invalid selection."
            fi
        done

        case $choice in
            1) # Create new in Windows
                if setup_windows_ssh_keys; then
                    return 0
                else
                    return 1
                fi
                ;;
            2) # Create new in WSL
                if generate_ssh_key; then
                    setup_ssh_agent
                    copy_ssh_key_to_clipboard
                    wait_for_github_setup
                    return 0
                else
                    return 1
                fi
                ;;
            3) # Skip
                echo -e "${YELLOW}Skipping SSH setup.${NC}"
                return 2 # User skipped
                ;;
            *)
                echo -e "${RED}Invalid option selected.${NC}"
                return 1
                ;;
        esac
    fi
}

# Overall SSH setup workflow
function full_ssh_setup_workflow {
    local setup_rc=1 # 0 for success, 1 for failure, 2 for skip

    if is_wsl; then
        setup_wsl_ssh
        setup_rc=$?
    else # Not WSL (Linux native)
        echo -e "\n${ARROW} ${BLUE}Setting up SSH for GitHub...${NC}\n"
        if generate_ssh_key; then # SSH_KEY_PATH updated
            setup_ssh_agent
            copy_ssh_key_to_clipboard
            wait_for_github_setup
            setup_rc=0 # Success
        else
            echo -e "${RED}Failed to generate SSH key.${NC}"
            setup_rc=1 # Failure
        fi
    fi

    if [[ $setup_rc -eq 0 ]]; then # If setup was attempted and reported success
        local retries=2
        while [[ $retries -ge 0 ]]; do
            if test_github_ssh; then
                USE_SSH=true # Global flag indicating SSH should be used
                return 0     # SSH setup fully successful
            else
                if [[ $retries -gt 0 ]]; then
                    echo -e "${YELLOW}GitHub SSH test failed. You might need to wait a moment for GitHub to recognize the new key, or double-check it was added correctly.${NC}"
                    read -r -p "Press Enter to retry, or Ctrl+C to abort setup..."
                    retries=$((retries - 1))
                else
                    _task_error "Could not establish SSH connection to GitHub after multiple attempts. Please verify your SSH key is correctly added to GitHub and your network connection."
                    # _task_error exits, so this return is not strictly needed but good for clarity
                    USE_SSH=false
                    return 1 # SSH setup failed at GitHub test
                fi
            fi
        done
    elif [[ $setup_rc -eq 2 ]]; then # User skipped
        echo -e "${YELLOW}SSH setup was skipped. Will proceed using HTTPS for GitHub operations.${NC}"
        USE_SSH=false
        return 2 # User skipped
    else # setup_rc is 1 (failure during key gen/link)
        echo -e "${RED}SSH key setup failed. Will proceed using HTTPS for GitHub operations.${NC}"
        USE_SSH=false
        return 1 # SSH setup failed
    fi
}
