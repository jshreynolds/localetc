#!/bin/bash
#
# common.sh - Common functions used across installation scripts
#
# Provides reusable functions for installation scripts
# Usage: source this file to access common functions
#

# Source logger if not already loaded
if [[ -z "$LOG_FILE" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

# Check if a command exists
command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

# Ask yes/no question with default
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" || "$default" == "Y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Create symlink with backup
safe_symlink() {
    local source="$1"
    local target="$2"
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        log_error "Source file does not exist: $source"
        return 1
    fi
    
    # Create parent directory if needed
    local target_dir=$(dirname "$target")
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        log_info "Created directory: $target_dir"
    fi
    
    # Backup existing file if it's not a symlink
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$backup"
        log_warning "Backed up existing file: $target → $backup"
    fi
    
    # Remove existing symlink if it points elsewhere
    if [[ -L "$target" ]]; then
        local current_source=$(readlink "$target")
        if [[ "$current_source" != "$source" ]]; then
            rm "$target"
            log_info "Removed existing symlink: $target"
        else
            log_info "Symlink already correct: $target → $source"
            return 0
        fi
    fi
    
    # Create symlink
    ln -sf "$source" "$target"
    log_success "Created symlink: $target → $source"
}

# Check disk space (in MB)
check_disk_space() {
    local required_mb="${1:-500}"
    local available_mb
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_mb=$(df -m / | awk 'NR==2 {print $4}')
    else
        available_mb=$(df -m / | awk 'NR==2 {print $4}')
    fi
    
    if [[ $available_mb -lt $required_mb ]]; then
        log_error "Insufficient disk space. Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    else
        log_info "Disk space check passed. Available: ${available_mb}MB"
        return 0
    fi
}

# Keep sudo alive during installation
keep_sudo_alive() {
    # Ask for sudo password upfront
    sudo -v
    
    # Keep sudo alive in background
    while true; do 
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# Install Brewfile with description
install_brewfile() {
    local brewfile="$1"
    local description="$2"
    
    if [[ ! -f "$brewfile" ]]; then
        log_warning "Brewfile not found: $brewfile"
        return 1
    fi
    
    log_section "Installing $description packages"
    log_command "brew bundle --file=$brewfile"
    
    if brew bundle --file="$brewfile"; then
        log_success "Installed $description packages"
        return 0
    else
        log_error "Failed to install some $description packages"
        return 1
    fi
}

# Check if running on Apple Silicon
is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

# Get Homebrew prefix
get_brew_prefix() {
    if is_apple_silicon; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# Wait for user to press enter
wait_for_enter() {
    local message="${1:-Press Enter to continue...}"
    read -p "$message"
}

# Run command with error checking
run_command() {
    local command="$1"
    local description="${2:-Running command}"
    
    log_command "$command"
    
    if eval "$command"; then
        log_success "$description"
        return 0
    else
        log_error "Failed: $description"
        return 1
    fi
}

# Check macOS version
check_macos_version() {
    local required_major="${1:-12}"  # Default to Monterey
    local current_version=$(sw_vers -productVersion)
    local current_major=$(echo "$current_version" | cut -d. -f1)
    
    if [[ $current_major -lt $required_major ]]; then
        log_error "macOS version $current_version is too old. Required: $required_major.0 or later"
        return 1
    else
        log_info "macOS version check passed: $current_version"
        return 0
    fi
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}