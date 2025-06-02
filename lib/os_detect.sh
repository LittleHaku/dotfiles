#!/bin/bash

# Detect OS
function detect_os {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID" # Use "$ID" to ensure it's treated as a string
    else
        echo "unknown"
    fi
}

# Check if running in WSL
function is_wsl {
    if [[ -n "${WSL_DISTRO_NAME}" ]] || [[ -n "${WSLENV}" ]] || (uname -r 2>/dev/null || echo "") | grep -q -i "microsoft"; then
        return 0
    else
        return 1
    fi
}

# Get Windows username
function get_windows_username {
    if is_wsl; then
        local win_user=""
        # Method 1: From WSL environment (prefer powershell.exe for consistency)
        win_user=$(powershell.exe -Command '$env:USERNAME' 2>/dev/null | tr -d '\r\n' || echo "")

        # Method 2: From Windows registry via cmd (fallback)
        if [[ -z "$win_user" ]]; then
            win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || echo "")
        fi

        # Method 3: Parse from current WSL path (more robust)
        if [[ -z "$win_user" ]] && [[ -d "/mnt/c/Users" ]]; then
            local users_dir="/mnt/c/Users"
            # Exclude common non-user directories and hidden/system files
            local possible_users=()
            while IFS= read -r d; do
                [[ "$d" != "Public" && "$d" != "Default" && "$d" != "All Users" && "$d" != "Default User" && ! "$d" =~ ^\..* ]] && possible_users+=("$d")
            done < <(ls -A "$users_dir" 2>/dev/null)


            if [[ ${#possible_users[@]} -eq 1 ]]; then
                win_user="${possible_users[0]}"
            elif [[ ${#possible_users[@]} -gt 1 ]]; then
                echo -e "${YELLOW}Multiple Windows user profiles found under /mnt/c/Users/. Please select yours:${NC}"
                select opt in "${possible_users[@]}"; do
                    if [[ -n "$opt" ]]; then
                        win_user="$opt"
                        break
                    else
                        echo "Invalid selection. Try again."
                    fi
                done
            fi
        fi
        echo "$win_user"
    fi
}


# Find Windows SSH directory
function find_windows_ssh_dir {
    if is_wsl; then
        local win_user
        win_user=$(get_windows_username) # Call the function to get username
        if [[ -n "$win_user" ]]; then
            # Common locations for .ssh directory on Windows
            local possible_paths=(
                "/mnt/c/Users/$win_user/.ssh"
                # Add other common paths if necessary, e.g., for OpenSSH installed via Windows Features
                # "/mnt/c/ProgramData/ssh" # System-wide, less likely for user keys
            )

            for path in "${possible_paths[@]}"; do
                if [[ -d "$path" ]]; then
                    echo "$path"
                    return 0 # Found
                fi
            done
        fi
    fi
    return 1 # Not found or not WSL
}
