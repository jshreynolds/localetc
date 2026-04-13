#!/bin/bash
#
# 65-skills.sh - Install and configure AI agent skills
#
# Installs third-party skills from dotfiles/skills/skills.list via npx skills
# Symlinks user-authored skills from dotfiles/skills/custom/ into ~/.agents/skills/
# Wires ~/.claude/skills and ~/.config/opencode/skills to ~/.agents/skills/
#
# Dependencies: npx (Node.js)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"
ETC_DIR="$(dirname "$INSTALL_DIR")"

if [[ -f "${INSTALL_DIR}/lib/logger.sh" ]]; then
    source "${INSTALL_DIR}/lib/logger.sh"
    source "${INSTALL_DIR}/lib/common.sh"
    source "${INSTALL_DIR}/lib/summary.sh"
    log_script_start "65-skills.sh"
else
    log_info() { echo "  [info] $*"; }
    log_success() { echo "  [ok]   $*"; }
    log_warning() { echo "  [warn] $*"; }
    log_error() { echo "  [err]  $*"; }
    log_section() { echo ""; echo "=== $* ==="; }
fi

SKILLS_LIST="${ETC_DIR}/dotfiles/skills/skills.list"
CUSTOM_SKILLS_DIR="${ETC_DIR}/dotfiles/skills"
AGENTS_SKILLS_DIR="${HOME}/.agents/skills"

# Create a symlink to a directory, backing up any existing directory first
# Usage: link_dir <source> <link>
link_dir() {
    local source="$1"
    local link="$2"

    if [[ -L "${link}" && "$(readlink "${link}")" == "${source}" ]]; then
        log_info "Symlink already correct: ${link} → ${source}"
        return 0
    fi

    if [[ -e "${link}" ]]; then
        mv "${link}" "${link}.bak"
        log_warning "Backed up existing path: ${link} → ${link}.bak"
    fi

    mkdir -p "$(dirname "${link}")"
    ln -s "${source}" "${link}"
    log_success "Linked: ${link} → ${source}"
}

# ---------------------------------------------------------------------------
# 1. Ensure ~/.agents/skills/ exists
# ---------------------------------------------------------------------------
log_section "Setting up skills directories"
mkdir -p "${AGENTS_SKILLS_DIR}"
log_success "Skills directory ready: ${AGENTS_SKILLS_DIR}"

# ---------------------------------------------------------------------------
# 2. Wire agent skill directories to ~/.agents/skills/
# ---------------------------------------------------------------------------
[[ -d "${HOME}/.claude" ]] && link_dir "${AGENTS_SKILLS_DIR}" "${HOME}/.claude/skills"
[[ -d "${HOME}/.config/opencode" ]] && link_dir "${AGENTS_SKILLS_DIR}" "${HOME}/.config/opencode/skills"

# ---------------------------------------------------------------------------
# 3. Install third-party skills from skills.list
# ---------------------------------------------------------------------------
log_section "Installing third-party skills"

if [[ ! -f "${SKILLS_LIST}" ]]; then
    log_warning "No skills.list found at ${SKILLS_LIST}, skipping"
else
    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Skip comments and empty lines
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        # Skip lines that are empty or contain only whitespace 
        [[ -z "${line// /}" ]] && continue

        package=$(echo "${line}" | awk '{print $1}')
        skill_name=$(echo "${line}" | awk '{print $2}')

        log_info "Processing skill entry: ${line}"
        log_info "Package: ${package}, Skill: ${skill_name:-<all>}"

        if [[ -n "${skill_name}" ]]; then
            log_info "Installing skill '${skill_name}' from ${package}"
            if npx --yes skills add "${package}" -g -y -s "${skill_name}" < /dev/null; then
                log_success "Installed: ${skill_name}"
            else
                log_error "Failed to install: ${skill_name} from ${package}"
            fi
        else
            log_info "Installing from ${package}"
            if npx --yes skills add "${package}" -g -y < /dev/null; then
                log_success "Installed from: ${package}"
            else
                log_error "Failed to install from: ${package}"
            fi
        fi
    done < "${SKILLS_LIST}"
fi

# ---------------------------------------------------------------------------
# 4. Symlink user-authored skills from dotfiles/skills/custom/
# ---------------------------------------------------------------------------
log_section "Symlinking custom skills"

shopt -s nullglob
for skill_dir in "${CUSTOM_SKILLS_DIR}"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_name=$(basename "${skill_dir}")
    link_dir "${skill_dir}" "${AGENTS_SKILLS_DIR}/${skill_name}"
done
shopt -u nullglob

if [[ -f "${INSTALL_DIR}/lib/logger.sh" ]]; then
    log_script_end "65-skills.sh"
else
    echo "Done with skills setup!"
fi
