#!/bin/bash
#
# 93-xcode.sh - Install Xcode from the Mac App Store
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

log_script_start "93-xcode.sh"

log_section "Installing Xcode"
log_command "mas install 497799835"
mas install 497799835  # Xcode
track_package "mas" "Xcode"

wait_for_enter "Accepting Xcode license. Hit Enter to continue..."

sudo xcodebuild -license accept
log_success "Accepted Xcode license"

log_script_end "93-xcode.sh"
