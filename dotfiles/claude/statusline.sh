#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

get() {
  echo "$input" | jq -r "$1 // empty" 2>/dev/null || true
}

model="$(get '.model.display_name')"
[ -z "$model" ] && model="$(get '.model.id')"
[ -z "$model" ] && model="unknown-model"

cwd="$(get '.workspace.current_dir')"
[ -z "$cwd" ] && cwd="$(get '.cwd')"
[ -n "$cwd" ] && cwd="$(basename "$cwd")"

branch="$(get '.workspace.git_branch')"
[ -z "$branch" ] && branch="$(get '.git.branch')"

ctx_pct="$(get '.context_window.used_percentage')"
ctx_size="$(get '.context_window.context_window_size')"
ctx_used="$(get '.context_window.tokens_used')"

cost="$(get '.cost.total_cost_usd')"
[ -z "$cost" ] && cost="$(get '.cost_usd')"

thinking="$(get '.thinking.enabled')"

mode="$(get '.mode')"
[ -z "$mode" ] && mode="$(get '.output_style.name')"

parts=()

parts+=("$model")

[ -n "$cwd" ] && parts+=("dir:$cwd")
[ -n "$branch" ] && parts+=("git:$branch")

if [ -n "$ctx_pct" ] && [ -n "$ctx_size" ]; then
  parts+=("ctx:${ctx_pct}%/${ctx_size}")
elif [ -n "$ctx_pct" ]; then
  parts+=("ctx:${ctx_pct}%")
elif [ -n "$ctx_size" ]; then
  parts+=("ctx:${ctx_size}")
fi

[ -n "$ctx_used" ] && parts+=("tokens:$ctx_used")
[ -n "$cost" ] && parts+=("cost:\$$cost")
[ -n "$thinking" ] && parts+=("thinking:$thinking")
[ -n "$mode" ] && parts+=("mode:$mode")

printf '%s' "${parts[0]}"
for part in "${parts[@]:1}"; do
  printf ' | %s' "$part"
done
printf '\n'
