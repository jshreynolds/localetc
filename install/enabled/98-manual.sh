#!/bin/bash
#
# 98-manual.sh - Prompt for manual application setup steps
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

log_script_start "98-manual.sh"

applications=(
    Cursor.app
    GoodNotes.app
    Rectangle.app
    "Visual Studio Code.app"
)

log_section "Manual application setup"
for app in "${applications[@]}"; do
    log_info "Please sign in or configure ${app} for sync, startup, permissions, or other setup"
    track_manual_step "Configure ${app}"
    open "/Applications/${app}"
    wait_for_enter "Hit Enter to continue..."
done

log_script_end "98-manual.sh"
