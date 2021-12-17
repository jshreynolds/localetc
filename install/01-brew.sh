#! /bin/sh


echo
echo "Installing brew..."
echo

# Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"

brew analytics off

echo
echo "Done with brew!"
echo
