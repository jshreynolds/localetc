#!/bin/bash

echo
echo "Installing and configuring additiona app specific settings..."
echo

echo 

###############################################################################
# Google Chrome & Google Chrome Canary                                        #
###############################################################################

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true
defaults write com.google.Chrome.canary DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Dash                                                                        #
###############################################################################
# shellcheck disable=SC2088
defaults write com.kapeli.dashdoc syncFolderPath -string "~/Documents/dash"
defaults write com.kapeli.dashdoc showInDoc -boolean false


###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Activity Monitor" \
	"Google Chrome Canary" \
	"Google Chrome"; do
	killall "${app}" &> /dev/null
done
echo "Done with app specific mac settings! Note that some of these changes require a logout/restart to take effect."
