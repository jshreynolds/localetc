#!/bin/bash
#
# 92-macos-additional.sh - Configure app-specific macOS settings
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

log_script_start "92-macos-additional.sh"

###############################################################################
# Google Chrome & Google Chrome Canary                                        #
###############################################################################

log_section "Configuring Chrome settings"

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true
defaults write com.google.Chrome.canary DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true
track_preference "Chrome print settings"

###############################################################################
# Dash                                                                        #
###############################################################################
log_section "Configuring Dash settings"
# shellcheck disable=SC2088
defaults write com.kapeli.dashdoc syncFolderPath -string "~/Documents/dash"
defaults write com.kapeli.dashdoc showInDoc -boolean false
track_preference "Dash settings"


###############################################################################
# Kill affected applications                                                  #
###############################################################################

log_section "Restarting affected applications"
for app in "Activity Monitor" \
	"Google Chrome Canary" \
	"Google Chrome"; do
	killall "${app}" &> /dev/null
done
log_warning "Some app-specific macOS changes require a logout or restart to take effect"
log_script_end "92-macos-additional.sh"
