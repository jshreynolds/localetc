#! /bin/bash

PACKS=$(< ~/etc/dotfiles/asdf)

function get_latest() {
    pack=$1
    if [[ $pack = "java" ]]; then
        latest=$(asdf latest java "adoptopenjdk-[0-9]")
    else
        latest=$(asdf latest "$pack")  
    fi
    echo "$latest"
}

for pack in $PACKS
do
    asdf plugin add "$pack"
    latest=$(get_latest "$pack")
    asdf install "$pack" "$latest"
    asdf global "$pack" "$latest"
done
