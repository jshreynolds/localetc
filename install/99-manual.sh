#!/bin/bash

applications=(
    Anki.app
    GoodNotes.app
    Nebo.app
    NordVPN.app
    "Visual Studio Code.app"
    WhatsApp.app
)

for app in "${applications[@]}"; do
    echo "Please sign in to ${app} to enable syncing"
    open "/Applications/${app}"
    echo
    echo "Hit enter to continue..."
    read -r
    echo
done

