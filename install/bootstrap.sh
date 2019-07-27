#! /bin/sh

ssh-keygen

read -p "Upload the ssh key public id to github and hit Enter..."

xcode-select --install

echo
read -p "Install xcode command-line tools"
echo

git clone git@github.com:jshreynolds/localetc.git ~/etc

echo
echo "Run ./install.sh to finish the installation."
echo
