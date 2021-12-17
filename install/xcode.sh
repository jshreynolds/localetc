#! /bin/sh


echo
echo "Updating xcode license and ..."
echo

# Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"

brew analytics off

pushd ../dotfiles

brew bundle

popd

echo
echo "Done with brew!"
echo
