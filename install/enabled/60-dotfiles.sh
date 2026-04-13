#!/bin/bash
#
# 60-dotfiles.sh - Configure dotfiles and application settings
#
# Creates symlinks for all configuration files
# Dependencies: overlay_symlinks utility
#

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

# Source libraries if available
if [[ -f "${INSTALL_DIR}/lib/logger.sh" ]]; then
    source "${INSTALL_DIR}/lib/logger.sh"
    source "${INSTALL_DIR}/lib/common.sh"
    source "${INSTALL_DIR}/lib/summary.sh"
    log_script_start "dotfiles.sh"
else
    echo "Configuring dotfiles..."
fi

# Standard config directory symlinks
log_section "Setting up application configurations"
ensure_directory ~/.config
for entry in ~/etc/dotfiles/config/*; do
    name="$(basename "$entry")"
    target="$HOME/.config/$name"
    safe_symlink "$entry" "$target"
    track_symlink "~/etc/dotfiles/config/$name" "~/.config/$name"
done


# Home directory dotfiles symlinks (~/etc/dotfiles/* → ~/.*)
log_section "Setting up home directory dotfiles"
for entry in ~/etc/dotfiles/*; do
    name="$(basename "$entry")"
    # Skip config/ - handled separately above
    [[ "$name" == "config" ]] && continue
    target="$HOME/.$name"
    safe_symlink "$entry" "$target"
    track_symlink "~/etc/dotfiles/$name" "~/.$name"
done

# Log completion
if [[ -f "${INSTALL_DIR}/lib/logger.sh" ]]; then
    log_script_end "dotfiles.sh"
else
    echo "Done with setting up configs!"
fi
