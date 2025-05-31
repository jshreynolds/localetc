#!/bin/bash
#
# logger.sh - Simple logging functions for consistent output
#
# Provides unified logging across all installation scripts
# Usage: source this file and use log_* functions
#

# Set up log file
LOG_DIR="${HOME}/etc/.logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✓]${NC} $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[✗]${NC} $message" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[!]${NC} $message" | tee -a "$LOG_FILE"
}

log_section() {
    local title="$1"
    echo -e "\n${GREEN}=== $title ===${NC}" | tee -a "$LOG_FILE"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Section: $title" >> "$LOG_FILE"
}

log_command() {
    local command="$1"
    echo -e "${BLUE}[RUN]${NC} $command" | tee -a "$LOG_FILE"
}

# Log script start
log_script_start() {
    local script_name="$1"
    log_section "Starting: $script_name"
    echo "Script: $script_name" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "Directory: $(pwd)" >> "$LOG_FILE"
}

# Log script end
log_script_end() {
    local script_name="$1"
    log_success "Completed: $script_name"
    echo -e "\n" >> "$LOG_FILE"
}