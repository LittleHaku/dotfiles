#!/bin/bash

# Ubuntu setup
function ubuntu_setup {
    __task "Updating package lists (Ubuntu)"
    _cmd "sudo apt-get update"

    local packages_to_install=()
    command -v ansible >/dev/null 2>&1 || packages_to_install+=("ansible")
    command -v git >/dev/null 2>&1 || packages_to_install+=("git")
    command -v python3 >/dev/null 2>&1 || packages_to_install+=("python3" "python3-pip")
    (command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1) || packages_to_install+=("xclip") # Install xclip if neither exists

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        __task "Installing core dependencies (Ubuntu): ${packages_to_install[*]}"
        if [[ " ${packages_to_install[*]} " =~ " ansible " ]]; then # Special handling for Ansible PPA
             _cmd "sudo apt-get install -y software-properties-common"
             _cmd "sudo apt-add-repository --yes --update ppa:ansible/ansible"
        fi
        _cmd "sudo apt-get install -y ${packages_to_install[*]}"
    else
        _task_done # Mark task as done if nothing to install
        echo -e "${GREEN}Core dependencies already installed (Ubuntu).${NC}"
    fi
    _task_done
}

# Arch/Endeavour setup
function arch_setup {
    __task "Updating package database (Arch)"
    _cmd "sudo pacman -Sy --noconfirm"

    local packages_to_install=()
    command -v ansible >/dev/null 2>&1 || packages_to_install+=("ansible")
    command -v git >/dev/null 2>&1 || packages_to_install+=("git")
    command -v python >/dev/null 2>&1 || packages_to_install+=("python" "python-pip") # Arch uses 'python' for python3
    (command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1) || packages_to_install+=("xclip")

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        __task "Installing core dependencies (Arch): ${packages_to_install[*]}"
        _cmd "sudo pacman -S --noconfirm ${packages_to_install[*]}"
    else
        _task_done # Mark task as done if nothing to install
        echo -e "${GREEN}Core dependencies already installed (Arch).${NC}"
    fi
    _task_done
}
