#! /bin/sh

echo
echo "Installing vimrc and stuff"
echo

mv ~/.vimrc ~/vimrc.bak
mv ~/.vim ~/.vim.back

ln -s ~/etc/dotfiles/vimrc ~/.vimrc
ln -s ~/etc/vim ~/.vim

echo
echo "Vim is done!"
echo
