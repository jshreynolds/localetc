#! /bin/bash

PACKS=$(< ~/etc/dotfiles/mise)

for pack in $PACKS
do
    mise use --global --yes "$pack"@"$(mise latest "$pack")"
done
