#! /bin/sh


echo
echo "Installing brew files, casks, and fonts..."
echo

pushd ~/etc/dotfiles

brew bundle

popd

echo
echo "Done with brew bundle!"
echo
