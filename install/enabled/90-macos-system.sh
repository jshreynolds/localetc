#!/bin/bash
#
# 90-macos-system.sh - Configure system-level macOS settings
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

log_script_start "90-macos-system.sh"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
log_info "Closing System Preferences"
osascript -e 'tell application "System Preferences" to quit'

keep_sudo_alive

###############################################################################
# General UI/UX                                                               #
###############################################################################

if [[ -z $MACHINE_NAME ]] 
then
   log_error "\$MACHINE_NAME not set. Please run this script with that environment variable set"
   exit 1
fi 

name=$MACHINE_NAME
log_section "Applying system-level macOS settings"

# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "$name"
sudo scutil --set HostName "$name"
sudo scutil --set LocalHostName "$name"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$name"
track_preference "Computer name set to $name"

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Show language menu in the top right corner of the boot screen
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

# Enable HiDPI display modes (requires restart)
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

# Show the /Volumes folder
sudo chflags nohidden /Volumes

track_preference "System-level macOS preferences applied"
log_warning "Some system-level macOS changes require a logout or restart to take effect"
log_script_end "90-macos-system.sh"
