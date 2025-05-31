#!/bin/bash
#
# summary.sh - Track and display installation summary
#
# Provides functions to track what gets installed and show summary
# Usage: source this file and use add_to_summary/show_summary functions
#

# Source logger if not already loaded
if [[ -z "$LOG_FILE" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

# Summary file location
SUMMARY_DIR="${HOME}/etc/.logs"
mkdir -p "$SUMMARY_DIR"
SUMMARY_FILE="${SUMMARY_DIR}/install-summary-$(date +%Y%m%d-%H%M%S).txt"

# Track start time
INSTALL_START_TIME=$(date +%s)

# Initialize summary
init_summary() {
    cat > "$SUMMARY_FILE" <<EOF
macOS Configuration Installation Summary
========================================
Date: $(date)
User: $(whoami)
Machine: $(hostname)
========================================

EOF
}

# Add item to summary
add_to_summary() {
    local category="${1}"
    local item="${2}"
    local status="${3:-✓}"
    
    echo "[$status] $category: $item" >> "$SUMMARY_FILE"
}

# Add section to summary
add_summary_section() {
    local section="$1"
    echo -e "\n--- $section ---" >> "$SUMMARY_FILE"
}

# Track installed package
track_package() {
    local package_type="$1"  # brew, cask, mas, mise
    local package_name="$2"
    
    add_to_summary "$package_type" "$package_name"
}

# Track symlink creation
track_symlink() {
    local source="$1"
    local target="$2"
    
    add_to_summary "Symlink" "$target → $source"
}

# Track system preference change
track_preference() {
    local description="$1"
    
    add_to_summary "System" "$description"
}

# Track manual step
track_manual_step() {
    local description="$1"
    
    add_to_summary "Manual" "$description" "⚠"
}

# Show installation summary
show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - INSTALL_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # Add timing info to summary
    echo -e "\n========================================" >> "$SUMMARY_FILE"
    echo "Installation completed in ${minutes}m ${seconds}s" >> "$SUMMARY_FILE"
    echo "========================================" >> "$SUMMARY_FILE"
    
    # Display summary
    echo
    log_section "Installation Summary"
    
    if [[ -f "$SUMMARY_FILE" ]]; then
        # Show key statistics
        local total_items=$(grep -c "^\[" "$SUMMARY_FILE" || echo "0")
        local successful=$(grep -c "^\[✓\]" "$SUMMARY_FILE" || echo "0")
        local warnings=$(grep -c "^\[⚠\]" "$SUMMARY_FILE" || echo "0")
        local errors=$(grep -c "^\[✗\]" "$SUMMARY_FILE" || echo "0")
        
        echo
        echo "📊 Statistics:"
        echo "   Total items: $total_items"
        echo "   Successful: $successful"
        [[ $warnings -gt 0 ]] && echo "   Warnings: $warnings"
        [[ $errors -gt 0 ]] && echo "   Errors: $errors"
        echo "   Duration: ${minutes}m ${seconds}s"
        
        # Show warnings/manual steps if any
        if [[ $warnings -gt 0 ]]; then
            echo
            echo "⚠️  Manual steps required:"
            grep "^\[⚠\]" "$SUMMARY_FILE" | sed 's/^\[⚠\] Manual: /   - /'
        fi
        
        # Show errors if any
        if [[ $errors -gt 0 ]]; then
            echo
            echo "❌ Errors occurred:"
            grep "^\[✗\]" "$SUMMARY_FILE" | sed 's/^\[✗\] /   - /'
        fi
        
        echo
        echo "📄 Full summary saved to: $SUMMARY_FILE"
        echo "📋 Installation log saved to: $LOG_FILE"
    else
        log_warning "No summary file found"
    fi
}

# Helper to show progress
show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    
    local percentage=$((current * 100 / total))
    log_info "Progress: [$current/$total] $percentage% - $description"
}

# Initialize summary when sourced
init_summary