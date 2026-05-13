#!/bin/bash
#
# 60-dotfiles.sh - Configure dotfiles and application settings
#
# Creates symlinks for all configuration files
# Dependencies: overlay_symlinks utility
#

# Get the directory of this script (repo root = parent of install/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"
ETC_DIR="$(dirname "$INSTALL_DIR")"
DOTFILES="${ETC_DIR}/dotfiles"

# Source libraries if available
if [[ -f "${INSTALL_DIR}/lib/logger.sh" ]]; then
    source "${INSTALL_DIR}/lib/logger.sh"
    source "${INSTALL_DIR}/lib/common.sh"
    source "${INSTALL_DIR}/lib/summary.sh"
    log_script_start "dotfiles.sh"
else
    echo "Configuring dotfiles..."
fi

# Standard config directory symlinks (~/.config/<app> ← dotfiles/config/<app>)
log_section "Setting up application configurations"
ensure_directory ~/.config
shopt -s nullglob
for entry in "${DOTFILES}/config/"*; do
    name="$(basename "$entry")"
    target="$HOME/.config/$name"
    safe_symlink "$entry" "$target"
    track_symlink "${DOTFILES}/config/${name}" "${HOME}/.config/${name}"
done

# Home directory dotfiles (dotfiles/<name> → ~/.<name>), e.g. zshrc, gitconfig
log_section "Setting up home directory dotfiles"
for entry in "${DOTFILES}/"*; do
    name="$(basename "$entry")"
    # Skip config/ - handled separately above
    [[ "$name" == "config" ]] && continue
    target="$HOME/.$name"
    safe_symlink "$entry" "$target"
    track_symlink "${DOTFILES}/${name}" "${HOME}/.${name}"
done
shopt -u nullglob

# Log completion
if [[ -f "${INSTALL_DIR}/lib/logger.sh" ]]; then
    log_script_end "dotfiles.sh"
else
    echo "Done with setting up configs!"
fi
