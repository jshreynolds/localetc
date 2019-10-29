#! /bin/sh


echo
echo "Installing brew files, casks, and fonts..."
echo

# Brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew analytics off

pushd ../dotfiles

brew bundle

popd

echo
echo "Done with brew!"
echo