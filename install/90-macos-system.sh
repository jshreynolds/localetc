#!/bin/bash

echo
echo "Installing and configuring mac system level settings..."
echo

echo 

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

if [[ -z $MACHINE_NAME ]] 
then
   echo
   echo "Error: \$MACHINE_NAME not set!"
   echo "Please run this script with that environment variable set"
   echo
   exit 1
fi 

name=$MACHINE_NAME
# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "$name"
sudo scutil --set HostName "$name"
sudo scutil --set LocalHostName "$name"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$name"

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

echo "Done with sysetem level mac changes! Note that some of these changes require a logout/restart to take effect."
