#! /bin/sh


echo
echo "Installing spacmeacs.."
echo

git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d

ln -s ~/etc/dotfiles/spacemacs ~/.spacemacs

echo
echo "Done with spacemacs!"
echo
