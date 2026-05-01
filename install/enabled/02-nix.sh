#! /bin/bash

echo
echo "Installing nix..."
echo

# Nix
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)

echo
echo "Done with nix!"
echo

echo
echo "Installing brew files, casks, and fonts..."
echo

pushd ~/etc/install/packages || exit

brew bundle -v --file=Brewfile.core

read -p "Would you like to install personal packages? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  brew bundle -v --file=Brewfile.personal
fi

read -p "Would you like to install work packages? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  brew bundle -v --file=Brewfile.work
fi

popd || exit

echo
echo "Done with brew bundle!"
echo
