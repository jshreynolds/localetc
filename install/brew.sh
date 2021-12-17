#! /bin/sh


echo
echo "Installing brew files, casks, and fonts..."
echo

# Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew analytics off

pushd ../dotfiles

brew bundle

popd

echo
echo "Done with brew!"
echo
