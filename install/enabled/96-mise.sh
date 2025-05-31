#!/bin/bash
#
# 96-mise.sh - Development Runtime Manager
#
# Installs mise (formerly rtx) for managing development tools
# Dependencies: Homebrew (mise should be installed via brew)
# Creates: ~/.local/share/mise
#

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

# Source libraries
source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

log_script_start "mise.sh"

# Check if mise is installed
if ! command_exists mise; then
    log_error "mise is not installed. Please run 01-brew.sh first"
    exit 1
fi

# Load packages from config file
MISE_CONFIG="${HOME}/etc/dotfiles/shell/mise"

if [[ ! -f "$MISE_CONFIG" ]]; then
    log_error "mise config file not found: $MISE_CONFIG"
    exit 1
fi

log_section "Installing development tools via mise"

# Count total packages for progress
total_packages=$(grep -v '^#' "$MISE_CONFIG" | grep -v '^$' | wc -l | tr -d ' ')
current=0

# Install each package
while IFS= read -r pack; do
    # Skip empty lines and comments
    [[ -z "$pack" || "$pack" =~ ^#.*$ ]] && continue
    
    current=$((current + 1))
    show_progress $current $total_packages "Installing $pack"
    
    # Get latest version
    latest_version=$(mise latest "$pack" 2>/dev/null)
    
    if [[ -z "$latest_version" ]]; then
        log_warning "Could not determine latest version for $pack"
        track_package "mise" "$pack" "⚠"
        continue
    fi
    
    # Install the package
    log_command "mise use --global --yes $pack@$latest_version"
    
    if mise use --global --yes "$pack"@"$latest_version" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Installed $pack@$latest_version"
        track_package "mise" "$pack@$latest_version"
    else
        log_error "Failed to install $pack"
        track_package "mise" "$pack" "✗"
    fi
done < "$MISE_CONFIG"

# Verify mise setup
log_info "Verifying mise installation..."
if mise doctor 2>&1 | tee -a "$LOG_FILE"; then
    log_success "mise is properly configured"
else
    log_warning "mise doctor reported issues - check the log"
fi

# Add summary
add_summary_section "Development Tools"
log_info "Installed $(mise list --installed | wc -l | tr -d ' ') development tools"

log_script_end "mise.sh"
