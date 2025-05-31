#! /bin/bash

echo
echo "Installing zshrc!.."
echo

if [[ -f ~/.zshrc ]]; then
    echo "moving old ~/.zshrc to ~/zshrc.bak"
    mv ~/.zshrc ~/.zshrc.bak
fi

ln -s ~/etc/dotfiles/shell/zshrc ~/.zshrc

echo
echo "Done with zshrc!"
echo
