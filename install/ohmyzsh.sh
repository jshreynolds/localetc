#! /bin/sh

echo
echo "Installing oh my zsh!.."
echo

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

ln -s ~/etc/dotfiles/jshlyd.zsh-theme ~/.oh-my-zsh/themes
mv ~/.zshrc ~/.zshrc.bak
ln -s ~/etc/dotfiles/zshrc ~/.zshrc

# Oh my zsh start's a new zsh and we have to exit it to return to the script.
exit

echo
echo "Done with oh my zsh!"
echo