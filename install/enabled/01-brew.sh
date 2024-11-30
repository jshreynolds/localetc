#! /bin/bash

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

echo
echo "Installing brew files, casks, and fonts..."
echo

pushd ~/etc/dotfiles/brew || exit

brew bundle -v

read -p "Would you like to install personal packages? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  brew bundle -v --file=Brewfile.personal
fi

popd || exit

echo
echo "Done with brew bundle!"
echo
