#!/bin/bash
#
# 01-brew.sh - Install Homebrew and Brewfile packages
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

log_script_start "01-brew.sh"

log_section "Installing Homebrew"
if command_exists brew; then
  log_success "Homebrew already installed"
else
  log_command "Homebrew installer"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

brew analytics off
log_success "Homebrew analytics disabled"

log_section "Installing Brewfile packages"

pushd ~/etc/install/packages || exit

install_brewfile "Brewfile.core" "core"

if ask_yes_no "Would you like to install personal packages?" "n"; then
  install_brewfile "Brewfile.personal" "personal"
fi

if ask_yes_no "Would you like to install work packages?" "n"; then
  install_brewfile "Brewfile.work" "work"
fi

popd || exit

log_script_end "01-brew.sh"
