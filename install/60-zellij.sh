#! /bin/sh


echo
echo "Configuring Zellij..."
echo

pushd ~/etc/dotfiles

ZELLIJ_CONFIG_DIR=~/.config/zellij

mkdir -p $ZELLIJ_CONFIG_DIR
cp -r zellij.kdl $ZELLIJ_CONFIG_DIR/config.kdl

popd

echo
echo "Done with setting up zellij config!"
echo
