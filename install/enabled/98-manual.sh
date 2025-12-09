#!/bin/bash

applications=(
    Cursor.app
    Dash.app
    GoodNotes.app
    Rectangle.app
    "Visual Studio Code.app"
)

for app in "${applications[@]}"; do
    echo "Please sign in or configure ${app} to sync / startup automatically / give permissions/ etc."
    open "/Applications/${app}"
    echo
    echo "Hit enter to continue..."
    read -r
    echo
done

open ~/Documents/dash/license.dash-license

