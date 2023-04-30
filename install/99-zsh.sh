#! /bin/sh

echo
echo "Installing zshrc!.."
echo

mv ~/.zshrc ~/.zshrc.bak
ln -s ~/etc/dotfiles/zshrc ~/.zshrc

echo
echo "Done with zshrc!"
echo
