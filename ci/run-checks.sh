#!/usr/bin/env bash
#
# run-checks.sh — this repo's checks, in one place, with nothing hand-listed.
#
# Three callers share this script so a check is never defined twice:
#   nix     flake.nix `checks` — one derivation per subcommand (`nix flake check`)
#   dagger  .dagger/src/localetc — the same run, containerised (`dagger call check`)
#   you     ci/run-checks.sh all
#
# Scripts are discovered by SHEBANG, never by a maintained list: a new script
# is covered the moment it is committed. The flake source is git-tracked files
# only, so untracked scratch files are never picked up.
#
# Usage: run-checks.sh [nixfmt|shell|python|skills|all]   (default: all)

set -euo pipefail

# py_compile and unittest must not try to write .pyc next to a read-only
# source tree (the nix store, and dagger's mounted source).
export PYTHONPYCACHEPREFIX="${PYTHONPYCACHEPREFIX:-${TMPDIR:-/tmp}/pycache}"

# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

# This repo's own files — the universe every check draws from.
#
# Must exclude vendored trees: tools/ai-manager/.venv alone holds ~976 .py
# files that are dependencies, not our code. `git ls-files` gets that right by
# construction (they are gitignored) and is exactly the set the flake copies to
# the store, so a local run and `nix flake check` agree on scope.
#
# The nix store and a .git-less mount have no work tree, hence the fallback.
# Its exclusion list is the sort of hand-maintained list this script exists to
# avoid — acceptable only because the contexts that reach it already contain
# tracked files only, so it never actually has to catch anything.
repo_files() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git ls-files
    else
        find . -type f \
            ! -path './.git/*' \
            ! -path '*/.venv/*' \
            ! -path '*/venv/*' \
            ! -path '*/node_modules/*' \
            ! -path '*/__pycache__/*' \
            ! -path './result/*' |
            sed 's|^\./||'
    fi | sort
}

# Repo files whose first line is a shebang matching $1.
_shebang_matches() {
    local file
    repo_files | while IFS= read -r file; do
        [ -f "$file" ] || continue
        if head -n 1 "$file" 2>/dev/null | grep -qE "$1"; then
            printf '%s\n' "$file"
        fi
    done
}

# sh/bash scripts. Matches `#!/bin/sh --`, `#!/bin/bash`, `#!/usr/bin/env bash`;
# deliberately does not match `... env python3`.
shell_scripts() {
    _shebang_matches '^#!.*[/ ](ba)?sh( |$|--)'
}

# Every .py file, plus extensionless scripts with a python shebang
# (bin/git_set_local_conf). Modules without a shebang still count.
python_scripts() {
    {
        repo_files | grep '\.py$' || true
        _shebang_matches '^#!.*python'
    } | sort -u
}

test_dirs() {
    repo_files | grep '/test_[^/]*\.py$' | sed 's|/[^/]*$||' | sort -u
}

# ---------------------------------------------------------------------------
# Checks
#
# Arrays are filled with an explicit while-read loop rather than `mapfile`:
# this script must also run under the bash 3.2 macOS ships, which has neither
# `mapfile` nor namerefs.
# ---------------------------------------------------------------------------

# A check that discovered nothing is a broken check, not a passing one.
#
# This is not hypothetical: the discovery pipelines run inside process
# substitution, where `set -e` and `pipefail` do NOT propagate. A container
# image missing `sed` made test_dirs return empty, and the python check
# cheerfully reported OK having run zero of its 74 tests. Assert the floor.
_require_found() {
    local what=$1 count=$2
    if [ "$count" -eq 0 ]; then
        echo "error: ${what}: discovered nothing." >&2
        echo "       A check with no inputs passes vacuously, so this is fatal." >&2
        echo "       Usually a missing tool (sed/grep/find/git) or a broken pipeline." >&2
        exit 1
    fi
}

check_nixfmt() {
    echo "==> nixfmt --check"
    find . -name '*.nix' ! -path './.git/*' -print0 | xargs -0 nixfmt --check
}

check_shell() {
    local scripts=() line
    while IFS= read -r line; do scripts+=("$line"); done < <(shell_scripts)
    echo "==> shellcheck (${#scripts[@]} scripts)"
    _require_found "shellcheck" "${#scripts[@]}"
    printf '    %s\n' "${scripts[@]}"
    shellcheck "${scripts[@]}"
}

check_python() {
    local files=() dirs=() line dir
    while IFS= read -r line; do files+=("$line"); done < <(python_scripts)
    echo "==> py_compile (${#files[@]} files)"
    _require_found "py_compile" "${#files[@]}"
    python3 -m py_compile "${files[@]}"

    while IFS= read -r line; do dirs+=("$line"); done < <(test_dirs)
    echo "==> unittest (${#dirs[@]} suites)"
    _require_found "unittest" "${#dirs[@]}"
    for dir in "${dirs[@]}"; do
        echo "--- $dir"
        python3 -m unittest discover -s "$dir"
    done
}

check_skills() {
    echo "==> skill metadata"
    python3 - <<'PY'
from pathlib import Path
import sys

failures = []
skills = sorted(Path("ai/skills").glob("*/SKILL.md"))
for path in skills:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        failures.append(f"{path}: missing frontmatter")
        continue
    end = text.find("\n---", 4)
    if end == -1:
        failures.append(f"{path}: unclosed frontmatter")
        continue
    frontmatter = text[4:end]
    for key in ("name:", "description:"):
        if key not in frontmatter:
            failures.append(f"{path}: missing {key}")

print(f"    {len(skills)} SKILL.md files")
if not skills:
    # same vacuous-pass guard as _require_found
    print("error: no SKILL.md files found under ai/skills", file=sys.stderr)
    raise SystemExit(1)
if failures:
    print("\n".join(failures), file=sys.stderr)
    raise SystemExit(1)
PY
}

# ---------------------------------------------------------------------------

main() {
    case "${1:-all}" in
    nixfmt) check_nixfmt ;;
    shell) check_shell ;;
    python) check_python ;;
    skills) check_skills ;;
    all)
        check_nixfmt
        check_shell
        check_python
        check_skills
        ;;
    *)
        echo "usage: run-checks.sh [nixfmt|shell|python|skills|all]" >&2
        exit 2
        ;;
    esac
    echo "OK"
}

# Only dispatch when executed. Sourcing gives you the discovery functions
# (repo_files, shell_scripts, python_scripts, test_dirs) for debugging.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
