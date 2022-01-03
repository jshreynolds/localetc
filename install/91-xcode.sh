#! /bin/sh

echo
echo "Installing xcode..."
echo

mas install 497799835  #Xcode

echo
read -p "Accepting xcode license.  Hit Enter to continue..."
echo

sudo xcodebuild -license accept

echo
echo "xcode installed!"
echo
