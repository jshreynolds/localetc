#! /bin/sh

if [ $# -ne 1 ] 
then
   echo "please provide a name for your machine"
fi 

set name = $1

#Keyboard repeat rate and initial wait
defaults write -g InitialKeyRepeat -int 25
defaults write -g KeyRepeat -int 2

#Two Button Mouse Mode
defaults write com.apple.AppleMultitouchMouse MouseButtonMode TwoButton
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode TwoButton

#Set the hostname
sudo scutil --set HostName $name
sudo scutil --set LocalHostName $name
sudo scutil --set ComputerName $name 
