#! /bin/sh

echo
echo "Installing oh my zsh!.."
echo

mkdir -p ~/.oh-my-zsh/themes
ln -s ~/etc/dotfiles/jshlyd.zsh-theme ~/.oh-my-zsh/themes
mv ~/.zshrc ~/.zshrc.bak
ln -s ~/etc/dotfiles/zshrc ~/.zshrc

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


echo
echo "Done with oh my zsh!"
echo
