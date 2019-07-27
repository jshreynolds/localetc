#! /bin/sh

# Brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew analytics off

cd ../dotfiles

brew bundle
