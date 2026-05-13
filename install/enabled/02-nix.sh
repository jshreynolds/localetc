#! /bin/bash

echo
echo "Installing nix..."
echo

# Nix
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)

echo
echo "Done with nix!"
echo
