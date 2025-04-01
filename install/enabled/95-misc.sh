#! /bin/bash

NAME="miscellaneous bits and bobs"

echo
echo "Installing and configuring $NAME..."
echo

# Activate Dash License
open ~/Documents/dash/license.dash-license
killall Dash

# Insert any miscellaneous installation logic here

echo "Configuring git default branch and ignore generator..."
git config --global init.defaultBranch main
git config --global alias.ignore '!gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}; gi'
echo "git configured"

echo "Loading in docker configuration..."
mkdir -p ~/.docker
ln -s ~/etc/dotfiles/docker/config.json ~/.docker/config.json
echo "docker configured"

echo
echo "Done with $NAME!"
echo
