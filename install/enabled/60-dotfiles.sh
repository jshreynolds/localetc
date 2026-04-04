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
    if [[ -d "$entry" ]]; then
        # For directories: back up existing dir, then symlink the whole folder
        if [[ -d "$target" && ! -L "$target" ]]; then
            log_info "Backing up existing $target to ${target}.bak"
            mv "$target" "${target}.bak"
        fi
        safe_symlink "$entry" "$target"
    else
        # For files: symlink directly
        safe_symlink "$entry" "$target"
    fi
    track_symlink "~/etc/dotfiles/config/$name" "~/.config/$name"
done

# Claude Code specific configuration
if [[ -d ~/.claude ]]; then
    log_info "Setting up Claude Code configuration"
    
    # Symlink the global cursor rules
    safe_symlink ~/etc/dotfiles/config/claude/CLAUDE.md ~/.claude/CLAUDE.md
    track_symlink "~/etc/dotfiles/config/claude/CLAUDE.md" "~/.claude/CLAUDE.md"
    
    log_success "Claude Code configuration complete"
else
    log_info "Claude Code directory not found, skipping configuration"
fi

# Docker configuration
if [[ -f ~/etc/dotfiles/docker/config.json ]]; then
    log_info "Setting up Docker configuration"
    ensure_directory ~/.docker
    safe_symlink ~/etc/dotfiles/docker/config.json ~/.docker/config.json
    track_symlink "~/etc/dotfiles/docker/config.json" "~/.docker/config.json"
fi

# Shell configuration
log_info "Setting up shell configuration"
safe_symlink ~/etc/dotfiles/shell/zshrc ~/.zshrc
track_symlink "~/etc/dotfiles/shell/zshrc" "~/.zshrc"

# Log completion
if [[ -f "${INSTALL_DIR}/lib/logger.sh" ]]; then
    log_script_end "dotfiles.sh"
else
    echo "Done with setting up configs!"
fi
