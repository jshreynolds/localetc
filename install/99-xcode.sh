#! /bin/sh

echo
echo "Installing XCode directly!"
echo

mas install 497799835  #Xcode

echo
read -p "Accepting xcode license.  Hit Enter to continue..."
echo

sudo xcodebuild -license accept

echo
echo "All done!"
echo
