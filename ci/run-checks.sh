#!/usr/bin/env bash
#
# run-checks.sh — this repo's checks, in one place, with nothing hand-listed.
#
# Three callers share this script so a check is never defined twice:
#   nix     flake.nix `checks` — one derivation per check (`nix flake check`)
#   dagger  .dagger/src/checks — the same run, containerised (`dagger call all`)
#   you     ci/run-checks.sh all
#
# WHICH checks exist is ci/checks.list, read by all three callers. WHAT each
# one does is a `check_<name>` function below. There is no third list: this
# script dispatches on the function's existence, so a name can never drift
# from an implementation.
#
# Scripts are discovered by SHEBANG, never by a maintained list: a new script
# is covered the moment it is committed. The flake source is git-tracked files
# only, so untracked scratch files are never picked up.
#
# Usage: run-checks.sh [<name>|all|list]   (default: all)

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
# There are two branches, and BOTH are live — the comment that used to sit here
# claimed the fallback "never actually has to catch anything", which was wrong:
#   git   dagger mounts .git, so the container takes this branch
#   find  `nix flake check` copies the repo to the store WITHOUT .git, so the
#         store build takes this one
# Two implementations of "the universe" is how the two CI paths would drift
# apart unnoticed, so check_discovery below asserts they agree.
#
# Set REPO_FILES_MODE=git|find to pin a branch (check_discovery uses this to
# run both; it is also the escape hatch when git refuses a tree it considers
# unsafe, which otherwise degrades to `find` silently).
REPO_FILES_MODE="${REPO_FILES_MODE:-auto}"

_repo_files_git() { git ls-files; }

# The exclusion list is the sort of hand-maintained list this script exists to
# avoid. It is tolerable only because check_discovery proves it drops nothing
# that git tracks.
_repo_files_find() {
    find . -type f \
        ! -path './.git/*' \
        ! -path '*/.venv/*' \
        ! -path '*/venv/*' \
        ! -path '*/node_modules/*' \
        ! -path '*/__pycache__/*' \
        ! -path './result/*' |
        sed 's|^\./||'
}

repo_files() {
    local mode=$REPO_FILES_MODE
    if [ "$mode" = auto ]; then
        # Quoted so shellcheck reads these as strings, not `$(git)`/`$(find)`.
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            mode="git"
        else
            mode="find"
        fi
    fi
    "_repo_files_$mode" | sort
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

# Every .nix file. Drawn from repo_files like everything else: a bare `find`
# here would check untracked scratch .nix files that no other check can see.
nix_files() {
    repo_files | grep '\.nix$' || true
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

# The two repo_files branches must describe the same repo.
#
# Asserted in one direction only: every file git tracks must also be found by
# the `find` branch. The reverse does not hold and should not — a working tree
# legitimately holds untracked scratch that git ignores, while the two contexts
# that actually run `find` (the nix store copy, a .git-less mount) contain
# tracked files only.
#
# What this catches is the drift that matters: an exclusion pattern or a
# missing tool quietly shrinking the file set `nix flake check` sees, so it
# checks less than dagger does while both still report OK.
check_discovery() {
    echo "==> discovery"
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "    skip: no work tree here, so only the find branch is reachable"
        return 0
    fi

    local tracked missing count
    tracked=$(REPO_FILES_MODE="git" repo_files)
    count=$(printf '%s\n' "$tracked" | grep -c . || true)
    echo "    ${count} tracked files, both branches agree"
    _require_found "discovery" "$count"

    missing=$(comm -23 <(printf '%s\n' "$tracked") <(REPO_FILES_MODE="find" repo_files))
    if [ -n "$missing" ]; then
        echo "error: the find branch misses files that git tracks:" >&2
        printf '%s\n' "$missing" | sed 's/^/       /' >&2
        echo "       \`nix flake check\` uses that branch, so it would check less" >&2
        echo "       than dagger does and still report OK." >&2
        return 1
    fi
}

# No `xargs`: with an empty list GNU xargs still runs `nixfmt --check`, which
# reads (empty) stdin and exits 0 — a vacuous pass. BSD xargs skips instead, so
# the old pipeline also disagreed between macOS and the linux container.
check_nixfmt() {
    local files=() line
    while IFS= read -r line; do files+=("$line"); done < <(nix_files)
    echo "==> nixfmt --check (${#files[@]} files)"
    _require_found "nixfmt" "${#files[@]}"
    nixfmt --check "${files[@]}"
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
    python3 ci/check_skills.py
}

# ---------------------------------------------------------------------------

# Every check runs even after one fails, then the roll-up decides the exit.
#
# Fail-fast would mean this and the dagger fan-out (one container per check)
# disagree about how much a single run tells you: the first failure would mask
# the other four here but not there. One trip, every answer, both places.
run_all() {
    local name failed=()
    while IFS= read -r name; do
        if ! "check_$name"; then
            failed+=("$name")
        fi
        echo
    done < <(check_names)

    if [ "${#failed[@]}" -gt 0 ]; then
        echo "FAILED: ${failed[*]}" >&2
        exit 1
    fi
    echo "OK"
}

# The registry, read from ci/checks.list — never a list in this file.
# Resolved against this script's own location so callers need not cd first.
MANIFEST="$(dirname "${BASH_SOURCE[0]}")/checks.list"

# Parsed with `read` rather than awk/cut: the nixos/nix image ships coreutils
# but no gawk, and the registry parser is the one thing that must work before
# any tool has been installed.
check_names() {
    local name rest
    while read -r name rest; do
        case "$name" in
        '' | \#*) continue ;;
        esac
        printf '%s\n' "$name"
    done <"$MANIFEST"
}

main() {
    local name="${1:-all}"

    case "$name" in
    all) run_all ;;
    list) check_names ;;
    *)
        # Dispatch on the function, not on a list of names: an entry in
        # checks.list with no check_<name> function fails loudly here rather
        # than silently doing nothing.
        if ! declare -F "check_$name" >/dev/null; then
            echo "usage: run-checks.sh [<name>|all|list]" >&2
            echo "checks: $(check_names | tr '\n' ' ')" >&2
            exit 2
        fi
        "check_$name"
        echo "OK"
        ;;
    esac
}

# Only dispatch when executed. Sourcing gives you the discovery functions
# (repo_files, shell_scripts, python_scripts, test_dirs) for debugging.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
