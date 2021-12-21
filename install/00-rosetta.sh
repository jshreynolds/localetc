#! /bin/sh


echo
echo "Installing rosetta 2..."
echo

arch=$(/usr/bin/arch)

if [ "$arch" == "arm64" ]; then
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

echo
echo "Done with rosetta 2!"
echo
