#! /bin/sh

if [ "$#" -ne 2 ]; then
    echo "provide the tool name and a default version to install"
    exit 1
fi

ENVTOOL=$1
DEFAULT_VERSION=$2

echo
echo "Installing a runtime using ${ENVTOOL}..."
echo

read -p "Runtime Version Desired? (${DEFAULT_VERSION})>" VERSION

if [ -z $VERSION ]; then
    VERSION=$DEFAULT_VERSION
fi

#Source the tool config
. ~/etc/env/enabled/*-$ENVTOOL

$ENVTOOL install $VERSION
$ENVTOOL global $VERSION

echo
echo "Done with $ENVTOOL!"
echo
