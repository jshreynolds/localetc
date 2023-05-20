#! /bin/sh

NAME="miscellaneous bits and bobs"

echo
echo "Installing $NAME..."
echo

# Alacritty themes (alacritty should be installed by now!)

mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

echo
echo "Done with $NAME!"
echo
