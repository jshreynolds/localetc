#! /bin/bash

echo
echo "Installing xcode..."
echo

mas install 497799835  #Xcode

echo
read -pr "Accepting xcode license.  Hit Enter to continue..."
echo

sudo xcodebuild -license accept

echo
echo "xcode installed!"
echo
