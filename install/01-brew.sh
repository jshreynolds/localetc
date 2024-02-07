#! /bin/bash


echo
echo "Installing brew..."
echo

# Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"

brew analytics off

echo
echo "Done with brew!"
echo


echo
echo "Installing brew files, casks, and fonts..."
echo

pushd ~/etc/dotfiles || exit

brew bundle -v

popd || exit

echo
echo "Done with brew bundle!"
echo
