#! /bin/sh

echo
echo "Installing zshrc!.."
echo

ln -s ~/etc/dotfiles/jshlyd.zsh-theme ~/.oh-my-zsh/themes
mv ~/.zshrc ~/.zshrc.bak
ln -s ~/etc/dotfiles/zshrc ~/.zshrc

echo
echo "Done with zshrc!"
echo
