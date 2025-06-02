#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
OVERWRITE='\e[1A\e[K'

# Emoji/symbols
CHECK_MARK="${GREEN}✓${NC}"
X_MARK="${RED}✗${NC}"
ARROW="${BLUE}▶${NC}"

# Task management functions
# TASK variable will be global, declared in the main script
function __task {
    if [[ -n "$TASK" ]]; then
        printf "${OVERWRITE}${CHECK_MARK} ${GREEN}${TASK}${NC}\n"
    fi
    TASK=$1
    printf "${BLUE}[ ] ${TASK}${NC}\n"
}

function _task_done {
    if [[ -n "$TASK" ]]; then
        printf "${OVERWRITE}${CHECK_MARK} ${GREEN}${TASK}${NC}\n"
        TASK=""
    fi
}

function _task_error {
    if [[ -n "$TASK" ]]; then
        printf "${OVERWRITE}${X_MARK} ${RED}${TASK} - ERROR${NC}\n"
    fi
    echo -e "${RED}$1${NC}" >&2 # Send error messages to stderr
    exit 1
}

# Command execution with error handling
function _cmd {
    if ! eval "$1" >/dev/null 2>&1; then
        _task_error "Command failed: $1"
    fi
}

# Command execution with output
function _cmd_with_output {
    if ! eval "$1"; then
        _task_error "Command failed: $1"
    fi
}
