#! /bin/sh

echo
echo "Installing a node using nodenv..."
echo

#Install the latest version of node
. ~/etc/env/enabled/04-nodenv
nodenv install 12.0.0
nodenv global 12.0.0
npm install -g react-native-cli

echo
echo "Done with nodenv!"
echo