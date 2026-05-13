#!/bin/bash
#
# 99-wecome.sh - Show final welcome message and install summary
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

source "${INSTALL_DIR}/lib/logger.sh"
source "${INSTALL_DIR}/lib/common.sh"
source "${INSTALL_DIR}/lib/summary.sh"

cat << EOF

And, Done!
Welcome to your system.
The sands of software shift beneath our feet so your mileage may vary.

EOF

show_summary
