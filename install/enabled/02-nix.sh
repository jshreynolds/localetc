#!/bin/bash
#
# 02-nix.sh - Install Nix
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

log_script_start "02-nix.sh"

log_section "Installing Nix"
if command_exists nix; then
  log_success "Nix already installed"
else
  log_command "Nix installer"
  sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
fi

log_script_end "02-nix.sh"
